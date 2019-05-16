# $Id: voyage_data_daily_change_re_summarizer.t 35732 2019-01-18 06:02:06Z p0660 $

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
use Test::Deep;
use Test::Deep::Matcher;
use Test::Differences;

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";
use lib '/usr/amoeba/lib/perl';

use logging;
use EsmLib;

# test module
use VoyageDataDailyChangeReSummarizer;

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
my $test_out_dir = "$top_dir/t/out";

my $log  = logging->Open( $log_fname );
my $name;
my $err_flg;
my $start_msg = "Subtest %s Start\n";
my $end_msg = "=== Subtest %s End ===\n";

# test
$name = "summarize No.2(exception case of summarize No.1)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_1.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  lives_ok(sub {$vrs->summarize($jh->get_data, ["calculate_phase1"]);}, 'summarize ok');
  if ($@) {
    like($@, qr/Can\'t use string/, 'No.1 - def file not found');
    $err_flg = 1;
  } else {
    # from_report_only, calculate_phase1, calculate_phase2, calclate_phase3 の項目を
    # それぞれ１つずつ確認
    # calculate_phase1の項目しか存在しないことを確認
    eq_or_diff(
    [
      $jh->get_data->{data}{for_row}{data}{voyage_number},    # from report only
      $jh->get_data->{data}{for_row}{data}{time_at_sea},      # calculate_phase1
      $jh->get_data->{data}{for_row}{data}{co2_dogo},         # calculate_phase2
      $jh->get_data->{data}{for_row}{data}{co2_per_distance}, # calculate_phase3
    ],
    [
      undef,
      "1.0",
      undef,
      undef,
    ], 'only one calculate ok');
  }

  $log->Info($end_msg, $name);
  done_testing;
};

plan skip_all => "skip all tests because of def file is invalid" if $err_flg;

