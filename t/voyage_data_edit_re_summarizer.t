# $Id: voyage_data_edit_re_summarizer.t 36277 2019-03-18 02:40:46Z p0660 $

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
use File::Copy 'copy';
use File::Path qw(mkpath rmtree);

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
# my $test_data_dir = "$top_dir/t/data/$prog_base";

my $log  = logging->Open( $log_fname );

# test
subtest "edit_and_save normal sysytem test 1" => sub {

  $log->Info("edit_and_save normal sysytem test 1 start log\n");

  # m列のNo.1、2、4、5、7、17実施
  # この試験は実施する前にeditファイルを削除して実施すること(voy_key)
  my $imo_no      = '9308883';
  my $client_code = 'EXMR';
  my $voy_key     = '20181005004450-4cdc4c38372a4c157fec5ca9010588ad_20181006042408-1cd30dd244f5dd978a84c6956671887a';
  my $imo_type    = '';
  my $year        = '2018';
  my $editor      = 'mms-report@sea.wni.com';
  my $edit_key    = 'eu_mrv';

  # inputデータに合わせて編集値(edit_value)、編集前（pre_edit_value）を変更する。
#  my $edit_value = 'arr_at_eu_port';
#  my $pre_edit_value = 'in_eu_port';
  my $edit_value = 'in_eu_port';
  my $pre_edit_value = 'arr_at_eu_port';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value),TRUE, 'edit_and_save normal test 1 ok');

  $log->Info("edit_and_save normal sysytem test 1 end log\n");

  done_testing;
};

subtest "edit_and_save normal sysytem test 2" => sub {

  $log->Info("edit_and_save normal sysytem test 2 start log\n");

  # m列のNo.3、8、11、15、16、18実施
  my $imo_no = '7654321';
  my $client_code = 'CBA';
  my $voy_key = '20180921140527-0e564f99150e6a30cb636358ec7b7e66_20180922125058-0fd8b067a1a7624d3d9eb8a5eb125787';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'distance_travelled';

  # 前処理(voyageデータを準備)
  my $tst_file_dir  = sprintf( "%s/t/data/%s/edit_and_save", $top_dir, $prog_base);
  my $dest_file_dir = sprintf( "%s/data/esm3_voyage/%s/%s", $top_dir, $client_code, $imo_no);
  my $voy_file_dir = "$dest_file_dir/voyage";
  my $edit_file_dir = "$dest_file_dir/edit";
  # ゴミが残っているかもしれないので、voyageデータ格納ディレクトリを削除
  rmtree $dest_file_dir or die qq{Can't remove directory tree "$dest_file_dir":$!};
  # voyデータコピー、edit用ロックディレクトリの作成
  mkpath $voy_file_dir if !-d $voy_file_dir;
  mkpath $edit_file_dir if !-d $edit_file_dir;
  my $voy_file = $voy_key."_20181211104818.json";
  copy "$tst_file_dir/$voy_file", $voy_file_dir;
  is (-f "$voy_file_dir/$voy_file", TRUE, 'target voyage file exists');

  # inputデータに合わせて編集値(edit_value)、編集前（pre_edit_value）を変更する。
#  my $edit_value = '50';
#  my $pre_edit_value = '100';
  my $edit_value = '100';
  my $pre_edit_value = '50';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value),TRUE, 'edit_and_save normal test 2 result ok');

  $log->Info("edit_and_save normal sysytem test 2 end log\n");

  done_testing;
};

subtest "edit_and_save normal sysytem test 3" => sub {

  $log->Info("edit_and_save normal sysytem test 3 start log\n");

  # m列のNo.9実施
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '20180407073802-37e2d63c3115f52b34db7b0ab3b9e307_20180408122543-120e679e937a6bc28308e93ac3022dd8';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'dep_port';

  # inputデータに合わせて編集値(edit_value)、編集前（pre_edit_value）を変更する。
#  my $edit_value = 'ANC';
#  my $pre_edit_value = 'NVK';
  my $edit_value = 'NVK';
  my $pre_edit_value = 'ANC';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value),TRUE, 'edit_and_save normal test 3 result ok');

  $log->Info("edit_and_save normal sysytem test 3 end log\n");

  done_testing;
};

