# $Id: emission_per_voyage_get_edit_history.t 36492 2019-04-02 03:23:51Z p0660 $

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
use File::Path qw(mkpath rmtree);
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
my $top_dir    = dirname(__FILE__) . "/..";
my $prog_name  = basename(__FILE__);
my $proc_time  = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd        = substr($local_time, 0, 8);
my $log_fname  = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $prog_base  = $prog_name;
$prog_base     =~ s/^(.*)\..*$/$1/;

my $log       = logging->Open( $log_fname ) ;
my $start_msg = "=== Subtest %s Start ===\n";
my $end_msg   = "=== Subtest %s End ===\n";
my $name;
my $num;

# test
# 下準備
my ( $cli_code, $imo_no,    $voyage_key,       $target_key)
  = ('CBA'    , '6754321', 'hoge_voyage_key',  'foc_dogo');
my $dest_file_dir = sprintf( "%s/data/esm3_voyage/%s/%s/edit", $top_dir, $cli_code, $imo_no);
rmtree $dest_file_dir;

$num = '1';
$name = "all the parameters empty - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

my ( $cli_code, $imo_no,  $voyage_key, $target_key)
  = (''    , '', '', '');

  # リクエストパラメータの設定
  my $param = {
    imo_no      => $imo_no,
    client_code => $cli_code,
    voyage_key  => $voyage_key,
    target_key  => $target_key,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  my $detail = $c->{detail};
  is($res->is_success, 1, 'success status');
  is($c->{result}, 'NG', 'result');
  is($detail->{message},
    'error: [failed because client_code imo_no target_key voyage_key is empty]', 'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '2';
$name = "all the valid parameters but no voyage data exists - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

# 下準備
my ( $cli_code, $imo_no,    $voyage_key,       $target_key)
  = ('CBA'    , '7754321', 'hoge_voyage_key',  'foc_dogo');

  # リクエストパラメータの設定
  my $param = {
    imo_no      => $imo_no,
    client_code => $cli_code,
    voyage_key  => $voyage_key,
    target_key  => $target_key,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  my $detail = $c->{detail};
  is($res->is_success, 1, 'success status');
  is($c->{result}, 'OK', 'result');
  is($detail->{message},
    "unknown edit file", 'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '3';
$name = "all the valid parameters and voyage data exists - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

# 下準備
my ( $cli_code, $imo_no,    $voyage_key,       $target_key)
  = ('CBA'    , '6754321', 'hoge_voyage_key',  'foc_dogo');
my $tst_file_dir  = sprintf( "%s/t/data/%s", $top_dir, $prog_base);
my $dest_file_dir = sprintf( "%s/data/esm3_voyage/%s/%s/edit", $top_dir, $cli_code, $imo_no);
mkpath $dest_file_dir if !-d $dest_file_dir;
copy "$tst_file_dir/".$voyage_key."_edit.json", "$dest_file_dir/".$voyage_key."_edit.json";

  # リクエストパラメータの設定
  my $param = {
    imo_no      => $imo_no,
    client_code => $cli_code,
    voyage_key  => $voyage_key,
    target_key  => $target_key,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  my $detail = $c->{detail};
  is($res->is_success, 1, 'success status');
  is($c->{result}, 'OK', 'result');
  is($detail->{message},
    "get history: voyage->foc_dogo", 'detail message');
  is($detail->{exec_user}, 'amms-report@sea.wni.com', 'exec user');
  is($detail->{exec_time}, '2018-03-26T03:06:36', 'exec time');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '4';
$name = "all the valid parameters and voyage data exists but no data of target key - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

# 下準備
my ( $cli_code, $imo_no,    $voyage_key,       $target_key)
  = ('CBA'    , '6754321', 'hoge_voyage_key',  'foc_lfo');
my $tst_file_dir  = sprintf( "%s/t/data/%s", $top_dir, $prog_base);
my $dest_file_dir = sprintf( "%s/data/esm3_voyage/%s/%s/edit", $top_dir, $cli_code, $imo_no);
mkpath $dest_file_dir if !-d $dest_file_dir;
copy "$tst_file_dir/".$voyage_key."_edit.json", "$dest_file_dir/".$voyage_key."_edit.json";

  # リクエストパラメータの設定
  my $param = {
    imo_no      => $imo_no,
    client_code => $cli_code,
    voyage_key  => $voyage_key,
    target_key  => $target_key,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  my $detail = $c->{detail};
  is($res->is_success, 1, 'success status');
  is($c->{result}, 'OK', 'result');
  is($detail->{message},
    "unknown data: voyage->foc_lfo", 'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '5';
$name = "imo number parameter empty - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

# 下準備
my ( $cli_code, $imo_no,    $voyage_key,       $target_key)
  = ('CBA'    , '', 'hoge_voyage_key',  'foc_lfo');

  # リクエストパラメータの設定
  my $param = {
    imo_no      => $imo_no,
    client_code => $cli_code,
    voyage_key  => $voyage_key,
    target_key  => $target_key,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  my $detail = $c->{detail};
  is($res->is_success, 1, 'success status');
  is($c->{result}, 'NG', 'result');
  is($detail->{message},
    'error: [failed because imo_no is empty]', 'detail message');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '6';
$name = "not readable edit file - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

# 下準備
my ( $cli_code, $imo_no,    $voyage_key,       $target_key)
  = ('CBA'    , '6754321', 'hoge_voyage_key',  'foc_lfo');
my $tst_file_dir  = sprintf( "%s/t/data/%s", $top_dir, $prog_base);
my $dest_file_dir = sprintf( "%s/data/esm3_voyage/%s/%s/edit", $top_dir, $cli_code, $imo_no);
mkpath $dest_file_dir if !-d $dest_file_dir;
copy "$tst_file_dir/".$voyage_key."_edit.json", "$dest_file_dir/".$voyage_key."_edit.json";
chmod 0333, "$dest_file_dir/".$voyage_key."_edit.json";

  # リクエストパラメータの設定
  my $param = {
    imo_no      => $imo_no,
    client_code => $cli_code,
    voyage_key  => $voyage_key,
    target_key  => $target_key,
  };
  my $res = request($param);

  # 結果のチェック
  my $c = decode_json($res->content);
  my $detail = $c->{detail};
  is($res->is_success, 1, 'success status');
  is($c->{result}, 'NG', 'result');
  like($detail->{message},
    qr/Exception error/, 'detail message');

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
  my $res = $ua->post("http://pt-esm-gen01-vmg.wni.co.jp/b/ESM/cgi-bin/pri/$prog_base.cgi", $param);

  return $res;
}

done_testing;
