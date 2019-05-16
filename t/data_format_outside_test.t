#! /usr/local/bin/perl
# $Id: data_format_outside_test.t 35732 2019-01-18 06:02:06Z p0660 $

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
use DataFormat;

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

###############################
# input data
###############################
# 上下限テスト
# 上限値内 テスト
subtest "data upper limit test" => sub {
  my $key = 'foc_dogo';
  my $value = '999.99';
  my $target_id = 'voyage';
  # test
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);
  # 判定結果の取得
  my $result = $data_format->range_check_proc_outside($key, $value, $target_id);
  
  is($result, 1, 'upper limit diff ok');

  done_testing;
};

# 下限値内　テスト
subtest "data format lower limit test" => sub {
  my $key = 'foc_dogo';
  my $value = '0.00';
  my $target_id = 'in_port';
  # test
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);
  # 判定結果の取得
  my $result = $data_format->range_check_proc_outside($key, $value, $target_id);
  
  is($result, 1, 'lower limit diff ok');

  done_testing;
};

# 上限値外　テスト
subtest "data format upper over limit test" => sub {
  my $key = 'foc_dogo';
  my $value = '1000.00';
  my $target_id = 'voyage';
  # test
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);

  # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
  my ($stdout, $strerr) = capture {
    # 判定結果の取得
    $data_format->range_check_proc_outside($key, $value, $target_id);
  };
  # 判定結果の取得
  my $result = $data_format->range_check_proc_outside($key, $value, $target_id);
  is($result, 0, 'upper over limit diff ok');
  # 処理が実施されてないか
  like($strerr, qr/Input value is higher than the upper limit.\n/, 'not exec process');

  done_testing;
};

# 下限値外　テスト
subtest "data format lower over limit test" => sub {
  my $key = 'foc_dogo';
  my $value = '-1';
  my $target_id = 'in_port';
  # test
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);

  # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
  my ($stdout, $strerr) = capture {
    # 判定結果の取得
    $data_format->range_check_proc_outside($key, $value, $target_id);
  };
  # 判定結果の取得
  my $result = $data_format->range_check_proc_outside($key, $value, $target_id);
  is($result, 0, 'lower over limit diff ok');
  # 処理が実施されてないか
  like($strerr, qr/Input value is lower than the lower limit.\n/, 'not exec process');

  done_testing;
};

# 定義ファイル取得失敗　テスト
subtest "data format upperlower Definition file test" => sub {
  my $key = 'foc_dogo';
  my $value = '999999.999999';
  my $target_id = '';
  # test
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);
  # 判定結果の取得
  my $result = $data_format->range_check_proc_outside($key, $value, $target_id);
  
  is($result, 1, 'upperlower Definition file diff ok');

  done_testing;
};

# 四捨五入テスト
# 四捨五入切上げ　テスト
subtest "data format rounding　up limit test" => sub {
  my $key = 'foc_dogo';
  my $value = '99.995';
  my $target_id = 'voyage';
  # test
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);
  # 判定結果の取得
  my $result = $data_format->rounding_off_proc_outside($key, $value, $target_id);
  is($result, '100.00', 'rounding　up　diff ok');
  done_testing;
};

# 四捨五入切捨て　テスト
subtest "data format rounding　down limit test" => sub {
  my $key = 'foc_dogo';
  my $value = '99.994';
  my $target_id = 'voyage';
  # test
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);
  # 判定結果の取得
  my $result = $data_format->rounding_off_proc_outside($key, $value, $target_id);
  is($result, '99.99', 'rounding　down　diff ok');

  done_testing;
};

# 定義ファイル取得失敗　テスト
subtest "Definition file test" => sub {
  my $key = 'foc_dogo';
  my $value = '999999.999999';
  my $target_id = '';
  # test
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);
  # 判定結果の取得
  my $result = $data_format->rounding_off_proc_outside($key, $value, $target_id);
  is($result, '999999.999999', 'rounding Definition file diff ok');

  done_testing;
};

done_testing;



