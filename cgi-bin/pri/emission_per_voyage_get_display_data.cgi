#! /usr/local/bin/perl

use strict;
use warnings;

umask 000;
use CGI;
use JSON;
use Encode;
use File::Path qw(mkpath);
use Data::Dumper;
use open ":utf8";
use Time::Local;
use POSIX qw(strftime);
use File::Copy;
use File::Basename;
use Time::HiRes qw/ gettimeofday /;

BEGIN{
  my $mylibdir = "/usr/amoeba/pub/b/ESM/lib";
  push( @INC, $mylibdir );
}
use EsmConfigWeb;
use EsmLogger;
use EsmLib;
use DataFormat;

use constant VOYAGE => "voyage";
use constant VOYAGE_INDEX => "voyage_index";

#-----------------------------------------
# init logging
#-----------------------------------------
mkpath($EsmConfigWeb::LOG_DIR);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "emission_per_voyage_get_display_data.cgi.%d",$ymd );
my $log = EsmLogger->Open( $log_fname ) or die($!);

END{
  $log->Close() if( defined( $log ) );
}

my %DATE = qw(JAN 1 FEB 2 MAR 3 APR 4 MAY 5 JUN 6 JUL 7 AUG 8 SEP 9 OCT 10 NOV 11 DEC 12);

