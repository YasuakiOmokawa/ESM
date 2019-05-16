package EsmLib;

use strict;
use Carp;
umask 000;

BEGIN{
  use Exporter;
  use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  @ISA = qw(Exporter);
  @EXPORT_OK = qw();
  $ENV{TZ} = "UTC";
};

use CGI qw(header);
use JSON;
use LWP::UserAgent;
use HTTP::Lite;
use Time::Local;
use XML::Simple;
use POSIX qw(strftime);
use File::Basename qw(dirname basename);
use File::Path qw(mkpath);
use Data::Dumper;
use Cwd qw(abs_path);
use vars qw($MY_NAME $MY_DIR);

BEGIN {
  $MY_DIR = dirname(__FILE__);
  $MY_NAME = basename(__FILE__);
}

use EsmConf;
use EsmConfigWeb;

my $UTEST = 0;
my $UTEST_OPTION = {};

my $PI = atan2 (1, 1) * 4;

my %DATE = qw(JAN 1 FEB 2 MAR 3 APR 4 MAY 5 JUN 6 JUL 7 AUG 8 SEP 9 OCT 10 NOV 11 DEC 12);

sub LoadJson {
  my ($path, $data) = @_;

  return 0 unless ( -f $path );

  open( my $in, $path );
  my $txt = do{ local $/; <$in> };
  close( $in );

  eval{
    $$data = decode_json( $txt );
  };
  if($@){
    croak("$path is faild.\n$@\n".Carp::longmess."\n");
  }
  return 1;
}

sub SaveJson {
  my ($path, $data, $pretty) = @_;

  my $dirname = dirname($path);
  my $basename = basename($path);
  mkpath( $dirname ) unless ( -d $dirname );

  my $json = undef;
  eval{
    $json = to_json( $data, { utf8=>1, pretty=>$pretty } );
  };
  if($@){
    croak("to_json error. path=$path\n$@\n".Carp::longmess."\n");
  }

  my $tmpfile = "$dirname/$$.$basename.$$";
  eval{
    open( my $in, ">$tmpfile" );
    print $in $json;
    close( $in );
  };
  if($@){
    croak("save error. path=$path\n$@\n".Carp::longmess."\n");
  }
  return rename( $tmpfile, $path );
}

sub LoadCsv {
  my ($path, $data) = @_;

  croak ("not found file. $path\n") unless( -f $path );

  eval{
    open (my $in, $path);
    my $text = do { local $/; <$in> };
    close ($in);

    foreach my $line ( split(/\n/, $text) ){
      next if( $line =~ /^\s*#/ );
      my $vals = ParseCsv( $line );
      push(@$data, $vals);
    }
  };
  if($@){
    croak ( "loadCsv($path) error.". $@ . "\n" . Carp::longmess . "\n" );
  }
}

sub ParseCsv {
  my $text = shift;
  my @new = ();
  push(@new, $+) while $text =~ m{
    # grouping for phrase in quate.
    "([^\"\\]*(?:\\.[^\"\\]*)*)",?
      |  ([^,]+),?
      | ,
    }gx;
    push(@new, undef) if substr($text, -1, 1) eq ',';
  return \@new;
}

sub ReadDir {
  my ($path, $aryRef) = @_;
  opendir DIR, "$path" or die $!;
  @$aryRef = grep {/^[^\.]/} readdir DIR;
  closedir DIR;
}

sub EpochToStr {
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
    croak( "epochtostr($t) ". $@ . "\n" . Carp::longmess . "\n" );
  }

  my $s = strftime($fmt, $sec, $min, $hour, $mday, $mon, $year);
  return $s;
}

sub EpochToLTStr {
  my $t   = shift;
  my $tz  = shift;
  my $fmt = shift || "%Y-%m-%dT%H:%M:%S";
  my ($sec, $min, $hour, $mday, $mon, $year);

  if( $t eq "" || int($t) == 0 ){
    return "";
  }

  eval{
    my $tmptz = $ENV{"TZ"};
    $ENV{"TZ"} = $tz;
    $t = timegm(localtime( $t ));
    $ENV{"TZ"} = $tmptz;
    ($sec,$min,$hour,$mday,$mon,$year) = gmtime( $t );
  };
  if($@){
    croak( "epochtostr($t) ". $@ . "\n" . Carp::longmess . "\n" );
  }

  my $s = strftime($fmt, $sec, $min, $hour, $mday, $mon, $year);
  return $s;
}

