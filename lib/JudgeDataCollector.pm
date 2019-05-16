package JudgeDataCollector;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;

my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";

use EsmConf;
use EsmConfigWeb;

sub new {
  my ($class, $log, $data) = @_;
  
  my $self = bless {
    log => $log,
    source => $data,
    data_group => []
  }, $class;
  
  return $self;
}

# dummy 
sub acquire {}

sub add_acquired_data {
  my $self = shift;
  
  my $data = shift;
  
  $self->{data_group} = [@{$self->{data_group}}, @{$data}];
  
}

1;