###############################
# Main process
###############################
sub main {
  my $cgi = CGI->new;
  my %json = ();
  eval {
    my $client_code    = $cgi->param("client_code") || '';
    my $imo_num        = $cgi->param('imo_num') || '';
    my $select_year    = $cgi->param('select_year') || '';
    my $get_target_id  = $cgi->param('get_target_id') || '';
    my $account_id     = $cgi->param("account_id") || '';

    my $callback     = $cgi->param("callback") || "";

    my $json = '';

    # 入力チェック
    my $str_param = &checkParam($client_code, $imo_num, $select_year, $get_target_id, $account_id);
    if($str_param ne ""){
      EsmLib::OutPutNG("failed because the ${str_param} is empty", $callback);
      $log->Error("error: [client_code=%s]:[imo_num=%s]:[select_year=%s]:[get_target_id=%s]:[failed because the %s is empty]\n",
                  $client_code, $imo_num, $select_year, $get_target_id, $str_param);
      return;
    }

    my $path ="";
    my $ship_info;
    my $record_type = "";

    my $voyage_list = {};

    my $result = {};
    $result->{result_data} = [];
    $result->{downloadKey} = "";

    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);

    # 取得対象識別子が"voyage"の場合
    if ($get_target_id eq "voyage") {

      # Voyageインデックスファイル取得
      my @voyage_idx_file_name_list = &getVoyageIndex($select_year, $client_code, $imo_num);

      # Voyageインデックスファイルソート
      my @sort_idx_file_name_list = &sortVoyageIdxProc(\@voyage_idx_file_name_list);

      # Voygae情報をソート、航海キー作成、データフフォーマットを実施する。
      my @result_sort_voyage;
      ($ship_info, @result_sort_voyage) = &sortVoyageListProc(\@sort_idx_file_name_list, $get_target_id, $client_code, $imo_num);

      # データ取得できなかった場合、正常終了でNO DATA出力
      unless (defined \@result_sort_voyage) {
        $result->{result} = "OK";
        $log->Info(" voyage data Unkown : [imo_num=%s]:[client_code=%s]\n", $imo_num, $client_code);
        EsmLib::OutPutOK(to_json( $result, {utf8=>1,pretty=>0}), $callback);
        return;
      }

      # データフォーマット起動
      my @fmt_voyage;

      foreach my $voyage_rec(@result_sort_voyage) {

# bug-077 update start
        while (my ($key,$value) = each(%{$voyage_rec})) {
          if (ref($value) eq 'ARRAY' || ref($value) eq 'HASH' ){
            $voyage_rec->{$key} = '';
          }
        }
# bug-077 update end

        $record_type = $voyage_rec->{record_type};

        my $fmt_voyage_rec = $data_format->load_format_def($get_target_id, $voyage_rec, $record_type);
        push(@fmt_voyage, $fmt_voyage_rec);

      }

      # データ出力
      push(@{$result->{result_data}}, @fmt_voyage);

      # DL用データファイル、downloadkey作成
      my $file_head = "voyage";

      my $downloadKey = &createDownloadFile($result, $ship_info, $client_code, $imo_num, $account_id, $file_head);
      $result->{downloadKey} = $downloadKey;
      $result->{ship_info} = $ship_info;

      # return
      $result->{result} = "OK";
      $log->Info("completed: [imo_num=%s]:[client_code=%s]\n", $imo_num, $client_code);

      EsmLib::OutPutOK(to_json( $result, {utf8=>1,pretty=>0}), $callback);

      return;

    # 取得対象識別子が"eu_mrv"の場合
    } elsif ($get_target_id eq "eu_mrv"){

      # EU-MRV年間値ファイルを取得する
      $path = sprintf("%s/%s/%s/%s/eu_mrv_annual.json", $EsmConfigWeb::ESM3_ANNUAL_DATA_DIR, $client_code, $imo_num, $select_year);

      my $eu_mrv_annual_data = &fetchingFiles($path);

      # データ取得できなかった場合、正常終了でNO DATA出力
      unless (defined $eu_mrv_annual_data) {
        $result->{result} = "OK";
        $log->Info("eu_mrv data Unkown : [imo_num=%s]:[client_code=%s]\n", $imo_num, $client_code);
        EsmLib::OutPutOK(to_json( $result, {utf8=>1,pretty=>0}), $callback);
        return;
      }

      # eu_mrv 設定
      $eu_mrv_annual_data->{data}->{in_port}->{data}->{eu_mrv} = "in_eu_port";
      $eu_mrv_annual_data->{data}->{dep_from_eu_port}->{data}->{eu_mrv} = "dep_from_eu_port";
      $eu_mrv_annual_data->{data}->{arr_at_eu_port}->{data}->{eu_mrv} = "arr_at_eu_port";
      $eu_mrv_annual_data->{data}->{eu_to_eu}->{data}->{eu_mrv} = "eu_to_eu";
      $eu_mrv_annual_data->{data}->{summary}->{data}->{eu_mrv} = "summary";

      # 年間値の出力順序に並び替える
      my @sort_eu_mrv_annual = (

        $eu_mrv_annual_data->{data}->{in_port}->{data},
        $eu_mrv_annual_data->{data}->{dep_from_eu_port}->{data},
        $eu_mrv_annual_data->{data}->{arr_at_eu_port}->{data},
        $eu_mrv_annual_data->{data}->{eu_to_eu}->{data},
        $eu_mrv_annual_data->{data}->{summary}->{data}

      );

      # データフォーマット起動
      my @fmt_eu_mrv_annual;

      foreach my $eu_mrv_annual_rec(@sort_eu_mrv_annual) {

# bug-077 update start
        while (my ($key,$value) = each(%{$eu_mrv_annual_rec})) {
          if (ref($value) eq 'ARRAY' || ref($value) eq 'HASH' ){
            $eu_mrv_annual_rec->{$key} = '';
          }
        }
# bug-077 update end

        my $fmt_eu_mrv_annual_rec = $data_format->load_format_def($get_target_id, $eu_mrv_annual_rec, $record_type);

        push(@fmt_eu_mrv_annual, $fmt_eu_mrv_annual_rec);

      }

      # データ出力
      push(@{$result->{result_data}}, @fmt_eu_mrv_annual);

      # DL用データファイル、downloadkey作成

      $ship_info = $eu_mrv_annual_data->{data}->{ship_info};

      my $file_head = "eumrv";

      my $downloadKey = &createDownloadFile($result, $ship_info, $client_code, $imo_num, $account_id, $file_head);
      $result->{downloadKey} = $downloadKey;
      $result->{ship_info} = $ship_info;

      # return
      $result->{result} = "OK";
      $log->Info("completed: [imo_num=%s]:[client_code=%s]\n", $imo_num, $client_code);
      EsmLib::OutPutOK(to_json( $result, {utf8=>1,pretty=>0}), $callback);
      return;

    # 取得対象識別子が"imo_dcs"の場合
    } elsif ($get_target_id eq "imo_dcs"){

      # IMO_DCS年間値ファイルを取得する
      $path = sprintf("%s/%s/%s/%s/imo_dcs_annual.json", $EsmConfigWeb::ESM3_ANNUAL_DATA_DIR, $client_code, $imo_num, $select_year);

      my $imo_dcs_annual_data = &fetchingFiles($path);

      # データ取得できなかった場合、正常終了でNO DATA出力
      unless (defined $imo_dcs_annual_data) {
        $result->{result} = "OK";
        $log->Info("imo_dcs data Unkown : [imo_num=%s]:[client_code=%s]\n", $imo_num, $client_code);
        EsmLib::OutPutOK(to_json( $result, {utf8=>1,pretty=>0}), $callback);
        return;
      }

      # eu_mrv 設定
      $imo_dcs_annual_data->{data}->{beginning_of_year}->{data}->{eu_mrv} = "beginning_of_year";
      $imo_dcs_annual_data->{data}->{middle_of_year}->{data}->{eu_mrv} = "middle_of_year";
      $imo_dcs_annual_data->{data}->{end_of_year}->{data}->{eu_mrv} = "end_of_year";
      $imo_dcs_annual_data->{data}->{summary}->{data}->{eu_mrv} = "summary";

      # 年間値の出力順序に並び替える
      my @imo_dcs_annual_data = (

        $imo_dcs_annual_data->{data}->{beginning_of_year}->{data},
        $imo_dcs_annual_data->{data}->{middle_of_year}->{data},
        $imo_dcs_annual_data->{data}->{end_of_year}->{data},
        $imo_dcs_annual_data->{data}->{summary}->{data}

      );

      # $log->Info("dumper data : %s", Dumper \@imo_dcs_annual_data);
      # データフォーマットを実施する レコード単位での実施をするのでforeachを使用
      my @fmt_imo_dcs_annual;

      foreach my $imo_dcs_annual_rec(@imo_dcs_annual_data) {

# bug-077 update start
        while (my ($key,$value) = each(%{$imo_dcs_annual_rec})) {
          if (ref($value) eq 'ARRAY' || ref($value) eq 'HASH' ){
            $imo_dcs_annual_rec->{$key} = '';
          }
        }
# bug-077 update end

        my $fmt_imo_dcs_annual_rec = $data_format->load_format_def($get_target_id, $imo_dcs_annual_rec, $record_type);

        push(@fmt_imo_dcs_annual, $fmt_imo_dcs_annual_rec);

      }

      # データ出力
      push(@{$result->{result_data}}, @fmt_imo_dcs_annual);

      # DL用データファイル、downloadkey作成

      $ship_info = $imo_dcs_annual_data->{data}->{ship_info};

      my $file_head = "imodcs";

      my $downloadKey = &createDownloadFile($result, $ship_info, $client_code, $imo_num, $account_id, $file_head);
      $result->{downloadKey} = $downloadKey;
      $result->{ship_info} = $ship_info;

      # return
      $result->{result} = "OK";
      $log->Info("completed: [imo_num=%s]:[client_code=%s]\n", $imo_num, $client_code);
      EsmLib::OutPutOK(to_json( $result, {utf8=>1,pretty=>0}), $callback);
      return;

  }

};
  if( $@ ){
    $log->Info("Error.\n$@\n");
    EsmLib::OutPutNG("$@");
    return;
  }
}

