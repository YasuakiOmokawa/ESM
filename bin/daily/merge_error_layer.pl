#! /usr/local/bin/perl

use strict;
use warnings;

use File::Basename qw(dirname basename);
use IO::Socket;
use JSON;
use Data::Dumper;
use POSIX qw(strftime);

my $MY_DIR = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};

use lib "$MY_DIR/../../lib";
use lib '/usr/amoeba/lib/perl';
use EsmConf;
use EsmLib;
use logging;

my $UNIX = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $EsmConf::FIFO);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);

my $top_dir = dirname(__FILE__) . "/../..";
my $log  = logging->Open("$top_dir/log/".basename(__FILE__).".$ymd.log");


####################
####################

sub main {
  my $errJson = $ARGV[0] || "/usr/amoeba/capture/error_test";
  die "unable to cache report_data.json" unless ($errJson);

  my $errObj = undef; 
  EsmLib::LoadJson($errJson, \$errObj);
  my $clientCode  = $errObj->{clientcode};
  # ESM での検索には "imo_num" を使う (ESM受入 EditESM-03 不具合対応)
  # my $wnishipnum  = $errObj->{wnishipnum};
  my $imo_num  = $errObj->{imo_num};
  my $editMsgId   = $errObj->{messageid};
  my $editType    = $errObj->{edit_type};
  # 検索に諸々値を使っているはず。開始ログを追加。
  $log->Info( "given data: [clientCode:%s][imo_num:%s][messageid:%s][type:%s]\n", $clientCode, $imo_num, $editMsgId, $editType );
  
  my $targetReportTime = $errObj->{target_report_time};
  foreach my $node ( @{$errObj->{edit_data}} ) {
    if ($node->{key} eq "report_time") {
      $targetReportTime = $node->{value};
      last;
    }
  }
  
  my $defObj = _getDefDailyData($clientCode);

  # ESM での検索には "imo_num" を使う (ESM受入 EditESM-03 不具合対応)
  my $tgtDailyPath = _pickUpDailyFilePath($clientCode, $imo_num, $editMsgId, $targetReportTime, $defObj);
  unless (-e $tgtDailyPath) {
    die "tgt file is not found ($tgtDailyPath)\n";
  }
  $log->Info("file path:: $tgtDailyPath\n");
  # ----- merge error layer ----- #
  my $dailyDataObj    = undef;
  EsmLib::LoadJson($tgtDailyPath, \$dailyDataObj);

  # ----- delete関数は使わず、@newRepAryに変更が必要でないreport、変更が必要なreportは変更を加えた上で追加 ----- #
  my @newRepAry = ();
  my $repAryLen = $#{$dailyDataObj->{report}};
  for (my $i=0; $i<=$repAryLen; $i++) {
    my $repObj = @{$dailyDataObj->{report}}[$i];

    # ----- ESM では、messageid は report_info に記録されている ----- #
    unless ($repObj->{report_info}{messageid} eq $editMsgId) {
      push (@newRepAry, $repObj);
      next;
    }
    
    # ----- errorレイヤーをマージ ----- #
    if(!exists($repObj->{error})){
      $repObj->{error} = [];
    }
    push(@{$repObj->{error}}, $errObj);
    
    my $isMoveAnotherFile = 0;
    if($editType eq "delete" || $editType eq "enabled"){
      ## if deleted by other system , can't delete rollback
      if($editType eq "delete" && $repObj->{"report_info"}->{"delete_at"}){
        push (@newRepAry, $repObj);
        next;
      }
      ## if enabled by other system , can't enabled rollback
      if($editType eq "enabled" && $repObj->{"report_info"}->{"enabled_at"}){
        push (@newRepAry, $repObj);
        next;
      }
      
      my $rollback = $editType eq "delete" ? "enabled" : "delete";
      $log->Info("Roll up ($editType) $editType => $rollback\n");
      &EsmLib::UpdateInvalid($repObj, $rollback);
    } else {
      my $isAlreadyAddError = 0;
      foreach my $node ( @{$errObj->{edit_data}} ) {
        my $editDataKey = $node->{key};
        my $editBaseVal = $node->{base_value};
        
        if($editDataKey eq "lat" || $editDataKey eq "lon"){
          $repObj->{forceBlankWx} = JSON::false;
          $editBaseVal = EsmLib::MinToLatLon($editBaseVal, $editDataKey);
        }
        
        if (_isEditRepTime($editDataKey)) {
          my ($yyyy, $mm, $other) = split(/-|\//, $editBaseVal, 3); # 2018-04-01T00:00:00
          # ESM での検索には "imo_num" を使う (ESM受入 EditESM-03 不具合対応)
          my $orgDailyDataPath = sprintf("$EsmConf::DAILY_DATA_DIR/$clientCode/$imo_num/%s/%s.json", $yyyy, $mm);
          $log->Info("Roll up (delete):: $repObj->{report_info}{delete} => JSON::false\n");
          $repObj->{report_info}{delete} = JSON::false;
          #$repObj->{calc}{report_time} = $editBaseVal;
          
          if($repObj->{calc}{report_time} eq $node->{value}){
            # remove new date report.
            $isMoveAnotherFile = 1;
          }
          
          unless ($tgtDailyPath eq $orgDailyDataPath) {
            $log->Info("merge another file:: $orgDailyDataPath\n");
            my $orgDailyData = undef;
            EsmLib::LoadJson($orgDailyDataPath, \$orgDailyData);
            foreach my $report (@{$orgDailyData->{report}}){
              # ----- ESM では、messageid は report_info に記録されている ----- #
              if($report->{report_info}{messageid} eq $editMsgId){
                unless($isAlreadyAddError){
                  if(!exists($report->{error})){
                    $report->{error} = [];
                  }
                  push(@{$report->{error}}, $errObj);
                  $isAlreadyAddError = 1;
                }
                $report->{report_info}{delete} = JSON::false ;
              }
            }
            &_reCalcRepObj($editMsgId, $orgDailyData->{report}, $orgDailyDataPath, $defObj->{calc_diff_frm_last_rep});
            EsmLib::SaveJson($orgDailyDataPath, $orgDailyData, 1);
            # $UNIX->write("$orgDailyDataPath\n");
            #$isMoveAnotherFile = 1;
          }
        } else {
          $log->Info("Roll up ($editDataKey):: $repObj->{calc}{$editDataKey} => $editBaseVal\n");
          $repObj->{calc}{$editDataKey} = $editBaseVal;
        }
      }
    }
    push (@newRepAry, $repObj) unless ($isMoveAnotherFile);
  }
  &_reCalcRepObj($editMsgId, \@newRepAry, $tgtDailyPath, $defObj->{calc_diff_frm_last_rep});
  
  my %saveObj = (
    ship_info => $dailyDataObj->{ship_info},
    period    => {
      start_time => $newRepAry[0]->{calc}{report_time},
      end_time   => $newRepAry[$#newRepAry]->{calc}{report_time}
    },
    report => \@newRepAry
  );
  EsmLib::SaveJson($tgtDailyPath, \%saveObj, 1);
  # $UNIX->write("$tgtDailyPath\n");
}

sub _pickUpDailyFilePath {
  my ($clientCode, $imo_num, $messageid, $targetReportTime, $defObj) = @_;
  $log->Info( " _pickUpDailyFilePath start, [client:%s][imo_num:%s][messageid:%s][report_time:%s]\n",
              $clientCode, $imo_num, $messageid, $targetReportTime );

  my $filePath = undef;
  $log->Info( "  used command: [grep -rl -e 'messageid\" : \"$messageid\"' $EsmConf::DAILY_DATA_DIR/$clientCode/$imo_num | grep -v swp | grep -v bk]\n" );
  my $searchFilePath = sprintf("%s/$defObj->{save_dir}", $EsmConf::BASE_TOP, $clientCode, $imo_num);
  $filePath = `grep -rl -e 'messageid" : "$messageid"' $searchFilePath | grep -v swp | grep -v bk`;

  my @paths = split(/\n/, $filePath);
  if(scalar(@paths) > 1 && $targetReportTime){
    #pickup new date report path
    my $availablPath = "";
    foreach my $path (@paths) {
      my $tmp = undef;
      EsmLib::LoadJson($path, \$tmp);
      foreach my $report (@{$tmp->{"report"}}){
        if($report->{"report_info"}->{"messageid"} eq $messageid && $report->{"calc"}->{"report_time"} eq $targetReportTime){
          $availablPath = $path;
          last;
        }
      }
      last if($availablPath ne "");
    }
    $filePath = $availablPath;
  }
  $filePath =~ s/\n//; 
  return $filePath;
}

sub _isEditRepTime {
  my $editKey = shift;
  my $isRepTimeKey = 0;

  my @tgtKey = qw(
    dep_berth_time
    dep_ps_time
    dep_sosp_time
    arr_eosp_time
    arr_ps_time
    arr_berth_time
    report_time
  );
  if (EsmLib::InAry($editKey, \@tgtKey)) {
    $isRepTimeKey = 1;
  }
  return $isRepTimeKey;
}

sub _getDefDailyData {
  my $client = shift;

  # --- 顧客別の定義ファイルがあれば、顧客定義を参照（なければdefault） --- #
  my $defFilePath = sprintf("%s/daily/def_adjust_daily_data_%s.json", $EsmConf::CONF_DIR, $client);
  unless (-e $defFilePath) {
    $defFilePath = "$EsmConf::CONF_DIR/daily/def_adjust_daily_data.json";
    die "can't get conf/daily/def_adjust_daily_data.json\n" unless (-e $defFilePath);;
  }
  $log->Info("def daily path:: $defFilePath\n");
  my $obj = undef;
  EsmLib::LoadJson($defFilePath, \$obj);
  return $obj;
}
sub _reCalcRepObj {
  my ($thisMsgId, $reportAry, $saveFilePath, $defCalcObj) = @_;

  # ================================================================= #
  #  今回追加するレポートの前後の値を算出する                         #
  #　今回追加するレポートは、messageidをkeyに特定する                 #
  #　今回追加するレポートがDepartureの場合、一つ前との差分は求めない  #
  #   (DEPで捕油されて、値がマイナスになる可能性がある)               #     
  #                                                                   #
  #      差分                     -1400    DEP                        #
  #               ----------+---------------+----------------         #
  #      ROB               100             1500                       #
  #                                                                   #
  #  次のレポートがDepartureの場合も、次のレポートとの差分は求めない  #
  #                                                                   #
  #      差分              今回追加    -1100        DEP               #
  #               ------------+----------------------+--------        #
  #      ROB                 200                    1300              #
  # ================================================================= #

  my $defCalcDiff = $defCalcObj->{diff_frm_last_rep}; 
  my $defCalcSum  = $defCalcObj->{sum_val};
  my $defCalcCo2  = $defCalcObj->{calc_co2};

  @$reportAry = sort {EsmLib::StrToEpoch($a->{calc}{report_time}) cmp EsmLib::StrToEpoch($b->{calc}{report_time})} @$reportAry;

  my $repAryLen = $#$reportAry;
  for (my $i=0; $i<=$repAryLen; $i++) {
    next unless ($thisMsgId eq @$reportAry[$i]->{report_info}{messageid});
    my $thisRepNode = @$reportAry[$i];

    #----- EditESM-03 2018/06/14 TmaxLib.pm では "I"sInvalid... だったので、合わせます -----#
    my $isInvalid = &EsmLib::IsInvalidReport($thisRepNode);
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
            _createPrevLayer( $thisRepNode, $prevRepNode, $defCalcDiff );
          }
        } else {
          # --- 一つ前のレポートが月をまたがない場合 (同一ファイル内にある) --- #
          if (@$reportAry[$i-1]) {
            # --- 一つ前のレポートがある && $thisRepType が DEPじゃない --- #
            my $prevRepNode = @$reportAry[$i-1];
            _calcMinus($thisRepNode, $prevRepNode, $defCalcDiff);
            _calcPlus($thisRepNode, $defCalcSum) if (defined $defCalcSum);
            _calcCo2( $thisRepNode, $defCalcCo2) if (defined $defCalcCo2);
            _createPrevLayer( $thisRepNode, $prevRepNode, $defCalcDiff );
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
          _createPrevLayer( @{$nextDailyObj->{report}}[0], $thisRepNode, $defCalcDiff );
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
            _createPrevLayer( @$reportAry[$i+1], $thisRepNode, $defCalcDiff );
          }
        }
      }
    }
  }
}

sub _createPrevLayer {
  my ($repNode, $prevRepNode, $defCalcDiff) = @_; 

  foreach my $saveItem ( keys %$defCalcDiff ) {
    my ($itemLayer, $itemKey) = split(/\./, $saveItem);
    my ($useItemLayer, $useItemKey) = split(/\./, $defCalcDiff->{$saveItem});
    $repNode->{prev}{$useItemKey} = $prevRepNode->{$useItemLayer}{$useItemKey};
  }
  $repNode->{prev}{messageid}   = $prevRepNode->{report_info}{messageid};
  $repNode->{prev}{report_type} = $prevRepNode->{calc}{report_type};
  $repNode->{prev}{data_path}   = $prevRepNode->{calc}{data_path};
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

sub _getPrevFilePath {
  my $dir = shift;

  # =====
  # 今回保存するファイルパスから、時系列的に一つ前のファイルを特定する。
  # prevFilePathの取得は、ひと月前まで。
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

####################
####################

eval {
  main();
};
if ($@) {
  $log->Error("$@");
}
$log->Close();
