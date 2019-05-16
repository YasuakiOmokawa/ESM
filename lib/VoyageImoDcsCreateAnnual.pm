package VoyageImoDcsCreateAnnual;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use constant {
  TRUE  => 1,
  FALSE => 0,
};
use POSIX qw(strftime);
use Carp qw(croak);

my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";

use parent 'Totalizer';
use EsmConf;
use EsmConfigWeb;
use EsmDataDetector;
use EsmLib;
use VoyageRowDataSummarizer;
use VoyageJudgeHandler;

sub new {
  my ($class, $log, $add, $year, $cli_code, $imo_no) = @_;

  my $self = $class->SUPER::new($log, $add);
  if ( !($cli_code && $imo_no && $year) ) {
    my $package = __PACKAGE__;
    $self->{log}->Error("client_code => %s, imo_no => %s, year => %s\n", $cli_code, $imo_no, $year);
    $self->{log}->Error("Useage: $package->new(log_module, voyage_infos_array_ref, year, client_code, imo_number)\n");
    croak "there is no required parameter\n";
  }

  $self->{totalize_year}                    = $year;
  $self->{totalize_client_code}             = $cli_code;
  $self->{totalize_imo_no}                  = $imo_no;
  $self->{totalize_result}                  = undef;
  $self->{not_totalize_items}               = [
    "voyage_number",
    "eu_mrv",
    "dep_port",
    "dep_date_time",
    "arr_port",
    "arr_date_time",
    "time_at_sea",
#    "foc_hfo",
#    "foc_lfo",
#    "foc_dogo",
#    "foc_other",
#    "co2_hfo",
#    "co2_lfo",
#    "co2_dogo",
#    "co2_other",
#    "distance_travelled",
#    "hours_underway",
    "cargo_weight",
    "passenger",
    "unit_laden",
    "unit_empty",
    "cars",
    "dwt_carried",
    "volume",
    "transport_work",
    "foc_dogo_per_distance",
    "foc_lfo_per_distance",
    "foc_hfo_per_distance",
    "foc_other_per_distance",
    "foc_dogo_per_transport_work",
    "foc_lfo_per_transport_work",
    "foc_hfo_per_transport_work",
    "foc_other_per_transport_work",
    "co2_per_distance",
    "eeoi"
  ];

  return $self;
}

# 年間値集計のメイン処理。
# 集計対象データがあれば、その数だけ集計を実施し、最後にサマリを出して返却するプログラム：
#    対象データを年始、年中、年末の3カテゴリに分別して加算してゆく。
#    すべてのカテゴリのサマリを計算。
# 集計結果には最大で年始、年中、年末、サマリ、の計4カテゴリが存在する。
# 集計対象データが存在しなければ未定義の集計結果が返却される。
sub totalize {
  my $self = shift;
  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  if (@{$self->{summarize_result_group}}) {

    # 集計の準備
    my $ed = EsmDataDetector->new($self->{log}, $self->{totalize_client_code}, $self->{totalize_imo_no});
    my $annual_tmp = EsmDataDetector::template_imo_dcs_annual;
    if (-f $annual_tmp) {

      my $jh = JsonHandler->new($self->{log}, $annual_tmp);
      $self->{totalize_result} = $jh->get_data;

      # 計算の実施
      $self->{log}->Info("  calculate by category start\n");
      for my $voy_info (@{$self->{summarize_result_group}}) {

        my $root = $voy_info->{data};

        # 本処理で使われるわけではないが、ダウンロードファイルに必要なデータなので取得しておく
        $self->{totalize_result}{data}{ship_info} = $root->{include_reports}{ship_info} if !exists $self->{totalize_result}{data}{ship_info};

        # カテゴリ別に加算
        my $voy_row_data = $root->{for_row}{data};
        my $info_type = $self->_judge_year_over($root);
        if ($info_type eq 'beginning_of_year') {

          # 年始
          $self->_calc_begin($voy_row_data);
        }
        elsif ($info_type eq 'end_of_year') {

          # 年末
          $self->_calc_end($voy_row_data);
        }
        elsif ($info_type eq 'middle_of_year') {

          # 年中
          $self->_calc_middle($voy_row_data);
        }
      }

      # 計算後チェックの実施(カテゴリ)
      $self->{log}->Info("  format category value start\n");
      $self->format($self->{totalize_result}{data}, ["ship_info", "summary"], 'imo_dcs');

      # サマリを作成
      my $calc_list = $self->_create_list_for_summary;
      if (@{$calc_list}) {

        $self->{log}->Info("  created category, calculate summary start\n");
        $self->{totalize_result}{data}{summary}{data} = $self->calc_total($calc_list,
                                                            $self->{not_totalize_items});

        # 計算後チェックの実施(サマリ)
        $self->{log}->Info("  format summary value start\n");
        $self->format($self->{totalize_result}{data},
          ["ship_info", "beginning_of_year", "middle_of_year", "end_of_year"], 'imo_dcs');
      }
    } else {
      $self->{log}->Error("there is no target path: %s\n", $annual_tmp);
      croak "there is no required path\n";
    }
  } else {
    $self->{log}->Info("there is no target data\n");
  }
  $self->{log}->Info("End : %s\n", (caller 0)[3]);
  return $self->_exists_result ? $self->{totalize_result} : undef;
}

