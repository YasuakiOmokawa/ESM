# $Id: voyage_eu_mrv_data_summarizer.t 35732 2019-01-18 06:02:06Z p0660 $

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
use VoyageEuMrvDataSummarizer;

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
subtest "No.1-4 new,summarize" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $vs = VoyageEuMrvDataSummarizer->new($log);
  
  # newできているか確認
  ok($vs,'new ok');

  # set_definition確認
  is($vs->{summarize_def}->{data}->{for_annual}->{eu_mrv}[0]->{voyage_number}->{format}->{init_val},
  '---','set_definition is ok');

  # set_formatter確認
  is($vs->{fmt}->{port_info}->{NVK}->{CNAME},'Norway','set_formatter is ok');  

  # summarize
  $vs->summarize($jh->{data});

  # # set_summarized_data確認
  is($vs->{summarize_result}->{data}->{data}->{record_type},'voyage','set_summarized_data is ok');
 
  # set_judge_result確認
  is($vs->{judge_result}->{data}->{to}->{report_info}->{report_type_repo},'BERTHING REPORT','set_judge_result is ok');

  done_testing;
};

subtest "No.5 param is file path" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  
  # テストデータのインスタンス化
  my $vs = VoyageEuMrvDataSummarizer->new($log);
  
  # newできているか確認
  ok($vs,'new ok');

  # set_definition確認
  is($vs->{summarize_def}->{data}->{for_annual}->{eu_mrv}[0]->{voyage_number}->{format}->{init_val},
  '---','set_definition is ok');

  # set_formatter確認
  is($vs->{fmt}->{port_info}->{NVK}->{CNAME},'Norway','set_formatter is ok');  

  # summarize
  $vs->summarize($tst_file_path);

  # # set_summarized_data確認
  is($vs->{summarize_result}->{data}->{data}->{record_type},'voyage','set_summarized_data is ok');
 
  # set_judge_result確認
  is($vs->{judge_result}->{data}->{to}->{report_info}->{report_type_repo},'BERTHING REPORT','set_judge_result is ok');

  done_testing;
};

subtest "No.6 no input data" => sub {

  my $tst_file = '9.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $vs = VoyageEuMrvDataSummarizer->new($log);
  
  # newできているか確認
  ok($vs,'new ok');

  # summarize
  $vs->summarize($jh->{data});

  # set_judge_resultで値が取得できていないことの確認
  is($vs->{judge_result}->{data}->{to}->{report_info}->{report_type_repo},undef,'set_judge_result is failed');

  done_testing;
};

subtest "No.7-17,20-22 _calc_voyage_type Case No.1-11,14-16" => sub {

  # 引数パターンごとの戻り値確認
  my $res;
  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('voyage','TAR','HLS');
  is($res,'eu_to_eu','Case No.1 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('voyage','XXX','HLS');
  is($res,'arr_at_eu_port','Case No.2 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('voyage','VAI','HLS');
  is($res,'arr_at_eu_port','Case No.3 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('voyage','TAR','XXX');
  is($res,'dep_from_eu_port','Case No.4 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('voyage','TAR','VAI');
  is($res,'dep_from_eu_port','Case No.5 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('voyage','VAI','SOD');
  is($res,'no_eu','Case No.6 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('in_port','TAR','HLS');
  is($res,'in_eu_port','Case No.7 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('in_port','VAI','HLS');
  is($res,'in_eu_port','Case No.8 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('in_port','TAR','VAI');
  is($res,'in_eu_port','Case No.9 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('in_port','VAI','SOD');
  is($res,'no_eu','Case No.10 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('xxx','TAR','HLS');
  is($res,'no_eu','Case No.11 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('','TAR','HLS');
  is($res,'no_eu','Case No.14 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('voyage','','HLS');
  is($res,'arr_at_eu_port','Case No.15 is ok');

  $res = VoyageEuMrvDataSummarizer::_calc_voyage_type('voyage','TAR','');
  is($res,'dep_from_eu_port','Case No.16 is ok');
  done_testing;
};

done_testing;
