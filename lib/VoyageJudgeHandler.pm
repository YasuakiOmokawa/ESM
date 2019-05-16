package VoyageJudgeHandler;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use constant { TRUE => 1, FALSE => 0 };

my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";

use EsmLib;
use DailyReportHandler;
use JsonHandler;


sub new {
  my ($class, $log, $data) = @_;

  $data = ref($data) eq "JsonHandler" ? $data : JsonHandler->new($log, $data);

  my $self = bless {
    log => $log,
    data => $data
  }, $class;

  return $self;
}

sub get_voyage_key {
  my $self = shift;

  my @datas = ($self->{data}->get_data->{from}, $self->{data}->get_data->{to});
  my @msg = ();
  for my $d (@datas) {

    my $dh = DailyReportHandler->new($self->{log}, $d);
    my $msg = $dh->get_message_id;
    push @msg, defined $msg ? $msg : "None";
  }

  my $voyage_key = $msg[0] . "_" . $msg[1];

  return $voyage_key;
}

sub get_from_data {
  my $self = shift;

  my $res;
  $res = $self->{data}->get_data->{from};
  return $res if $res;
}

sub get_to_data {
  my $self = shift;

  my $res;
  $res = $self->{data}->get_data->{to};
  return $res if $res;
}

sub get_index_file_name {
  my $self = shift;

  my ($from, $to, $type, $sort) = ("", "", $self->{data}->get_data->{type}, "");

  my $dh = DailyReportHandler->new($self->{log}, $self->get_to_data);

  $from = $dh->get_start_time;
  $to = $dh->get_report_time;
  $sort = $type eq "underway" ? "0" : "9";

  my $fmt = "%Y%m%d%H%M%S";
  my $from_fmt = EsmLib::EpochToStr(EsmLib::StrToEpoch($from), $fmt);
  my $to_fmt = EsmLib::EpochToStr(EsmLib::StrToEpoch($to), $fmt);
  my $index_name = sprintf("%s_%s_%s.json", $from_fmt, $to_fmt, $sort);

  return $index_name;
}

sub get_latest_time {
  my $self = shift;

  $self->{log}->Info("  Start : %s\n", (caller 0)[3]);

  my $value = FALSE;

  my $reps = $self->get_all_reports;
  if (@{$reps}) {

    my @latest_times = map {
      my @v = values(%{$_});
      my $drh = DailyReportHandler->new($self->{log}, $v[0]);
      $drh->get_latest_report_time();
    } @{$reps};

    if (@latest_times) {
      @latest_times = sort {EsmLib::StrToEpoch($b) <=> EsmLib::StrToEpoch($a)} @latest_times;

      $value = shift @latest_times;
    }
  } else {
    $self->{log}->Info("    report not contained\n");
  }

  $self->{log}->Info("    latest time => %s\n", $value);

  $self->{log}->Info("  End : %s\n", (caller 0)[3]);

  return  $value;
}

sub get_additional_data {
  my $self = shift;

  return $self->{data}->get_data->{addition_report};
}

sub upsert_report {
  my $self = shift;

  my $res = FALSE;

  $self->{log}->Info("  Start : %s\n", (caller 0)[3]);

  my $data = shift;

  if ($data) {

    my $new_dh = DailyReportHandler->new($self->{log}, $data);
    my $msg_id = $new_dh->get_message_id;
    my $n_k = $new_dh->get_for_judge_voyage;

    $self->{log}->Info("    param message id: %s\n", $msg_id);

    # all report search
    my $reps = $self->get_all_reports(1);
    for my $d (0..$#{$reps}) {

      my $dh = DailyReportHandler->new($self->{log}, values(%{$reps->[$d]}));

      $self->{log}->Info("    voyage contain message id: %s\n", $dh->get_message_id);

      if ($msg_id eq $dh->get_message_id) {

        my @k = keys(%{$reps->[$d]});
        my $k = $k[0];
        $self->{log}->Info("    report match, contain key: %s\n", $k);

        if ($k eq "from" || $k eq "to") {

          $self->{log}->Info("      replace report : %s \n", $k);
          $self->{data}->get_data->{$k} = $data;

          $res = TRUE; last;
        } else {

          # replace report
          $self->{log}->Info("      replace addition report\n");
          $self->get_additional_data->[$d - 2] = {$k => $data};

          $res = TRUE; last;
        }
      } else {
        $self->{log}->Info("      unmatch message id\n");
      }
    }

    if ($self->get_additional_data && !$res) {

      $self->{log}->Info("    all unmatch, add new addition report\n");
      push @{$self->get_additional_data}, {$n_k => $data};
      $res = TRUE;
    }

    if (!$self->get_additional_data && !$res) {

      $self->{log}->Info("    already addition data not found, add new addition report\n");
      $self->{data}->get_data->{addition_report} = [{$n_k => $data}];
      $res = TRUE;
    }
  } else {
    $self->{log}->Error("    update data not found\n");
  }

  $self->{log}->Info("  End : %s\n", (caller 0)[3]);

  return $res;
}

sub get_all_reports {
  my $self = shift;

  my $srch_flg = shift;

  my $value = [];

  if ($self->get_from_data) {

    my $dhf = DailyReportHandler->new($self->{log}, $self->get_from_data);
    my $key = $srch_flg ? "from" : $dhf->get_for_judge_voyage;
    push @{$value}, {$key => $self->get_from_data} unless $dhf->is_invalid;
  }

  if ($self->get_to_data) {

    my $dhf = DailyReportHandler->new($self->{log}, $self->get_to_data);
    my $key = $srch_flg ? "to" : $dhf->get_for_judge_voyage;
    push @{$value}, {$key => $self->get_to_data} unless $dhf->is_invalid;
  }

  if ($self->get_additional_data) {

    for my $d (@{$self->get_additional_data}) {
      my @v = values(%{$d});
      my $dhf = DailyReportHandler->new($self->{log}, $v[0]);
      push @{$value}, $d unless $dhf->is_invalid;
    }
  }

  return $value;
}

sub convert_start_time {
  my $self = shift;

  my $type = $self->{data}->get_data->{type};
  my $t_dh = DailyReportHandler->new($self->{log}, $self->get_to_data);

  if ($type eq 'underway' && !($t_dh->get_esm_version && $t_dh->get_esm_version eq '3.00')) {
    $self->{log}->Info("    this type of underway(it means voyage) must convert from time\n");
    my $f_dh;
    $f_dh = DailyReportHandler->new($self->{log}, $self->get_from_data) if $self->get_from_data;
    $self->{log}->Info("      before convert from time : %s \n", $t_dh->get_start_time);
    my $v = $f_dh && $f_dh->get_report_time ? $f_dh->get_report_time : "";
    $self->{log}->Info("      converted from time      : %s \n", $v);
    $t_dh->set_report_value(["calc", "start_time"], $v);
  }
}

sub is_correct_index_file_name {
  my $self = shift;

  my $res = FALSE;
  my @idx = split /_/, $self->get_index_file_name;
  if ($idx[0] && $idx[1]) {
    $res = TRUE;
  }
  return $res;
}

1;