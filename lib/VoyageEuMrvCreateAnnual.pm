package VoyageEuMrvCreateAnnual;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use constant { TRUE => 1,
  FALSE => 0,
  COEF_DOGO => 3.206,
  COEF_LFO => 3.114,
  COEF_HFO => 3.151,
};

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

sub totalize {
  my $self = shift;

  $self->{log}->Info("  Start : %s\n", (caller 0)[3]);

  my $result;

  my $def_path = EsmDataDetector::template_eu_mrv_annual;
  if (-f $def_path) {

    my $def_jh = JsonHandler->new($self->{log}, $def_path);

    my $out_def = [
      { key => "in_port-in_eu_port",       output_target => ["data", "in_port", "data"] },
      { key => "voyage-dep_from_eu_port",  output_target => ["data", "dep_from_eu_port", "data"] },
      { key => "voyage-arr_at_eu_port",    output_target => ["data", "arr_at_eu_port", "data"] },
      { key => "voyage-eu_to_eu",          output_target => ["data", "eu_to_eu", "data"] }
    ];

    my $not_totalize_items = [
      "voyage_number",
      "eu_mrv",
      "dep_port",
      "dep_date_time",
      "arr_port",
      "arr_date_time",
#       "distance_travelled",
#       "time_at_sea",
      "hours_underway",
#       "foc_dogo",
#       "foc_lfo",
#       "foc_hfo",
#       "foc_other",
      "co2_dogo",
      "co2_lfo",
      "co2_hfo",
      # "co2_other",
      # "cargo_weight",
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

    # totalize start
    $self->{log}->Info("    totalize start\n");
    my @tmp_out;
    for my $info (@{$self->{summarize_result_group}}) {

      my $rt = $info->{data};
      $def_jh->set_item(['data', 'ship_info'], $rt->{include_reports}->{ship_info}) if !$def_jh->get_item(['data', 'ship_info']);

      my $key = $rt->{record_type} . "-" . $rt->{for_row}{data}{eu_mrv};
      $self->{log}->Info("      output def key : %s\n", $key);
      my @mtch;
      @mtch = grep { $_->{key} eq $key } @{$out_def};
      if (@mtch) {

        my $str;
        my @arr = @{$mtch[0]->{output_target}};
        for my $i (@arr) {
          $str .= "{$i}";
        }
        @tmp_out = @{$mtch[0]->{output_target}};

        $self->{log}->Info("        output target : %s\n", $str);

        my $res_data = $def_jh->get_item(\@tmp_out);
        my $voy_data = $rt->{for_row}{data};

        $self->{log}->Info("        add item : %s", Dumper $voy_data);

        my $res; $res = $self->calc_total([$res_data, $voy_data], $not_totalize_items);
        if (%{$res}) {

          @tmp_out = @{$mtch[0]->{output_target}};
          $def_jh->set_item(\@tmp_out, $res);
          $self->{log}->Info("        result item found\n");
          $self->{log}->Info("        add result : %s", Dumper $res);
        } else {
          $self->{log}->Info("        result item not found\n", $str);
        }
      } else {
        $self->{log}->Info("        output def key not match\n");
      }
    }

    # formatter value start
    my $d = $def_jh->get_data->{data};

    $self->{log}->Info("    format value start (No.1)\n");

    $self->format($d, ["ship_info", "summary"], 'eu_mrv');

    # totalize summary start
    $self->{log}->Info("    totalize summary start\n");

    my $calc_list = [];
    for my $k (keys(%{$d})) {
      if ($k ne "ship_info" && $k ne "summary") {
        push @{$calc_list}, $d->{$k}->{data};
      }
    }

    my $sum_res; $sum_res = $self->calc_total($calc_list, $not_totalize_items);
    if (scalar(keys(%{$sum_res})) >= 1) {

      $self->{log}->Info("      totalize summary success\n");
      $def_jh->set_item(['data', 'summary', 'data'], $sum_res);
      $result = $def_jh->get_data;

      # format check
      $self->{log}->Info("      format value start (No.2)\n");
      $self->format($d, ["ship_info", "dep_from_eu_port", "arr_at_eu_port", "in_port", "eu_to_eu"], 'eu_mrv');

      # calculation
      $self->{log}->Info("      calculate start\n");
      $self->_calculate($d, ["ship_info"]);

      # format check
      $self->{log}->Info("      format value start (last)\n");
      $self->format($d, ["ship_info"], 'eu_mrv');
      # print Dumper $d;
    } else {
      $self->{log}->Info("      totalize summary failed\n");
    }
  } else {
    $self->{log}->Info("      def path not found : %s\n", $def_path);
  }

  $self->{log}->Info("  End : %s\n", (caller 0)[3]);
  return $result;
}

sub _calculate {
  my $self = shift;
  my $d = shift;
  my $black_list = shift;

  for my $k (keys(%{$d})) {

    if (!grep { /^$k$/ } @$black_list ) {

      $self->{log}->Info("        category => %s\n", $k);

      my $datas = $d->{$k}->{data};
      my $param = {};

      # initial parameter set
      $param->{foc_dogo}           = _exists($datas, "foc_dogo");
      $param->{foc_lfo}            = _exists($datas, "foc_lfo");
      $param->{foc_hfo}            = _exists($datas, "foc_hfo");
      $param->{foc_other}          = _exists($datas, "foc_other");
      $param->{co2_other}          = _exists($datas, "co2_other");
      $param->{distance_travelled} = _exists($datas, "distance_travelled");
      $param->{cargo_weight}       = _exists($datas, "cargo_weight");

      while (my ($i, $v) = (each(%{$param}))) {
        $self->{log}->Info("          key => %s, value => %s\n", $i, $v);
      }

      # calc and set co2
      $self->_set($datas, "co2_dogo", EsmLib::CalcMulti($param->{foc_dogo}, COEF_DOGO));
      $self->_set($datas, "co2_lfo", EsmLib::CalcMulti($param->{foc_lfo}, COEF_LFO));
      $self->_set($datas, "co2_hfo", EsmLib::CalcMulti($param->{foc_hfo}, COEF_HFO));

      # calc and set transport_work
      $self->_set($datas, "transport_work", EsmLib::CalcMulti($param->{distance_travelled}, $param->{cargo_weight}));

      # addition parameter set
      $param->{co2_dogo}       = _exists($datas, "co2_dogo");
      $param->{co2_lfo}        = _exists($datas, "co2_lfo");
      $param->{co2_hfo}        = _exists($datas, "co2_hfo");
      $param->{transport_work} = _exists($datas, "transport_work");

      # calc and set foc_per_distance
      $self->_set($datas, "foc_dogo_per_distance", VoyageRowDataSummarizer::_calc_div($param->{foc_dogo}, $param->{distance_travelled}));
      $self->_set($datas, "foc_lfo_per_distance", VoyageRowDataSummarizer::_calc_div($param->{foc_lfo}, $param->{distance_travelled}));
      $self->_set($datas, "foc_hfo_per_distance", VoyageRowDataSummarizer::_calc_div($param->{foc_hfo}, $param->{distance_travelled}));
      $self->_set($datas, "foc_other_per_distance", VoyageRowDataSummarizer::_calc_div($param->{foc_other}, $param->{distance_travelled}));

      # calc and set foc_per_transport_work
      $self->_set($datas, "foc_dogo_per_transport_work", VoyageRowDataSummarizer::_calc_div($param->{foc_dogo}, $param->{transport_work}));
      $self->_set($datas, "foc_lfo_per_transport_work", VoyageRowDataSummarizer::_calc_div($param->{foc_lfo}, $param->{transport_work}));
      $self->_set($datas, "foc_hfo_per_transport_work", VoyageRowDataSummarizer::_calc_div($param->{foc_hfo}, $param->{transport_work}));
      $self->_set($datas, "foc_other_per_transport_work", VoyageRowDataSummarizer::_calc_div($param->{foc_other}, $param->{transport_work}));

      # calc and set co2_per_distance
      $self->_set($datas, "co2_per_distance", VoyageRowDataSummarizer::_calc_efficiency($param->{co2_dogo}, $param->{co2_lfo},
        $param->{co2_hfo}, $param->{co2_other}, $param->{distance_travelled}));

      # calc and set eeoi
      $self->_set($datas, "eeoi", VoyageRowDataSummarizer::_calc_efficiency($param->{co2_dogo}, $param->{co2_lfo},
        $param->{co2_hfo}, $param->{co2_other}, $param->{transport_work}));
    }
  }
}

sub _exists {
  my ($d, $i) = @_;
  return exists $d->{$i} ? $d->{$i} : "";
}

sub _set {
  my $self = shift;
  my ($d, $i, $r) = @_;

  my $msg = "            key => %s, calc_result => %s";
  if (EsmLib::IsTheNumeric($r)) {
    $d->{$i} = $r;
  } else {
    $msg .= ", do not add invalid result";
  }
  $self->{log}->Info("$msg\n", $i, $r);
}

1;