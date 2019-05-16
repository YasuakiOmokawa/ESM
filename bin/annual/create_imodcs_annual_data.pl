#! /usr/local/bin/perl

use strict;
use warnings;
use File::Basename;
use POSIX qw(strftime);
use constant { TRUE => 1, FALSE => 0 };
use Data::Dumper;
use File::Path qw/mkpath rmtree/;

my $MY_DIR  = "";
my $TOP_DIR = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
  $TOP_DIR = "$MY_DIR/../..";
};

use lib "$TOP_DIR/lib";
use lib '/usr/amoeba/lib/perl';
use EsmConf;
use EsmConfigWeb;
use logging;

use JsonHandler;
use EsmDataDetector;
use VoyageImoDcsCreateAnnual;

# result flag
my $res = FALSE;

# Static settings
my $top_dir    = dirname(__FILE__) . "/../..";
my $prog_name  = basename(__FILE__);
my $proc_time  = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd        = substr($local_time, 0, 8);
my $log_fname  = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $spool_dir  = sprintf("%s/spool/annual_spool", $top_dir);

# Initialized Logging Object
my $log  = logging->Open( $log_fname ) ;

# トリガーファイルの中身のデータを用いてVoyage情報ファイルを取得し、年間値計算対象のデータを抽出する
# 抽出したデータを集計プログラムに渡して集計を実施する
# 集計結果はファイルに保存する
sub main {

  my $log_mode = shift;
  $log_mode //= '6';

  $log->Info("Create annual data starts...\n");

  my $ec = ExclusiveControl->new($spool_dir, $prog_name, $log_mode, $log);
  if ($ec->do()) {

    my $total_count = 0;
    my @triggers = glob(sprintf("%s/*/*/imodcs_*.json", $spool_dir));
    if (@triggers) {

      $log->Info("  trigger found : %s files \n", scalar(@triggers));

      for my $trig (@triggers) {

        # トリガーファイルを取得
        my $th = JsonHandler->new($log, $trig);
        my $imo_no      = $th->get_item(["imo_no"]);
        my $client_code = $th->get_item(["client_code"]);
        my $year        = $th->get_item(["year"]);
        $log->Info("    imo_no      : %s\n", $imo_no);
        $log->Info("    client_code : %s\n", $client_code);
        $log->Info("    year        : %s\n", $year);

        # Voyage情報ファイルを検索して、年間値計算対象のデータを抽出
        $log->Info("    voyage data collect start\n");
        my $ed = EsmDataDetector->new($log, $client_code, $imo_no);
        my $voy_infos = collect_voyage_data($log, $ed, $year);
        if (@{$voy_infos}) {

          my $tmp_count = @{$voy_infos};
          $log->Info("            add voyage total number : %s\n", $tmp_count);
          $total_count += $tmp_count;

          # 年間値計算
          $log->Info("            create annual start\n");
          my $annual     = VoyageImoDcsCreateAnnual->new($log, $voy_infos, $year, $client_code, $imo_no);
          my $annual_res = $annual->totalize;
          my $save_path  = $ed->annual_path($year);
          my $save_file  = "$save_path/imo_dcs_annual.json";
          if ($annual_res) {

            $log->Info("              create annual success : save file\n");
            mkpath $save_path unless -d $save_path;
            my $ejh = JsonHandler->new($log, $annual_res);
            $ejh->set_save_path($save_file);
            $ejh->save;
            $log->Info("                save file success\n");
            $res = TRUE;
          } elsif (!$annual_res && -f $save_file) { # 計算結果が無ければ既存ファイルは期限切れデータなので削除

            $log->Info("              annual obsoleted : delete file\n");
            unlink $save_file;
            $log->Info("                delete file success\n");
            $res = TRUE;
          } else {
            $log->Info("              create annual failed : empty result\n");
          }
          unlink $trig if $res ;

        } else {
          $log->Info("    failed collect voyage data\n");
        }
      }
      $log->Info("  total processed voyage file number : %s\n", $total_count);

    } else {
      $log->Info("  trigger data not found, exit\n");
    }
  }
}

# Voyage情報を抽出するにはいくつかのステップが必要なので、
# 別メソッドにしてmain処理の可読性を上げた。
# なお、Voyage情報の抽出は更に2ステップ処理があるので別メソッドに分けた
sub collect_voyage_data {
  my ($log, $detector, $year) = @_;

  my $datas = [];

  # Voyage情報ファイルのインデックス情報を取得
  my @idxs = glob($detector->voyage_index_dir."/*.json");
  if (@idxs) {

    $log->Info("    index file found : %s files \n", scalar(@idxs));

    # 対象のインデックスのみ抽出
    my @idxs_for_annual;
    @idxs_for_annual = grep {
      my @idx = split /_/, basename($_);
      my ($from, $to) = ($idx[0], $idx[1]);
     ($year == substr($from, 0, 4) || $year == substr($to, 0, 4))
    } @idxs;
    if (@idxs_for_annual) {

      $log->Info("      for annual index extracted : %s files \n", scalar(@idxs_for_annual));
      $log->Info("        collect data start\n");
      # Voyage情報の抽出
      $datas = _collect_data($log, \@idxs_for_annual);
    } else {
      $log->Info("      for annual index not found\n");
    }
  } else {
    $log->Info("  voyage index not found\n");
  }

  return $datas;
}

sub _collect_data {
  my ($log, $files) = @_;

  my $datas = [];
  for my $idx (@{$files}) {

    my $jh = JsonHandler->new($log, $idx);
    my $voy_path = $jh->get_item(["voyage_file_path"]);
    if (-f $voy_path) {

      $log->Info("          add voyage : %s\n", basename($voy_path));
      my $vh = JsonHandler->new($log, $voy_path);
      push @{$datas}, $vh->get_data;
    } else {
      $log->Info("          voyage not found : %s\n", basename($voy_path));
    }
  }

  return $datas;
}

# Start process
eval{
  &main();
};
if($@){
  $log->Info("Error : ".$@."\n");
}

END{
  $log->Close() if( defined( $log ) );
}
