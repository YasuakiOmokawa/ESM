# $Id: voyage_judge_data_collector.t 35732 2019-01-18 06:02:06Z p0660 $

use strict;
use warnings;

use Capture::Tiny qw/ capture /;
use Test::More;
use Test::Exception;
use JSON;
use Data::Dumper;
use Benchmark;
use File::Basename;
use POSIX qw(strftime);

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";
use lib '/usr/amoeba/lib/perl';

use logging;
use EsmDataDetector;
use JsonHandler;
use DailyReportHandler;
use EsmLib;


# test module
use VoyageJudgeDataCollector;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;
my $test_data_dir = "$top_dir/t/data/$prog_base";

my $log  = logging->Open( $log_fname );

# test
subtest "acquire normal sysytem test" => sub {

  my $daily_path = sprintf("%s/daily_report.json", $test_data_dir); 
  my $drh = DailyReportHandler->new($log, $daily_path);
  my $vjdc = VoyageJudgeDataCollector->new($log, $drh);
  lives_ok( sub { $vjdc->acquire(); }, 'acquire ok');

  my $result_data = $vjdc->get_collector_result();

  $log->Info("acquire normal sysytem test log\n");

  my $tmpPath = sprintf("%s/output/%s.output",$test_data_dir, $prog_base);
  open(FH, ">$tmpPath");
  print FH JSON->new->utf8(0)->encode($result_data);
  close(FH);

  done_testing;
};

subtest "acquire param nothing test" => sub {

  my $daily_path = sprintf("%s/daily_report_2.json", $test_data_dir); 
  my $drh = DailyReportHandler->new($log, $daily_path);
  my $vjdc = VoyageJudgeDataCollector->new($log, $drh);
  lives_ok( sub { $vjdc->acquire(); }, 'acquire ok');

  $log->Info("acquire param nothing test\n");

  done_testing;
};

subtest "acquire target year nothing test" => sub {

  my $daily_path = sprintf("%s/daily_report_3.json", $test_data_dir); 
  my $drh = DailyReportHandler->new($log, $daily_path);
  my $vjdc = VoyageJudgeDataCollector->new($log, $drh);
  lives_ok( sub { $vjdc->acquire(); }, 'acquire ok');

  $log->Info("acquire target year nothing test\n");

  done_testing;
};

subtest "acquire Fault test" => sub {

  my $daily_path = sprintf("%s/daily_report_4.json", $test_data_dir); 
  my $drh = DailyReportHandler->new($log, $daily_path);
  my $vjdc = VoyageJudgeDataCollector->new($log, $drh);
  lives_ok( sub { $vjdc->acquire(); }, 'acquire ok');

  my $result_data = $vjdc->get_collector_result();
  my $tmpPath = sprintf("%s/output/%s_fault_test.output",$test_data_dir, $prog_base);
  open(FH, ">$tmpPath");
  print FH JSON->new->utf8(0)->encode($result_data);
  close(FH);

  $log->Info("acquire Fault test\n");

  done_testing;
};

done_testing;
