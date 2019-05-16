# $Id: qrt_adjust_2019.t 35732 2019-01-18 06:02:06Z p0660 $

use strict;
use warnings;


use Test::More;
use Test::Exception;
use Data::Dumper;
use Benchmark;
use File::Basename;
use POSIX qw(strftime);
use constant { TRUE => 1, FALSE => 0 };
use Test::Deep;
use Test::Deep::Matcher;
use Test::Differences;
use constant { TRUE => 1, FALSE => 0, ZERO_BUT_TRUE => 'ZERO_BUT_TRUE' };

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
use QrtVer2019Adjust;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $test_data_dir = "$top_dir/t/data";
my $qrt_2018 = "$test_data_dir/test_qrt_adj/ver2018";
my $qrt_2019 = "$test_data_dir/test_qrt_adj/ver2019";
my $test_out_dir = "$top_dir/t/out";
my $out_2018 = "$test_out_dir/test_qrt_adj/ver2018";
my $out_2019 = "$test_out_dir/test_qrt_adj/ver2019";
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;
#my $test_data_dir = "$top_dir/t/data/$prog_base";


diag "It is no problem below warning message as Lack of report attribute";

my $log  = logging->Open( $log_fname );
my $err_flg;
my $start_msg = "Subtest %s Start\n";
my $end_msg = "=== Subtest %s End ===\n";
my $name;
my $num;

# test
subtest "dep test" => sub {

  # m列 No 1,2,3,9,21,26,28
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2019/dep.json");
  my $chk = DailyReportHandler->new($log, $dep);

  # 本試験対象ロジック起動
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');
  # 本試験対象ロジック起動
  lives_ok( sub { $adj->interchange; }, 'interchange ok');

  my $result_start_time = EsmLib::EpochToStr(EsmLib::StrToEpoch($chk->get_raw_dep_berth_time) - ($chk->get_inport_time * 60));
  $log->Info("result_start_time : %s\n", Dumper $result_start_time);

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'voyage_start', 'test No 3 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_dep_berth_time, 'test No 9 : _set_report_time ok');
  is($chk->get_start_time, $result_start_time, 'test No 21 : _completion_start_time ok');
  # is($chk->get_interchange_steaming_hours, undef, 'test No 26 : _interchange_steaming_hours ok');
  # is($chk->get_steaming_time, undef, 'test No 28 : _completion_steaming_time ok');

  # data evidence
  $dep->set_save_path("$out_2019/dep_out.json");
  $dep->save;

  done_testing;
};

=pod
subtest "dep failed test" => sub {

  # m列,No 23
  my $adj;
  my $preface = 'dep_ng';
  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_start_time, '', 'test No 23 : _completion_start_time ok');

  done_testing;
};
=cut

subtest "noon test" => sub {

  # m列,No 10
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2019/noon.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_noon_time, 'test No 10 : _set_report_time ok');

  done_testing;
};

subtest "drft_start test" => sub {

  # m列,No 11
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2019/drft_start.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_drft_start_time, 'test No 11 : _set_report_time ok');

  done_testing;
};

subtest "drft_end test" => sub {

  # m列,No 12
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2019/drft_end.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_drft_end_time, 'test No 12 : _set_report_time ok');

  done_testing;
};

subtest "anch start test" => sub {

  # m列,No 5,13
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2019/anch_start.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'anchor_start', 'test No 5 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_anch_start_time, 'test No 13 : _set_report_time ok');

  done_testing;
};

subtest "anch end test" => sub {

  # m列,No 6,14
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2019/anch_end.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'anchor_end', 'test No 6 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_anch_end_time, 'test No 14 : _set_report_time ok');

  done_testing;
};

subtest "bunker end test" => sub {

  # m列,No 16
  my $adj;
  my $preface = "bunker_end";
  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_bunkering_end_time, 'test No 16 : _set_report_time ok');

  done_testing;
};

subtest "cargo test" => sub {

  # m列,No 17
  my $adj;
  my $preface = "cargo";
  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_raw_report_time, 'test No 17 : _set_report_time ok');

  done_testing;
};