subtest "edit_and_save normal sysytem test 4" => sub {

  $log->Info("edit_and_save normal sysytem test 4 start log\n");

  # m列のNo.10実施
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '20180303185814-ff4ea2fd78851a685d495460185ad344_20180311174316-bb0c73ef42d1a4a5cdd0aea2e6fbd1ad';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'arr_port';

  # inputデータに合わせて編集値(edit_value)、編集前（pre_edit_value）を変更する。
#  my $edit_value = 'MLO';
#  my $pre_edit_value = 'FAR';
  my $edit_value = 'FAR';
  my $pre_edit_value = 'MLO';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value),TRUE, 'edit_and_save normal test 4 result ok');

  $log->Info("edit_and_save normal sysytem test 4 end log\n");

  done_testing;
};

subtest "edit_and_save normal sysytem test 5" => sub {

  $log->Info("edit_and_save normal sysytem test 5 start log\n");

  # m列のNo.12実施
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '20180830051414-31dd799d8a659587fdd24dcabc3f7320_20180831082537-50b019e7b9854f5b2bb00924adeb7ca6';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'time_at_sea';

  # inputデータに合わせて編集値(edit_value)、編集前（pre_edit_value）を変更する。
#  my $edit_value = '15.0';
#  my $pre_edit_value = '10.0';
  my $edit_value = '10.0';
  my $pre_edit_value = '15.0';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value),TRUE, 'edit_and_save normal test 5 result ok');

  $log->Info("edit_and_save normal sysytem test 5 end log\n");

  done_testing;
};

subtest "edit_and_save normal sysytem test 6" => sub {

  $log->Info("edit_and_save normal sysytem test 6 start log\n");

  # m列のNo.13実施
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '20180506020743-35b91d3145c8579fd9dd8a46acf5e8a7_20180523130315-be63688feac4b87a22185b6e2ed00b89';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'hours_underway';

  # inputデータに合わせて編集値(edit_value)、編集前（pre_edit_value）を変更する。
#  my $edit_value = '456.7';
#  my $pre_edit_value = '123.4';
  my $edit_value = '123.4';
  my $pre_edit_value = '456.7';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value),TRUE, 'edit_and_save normal test 6 result ok');

  $log->Info("edit_and_save normal sysytem test 6 end log\n");

  done_testing;
};

subtest "edit_and_save normal sysytem test 7" => sub {

  $log->Info("edit_and_save normal sysytem test 7 start log\n");

  # m列のNo.14実施
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '20180608015803-124245f57dc2f9c42abdb2c1a80ebc99_20180611201547-5eeb617cbe7d3241c24e46a53b02516a';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'foc_hfo';

  # inputデータに合わせて編集値(edit_value)、編集前（pre_edit_value）を変更する。
#  my $edit_value = '123.12';
#  my $pre_edit_value = '222.12';
  my $edit_value = '222.12';
  my $pre_edit_value = '123.12';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value),TRUE, 'edit_and_save normal test 7 result ok');

  $log->Info("edit_and_save normal sysytem test 7 end log\n");

  done_testing;
};

subtest "edit_and_save error test 1" => sub {

  $log->Info("edit_and_save error test 1 start log\n");

  # m列のNo.19実施
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '';
  my $imo_type = 'begin';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'distance_travelled';
  my $edit_value = '50';
  my $pre_edit_value = '100';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value), FALSE, 'edit_and_save test 1 result ok');

  $log->Info("edit_and_save error test 1 end log\n");

  done_testing;
};

subtest "edit_and_save error test 2" => sub {

  $log->Info("edit_and_save error test 2 start log\n");

  # m列のNo.20実施
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'distance_travelled';
  my $edit_value = '50';
  my $pre_edit_value = '100';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value), FALSE, 'edit_and_save error test 2 result ok');

  $log->Info("edit_and_save error test 2 end log\n");

  done_testing;
};

subtest "edit_and_save error test 3" => sub {

  $log->Info("edit_and_save error test 3 start log\n");

  # m列のNo.21実施
  my $imo_no = '9427574';
  my $client_code = 'NEOM';
  my $voy_key = '20181001123456-ba1_20181009987654-07g';
  my $imo_type = '';
  my $year = '2018';
  my $editor = 'mms-report@sea.wni.com';
  my $edit_key = 'distance_travelled';
  my $edit_value = '50';
  my $pre_edit_value = '100';

  my $vders = VoyageDataEditReSummarizer->new($log);

  #結果チェック １：対象メソッド起動 ２：返却予想結果 ３：terminal出力
  is($vders->edit_and_save($imo_no, $client_code, $voy_key, $imo_type, $year, $editor, $edit_key, $edit_value, $pre_edit_value), FALSE, 'edit_and_save error test 3 result ok');

  $log->Info("edit_and_save error test 3 end log\n");

  done_testing;
};

done_testing;
