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
use Spreadsheet::WriteExcel;

BEGIN{
  my $mylibdir = "/usr/amoeba/pub/b/ESM/lib";
  push( @INC, $mylibdir );
}
use EsmConf;
use EsmConfigWeb;
use EsmLogger;
use EsmMdbCommon;
use EsmLib;

#-----------------------------------------
# init logging
#-----------------------------------------
mkpath($EsmConfigWeb::LOG_DIR);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "emission_per_voyage_download.cgi.%d",$ymd );
my $log = EsmLogger->Open( $log_fname );
END{
  $log->Close() if( defined( $log ) );
}

my $cgi = CGI->new;
my $workbook = undef;

## Column definition
my $COLUMNS = [];

###############################
# Main process
###############################
sub main {
  my %json = ();
  eval {
    my $downloadKey  = $cgi->param('downloadKey') || '';
    my $imo_num      = $cgi->param('imo_num') || '';
    my $client_code  = $cgi->param("client_code") || '';
    my $target_id    = $cgi->param("target_id") || '';
    my $callback     = $cgi->param("callback") || '';
    
  $log->Info("param downloadKey:[$downloadKey] imo_num:[$imo_num] client_code:[$client_code] target_id:[$target_id]\n");

  unless( $client_code ){
    $log->Error("client_code is required.\n");
    EsmLib::OutPutNG("client_code is required", $callback);
    return;
  }
  
  unless( $imo_num ){
    $log->Error("imo_num is required.\n");
    EsmLib::OutPutNG("imo_num is required", $callback);
    return;
  }

  unless( $downloadKey ){
    $log->Error("downloadKey is required.\n");
    EsmLib::OutPutNG("downloadKey is required", $callback);
    return;
  }

  unless( $target_id ){
    $log->Error("target_id is required.\n");
    EsmLib::OutPutNG("target_id is required", $callback);
    return;
  }

  # target_id の切り出し
  $target_id =~s/_//;

  # カラム読み込み
  my $column_list = &column_loading();
  $COLUMNS = $column_list->{data}->{excel_column};

  if ($target_id eq 'imodcs'){
    foreach my $data (@{$COLUMNS}){
      if ($data->{key} eq 'eu_mrv_display') {
        $data->{category1} = 'IMO DCS';
      }
    }
  }

#  unless(%{$COLUMNS}){
  unless(\$COLUMNS){
    $log->Error("Excel_format is Read failed.\n");
    EsmLib::OutPutNG("Excel_format is Read failed.", $callback);
    return;
  }
  
  my $voyage_list = &getVoyageList($client_code, $imo_num, $downloadKey ,$target_id);
  unless(%{$voyage_list}){
    $log->Error("download_file is required.\n");
    EsmLib::OutPutNG("download_file is required.", $callback);
    return;
  }
  
  my $shipname    = "";
  my $callsign    = "";
  if(defined($voyage_list->{ship_info})){
    $shipname = $voyage_list->{ship_info}->{vessel_name_repo} || "";
    $callsign = $voyage_list->{ship_info}->{callsign_repo} || "";
  }

  my $table_def   = undef;
  my $display_all = 1;

  binmode(STDOUT);
  $workbook = Spreadsheet::WriteExcel->new(\*STDOUT);
  my $sheet = $workbook->add_worksheet();
  
  ## Definition STYLE
  my $header_bg  = $workbook->set_custom_color(60, 217, 217, 217); # args(index, r , g , b); index's range(8..63) (http://search.cpan.org/~jmcnamara/Spreadsheet-WriteExcel-2.40/lib/Spreadsheet/WriteExcel.pm#set_custom_color($index,_$red,_$green,_$blue))
  my $voyage_row = $workbook->set_custom_color(61, 240, 240, 240); 
  my $STYLE_VESSELNAME = $workbook->add_format(
    valign => 'vcenter',
    bold => 1,
    size => 12
  );
  my $STYLE_HEADER1 = $workbook->add_format(
    border       => 1,
    border_color => 22,
    size         => 10,
    text_wrap    => 1,
    bg_color     => $header_bg,
    valign       => 'vcenter',
    align        => 'center'
  );
  my $STYLE_HEADER2 = $workbook->add_format(
    border       => 1,
    border_color => 22,
    size         => 10,
    text_wrap    => 1,
    bg_color     => $header_bg,
    valign       => 'vcenter',
    align        => 'center'
  );
  my $STYLE_DAILY_VALUE = $workbook->add_format(
    size         => 10,
    border       => 1,
    border_color => 22,
    valign       => 'vcenter',
    align        => 'center'
  );
  my $STYLE_VOYAGE_VALUE = $workbook->add_format(
    size         => 10,
    border       => 1,
    border_color => 22,
    bg_color     => $voyage_row,
    valign       => 'vcenter',
    align        => 'center'
  );
  my $HEADER_STYLES = {
    "gray1" => $STYLE_HEADER1,
    "gray2" => $STYLE_HEADER2
  };
  
  # vessel name
  $sheet->set_row( 0, 30 );
  my $shipname_str = "";
  if($shipname ne "" && $callsign ne ""){
    $shipname_str = "$shipname / $callsign";
  }
  $sheet->write( 0, 0, "Vessel Name: $shipname_str", $STYLE_VESSELNAME );
  
  #=============
  # make header 
  #=============
  for (my $i=1; $i<=3; $i++) {
    $sheet->set_row( $i, 30 );
  }
  my @outputItems = ();
  
  my $headerRow = 1;
  my $col = 0;
  my ($mergeCount1, $mergeCount2) = (0,0);
  my ($category1, $category2, $category3, $tmpCategory1, $tmpCategory2) = ("","","","","");
  my $tmpColumn = {};
  foreach my $COLUMN (@{$COLUMNS}){
      
    push(@outputItems, $COLUMN);
    
    ($category1, $category2, $category3) = ($COLUMN->{"category1"},$COLUMN->{"category2"},$COLUMN->{"category3"});
    
    $tmpCategory1 = $tmpColumn->{"category1"} || "";
    $tmpCategory2 = $tmpColumn->{"category2"} || "";
    
    if($tmpCategory1 ne "" && $category1 ne $tmpCategory1 && $tmpColumn->{"columns"} > 1){
      $sheet->merge_range($headerRow, ($col-$mergeCount1-1), $headerRow, ($col-1), $tmpCategory1, $HEADER_STYLES->{$tmpColumn->{"merge_style"}}) if($mergeCount1 > 0);
      $sheet->write($headerRow, ($col-1), $tmpCategory1, $HEADER_STYLES->{$tmpColumn->{"style"}}) if($mergeCount1 == 0);
      $mergeCount1 = 0;
    }
    if($tmpCategory2 ne "" && $category2 ne $tmpCategory2 && $tmpColumn->{"columns"} > 2){
      $sheet->merge_range(($headerRow+1), ($col-$mergeCount2-1), ($headerRow+1), ($col-1), $tmpCategory2, $HEADER_STYLES->{$tmpColumn->{"merge_style"}}) if($mergeCount2 > 0);
      $sheet->write(($headerRow+1), ($col-1), $tmpCategory2, $HEADER_STYLES->{$tmpColumn->{"style"}}) if($mergeCount2 == 0);
      $mergeCount2 = 0;
    }
    
    my $columnRange = $COLUMN->{"columns"};
    if($columnRange == 1){
      $sheet->merge_range($headerRow, $col, ($headerRow+2), $col, $category1, $HEADER_STYLES->{$COLUMN->{"merge_style"}} );
      ($mergeCount1, $mergeCount2) = (0,0);
    } elsif ($columnRange == 2){
      $sheet->merge_range(($headerRow+1), $col, ($headerRow+2), $col, $category2, $HEADER_STYLES->{$COLUMN->{"merge_style"}});
      $mergeCount2 = 0;
    } else {
      $sheet->write(($headerRow+2), $col, $category3, $HEADER_STYLES->{$COLUMN->{"style"}});
    }
    
    my $width = $COLUMN->{"width"};
    $sheet->set_column( $col, $col, $width );
    
    $mergeCount1++ if($tmpCategory1 ne "" && $category1 ne "" && $category1 eq $tmpCategory1);
    $mergeCount2++ if($tmpCategory2 ne "" && $category2 ne "" && $category2 eq $tmpCategory2);
    
    $col++;
    $tmpColumn = $COLUMN;

  }
  if(defined($tmpColumn->{"category1"}) && $tmpColumn->{"category1"} ne "" && $tmpColumn->{"columns"} > 1){
    $sheet->merge_range($headerRow, ($col-$mergeCount1-1), $headerRow, ($col-1), $tmpColumn->{"category1"}, $HEADER_STYLES->{$tmpColumn->{"merge_style"}}) if($mergeCount1 > 0);
    $sheet->write($headerRow, ($col-1), $tmpColumn->{"category1"}, $HEADER_STYLES->{$tmpColumn->{"style"}}) if($mergeCount1 == 0);
  }
  if(defined($tmpColumn->{"category2"}) && $tmpColumn->{"category2"} ne "" && $tmpColumn->{"columns"} > 2){
    $sheet->merge_range(($headerRow+1), ($col-$mergeCount2-1), ($headerRow+1), ($col-1), $tmpColumn->{"category2"}, $HEADER_STYLES->{$tmpColumn->{"merge_style"}}) if($mergeCount2 > 0);
    $sheet->write(($headerRow+1), ($col-1), $tmpColumn->{"category2"}, $HEADER_STYLES->{$tmpColumn->{"style"}}) if($mergeCount2 == 0);
  }
  #=============
  # make data
  #=============
  my $dataRow = 4;
  my $col_ex = 0;

  foreach my $voyage_rec ($voyage_list->{result_data}) {

    foreach my $hash_rec (@{$voyage_rec}){

      $sheet->set_row( $dataRow, 22 );
      foreach my $column_rec (@outputItems){

        $sheet->write_string( $dataRow, $col_ex, $hash_rec->{$column_rec->{key}} , $STYLE_DAILY_VALUE);
        $col_ex++;
      }
     $dataRow++;
     $col_ex = 0;
    }
  }

  &downloadExcel($shipname, $target_id);
  $workbook->close;

  };
  if( $@ ){
    my $log_msg = 'System error (' . $@ . ' )\n';
    my $err_msg = 'Problem Occurred. Try later.';
    &procResult($cgi, $log, $log_msg, $err_msg, 'NG', 'true', 'true', '');
    return;
  }
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


# =========================================
# Downloading Excel file.Excelをダウンロードする。
# =========================================
sub downloadExcel {
  $log -> Info("====== Start Downloading Excel =====\n");
  my $shipname = shift || "";
  my $target_id = shift || "";
  my $proc_time = time;
  my $local_time = strftime("%Y%m%d_%H%M", localtime($proc_time));
  my $filename = sprintf("%s_%s_%s.xls", $target_id, $shipname, $local_time);
  $filename =~ s/ //g;
  print $cgi->header( -expires => "now", -charset => "utf-8",
                    -content_type => "application/octet-stream",
                    -content_disposition => "attachment; filename=$filename" );
  $log -> Info("=== End Downloading Excel ====\n");  
}
#==========================================================
# Function for get voyage list
#==========================================================
sub column_loading {
#  my $path = sprintf("%s/def_summarize_voyage.json", $EsmConf::DATA_FORMAT_DEF);
  my $path = sprintf("%s/def_emission_per_voyage_items.json", $EsmConf::DATA_FORMAT_DEF);
  my $column_list = {};
  if(-f $path){
    $column_list = &fetchingFiles($path);
  }
  return $column_list;
}

#==========================================================
# Function for get voyage list
#==========================================================
sub getVoyageList {
  my ($client_code, $imo_num, $downloadKey, $target_id) = @_;
  my $path = sprintf("%s/%s/%s/%s_%s.json", $EsmConfigWeb::ESM_TMP_DIR, $client_code, $imo_num, $target_id,$downloadKey);
  my $voyage_list = {};
  if(-f $path){
    $voyage_list = &fetchingFiles($path);
  }
  return $voyage_list;
}
#==========================================================
# Function for fetching files
#==========================================================
sub fetchingFiles {
  my $path = shift;
  # ファイルのload
  my $result = undef;
  $log->Info("load $path\n");
  EsmLib::LoadJson($path, \$result);
  $log->Info("load finish.\n");
  return $result;
}

###############################
# return result
###############################
sub procResult {
  my ( $cgi, $log, $log_msg, $err_msg, $status, $alert, $flag, $url ) = @_;
    if($log_msg){
      $log->Error($log_msg."\n");
    }
    my $result = {
      message=>$err_msg,  
      result=>$status,
      alert=>$alert,
      redirect_flag=>$flag,
      redirect_url=>$url
    };
    &returnResult($cgi, $result);
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
