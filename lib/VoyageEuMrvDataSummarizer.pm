package VoyageEuMrvDataSummarizer;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use constant { TRUE => 1, FALSE => 0, ZERO_BUT_TRUE => 'ZERO_BUT_TRUE' };

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

sub summarize {
  my $self = shift;
  
  my $voy_info = shift;
  
  $self->{log}->Info("    Start : %s\n", (caller 0)[3]);

  my $h = ref($voy_info) eq 'JsonHandler' ? $voy_info : JsonHandler->new($self->{log}, $voy_info);
  $self->set_summarized_data($h);
  $self->set_judge_result( JsonHandler->new($self->{log}, $h->get_item(["data", "include_reports"])) );
  
  my $res = $self->SUPER::summarize($self->get_definition->{data}->{for_annual}->{eu_mrv});
  
  $self->{log}->Info("    End : %s\n", (caller 0)[3]);
  return $res;
}

sub _calc_voyage_type {
  my ($type, $from_port_code, $to_port_code) = @_;
  
  my $wni_port_list = EsmDataDetector::wni_port_list();
  my $eu_country = EsmDataDetector::eu_country();
  
  my $list;
  EsmLib::LoadJson($wni_port_list, \$list);
  
  my $eu;
  EsmLib::LoadJson($eu_country, \$eu);
  
  my ($from_eu, $to_eu) = (FALSE, FALSE);
  if ($from_port_code) {
    
    my @s = grep { $_->{AREA} eq $from_port_code } @$list;
    if (@s && $eu->{$s[0]->{CNTRY}}) {
      $from_eu = TRUE;
    }
  } 
  if ($to_port_code) {
    
    my @l = grep { $_->{AREA} eq $to_port_code } @$list;
    if (@l && $eu->{$l[0]->{CNTRY}}) {
      $to_eu = TRUE;
    }
  }
  
  # judge
  my $res = $type eq "voyage" && $from_eu && !$to_eu   ? "dep_from_eu_port"
          : $type eq "voyage" && !$from_eu && $to_eu   ? "arr_at_eu_port"
          : $type eq "voyage" && $from_eu && $to_eu    ? "eu_to_eu"
          : $type eq "in_port" && ($from_eu || $to_eu) ? "in_eu_port"
          : "no_eu";

  return $res;
}

1;