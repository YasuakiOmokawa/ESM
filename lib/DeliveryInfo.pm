use strict;
use warnings;

{
  package DeliveryInfo;

  use EsmConfigWeb;

  sub new
  { 
    my $class = shift;
    my $kind = shift;
    my $self = {};

    if ( $kind eq ${EsmConfigWeb::EDIT_DATA_KIND} )
    {
      $self->{dataid} = ${EsmConfigWeb::edit_tagid};
    }

    $self->{hostnames} = [ $EsmConfigWeb::API_DOMAINS{reportdb} ];
    $self->{addcareer} = '/usr/amoeba/lib/amdpp/addcareer';
    $self->{amdeliver} = '/usr/amoeba/lib/amftp/amdeliver';

   return bless $self, $class;
  }

  sub dataid
  {
    my $self = shift;
    return $self->{dataid};
  }
  
  sub hostnames
  {
    my $self = shift;
    return $self->{hostnames};
  }
  
  sub addcareer
  {
    my $self = shift;
    return $self->{addcareer};
  }

  sub amdeliver
  {
    my $self = shift;
    return $self->{amdeliver};
  }

}

1;
