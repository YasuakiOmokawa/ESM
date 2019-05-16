package JsonHandler;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use constant { TRUE => 1, FALSE => 0, ZERO_BUT_TRUE => 'ZERO_BUT_TRUE' };

my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";

use EsmLib;
use EsmConf;
use ExclusiveControl;

sub new {
  my ($class, $log, $info) = @_;

  my $self = bless {
    log => $log,
  }, $class;
  
  if ($info) {
    
    if (ref($info) eq "JsonHandler") {
      $log->Error("this data is already JsonHandler instance\n");
      exit;
    }
  
    if (-f $info) {
      $self->{file_abs_path_read} = $info;
      $self->{file_abs_path_save} = $info;
      $self->load_file;
    }
    else {
      $self->set_data($info);
    }
  }

  return $self;
}

sub load_file {
  my $self = shift;
  
  my $data;
  EsmLib::LoadJson($self->{file_abs_path_read}, \$data);

  $self->{data} = $data;
}

sub set_save_path {
  my $self = shift;
  
  my $file_path = shift;
  
  $self->{file_abs_path_save} = $file_path;
}

sub set_data {
  my $self = shift;
  
  my $data = shift;
  
  $self->{data} = $data;

}

sub get_data {
  my $self = shift;
  
  return $self->{data};
}

sub set_item {
  my $self = shift;
  my ($keys, $value, $report_info) = @_;
  
  $self->key_value($keys, $value, $report_info);
}

sub get_item {
  my $self = shift;
  my $keys = shift;
  my $report_info = shift;
  
  my @keys = @{$keys};
  my $res = $self->key_value(\@keys, "none", $report_info);
  $res = ZERO_BUT_TRUE if $self->_is_zero_but_true($res);

  return $res;
}

sub key_value {
  my ($self, $keys, $value, $report_info ) = @_;
  
  if (@$keys) {
    
    $report_info = $self->{data} if (!defined($report_info));
    $value = "none" if (!defined($value));
  
    my $target_data = undef;
    my $key = shift(@$keys);
    my $cnt = @$keys;
  
    if ($report_info && exists($report_info->{$key})) {
      
        # get data
        $target_data = $report_info->{$key};
    }
    if ($keys && $cnt > 0 && $target_data) {

      # recursive search one layer under
      $target_data = $self->key_value($keys, $value, $target_data);
    }
    if (!$cnt && $value ne "none") {
      
      # set data
      if ($key) {
        
        if (ref $report_info->{$key} eq "ARRAY") {
          push @{$report_info->{$key}}, $value;
        } else {
          $report_info->{$key} = $value;
        }
      }
    }
  
    return $target_data ;
  } else {
    $self->{log}->Error("no numbers of search key\n");
  }
}

sub _is_zero_but_true {
  my $self = shift;
  
  my $v = shift;
  
  my $result = FALSE;
  
  if (defined $v && $v =~ /^0$/) {
    $result = TRUE;
  }
  
  return $result;
}

sub save {
  my $self = shift;
  
  EsmLib::SaveJson($self->{file_abs_path_save}, $self->{data}, $EsmConf::IS_DEV);
}

sub _write_lock_prepare {
  my $self = shift;
  
  my $dir = dirname $self->{file_abs_path_save};
  my $file = basename $self->{file_abs_path_save};
  my $mode = 2; # blocking after process
  
  return ExclusiveControl->new($dir, $file, $mode, $self->{log});
}

sub write_lock {
  my $self = shift;
  
  $self->{lock_h} = $self->_write_lock_prepare;

  $self->{lock_h}->do;
}

sub undo_lock {
  my $self = shift;
  
  $self->{lock_h}->undo;
}

sub unlink_lock {
  my $self = shift;
  
  $self->{lock_h}->unlink_lock_file;
}


1;