sub _judge_year_over {
  my $self = shift;
  my $sum_res = shift;
  my $judge_res = 'middle_of_year';

  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  my $voy_start_datetime_str //= $sum_res->{for_row}{data}{dep_date_time};
  my $voy_end_datetime_str   //= $sum_res->{for_row}{data}{arr_date_time};

  if ($voy_start_datetime_str && $voy_end_datetime_str) {
    my $voy_start_year_yyyy = substr($voy_start_datetime_str, 0, 4);
    my $voy_end_year_yyyy   = substr($voy_end_datetime_str,   0, 4);

    $self->{log}->Info("can get all parameter for judge year over, start judge\n");
    if ($voy_start_year_yyyy == ($self->{totalize_year} - 1) && $voy_end_year_yyyy == $self->{totalize_year}) {
      $judge_res = 'beginning_of_year';
    }
    elsif ($voy_start_year_yyyy == $self->{totalize_year} && $voy_end_year_yyyy == ($self->{totalize_year} + 1)) {
      $judge_res = 'end_of_year';
    }
  } else {
    $self->{log}->Error("can not get all parameter for judge year over\n");
  }

  $self->{log}->Info("  judge result: %s\n", $judge_res);
  $self->{log}->Info("End : %s\n", (caller 0)[3]);
  return $judge_res;
}

sub _calc_begin {
  my $self = shift;
  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  my $voy_row_data = shift;
  if (keys(%{$voy_row_data}) >= 1) {

    my $beginning_of_the_year_datetime_str = sprintf("%s-01-01T00:00:00Z", $self->{totalize_year});
    my $voy_start_datetime_str //= $voy_row_data->{dep_date_time};
    my $voy_end_datetime_str   //= $voy_row_data->{arr_date_time};
    if ($voy_start_datetime_str && $voy_end_datetime_str) {

      $self->{log}->Info("calculate waiting factor for a value by the day\n");
      my $secs_under_voyage     = EsmLib::StrToEpoch($voy_end_datetime_str) - EsmLib::StrToEpoch($voy_start_datetime_str);
      my $secs_over_year_voyage = EsmLib::StrToEpoch($voy_end_datetime_str) - EsmLib::StrToEpoch($beginning_of_the_year_datetime_str);
      my $by_the_day_ratio      = $secs_over_year_voyage / $secs_under_voyage;
      $self->{log}->Info("waiting factor => %s\n", $by_the_day_ratio);

      $self->_calc('beginning_of_year', $voy_row_data, $by_the_day_ratio);
    } else {
      $self->{log}->Error("  dep_date_time => %s arr_date_time => %s\n", $voy_start_datetime_str, $voy_end_datetime_str);
      croak "  there is no required parameter\n";
    }
  } else {
    croak "there is no required key\n";
  }
  $self->{log}->Info("End : %s\n", (caller 0)[3]);
}