sub StrToEpoch {
  my $s = shift;
  my ($Y, $m, $d, $H, $M, $S) = split(/[\/\-\s:TZz]/, $s);
  my $t = 0;

  return 0 if( $s eq "" );

  $m = uc($m);
  $m = int($DATE{$m}) if( defined $DATE{$m} );

  eval{
    $t = timegm( $S, $M, $H, $d, $m-1, $Y-1900);
  };
  if($@){
    croak( "strtoepoch($s) ". $@ . "\n" . Carp::longmess . "\n" );
  }
  return $t;
}

sub LTStrToEpoch {
  my $s  = shift;
  my $tz = shift;
  my ($Y, $m, $d, $H, $M, $S) = split(/[\/\-\s:TZz]/, $s);
  my $t = 0;

  return 0 if( $s eq "" );

  $m = uc($m);
  $m = int($DATE{$m}) if( defined $DATE{$m} );

  eval{
    my $tmptz = $ENV{"TZ"};
    $ENV{"TZ"} = $tz;
    $t = timelocal( $S, $M, $H, $d, $m-1, $Y-1900);
    $ENV{"TZ"} = $tmptz;
  };
  if($@){
    croak( "strtoepoch($s) ". $@ . "\n" . Carp::longmess . "\n" );
  }
  return $t;
}

sub HmsToTime {
  my $s = shift;

  my ($flagedH, $M, $S) = split(/:/, $s);

  $flagedH =~ /([-+]?)(\d+)/;

  my ($flag, $H) = ($1, $2);

  my $t = ($H ne "" ? int($H) : 0 ) * 3600
        + ($M ne "" ? int($M) : 0 ) * 60
        + ($S ne "" ? int($S) : 0 );

  $t *= -1 if( $flag eq "-" );
  return $t;
}

sub Round {
  my ($v, $fig) = @_;
  return "" if ( $v eq "" );
  return ( int( $v * (10 ** $fig) + ($v<0?-0.5:0.5) ) / (10 ** $fig) );
}

sub IsString {
  my ($n) = @_;
  return ($n =~ m/^[- _:,A-Za-z0-9\.]*$/) ? 1 : 0;
}

sub IsInteger {
  my ($n) = @_;
  return 1 if ($n =~ m/^[\s]*$/);
  return ($n =~ m/^\s*\-?\d+\s*$/) ? 1 : 0;
}

sub IsNumber {
  my ($n) = @_;
  return 1 if ($n =~ m/^[\s]*$/);
  return ($n =~ m/^\s*\-?\d+(\.?\d+)*\s*$/) ? 1 : 0;
}

sub IsTime {
  my ($n) = @_;
  my $result = ( $n =~ m/^\s*(\d\d\d\d)\-(\d\d)-(\d\d).(\d\d):(\d\d):(\d\d)\s*$/ ) ? 1 : 0;

  my ($YYYY,$mm,$dd,$HH,$MM,$SS) = (
    scalar($1?$1:0),
    scalar($2?$2:0),
    scalar($3?$3:0),
    scalar($4?$4:0),
    scalar($5?$5:0),
    scalar($6?$6:0),
  );

  eval {
    timegm ($SS, $MM, $HH, $dd, $mm-1, $YYYY-1900);
  };
  if ($@) {
    return 0;
  }

  $result = 0 if ($YYYY < 1900 || 2030 < $YYYY);
  $result = 0 if ($mm < 1 || 12 < $mm);
  $result = 0 if ($dd < 1 || 31 < $dd);
  $result = 0 if ($HH < 0 || 23 < $HH);
  $result = 0 if ($MM < 0 || 59 < $MM);
  $result = 0 if ($SS < 0 || 59 < $SS);
  return $result;
}

sub InAry {
  my ($tgtVal, $array) = @_;

  foreach my $elem ( @$array ) {
    return 1 if $tgtVal eq $elem;
  }
  return 0;
}

sub SplitByComma {
  my ($num, $fig) = @_;
  my $splNum = "";
  $num = Round($num, $fig) if (defined $fig);
  my ($integer, $decimal) = split(/\./, $num);
  $decimal = $decimal ? ".$decimal" : "";
  while( 3 <= length($integer) ) {
    my ($before, $after) = ($1, $2) if ($integer =~ /(\d*)(\d\d\d)$/);
    $splNum = $splNum ? sprintf("%s,%s", $after, $splNum) : $after;
    $integer = $before || 0;
  }
  return $integer ? "$integer,$splNum"."$decimal" : "$splNum"."$decimal";
}

sub OutPutOK {
  my ($data, $callback) = @_;

  print header (
    -expires      => "now",
    -charset      => "utf-8",
    -content_type => (defined $callback) ? "application/javascript" : "application/json"
  );
  print "$callback(\n" if $callback;
  print "{\"result\":\"OK\", \"data\":$data}\n";
  print ")\n" if $callback;
}

