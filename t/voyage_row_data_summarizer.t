# $Id: voyage_row_data_summarizer.t 35732 2019-01-18 06:02:06Z p0660 $

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

# test
subtest "summarize in_port normal system test" => sub {

  $log->Info("summarize in_port normal system test start log\n");

  my $voyage_fname = "20181007134907-9aae88abb64f93d5419993194f495c77_20181008013853-f98e4ca0f004c8a676a4e4561585ea62_20181007233907.json";
  my $voyage_path = sprintf("%s/%s", $test_data_dir , $voyage_fname );
  my $jh = JsonHandler->new($log, $voyage_path);
  my $jh_result = $jh->get_item(["data", "include_reports"]);

  # 対象クラス・メソッド呼び出し
  my $vrds = VoyageRowDataSummarizer->new($log);
  lives_ok( sub { $vrds->summarize($jh_result); }, 'summarize ok' );


  my $result_data = $vrds->get_summarize_result();

  $log->Info("result_data : %s\n", Dumper $result_data);

  $log->Info("summarize in_port normal system test end log\n");

  done_testing;
};

subtest "summarize underway normal sysytem test" => sub {

  $log->Info("summarize underway normal sysytem test start log\n");

  my $voyage_fname = "20181008013853-f98e4ca0f004c8a676a4e4561585ea62_20181008113458-66c08b4439e97bec11db9a90f5eb2f87_20181008093311.json";
  my $voyage_path = sprintf("%s/%s", $test_data_dir , $voyage_fname );

  # 対象クラス・メソッド呼び出し
  my $vrds = VoyageRowDataSummarizer->new($log);
  lives_ok( sub { $vrds->summarize($voyage_path); }, 'summarize ok' );

  my $result_data = $vrds->get_summarize_result();

  $log->Info("result_data : %s\n", Dumper $result_data);

  $log->Info("summarize underway normal sysytem test end log\n");

  done_testing;
};

subtest "_calc_efficiency normal system test 1" => sub {

  $log->Info("_calc_efficiency normal system test 1 start log\n");

  my $co2_dogo = 1;
  my $co2_lfo = 2;
  my $co2_hfo = 3;
  my $co2_other = 4;
  my $distance_travelled = 2;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_efficiency($co2_dogo, $co2_lfo, $co2_hfo, $co2_other, $distance_travelled), 5 , '_calc_efficiency test1 result ok');

  $log->Info("_calc_efficiency normal system test 1 end log\n");

  done_testing;
};

subtest "_calc_efficiency normal system test 2" => sub {

  $log->Info("_calc_efficiency normal system test 2 start log\n");

  my $co2_dogo = 1;
  my $co2_lfo = "";
  my $co2_hfo = 3;
  my $co2_other = "";
  my $distance_travelled = 2;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_efficiency($co2_dogo, $co2_lfo, $co2_hfo, $co2_other, $distance_travelled), 2 , '_calc_efficiency test2 result ok');

  $log->Info("_calc_efficiency normal system test 2 end log\n");

  done_testing;
};

subtest "_calc_efficiency normal system test 3" => sub {

  $log->Info("_calc_efficiency normal system test 3 start log\n");

  my $co2_dogo = "";
  my $co2_lfo = 5;
  my $co2_hfo = "";
  my $co2_other = 2;
  my $distance_travelled = 3;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_efficiency($co2_dogo, $co2_lfo, $co2_hfo, $co2_other, $distance_travelled), '2.33333333333333' , '_calc_efficiency test3 result ok');

  $log->Info("_calc_efficiency normal system test 3 end log\n");

  done_testing;
};

subtest "_calc_efficiency normal system test 4" => sub {

  $log->Info("_calc_efficiency normal system test 4 start log\n");

  my $co2_dogo = 2;
  my $co2_lfo = 3;
  my $co2_hfo = 4;
  my $co2_other = 5;
  my $distance_travelled = 0;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
#  is(VoyageRowDataSummarizer::_calc_efficiency($co2_dogo, $co2_lfo, $co2_hfo, $co2_other, $distance_travelled), 0 , '_calc_efficiency test4 result ok');
  # throws_ok(sub {VoyageRowDataSummarizer::_calc_efficiency($co2_dogo, $co2_lfo, $co2_hfo, $co2_other, $distance_travelled);}, qr/Illegal division by zero/,'_calc_efficiency test4 result ok');
  is(VoyageRowDataSummarizer::_calc_efficiency($co2_dogo, $co2_lfo, $co2_hfo, $co2_other, $distance_travelled), undef, '_calc_efficiency test4 result ok');
  $log->Info("_calc_efficiency normal system test 4 end log\n");

  done_testing;
};