sub _calc_middle {
  my $self = shift;
  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  my $voy_row_data = shift;
  if (keys(%{$voy_row_data}) >= 1) {

    $self->_calc('middle_of_year', $voy_row_data);
  } else {
    croak "there is no required key\n";
  }
  $self->{log}->Info("End : %s\n", (caller 0)[3]);
}

sub _calc_end {
  my $self = shift;
  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  my $voy_row_data = shift;
  if (keys(%{$voy_row_data}) >= 1) {

    my $beginning_of_the_year_datetime_str = sprintf("%s-01-01T00:00:00Z", $self->{totalize_year} + 1);
    my $voy_start_datetime_str //= $voy_row_data->{dep_date_time};
    my $voy_end_datetime_str   //= $voy_row_data->{arr_date_time};
    if ($voy_start_datetime_str && $voy_end_datetime_str) {

      $self->{log}->Info("calculate waiting factor for a value by the day\n");
      my $secs_under_voyage     = EsmLib::StrToEpoch($voy_end_datetime_str) - EsmLib::StrToEpoch($voy_start_datetime_str);
      my $secs_over_year_voyage = EsmLib::StrToEpoch($voy_end_datetime_str) - EsmLib::StrToEpoch($beginning_of_the_year_datetime_str);
      my $by_the_day_ratio      = $secs_over_year_voyage / $secs_under_voyage;
      $self->{log}->Info("waiting factor => %s\n", $by_the_day_ratio);

      $self->_calc('end_of_year', $voy_row_data, $by_the_day_ratio);
    } else {
      $self->{log}->Error("  dep_date_time => %s arr_date_time => %s\n", $voy_start_datetime_str, $voy_end_datetime_str);
      croak "  there is no required parameter\n";
    }
  } else {
    croak "there is no required key\n";
  }
  $self->{log}->Info("End : %s\n", (caller 0)[3]);
}

sub _calc {
  my $self = shift;
  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  my ($out_str, $voy_row_data, $value_wait) = @_;

  my $out_target = $self->{totalize_result}{data}{$out_str}{data};
  for my $item (keys(%{$voy_row_data})) {

    $self->{log}->Info("item: %s\n", $item);

    if (grep { /^$item$/ } @{$self->{not_totalize_items}}) {
      $self->{log}->Info("  it is not a target\n");
      next;
    }

    if (EsmLib::IsTheNumeric($voy_row_data->{$item})) {
      my $tmp_calc_res = $value_wait ? $voy_row_data->{$item} * $value_wait : $voy_row_data->{$item};
      if (exists $out_target->{$item}) {
        $out_target->{$item} += $tmp_calc_res;
      } else {
        $out_target->{$item} = $tmp_calc_res;
      }
    } else {
      $self->{log}->Info("  it is not a number or undefined\n");
    }
  }
  $self->{log}->Info("End : %s\n", (caller 0)[3]);
}

sub _create_list_for_summary {
  my $self = shift;
  my $calc_list = [];
  my $d = $self->{totalize_result}{data};
  for my $k (keys(%{$d})) {

    if ($k ne "ship_info" && $k ne "summary"
      && scalar(keys(%{$d->{$k}{data}})) >= 1) {

      push @{$calc_list}, $d->{$k}{data};
    }
  }
  return $calc_list;
}

sub _exists_result {
  my $res = FALSE;
  my $data = shift->{totalize_result}->{data};
  if ($data) {
    for my $k (keys(%{$data})) {
      next if $k eq 'ship_info';
      if (scalar(keys(%{$data->{$k}->{data}})) >= 1 ) {
        $res = TRUE;
      }
    }
  }
  return $res;
}

1;