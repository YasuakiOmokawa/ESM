package VoyageDataDailyChangeReSummarizer;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use constant { TRUE => 1, FALSE => 0, };

my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";

use parent 'DataSummarizer';
use EsmConf;
use EsmConfigWeb;
use VoyageJudgeHandler;
use EsmDataDetector;
use EsmLib;
use VoyageEuMrvDataSummarizer;
use VoyageRowDataSummarizer;

sub summarize {
  my $self = shift;

  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  my $voy_info = shift;
  my $calc_categories = shift;
  my $recalc_items = shift;

  my $res;
  my $h = ref($voy_info) eq 'JsonHandler' ? $voy_info : JsonHandler->new($self->{log}, $voy_info);
  $self->set_summarized_data($h);

  my $data = $h->get_item(["data"]);
  $self->set_judge_result( JsonHandler->new($self->{log}, $data->{include_reports}) );

  # list of voyage summarize
  if ($data->{include_reports}->{type} eq "underway") {

    $self->{log}->Info("  re-summarize type is underway\n");

    $data->{record_type} = "voyage";

    $res = $self->SUPER::summarize($self->get_definition->{data}->{for_row}->{voyage}, $calc_categories, 'voyage', $recalc_items);
  }
  elsif ($data->{include_reports}->{type} eq "in_port") {

    $self->{log}->Info("  re-summarize type is in_port\n");

    $data->{record_type} = "in_port";

    $res = $self->SUPER::summarize($self->get_definition->{data}->{for_row}->{in_port}, $calc_categories, 'in_port', $recalc_items);
  }

  # eu mrv summarize
  $self->{log}->Info("  re-summarize type is eu-mrv\n");

  my $eu_sum = VoyageEuMrvDataSummarizer->new($self->{log});
  $res = $eu_sum->summarize($self->get_summarize_result);

  $self->{log}->Info("End : %s\n", (caller 0)[3]);

  return $res;
}


1;