subtest "_calc_efficiency normal system test 5" => sub {

  $log->Info("_calc_efficiency normal system test 5 start log\n");

  my $co2_dogo = 2;
  my $co2_lfo = 3;
  my $co2_hfo = 4;
  my $co2_other = 5;
  my $distance_travelled = "";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_efficiency($co2_dogo, $co2_lfo, $co2_hfo, $co2_other, $distance_travelled), undef , '_calc_efficiency test5 result ok');

  $log->Info("_calc_efficiency normal system test 5 end log\n");

  done_testing;
};

subtest "CalcMulti normal system test " => sub {

  $log->Info("CalcMulti normal system test start log\n");

  my $param_a = 10;
  my $param_b = 5;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcMulti($param_a, $param_b), 50 , 'CalcMulti test result ok');

  $log->Info("CalcMulti normal system test end log\n");

  done_testing;
};

subtest "CalcMulti error test 1" => sub {

  $log->Info("CalcMulti error test 1 start log\n");

  my $param_a = 0;
  my $param_b = 5;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcMulti($param_a, $param_b), 0 , 'CalcMulti error test 1 result ok');

  $log->Info("CalcMulti error test 1 end log\n");

  done_testing;
};

subtest "CalcMulti error test 2" => sub {

  $log->Info("CalcMulti error test 2 start log\n");

  my $param_a = "a";
  my $param_b = 5;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcMulti($param_a, $param_b), undef , 'CalcMulti error test 2 result ok');

  $log->Info("CalcMulti error test 2 end log\n");

  done_testing;
};

subtest "CalcMulti error test 3" => sub {

  $log->Info("CalcMulti error test 3 start log\n");

  my $param_a = 2;
  my $param_b = "f";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcMulti($param_a, $param_b), undef , 'CalcMulti error test 3 result ok');

  $log->Info("CalcMulti error test 3 end log\n");

  done_testing;
};

subtest "CalcMulti error test 4" => sub {

  $log->Info("CalcMulti error test 4 start log\n");

  my $param_a = "param_a";
  my $param_b = "param_b";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcMulti($param_a, $param_b), undef , 'CalcMulti error test 4 result ok');

  $log->Info("CalcMulti error test 4 end log\n");

  done_testing;
};

subtest "CalcMulti error test 5" => sub {

  $log->Info("CalcMulti error test 5 start log\n");

  my $param_a = "";
  my $param_b = 7;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcMulti($param_a, $param_b), undef , 'CalcMulti error test 5 result ok');

  $log->Info("CalcMulti error test 5 end log\n");

  done_testing;
};

subtest "_calc_transport_work normal system test" => sub {

  $log->Info("_calc_transport_work normal system test start log\n");

  my $dist = 2;
  my $cargo = 3;
  my $passngr;
  my $unit;
  my $cars;
  my $dwt_crd;
  my $vlm;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_transport_work($dist, $cargo, $passngr, $unit, $cars, $dwt_crd, $vlm), 6 , '_calc_transport_work normal test result ok');

  $log->Info("_calc_transport_work normal system test end log\n");

  done_testing;
};

subtest "_calc_transport_work error test 1" => sub {

  $log->Info("_calc_transport_work error test 1 start log\n");

  my $dist = "dist";
  my $cargo;
  my $passngr = 4;
  my $unit;
  my $cars;
  my $dwt_crd;
  my $vlm;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_transport_work($dist, $cargo, $passngr, $unit, $cars, $dwt_crd, $vlm), undef , '_calc_transport_work error test 1 result ok');

  $log->Info("_calc_transport_work error test 1 end log\n");

  done_testing;
};

subtest "_calc_transport_work error test 2" => sub {

  $log->Info("_calc_transport_work error test 2 start log\n");

  my $dist = 9;
  my $cargo;
  my $passngr;
  my $unit;
  my $cars;
  my $dwt_crd;
  my $vlm;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_transport_work($dist, $cargo, $passngr, $unit, $cars, $dwt_crd, $vlm), undef , '_calc_transport_work error test 2 result ok');

  $log->Info("_calc_transport_work error test 2 end log\n");

  done_testing;
};

