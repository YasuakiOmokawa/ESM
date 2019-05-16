package ExclusiveControl;

use strict;
use warnings;
use constant { TRUE => 1, FALSE => 0 };

sub new {
  my ($class, $dir, $file, $mode, $log) = @_;
  
  my $self = bless {
    dir  => $dir,
    file => $file,
    mode => $mode,
    log  => $log,
  }, $class;

  return $self;
}

sub do {
  my $self = shift;
  
  my $_res = TRUE;
  
  my $lock_file = sprintf("%s/%s.lock", $self->{dir}, $self->{file});
  
  $self->{lock_file} = $lock_file;

  if (!open(LOCK, "> $lock_file")) {
    $self->{log}->Error("Can\'t open lock file. [%s]\n", $!);
    $self->{log}->Error("Lock file => %s\n", $lock_file);
    $_res = FALSE;
  } else {
    if (!flock(LOCK, $self->{mode})) {
      $self->{log}->Error("Can\'t flock. [%s]\n", $!);
      $_res = FALSE;
    }
  }
  
  return $_res;
}

sub undo {
  my $self = shift;
  
  close(LOCK);
}

sub unlink_lock_file {
  my $self = shift;
  
  unlink $self->{lock_file};
}

1;