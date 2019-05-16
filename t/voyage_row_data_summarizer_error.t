# $Id: voyage_row_data_summarizer_error.t 35732 2019-01-18 06:02:06Z p0660 $

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
use constant { TRUE => 1, FALSE => 0 };

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
use VoyageRowDataSummarizer;

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

plan skip_all => "summarize voyage template file is valid, skip" if -f EsmDataDetector::template_voyage_info;

# test
subtest "summarize error test" => sub {

  my $voyage_fname = "20181007134907-9aae88abb64f93d5419993194f495c77_20181008013853-f98e4ca0f004c8a676a4e4561585ea62_20181007233907.json";
  my $voyage_path = sprintf("%s/%s", $test_data_dir , $voyage_fname ); 
  my $jh = JsonHandler->new($log, $voyage_path);
  my $jh_result = $jh->get_item(["data", "include_reports"]);

  # 対象クラス・メソッド呼び出し
  my $vrds = VoyageRowDataSummarizer->new($log);

  throws_ok { $vrds->summarize($jh_result) } qr/template voyage info not found/, 'output error info';

  $log->Info("summarize error test log\n");

  done_testing;
};


done_testing;