sub OutPutNG {
  my $msg = shift || "";
  $msg = ClearText($msg);
  my $callback = $_[1];
  print header (
    -expires => "now",
    -charset => "utf-8",
    -content_type => (defined $callback) ? "application/javascript" : "application/json"
  );
  print "$callback(\n" if $callback;
  print qq/{"result":"NG", "msg":"$msg"}\n/;
  print ")\n" if $callback;
}

sub ClearText {
  my $text = shift;
  $text =~ s/\n//g;
  $text =~ s/\r//g;
  $text =~ s/\"/\\\"/g;
  return $text;
}

sub Beaufort {
  my $knot = shift;
  my $bf   = "";
  return "" if ($knot eq "");

  if ( $knot < 1 ) {
    $bf = 0;
  } elsif ( 1  <= $knot && $knot < 4 ) {
    $bf = 1;
  } elsif ( 4  <= $knot && $knot < 7 ) {
    $bf = 2;
  } elsif ( 7  <= $knot && $knot < 11 ) {
    $bf = 3;
  } elsif ( 11 <= $knot && $knot < 17 ) {
    $bf = 4;
  } elsif ( 17 <= $knot && $knot < 22 ) {
    $bf = 5;
  } elsif ( 22 <= $knot && $knot < 28 ) {
    $bf = 6;
  } elsif ( 28 <= $knot && $knot < 34 ) {
    $bf = 7;
  } elsif ( 34 <= $knot && $knot < 41 ) {
    $bf = 8;
  } elsif ( 41 <= $knot && $knot < 48 ) {
    $bf = 9;
  } elsif ( 48 <= $knot && $knot < 56 ) {
    $bf = 10;
  } elsif ( 56 <= $knot && $knot < 64 ) {
    $bf = 11;
  } elsif ( 64 <= $knot ) {
    $bf = 12;
  }
  return $bf;
}

sub ConvWaveHtToDss {
  my $wave = shift;
  my $dss = "";
  return "" if ($wave eq "");

  if (0 <= $wave && $wave < 0.16) {
    $dss = 1;
  } elsif (0.16 <= $wave && $wave < 0.80) {
    $dss = 2;
  } elsif (0.80 <= $wave && $wave < 2.00) {
    $dss = 3;
  } elsif (2.00 <= $wave && $wave < 4.00) {
    $dss = 4;
  } elsif (4.00 <= $wave && $wave < 6.40) {
    $dss = 5;
  } elsif (6.40 <= $wave && $wave < 9.60) {
    $dss = 6;
  } elsif (9.60 <= $wave && $wave < 14.4) {
    $dss = 7;
  } elsif (14.4 <= $wave && $wave < 22.4) {
    $dss = 8;
  } elsif (24.4 <= $wave) {
    $dss = 9;
  }
  return $dss;
}

sub MinToLatLon {
  my $val = shift;
  my $flg = shift;
  my $dir = "";
  return "" if $val eq "";

  if ($val >= 0) {
    $dir = $flg eq "lon" ? "E" : "N";
  } else {
    $dir = $flg eq "lon" ? "W" : "S";
  }
  $val = abs($val);
  $val /= 60;
  my $deg = int($val);
  my $min = sprintf("%.2f", ($val - $deg));
  $min *= 0.6;
  $min *= 100;
  $min += 0.5;

  my $position = sprintf("%02d-%02d%s", $deg, $min, $dir);
  return $position;
}

# Convert DMM('mmmm.m') to DMS(DDD-mm.m{EW|NS})
sub MinToLatLon_sec {
  my $val = shift;
  my $flg = shift;
  my $dir = "";
  return "" if $val eq "";

  if ($val >= 0) {
    $dir = $flg eq "lon" ? "E" : "N";
  } else {
    $dir = $flg eq "lon" ? "W" : "S";
  }

  # Deg
  my $wk = int(abs($val));
  $wk /= 60;
  my $deg = int($wk);

  # Min
  my $min = sprintf("%.2f", ($wk - $deg));
  $min *= 0.6;
  $min *= 100;
  $min += 0.5;

  # Sec
  $wk = abs($val);
  my $sec = $wk - int($wk);
  $sec *= 10;
  $sec += 0.5;
  $sec = int($sec);

  my $position = undef;
  if ($sec == 0){
    $position = sprintf("%02d-%02d%s", $deg, $min, $dir);
  } else {
    $position = sprintf("%02d-%02d.%1d%s", $deg, $min, $sec, $dir);
  }

  return $position;
}

sub DegToVec {
  my $val = shift;
  return "" if $val eq "";

  my @dir = qw(N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW);

  $val /= 22.5;
  $val = 0 if $val == 16;

  my $dir = $dir[$val];
  return $dir;
}