subtest "berth test( not calculate start time )" => sub {

  # m列,No 4,18,22,25,27
  my $adj;
  my $preface = "berth";
  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'voyage_end', 'test No 4 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_arr_berth_time, 'test No 18 : _set_report_time ok');
  is($chk->get_start_time, '2017-05-01T10:12:00Z', 'test No 22 : _completion_start_time ok');
  # is($chk->get_interchange_steaming_hours, '60.0', 'test No 25 : _interchange_steaming_hours ok');
  # is($chk->get_steaming_time, '120', 'test No 27 : _completion_steaming_time ok');
  # print Dumper $chk;

  done_testing;
};

subtest "berth failed test" => sub {

  # m列,No 24
  my $adj;
  my $preface = "berth_ng";
  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_start_time, '', 'test No 24 : _completion_start_time ok');

  done_testing;
};

subtest "berth test( calculate start time )" => sub {

  my $adj;
  my $preface = "berth_no_dep_berth_time";
  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_start_time, '2017-05-02T09:12:00', 'test No 42 : _completion_start_time ok');
  # print Dumper $chk;

  done_testing;
};

subtest "blank test" => sub {

  # m列,No 7,19
  my $adj;
  my $preface = "blank";
  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
#  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, '', 'test No 7 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, '2018-05-01T10:12:00Z', 'test No 19 : _completion_start_time ok');

  done_testing;
};

