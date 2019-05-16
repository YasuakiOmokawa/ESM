package VoyageRowDataSummarizer;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use constant { TRUE => 1, FALSE => 0, };
use Carp 'croak';

my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";

use parent 'DataSummarizer';
use EsmConf;
use EsmConfigWeb;
use EsmDataDetector;
use EsmLib;
use VoyageEuMrvDataSummarizer;

sub summarize {
  my $self = shift;

  $self->{log}->Info("  Start : %s\n", (caller 0)[3]);

  my $voy_info = shift;
  my $calc_categories = shift;

  my $res;
  my $h = ref($voy_info) eq 'JsonHandler' ? $voy_info : JsonHandler->new($self->{log}, $voy_info);

  my $data = $h->get_data;
  $self->set_judge_result( JsonHandler->new($self->{log}, $data) );

  my $tmp_voy_info = EsmDataDetector::template_voyage_info();
  if (-f $tmp_voy_info) {

    my $voy_jh = JsonHandler->new($self->{log}, $tmp_voy_info);
    $self->set_summarized_data($voy_jh);
    my $voy_res = $voy_jh->get_data->{data};

    # add judge result
    $self->add_judge_result_to_summarize_result;

    # list of voyage summarize
    if ($data->{type} eq "underway") {

      $self->{log}->Info("    summarize type is underway\n");

      $voy_res->{record_type} = "voyage";

      $res = $self->SUPER::summarize($self->get_definition->{data}->{for_row}->{voyage}, undef, 'voyage');
    }
    elsif ($data->{type} eq "in_port") {

      $self->{log}->Info("    summarize type is in_port\n");

      $voy_res->{record_type} = "in_port";

      $res = $self->SUPER::summarize($self->get_definition->{data}->{for_row}->{in_port}, undef, 'in_port');
    }

    # eu mrv summarize
    $self->{log}->Info("    summarize type is eu-mrv\n");

    my $eu_sum = VoyageEuMrvDataSummarizer->new($self->{log});
    $res = $eu_sum->summarize($self->get_summarize_result);
  } else {
    $self->{log}->Error("    template voyage info not found\n");
    croak("    template voyage info not found");
  }

  $self->{log}->Info("    End : %s\n", (caller 0)[3]);

  return $res;
}

sub _calc_efficiency {
  my ($co2_dogo, $co2_hfo, $co2_lfo, $co2_other, $base_data) = @_;

  my $res;

  if (EsmLib::IsTheNumeric($base_data) && $base_data > 0) {

    for my $arg ($co2_dogo, $co2_hfo, $co2_lfo, $co2_other) {

      if (EsmLib::IsTheNumeric($arg)) {
        $res += $arg;
      }
    }
    $res /= $base_data if $res;
  }

  return $res;
}

sub _calc_transport_work {
  my ($dist, $cargo, $passngr, $unit, $cars, $dwt_crd, $vlm) = @_;

  my $res;

  if (EsmLib::IsTheNumeric($dist)) {

    my @match = grep { EsmLib::IsTheNumeric($_) } ($cargo, $passngr, $unit, $cars, $dwt_crd, $vlm);

    if ( @match && scalar(@match) == 1 ) {

      $res = $dist * $match[0];
    }
  }
  return $res;
}

sub _calc_voyage_time {
  my ($voy_minutes, $anch_end_time_str, $anch_start_time_str) = @_;

  my $res;
  $res = ($voy_minutes / 60) if EsmLib::IsTheNumeric($voy_minutes);
  if (EsmLib::IsTheNumeric($voy_minutes) && $anch_end_time_str && $anch_end_time_str ne "none" && $anch_start_time_str && $anch_start_time_str ne "none") {

    $res = ($voy_minutes * 60) - (EsmLib::StrToEpoch($anch_end_time_str) - EsmLib::StrToEpoch($anch_start_time_str));
    $res /= 3600 if $res; # convert hour
  }

  return $res;
}

sub _calc_div {
  my ($a, $b) = @_;

  my $res;
  if (EsmLib::IsTheNumeric($a) && EsmLib::IsTheNumeric($b) && $b > 0) {
    $res = $a / $b;
  }
  return $res;
}



1;