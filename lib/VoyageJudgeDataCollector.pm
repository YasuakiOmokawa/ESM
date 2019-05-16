package VoyageJudgeDataCollector;

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

use parent 'JudgeDataCollector';
use EsmConf;
use EsmConfigWeb;
use CheckArgument;
use MonthlyReportHandler;
use JsonHandler;
use DailyReportHandler;


# Static settings
my $top_dir = dirname(__FILE__) . "/..";

sub acquire {
  my $self = shift;
  
  $self->{log}->Info("  Start : %s\n", (caller 0)[3]);

  if ($self->_create_data) {
    
    # extract data for judge voyage
    $self->_extract_judge_report;
  }

  $self->{log}->Info("  End : %s\n", (caller 0)[3]);
}

sub _seek_the_year {
  my $self = shift;
  
  my ($root, $year) = @_;
  
  my $search_path = sprintf("%s/%s", $root, $year);
  
  return $self->_get_data($search_path);
}

sub _seek_last_year {
  my $self = shift;
  
  my ($root, $year) = @_;
  
  return $self->_seek_the_year($root, $year - 1);
  
}

sub _seek_next_year {
  my $self = shift;
  
  my ($root, $year) = @_;
  
  return $self->_seek_the_year($root, $year + 1);
  
}

sub _extract_judge_report {
  my $self = shift;
  
  my @res = grep {
    my $h = JsonHandler->new($self->{log}, $_);
    my $d = DailyReportHandler->new($self->{log}, $h);
    $d->get_for_judge_voyage && !$d->is_invalid
  } @{$self->{data_group}};
  
  $self->{data_group} = \@res;
}

sub get_collector_result {
  my $self = shift;
  
  return $self->{data_group};
}

sub _get_data {
  my $self = shift;
  
  my $path = shift;
  
  my $res = FALSE;

  $self->{log}->Info("      seek path: %s\n", $path);
  
  my $exp = sprintf("%s/*.json", $path);
  my @files = glob($exp);

  if (@files) {
    
    $self->{log}->Info("      search file found.\n");

    foreach my $file (@files) {
      
      $self->{log}->Info("      open file: %s\n", $file) if $EsmConf::IS_DEV;

      my $jh = JsonHandler->new($self->{log}, $file);
  
      my $mh = MonthlyReportHandler->new($self->{log}, $jh);
      
      $self->add_acquired_data($mh->get_monthly_data);
      
      $res = TRUE;
    }
  } else {
    $self->{log}->Info("      search file not found.\n");
  }
  
  return $res;
}

sub _create_data {
  my $self = shift;
  
  my $res = FALSE;
  my $client_code = $self->{source}->get_client_code;
  my $imo_no = $self->{source}->get_imo_number;
  my $year = $self->{source}->get_report_year;
  
  # required parameter check
  my $params = {
    client_code => $client_code,
    imo_no => $imo_no,
    year => $year,
  };
  
  if (CheckArgument::check_argument($params, $self->{log})) {
    
    my $monthly_report_root_dir = sprintf("%s/data/esm3_daily/%s/%s", $top_dir, $client_code, $imo_no);
       
    # get last year data
    $self->{log}->Info("    get last year data start\n");
    $self->_seek_last_year($monthly_report_root_dir, $year);
    
    # get year data
    $self->{log}->Info("    get year data start\n");
    $self->_seek_the_year($monthly_report_root_dir, $year);
  
    # get next year data
    $self->{log}->Info("    get next year data start\n");
    $self->_seek_next_year($monthly_report_root_dir, $year);
    
    $res = TRUE;
  }
  
  return $res;
}

1;