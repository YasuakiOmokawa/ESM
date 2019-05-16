# $Id: monthly_report_handler.t 35732 2019-01-18 06:02:06Z p0660 $

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
use MonthlyReportHandler;

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

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $mh = MonthlyReportHandler->new($log, $jh->{data});
  
  # newできているか確認
  ok($mh,'new ok');
  done_testing;
};

subtest "No.3 search_data" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化（JsonHandlerを引数）
  my $mh = MonthlyReportHandler->new($log, $jh->{data});
  
  # message id, report_type_idが一致する1つ目のレポートを取得しているかの確認
  my $get_report = $mh->search_data("20181011093040-99999999999999999999999999999999", "002");
  is($get_report->{report_info}->{messageid},'20181011093040-99999999999999999999999999999999','message id is match');
  is($get_report->{dgc}->{DRER013}->{result},'na','get report is ok');
  is($get_report->{report_info}->{report_type_id},'002','report type id is match');
  done_testing;
};

subtest "No.4 search_data" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  
  # テストデータのインスタンス化（ファイルパスを引数）
  my $mh = MonthlyReportHandler->new($log, $tst_file_path);
  
  # message id, report_type_idが一致する1つ目のレポートを取得しているかの確認
  my $get_report = $mh->search_data("20181011093040-99999999999999999999999999999999", "002");
  is($get_report->{report_info}->{messageid},'20181011093040-99999999999999999999999999999999','message id is match');
  is($get_report->{dgc}->{DRER013}->{result},'na','get report is ok');
  is($get_report->{report_info}->{report_type_id},'002','report type id is match');
  done_testing;
};

subtest "No.5 search_data" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $mh = MonthlyReportHandler->new($log, $jh->{data});
  
  # レポートを取得しないことの確認
  my $get_report = $mh->search_data("20181011093040-9999999999999999999999999999999X", "002");
  is($get_report,undef,'report is undef');
  is($get_report->{report_info}->{messageid},undef,'messsage id is undef');
  done_testing;
};

subtest "No.6 search_data" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $mh = MonthlyReportHandler->new($log, $jh->{data});
  
  # レポートを取得しないことの確認
  my ($stdout, $strerr) = capture {
    my $get_report = $mh->search_data('', '002');
    is($get_report,undef,'report is undef');
    is($get_report->{report_info}->{messageid},undef,'messsage id is undef');
  };
  like($strerr, qr/there is undefined parameter/, 'err msg is ok');
  done_testing;
};

subtest "No.7 search_data" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $mh = MonthlyReportHandler->new($log, $jh->{data});
  
  # レポートを取得しないことの確認
  my $get_report = $mh->search_data("20181011093040-99999999999999999999999999999999", "999");
  is($get_report,undef,'report is undef');
  is($get_report->{report_info}->{messageid},undef,'messsage id is undef');
  is($get_report->{report_info}->{report_type_id},undef,'report type id is undef');
  done_testing;
};

subtest "No.8 search_data" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $mh = MonthlyReportHandler->new($log, $jh->{data});
  
  # レポートを取得しないことの確認
  my ($stdout, $strerr) = capture {
    my $get_report = $mh->search_data('hoge', '');
    is($get_report,undef,'report is undef');
    is($get_report->{report_info}->{messageid},undef,'messsage id is undef');
    is($get_report->{report_info}->{report_type_id},undef,'report type id is undef');
  };
  like($strerr, qr/there is undefined parameter/, 'err msg is ok');
  done_testing;
};


done_testing;