sub DegToMin {
  my ($deg) = @_;
  if ($deg =~ m/^\s*(\d+)[^\d]+(\d+)([NESW]\s*)/i) {
    my $s = uc $3;
    my $m = $1 * 60 + $2;
    $m *= -1 if ($s eq "S" || $s eq "W");
    return $m;
  } else {
    return undef;
  }
}

sub ConvWindDir {
  my $val = shift;
  return "" if $val eq "";

  my @dir = qw(N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW);

  $val /= 22.5;
  $val = 0 if $val == 16;

  my $dir = $dir[$val];
  return $dir;
}

sub KmToKnot {
  my ($km, $rack) = @_;
  $rack = 9999 unless (defined $rack);
  return undef if (! defined $km || $km eq "" || $km >= $rack);
  return $km / 0.5144;
}

sub VecToScalar {
  my ($u, $v, $rack) = @_;

  $rack = 9999 unless (defined $rack);
  return undef if (! defined $u || $u eq "" || $u >= $rack);
  return undef if (! defined $v || $v eq "" || $v >= $rack);
  return (sqrt( $u ** 2 + $v ** 2 ));
}

sub VecToDeg {
  my ($u, $v, $isCurrent, $rack) = @_;

  $rack = 9999 unless (defined $rack);
  return undef if (! defined $u || $u eq "" || $u >= $rack);
  return undef if (! defined $v || $v eq "" || $v >= $rack);

  my $r = (atan2( $u, $v ) * 180 / $PI);
  if ($isCurrent) {
    return ($r + 360.0) % 360;
  } else {
    my $dir = (($r + 360.0) % 360) + 180;
    return 360 <= $dir ? $dir - 360 : $dir;
  }
}

sub VecToFactor {
  my ($u, $v, $h, $rack) = @_; # h is heading

  $rack = 9999 unless (defined $rack);
  return undef if (! defined $u || $u eq "" || $u >= $rack);
  return undef if (! defined $v || $v eq "" || $v >= $rack);
  return undef if (! defined $h || $h eq "" || $h >= $rack);

  my $h_rad = ($h / 180.0) * $PI;
  my $h_cos = cos ($h_rad);
  my $h_sin = sin ($h_rad);

  return ($v * $h_cos + $u * $h_sin);
}