$name = "summarize No.3";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_1.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  # from_report_only, calculate_phase1, calculate_phase2, calclate_phase3 の項目を
  # それぞれ１つずつ確認
  # ※ 計算順序はログ目視で確認するしかない。。
  eq_or_diff(
  [
    $jh->get_data->{data}{for_row}{data}{voyage_number},
    $jh->get_data->{data}{for_row}{data}{time_at_sea},
    $jh->get_data->{data}{for_row}{data}{co2_dogo},
    $jh->get_data->{data}{for_row}{data}{co2_per_distance},
  ],
  [
    $jh->get_data->{data}{include_reports}{to}{calc}{voyage_num},
    "1.0",
    "32.06",
    3.4719,
  ], 'all type calculate ok');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (record type: voyage - type 1)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_1.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);

  my $res;
  my ($stdout, $stderr) = capture {
    lives_ok(sub{$res = $vrs->summarize($jh->get_data);}, 'No.6 - summarize ok');
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  is($jh->get_data->{data}{for_row}{data}{distance_travelled}, '100', 'No.4');
  is($jh->get_data->{data}{for_row}{data}{cargo_weight}, undef, 'No.5 - data');
  like($stderr, qr/Input value is lower than the lower limit/, 'No.5 - out of lower range ');
  is($jh->get_data->{data}{for_row}{data}{passenger}, undef, 'No.6 - data');
  is($jh->get_data->{data}{for_row}{data}{voyage_number}, "0", 'No.7');
  is($jh->get_data->{data}{for_row}{data}{foc_hfo}, "100.01", 'No.8');
  is($jh->get_data->{data}{for_row}{data}{hours_underway}, "1.0", 'No.9');
  is($jh->get_data->{data}{for_row}{data}{foc_dogo_per_distance}, "0.1000", 'No.10');
  is($jh->get_data->{data}{for_row}{data}{co2_lfo}, undef, 'No.11');
  is($jh->get_data->{data}{for_row}{data}{co2_hfo}, "315.13", 'No.12');
  is($jh->get_data->{data}{for_row}{data}{co2_dogo}, "32.06", 'No.13'); # 定義ファイルの固定値書き換えでエラーにする
  is($jh->get_data->{data}{for_row}{data}{foc_other_per_distance}, '0.0000', 'No.16');
  is($jh->get_data->{data}{for_row}{data}{eu_mrv}, 'dep_from_eu_port', 'No.19');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (record type: in_port)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_in_port_1.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);

  my $res;
  my ($stdout, $stderr) = capture {
    lives_ok(sub{$res = $vrs->summarize($jh->get_data);}, 'summarize ok');
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  is($jh->get_data->{data}{for_row}{data}{foc_hfo}, '0.00', 'No.14 - data');
  is($jh->get_data->{data}{record_type}, 'in_port', 'No.14 - type');
  is($jh->get_data->{data}{for_row}{data}{foc_lfo}, '0.00', 'No.15');
  is($jh->get_data->{data}{for_row}{data}{co2_dogo}, '0.00', 'No.18'); # 定義ファイルの値を変更してもokとなること
  is($jh->get_data->{data}{for_row}{data}{eu_mrv}, 'no_eu', 'No.20');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (record type: voyage - type 2)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_2.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);

  my $res;
  my ($stdout, $stderr) = capture {
    lives_ok(sub{$res = $vrs->summarize($jh->get_data);}, 'summarize ok');
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  is($jh->get_data->{data}{for_row}{data}{transport_work}, undef, 'No.17');
  is($jh->get_data->{data}{for_row}{data}{foc_hfo}, undef, 'No.22 - data');
  like($stderr, qr/Input value is higher than the upper limit/, 'No.22 - out of upper range ');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (record type: voyage - type 3)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_3.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  eq_or_diff(
  [
    $jh->get_data->{data}{for_row}{data}{co2_per_distance},
  ],
  [
    "0.0000",
  ], 'No.23');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (record type: voyage - type 4)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_4.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  eq_or_diff(
  [
    $jh->get_data->{data}{for_row}{data}{eeoi},
  ],
  [
    "0.00009999",
  ], 'No.24');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (for addition report test - no recursive items)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_for_addition_report_test_1.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data, ['calculate_phase1']);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  # 複数回の計算が行われる対象がない(addition_reportにanchor_start, anchor_endが1組だけ)
  # ため、再帰計算が実施されない
  is($jh->get_data->{data}{for_row}{data}{time_at_sea}, "0.0", 'No.25 - sea');



  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (for addition report test - exist recursive items)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_for_addition_report_test_2.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data, ['calculate_phase1']);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  # 3回計算が実施され、それぞれ1,2,3時間ずつanchoring時間が引かれてゆき、最終的に
  # 480分(8時間) - (1 + 2 + 3)時間 = 2時間となること
  is($jh->get_data->{data}{for_row}{data}{time_at_sea}, "2.0", 'No.26 - sea');



  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (for addition report test - not for addition test - invalid exchange)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_for_addition_report_test_3.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data, ['calculate_phase1']);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  # 再帰計算対象の引数フラグであるis_exchangeを無効にしてからテスト。
  # 再帰計算が実施されなくなるため、通常では結果が0.0となるところが1.0となり、エラーになる
  is($jh->get_data->{data}{for_row}{data}{hours_underway}, "0.0", 'No.27 - underway');



  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize (for addition report test - include invalid report)";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_for_addition_report_test_4.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data, ['calculate_phase1']);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  # 3回計算が実施されるはずだが2回目のレポートは無効なので対象外となり、それぞれ1,3時間ずつanchoring時間が引かれてゆき、最終的に
  # 420分(7時間) - (1 + 3)時間 = 3時間となること
  is($jh->get_data->{data}{for_row}{data}{time_at_sea}, "3.0", 'No.28 - sea');



  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize to invalid";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'voyage_info_underway_to_invalid_1.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  # from_report_only, calculate_phase1, calculate_phase2, calclate_phase3 の項目を
  # それぞれ１つずつ確認し、取得元レポートがinvalidなのですべて取得できないことを確認
  eq_or_diff(
  [
    $jh->get_data->{data}{for_row}{data}{voyage_number},
    $jh->get_data->{data}{for_row}{data}{time_at_sea},
    $jh->get_data->{data}{for_row}{data}{co2_dogo},
    $jh->get_data->{data}{for_row}{data}{co2_per_distance},
  ],
  [
    undef,
    undef,
    undef,
    undef,
  ], 'No.29 - all type calculate undef ok');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "summarize dependency 1";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $voy = 'dependency_1.json';
  my $voy_path = sprintf("%s/summarize/%s", $test_data_dir, $voy);
  my $jh = JsonHandler->new($log, $voy_path);

  # 集計結果が格納されているVoyage情報ファイルデータを使って航海判定を行う
  $ENV{a} = 1;
  my $vrs = VoyageDataDailyChangeReSummarizer->new($log);
  my $res;
  my ($stdout, $stderr) = capture {
    $res = $vrs->summarize($jh->get_data);
  };

  # 戻り値の確認
  is($res, TRUE, 'summarize success');

  # 判定結果の確認
  # 既存の項目(dogo)が削除され、依存項目も削除され、
  # 削除されない項目(lfo)は上書きされることを確認
  eq_or_diff(
  [
    $jh->get_data->{data}{for_row}{data}{foc_dogo},
    $jh->get_data->{data}{for_row}{data}{co2_dogo},
    $jh->get_data->{data}{for_row}{data}{foc_lfo},
    $jh->get_data->{data}{for_row}{data}{co2_lfo},
  ],
  [
    undef,
    undef,
    9999.99,
    31139.97
  ], 'No.30 - foc, co2 dependency ok');

  $log->Info($end_msg, $name);
  done_testing;
};

done_testing;

END{
  $log->Close() if( defined( $log ) );
}
