# $Id: voyage_data_judge.t 35732 2019-01-18 06:02:06Z p0660 $

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

# test module
use VoyageDataJudge;

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

# test
subtest "judge valid pattern(No.1 ~ No.3)" => sub {
  
  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'valid_1.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;

  # 判定結果が正しいかを確認
  # ship_infoが格納されているか、typeが正しいか、判定結果は収集データから正しく生成されているか、を確認
  {
    my $test_name = 'No.1';
    my $n = "0";
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});      # 判定結果データ
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]); # 収集データ（判定結果の元ネタ)
    
    # ※ データ構造を細かくチェックするので、Test::Defferences::eq_or_diffを使用。間違っていたらその箇所だけdiff形式で指摘してくれる
    eq_or_diff(
      [
        $res->[$n]->{ship_info}, 
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'in_port',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  # 判定結果が正しいかを確認
  {
    my $test_name = 'No.2';
    my $n = "1";
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    eq_or_diff(
      [
        $res->[$n]->{ship_info},
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'underway',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  # 判定結果が正しいかを確認
  {
    my $test_name = 'No.3';
    my $n = "2";
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    eq_or_diff(
      [
        $res->[$n]->{ship_info},
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'in_port',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  done_testing;
};

subtest "judge invalid pattern(No.4 ~ No.6)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'invalid_1.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;

  # 判定結果が正しいかを確認
  # ship_infoが格納されているか、typeが正しいか、判定結果は収集データから正しく生成されているか、を確認
  {
    my $test_name = 'No.4';
    my $n = "0";
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});      # 判定結果データ
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]); # 収集データ（判定結果の元ネタ)
    
    # ※ データ構造を細かくチェックするので、Test::Defferences::eq_or_diffを使用。間違っていたらその箇所だけdiff形式で指摘してくれる
    eq_or_diff(
      [
        $res->[$n]->{ship_info}, 
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'underway',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  # 判定結果が正しいかを確認
  {
    my $test_name = 'No.5';
    my $n = 1;
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    eq_or_diff(
      [
        $res->[$n]->{ship_info},
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'underway',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  # 判定結果が正しいかを確認
  {
    my $test_name = 'No.6 - 1';
    my $n = 2;
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    eq_or_diff(
      [
        $res->[$n]->{ship_info},
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'in_port',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  # 判定結果が正しいかを確認
  {
    my $test_name = 'No.6 - 2';
    my $n = 3;
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    eq_or_diff(
      [
        $res->[$n]->{ship_info},
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'in_port',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  done_testing;
};

subtest "judge year-over pattern(No.7)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'year_over_1.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;
  
  # 除外されるかを確認
  cmp_deeply($res, [], 'out of range - last year to last year');

  done_testing;
};

subtest "judge year-over pattern(No.8)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'year_over_2.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;
  
  # 除外されないかを確認
  {
    my $test_name = 'within range - year overs first';
    my $n = "0";
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    eq_or_diff(
      [
        $res->[$n]->{ship_info},
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'underway',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  done_testing;
};

subtest "judge year-over pattern(No.9)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'year_over_3.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;
  
  # 除外されないかを確認
  {
    my $test_name = 'within range - year overs last';
    my $n = "0";
    my $res_h = DailyReportHandler->new($log, $res->[$n]->{to});
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    eq_or_diff(
      [
        $res->[$n]->{ship_info},
        $res->[$n]->{type},
        $res_h->get_start_time,
        $res_h->get_report_time
      ],
      [
        $drh->get_ship_info,
        'underway',
        $src_h->get_start_time,
        $src_h->get_report_time
      ], $test_name);
  }

  done_testing;
};

subtest "judge year-over pattern(No.10)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'year_over_4.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;
  
  # 除外されるかを確認
  cmp_deeply($res, [], 'out of range - next year to next year');

  done_testing;
};

subtest "addition report handling pattern(No.11)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'addition_1.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;
  
  # addition_reportが正しく追加されているか確認
  {
    my $test_name = 'valid addition info contain';
    my $n = "0";
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    # 追加されたデータの数が正しいか
    cmp_ok(scalar @{$res->[$n]->{addition_report}}, '==', 2, 'valid numbers contain');

    # 追加されたデータはfromとtoの範囲内であるか
    cmp_deeply(
      $res->[$n]->{addition_report},
      array_each(

        # データ構造のvalueの部分を検査
        hash_each(
          {
            report_info => {
              # Test::Deepの正規表現マッチャメソッド(re)に、範囲内のデータを示す"within"を渡してチェック
              for_judge_voyage => re("within")
            },
            calc => is_hash_ref,
            custom => is_array_ref
          }
        )
      )
      , $test_name);
  }

  done_testing;
};

subtest "addition report handling pattern(No.12)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'addition_2.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;
  
  # addition_reportが存在しないか確認
  {
    my $test_name = 'addition not exists';
    my $n = "0";
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    is($res->[$n]->{addition_report}, undef, $test_name);
  }

  done_testing;
};

subtest "addition report handling pattern(No.13)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'addition_3.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;
  
  # addition_reportが存在しないか確認
  {
    my $test_name = 'addition not exists';
    my $n = "0";
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    is($res->[$n]->{addition_report}, undef, $test_name);
  }

  done_testing;
};

subtest "addition report handling pattern(No.14)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  my $collected = 'addition_4.json';
  my $collected_path = sprintf("%s/judge/%s", $test_data_dir, $collected);
  my $jh_c = JsonHandler->new($log, $collected_path);
  
  # 収集データと、RMSから連携されたDailyデータを使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, $jh_c->get_data, $drh);
  $vdj->judge;
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;
  
  # addition_reportが存在しないか確認
  {
    my $test_name = 'addition not exists';
    my $n = "0";
    my $src_h = DailyReportHandler->new($log, $jh_c->get_data->[$n]);
    
    is($res->[$n]->{addition_report}, undef, $test_name);
  }

  done_testing;
};

subtest "no parameter pattern(No.15)" => sub {

  $log->Info("subtest start\n");

  my $daily = '1_daily.json';
  my $daily_path = sprintf("%s/judge/%s", $test_data_dir, $daily);
  my $drh = DailyReportHandler->new($log, $daily_path);

  # 異常ケース用に、空配列を使って航海判定を行う
  my $vdj = VoyageDataJudge->new($log, [], $drh);

  # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
  my ($stdout, $strerr) = capture {
  
    $vdj->judge;
  };
  
  # 判定結果の取得
  my $res = $vdj->get_judge_result;

  # 結果が空か
  cmp_deeply($res, [], 'no data create');

  # 処理が実施されてないか
  like($strerr, qr/please input collected data/, 'not exec process');

  done_testing;
};

done_testing;
