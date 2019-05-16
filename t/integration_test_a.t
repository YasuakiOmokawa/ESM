# $Id: integration_test_a.t 36403 2019-03-27 08:40:15Z p0660 $

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
use File::Path qw/mkpath rmtree/;
use File::Copy qw/copy move/;
use Time::HiRes;
use File::Copy::Recursive qw(fcopy rcopy dircopy);

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";
use lib '/usr/amoeba/lib/perl';

use JsonHandler;
use logging;
use EsmConf;
use MonthlyReportHandler;
use EsmDataDetector;


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

my $app_top = $EsmConf::BASE_TOP;
my $c_code  = 'CBA';
my $imo     = '9990009';
my $year    = '2018';

my $voy_dir        = "$app_top/data/esm3_voyage/$c_code/$imo";
my $daily_dir      = "$app_top/data/esm3_daily/$c_code/$imo";
my $nk_trg_dir     = "$app_top/spool/trigger/class_nk/$c_code/$imo";
my $annual_trg_dir = "$app_top/spool/annual_spool/$c_code/$imo";
my $annual_data_dir = "$app_top/data/annual/$c_code/$imo";

# initialize data directory
for ($voy_dir, $daily_dir, $nk_trg_dir, $annual_trg_dir, $annual_data_dir) {
  rmtree $_;
}
rmtree "$app_top/data/esm3_daily/$c_code/4234567"; # No.14用
# No.16用
rmtree "$app_top/data/esm3_daily/NEOM/9708980";
rmtree "$app_top/data/esm3_voyage/NEOM/9708980";
rcopy "$test_data_dir/esm_NEOM_9708980/esm3_daily/*", "$app_top/data/esm3_daily/NEOM/9708980";
rcopy "$test_data_dir/esm_NEOM_9708980/esm3_voyage/*", "$app_top/data/esm3_voyage/NEOM/9708980";

# 実施する処理
my $daily_cmd  = "$app_top/bin/daily/adjust_daily_data_v3.pl";
my $annual_eumrv_cmd = "$app_top/bin/annual/create_eumrv_annual_data.pl";
my $annual_imodcs_cmd = "$app_top/bin/annual/create_imodcs_annual_data.pl";
my $merge_cmd  = "$app_top/bin/daily/merge_error_layer.pl";

# 各種データ情報の取得モジュールを初期化
my $ed = EsmDataDetector->new($log, $c_code, $imo);

