use strict;
use warnings;

BEGIN{
  my $loggingdir = "/usr/amoeba/lib/perl";
  my $mylibdir = "/usr/amoeba/pub/b/ESM/lib";
  push( @INC, $loggingdir, $mylibdir );
}

use logging;
use EsmConfigWeb;

package EsmLogger;

my $log_i;
my $log_e;

#----------------------------
# Open
#----------------------------
sub Open {
  my ( $pkg, $func_id ) = @_;
  
  my $logfile_i = sprintf('%s/%s.log', $EsmConfigWeb::LOG_DIR, $func_id);
  my $logfile_e = sprintf('%s/%s_error.log', $EsmConfigWeb::LOG_DIR, $func_id);

  $log_i = logging->Open($logfile_i);
  $log_e = logging->Open($logfile_e);

  my $self = {
    Info_log => $log_i,
    Error_log => $log_e
  };

  return bless $self, $pkg;
}

#----------------------------
# Close
#----------------------------
sub Close {
  $log_i->Close();
  $log_e->Close();
}

#----------------------------
# Info Log
#----------------------------
sub Info {
  my $self = shift;
  my $fmt = shift;

  $log_i->Info($fmt, @_);
}

#----------------------------
# Warning Log
#----------------------------
sub Warn {
  my $self = shift;
  my $fmt = shift;

  $log_i->Warn($fmt, @_);
}

#----------------------------
# Error Log
#----------------------------
sub Error {
  my $self = shift;
  my $fmt = shift;

  $log_e->Error($fmt, @_);
}

#----------------------------
#  for "require"
#----------------------------
1;