#==========================================================
# Function for argument check
#==========================================================
sub checkParam {
  $log->Info("{start Function checkParam}\n");
  my ($client_code, $imo_num, $select_year, $get_target_id, $account_id) = @_;

  my $str_param = "";
  $log->Info("  Parameter {client_code:[$client_code] imo_num:[$imo_num] select_year:[$select_year] get_target_id:[$get_target_id]} } account_id:[$account_id]}\n");
  if($client_code eq '' || $imo_num eq '' || $select_year eq '' || $get_target_id eq '' || $account_id eq '') {
    my @params = ();
    unless($client_code){
      push(@params, "client_code");
    }
    unless($imo_num){
      push(@params, "imo_num");
    }
    unless($select_year){
      push(@params, "select_year");
    }
    unless($get_target_id){
      push(@params, "get_target_id");
    }
    unless($account_id){
      push(@params, "account_id");
    }
    $str_param = join(' and ', @params);
  }
  $log->Info("{end Function checkParam}\n");
  return $str_param;
}

#==========================================================
# Function for fetching files
#==========================================================
sub fetchingFiles {
  $log->Info("{start Function fetchingFiles}\n");
  my $path        = shift;

  # ファイルのload
  my $result = undef;
  $log->Info("  load $path\n");
  EsmLib::LoadJson($path, \$result);
  $log->Info("  load finish.\n");

  $log->Info("{end Function fetchingFiles}\n");
  return $result;
}

