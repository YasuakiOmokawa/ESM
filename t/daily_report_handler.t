# $Id: daily_report_handler.t 35732 2019-01-18 06:02:06Z p0660 $

use strict;
use warnings;

use Capture::Tiny qw/ capture /;
use Test::More;
use Test::Exception;
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


# test module
use DailyReportHandler;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $debug_path = '/usr/home/partner/p0562/test_data_v3/';
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;
my $test_data_dir = "$top_dir/t/data/$prog_base";
my $test_out_dir = "$top_dir/t/out";

my $log  = logging->Open( $log_fname ) ;

# test
subtest "No.1 new" => sub {

  my $tst_file = 'd1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # newできているか確認
  ok($dh,'new ok');
  done_testing;
};

subtest "No.2 & No.17 get_client_code" => sub {

  my $tst_file = 'd1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化（JsonHandlerを引数）
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # client codeを想定通り取得しているかの確認（最終要素の確認含む）
  is($dh->get_client_code,'MOL','client code is ok');
  done_testing;
};

subtest "No.3 get_client_code" => sub {

  my $tst_file = 'd9.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});

  # client codeを取得しないことの確認
  my ($stdout, $strerr) = capture {
    is($dh->get_client_code,undef,'client code is undef');
  };
  like($strerr, qr/Use of uninitialized value/, 'wrn msg is ok');
  done_testing;
};

subtest "No.4 get_report_year" => sub {

  my $tst_file = 'd2.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  
  # テストデータのインスタンス化（ファイルパスを引数）
  my $dh = DailyReportHandler->new($log, $tst_file_path);
  
  # report yearを想定通り取得しているかの確認
  is($dh->get_report_year,'2020','report year is ok');
  done_testing;
};

subtest "No.5 get_report_year" => sub {

  my $tst_file = 'd9.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # report yearを取得しないことの確認
  my ($stdout, $strerr) = capture {
    is($dh->get_report_year,'','report year is \'\'');
  };
  like($strerr, qr/Use of uninitialized value/, 'wrn msg is ok');
  done_testing;
};

subtest "No.6 get_message_id" => sub {

  my $tst_file = 'd1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # message idを想定通り取得しているかの確認
  is($dh->get_message_id,'20181009083745-DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD','message id is ok');
  done_testing;
};

subtest "No.7 & No.18 get_message_id" => sub {

  my $tst_file = 'm1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # message idを想定通り取得しているかの確認
  is($dh->get_message_id,'20180203124754-MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM','message id is ok');
  done_testing;
};

subtest "No.8 get_message_id" => sub {

  my $tst_file = 'd9.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # message idを取得しないことの確認
  is($dh->get_message_id,undef,'message id is undef');
  done_testing;
};

subtest "No.9 get_latest_report_time" => sub {

  my $tst_file = 'd1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # latest report timeを想定通り取得しているかの確認（customs->exec_time）
  is($dh->get_latest_report_time,'2018-10-15T00:00:00Z','latest report time is ok');
  done_testing;
};

subtest "No.10 get_latest_report_time" => sub {

  my $tst_file = 'm1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # latest report timeを想定通り取得しているかの確認（report_info->updated_at）
  is($dh->get_latest_report_time,'2018-10-20T00:00:00Z','latest report time is ok');
  done_testing;
};

subtest "No.11 get_latest_report_time" => sub {

  my $tst_file = 'd3.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # latest report timeを想定通り取得しているかの確認（customs->exec_time＞report_info->updated_at）
  is($dh->get_latest_report_time,'2018-10-25T00:00:00Z','latest report time is ok');
  done_testing;
};

subtest "No.12 get_latest_report_time" => sub {

  my $tst_file = 'd4.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # latest report timeを想定通り取得しているかの確認（customs->exec_time＜report_info->updated_at）
  is($dh->get_latest_report_time,'2018-10-30T00:00:00Z','latest report time is ok');
  done_testing;
};

subtest "No.13 get_latest_report_time" => sub {

  my $tst_file = 'd9.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化（JsonHandlerを引数）
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # latest report timeを取得しないことの確認
  is($dh->get_latest_report_time,undef,'latest report time is undef');
  done_testing;
};

subtest "No.14 is_invalid" => sub {

  my $tst_file = 'd1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化（JsonHandlerを引数）
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # is invalidの設定値を確認
  is($dh->is_invalid,TRUE,'is_invalid is ok');
  done_testing;
};

subtest "No.15 is_invalid" => sub {

  my $tst_file = 'd3.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化（JsonHandlerを引数）
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # is invalidの設定値を確認
  is($dh->is_invalid,FALSE,'is_invalid is ok');
  done_testing;
};

subtest "No.16 is_invalid" => sub {

  my $tst_file = 'd9.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化（JsonHandlerを引数）
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # is invalidの設定値を確認
  is($dh->is_invalid,FALSE,'is_invalid is ok');
  done_testing;
};

subtest "No.19 set_report_value" => sub {

  my $tst_file = 'd5.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化（JsonHandlerを引数）
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # 値がセットされることの確認
  $dh->set_report_value( ["calc", "input_test"],"written by test 1");
  is($jh->{data}->{data}[1]->{calc}->{input_test},'written by test 1','set_report_value is ok');
  done_testing;
};

subtest "No.20 set_report_value" => sub {

  my $tst_file = 'm2.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化（JsonHandlerを引数）
  my $dh = DailyReportHandler->new($log, $jh->{data});
  
  # 値がセットされることの確認
  $dh->set_report_value( ["calc", "input_test"],"written by test 2");
  is($jh->{data}->{calc}->{input_test},'written by test 2','set_report_value is ok');
  done_testing;
};

done_testing;