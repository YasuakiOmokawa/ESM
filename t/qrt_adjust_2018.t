# $Id: qrt_adjust_2018.t 35795 2019-01-24 01:43:21Z p0660 $

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
use List::MoreUtils;

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
use QrtVer2018Adjust;

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

my $log  = logging->Open( $log_fname );
my $start_msg = "Subtest %s Start\n";
my $end_msg = "=== Subtest %s End ===\n";
my $name;
my $num;
my $func;

# main tests
subtest "2018 dep test" => sub {

  # m列 No 1,2,3,9,21,25
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2018/dep.json");
  my $chk = DailyReportHandler->new($log, $dep);

  # 本試験対象ロジック起動
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  # 本試験対象ロジック起動
  lives_ok( sub { $adj->interchange; }, 'interchange ok');
#  $adj->interchange;

  my $result_start_time = EsmLib::EpochToStr(EsmLib::StrToEpoch($chk->get_raw_dep_berth_time) - ($chk->get_inport_time * 60));
  $log->Info("result_start_time : %s\n", Dumper $result_start_time);

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'voyage_start', 'test No 3 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_dep_berth_time, 'test No 9 : _set_report_time ok');
  is($chk->get_start_time, $result_start_time, 'test No 21 : _completion_start_time ok');
  # is($chk->get_interchange_steaming_hours, '123', 'test No 25 : _interchange_steaming_hours ok');

  # data evidence
  $dep->set_save_path("$out_2018/dep_out.json");
  $dep->save;

  done_testing;
};

=pod
subtest "2018 dep failed test" => sub {

  # m列,No 23
  my $adj;
  my $preface = 'dep_ng';
  my $dep = JsonHandler->new($log, "$qrt_2018/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_start_time, '', 'test No 23 : _completion_start_time ok');

  done_testing;
};
=cut

subtest "2018 noon test" => sub {

  # m列,No 10
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2018/noon.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_noon_time, 'test No 10 : _set_report_time ok');

  done_testing;
};

subtest "2018 drft_start test" => sub {

  # m列,No 11
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2018/drft_start.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_drft_start_time, 'test No 11 : _set_report_time ok');

  done_testing;
};

subtest "2018 drft_end test" => sub {

  # m列,No 12
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2018/drft_end.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_drft_end_time, 'test No 12 : _set_report_time ok');

  done_testing;
};

subtest "2018 anch start test" => sub {

  # m列,No 5,13
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2018/anch_start.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'anchor_start', 'test No 5 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_anch_start_time, 'test No 13 : _set_report_time ok');

  done_testing;
};

subtest "2018 anch start test type 2" => sub {

  # m列,No 5,13
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2018/anch_start_2.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'anchor_start', 'test No 27 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_anch_start_time, 'test No 29 : _set_report_time ok');

  done_testing;
};

subtest "2018 anch end test" => sub {

  # m列,No 6,14
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2018/anch_end.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'anchor_end', 'test No 6 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_anch_end_time, 'test No 14 : _set_report_time ok');

  done_testing;
};

