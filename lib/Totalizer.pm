package Totalizer;

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
use DataFormat;
use EsmLib;

sub new {
  my ($class, $log, $add) = @_;

  my $self = bless {
    log => $log
  }, $class;

  if ($add) {
    $self->add_result_group($add);
  }

  $self->set_formatter;

  return $self;
}

sub set_formatter {
  my $self = shift;

  $self->{fmt} = DataFormat->new($self->{log});
}

sub add_result_group {
  my $self = shift;

  $self->{summarize_result_group} = shift;
}

# dummy
sub totalize {}

sub calc_total {
  my $self = shift;

  my ($calc_list, $black_list) = @_;

  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  my $res = {};

  if ($calc_list && @$calc_list) {

    for my $i (@$calc_list) {

      for my $k (keys(%{$i})) {

        next if $black_list && grep { /^$k$/ }@{$black_list};

        if ( exists $i->{$k} && EsmLib::IsTheNumeric($i->{$k}) ) {
          $res->{$k} += $i->{$k};
        } else {
          $self->{log}->Info("  key is not found or pair value is undefined : %s\n", $k);
        }
      }
    }
  } else {
    $self->{log}->Info("  calclation list is empty\n");
  }

  $self->{log}->Info("End : %s\n", (caller 0)[3]);
  return $res;
}

sub format {
  my $self = shift;
  $self->{log}->Info("Start : %s\n", (caller 0)[3]);
  my ($d, $black_list, $format_type) = @_;

  for my $k (keys(%{$d})) {

    if (!grep { /^$k$/ } @$black_list ) {

      for my $i (keys(%{$d->{$k}->{data}})) {

        my $value = $d->{$k}->{data}->{$i};
        my $fmt_val = $self->{fmt}->rounding_off_proc_outside($i, $value, $format_type);

        $self->{log}->Info("category => %s, key => %s, value => %s, formatted_value => %s\n", $k, $i, $value, $fmt_val);

        if (!$self->{fmt}->range_check_proc_outside($i, $fmt_val, $format_type)) {

          $self->{log}->Info("this item invalid range, delete\n");
          delete $d->{$k}->{data}->{$i};
        } else {

          $d->{$k}->{data}->{$i} = $fmt_val;
        }
      }
    }
  }
  $self->{log}->Info("End : %s\n", (caller 0)[3]);
}

1;