# test
$name = "No.1";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $file = 'rms_dep_1.json';
  my $file_path = sprintf("%s/%s", $test_data_dir, $file);
  my $jh = JsonHandler->new($log, $file_path);

  # dailyデータ作成　～　航海判定メイン処理　までを実施
  my @cmd = (
    $daily_cmd,
    $file_path
  );
  is(system(@cmd), '0', 'exec program');

  # データ生成確認
  # ※ 詳細はITaテスト仕様書を参照
  my @v_idx_all = glob("$voy_dir/voyage_index/*");
  my @v_info_all = glob("$voy_dir/voyage/*");
  my @v_idx_in = glob("$voy_dir/voyage_index/*_9.json");
  my $v_idx = JsonHandler->new($log, $v_idx_in[0]);
  my $v_info = JsonHandler->new($log, $v_idx->get_data->{voyage_file_path});
  my @annu_spool = `ls -1 $annual_trg_dir/*`;
  my @nk_spool = `ls -1 $nk_trg_dir/*`;

  cmp_ok(@v_info_all, '==', 1, 'info file number');
  cmp_ok(@v_idx_all, '==', 1, 'index file number');
  cmp_ok(@v_idx_in, '==', 1, 'exists in-port index file');
  is($v_info->get_data->{data}{record_type}, 'in_port', 'voyage type');
  cmp_ok(@annu_spool, '==', 2, 'annual trigger number');
  cmp_ok(@nk_spool, '==', 1, 'class nk trigger number');

  my $eumrv_res = grep {/eumrv/} @annu_spool;
  is($eumrv_res, TRUE, 'eumrv annual trigger exist');

  my $imodcs_res = grep {/imodcs/} @annu_spool;
  is($imodcs_res, TRUE, 'imodcs annual trigger exist');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.2";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $file = 'rms_arr_1.json';
  my $file_path = sprintf("%s/%s", $test_data_dir, $file);
  my $jh = JsonHandler->new($log, $file_path);

  # dailyデータ作成　～　航海判定メイン処理　までを実施
  my @cmd = (
    $daily_cmd,
    $file_path
  );
  is(system(@cmd), '0', 'exec program');

  # データ生成確認
  # ※ 詳細はITaテスト仕様書を参照
  my @v_info_all  = glob("$voy_dir/voyage/*");
  my @v_idx_all   = glob("$voy_dir/voyage_index/*");
  my @v_idx_in    = glob("$voy_dir/voyage_index/*_9.json");
  my @v_idx_under = glob("$voy_dir/voyage_index/*_0.json");
  my $v_idx       = JsonHandler->new($log, $v_idx_under[0]);
  my $v_info      = JsonHandler->new($log, $v_idx->get_data->{voyage_file_path});
  my @annu_spool  = `ls -1 $annual_trg_dir/*`;

  cmp_ok(@v_info_all, '==', 2, 'info file number');
  cmp_ok(@v_idx_all, '==', 2, 'index file number');
  cmp_ok(@v_idx_in, '==', 1, 'exists in-port index file');
  cmp_ok(@v_idx_under, '==', 1, 'add underway index file');
  is($v_info->get_data->{data}{record_type}, 'voyage', 'voyage type');
  cmp_ok(@annu_spool, '==', 4, 'annual trigger number');
  is($v_info->get_data->{data}{for_row}{data}{dep_date_time}, '2017-12-31T15:54:00Z', 'convert voyage start time');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.3";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $file = 'rms_anch_end_1.json';
  my $file_path = sprintf("%s/%s", $test_data_dir, $file);
  my $jh = JsonHandler->new($log, $file_path);

  # dailyデータ作成　～　航海判定メイン処理　までを実施
  my @cmd = (
    $daily_cmd,
    $file_path
  );
  is(system(@cmd), '0', 'exec program');

  # データ生成確認
  # ※ 詳細はITaテスト仕様書を参照
  my @v_info_all  = glob("$voy_dir/voyage/*");
  my @v_idx_all   = glob("$voy_dir/voyage_index/*");
  my @v_idx_under = glob("$voy_dir/voyage_index/*_0.json");
  my $v_idx       = JsonHandler->new($log, $v_idx_under[0]);
  my $v_info      = JsonHandler->new($log, $v_idx->get_data->{voyage_file_path});
  my @annu_spool  = `ls -1 $annual_trg_dir/*`;

  cmp_ok(@v_info_all, '==', 2, 'info file number');
  cmp_ok(@v_idx_all, '==', 2, 'index file number');
  cmp_ok(@v_idx_under, '==', 1, 'exists underway index file');
  like($v_idx->get_data->{voyage_file_path}, qr/.*_20181023094506\.json$/, 'update info file name');
  cmp_ok(scalar(@{$v_info->get_data->{data}{include_reports}{addition_report}}), '==', 1, 'adding report');
  cmp_ok(@annu_spool, '==', 4, 'annual trigger number');


  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.4";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $file = 'rms_dep_2.json';
  my $file_path = sprintf("%s/%s", $test_data_dir, $file);
  my $jh = JsonHandler->new($log, $file_path);

  # dailyデータ作成　～　航海判定メイン処理　までを実施
  my @cmd = (
    $daily_cmd,
    $file_path
  );
  is(system(@cmd), '0', 'exec program');

  # データ生成確認
  # ※ 詳細はITaテスト仕様書を参照
  my @v_idx_all = glob("$voy_dir/voyage_index/*");
  my @v_info_all = glob("$voy_dir/voyage/*");
  my @v_idx_in = glob("$voy_dir/voyage_index/*_9.json");
  my @v_idx_under = glob("$voy_dir/voyage_index/*_0.json");
  my $v_idx = JsonHandler->new($log, $v_idx_under[0]);

  cmp_ok(@v_info_all, '==', 3, 'info file number');
  cmp_ok(@v_idx_all, '==', 3, 'index file number');
  cmp_ok(@v_idx_in, '==', 2, 'exists in-port index file');
  cmp_ok(@v_idx_under, '==', 1, 'exists correct underway index file');
  like($v_idx->get_data->{voyage_file_path}, qr/30181022041647-5422f110b03cf1c9cf84b61b05ecbf14_20181022094237-06f239878bf268a32d49b31e0abdb6eb/, 'new voyage key');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.5";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $file = 'rms_dep_3.json';
  my $file_path = sprintf("%s/%s", $test_data_dir, $file);
  my $jh = JsonHandler->new($log, $file_path);

  # dailyデータ作成　～　航海判定メイン処理　までを実施
  my @cmd = (
    $daily_cmd,
    $file_path
  );
  is(system(@cmd), '0', 'exec program');

  # データ生成確認
  # ※ 詳細はITaテスト仕様書を参照
  my @v_idx_all   = glob("$voy_dir/voyage_index/*");
  my @v_info_all  = glob("$voy_dir/voyage/*");
  my @v_idx_in    = glob("$voy_dir/voyage_index/*_9.json");
  my @v_idx_under = glob("$voy_dir/voyage_index/*_0.json");
  my $v_idx       = JsonHandler->new($log, $v_idx_in[1]);
  my $v_info      = JsonHandler->new($log, $v_idx->get_data->{voyage_file_path});
  my $v_idx_un    = JsonHandler->new($log, $v_idx_under[0]);
  my $v_info_un   = JsonHandler->new($log, $v_idx_un->get_data->{voyage_file_path});

  cmp_ok(@v_info_all, '==', 3, 'info file number');
  cmp_ok(@v_idx_all, '==', 3, 'index file number');
  cmp_ok(@v_idx_in, '==', 2, 'exists in-port index file');
  cmp_ok(@v_idx_under, '==', 1, 'exists correct underway index file');
  is($v_info->get_data->{data}{for_row}{data}{voyage_number}, 'upd9999', 'update value');
  is($v_info_un->get_data->{data}{for_row}{data}{dep_date_time}, '2018-06-10T21:24:00Z', 'convert voyage start time');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.6";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $file = 'rms_dep_4.json';
  my $file_path = sprintf("%s/%s", $test_data_dir, $file);
  my $jh = JsonHandler->new($log, $file_path);

  # dailyデータ作成　～　航海判定メイン処理　までを実施
  my @cmd = (
    $daily_cmd,
    $file_path
  );
  is(system(@cmd), '0', 'exec program');

  # データ生成確認
  # ※ 詳細はITaテスト仕様書を参照
  my @v_idx_all   = glob("$voy_dir/voyage_index/*");
  my @v_info_all  = glob("$voy_dir/voyage/*");
  my @v_idx_in    = glob("$voy_dir/voyage_index/*_9.json");
  my @v_idx_under = glob("$voy_dir/voyage_index/*_0.json");
  my $v_idx       = JsonHandler->new($log, $v_idx_under[0]);

  cmp_ok(@v_info_all, '==', 2, 'info file number');
  cmp_ok(@v_idx_all, '==', 2, 'index file number');
  cmp_ok(@v_idx_in, '==', 1, 'exists in-port index file');
  cmp_ok(@v_idx_under, '==', 1, 'exists correct underway index file');
  like($v_idx->get_data->{voyage_file_path}, qr/20181022041647-5422f110b03cf1c9cf84b61b05ecbf14_20181022094237-06f239878bf268a32d49b31e0abdb6eb/, 'new voyage key');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.7, 8, 9, 13 - eumrv";
