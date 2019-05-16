#! /usr/local/bin/perl

use strict;
use warnings;

use File::Basename qw(dirname basename);
use File::Path;
use IO::Socket;
use POSIX qw(strftime);
use Data::Dumper;

my $MY_DIR = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};

use lib "$MY_DIR/../../lib";
use lib '/usr/amoeba/lib/perl';
use EsmConf;
use EsmLib;
use CreateEvidenceFileList;
use logging;

# for esm v3.0
use JsonHandler;
use MonthlyReportHandler;
use QrtVer2018Adjust;
use QrtVer2019Adjust;
use EsmDataDetector;

my $UNIX = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $EsmConf::FIFO);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);

my $top_dir = dirname(__FILE__) . "/../..";
my $log  = logging->Open("$top_dir/log/".basename(__FILE__).".$ymd.log");

####################
####################

sub main {
  my $repJson = $ARGV[0] || "/usr/amoeba/capture/daily_test";
  die "unable to cache report_data.json" unless ($repJson);

  my $repObj = undef;
  EsmLib::LoadJson($repJson, \$repObj);

  my $repData    = @{$repObj->{data}}[ $#{$repObj->{data}} ];
  my $clientCode = $repData->{raw}{clientcode};

  # ----- skip delete flg == true ----- #
  if (exists $repObj->{report_info}{delete} and $repObj->{report_info}{delete} eq "true") {
    $log->Info("This report has delete flag. (process ends)\n");
    return;
  }

  # ----- skip if not esm customer ----- #
  unless(EsmLib::IsServiceClient($clientCode)) {
    $log->Info("not ESM customer.\n");
    return;
  }
  $log->Info("clientCode  : $clientCode\n");
  $log->Info("imo_num_repo: $repData->{calc}{imo_num_repo}\n");
  $log->Info("messageid   : $repData->{raw}{messageid}\n");

  # ----- load daily data setting ----- #
  my $defObj = _getDefDailyData($clientCode);

  unless ($repData->{calc}{report_type}) {
    die "not defined report_type"; # skip:: report_type is undef
  }
  # ----- skip if not target report_type ----- #
  unless(EsmLib::InAry($repData->{calc}{report_type}, $defObj->{save_rep_type})) {
    $log->Info("$repData->{calc}{report_type} is not target.\n");
    return;
  }

  ## for esm v 3.0 start

  # ----- skip if not target report ----- #
  if ($repData->{report_info}{report_type_repo} eq $EsmConf::BUNKERING_REPORT_REPO
    && $repData->{report_info}{report_type_id} eq $EsmConf::BUNKERING_START_REPORT_TYPE_ID) {

    $log->Info("It is not target : Bunkering start report.\n");
    return;
  }

  #### QRT convert
  my $adj;
  if ($repData->{raw}{esm_version} && $repData->{raw}{esm_version} eq '3.00') {

    # for QRT 2019 convert
    $log->Info("QRT(of this report) is version 2019, convert start\n");
    $adj = QrtVer2019Adjust->new($log, $repData);
  }
  elsif (!$repData->{raw}{esm_version}) {

    # for QRT 2018 convert
    $log->Info("QRT(of this report) is version 2018, convert start\n");
    $adj = QrtVer2018Adjust->new($log, $repData);
  }
  $adj->interchange;
  ## for esm v 3.0 end
  
  # BUG-089 start
  if ($adj->{data}->is_not_save) {

    $log->Info("It is paticular pattern data: outliers, not save\n");
    return;
  }
  # BUG-089 end

  # ----- merge save items into $saveRepObj  ----- #
  my $saveRepObj = undef;
  $saveRepObj->{calc} = $repData->{calc}; # calc is default

  $saveRepObj->{report_info}{messageid}        = $repData->{raw}{messageid};
  $saveRepObj->{report_info}{report_type}      = $repData->{report_info}{report_type};
  $saveRepObj->{report_info}{report_type_id}   = $repData->{report_info}{report_type_id};
  $saveRepObj->{report_info}{report_type_repo} = $repData->{report_info}{report_type_repo};

  # for esm v 3.0
  $saveRepObj->{report_info}{updated_at}       = $repData->{raw}{updated_at};
  $saveRepObj->{report_info}{status}           = $repData->{report_info}{status};
  $saveRepObj->{report_info}{for_judge_voyage} = $repData->{report_info}{for_judge_voyage};
  $repData->{report_info}{updated_at}          = $repData->{raw}{updated_at};
  $saveRepObj->{calc}{esm_version}             = $repData->{raw}{esm_version};

  foreach my $key ("exec_time", "delete_at", "enabled_at", "service_code", "invalid") {
    next unless (exists $repObj->{report_info}{$key});
    $saveRepObj->{report_info}{$key} = $repObj->{report_info}{$key};
  }

  die "not defined use_data_layer" unless ($defObj->{use_data_layer});
  foreach my $layer (@{$defObj->{use_data_layer}}) {
    map { $saveRepObj->{$layer} = $repData->{$layer} } keys %$repData;
  }

  #### Return if this data is re-send data
  # get monthly data
  my $message_id = $repData->{raw}{messageid};
  my $rep_id = $repData->{report_info}{report_type_id};
  my $rep_str = EsmLib::EpochToStr( EsmLib::StrToEpoch($repData->{calc}{report_time}), "%Y%m%d%H%M%S" );
  my $year = substr($rep_str, 0, 4);
  my $month = substr($rep_str, 4, 2);
  my $month_file = sprintf("%s/data/esm3_daily/%s/%s/%s/%s.json", $top_dir, $clientCode, $repData->{calc}{imo_num_repo}, $year, $month);

  if (-f $month_file) {

    my $jh = JsonHandler->new($log, $month_file);
    my $mh = MonthlyReportHandler->new($log, $jh);
    my $m_data = $mh->search_data($message_id, $rep_id);

    # is re-send data?
    if ($m_data) {

      $log->Info("this report updated at         : %s\n", $repData->{raw}{updated_at}) if $repData->{raw}{updated_at};
      $log->Info("already send report updated at : %s\n", $m_data->{report_info}{updated_at}) if $m_data->{report_info}{updated_at};

      if ( $repData->{raw}{updated_at} && $m_data->{report_info}{updated_at} && ($repData->{raw}{updated_at} eq $m_data->{report_info}{updated_at})
        && undef $repObj->{"report_info"}->{"delete_at"} && !@{$repData->{custom}} ) {

        $log->Info("this is re-send report, return\n");
        return;
      }
    }
  } else {
    $log->Info("already send report not found : %s\n", $month_file);
  }
  ## for esm v 3.0 end


  # ----- サービスメニュー毎の処理 ----- #
  if ($defObj->{service_code} eq "ESM") {
    # 6.1
    my $attachmentsJson = "$EsmConf::CONF_DIR/attachment_target_report.json";
    my $attachmentsObj = undef;
    EsmLib::LoadJson($attachmentsJson, \$attachmentsObj);

    if ($attachmentsObj) {
      # 6.3
      foreach my $repoTypeRepo (@$attachmentsObj) {
        if ($repData->{report_info}{report_type_repo} eq $repoTypeRepo) {
          my $evidence_lock_file = sprintf("%s/evidence/evidence.lock", $top_dir."/data");
          open(LOCK, "> $evidence_lock_file") or die("Can't open lock file.[$!]\n");
          $log->Info( "Trying Evidence flock [messageid:%s]\n" , $repData->{raw}{messageid} );
          flock(LOCK, 2);
          $log->Info( "Succeeded flock [messageid:%s]\n" , $repData->{raw}{messageid} );
          CreateEvidenceFileList::create_evidence_file_list($repObj, $log);
          close(LOCK);
        }
      }
    } else {
      $log->Info("not defined attachment_target_report.json.\n");
    }
  }

  # ----- 既存のデータにマージ ----- #
  #  既存ファイルがある場合、重複チェック
  #  既存ファイルがない場合、新規でファイル作成

  my $saveObj = undef;
  my $saveFilePath = _getSaveFilePath($defObj, $clientCode, $repObj->{ship_info}, $saveRepObj->{calc}{report_time});
  if (-f $saveFilePath) {
    EsmLib::LoadJson($saveFilePath, \$saveObj);

    # --- 重複データ処理 --- #
    my $sameIdx = "";
    if (_isExistSameData($saveObj->{report}, $saveRepObj, \$sameIdx)) {
      splice(@{$saveObj->{report}}, $sameIdx, 1); # 古いデータは削除
      $log->Info("delete already duplicate report\n");
    }
    push(@{$saveObj->{report}}, $saveRepObj);
    @{$saveObj->{report}} = sort { $a->{calc}{report_time} cmp $b->{calc}{report_time} } @{$saveObj->{report}};
  } else {
    $saveObj = {
      ship_info => $repObj->{ship_info},
      report => [ $saveRepObj ]
    };
    $log->Info("create new report\n");
  }
  # --- BROB処理 --- #
  if (exists $repObj->{voyage_info}{invalid} && $repObj->{voyage_info}{invalid} ne "true") {
    if (exists $defObj->{calc_diff_frm_last_rep}) {
      _calcDiffFromLastReport($repData->{raw}{messageid}, $saveObj->{report}, $saveFilePath, $defObj->{calc_diff_frm_last_rep});
    }
  }

  # --- period オブジェクトの作成 --- #
  $saveObj->{period} = _getPeriod($saveObj->{report});

  # ----- 保存 + disseminate ----- #
  EsmLib::SaveJson($saveFilePath, $saveObj, 1);
  # $UNIX->write("$saveFilePath\n"); # no dessiminate ( ESM need not )
  $log->Info("save report : %s\n", $saveFilePath);

##### NK連携 #####
  # 11. レポート受信履歴ファイルの作成
  _createHistoryFile($repData, $defObj, $saveFilePath);
##### NK連携 #####

  ## for esm v 3.0 start
  #### call judge voyage
  my $repSave = sprintf("/tmp/$$.json");
  EsmLib::SaveJson($repSave, $repObj, 1);
  my @cmd = (
    EsmDataDetector::judge_voyage_program,
    $repSave
  );

  system @cmd;
  ## for esm v 3.0 end

}

sub _updateShipModelParam {
  my ($clientCode, $wnishipnum, $repData) = @_;
  my $cmdParam = sprintf("-wnishipnum %s -draft_fore %s -draft_aft %s -loading_condition %s -client_code %s",
    $wnishipnum,
    $repData->{calc}{draft_fore},
    $repData->{calc}{draft_aft},
    $repData->{calc}{loading_condition},
    $clientCode
  );
  my $exeCmd = `$EsmConf::BASE_TOP/bin/param/update_parameter.pl $cmdParam`;
}

sub _createChargingAry {
  my ($clientCode, $wnishipnum) = @_;

  my @isCharging = ();
  my $tgtDir = "$EsmConf::TBL_DIR/vesselList/$clientCode";
  my $resultExe = `grep -rl $wnishipnum $tgtDir/*/vessel_list.json`;
  foreach my $vslListPath (split(/\n/, $resultExe)) {
    if ($vslListPath =~ /$tgtDir\/(.*)\/vessel_list.json/) {
      push(@isCharging, $1);  # $1: sectionCode
    }
  }
  return \@isCharging;
}

sub _isInvalidReport {
  my $data = shift;
  if(defined($data->{"report_info"}->{"invalid"}) && ($data->{"report_info"}->{"invalid"} eq "true" || $data->{"report_info"}->{"invalid"} == 1)){
    return 1;
  }
  if(defined($data->{"invalid"}) && ($data->{"invalid"} eq "true" || $data->{"invalid"} == 1)){
    return 1;
  }
  return 0;
}

sub _calcDiffFromLastReport {
  my ($thisMsgId, $reportAry, $saveFilePath, $defCalcObj) = @_;

  my $defCalcDiff = $defCalcObj->{diff_frm_last_rep};
  my $defCalcSum  = $defCalcObj->{sum_val};
  my $defCalcCo2  = $defCalcObj->{calc_co2};

  my $repAryLen = $#$reportAry;
  for (my $i=0; $i<=$repAryLen; $i++) {
    next unless ($thisMsgId eq @$reportAry[$i]->{calc}{messageid});
    my $thisRepNode = @$reportAry[$i];
    my $isInvalid = _isInvalidReport($thisRepNode);
    if($isInvalid){
      # invalidとなったレポートの場合は、1つ先とのbrob計算

      # prev取得
      my $prevRepNode = undef;
      my $nextRepNode = undef;
      my $nextDailyObj = undef;
      my $nextFilePath = "";
      if ($i == 0) {
        my $prevDailyObj = undef;
        my $prevFilePath = _getPrevFilePath($saveFilePath);
        if (-e $prevFilePath){
          EsmLib::LoadJson($prevFilePath, \$prevDailyObj);
          $prevRepNode = @{$prevDailyObj->{report}}[$#{$prevDailyObj->{report}}];
        }
      } else {
        $prevRepNode = @$reportAry[$i-1];
      }
      # next取得
      if ($i == $repAryLen) {
        $nextFilePath = _getNextFilePath($saveFilePath);
        if (-e $nextFilePath) {
          EsmLib::LoadJson($nextFilePath, \$nextDailyObj);
          $nextRepNode = @{$nextDailyObj->{report}}[0];
        } else {
          $nextFilePath = "";
        }
      } else {
        $nextRepNode = @$reportAry[$i+1] if(@$reportAry[$i+1]);
      }
      _createEmptyValObj($nextRepNode, $defCalcDiff);
      _createEmptyValObj($nextRepNode, $defCalcSum) if ($defCalcSum);
      _createEmptyValObj($nextRepNode, $defCalcCo2) if ($defCalcCo2);
      unless ($nextRepNode->{calc}{report_type} eq "DEP") {
        _calcMinus($nextRepNode, $prevRepNode, $defCalcDiff);
        _calcPlus( $nextRepNode, $defCalcSum) if (defined $defCalcSum);
        _calcCo2(  $nextRepNode, $defCalcCo2) if (defined $defCalcCo2);
        _createPrevLayer( $nextRepNode, $prevRepNode, $defCalcDiff ) if ($defCalcObj->{save_prev_val});
      }
      if($nextFilePath ne ""){
        $log->Info("nextfile:: $nextFilePath\n");
        EsmLib::SaveJson($nextFilePath, $nextDailyObj, 1);
        # $UNIX->write("$nextFilePath\n");
      }
    } else {
      # ----- オブジェクトの初期化 ----- #
      _createEmptyValObj($thisRepNode, $defCalcDiff);
      _createEmptyValObj($thisRepNode, $defCalcSum) if ($defCalcSum);
      _createEmptyValObj($thisRepNode, $defCalcCo2) if ($defCalcCo2);

            # ----- 一つ前のレポートとの差分を求める(今回追加するレポートがDEPじゃないこと前提)  ----- #
      unless ($thisRepNode->{calc}{report_type} eq "DEP") {
        if ($i == 0) {
          # --- 一つ前のレポートが月をまたぐ場合 --- #
          my $prevFilePath = _getPrevFilePath($saveFilePath);
          if (-e $prevFilePath) {
            my $prevDailyObj = undef;
            EsmLib::LoadJson($prevFilePath, \$prevDailyObj);
            my $prevRepNode = @{$prevDailyObj->{report}}[$#{$prevDailyObj->{report}}];
            _calcMinus($thisRepNode, $prevRepNode, $defCalcDiff);
            _calcPlus( $thisRepNode, $defCalcSum) if (defined $defCalcSum);
            _calcCo2(  $thisRepNode, $defCalcCo2) if (defined $defCalcCo2);
            _createPrevLayer( $thisRepNode, $prevRepNode, $defCalcDiff ) if ($defCalcObj->{save_prev_val});
          }
        } else {
          # --- 一つ前のレポートが月をまたがない場合 (同一ファイル内にある) --- #
          if (@$reportAry[$i-1]) {
            # --- 一つ前のレポートがある && $thisRepType が DEPじゃない --- #
            my $prevRepNode = @$reportAry[$i-1];
            _calcMinus($thisRepNode, $prevRepNode, $defCalcDiff);
            _calcPlus($thisRepNode, $defCalcSum) if (defined $defCalcSum);
            _calcCo2( $thisRepNode, $defCalcCo2) if (defined $defCalcCo2);
            _createPrevLayer( $thisRepNode, $prevRepNode, $defCalcDiff ) if ($defCalcObj->{save_prev_val});
          }
        }
      }

      # ----- 次のレポートとの差分を求める ----- #
      if ($i == $repAryLen) {
        # --- 次のレポートが月をまたぐ場合 --- #
        my $nextFilePath = _getNextFilePath($saveFilePath);
        if (-e $nextFilePath) {
          my $nextDailyObj = undef;
          EsmLib::LoadJson($nextFilePath, \$nextDailyObj);
          if (@{$nextDailyObj->{report}}[0]->{calc}{report_type} eq "DEP") {
            # ----- 次のレポートがDEPの場合、差分は求めない ----- #
            _createEmptyValObj(@{$nextDailyObj->{report}}[0], $defCalcDiff);
            _createEmptyValObj(@{$nextDailyObj->{report}}[0], $defCalcSum) if (defined $defCalcSum);
            _createEmptyValObj(@{$nextDailyObj->{report}}[0], $defCalcCo2) if (defined $defCalcCo2);
          } else {
            _calcMinus(@{$nextDailyObj->{report}}[0], $thisRepNode, $defCalcDiff);
            _calcPlus( @{$nextDailyObj->{report}}[0], $defCalcSum) if (defined $defCalcSum);
            _calcCo2(  @{$nextDailyObj->{report}}[0], $defCalcCo2) if (defined $defCalcCo2);
          }
          _createPrevLayer( @{$nextDailyObj->{report}}[0], $thisRepNode, $defCalcDiff ) if ($defCalcObj->{save_prev_val});
          $log->Info("nextfile:: $nextFilePath\n");
          EsmLib::SaveJson($nextFilePath, $nextDailyObj, 1);
          # $UNIX->write("$nextFilePath\n");
        }
      } else {
        # --- 次のレポートが月をまたがない場合(同一ファイル内にある) --- #
        if (@$reportAry[$i+1]) {
          if (@$reportAry[$i+1]->{calc}{report_type} eq "DEP") {
            _createEmptyValObj(@$reportAry[$i+1], $defCalcDiff);
            _createEmptyValObj(@$reportAry[$i+1], $defCalcSum) if (defined $defCalcSum);
            _createEmptyValObj(@$reportAry[$i+1], $defCalcCo2) if (defined $defCalcCo2);
          } else {
            _calcMinus(@$reportAry[$i+1], $thisRepNode, $defCalcDiff);
            _calcPlus( @$reportAry[$i+1], $defCalcSum) if (defined $defCalcSum);
            _calcCo2(  @$reportAry[$i+1], $defCalcCo2) if (defined $defCalcCo2);
            _createPrevLayer( @$reportAry[$i+1], $thisRepNode, $defCalcDiff ) if ($defCalcObj->{save_prev_val});
          }
        }
      }
    }
  }
}

sub _createEmptyValObj {
  my ($repNode, $defObj) = @_;
  foreach my $saveItem (keys %$defObj) {
    my ($itemLayer, $itemKey)       = split(/\./, $saveItem);
    my ($useItemLayer, $useItemKey) = split(/\./, $defObj->{$saveItem});
    $repNode->{$itemLayer}{$itemKey} = "";
  }
}

sub _calcMinus {
  my ($subtrahendObj, $minuendObj, $defCalcDiff) = @_;
  foreach my $saveItem (keys %$defCalcDiff) {
    my ($itemLayer, $itemKey)       = split(/\./, $saveItem);
    my ($useItemLayer, $useItemKey) = split(/\./, $defCalcDiff->{$saveItem});
    if (exists $minuendObj->{$useItemLayer}{$useItemKey} and exists $subtrahendObj->{$useItemLayer}{$useItemKey} and
        $minuendObj->{$useItemLayer}{$useItemKey} ne "" and $subtrahendObj->{$useItemLayer}{$useItemKey} ne "") {
      $subtrahendObj->{$itemLayer}{$itemKey} = $minuendObj->{$useItemLayer}{$useItemKey} - $subtrahendObj->{$useItemLayer}{$useItemKey};
    } else {
      $subtrahendObj->{$itemLayer}{$itemKey} = "";
    }
  }
}

sub _calcCo2 {
  my ($repNode, $defCo2Obj) = @_;

  foreach my $saveItem (keys %$defCo2Obj) {
    my ($itemLayer, $itemKey) = split(/\./, $saveItem);
    my ($useItemLayer, $useItemKey) = split(/\./, $defCo2Obj->{$saveItem}{use_key});
    my $fuelVal = $repNode->{$useItemLayer}{$useItemKey};
    $repNode->{$itemLayer}{$itemKey} = "";

    next if ($fuelVal eq "");
    $repNode->{$itemLayer}{$itemKey} = $fuelVal * $defCo2Obj->{$saveItem}{coef};
  }
}

sub _calcPlus {
  my ($repNode, $defCalcSum) = @_;

  # =====
  # 差分で算出した値を足し合わせる
  # ex.) total_fo = total_hsfo + total_lsfo

  foreach my $saveItem (keys %$defCalcSum) {
    my ($itemLayer, $itemKey) = split(/\./, $saveItem);
    $repNode->{$itemLayer}{$itemKey} = "";
    foreach my $useItem (@{$defCalcSum->{$saveItem}}) {
      my ($useItemLayer, $useItemKey) = split(/\./, $useItem);
      next unless (exists $repNode->{$itemLayer}{$itemKey} and $repNode->{$useItemLayer}{$useItemKey} ne "");
      $repNode->{$itemLayer}{$itemKey} += $repNode->{$useItemLayer}{$useItemKey};
    }
  }
}

sub _isExistSameData {
  # report_type_repo, report_timeが同一のレポートがあるかどうかのチェック

  my ($reportAry, $saveRepObj, $sameIdx) = @_;
  for (my $i=0; $i<=$#$reportAry; $i++) {
    my $calcNode = @$reportAry[$i]->{calc};
    my $repoInfoNode = @$reportAry[$i]->{report_info};

    if ( EsmLib::StrToEpoch($saveRepObj->{calc}{report_time}) == EsmLib::StrToEpoch($calcNode->{report_time})
           &&
         $saveRepObj->{report_info}{report_type_repo} eq $repoInfoNode->{report_type_repo} ) {
         $$sameIdx = $i;
      return 1;
    }
  }
  return 0;
}

sub _getPrevFilePath {
  my $dir = shift;

  # =====
  # 今回保存するファイルパスから、時系列的に一つ前のファイルを特定する。
  #
  my $thisMonth = basename($dir);
  $thisMonth =~ s/\.json//g;

  my $prevFilePath = undef;
  if ($thisMonth+0 == 1) {
    my ($basedir, $yy) = ($1, $2) if (dirname($dir) =~ /(.*)\/(\d{4})/);
    $prevFilePath = sprintf("%s/%s/12.json", $basedir, $yy-1);
  } else {
    $prevFilePath = sprintf("%s/%02d.json", dirname($dir), $thisMonth-1);
  }
  return $prevFilePath;
}

sub _getNextFilePath {
  my $dir = shift;

  # =====
  # 今回保存するファイルパスから、時系列的に次のファイルを特定する。
  #

  my $thisMonth = basename($dir);
  $thisMonth =~ s/\.json//g;

  my $nextFilePath = "";
  if ($thisMonth+0 == 12) {
    my ($basedir, $yy) = ($1, $2) if (dirname($dir) =~ /(.*)\/(\d{4})/);
    $nextFilePath = sprintf("%s/%s/01.json", $basedir, $yy+1);
  } else {
    $nextFilePath = sprintf("%s/%02d.json", dirname($dir), $thisMonth+1);
  }
  return $nextFilePath;
}

sub _getSaveFilePath {
  my ($defObj, $client, $shipInfo, $reportTime) = @_;

  my ($yyyy, $mm)  = split(/-/, $reportTime);
  my $saveFilePath = sprintf("%s/$defObj->{save_dir}/%s/%s.json",
    $EsmConf::BASE_TOP,
    $client,
    $shipInfo->{$defObj->{save_type}},
    $yyyy,
    $mm
  );
  return $saveFilePath;
}

sub _getDefDailyData {
  my $client = shift;

  # --- 顧客別の定義ファイルがあれば、顧客定義を参照（なければdefault） --- #
  my $defFilePath = sprintf("%s/daily/def_adjust_daily_data_%s.json", $EsmConf::CONF_DIR, $client);
  unless (-e $defFilePath) {
    $defFilePath = "$EsmConf::CONF_DIR/daily/def_adjust_daily_data.json";
  }
  my $obj = undef;
  EsmLib::LoadJson($defFilePath, \$obj);
  return $obj;
}

sub _getPeriod {
  my $reportAry = shift;
  my %period = (
    start_time => @$reportAry[0]->{calc}{report_time},
    end_time   => @$reportAry[$#$reportAry]->{calc}{report_time}
  );
  return \%period;
}

##### NK連携 #####
sub _createHistoryFile {
  my ($repData, $defObj, $saveFilePath) = @_;

  # 11.1.
  my $baseLength = length($EsmConfigWeb::DATA_DIR);
  my $historyData = {
    "messageId"      => $repData->{raw}{messageid},
    "report_type_id" => $repData->{report_info}{report_type_id},
    "path"           => substr($saveFilePath, $baseLength + 1),
    "report_time"    => $repData->{calc}{report_time}
  };

  # 11.2.
  my $historyDataFileName = sprintf("%s_%s.json", strftime("%Y%m%d%H%M%S", localtime(time)), $$);

  # 11.3.
  foreach my $dirNm (@{$defObj->{recv_history}}) {
    # 11.3.1.
    my $historyDataPath = sprintf("%s/trigger/%s/%s/%s/%s", $EsmConfigWeb::SPOOL_DIR, $dirNm, $repData->{raw}{clientcode}, $repData->{calc}{imo_num_repo}, $historyDataFileName);
    # 11.3.2.
    EsmLib::SaveJson($historyDataPath, $historyData, 1);
  }
}
##### NK連携 #####

####################
####################

eval {
  main();
};
if ($@) {
  $log->Error("$@");
}
$log->Close();
