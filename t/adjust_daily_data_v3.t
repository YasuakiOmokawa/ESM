# $Id: adjust_daily_data_v3.t 36271 2019-03-18 01:16:27Z p0660 $

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
subtest "main normal system test 1" => sub {

  # m列、No1,4,6,17,19
  # 実施前[/usr/amoeba/pub/b/ESM/data/esm3_daily/MOL/9876543/2018/10.json]削除
  $log->Info("main normal system test 1 start log\n");

  my $batch = "$top_dir/bin/daily/adjust_daily_data_v3.pl";

  my $rep_json = "$test_data_dir/20181009030000_008.json";

  my @cmd = ($batch, $rep_json);

  #結果チェック １：対象プログラム起動 ２：結果 ３：terminal出力
  is(system(@cmd), 0, 'main normal system test 1 result ok');

  $log->Info("main normal system test 1 end log\n");

  done_testing;
};

subtest "main normal system test 2" => sub {

  # m列、No3,5,7,9,12,14,16,18,20
  # 既に月次dailyデータが存在する事が前提となる
  $log->Info("main normal system test 2 start log\n");

  my $batch = "$top_dir/bin/daily/adjust_daily_data_v3.pl";

  my $rep_json = "$test_data_dir/20181010013000_021.json";

  my @cmd = ($batch, $rep_json);

  # diag関数 診断メッセージ出力
  # 結果チェック １：対象プログラム起動 ２：結果 ３：terminal出力
  diag("The following messages are irrelevant to the results of the exam.");
  is(system(@cmd), 0, 'main normal system test 2 result ok');

  $log->Info("main normal system test 2 end log\n");

  done_testing;
};

subtest "main normal system test 3" => sub {

  # m列、No10
  # 既に月次dailyデータが存在する事が前提となる
  $log->Info("main normal system test 3 start log\n");

  my $batch = "$top_dir/bin/daily/adjust_daily_data_v3.pl";

  my $rep_json = "$test_data_dir/20180903204200_002.json";

  my @cmd = ($batch, $rep_json);

  # diag関数 診断メッセージ出力
  # 結果チェック １：対象プログラム起動 ２：結果 ３：terminal出力
  diag("The following messages are irrelevant to the results of the exam.");
  is(system(@cmd), 0, 'main normal system test 3 result ok');

  $log->Info("main normal system test 3 end log\n");

  done_testing;
};

subtest "main normal system test 4" => sub {

  # m列、No11,13
  # 既に月次dailyデータが存在する事が前提となる.また月次dailyデータの{report_info}{updated_at}は削除する事
  $log->Info("main normal system test 4 start log\n");

  my $batch = "$top_dir/bin/daily/adjust_daily_data_v3.pl";

  my $rep_json = "$test_data_dir/20180802153000_002.json";

  my @cmd = ($batch, $rep_json);

  #結果チェック １：対象プログラム起動 ２：結果 ３：terminal出力
  is(system(@cmd), 0, 'main normal system test 4 result ok');

  $log->Info("main normal system test 4 end log\n");

  done_testing;
};

subtest "main normal system test 5" => sub {

  # m列、No8
  # 既に月次dailyデータが存在する事が前提となる
  $log->Info("main normal system test 5 start log\n");

  my $batch = "$top_dir/bin/daily/adjust_daily_data_v3.pl";

  my $rep_json = "$test_data_dir/20180920134200_002.json";

  my @cmd = ($batch, $rep_json);

  #結果チェック １：対象プログラム起動 ２：結果 ３：terminal出力
  is(system(@cmd), 0, 'main normal system test 5 result ok');

  $log->Info("main normal system test 5 end log\n");

  done_testing;
};

subtest "main error test 1" => sub {

  # m列、No2
  $log->Info("main error test 1 start log\n");

  my $batch = "$top_dir/bin/daily/adjust_daily_data_v3.pl";

  my $rep_json = "$test_data_dir/20181012060000_019.json";

  my @cmd = ($batch, $rep_json);

  #結果チェック １：対象プログラム起動 ２：結果 ３：terminal出力
  is(system(@cmd), 0, 'main error test 1 result ok');

  $log->Info("main error test 1 end log\n");

  done_testing;
};

done_testing;
