#! /usr/local/bin/perl

use strict;
use warnings;

# CPAN module
use File::Basename;
use POSIX qw(strftime);
use JSON;
use Data::Dumper;
use CGI::Carp qw/fatalsToBrowser/;

my $MY_DIR  = "";
my $TOP_DIR = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
  $TOP_DIR = "$MY_DIR/../..";
};

use lib "$TOP_DIR/lib";
use lib '/usr/amoeba/lib/perl';

# not CPAN module
use logging;
use EsmDataDetector;
use JsonHandler;

# Static settings
my $top_dir    = dirname(__FILE__) . "/../..";
my $prog_name  = basename(__FILE__);
my $proc_time  = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd        = substr($local_time, 0, 8);
my $log_fname  = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );

# Initialize logging object
my $log = logging->Open($log_fname);

# Initialize result data
my $res_data = {
  result => "NG",
  detail => {
    message   => "",
    exec_user => "",
    exec_time => ""
  }
};

#=========================================
# main process
#=========================================
my $cgi = CGI->new;
eval {

  # create check parameter
  my $params = {};
  $params->{imo_no}       = $cgi->param("imo_no") // '';
  $params->{client_code}  = $cgi->param("client_code") // '';
  $params->{voyage_key}   = $cgi->param("voyage_key") // '';
  $params->{target_key}   = $cgi->param("target_key") // '';
  my $undef_param_str = checkParam($params);
  if (!$undef_param_str) {

    # データ取得条件の設定
    my $ed = EsmDataDetector->new($log, $params->{client_code}, $params->{imo_no});
    my ($edit_file, $target, $regex, $data_type) = ("", "", "", "");
    if ($params->{voyage_key}) {

      $edit_file = $ed->voyage_edit($params->{voyage_key});
      $target    = ['data', 'for_row', 'data'];
      $data_type = 'voyage';
    }
    if (-f $edit_file) {

      # データ取得
      my $data_type_msg = sprintf("%s->%s", $data_type, $params->{target_key});
      my $jh            = JsonHandler->new($log, $edit_file);
      my $data_root     = $jh->get_item($target);
      my @matched       = grep { $_->{key} eq $params->{target_key} } @{$data_root};
      if (@matched) {

        setInfoMsg( sprintf("get history: %s", $data_type_msg) );
        # $log->Error("%s\n", Dumper \@matched);
        my $last_edit_info = pop @{$matched[0]->{edit_info}};
        $res_data->{detail}{exec_user} = $last_edit_info->{exec_user};
        $res_data->{detail}{exec_time} = $last_edit_info->{exec_time};
      } else {
        setInfoMsg( sprintf("unknown data: %s", $data_type_msg) );
      }
    } else {
      setInfoMsg("unknown edit file");
    }
  } else {
    setErrMsg( sprintf("error: [failed because %s is empty]", $undef_param_str) );
  }
};
if ($@) {
  setErrMsg( sprintf("Exception error: %s", $@) );
}

sub returnResult {
  my ($cgi, $res_data) = @_;
  print $cgi->header(-type => 'application/json', -charset => 'UTF-8');
  $res_data //= '';
  print JSON->new->utf8(0)->encode($res_data) . "\n";
}

sub setErrMsg {
  my $msg = shift;
  $log->Error("$msg\n");
  $res_data->{detail}{message} = $msg;
}

sub setInfoMsg {
  my $msg = shift;
  $log->Info("$msg\n");
  $res_data->{detail}{message} = $msg;
  $res_data->{result} = 'OK';
}

sub checkParam {
  my $params = shift;
  my ($def_param_str, @def_params, $undef_param_str, @undef_params)
    = ("", (), "", ());
  $log->Info("{start Function checkParam}\n");

  # existance check
  for my $key (sort keys(%{$params})) {

    if ($params->{$key}) {
      push @def_params, "$key:$params->{$key}";
    } else {
      push @undef_params, $key;
    }
  }
  $def_param_str = join " ", @def_params;
  $log->Info("  Parameter { %s }\n", $def_param_str);

  $undef_param_str = join " ", @undef_params;

  $log->Info("{end Function checkParam}\n");
  return $undef_param_str;
}

END {
  $log->Close() if( defined( $log ) );
  returnResult($cgi, $res_data);
}

1;