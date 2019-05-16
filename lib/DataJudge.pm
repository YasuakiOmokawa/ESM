package DataJudge;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use constant { TRUE => 1, FALSE => 0 };

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
    data => $data,
    judge_group => []
  }, $class;
  
  return $self;
}

# dummy 
sub judge {}


1;