# $Id: voyage_judge_handler.t 35732 2019-01-18 06:02:06Z p0660 $

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
use VoyageJudgeHandler;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $debug_path = '/usr/home/partner/p0660/test_data_v3/';
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;
my $test_data_dir = "$top_dir/t/data/$prog_base";
my $test_out_dir = "$top_dir/t/out";

my $log  = logging->Open( $log_fname ) ;

# test
subtest "get_voyage_key No.1" => sub {

  my $tst_file = 'get_voyage_key_1.json';
  my $tst_file_path = sprintf("%s/get_voyage_key/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # fromとto両方messageIdがある場合
  is($vj->get_voyage_key, '10171204123649-d02e62705dc62966564c2c3b0581a509_20171204123643-a4f1f1c35bd5dc2c6b2c717c6aed6833', 'both of from and to');

  done_testing;
};

subtest "get_voyage_key No.2" => sub {

  my $tst_file = 'get_voyage_key_2.json';
  my $tst_file_path = sprintf("%s/get_voyage_key/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # fromのみmessageIdがある場合
  is($vj->get_voyage_key, '10171204123649-d02e62705dc62966564c2c3b0581a509_None', 'from only');

  done_testing;
};

subtest "get_voyage_key No.3" => sub {

  my $tst_file = 'get_voyage_key_3.json';
  my $tst_file_path = sprintf("%s/get_voyage_key/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # toのみmessageIdがある場合
  is($vj->get_voyage_key, 'None_20171204123643-a4f1f1c35bd5dc2c6b2c717c6aed6833', 'to only');

  done_testing;
};

subtest "get_index_file_name No.1" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/get_index_file_name/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # from時刻: あり, to時刻: あり, type: "underway"
  is($vj->get_index_file_name, '20170202000000_20170202000001_0.json', 'type is underway');

  done_testing;
};

subtest "get_index_file_name No.2" => sub {

  my $tst_file = '2.json';
  my $tst_file_path = sprintf("%s/get_index_file_name/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # from時刻: あり, to時刻: あり, type: "in_port"
  is($vj->get_index_file_name, '20170202000000_20170202000001_9.json', 'type is in_port');

  done_testing;
};

subtest "get_latest_time No.1" => sub {

  my $tst_file = '10171204123649-d02e62705dc62966564c2c3b0581a509_20171204123643-a4f1f1c35bd5dc2c6b2c717c6aed6833_20170202110200.json';
  my $tst_file_path = sprintf("%s/get_latest_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # from, to, addition_reportがすべて取得でき、fromがもっとも新しい
  is($vj->get_latest_time, "2017-12-02T10:01:00Z", 'latest time is from');

  done_testing;
};

subtest "get_latest_time No.2" => sub {

  my $tst_file = '20171204123649-d02e62705dc62966564c2c3b0581a509_20171204123643-a4f1f1c35bd5dc2c6b2c717c6aed6833_20170202110200.json';
  my $tst_file_path = sprintf("%s/get_latest_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # to, addition_reportがすべて取得でき、toがもっとも新しい
  is($vj->get_latest_time, "2017-12-02T10:00:59Z", 'latest time is to');

  done_testing;
};

subtest "get_latest_time No.3" => sub {

  my $tst_file = '30171204123649-d02e62705dc62966564c2c3b0581a509_20171204123643-a4f1f1c35bd5dc2c6b2c717c6aed6833_20170202110200.json';
  my $tst_file_path = sprintf("%s/get_latest_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # addition_reportのみ2つ取得でき、そのうち1つがもっとも新しい
  is($vj->get_latest_time, "2017-12-02T10:00:58Z", 'latest time is addition_report');

  done_testing;
};

subtest "get_latest_time No.4" => sub {

  my $tst_file = '40171204123649-d02e62705dc62966564c2c3b0581a509_20171204123643-a4f1f1c35bd5dc2c6b2c717c6aed6833_20170202110200.json';
  my $tst_file_path = sprintf("%s/get_latest_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  # すべて取得できない
  is($vj->get_latest_time, FALSE, 'latest time is false');

  done_testing;
};

#subtest "get_latest_time (enhancement test)" => sub {
#
#  my $tst_file = '50171204123649-d02e62705dc62966564c2c3b0581a509_20171204123643-a4f1f1c35bd5dc2c6b2c717c6aed6833_20170202110200.json';
#  my $tst_file_path = sprintf("%s/get_latest_time/%s", $test_data_dir, $tst_file);
#  my $jh = JsonHandler->new($log, $tst_file_path);
#  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));
#
#  is($vj->get_latest_time, "2017-12-02T10:00:57Z", 'latest time is addition_report(only contain 1 report)');
#
#  done_testing;
#};

subtest "upsert_report No.1" => sub {

  # アップデートするDaily情報。messaeIdが一致するfrom
  my $new_daily = '1_daily.json';
  my $daily_path = sprintf("%s/upsert_report/%s", $test_data_dir, $new_daily);
  my $jh_d = JsonHandler->new($log, $daily_path);

  # アップデートされるvoyage情報
  my $voy = 'voy.json';
  my $voy_path = sprintf("%s/upsert_report/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  my $res = $vj->upsert_report($jh_d->get_data);

  # 結果チェック（複数の評価項目があるので、is_deeplyでチェック) ※ is_deeplyでチェックするときはリファレンス形式で比較すること
  is_deeply(
    [$jh_v->get_item(["data", "include_reports", "from", "calc", "cp_go"]), $res],
    [$jh_d->get_item(["calc", "cp_go"]), TRUE], 'update from report');

  done_testing;
};

subtest "upsert_report No.2" => sub {

  # アップデートするDaily情報。messaeIdが一致するto
  my $new_daily = '2_daily.json';
  my $daily_path = sprintf("%s/upsert_report/%s", $test_data_dir, $new_daily);
  my $jh_d = JsonHandler->new($log, $daily_path);

  # アップデートされるvoyage情報
  my $voy = 'voy.json';
  my $voy_path = sprintf("%s/upsert_report/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  my $res = $vj->upsert_report($jh_d->get_data);

  # 結果チェック（複数の評価項目があるので、is_deeplyでチェック)
  is_deeply(
    [$jh_v->get_item(["data", "include_reports", "to", "calc", "cp_go"]), $res],
    [$jh_d->get_item(["calc", "cp_go"]), TRUE], 'update to report');

  done_testing;
};

subtest "upsert_report No.3" => sub {

  # アップデートするDaily情報。messaeIdが一致するaddition_report
  my $new_daily = '3_daily.json';
  my $daily_path = sprintf("%s/upsert_report/%s", $test_data_dir, $new_daily);
  my $jh_d = JsonHandler->new($log, $daily_path);

  # アップデートされるvoyage情報
  my $voy = 'voy.json';
  my $voy_path = sprintf("%s/upsert_report/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  my $r = $vj->upsert_report($jh_d->get_data);
  my $res = $jh_v->get_item(["data", "include_reports", "addition_report"]);
  my @res = values(%{$res->[0]}); # アップデート対象の要素を取得

  # 結果チェック（複数の評価項目があるので、is_deeplyでチェック)
  is_deeply(
    [$res[0]->{calc}{cp_go}, $r],
    [$jh_d->get_item(["calc", "cp_go"]), TRUE], 'update addition report');

  done_testing;
};

subtest "upsert_report No.4" => sub {

  # アップデートするDaily情報。messaeIdが一致しないaddition_report
  my $new_daily = '4_daily.json';
  my $daily_path = sprintf("%s/upsert_report/%s", $test_data_dir, $new_daily);
  my $jh_d = JsonHandler->new($log, $daily_path);

  # アップデートされるvoyage情報
  my $voy = 'voy.json';
  my $voy_path = sprintf("%s/upsert_report/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  my $r = $vj->upsert_report($jh_d->get_data);

  my $res = $jh_v->get_item(["data", "include_reports", "addition_report"]);
  my @res = values(%{$res->[1]}); # 追加された要素を取得

  # 結果チェック（複数の評価項目があるので、is_deeplyでチェック)
  # 追加された要素は取得できるか、addition_reportの要素は増えたか(念のため)、結果はtrueか、をチェック
  is_deeply(
    [$res[0]->{calc}{cp_go}, scalar(@$res), $r],
    [$jh_d->get_item(["calc", "cp_go"]), 2, TRUE], 'insert addition report');

  done_testing;
};

subtest "upsert_report No.5" => sub {

  # アップデートするDaily情報。messaeIdが一致しないaddition_report
  my $new_daily = '5_daily.json';
  my $daily_path = sprintf("%s/upsert_report/%s", $test_data_dir, $new_daily);
  my $jh_d = JsonHandler->new($log, $daily_path);

  # アップデートされるvoyage情報。addition_reportが航海判定データに存在しない
  my $voy = 'voy_no_addition.json';
  my $voy_path = sprintf("%s/upsert_report/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  my $res = $vj->upsert_report($jh_d->get_data);

  # 結果チェック（複数の評価項目があるので、is_deeplyでチェック)
  # fromの要素に変化は無いか、toの要素に変化は無いか、addition_reportは存在するようになるか、結果はtrueか、をチェック
  # ※ 仕様書には書いていないが念のため、データ構造のチェックを厳密に行う。
  is_deeply(
    [
      $jh_v->get_item(["data", "include_reports", "from", "calc", "cp_go"]),
      $jh_v->get_item(["data", "include_reports", "to", "calc", "cp_go"]),
      scalar @{$jh_v->get_item(["data", "include_reports", "addition_report"])},
      $res
    ],
    [
      '',
      '',
      1,
      TRUE
    ], 'create new data');

  done_testing;
};

subtest "upsert_report No.6" => sub {

  my $voy = 'voy.json';
  my $voy_path = sprintf("%s/upsert_report/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
  my ($stdout, $strerr) = capture {

    is($vj->upsert_report(), FALSE, 'no parameter');
  };

  # 引数なしで実行された場合、想定したエラー結果が出力されているかをチェック
  like($strerr, qr/update data not found/, 'output error info');

  done_testing;
};

subtest "get_all_reports No.1" => sub {

  my $voy = '1.json';
  my $voy_path = sprintf("%s/get_all_reports/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  my $res = $vj->get_all_reports;

  my @res_k = map { keys(%{$_}) } @$res; # key summary
  my @res_v = map { my @v = values(%{$_}); $v[0]->{calc}{cp_go} } @$res; # values summary

  # 結果チェック（複数の評価項目があるので、is_deeplyでチェック)
  # 当メソッドは、from, to, addition_reportの並びを、{レポート種別 => レポートデータ}の配列にまとめるメソッドであるため、
  # キーの部分が想定通りであるかの確認と、値の部分が想定通りであるかの確認を行っている

  # from取得：あり、 to取得：あり、 addition_report：あり
  is_deeply(
    [
      \@res_k,
      \@res_v
    ],
    [
      ['voyage_start', 'voyage_end', 'anchor_end'],
      ['f', 't', 'a']
    ], 'contains all');

  done_testing;
};

subtest "get_all_reports No.2" => sub {

  my $voy = '2.json';
  my $voy_path = sprintf("%s/get_all_reports/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  my $res = $vj->get_all_reports;

  my @res_k = map { keys(%{$_}) } @$res; # key summary
  my @res_v = map { my @v = values(%{$_}); $v[0]->{calc}{cp_go} } @$res; # values summary

  # from取得：なし、 to取得：あり、 addition_report：あり
  is_deeply(
    [
      \@res_k,
      \@res_v
    ],
    [
      ['voyage_end', 'anchor_end'],
      ['t', 'a']
    ], 'contains to, addition');

  done_testing;
};

subtest "get_all_reports No.3" => sub {

  my $voy = '3.json';
  my $voy_path = sprintf("%s/get_all_reports/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  my $res = $vj->get_all_reports;

  my @res_k = map { keys(%{$_}) } @$res; # key summary
  my @res_v = map { my @v = values(%{$_}); $v[0]->{calc}{cp_go} } @$res; # values summary

  # from取得：なし、 to取得：なし、 addition_report：あり
  is_deeply(
    [
      \@res_k,
      \@res_v
    ],
    [
      ['anchor_end'],
      ['a']
    ], 'contains addition only');

  done_testing;
};

subtest "get_all_reports No.4" => sub {

  my $voy = '4.json';
  my $voy_path = sprintf("%s/get_all_reports/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  # from取得：なし、 to取得：なし、 addition_report：なし
  is_deeply($vj->get_all_reports, [], 'no contain');

  done_testing;
};

subtest "get_all_reports No.5" => sub {

  my $voy = '5.json';
  my $voy_path = sprintf("%s/get_all_reports/%s", $test_data_dir, $voy);
  my $jh_v = JsonHandler->new($log, $voy_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh_v->get_item(["data", "include_reports"]));

  # すべて「あり」だが、無効なので取得されない
  is_deeply($vj->get_all_reports, [], 'no contain - all invalid');

  done_testing;
};

subtest "convert_start_time No.1" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/convert_start_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  $vj->convert_start_time;

  # check
  is($vj->get_to_data->{calc}{start_time}, $vj->get_from_data->{calc}{report_time}, 'data convert');

  done_testing;
};

subtest "convert_start_time No.2" => sub {

  my $tst_file = '2.json';
  my $tst_file_path = sprintf("%s/convert_start_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  $vj->convert_start_time;

  # check
  is($vj->get_to_data->{calc}{start_time}, "", 'data convert');

  done_testing;
};

subtest "convert_start_time No.3" => sub {

  my $tst_file = '3.json';
  my $tst_file_path = sprintf("%s/convert_start_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  $vj->convert_start_time;

  # check
  is($vj->get_to_data->{calc}{start_time}, "2017-02-01T00:00:00Z", 'data convert');

  done_testing;
};

subtest "convert_start_time No.4" => sub {

  my $tst_file = '4.json';
  my $tst_file_path = sprintf("%s/convert_start_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  $vj->convert_start_time;

  # check
  is($vj->get_to_data->{calc}{start_time}, "2017-02-01T00:00:00Z", 'data convert');

  done_testing;
};

subtest "convert_start_time No.5" => sub {

  my $tst_file = '5.json';
  my $tst_file_path = sprintf("%s/convert_start_time/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # voyage情報ファイルから、航海判定データの部分を指定してインスタンス化
  my $vj = VoyageJudgeHandler->new($log, $jh->get_item(["data", "include_reports"]));

  $vj->convert_start_time;

  # check
  is($vj->get_to_data->{calc}{start_time}, "", 'data convert');

  done_testing;
};

done_testing;