subtest "_calc_transport_work error test 3" => sub {

  $log->Info("_calc_transport_work error test 3 start log\n");

  my $dist = 9;
  my $cargo;
  my $passngr;
  my $unit;
  my $cars = 3;
  my $dwt_crd;
  my $vlm = 8;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_transport_work($dist, $cargo, $passngr, $unit, $cars, $dwt_crd, $vlm), undef , '_calc_transport_work error test 3 result ok');

  $log->Info("_calc_transport_work error test 3 end log\n");

  done_testing;
};

subtest "CalcSum normal system test 1" => sub {

  $log->Info("CalcSum normal system test 1 start log\n");

  my $param_a = 3;
  my $param_b = 7;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcSum($param_a, $param_b), 10 , 'CalcSum normal system test 1 result ok');

  $log->Info("CalcSum normal system test 1 end log\n");

  done_testing;
};

subtest "CalcSum normal system test 2" => sub {

  $log->Info("CalcSum normal system test 2 start log\n");

  my $param_a = 3;
  my $param_b = 7;
  my $param_c = 5;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcSum($param_a, $param_b, $param_c), 15 , 'CalcSum normal system test 2 result ok');

  $log->Info("CalcSum normal system test 2 end log\n");

  done_testing;
};

subtest "CalcSum normal system test 3" => sub {

  $log->Info("CalcSum normal system test 3 start log\n");

  my $param_a = 0;
  my $param_b = 0;
  my $param_c = 0;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcSum($param_a, $param_b, $param_c), 0 , 'CalcSum normal system test 3 result ok');

  $log->Info("CalcSum normal system test 3 end log\n");

  done_testing;
};

subtest "CalcSum normal system test 4" => sub {

  $log->Info("CalcSum normal system test 4 start log\n");

  my $param_a = "r";
  my $param_b = 4;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcSum($param_a, $param_b), 4 , 'CalcSum normal system test 4 result ok');

  $log->Info("CalcSum normal system test 4 end log\n");

  done_testing;
};

subtest "CalcSum normal system test 5" => sub {

  $log->Info("CalcSum normal system test 5 start log\n");

  my $param_a = 5;
  my $param_b = "aaaa";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcSum($param_a, $param_b), 5 , 'CalcSum normal system test 5 result ok');

  $log->Info("CalcSum normal system test 5 end log\n");

  done_testing;
};

subtest "CalcSum normal system test 6" => sub {

  $log->Info("CalcSum normal system test 6 start log\n");

  my $param_a = "param_a";
  my $param_b = "param_b";
  my $param_c = 0;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcSum($param_a, $param_b, $param_c), 0 , 'CalcSum normal system test 6 result ok');

  $log->Info("CalcSum normal system test 6 end log\n");

  done_testing;
};

subtest "CalcSum error test" => sub {

  $log->Info("CalcSum error test start log\n");

  my $param_a = "param_a";
  my $param_b = "param_b";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(EsmLib::CalcSum($param_a, $param_b), '' , 'CalcSum error test result ok');

  $log->Info("CalcSum error test end log\n");

  done_testing;
};

subtest "_calc_voyage_time normal system test" => sub {

  $log->Info("_calc_voyage_time normal system test start log\n");

  my $voy_minutes = 3600.0;
  my $anch_start_time_str = "2018-09-10T03:00:00Z";
  my $anch_end_time_str   = "2018-09-11T03:00:00Z";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), 36 , '_calc_voyage_time normal system test result ok');

  $log->Info("_calc_voyage_time normal system test end log\n");

  done_testing;
};

subtest "_calc_voyage_time error test 1" => sub {

  $log->Info("_calc_voyage_time error test 1 start log\n");

  my $voy_minutes = "voy_minutes";
  my $anch_start_time_str = "2018-09-10T03:00:00Z";
  my $anch_end_time_str   = "2018-09-11T03:00:00Z";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), undef , '_calc_voyage_time error test 1 result ok');

  $log->Info("_calc_voyage_time error test 1 end log\n");

  done_testing;
};

subtest "_calc_voyage_time error test 2" => sub {

  $log->Info("_calc_voyage_time error test 2 start log\n");

  my $voy_minutes = 3600.0;
  my $anch_start_time_str = "2018-09-10T03:00:00Z";
  my $anch_end_time_str   = "";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
#  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), undef , '_calc_voyage_time error test 2 result ok');
  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), 60 , '_calc_voyage_time error test 2 result ok');

  $log->Info("_calc_voyage_time error test 2 end log\n");

  done_testing;
};