subtest $name => sub {

  $log->Info($start_msg, $name);

  diag "'Forked inside ~' is not error, Test::API informed it and have no problem of business logic";
  diag "its bad timing take no conflict";

  # 削除用の年間値ファイルを作成
  my $fake_year = '2020';
  my $annu_dir = "$app_top/data/annual/$c_code/$imo/$fake_year";
  mkpath $annu_dir;
  `touch $annu_dir/eu_mrv_annual.json`;
  is(-f "$annu_dir/eu_mrv_annual.json", TRUE, 'No.13 - pre annual data creation');

  # 集計用の航海データを準備（集計用データがないと期限切れ年間値データは削除できないため）
  rcopy "$test_data_dir/$c_code/$imo/voyage/no_13/*", "$voy_dir/voyage";
  rcopy "$test_data_dir/$c_code/$imo/voyage_index/no_13/*", "$voy_dir/voyage_index";

  # チェック用の年間値トリガー作成
  my $content = {
     "client_code" => $c_code,
     "imo_no"      => $imo,
     "year"        => $fake_year
  };
  my $fake_eumrv_annual = $ed->eumrv_annual_trigger($fake_year);

  my $jh = JsonHandler->new($log, $content);
  $jh->set_save_path($fake_eumrv_annual);
  $jh->save;

  # 年間値計算メイン処理の準備
  my @cmd = (
    $annual_eumrv_cmd
  );

  # プロセスを複製(子プロセスを生成) ※ Windowsではスレッドを使って擬似的にfork()を実現してるっぽいので、うまく動きませんでした。。
  defined(my $pid = fork) or die "Cannot fork: $!";

  # 子プロセスはfork()の戻り値が"0"
  if (!$pid) {

    is(system(@cmd), '0', 'No.7 - exec program');
      my ($st, $err) = capture {
        is(-f "$annu_dir/eu_mrv_annual.json", undef, 'No.13 - no calculate item and no create/delete annual file');
      };
  } else {

    defined(my $pid = fork) or die "Cannot fork: $!";
    if (!$pid) {
      push @cmd, '2';
      is(system(@cmd), '0', 'No.8 - do not conflict');
    } else {
      Time::HiRes::sleep(0.001);
      push @cmd, '6';
      # 標準エラー出力($log->Error()の出力)をキャッチ
      my ($stdout, $strerr) = capture {

        system(@cmd);
      };

      # エラーメッセージの内容チェック
      like($strerr, qr/Can\'t flock/, 'No.9 - parent conflict ok');
      wait; # 子プロセスの終了を待つ
    }
    wait; # 子プロセスの終了を待つ
  }

  $log->Info($end_msg, $name);
  done_testing;
};

Time::HiRes::sleep(0.5);

$name = "No.7, 8, 9, 13 - imodcs";
subtest $name => sub {

  $log->Info($start_msg, $name);

  diag "'Forked inside ~' is not error, Test::API informed it and have no problem of business logic";
  diag "its bad timing take no conflict";

  # 削除用の年間値ファイルを作成
  my $fake_year = '2020';
  my $annu_dir = "$app_top/data/annual/$c_code/$imo/$fake_year";
  mkpath $annu_dir;
  `touch $annu_dir/imo_dcs_annual.json`;
  is(-f "$annu_dir/imo_dcs_annual.json", TRUE, 'No.13 - pre annual data creation');

  # 集計用の航海データを準備（集計用データがないと期限切れ年間値データは削除できないため）
  rcopy "$test_data_dir/$c_code/$imo/voyage/no_13/*", "$voy_dir/voyage";
  rcopy "$test_data_dir/$c_code/$imo/voyage_index/no_13/*", "$voy_dir/voyage_index";

  # チェック用の年間値トリガー作成
  my $content = {
     "client_code" => $c_code,
     "imo_no"      => $imo,
     "year"        => $fake_year
  };
  my $fake_annual = $ed->imodcs_annual_trigger($fake_year);

  my $jh = JsonHandler->new($log, $content);
  $jh->set_save_path($fake_annual);
  $jh->save;

  # 年間値計算メイン処理の準備
  my @cmd = (
    $annual_imodcs_cmd
  );

  # プロセスを複製(子プロセスを生成) ※ Windowsではスレッドを使って擬似的にfork()を実現してるっぽいので、うまく動きませんでした。。
  defined(my $pid = fork) or die "Cannot fork: $!";

  # 子プロセスはfork()の戻り値が"0"
  if (!$pid) {

    is(system(@cmd), '0', 'No.7 - exec program');
      my ($st, $err) = capture {
        is(-f "$annu_dir/imo_dcs_annual.json", undef, 'No.13 - no calculate item and no create/delete annual file');
      };
  } else {

    defined(my $pid = fork) or die "Cannot fork: $!";
    if (!$pid) {
      push @cmd, '2';
      is(system(@cmd), '0', 'No.8 - do not conflict');
    } else {
      Time::HiRes::sleep(0.001);
      push @cmd, '6';
      # 標準エラー出力($log->Error()の出力)をキャッチ
      my ($stdout, $strerr) = capture {

        system(@cmd);
      };

      # エラーメッセージの内容チェック
      like($strerr, qr/Can\'t flock/, 'No.9 - parent conflict ok');
      wait; # 子プロセスの終了を待つ
    }
    wait; # 子プロセスの終了を待つ
  }

  $log->Info($end_msg, $name);
  done_testing;
};

Time::HiRes::sleep(0.5);

$name = "No.10";
subtest $name => sub {

  $log->Info($start_msg, $name);


  # 年間値トリガー全削除
  my $all_spool_dir = sprintf("%s/*/*/*.json", "$app_top/spool/annual_spool");
  `rm -rf $all_spool_dir`;

  # 年間値計算メイン処理
  is(system($annual_eumrv_cmd), '0', 'No.10 - eumrv');
  is(system($annual_imodcs_cmd), '0', 'No.10 - imodcs');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.11";
subtest $name => sub {

  $log->Info($start_msg, $name);


  # 不正な年間値トリガー作成
  my $content = {
     "client_code" => $c_code,
     "imo_no"      => $imo,
     "year"        => "3020"
  };
  my $fake_imodcs_annual = $ed->imodcs_annual_trigger("3020");

  my $jh = JsonHandler->new($log, $content);
  $jh->set_save_path($fake_imodcs_annual);
  $jh->save;

  # 年間値計算メイン処理
  my @cmd = (
    $annual_imodcs_cmd
  );

  is(system(@cmd), '0', 'No.11');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.12";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # 不正トリガーのimo内容を変更
  my $fake_imodcs_annual = $ed->imodcs_annual_trigger("3020");
  my $jh = JsonHandler->new($log, $fake_imodcs_annual);
  $jh->get_data->{imo_no} = '9990001';
  $jh->save;

  # 年間値計算メイン処理
  my @cmd = (
    $annual_imodcs_cmd
  );

  is(system(@cmd), '0', 'No.12');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.14";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # アップデートデータをセット
  my $file = '06.json';
  my $file_path = sprintf("%s/%s", $test_data_dir, $file);
  my $mv_path = "$app_top/data/esm3_daily/$c_code/4234567/2017/";
  mkpath $mv_path;
  `cp $file_path $mv_path`;

  # 更新不正ファイル
  my $e_file = 'merge_error_test.json';
  my $e_file_path = sprintf("%s/%s", $test_data_dir, $e_file);

  # 処理を実施
  my @cmd = (
    $merge_cmd,
    $e_file_path
  );

  is(system(@cmd), '0', 'exec ok');

  # データは上書きされているか？
  my $jh = JsonHandler->new($log, "$app_top/data/esm3_daily/$c_code/4234567/2017/06.json");
  is($jh->get_data->{report}->[0]->{error}->[0]->{edit_data}->[0]->{base_value},
    '905T', 'add error layer');
  is($jh->get_data->{report}->[0]->{calc}{voyage_num}, '905T', 'replace base value');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.15, No.18";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # テスト用の航海インデックスファイルを用意
  rcopy "$test_data_dir/no_15_and_18/*", "$voy_dir/voyage_index";

  # 年間値トリガー作成
  my $content = {
     "client_code" => $c_code,
     "imo_no"      => $imo,
     "year"        => $year
  };
  my $fake_imodcs_annual = $ed->imodcs_annual_trigger($year);
  my $fake_eumrv_annual = $ed->eumrv_annual_trigger($year);

  my $jh = JsonHandler->new($log, $content);
  $jh->set_save_path($fake_eumrv_annual); $jh->save;
  $jh->set_save_path($fake_imodcs_annual); $jh->save;

  # 年間値計算メイン処理を実施
  is(system($annual_eumrv_cmd), '0', "No.15");
  is(system($annual_imodcs_cmd), '0', "No.18");

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.16";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $file = '20181128101800_017.json';
  my $file_path = sprintf("%s/%s/%s", $test_data_dir, 'esm_NEOM_9708980', $file);
  my $jh = JsonHandler->new($log, $file_path);

  # is(1, 1, 'dummy check');

  # dailyデータ作成　～　航海判定メイン処理　までを実施
  my @cmd = (
    $daily_cmd,
    $file_path
  );
  is(system(@cmd), '0', 'exec program');

  $log->Info($end_msg, $name);
  done_testing;
};

$name = "No.17";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # No.17用の前処理
  my $month = "$test_data_dir/outlier/03.json";
  my $path = "$app_top/data/esm3_daily/NSU/9552915/2018";
  mkpath $path unless -d $path;
  `cp $month $path`;

  my $file = 'outlier_rep_1.json';
  my $file_path = sprintf("%s/%s/%s", $test_data_dir, 'outlier', $file);
  my $jh = JsonHandler->new($log, $file_path);

  # dailyデータ作成を実施
  my @cmd = (
    $daily_cmd,
    $file_path
  );
  is(system(@cmd), '0', 'exec program');

  # チェック
  my $mh = MonthlyReportHandler->new($log, $month);
  is($mh->search_data('20180328093409-eb0842a08c7c00d9290537f21b4d46ba', '006'),
    undef, 'not save particular data');

  $log->Info($end_msg, $name);
  done_testing;
};

done_testing;

END{
  $log->Close() if( defined( $log ) );
}
