# $Id: voyage_eu_mrv_create_annual_error.t 35732 2019-01-18 06:02:06Z p0660 $

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
my $debug_path = '/usr/home/partner/p0562/test_data_v3/';
my $prog_base = 'voyage_eu_mrv_create_annual';
$prog_base =~ s/^(.*)\..*$/$1/;
my $test_data_dir = "$top_dir/t/data/$prog_base";
my $test_out_dir = "$top_dir/t/out/$prog_base";

my $log  = logging->Open( $log_fname ) ;

# test
subtest "No.12 def file path not found" => sub {

  my $tst_file = '9.json';
  my $tst_file_path = sprintf("%s/%s", $test_data_dir, $tst_file);
  my $jh = JsonHandler->new($log, $tst_file_path);
  
  # テストデータのインスタンス化
  my $va = VoyageEuMrvCreateAnnual->new($log, $jh->{data});

  # totalize実行
  my $res = JsonHandler->new($log, $va->totalize);
  ok($va,'totalize ok');
  
  # 戻り値の確認
  is($res->{data}->{data},undef,'return is nothing');

  done_testing;
};

done_testing;
