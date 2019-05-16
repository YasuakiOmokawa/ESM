#! /usr/local/bin/perl
# $Id: voyage_info_edit_proc.cgi

use strict;
use warnings;
use File::Basename;
use File::Path qw(mkpath);
use CGI;
use POSIX qw(strftime);
use JSON;
use Data::Dumper;

BEGIN{
  my $mylibdir = "/usr/amoeba/pub/b/ESM/lib";
  push( @INC, $mylibdir );
}
use EsmConfigWeb;
use EsmLogger;
use EsmLib;
use VoyageDataEditReSummarizer;
use ExclusiveControl;

#-----------------------------------------
# init logging
#-----------------------------------------
mkpath($EsmConfigWeb::LOG_DIR);
my $top_dir = $EsmConfigWeb::APP_ROOT_DIR;
my $prog_name = basename(__FILE__);

my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s.%d", $prog_name, $ymd );
my $spool_dir = sprintf("%s/spool/edit_spool", $top_dir);

my $log = EsmLogger->Open( $log_fname );

END{
  $log->Close() if( defined( $log ) );
}

###############################
# Main process
###############################
sub main {
  my $cgi = CGI->new;

  $log->Info("voyage inte edit cgi start.\n");

  my @return_data;
  my %return_json_data = ();

  # タイムアウト時間設定
  my $timeout = 180;

  eval{
    
    # タイムアウト定義
    local $SIG{ALRM} = sub {die "timeout"};

    # タイムアウト処理
    alarm $timeout;

    # ロック処理
    my $ec = ExclusiveControl->new($spool_dir, $prog_name, 6, $log);

    if ($ec->do()) {

      # input
      my $pre_edit_value = $cgi->param('before_data');
      my $client_code    = $cgi->param('client_code') || '';
      my $edit_data      = $cgi->param('edit_data');
      my $edit_key       = $cgi->param('edit_key') || '';
      my $type           = $cgi->param('imo_dcs_type') || '';
      my $imo_num        = $cgi->param('imo_num') || '';
      my $editor         = $cgi->param('mail_address') || '';
      my $voy_key        = $cgi->param('voyage_key') || '';
      my $year           = $cgi->param('select_year') || '';
      my $callback       = $cgi->param("callback") || "";
      # 入力チェック
      # my $str_param = &checkParam($pre_edit_value, $client_code, $edit_data, $edit_key, $imo_num, $editor, $year);
      my $str_param = &checkParam($client_code, $edit_key, $imo_num, $editor, $year);
      # 入力チェックで問題があった場合エラー
      if($str_param ne ""){
        $log->Error("error: [failed because the %s is empty]\n", $str_param);
        $return_json_data{result} = 'NG';
        $return_json_data{message} = 'Faild to input param.';
        &returnResult($cgi, \%return_json_data);
#        EsmLib::OutPutNG("failed because the ${str_param} is empty", $callback);
        return;
      }

      # type voy_key 相関チェック
      my $error_str = "";
      if ($type eq "" && $voy_key eq "") {
        $error_str = "type and voy_key are is empty";
      } elsif ($type ne "" && $voy_key ne "") {
        $error_str = "there is input in type and voy_key";
      }

      # 相関チェックのエラー処理
      if ($error_str ne "" ){
        $log->Error("error: [failed because %s]\n", $error_str);
        $return_json_data{result} = 'NG';
        $return_json_data{message} = 'Faild to Correlation check error.';
        &returnResult($cgi, \%return_json_data);
        return;
      }

      # eu_mrv_displayからeu_mrvにkey変換
      if ($edit_key eq "eu_mrv_display"){
        $edit_key = "eu_mrv";
      }

      # port変換
      if ($edit_key eq "dep_port_display") {
        $edit_key = "dep_port";
      }

      # port変換
      if ($edit_key eq "arr_port_display") {
        $edit_key = "arr_port";
      }

      # 年間値集計クラスインスタンス生成
      my $annual_class = VoyageDataEditReSummarizer->new($log);

      $log->Info("annual class input : imo_num[$imo_num], client_code[$client_code], voy_key[$voy_key], type[$type], year[$year], editor[$editor], edit_key[$edit_key], edit_data[$edit_data], pre_edit_value[$pre_edit_value] .\n");
      # 年間値計算・保存処理
      my $annual_class_result = $annual_class->edit_and_save($imo_num, $client_code, $voy_key, $type, $year, $editor, $edit_key, $edit_data, $pre_edit_value);

      if (!$annual_class_result) {
        $log->Error("error: [%s] : class error.\n", &getTimeStamp("log") );
        $return_json_data{result} = 'INFO';
        $return_json_data{message} = 'Another user disabled the same record. Your work is lost.';
        &returnResult($cgi, \%return_json_data);
        return;
      }
      
      # 返却処理
      $return_json_data{result} = "OK";
      $return_json_data{message} = "Update Completed!";
      $log->Info("completed: [imo_num=%s]:[client_code=%s]\n", $imo_num, $client_code);
      &returnResult($cgi, \%return_json_data);

      alarm 0;

      return;
    }
  };

  #-----------------------------------------
  # error check
  #-----------------------------------------
  if ($@) {

    $log->Error("Error [$@]\n");
    $return_json_data{result} = "NG";
    $return_json_data{message} = "An unexpected error occurred.";
    &returnResult($cgi, @return_data);
    return;
  }
  $log->Close();
}

###############################
# get TimeStamp
###############################
sub getTimeStamp{
  my ( $output ) = @_;

  my %fmt = (mdb => "%04d/%02d/%02dT%02d:%02dZ", 
             log => "%04d/%02d/%02d %02d:%02d:%02d");

  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

  return sprintf($fmt{"$output"}, $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

###############################
# Read JSON File
###############################
sub loadJSON {
  my ($path) = @_;
  my $json = undef;
  eval {
    if (-f $path) {
      my $jsonstring = "";
      open(IN, "< $path");
      read (IN, $jsonstring, (-s "$path"));
      close IN;
      $log->Info("Read: $path\n");
      $json = JSON->new->utf8(0)->decode($jsonstring);
    }
  };
  if ($@) {
    $log->Error("JSON Read Error: $@\n");
    $json = undef;
  }
  return $json;
}

#==========================================================
# Function for argument check
#==========================================================
sub checkParam {
  $log->Info("{start Function checkParam}\n");
  my ($client_code, $edit_key, $imo_num, $editor, $year) = @_;

  my $str_param = "";

  $log->Info("  Parameter { client_code:[$client_code] edit_key:[$edit_key] imo_num:[$imo_num] editor:[$editor] year:[$year] } \n" );
  if($client_code eq '' || $edit_key eq '' || $imo_num eq '' || $editor eq '' || $year eq '') {
    my @params = ();
    unless($client_code){
      push(@params, "client_code");
    }
    unless($edit_key){
      push(@params, "edit_key");
    }
    unless($imo_num){
      push(@params, "imo_num");
    }
    unless($editor){
      push(@params, "editor");
    }
    unless($year){
      push(@params, "year");
    }
    $str_param = join(' and ', @params);
  }
  $log->Info("{end Function checkParam}\n");
  return $str_param;
}

###############################
# return result
###############################
sub returnResult {
  my ( $cgi, $result ) = @_;
  print $cgi->header('applecation/json; charset=utf-8\n\n');
  $result = $result || '';
  print JSON->new->utf8(0)->encode($result) . "\n";
}

&main();

1;
