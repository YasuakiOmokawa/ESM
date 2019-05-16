use strict;
use warnings;

{
  package CheckArgument;

  use File::Basename;
  use constant { TRUE => 1, FALSE => 0 };

  BEGIN{
    my $mylibdir = dirname( $0 ) . "/../lib";
    push( @INC, $mylibdir );
  }

  #-----------------------------------------
  # Check Argument
  #-----------------------------------------
  sub check_argument {
    my ($args_ref, $log) = @_;

    $log->Info("  Start %s\n", __PACKAGE__);
    
    my $result = TRUE;
    eval {

      my $msg = "    Arguments: ";
      foreach my $key (sort keys %$args_ref) {
        if (!$args_ref->{$key}) {
          $log->Info("    can't get argument: $key\n");
          $result = FALSE;
        } else {
          $msg = "$msg [$key] => $args_ref->{$key},";
        }
      }
      $msg =~ s/,$//; # delete last comma
      $log->Info($msg."\n") if $result;
    };
    if ($@)
    {
      $log->Error("    Error: $@");
      $result = FALSE;
    }

    $log->Info("  End %s\n", __PACKAGE__);
    return $result;
  }
}
1;
