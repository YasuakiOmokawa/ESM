# $Id: parameter_test.t 36136 2019-03-08 08:16:54Z p0660 $

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

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";
use lib '/usr/amoeba/lib/perl';

use logging;
# use JsonHandler;

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
$num = '1';
$name = "valid call  - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # my $tst_file = '14.json';
  # my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  # my $jh = JsonHandler->new($log, $tst_file_path);

  # リクエストオブジェクトの作成
  my $ua = LWP::UserAgent->new();

  # privateディレクトリに格納されているCGIのため、セッション情報をCookieヘッダに付与
  #  $cookie_jar->set_cookie(cookie_version, cookie_key, cookie_value, url_path, domain, port );
  #                          [str]           [str]       [str]         [str]     [str]   [str]
  my $cookie_jar = HTTP::Cookies->new;
  $cookie_jar->set_cookie(undef, 'cookie_name', 'cookie_value', "/", 'pt-esm-gen01-vmg.wni.co.jp', '80');
  $cookie_jar->set_cookie(undef, 'akey', '615e43dd24262163bf38d6c61f71a82f', "/", 'pt-esm-gen01-vmg.wni.co.jp', '80');
  $ua->cookie_jar($cookie_jar);

  # リクエストパラメータの設定
  my $param = {
    hoge => 'ho-ge-',
    fuga => 'fu-ga-',
  };
  # print Dumper $ua;

  # リクエストの実施
  my $res = $ua->post('http://pt-esm-gen01-vmg.wni.co.jp/b/ESM/cgi-bin/pri/parameter_test.cgi', $param);

  # 結果のチェック
  is($res->is_success, 1, 'call cgi');
  # print Dumper $res;

  $log->Info($end_msg, $name);
  done_testing;
};


done_testing;