subtest "_calc_voyage_time error test 3" => sub {

  $log->Info("_calc_voyage_time error test 3 start log\n");

  my $voy_minutes = 3600.0;
  my $anch_start_time_str = "2018-09-10T03:00:00Z";
  my $anch_end_time_str   = "none";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
#  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), undef , '_calc_voyage_time error test 3 result ok');
  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), 60 , '_calc_voyage_time error test 3 result ok');

  $log->Info("_calc_voyage_time error test 3 end log\n");

  done_testing;
};

subtest "_calc_voyage_time error test 4" => sub {

  $log->Info("_calc_voyage_time error test 4 start log\n");

  my $voy_minutes = 3600.0;
  my $anch_start_time_str = "2018-09-10T03:00:00Z";
  my $anch_end_time_str   = "aaa";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  throws_ok { VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str) } '/strtoepoch/' , '_calc_voyage_time error test 4 result ok';

  $log->Info("_calc_voyage_time error test 4 end log\n");

  done_testing;
};

subtest "_calc_voyage_time error test 5" => sub {

  $log->Info("_calc_voyage_time error test 5 start log\n");

  my $voy_minutes = 3600.0;
  my $anch_start_time_str = "";
  my $anch_end_time_str   = "2018-09-11T03:00:00Z";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
#  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), undef , '_calc_voyage_time error test 5 result ok');
  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), 60 , '_calc_voyage_time error test 5 result ok');

  $log->Info("_calc_voyage_time error test 5 end log\n");

  done_testing;
};

subtest "_calc_voyage_time error test 6" => sub {

  $log->Info("_calc_voyage_time error test 6 start log\n");

  my $voy_minutes = 3600.0;
  my $anch_start_time_str = "none";
  my $anch_end_time_str   = "2018-09-11T03:00:00Z";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
#  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), undef , '_calc_voyage_time error test 6 result ok');
  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), 60 , '_calc_voyage_time error test 6 result ok');

  $log->Info("_calc_voyage_time error test 6 end log\n");

  done_testing;
};

subtest "_calc_voyage_time error addition test" => sub {

  $log->Info("_calc_voyage_time error test addition start log\n");

  my $voy_minutes = "0";
  my $anch_start_time_str = "2018-09-11T02:00:00Z";
  my $anch_end_time_str   = "2018-09-11T03:00:00Z";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
#  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), undef , '_calc_voyage_time error test 6 result ok');
  is(VoyageRowDataSummarizer::_calc_voyage_time($voy_minutes, $anch_end_time_str, $anch_start_time_str), -1 , '_calc_voyage_time error test addition result ok');

  $log->Info("_calc_voyage_time error test 6 end log\n");

  done_testing;
};

subtest "_calc_div normal test " => sub {

  $log->Info("_calc_div normal test start log\n");

  my $param_a = 10;
  my $param_b = 2;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_div($param_a, $param_b), 5 , '_calc_div normal test result ok');

  $log->Info("_calc_div normal test end log\n");

  done_testing;
};

subtest "_calc_div error test 1" => sub {

  $log->Info("_calc_div error test 1 start log\n");

  my $param_a = "aaa";
  my $param_b = 2;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_div($param_a, $param_b), undef , '_calc_div error test 1 result ok');

  $log->Info("_calc_div error test 1 end log\n");

  done_testing;
};

subtest "_calc_div error test 2" => sub {

  $log->Info("_calc_div error test 2 start log\n");

  my $param_a = 10;
  my $param_b = "bbb";

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_div($param_a, $param_b), undef , '_calc_div error test 2 result ok');

  $log->Info("_calc_div error test 2 end log\n");

  done_testing;
};

subtest "_calc_div error test 3" => sub {

  $log->Info("_calc_div error test 3 start log\n");

  my $param_a = 10;
  my $param_b = 0;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_div($param_a, $param_b), undef , '_calc_div error test 3 result ok');

  $log->Info("_calc_div error test 3 end log\n");

  done_testing;
};

subtest "_calc_div error test 4" => sub {

  $log->Info("_calc_div error test 4 start log\n");

  my $param_a = 10;
  my $param_b;

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is(VoyageRowDataSummarizer::_calc_div($param_a, $param_b), undef , '_calc_div error test 4 result ok');

  $log->Info("_calc_div error test 4 end log\n");

  done_testing;
};

done_testing;