$name = "_interchange_report_categories - 1";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = '1.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_report_categories/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->_interchange_report_categories;

  # 条件：　{report_info}{report_type}が"ARR" かつ、{raw}{esm_status}が存在し"BERTH"
  # 予想：　{report_info}{report_type}に"STATUS"が設定され、{report_info}{status}に"BERTH"が設定される
  eq_or_diff(
  [
    $chk->get_report_type,
    $chk->get_status,
    $chk->get_calc_report_type
  ],
  [
    'STATUS',
    'BERTH',
    'STATUS'
  ], 'No.29');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_interchange_report_categories - 2";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = '2.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_report_categories/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->_interchange_report_categories;

  # 条件：　{report_info}{report_type}が"ARR" だが、{raw}{esm_status}が存在し"BERTH"でない
  # 予想：　{report_info}{report_type}に"STATUS"が設定されず、{report_info}{status}に"BERTH"も設定されない
  eq_or_diff(
  [
    $chk->get_report_type,
    $chk->get_status,
    $chk->get_calc_report_type
  ],
  [
    'ARR',
    '',
    'ARR',
  ], 'No.30');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_interchange_report_categories - 3";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = '3.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_report_categories/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->_interchange_report_categories;

  # 条件：　{report_info}{report_type}が"ARR" だが、{raw}{esm_status}が存在しない
  # 予想：　{report_info}{report_type}に"STATUS"が設定されず、{report_info}{status}に"BERTH"も設定されない
  eq_or_diff(
  [
    $chk->get_report_type,
    $chk->get_status,
    $chk->get_calc_report_type
  ],
  [
    'ARR',
    '',
    'ARR'
  ], 'No.31');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_interchange_report_categories - 4";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = '4.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_report_categories/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->_interchange_report_categories;

  # 条件：　{report_info}{report_type}が"ARR"でない、 かつ、{raw}{esm_status}が存在し"BERTH"
  # 予想：　{report_info}{report_type}に"STATUS"が設定されず、{report_info}{status}に"BERTH"も設定されない
  eq_or_diff(
  [
    $chk->get_report_type,
    $chk->get_status,
    $chk->get_calc_report_type
  ],
  [
    '__ARR__',
    '',
    '__ARR__'
  ], 'No.32');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_interchange_report_categories - 5";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = '5.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_report_categories/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->_interchange_report_categories;

  # 条件：　{report_info}{report_type}が"ARR"でない、 かつ、{raw}{esm_status}が存在し"BERTH"でない
  # 予想：　{report_info}{report_type}に"STATUS"が設定されず、{report_info}{status}に"BERTH"も設定されない
  eq_or_diff(
  [
    $chk->get_report_type,
    $chk->get_status,
    $chk->get_calc_report_type
  ],
  [
    '__ARR__',
    '',
    '__ARR__'
  ], 'No.33');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_interchange_report_categories - 6";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = '6.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_report_categories/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->_interchange_report_categories;

  # 条件：　{report_info}{report_type}が"ARR"でない、 かつ、{raw}{esm_status}が存在しない
  # 予想：　{report_info}{report_type}に"STATUS"が設定されず、{report_info}{status}に"BERTH"も設定されない
  eq_or_diff(
  [
    $chk->get_report_type,
    $chk->get_status,
    $chk->get_calc_report_type
  ],
  [
    '__ARR__',
    '',
    '__ARR__',
  ], 'No.34');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_summarize_report_terms - 35";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'arr_1.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_summarize_report_terms/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->interchange;

  # 条件：　
    # steaming_distanceはeosptoberthのみ
    # steaming_timeはarr_eospのみ
    # time_spent_hoursはどちらも存在しない
    # cons_total_hs-hfoはどちらも"0"
  # 予想：
    # ・steaming_distance, steaming_timeの値が変わらない
    # ・time_spent_hoursは値が存在しない
    # ・cons_total_hs_hfoが"0"
    # ・その他の対象項目はすべて積算される
  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "steaming_distance"]),
    $chk->_get_report_value(["calc", "steaming_time"]),
    $chk->_get_report_value(["calc", "time_spent_hours"]),
    $chk->_get_report_value(["calc", "cons_total_ls-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_hs-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_ls-lfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsdogo"]),
    $chk->_get_report_value(["calc", "cons_total_hsdo"]),
    $chk->_get_report_value(["calc", "cons_total_lsdo"]),
    $chk->_get_report_value(["calc", "cons_total_hsgo"]),
    $chk->_get_report_value(["calc", "cons_total_lsgo"]),
  ],
  [
    "10",
    "10",
    "",
    "20",
    ZERO_BUT_TRUE,
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
  ], 'No.35');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_summarize_report_terms - 36";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'arr_2.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_summarize_report_terms/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->interchange;

  # 条件：　
    # {custom}配列に{calc_key}が2つ存在し、それぞれcons_total_hsgo, cons_total_lsgoである
  # 予想：
    # customの{calc_key}キー以外の対象項目すべてが積算される
  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "steaming_distance"]),
    $chk->_get_report_value(["calc", "steaming_time"]),
    $chk->_get_report_value(["calc", "time_spent_hours"]),
    $chk->_get_report_value(["calc", "cons_total_ls-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_hs-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_ls-lfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsdogo"]),
    $chk->_get_report_value(["calc", "cons_total_hsdo"]),
    $chk->_get_report_value(["calc", "cons_total_lsdo"]),
    $chk->_get_report_value(["calc", "cons_total_hsgo"]),
    $chk->_get_report_value(["calc", "cons_total_lsgo"]),
  ],
  [
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "10",
    "10",
  ], 'No.36');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_summarize_report_terms - 37";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'arr_3.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_summarize_report_terms/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->interchange;

  # 条件：　
    # {custom}配列に{calc_key}が2つ存在し、すべてcons_total_lsdoである
  # 予想：
    # cons_total_lsdo以外の対象項目すべてが積算される
  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "steaming_distance"]),
    $chk->_get_report_value(["calc", "steaming_time"]),
    $chk->_get_report_value(["calc", "time_spent_hours"]),
    $chk->_get_report_value(["calc", "cons_total_ls-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_hs-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_ls-lfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsdogo"]),
    $chk->_get_report_value(["calc", "cons_total_hsdo"]),
    $chk->_get_report_value(["calc", "cons_total_lsdo"]),
    $chk->_get_report_value(["calc", "cons_total_hsgo"]),
    $chk->_get_report_value(["calc", "cons_total_lsgo"]),
  ],
  [
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "20",
    "10",
    "20",
    "20",
  ], 'No.37');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_summarize_report_terms - 38";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'arr_4.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_summarize_report_terms/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->interchange;

  # 条件：　
    # {raw}{esm_status}が存在し"BERTH"でない
  # 予想：
    # 対象項目すべてが積算されない
  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "steaming_distance"]),
    $chk->_get_report_value(["calc", "steaming_time"]),
    $chk->_get_report_value(["calc", "time_spent_hours"]),
    $chk->_get_report_value(["calc", "cons_total_ls-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_hs-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_ls-lfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsdogo"]),
    $chk->_get_report_value(["calc", "cons_total_hsdo"]),
    $chk->_get_report_value(["calc", "cons_total_lsdo"]),
    $chk->_get_report_value(["calc", "cons_total_hsgo"]),
    $chk->_get_report_value(["calc", "cons_total_lsgo"]),
  ],
  [
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
  ], 'No.38');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_summarize_report_terms - 39";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'arr_5.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_summarize_report_terms/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->interchange;

  # 条件：　
    # {raw}{esm_status}が存在しない
  # 予想：
    # 対象項目すべてが積算されない
  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "steaming_distance"]),
    $chk->_get_report_value(["calc", "steaming_time"]),
    $chk->_get_report_value(["calc", "time_spent_hours"]),
    $chk->_get_report_value(["calc", "cons_total_ls-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_hs-hfo"]),
    $chk->_get_report_value(["calc", "cons_total_ls-lfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsfo"]),
    $chk->_get_report_value(["calc", "cons_total_ulsdogo"]),
    $chk->_get_report_value(["calc", "cons_total_hsdo"]),
    $chk->_get_report_value(["calc", "cons_total_lsdo"]),
    $chk->_get_report_value(["calc", "cons_total_hsgo"]),
    $chk->_get_report_value(["calc", "cons_total_lsgo"]),
  ],
  [
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
    "10",
  ], 'No.39');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "_interchange_berth_items - 40";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'arr_1.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_berth_items/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->interchange;

  # 条件：　
    # berth_berth_cons_total_lfoは 0,
    # berth_berth_cons_total_ls-lfoは 'hoge'(文字列)
    # berth_berth_cons_total_lsfoは'0.0'
  # 予想：
    # ・{raw}配下のberth_berth_から始まる項目が{calc}配下に存在する
    # ・{raw}配下のberth_berth_から始まらない項目が{calc}配下に追加されない
    # berth_berth_cons_total_lfoは 0が追加される
    # berth_berth_cons_total_ls-lfoは 文字列だが追加される
    # berth_berth_cons_total_lsfoは数値として扱われるので追加される
  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "berth_berth_total_distance"]),
    $chk->_get_report_value(["calc", "berth_berth_total_hours"]),
    $chk->_get_report_value(["calc", "berth_berth_cons_total_lfo"]),
    $chk->_get_report_value(["calc", "berth_berth_cons_total_ls-lfo"]),
    $chk->_get_report_value(["calc", "berth_berth_cons_total_lsfo"]),
    $chk->_get_report_value(["calc", "hoge_berth_berth_items"]),
  ],
  [
    "3910",
    "60.0",
    ZERO_BUT_TRUE,
    "hoge",
    "0.0",
    undef
  ], 'No.40');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '41';