#==========================================================
# Function for serch file
#==========================================================
sub searchFiles {
  $log->Info("{start Function serchFiles}\n");
  my $path        = shift;
  my $select_year = shift;

  # file serch
  my @result;
  $log->Info("  load $path\n");

  my @files = glob "$path/*.json";

  foreach my $file_abs_path(@files){

    my $file_name = basename($file_abs_path);
    my @idx = split /_/, $file_name;
    my ($from_yyyy, $to_yyyy) = (substr($idx[0], 0, 4), substr($idx[1], 0, 4));

    if ( ($from_yyyy && $to_yyyy)
          && ($from_yyyy == $select_year || $to_yyyy == $select_year) ){

      push(@result, $file_abs_path);
    } else {
      next;
    }
  }

  $log->Info("  load finish.\n");

  $log->Info("{end Function serchFiles}\n");
  return @result;
}

#==========================================================
# Function for get voyageIndex list of each year
#==========================================================
sub getVoyageIndex {
  $log->Info("{start Function getVoyageList}\n");
  my ($select_year, $client_code, $imo_num) = @_;
  my @voyage_idx_file_list;
  my $path = "";
  my $abs_path = "";
  my @file_name_list;

  $path = sprintf("%s/%s/%s/%s", $EsmConfigWeb::ESM3_VOYAGE_DATA_DIR, $client_code, $imo_num, VOYAGE_INDEX);

  @file_name_list = &searchFiles($path, $select_year);

  foreach my $file_name(@file_name_list){

    push(@voyage_idx_file_list, $file_name);

  }

  return @voyage_idx_file_list;

}

#==========================================================
# Function for sort voyageIndex list
#==========================================================
sub sortVoyageIdxProc {
  $log->Info("{start Function sortVoyageProc}\n");
  my ($params) = @_;
  my @voyage_idx_list = @{$params};
  my $path = "";
  my @sort_array = ();
  my $sort_key = "";
  my @result;

  # ソートキーの生成と付与を行う
  foreach my $voyage_idx (@voyage_idx_list){

    my $file_name = basename($voyage_idx);

    my $from_ads = index($file_name, "_");

    my $from_year = substr($file_name, 0, $from_ads);

    my $to_ads = index($file_name, "_");

    $to_ads++;

    my $to_year = substr($file_name, $to_ads, -7);

    my $lov_id = substr($file_name, -6, 1);

    if ($to_year ne "" ){

      $sort_key = $to_year.$lov_id;
      push(@sort_array, {key => $sort_key, value => $voyage_idx});

    } elsif ($from_year ne "" ){

      $sort_key = $to_year.$lov_id;
      push(@sort_array, {key => $sort_key, value => $voyage_idx});

    }
  }

  # 判定用配列のソート
  my @voyage_sort_list_map = sort { $b->{ key } cmp $a->{ key } } @sort_array ;

  foreach my $hash_rec(@voyage_sort_list_map){
    push(@result, $hash_rec->{ value });
  }

  return @result;
}

