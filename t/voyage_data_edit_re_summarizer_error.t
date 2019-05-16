# $Id: voyage_data_edit_re_summarizer_error.t 36271 2019-03-18 01:16:27Z p0660 $

use strict;
use warnings;

use Capture::Tiny qw/ capture /;
use Test::More;
use Test::Exception;
use JSON;
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
use EsmDataDetector;
use JsonHandler;
use DailyReportHandler;
use EsmLib;


# test module
use VoyageDataEditReSummarizer;

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

my $log  = logging->Open( $log_fname );

# test
subtest "edit_and_save error test 4" => sub {

  $log->Info("edit_and_save error test 4 start log\n");

  # m列のNo.22実施
  # /usr/amoeba/pub/b/ESM/conf/esm3_voyage/template_edit_voyage.json ←下記試験実施時はファイル名を変更しておく
  # editファイルは事前に削除しておく
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '20180705131410-9372a42e406f522499df9d0b63404592_20180705184806-d3d6adbaa82cde7067ce16cd00d213ec';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'distance_travelled';
  my $edit_value = '50';
  my $pre_edit_value = '100';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２(qr)：返却予想結果 ３：terminal出力
  throws_ok { $vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value) } qr/voyage edit template not exist/, 'edit_and_save error test 4 result ok';

  $log->Info("edit_and_save error test 4 end log\n");

  done_testing;
};

done_testing;