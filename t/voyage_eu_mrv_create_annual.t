# $Id: voyage_eu_mrv_create_annual.t 35732 2019-01-18 06:02:06Z p0660 $

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

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";
use lib '/usr/amoeba/lib/perl';

use logging;
use JsonHandler;

# test module
use VoyageEuMrvCreateAnnual;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
# my $debug_path = '/usr/home/partner/p0562/test_data_v3/';
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;
my $test_data_dir = "$top_dir/t/data/$prog_base";
my $test_out_dir = "$top_dir/t/out/$prog_base";

my $log  = logging->Open( $log_fname ) ;

my $start_msg = "Subtest %s Start\n";
my $end_msg = "=== Subtest %s End ===\n";
my $name;
my $num;

# test
subtest "No.1-4 normal pattern" => sub {

  my $tst_file = '1.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->{data});

  # totalize実行
  my $res = JsonHandler->new($log, $va->totalize);
  ok($va,'totalize ok');

  # 戻り値データ出力
  $res->set_save_path("$test_out_dir/1_out.json");
  $res->save;

  done_testing;
};

subtest "No.5 no summary key" => sub {

  my $tst_file = '2.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->{data});

  # totalize実行
  my $res = $va->totalize;

  # 戻り値がundefを確認
  is($res,undef,'return is undef');

  done_testing;
};

subtest "No.6 only voyage-eu_to_eu" => sub {

  my $tst_file = '3.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->{data});

  # totalize実行
  my $res = JsonHandler->new($log, $va->totalize);
  ok($va,'totalize ok');

  # 戻り値データ出力
  $res->set_save_path("$test_out_dir/3_out.json");
  $res->save;

  # eu_to_euのdistance_travelled確認
  is($res->{data}->{data}->{eu_to_eu}->{data}->{distance_travelled},'2604','distance_travelled is ok');

  done_testing;
};

subtest "No.7 no output def key" => sub {

  my $tst_file = '4.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->{data});

  # totalize実行
  my $res = $va->totalize;

  # 戻り値がundefを確認
  is($res,undef,'return is undef');

  done_testing;
};

subtest "No.8 output def key unmatch" => sub {

  my $tst_file = '5.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->{data});

  # totalize実行
  my $res = JsonHandler->new($log, $va->totalize);
  ok($va,'totalize ok');

  # 戻り値データ出力
  $res->set_save_path("$test_out_dir/5_out.json");
  $res->save;

  done_testing;
};

subtest "No.9-10 round" => sub {

  my $tst_file = '6.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->{data});

  my ($stdout, $strerr) = capture {
    # totalize実行
    my $res = JsonHandler->new($log, $va->totalize);
    ok($va,'totalize ok');

    # 戻り値データ出力
    $res->set_save_path("$test_out_dir/6_out.json");
    $res->save;
  };
  like($strerr, qr/Input value is higher than the upper limit./, 'wrn msg is ok');

  done_testing;
};

$num = '13';
$name = "summary limit and calculation check - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $tst_file = '13.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->get_data->{voyages});

  # my ($stdout, $strerr) = capture {
  # totalize実行
  my $res = JsonHandler->new($log, $va->totalize);
  ok($va,'totalize ok');
  # };

  my $r = $res->get_data->{data};
  eq_or_diff(
  [
    $r->{summary}{data}{foc_dogo},
    $r->{summary}{data}{co2_dogo},
    $r->{summary}{data}{co2_lfo},
    $r->{summary}{data}{co2_hfo},
    $r->{summary}{data}{co2_other},
    $r->{summary}{data}{transport_work},
  ],
  [
    undef,
    undef,
    '3.11',
    '0.00',
    undef,
    '50',
  ], "foc_dogo ~ transport_work summary record check");

  eq_or_diff(
  [
    $r->{summary}{data}{foc_dogo_per_distance},
    $r->{summary}{data}{foc_lfo_per_distance},
    $r->{summary}{data}{foc_hfo_per_distance},
    $r->{summary}{data}{foc_other_per_distance},
    $r->{summary}{data}{foc_dogo_per_transport_work},
    $r->{summary}{data}{foc_lfo_per_transport_work},
    $r->{summary}{data}{foc_hfo_per_transport_work},
    $r->{summary}{data}{foc_other_per_transport_work},
    $r->{summary}{data}{co2_per_distance},
    $r->{summary}{data}{eeoi},
  ],
  [
    undef,
    '0.1000',
    '0.0000',
    '0.0500',
    undef,
    '0.02000000',
    '0.00000000',
    '0.01000000',
    '0.3114',
    '0.06228000'
  ], "per_distance ~ eeoi summary record check");


  $log->Info($end_msg, $name);
  done_testing;
};

$num = '14';
$name = "full item check of effect value  - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $tst_file = '14.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->get_data->{voyages});

  # totalize実行
  my $res = JsonHandler->new($log, $va->totalize);
  ok($va,'totalize ok');

  my $r = $res->get_data->{data};
  eq_or_diff(
  [
    $r->{in_port}{data}{co2_per_distance},
    $r->{in_port}{data}{eeoi},
    $r->{dep_from_eu_port}{data}{co2_per_distance},
    $r->{dep_from_eu_port}{data}{eeoi},
    $r->{arr_at_eu_port}{data}{co2_per_distance},
    $r->{arr_at_eu_port}{data}{eeoi},
    $r->{eu_to_eu}{data}{co2_per_distance},
    $r->{eu_to_eu}{data}{eeoi},
  ],
  [
    '23.8500',
    '11.92500000',
    '23.8500',
    '11.92500000',
    '23.8500',
    '11.92500000',
    '23.8500',
    '11.92500000',
  ], "contains full value");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '15';
$name = "full item check of effect value  - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $tst_file = '15.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->get_data->{voyages});

  # totalize実行
  my $res = JsonHandler->new($log, $va->totalize);
  ok($va,'totalize ok');

  my $r = $res->get_data->{data};
  eq_or_diff(
  [
    $r->{eu_to_eu}{data}{foc_dogo_per_distance},
    $r->{eu_to_eu}{data}{foc_dogo_per_transport_work},
    $r->{eu_to_eu}{data}{co2_per_distance},
    $r->{eu_to_eu}{data}{eeoi},
  ],
  [
    undef,
    undef,
    undef,
    undef,
  ], "safes division zero value");

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '16';
$name = "all rows enable limit check  - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  my $tst_file = '16.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);

  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->get_data->{voyages});

  # totalize実行
  my $res;
  my ($stdout, $strerr) = capture {
    # totalize実行
   $res = JsonHandler->new($log, $va->totalize);
   ok($va,'totalize ok');
  };

  my $r = $res->get_data->{data};
  eq_or_diff(
  [
    $r->{in_port}{data}{transport_work},
    $r->{dep_from_eu_port}{data}{transport_work},
    $r->{arr_at_eu_port}{data}{transport_work},
    $r->{eu_to_eu}{data}{transport_work},
  ],
  [
    undef,
    undef,
    undef,
    undef,
  ], "upper limit");

  $log->Info($end_msg, $name);
  done_testing;
};

done_testing;
