# $Id: exclusive_control.t 35732 2019-01-18 06:02:06Z p0660 $

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
use ExclusiveControl;

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
my $name = "lock conflict sample";
subtest $name => sub {
  
  # 「Forked inside subtest, but subtest never finished!」メッセージが
  # 出るのは気持ち悪いが、業務ロジックに問題はない。テストモジュールのコアモジュールであるTest::APIが
  # 出力しているのだが、出力を消す条件が良く分からないので診断メッセージで問題ない旨を提示
  
  $log->Info("subtest $name start\n");

  my $file = '1.json';

  diag "'Forked inside ~' is not error, Test::API informed it and have no problem of business logic";

  # プロセスを複製(子プロセスを生成) ※ Windowsではスレッドを使って擬似的にfork()を実現してるっぽいので、うまく動きませんでした。。
  defined(my $pid = fork) or die "Cannot fork: $!";

  # 子プロセスはfork()の戻り値が"0"
  if (!$pid) {
    my $ec = ExclusiveControl->new($test_data_dir, $file, 6, $log);
    $ec->do;
    sleep 2; # 親プロセスに排他制御エラーを起こさせるため、ロック取得後にスリープ
  } else {
    my $ec = ExclusiveControl->new($test_data_dir, $file, 6, $log);
    sleep 1; # 先に子プロセスのロックを取得させるため、1秒スリープ

    # 標準エラー出力($log->Error()の出力)をキャッチ
    my ($stdout, $strerr) = capture {
    
      $ec->do; # flockによる排他制御エラーが返却される
    };

    # エラーメッセージの内容チェック
    like($strerr, qr/Can\'t flock/, 'parent conflict ok');
    wait; # 子プロセスの終了を待つ
  }
  

  done_testing;
};


done_testing;