#==========================================================
# Function for sort voyage list
#==========================================================
sub sortVoyageListProc {

  # voyage情報リストのソート、航海キー作成を実施する

  $log->Info("{start Function sortVoyageProc}\n");
  my ($params, $target_id, $client_code, $imo_num) = @_;
  my @file_list = @{$params};

  my $sort_idx_list = {};
  my $path = "";
  my $abs_path = "";
  my @file_name_list;
  my $to_reftime = "";
  my @sort_array;
  my $sort_key = "";

  my $voyage_info_path = "";

  my $data_format = "";
  my @result;
  my $ship_info;

  foreach my $file_name(@file_list){

    my $voyage_data = &fetchingFiles($file_name);

    my $voyage_info_path = $voyage_data->{voyage_file_path};

    my $voyage_file_name = basename($voyage_info_path);

    my $target_num = rindex($voyage_file_name, "_");
#    $target_num--;
    my $voyage_key = substr($voyage_file_name, 0, $target_num);
    my $voyage_info = &fetchingFiles($voyage_info_path);

    unless (defined $voyage_info) {
      next;
    }

    my $result_data;

    $result_data->{result_data} = $voyage_info->{data}->{for_row}->{data};
    $result_data->{result_data}->{record_type} = $voyage_info->{data}->{record_type};
    $result_data->{result_data}->{voyage_key} = $voyage_key;

    $ship_info = $voyage_info->{data}->{include_reports}->{ship_info};

    push(@result, $result_data->{result_data});

  }

  return ($ship_info, @result);
}

#==========================================================
# Function for create download file
#==========================================================
sub createDownloadFile{
  $log->Info("{start Function Function createDownloadFile}\n");
  my ($result, $ship_info, $client_code, $imo_num, $account_id, $file_head) = @_;

  my %tmp_result = %{$result};
  $tmp_result{'ship_info'} = $ship_info;
  $log->Info("  set ship_info->allsign_repo => $ship_info->{callsign_repo}\n");
  $log->Info("  set ship_info->wni_ship_num => $ship_info->{wni_ship_num}\n");
  $log->Info("  set ship_info->vessel_name_repo => $ship_info->{vessel_name_repo}\n");
  $log->Info("  set ship_info->imo_num_repo => $ship_info->{imo_num_repo}\n");

  my $now = time();
  my $y_day_time = time - 24 * 3600;

  my $downloadKey = &EpochToStrMicroSec($now, "%Y%m%d%H%M%S");

  my $yesterday = &EpochToStrMicroSec($y_day_time, "%Y%m%d%H%M%S");

  $downloadKey =  $downloadKey . "_" . $account_id;
  $log->Info("  create downloadKey => $downloadKey\n");

  $tmp_result{'downloadKey'} = $downloadKey;

  my $save_file_dir = sprintf("%s/%s/%s/", $EsmConfigWeb::ESM_TMP_DIR, $client_code, $imo_num);

  if (! -e $save_file_dir) {
     mkpath($save_file_dir);
  }

  #remove
  opendir(DIR, $save_file_dir);
  my @files = grep(/$file_head/,readdir(DIR));
  closedir(DIR);
  foreach my $file (@files) {
     my @arr = split /[_.]+/, $file;

     if($arr[2] eq $account_id && $arr[0] eq $file_head){

       if ($arr[1] lt $yesterday ) {
         $log->Info("  remove old file(s) by [$file]\n");
         `rm $save_file_dir/$file`;
       }
     }
  }

  # create path
  my $path = sprintf("%s/%s/%s/%s_%s.json", $EsmConfigWeb::ESM_TMP_DIR, $client_code, $imo_num, $file_head, $downloadKey);

  # create file
  my $tmpPath = $path . ".$$.tmp";
  open(FH, ">$tmpPath");
  print FH JSON->new->utf8(0)->encode(\%tmp_result);
  close(FH);
  File::Copy::move($tmpPath, $path) or die 'Cannot move '.$tmpPath. 'to'. $path;

  $log->Info("{end Function createDownloadFile}\n");
  return $downloadKey;
}


####################################
# Function for Epoch chenge To Str
####################################
sub EpochToStrMicroSec {
  my $t   = shift;
  my $fmt = shift || "%Y-%m-%dT%H:%M:%S";
  my ($sec, $min, $hour, $mday, $mon, $year);

  if( $t eq "" || int($t) == 0 ){
    return "";
  }

  eval{
    ($sec,$min,$hour,$mday,$mon,$year) = gmtime( $t );
  };
  if($@){
    croak( "epochtostrMicroSec($t) ". $@ . "\n" . Carp::longmess . "\n" );
  }

  my ($seconds, $microsec) = gettimeofday();
  $microsec = sprintf( "%03d", $microsec / 1000 ) ;

  my $s = strftime($fmt, $sec, $min, $hour, $mday, $mon, $year);

  $s .= $microsec;

  return $s;
}

&main();

1;
