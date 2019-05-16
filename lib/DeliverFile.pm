{
  package DeliverFile;

  use strict;
  use warnings;
  use File::Basename;

  #--------------------------------------------------------
  # Deliver file to another server using amdeliver command
  #--------------------------------------------------------
  sub deliver_file {
    my ($deliverinfo, $file_path, $log) = @_;

    $log->Info("  Start %s\n", __PACKAGE__);
    
    my $result = 1;
    eval {

      my @target_paths        = split /\//,$file_path;
      my $target_file_name    = $target_paths[-1];
      $target_file_name       .= ".am";
      my $deliver_file_path   = "/tmp/".$target_file_name;
      
      my $dataid    = $deliverinfo->dataid();
      my $addcareer = $deliverinfo->addcareer();
      my $amdeliver = $deliverinfo->amdeliver();
      my @hostnames = @{$deliverinfo->hostnames()};
    
      my $str = "$addcareer ".$file_path." ".$dataid." ".$deliver_file_path;
      my $ret = system( $str );
      foreach my $hostname ( @hostnames )
      {
        my $cmd = "$amdeliver ".$hostname." ".$deliver_file_path;
        $log->Info("    amdeliver command => [%s]\n", $cmd);
        my $ret = system( $cmd );
        $result = 0 if $ret > 0;
      }
      unlink $deliver_file_path;
    };
    if ($@)
    {
      $log->Error("    Error: $@");
      $result = 0;    
    }

    $log->Info("  End %s\n", __PACKAGE__);
    return $result;
  }
}
1;
