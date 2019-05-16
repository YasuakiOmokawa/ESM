# $Id: emission_per_voyage_get_display_data.t 36136 2019-03-08 08:16:54Z p0660 $

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
use Test::Deep::Matcher;
use Test::Differences;
use LWP::UserAgent;
use HTTP::Cookies;
use File::Copy 'copy';
use File::Path 'mkpath';
use Test::Deep;
use JSON;

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";
use lib '/usr/amoeba/lib/perl';

use logging;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;

my $log  = logging->Open( $log_fname ) ;

my $start_msg = "=== Subtest %s Start ===\n";
my $end_msg = "=== Subtest %s End ===\n";
my $name;
my $num;

# test
# 下準備
my ( $cli_code, $imo_no,   $year,  $target_id, $account_id)
  = ('CBA'    , '2234567', '2018', 'imo_dcs',  '3');
my $tst_file_dir  = sprintf( "%s/t/data/%s", $top_dir, $prog_base);
my $dest_file_dir = sprintf( "%s/data/annual/%s/%s/%s", $top_dir, $cli_code, $imo_no, $year);
mkpath $dest_file_dir if !-d $dest_file_dir;
copy "$tst_file_dir/imo_dcs_annual.json", "$dest_file_dir/imo_dcs_annual.json";

$num = '2~3';
$name = "get data - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  # リクエストパラメータの設定
  my $param = {
    client_code   => $cli_code,
    imo_num       => $imo_no,
    select_year   => $year,
    get_target_id => $target_id,
    account_id    => $account_id,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  my $data = $c->{data}{result_data};
  is($res->is_success, 1, 'success status');
  is($c->{result}, 'OK', 'result');
  cmp_deeply(
    [
      $data->[0]->{eu_mrv},
      $data->[1]->{eu_mrv},
      $data->[2]->{eu_mrv},
      $data->[3]->{eu_mrv},
    ],
    [
      'beginning_of_year',
      'middle_of_year',
      'end_of_year',
      'summary',
    ],
  'sort data');
  cmp_deeply(
    [
      $data->[0]->{foc_dogo},
      $data->[1]->{foc_dogo},
      $data->[2]->{foc_dogo},
      $data->[3]->{foc_dogo},
    ],
    [
      '0.01',
      '0.02',
      '0.03',
      '0.04',
    ],
  'catch data');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '4';
$name = "lack of parameter - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  # リクエストパラメータの設定
  my $param = {
    # client_code   => $cli_code,
    # imo_num       => $imo_no,
    # select_year   => $year,
    get_target_id => $target_id,
    # account_id    => $account_id,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  is($c->{result}, 'NG', 'result');
  is($c->{msg}, 'failed because the client_code and imo_num and select_year and account_id is empty',
    'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '5';
$name = "lack of parameter - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  # リクエストパラメータの設定
  my $param = {
    client_code   => $cli_code,
    # imo_num       => $imo_no,
    select_year   => $year,
    get_target_id => $target_id,
    account_id    => $account_id,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  is($c->{result}, 'NG', 'result');
  is($c->{msg}, 'failed because the imo_num is empty',
    'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '6';
$name = "lack of parameter - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  # リクエストパラメータの設定
  my $param = {
    client_code   => $cli_code,
    imo_num       => $imo_no,
    # select_year   => $year,
    get_target_id => $target_id,
    account_id    => $account_id,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  is($c->{result}, 'NG', 'result');
  is($c->{msg}, 'failed because the select_year is empty',
    'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '7';
$name = "lack of parameter - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  # リクエストパラメータの設定
  my $param = {
    client_code   => $cli_code,
    imo_num       => $imo_no,
    select_year   => $year,
    # get_target_id => $target_id,
    account_id    => $account_id,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  is($c->{result}, 'NG', 'result');
  is($c->{msg}, 'failed because the get_target_id is empty',
    'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '8';
$name = "lack of parameter - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  # リクエストパラメータの設定
  my $param = {
    client_code   => $cli_code,
    imo_num       => $imo_no,
    select_year   => $year,
    get_target_id => $target_id,
    # account_id    => $account_id,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  is($c->{result}, 'NG', 'result');
  is($c->{msg}, 'failed because the account_id is empty',
    'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

# 以下、ヘルパーメソッド
sub request {
  my $param = shift;
  # リクエストオブジェクトの作成
  my $ua = LWP::UserAgent->new();

  # privateディレクトリに格納されているCGIのため、セッション情報をCookieヘッダに付与
  #  $cookie_jar->set_cookie(cookie_version, cookie_key, cookie_value, url_path, domain, port );
  #                          [str]           [str]       [str]         [str]     [str]   [str]
  my $cookie_jar = HTTP::Cookies->new;
  $cookie_jar->set_cookie(undef, 'akey', '615e43dd24262163bf38d6c61f71a82f', "/", 'pt-esm-gen01-vmg.wni.co.jp', '80');
  $ua->cookie_jar($cookie_jar);

  # リクエストの実施
  my $res = $ua->post('http://pt-esm-gen01-vmg.wni.co.jp/b/ESM/cgi-bin/pri/emission_per_voyage_get_display_data.cgi', $param);

  return $res;
}

done_testing;