subtest "2018 anch end test type 2" => sub {

  # m列,No 6,14
  my $adj;
  my $dep = JsonHandler->new($log, "$qrt_2018/anch_end_2.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'anchor_end', 'test No 28 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_anch_end_time, 'test No 30 : _set_report_time ok');

  done_testing;
};

subtest "2018 bunker end test" => sub {

  # m列,No 16
  my $adj;
  my $preface = "bunker_end";
  my $dep = JsonHandler->new($log, "$qrt_2018/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_bunkering_end_time, 'test No 16 : _set_report_time ok');

  done_testing;
};

subtest "2018 cargo test" => sub {

  # m列,No 17
  my $adj;
  my $preface = "cargo";
  my $dep = JsonHandler->new($log, "$qrt_2018/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_report_time, $chk->get_raw_report_time, 'test No 17 : _set_report_time ok');

  done_testing;
};

subtest "2018 berth test" => sub {

  # m列,No 4,18,22
  my $adj;
  my $preface = "berth";
  my $dep = JsonHandler->new($log, "$qrt_2018/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  my $result_start_time = EsmLib::EpochToStr(EsmLib::StrToEpoch($chk->get_raw_arr_berth_time) - ($chk->get_berth_berth_total_hours * 60));
  $log->Info("result_start_time : %s\n", Dumper $result_start_time);

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, 'voyage_end', 'test No 4 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, $chk->get_arr_berth_time, 'test No 18 : _set_report_time ok');
  is($chk->get_start_time, $result_start_time, 'test No 22 : _completion_start_time ok');

  done_testing;
};

subtest "2018 berth failed test" => sub {

  # m列,No 24
  my $adj;
  my $preface = "berth_ng";
  my $dep = JsonHandler->new($log, "$qrt_2018/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_start_time, '', 'test No 24 : _completion_start_time ok');

  done_testing;
};

subtest "2018 blank test 1" => sub {

  # m列,No 7,19
  my $adj;
  my $preface = "blank";
  my $dep = JsonHandler->new($log, "$qrt_2018/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');

  $adj->interchange;

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, '', 'test No 7 : _add_flag_for_judge_voyage ok');
  is($chk->get_report_time, '2018-05-01T10:12:00Z', 'test No 19 : _completion_start_time ok');

  done_testing;
};

$num = '31';
$name = "_interchange_time_spent_hours - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_1.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_time_spent_hours/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "berth_berth_time_spent_hours"]),
    $chk->_get_report_value(["calc", "berth_berth_total_hours"]),
  ],
  [
    ZERO_BUT_TRUE,
    ""
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '32';
$name = "_interchange_time_spent_hours - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_2.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_time_spent_hours/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "berth_berth_time_spent_hours"]),
  ],
  [
    1000,
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '33';
$name = "_interchange_time_spent_hours - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_3.json';
  my $path = sprintf("%s/test_qrt_adj/%s/_interchange_time_spent_hours/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->_get_report_value(["calc", "berth_berth_time_spent_hours"]),
    $chk->_get_report_value(["calc", "berth_berth_total_hours"]),
  ],
  [
    1,
    1
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

=pod
subtest "2018 error test" => sub {

  # m列,No 8,20,26
  my $adj;
  my $preface = "error";
  my $dep = JsonHandler->new($log, "$qrt_2018/${preface}.json");
  my $chk = DailyReportHandler->new($log, $dep);
  lives_ok( sub { $adj = QrtVer2018Adjust->new($log, $dep->get_data); }, 'new ok');
  lives_ok( sub { $adj->interchange; }, 'interchange ok');

  # 1.互換対象データ取得　2.予想結果　3.terminal出力
  is($chk->get_for_judge_voyage, '', 'test No 8 : _add_flag_for_judge_voyage ok');
  is($chk->get_start_time, '', 'test No 20 : _completion_start_time ok');
  is($chk->get_interchange_steaming_hours, undef, 'test No 26 : _completion_start_time ok');

  done_testing;
};
=cut

$num = '34';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_1.json';
  my $path = sprintf("%s/test_qrt_adj/%s/$func/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    'voyage_end',
    "BERTH"
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '35';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_2.json';
  my $path = sprintf("%s/test_qrt_adj/%s/$func/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    'voyage_end',
    "BERTH"
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '36';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_3.json';
  my $path = sprintf("%s/test_qrt_adj/%s/$func/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    'voyage_end',
    "BERTH"
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '37';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_4.json';
  my $path = sprintf("%s/test_qrt_adj/%s/$func/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    'voyage_end',
    "BERTH"
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};


$num = '38';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_5.json';
  my $path = sprintf("%s/test_qrt_adj/%s/$func/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    "",
    ""
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};


$num = '39';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_6.json';
  my $path = sprintf("%s/test_qrt_adj/%s/$func/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    "",
    ""
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '40';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_7.json';
  my $path = sprintf("%s/test_qrt_adj/%s/$func/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    "voyage_end",
    "BERTH"
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '41';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $f = 'rep_8.json';
  my $path = sprintf("%s/test_qrt_adj/%s/$func/%s", $test_data_dir, 'ver2018', $f);
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;

  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    "",
    ""
  ], "No.$num");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '41-base';
$func = "_interchange_report_categories";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $chk = _test_base(+{file=>'rep_8.json', func=>$func,
              log=>$log, test_data_dir=>$test_data_dir});
  
  eq_or_diff(
  [
    $chk->get_for_judge_voyage,
    $chk->get_status,
  ],
  [
    "",
    ""
  ], "No.$num");

  $log->Info($end_msg, $name);

  done_testing;
};

$num = '42';
$func = "_add_flag_for_not_save_report";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $chk = _test_base(+{file=>'rep_1.json', func=>$func,
              log=>$log, test_data_dir=>$test_data_dir});

#  print Dumper $chk;
  
  eq_or_diff(
  [
    $chk->is_not_save,
  ],
  [
    TRUE,
  ], "No.$num");

  $log->Info($end_msg, $name);

  done_testing;
};

$num = '43';
$func = "_add_flag_for_not_save_report";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $chk = _test_base(+{file=>'rep_2.json', func=>$func,
              log=>$log, test_data_dir=>$test_data_dir});
  
  eq_or_diff(
  [
    $chk->is_not_save,
  ],
  [
    FALSE,
  ], "No.$num");

  $log->Info($end_msg, $name);

  done_testing;
};

$num = '44';
$func = "_add_flag_for_not_save_report";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $chk = _test_base(+{file=>'rep_3.json', func=>$func,
              log=>$log, test_data_dir=>$test_data_dir});
  
  eq_or_diff(
  [
    $chk->is_not_save,
  ],
  [
    FALSE,
  ], "No.$num");

  $log->Info($end_msg, $name);

  done_testing;
};

$num = '45';
$func = "_add_flag_for_not_save_report";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $chk = _test_base(+{file=>'rep_4.json', func=>$func,
              log=>$log, test_data_dir=>$test_data_dir});
  
  eq_or_diff(
  [
    $chk->is_not_save,
  ],
  [
    FALSE,
  ], "No.$num");

  $log->Info($end_msg, $name);

  done_testing;
};

$num = '46';
$func = "_add_flag_for_not_save_report";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $chk = _test_base(+{file=>'rep_5.json', func=>$func,
              log=>$log, test_data_dir=>$test_data_dir});
  
  eq_or_diff(
  [
    $chk->is_not_save,
  ],
  [
    FALSE,
  ], "No.$num");

  $log->Info($end_msg, $name);

  done_testing;
};

$num = '47';
$func = "_add_flag_for_not_save_report";
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $chk = _test_base(+{file=>'rep_6.json', func=>$func,
              log=>$log, test_data_dir=>$test_data_dir});
  
  eq_or_diff(
  [
    $chk->is_not_save,
  ],
  [
    FALSE,
  ], "No.$num");

  $log->Info($end_msg, $name);

  done_testing;
};


# template test subroutine
sub _test_base {
  my $args = shift;
  my $log = $args->{log};

  my $path = sprintf("%s/test_qrt_adj/%s/$args->{func}/%s", $args->{test_data_dir}, 'ver2018', $args->{file});
  my $jh = JsonHandler->new($log, $path);
  my $chk = DailyReportHandler->new($log, $jh);
  my $adj;
  $adj = QrtVer2018Adjust->new($log, $jh->get_data);
  $adj->interchange;
  
  return $chk;
}

done_testing;
