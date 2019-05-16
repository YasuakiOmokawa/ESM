package MonthlyReportHandler;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use JsonHandler;
use DailyReportHandler;

my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";

sub new {
  my ($class, $log, $data) = @_;

  $data = ref($data) eq "JsonHandler" ? $data : JsonHandler->new($log, $data);
  
  my $self = bless {
    log => $log,
    data => $data
  }, $class;
  
  return $self;
}

sub get_monthly_data {
  my $self = shift;

  return $self->{data}->get_item(["report"]);
}

sub search_data {
  my $self = shift;
  
  my $res;

  my ($msg_id, $rep_id) = @_;
  if ($msg_id && $rep_id) {
    
    my @res = grep {
      my $dh = DailyReportHandler->new($self->{log}, $_);
      ($dh->get_message_id eq $msg_id)
        && ($dh->get_report_type_id eq $rep_id) if $dh->get_message_id && $dh->get_report_type_id
    } @{$self->get_monthly_data};
    
    $res = $res[0] if @res;
  } else {
    $self->{log}->Error("  there is undefined parameter\n");
  }

  return $res;
}

1;