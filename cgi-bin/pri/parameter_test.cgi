#! /usr/local/bin/perl

use strict;
use warnings;

#モジュール読み込み
use File::Basename;
use POSIX qw(strftime);
use JSON;
use Data::Dumper;
use URI;
use CGI;
use bytes();

my $MY_DIR  = "";
my $TOP_DIR = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
  $TOP_DIR = "$MY_DIR/../..";
};

use lib "$TOP_DIR/lib";
use lib '/usr/amoeba/lib/perl';

# not CPAN module use below
use logging;

# Static settings
my $top_dir = dirname(__FILE__) . "/../..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );

# Initialize Logging Object
my $log  = logging->Open( $log_fname ) ;

#=========================================
# main process
#=========================================
eval {

  # fetch request data
  my $q = CGI->new;
  my %params = map { $_ => $q->param($_) } $q->param();
  my @cookies = $q->cookie();

  # show request data
  $log->Info("  show request parameter:\n");
  for my $param ( keys %params ) {
      $log->Info("    $param: $params{$param}\n");
  }

  $log->Info("  show request cookie:\n");
  for my $i ( @cookies ) {
      $log->Info("    %s: %s\n", $i, $q->cookie($i));
  }
  # $log->Info(Dumper $q);

  # create response data
  my $res = {
    result => "OK",
    detail => {
      message => 'sample ok response',
      exec_user => 'hoge@fuga.com',
      exec_time => '2018-10-01T09:46:53'
    }
  };

  # encode response data
  my $json = JSON->new->utf8(0)->encode($res);

  # output response
  print CGI::header(-type => 'application/json', -charset => 'UTF-8');
  print $json;

};
if ($@) {
  $log->Error("Error: $@");
}

END{
  $log->Close() if( defined( $log ) );
}


1;