$name = "_interchange_berth_items - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'arr_2.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_berth_items/%s", $test_data_dir, 'ver2019', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2019Adjust->new($log, $jh->get_data);
  $adj->interchange;

  # 条件：　
    # {custom}配列に{calc_key}が4つ存在し、それぞれberth_berth_total_distance,
    # berth_berth_total_hours, berth_berth_cons_total_hfo, berth_berth_cons_total_hfoである
  # 予想：
    # customの{calc_key}キー以外の{raw}配下のberth_berth_から始まる項目が{calc}配下に追加される
    # ※ berth_berth_cons_total_hfoは重複しているが、1つ以上項目がcustomに存在していれば追加対象外となる。
    # よって、3つが追加対象外である。
  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "berth_berth_total_distance"]),
    $chk->_get_report_value(["calc", "berth_berth_total_hours"]),
    $chk->_get_report_value(["calc", "berth_berth_cons_total_hfo"]),
    $chk->_get_report_value(["calc", "berth_berth_cons_total_lfo"]),
  ],
  [
    "4000",
    "120",
    undef,
    ZERO_BUT_TRUE,
  ], "No.$num");

  # print Dumper $chk;

  $log->Info($end_msg, $name);
  done_testing;
};

=pod
subtest "error test" => sub {

  # m列,No 8,20
  my $adj;
  my $preface = "error";
  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
#  my $dep = JsonHandler->new($log, "$qrt_2019/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2019Adjust->new($log, $dep->get_data); }, 'new ok');
  lives_ok( sub { $adj->interchange; }, 'interchange ok');

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, '', 'test No 8 : _add_flag_for_judge_voyage ok');
  is($chk->get_start_time, '', 'test No 20 : _completion_start_time ok');

  done_testing;
};
=cut

done_testing;