sub CalcMinus {
  my ($item, $data, $isFuel) = @_;

  my @items = @$item;  # $items[0] - $items[1] - $items[2] - $items[n] ...

  my $val = $data->{$items[0]};
  if ($isFuel) {
    $val = 0 if $val eq "";
  } else {
    return "" if ($val eq "" or $#items <= 0);
  }
  my $inValid = 0;
  for (my $i=1; $i<=$#items; $i++) {
    $val -= $data->{$items[$i]} if ($data->{$items[$i]});
    $inValid = 1 if ($data->{$items[$i]} eq "" and !$isFuel);
  }
  if ($isFuel) {
    $val = !$val ? 0 : Round($val, 2);
  } else {
    $val = $inValid ? "" : Round($val, 1);
  }
  return $val;
}

sub CalcDevide {
  my $item = shift;
  my $data = shift;
  my $log = shift;

  my @items = @$item;
  my $val = $data->{$items[0]};
  return "" if ($val eq "" or $val == 0);
  eval {
    for (my $i=1; $i<=$#items; $i++) {
      $val /= $data->{$items[$i]};
    }
  };
  return $@ ? "" : Round($val, 2);
}

sub CalcRelativeDir {
  my ($winddir, $heading) = @_;
  my $relative = "";
  return "" if( $heading eq "" or $winddir eq "" );

  my $dir = abs($winddir - $heading);

  if ( (0 <= $dir && $dir <= 22.5) || (337.5 <= $dir && $dir <= 360) ) {
    $relative = "HD";
  } elsif ( (22.5  <  $dir && $dir <  67.5)  || (292.5 <  $dir && $dir < 337.5)  ) {
    $relative = "BW";
  } elsif ( (67.5  <= $dir && $dir <= 112.5) || (247.5 <= $dir && $dir <= 292.5) ) {
    $relative = "BM";
  } elsif ( (112.5 <  $dir && $dir < 157.5)  || (202.5 <  $dir && $dir < 247.5) ) {
    $relative = "QF";
  } elsif ( 157.5 <= $dir && $dir <= 202.5 ) {
    $relative = "FL";
  }
  return $relative;
}

sub CalcFuelEfficiency {
  my $data = shift;
  my $val;

  #  Actual vs. Ordered(%)
  #  = [(2) - (1)] / (1)
  # (1) Ordered Speed * 24 / Ordered ME FOC
  # (2) Actual Performance Speed * 24 / Reported 24h ME FOC)
  #
  #    * Actual Performance Speed: Ave. Speed - Wxfactor - Currfactor
  #    * Reported 24h ME FOC     : CONS HSFO * 24 / SteamingTime

  my $steamingTime = $data->{steaming_hours} / 60; # min => hour
  return "" unless ($data->{steaming_hours} and $data->{daily_perf_speed} and $data->{cons_me_hsfo} and $data->{ordered_speed} and $data->{ordered_cons_fo});

  eval {
    my $actPerfSpd = $data->{daily_perf_speed} * 24;
    my $rep24Foc   = ($data->{cons_me_hsfo} * 24 / $steamingTime);
    my $no1 = $data->{ordered_speed} * 24 / $data->{ordered_cons_fo};
    my $no2 = $actPerfSpd / $rep24Foc;
    $val = ($no2 - $no1) / $no1 * 100;
  };
  if ($@) {
    return "";
  } else {
    return Round($val, 2);
  }
}

sub GetRefTimeHash {
  my $dirPath = shift;
  my %result = ();

  my @refTimeAry = `grep -r '"ref_time"' $dirPath`;
  return \%result if !@refTimeAry;

  foreach my $resultText (@refTimeAry) {
    next if $resultText =~ /latest/;
    my ($filePath, $refTime) = ($1, $2) if ($resultText =~ /(.*?):\s*"ref_time"\s*:\s*"(.*?)",/);
    $result{ StrToEpoch($refTime) } = $filePath;
  }
  return \%result;
}

sub CalcWxFactor {
  my ($param, $log) = @_;
  my $wxFactor;
  return unless $param;
  $log->Info("*fetchWxFactor:: wnishipnum=$param->{wni_ship_num}, generic=$param->{generic}, inrpm=$param->{inrpm}\n");
  my %param = (
    inrpm        => $param->{inrpm},
    generic      => $param->{generic},
    wni_ship_num => $param->{wni_ship_num}
  );
  return $wxFactor if ($param->{inrpm} eq "" || $param->{wnishipnum});

  my $http = new HTTP::Lite;
  $http->prepare_post( \%param );
  my $req = $http->request($EsmConf::IF_FETCH_GOOD_SPD);

  if( $req ne "200" ){
    $log->Error("Request failed (calcGoodWxSpeed)\n");
    return "";
  }
  my $result = decode_json($http->body);
  if ($result->{Result} eq "NG" || !$result->{Content}{RPM}{$param->{inrpm}}) {
    $log->Warn( "Cannot get WxFactor\n" );
    return "";
  }
  my $goodSpd       = $result->{Content}{RPM}{$param->{inrpm}}{Speed};
  my $aveSpd        = $param->{speed};
  my $currentFactor = $param->{curFactor};
  if ( ($aveSpd eq "" || !$aveSpd) or ($goodSpd eq "" || !$goodSpd) or ($currentFactor eq "" || !$currentFactor) ) {
    $wxFactor = "";
    $log->Info("WxFactor($wxFactor) = \"\" (\$aveSpd: $aveSpd, \$goodSpd: $goodSpd, \$currentFactor: $currentFactor)\n");
  } else {
    $wxFactor = $aveSpd - $goodSpd - $currentFactor;
    $wxFactor = Round($wxFactor, 1);
    $log->Info("WxFactor($wxFactor) = aveSpeed($aveSpd) - goodSpd($goodSpd) - currFactor($currentFactor)\n");
  }
  return $wxFactor;
}

sub GetShipInfo {
  my ($imo_num, $log) = @_;

  my $HTTP = new HTTP::Lite;
  my $url = sprintf("%s?imo_num=%s", $EsmConf::IF_FETCH_SHIP_INFO, $imo_num);
  my $req = $HTTP->request($url);

  unless($req =~ /^2\d\d/) {
    $log->Error("Unable to access VPDB\n");
    return undef;
  }
  my $reqBody = undef;
  my $XML = new XML::Simple;
  eval{ $reqBody = XMLin($HTTP->body); };
  return undef unless($reqBody);
  my $return = {
    "wni_ship_num" => $reqBody->{wni_ship_info}{wni_ship_num},
    "imo_num"      => $reqBody->{wni_ship_info}{imo_num},
    "ship_name"    => $reqBody->{wni_ship_info}{ship_name},
    "callsign"     => $reqBody->{wni_ship_info}{callsign},
  };
  return $return;
}

sub getClientSection {
  my ($client, $section) = @_;
  return $client unless($section && $section ne "");

  my @sections = split(/\./, $section);
  if($sections[0] ne ""){
    return $client.".".$sections[0];
  } else {
    return $client;
  }
}

sub GetNextDailyDataPath {
  my ($refTime, $wnishipnum, $clientsection) = @_;
  return undef unless $wnishipnum;
  my $dailyDir  = sprintf("%s/%s/%s", $EsmConf::DAILY_DATA_DIR, $clientsection, $wnishipnum);
  return undef unless -e $dailyDir;
  my $refTimeEpoch = StrToEpoch($refTime);

  my $nextRefTimes = GetRefTimeHash($dailyDir);

  my $nextDailyDataPath = undef;
  foreach my $nextRefTimeEpoch (sort {$a <=> $b} keys %{$nextRefTimes}) {
    next if ($nextRefTimeEpoch <= $refTimeEpoch);

    if(($nextRefTimeEpoch - $refTimeEpoch) < $EsmConf::PREV_REPORT_DIFF){
      $nextDailyDataPath = $nextRefTimes->{$nextRefTimeEpoch};
    }
    last;
  }
  return $nextDailyDataPath;
}

sub GetPrevDailyData {
  my ($refTime, $wnishipnum, $clientsection) = @_;
  return undef unless $wnishipnum;
  my ($year, $month) = GetMonthFromRefTime($refTime);
  my $dailyDataPath = sprintf("%s/%s/%s/%04d/%02d.json", $EsmConf::DAILY_DATA_DIR, $clientsection, $wnishipnum, $year, $month);
  my ($dailyDataNode, $prevDataNode) = (undef, undef);
  my $refTimeEpoch = StrToEpoch($refTime);

  if( -f $dailyDataPath){
    LoadJson($dailyDataPath, \$dailyDataNode);
    my $firstElememtRefTime = StrToEpoch(@{$dailyDataNode->{body}}[0]->{ref_time});
    if($refTimeEpoch <= $firstElememtRefTime){
      ## if target time less than first element, then previous report exist another file.
      $prevDataNode = GetPrevDailyDataFromOhterFile($refTimeEpoch, $wnishipnum, $clientsection);
      return undef unless $prevDataNode;
      $prevDataNode->{filePath} = $dailyDataPath;
    } else {
      ## previous report exist in same file.
      my $len = scalar(@{$dailyDataNode->{body}});
      for(my $i = 1; $i < $len; $i++){
        my $bodyNode = @{$dailyDataNode->{body}}[$i];
        next unless($refTimeEpoch == StrToEpoch($bodyNode->{ref_time}));
        $prevDataNode = @{$dailyDataNode->{body}}[$i-1];
        last;
      }
      # previous ref_time must less than 30day difference.
      return undef unless(($refTimeEpoch - StrToEpoch($prevDataNode->{ref_time})) < $EsmConf::PREV_REPORT_DIFF);
    }
  } else {
    $prevDataNode = GetPrevDailyDataFromOhterFile($refTimeEpoch, $wnishipnum, $clientsection);
  }
  return $prevDataNode;
}

sub GetPrevDailyDataFromOhterFile {
  my ($refTime, $wnishipnum, $clientsection) = @_;
  return undef unless $wnishipnum;
  my $dailyDir  = sprintf("%s/%s/%s", $EsmConf::DAILY_DATA_DIR, $clientsection, $wnishipnum);
  return undef unless -e $dailyDir;
  my $prevRefTimes = GetRefTimeHash($dailyDir);
  # prevRefTimes => {ref_time(epoch) => path}; (all file's reftime)
  my $targetFilePath = undef;
  foreach my $prevRefTime (sort {$b <=> $a} keys %{$prevRefTimes}) {
    next if ($refTime <= $prevRefTime); ## ignore future ref_time
    # first not the future ref_time is previous
    # previous ref_time must less than 30day difference.
    if(($refTime - $prevRefTime) < $EsmConf::PREV_REPORT_DIFF){
      $targetFilePath = $prevRefTimes->{$prevRefTime};
    } else {
      $targetFilePath = undef;
    }
    last;
  }
  return undef unless $targetFilePath;

  my $prev = undef;
  LoadJson($targetFilePath, \$prev);
  my $prevDataNode = pop @{$prev->{body}}; # outher files last element is previous
  return $prevDataNode;
}

sub GetMonthFromRefTime {
  my $refTime = shift;
  my $refEpoch = StrToEpoch($refTime);
  my $yearMonth = strftime("%Y-%m", localtime($refEpoch));
  my ($year, $month) = split("-", $yearMonth);
  return ($year, $month);
}

sub ConvSpeedToRPM {
  my ($simParam, $shipInfo, $speed) = @_;

  # ----- preapre parameter
  my %param = (
    ShipInfo => {
      SummerDraft => $shipInfo->{summer_draft},
      ship_type   => $shipInfo->{ship_type}
    },
    LegInfo => {
      DraftFore => $shipInfo->{draft_fore},
      DraftAft  => $shipInfo->{draft_aft}
    },
    ContentInfo => {
      Speed => [ $speed ]
    }
  );
  my @TGT_SIM_PARAM = qw(spd_a_const spd_R_draft spd_a_sight spd_a_period spd_a_windL spd_a_wind0 spd_a_wind1 spd_a_wind2);
  foreach my $key (keys %$simParam) {
    next unless (InAry($key, \@TGT_SIM_PARAM));
    $param{ParameterInfo}{$key} = ref($simParam->{$key}) eq "HASH" ? "" : $simParam->{$key};
  }

  my $json = to_json( \%param );
  my $HTTP = new HTTP::Lite;
  $HTTP->prepare_post({inputjson => $json});
  my $req = $HTTP->request($EsmConf::IF_FETCH_GOOD_SPD);
  unless($req eq "200") {
    return "";
  }
  my $rpm;
  my $resultObj = decode_json($HTTP->body);
  if ($resultObj->{Result} eq "NG") {
    my $params = {
      "wni_ship_num" => $shipInfo->{wnishipnum},
      "generic"      => "true",
      "inspeed"      => $speed
    };
    $rpm = ConvSpeedToRPMGeneric($params);
  }else {
    $rpm = $resultObj->{Content}{Speed}{$speed}{RPM};
  }
  return $rpm;
}
sub ConvSpeedToRPMGeneric {
  my ($param) = @_;
  my $rpm;
  return unless $param;
  my %param = (
    inspeed      => $param->{inspeed},
    generic      => $param->{generic},
    wni_ship_num => $param->{wni_ship_num}
  );
  return $rpm if ($param->{inspeed} eq "" || $param->{wnishipnum});

  my $http = new HTTP::Lite;
  $http->prepare_post( \%param );
  my $req = $http->request($EsmConf::IF_FETCH_GOOD_SPD);

  if( $req ne "200" ){
    return "";
  }
  my $result = decode_json($http->body);
  if ($result->{Result} eq "NG" || !$result->{Content}{Speed}{$param->{inspeed}}) {
    return "";
  }
  $rpm = $result->{Content}{Speed}{$param->{inspeed}}{RPM};
  return $rpm;
}
sub IsServiceClient {
  #1
  my $client = shift;
  #2.1
  my $customerDataPath = $EsmConfigWeb::ADMIN_CUSTOMER_DATA_DIR;
  my @filePath = `find $customerDataPath -follow -name '*.json'`;

  foreach my $targetFilePath (@filePath) {
    #2.1.1
    chomp($targetFilePath);
    my $fileObj = undef;
    LoadJson($targetFilePath, \$fileObj);

    #2.1.2
    my $customerClient = $fileObj->{client_code};

    if($customerClient =~ /0+$/) {
      $customerClient = "$`";
    }
    #2.1.3
    return 1 if($client eq $customerClient);
  }
  #3
  return 0;
}
## EditESM-03 RMS高速化エラーマージに利用
## 2018-06-13 追加
sub UpdateInvalid {
  my $dailydata = shift;
  my $edit_type = shift;
  return undef if $edit_type eq "update";
  my $invalid = $edit_type eq "delete" ? "true" : "false";
  $dailydata->{"report_info"}->{"invalid"} = $invalid;
  $dailydata->{"invalid"} = $invalid;
}
## EditESM-03 これもRMS高速化エラーマージに利用
## TmaxLib.pm から追加 (大文字始まりですが、TmaxLib.pmと同じです)
sub IsInvalidReport{
  my $data = shift;
  if(defined($data->{"report_info"}->{"invalid"}) && ($data->{"report_info"}->{"invalid"} eq "true" || $data->{"report_info"}->{"invalid"} == 1)){
    return 1;
  }
  if(defined($data->{"invalid"}) && ($data->{"invalid"} eq "true" || $data->{"invalid"} == 1)){
    return 1;
  }
  return 0;
}

sub getParentId {
  my $client = shift;
  my $parentId = undef;
  my $customerDataPath = $EsmConfigWeb::ADMIN_CUSTOMER_DATA_DIR;

  my @filePath = `find $customerDataPath -follow -name '*.json'`;
  foreach my $targetFilePath (@filePath) {
    chomp($targetFilePath);
    my $fileObj = undef;
    LoadJson($targetFilePath, \$fileObj);

    my $customerClient = $fileObj->{client_code};

    if($customerClient =~ /0+$/) {
      $customerClient = "$`";
    }
    if($client eq $customerClient){
      $parentId = basename($targetFilePath, (".json"));
      last;
    }
  }
  return $parentId;
}
#####################################################
# Delivering Libraries
#####################################################

#####################################################
# evacuation to spool directories
#####################################################

sub evacuateAmfileToSpool{
  my ( $amfile , $hostnames , $log ) = @_;

  my $return_value = 0;

  $log->Info( "  evacuateAmfileToSpool() start [amfile:%s][destinations:%s]\n",
              $amfile,
              ( ( ref( $hostnames ) eq 'ARRAY' ) ? join( ',' , @$hostnames ) : 'argument type error' )
      ) if $log;
  if ( ! -e $amfile || ref( $hostnames ) ne 'ARRAY' ){
    $log->Info( "   argument Error [amfile check:%s][hostname reference:%s]\n",
                ( ( -e $amfile )? 'OK' : 'NG' ),
                ref( $hostnames ) // 'undefined' ) if $log;
  }else{
    foreach my $hostname( @{ $hostnames } ){
      my $spool_dir = $EsmConfigWeb::DGC_EDIT_DELETE_EVAC_DIR . "/$hostname";
      mkdir $spool_dir if ! -d $spool_dir;
      $log->Info( "  spooldir : %s\n" , $spool_dir ) if $log;
      my $spool_path = &getSequentialFilePath( $spool_dir , $log );
      if ( ! $spool_path ){
        $log->Info( "  error: not returned valid path, skip [returned:%s]\n" ) if $log;
        next;
      }
      my $cp_res = system( "/bin/cp $amfile $spool_path" );
      $log->Info( "  copied %s -> %s [status:%s]\n" , $amfile , $spool_path , $cp_res ) if $log;
    }
    $return_value = 1;
  }
  $log->Info( "  evacuateAmfileToSpool() end\n" ) if $log;

  return $return_value;
}

#####################################################
# get sequential file path under designated dir
#####################################################
sub getSequentialFilePath{

  my $base_dir    = shift;
  my $log         = shift;

  my $num = 0; #initial number
  my $return_str = '';

  $log->Info( "   getSequentialFilePath start [path:%s]\n" , $base_dir ) if !$log;

  if( ! -d $base_dir ){ # Bad Path
    $log->Info( "   designated directory is not a directory [path:%s]\n" , $base_dir ) if $log;
  }else{ # Good Path
    opendir ( my $dir , $base_dir );
    my @all_obj = readdir $dir;
    closedir $dir;
    my @files_only = ();

    foreach my $obj( @all_obj ){
      next if $obj =~ /^\./;
      my $fullpath = $base_dir . "/$obj";
      next if -d $fullpath;
      push @files_only , $obj;
    }

    if ( @files_only ){
      @files_only = sort{ $a <=> $b } @files_only;
      $num = $files_only[$#files_only];
      $log->Info( "   biggest number -> %s [path:%s]\n" , $num , $base_dir ) if $log;
      $num ++ ; # get next number
    }else{
      $log->Info( "   no file [path:%s]\n" , $base_dir ) if $log ;
    }
    $return_str = sprintf( "%s/%06d" , $base_dir , $num );
  }

  $log->Info( "   getSequentialFilePath end [return_path:%s]\n" , $return_str ) if $log;
  return $return_str;
}

sub CalcSum {
  my @args = @_;

  my $res = "";

  for my $arg (@args) {

    if (EsmLib::IsTheNumeric($arg)) {
      $res += $arg;
    }
  }
  return $res;
}

sub IsTheNumeric {

  # pattern     result
  # ----------|--------
  # 0           TRUE
  # 1           TRUE
  # 123	        TRUE
  # 0.1         TRUE
  # 0.123       TRUE
  # 12.345      TRUE
  # 0123        FALSE
  # 1.a         FALSE
  # 1a          FALSE
  # 1.          FALSE
  # hoge        FALSE
  # ""          FALSE
  # $undefined  FALSE

  my $v = shift;

  my $result = 0;

  if (defined $v && $v =~ /^([1-9]\d*|0)(\.[0-9]+)?$/) {
    $result = 1;
  }

  return $result;
}

sub CalcMulti {
  my ($a, $b) = @_;

  my $res;
  if (EsmLib::IsTheNumeric($a) && EsmLib::IsTheNumeric($b)) {
    $res = $a * $b;
  }
  return $res;
}

sub Devide {
  my ($numerator, $denominator, $fig) = @_;
  my $val = 0;
  eval { $val = $numerator / $denominator };
  $val = $@ ? "" : $val;
  if (!$val and !$fig) {
    return $val;
  }
  my $roundVal = Round($val, $fig);
  return $roundVal;
}

1;
