package DataSummarizer;

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

use EsmConf;
use EsmConfigWeb;
use VoyageJudgeHandler;
use EsmDataDetector;
use DataFormat;
use DailyReportHandler;
use EsmLib;

sub new {
  my ($class, $log) = @_;

  my $self = bless {
    log => $log
  }, $class;

  $self->set_definition;
  $self->set_formatter;

  return $self;
}

sub set_judge_result {
  my $self = shift;

  $self->{judge_result} = shift;
}

sub set_formatter {
  my $self = shift;

  $self->{fmt} = DataFormat->new($self->{log});
}

sub _search_report() {
  my $self = shift;

  my ($searcher, $src) = @_;
  my $result_value = "";

  my @matched_src = grep {
    my @k = keys(%{$_});
    my $k = $k[0];
    $k eq $searcher->{rep_type}
  } @{$src};

  if (@matched_src) {

    for my $i (@matched_src) {
      my @ky = keys(%{$i});
      my $key = $ky[0];
      my $val = $i->{$key};

      my $jh = JsonHandler->new($self->{log}, $val);
      my $dh = DailyReportHandler->new($self->{log}, $jh);
      $result_value = $jh->get_item($searcher->{rep_item}) unless $dh->is_invalid();
      last if $result_value;
    }
  }

  return $result_value;
}


sub set_definition {
  my $self = shift;

  my $path = EsmDataDetector::def_emission_per_voyage_items();

  my $jh = JsonHandler->new($self->{log}, $path);

  $self->{summarize_def} = $jh->get_data;
}

sub get_definition {
  my $self = shift;

  return $self->{summarize_def};
}

sub set_summarized_data {
  my $self = shift;

  my $val = shift;

  $self->{summarize_result} = $val;
}

sub get_summarize_result {
  my $self = shift;

  return $self->{summarize_result};
}

sub add_judge_result_to_summarize_result {
  my $self = shift;

  $self->{summarize_result}->set_item(["data", "include_reports"], $self->{judge_result}->get_data);
}

sub _convert_zero_but_true {
  my $self = shift;

  my $v = shift;

  return $v eq ZERO_BUT_TRUE ? "0" : $v;
}

sub summarize {
  my $self = shift;

  my $def = shift;
  my $args = shift || ['from_report_only', 'calculate_phase1', 'calculate_phase2', 'calculate_phase3'];
  my $fmt_type = shift;
  my $recalc_items = shift;

  my $reps = $self->{judge_result};

  $self->{log}->Info("    summarize value start.. \n");

  my $res = TRUE;
  my $proc_orders = [];

  # create proc orders
  for my $arg (@$args) {

    my @res = grep {
      my @k = keys(%{$_});
      my $k = $k[0];
      $arg eq $_->{$k}->{type} if $_->{$k}->{type}
    } @{$def};

    if ($recalc_items && @{$recalc_items}) {

      my @tmp_res = ();
      for my $i (@res) {
        my @k = keys(%{$i});
        my $k = $k[0];
        push @tmp_res, $i if grep { /^$k$/ } @{$recalc_items};
      }
      @res = @tmp_res;
    }
    if (@res) { push @{$proc_orders}, @res }
  }

  if (@{$proc_orders}) {

    my $vh = VoyageJudgeHandler->new($self->{log}, $reps);
    my $src = $vh->get_all_reports;

    if (@{$src}) {

      for my $df (@{$proc_orders}) {

        my @item_keys = keys(%{$df});
        my $item_key = $item_keys[0];
        my @values = values(%{$df});
        my $values = $df->{$item_key};

        my $init_log_msg = "      NG :";

        push( @{$values->{output_target}}, $item_key );
        my $out_tgt_str; for my $i (@{$values->{output_target}}) { $out_tgt_str .= "{$i}"; }
        $self->{log_msg} = sprintf(" summarize key => %s, summarize type => %s", $item_key, $values->{type});

        if ($values->{type} eq "from_report_only") {

          for my $rep (@{$values->{report}}) {

            # for log display message
            my $in_tgt_str; for my $i (@{$rep->{rep_item}}) { $in_tgt_str .= "{$i}"; }

            my $tgt_val = $self->_search_report($rep, $src);

            if ($tgt_val) {

              # get successed value
              $tgt_val = $self->_convert_zero_but_true($tgt_val);

              # format data
              my $formatted_value = $self->{fmt}->rounding_off_proc_outside($item_key, $tgt_val, $fmt_type);

              # limit check ok?
              if ($self->{fmt}->range_check_proc_outside($item_key, $formatted_value, $fmt_type)) {

                $self->{summarize_result}->set_item($values->{output_target}, $formatted_value);
                $self->{log_msg} .= sprintf(", set summarize value => %s, formatted_value => %s, input_target => %s, output_target => %s"
                 , $tgt_val, $formatted_value, $in_tgt_str, $out_tgt_str);
                $init_log_msg = "      OK :";
                last;
              }
            } else {
              $self->{log_msg} .= sprintf(", value not found -- rep_type => %s, rep_item_key => %s --", $rep->{rep_type}, $in_tgt_str);
            }
          }
          $self->{log}->Info($init_log_msg . $self->{log_msg} . "\n");
        }
        elsif ($values->{type} =~ /calculate/) {

          $self->{calc_res} = undef;
          my @src = @$src;

          eval {
            $self->_proc_calculation($values, \@src);
          };
          if ($@) {
            $self->{log_msg} .= ", Calc Error: $@";
          }

          if (( $values->{calc_method}
                && $values->{calc_method} ne 'VoyageEuMrvDataSummarizer::_calc_voyage_type'
                && EsmLib::IsTheNumeric($self->{calc_res})
              ) || $self->{calc_res}) {

            # format value
            my $formatted_calc_value = $self->{fmt}->rounding_off_proc_outside($item_key, $self->{calc_res}, $fmt_type);

            # limit check ok?
            if ($self->{fmt}->range_check_proc_outside($item_key, $formatted_calc_value, $fmt_type)) {


              $self->{summarize_result}->set_item($values->{output_target}, $formatted_calc_value);

              $self->{log_msg} .= sprintf(", set summarize value => %s, formatted_value => %s, output_target => %s"
               , $self->{calc_res}, $formatted_calc_value, $out_tgt_str);
              $init_log_msg = "      OK :";
            }
            # delete calc value dependency
            elsif (exists $self->{summarize_result}->get_data->{data}{for_row}{data}{$item_key}) {

              delete $self->{summarize_result}->get_data->{data}{for_row}{data}{$item_key};
              $self->{log}->Info("      this item deletion rounding off : $item_key\n");
            }
          }
          # delete calc value dependency
          elsif (exists $self->{summarize_result}->get_data->{data}{for_row}{data}{$item_key}) {

            delete $self->{summarize_result}->get_data->{data}{for_row}{data}{$item_key};
            $self->{log}->Info("      this item deletion : $item_key\n");
          }

          $self->{log_msg} =~ s/\n+$//; # adjust line feed
          $self->{log}->Info("%s%s%s", $init_log_msg, $self->{log_msg}, "\n");
        }
      }
    } else {
      $self->{log}->Info("    can not get source reports for summarize, exit\n");
    }
  } else {
    $self->{log}->Info("    can not get process orders, exit\n");
  }

  return $res;
}

sub _proc_calculation {
  my $self = shift;

  my ($values, $src) = @_;

  my $proc_res;

  # create args array for calculate
  my @calc_args = ();
  for my $arg (@{$values->{calc_args}}) {

    if ($arg->{arg_type} eq "rep") {

      my $in_tgt_str; for my $i (@{$arg->{rep_item}}) { $in_tgt_str .= "{$i}"; }

      my $arg_rep = $self->_search_report($arg, $src) || "none";

      if ($arg_rep eq "none") {
        $self->{log_msg} .= sprintf(", arg value not found -- arg_type => %s, rep_type => %s, rep_item_key => %s --"
         , $arg->{arg_type}, $arg->{rep_type}, $in_tgt_str);
      }
      push @calc_args, $arg_rep;
    }
    elsif ($arg->{arg_type} eq "summarize_result") {

      my $in_tgt_str; for my $i (@{$arg->{summarized_item}}) { $in_tgt_str .= "{$i}"; }

      my $arg_voy = $self->{summarize_result}->get_item($arg->{summarized_item}) || "none";

      if ($arg_voy eq "none") {
        $self->{log_msg} .= sprintf(", arg value not found -- arg_type => %s, summarized_item_key => %s --"
         , $arg->{arg_type}, $in_tgt_str);
      }
      push @calc_args, $arg_voy;
    }
    elsif ($arg->{arg_type} eq "string_value") {

      my $arg_str = (defined $arg->{arg_item} || EsmLib::IsTheNumeric($arg->{arg_item})) ? $arg->{arg_item} : "none";
      if ($arg_str eq "none") {
        $self->{log_msg} .= sprintf(", arg value not found -- arg_type => %s, string value is not defined --"
         , $arg_str);
      }
      push @calc_args, $arg_str;
    }
  }

  # output log args info
  $self->{log_msg} .= sprintf(", calc_args => [");
  for my $i (0..$#calc_args) {
    $self->{log_msg} .= sprintf(" %s ", $calc_args[$i]);
    last if $i eq $#calc_args;
    $self->{log_msg} .= ", ";
  }
  $self->{log_msg} .= sprintf("] ");

  # calculate using created array
  # zero but true convert process
  @calc_args = map { $self->_convert_zero_but_true($_) } @calc_args;

  # exec calculation
  {
    no strict "refs";
    $self->{calc_res} = &{$values->{calc_method}}(@calc_args);
  }

  # recursive calc process
  if (EsmLib::IsTheNumeric($self->{calc_res}) && $values->{is_recursive}
   && grep { exists($_->{is_exchange}) && $_->{is_exchange}} @{$values->{calc_args}}) {

    $self->{log_msg} .= sprintf(", for recursive calculation - check start");

    # create matcher from def item
    my @tmp_matcher = grep {
      !exists($_->{is_exchange}) && !($_->{is_exchange})
    } @{$values->{calc_args}};

    @tmp_matcher = map {$_->{rep_type}} @tmp_matcher;

    # delete src parameter if matched matcher
    for my $matcher (@tmp_matcher) {

      for my $i (0..$#{$src}) {

        my @k = keys(%{$src->[$i]});
        if ($k[0] eq $matcher) {
          splice(@{$src}, $i, 1); # delete src parameter
          last;
        }
      }
    }

    # recursive?
    if (@{$src}
     && grep { my @k = keys(%{$_}); EsmLib::InAry($k[0], \@tmp_matcher) } @{$src}) {

      $self->{log_msg} .= sprintf(", found recursive information - recursive calculation start");

      for my $i (0..$#{$values->{calc_args}}) {

        if (exists $values->{calc_args}->[$i]->{is_exchange} && $values->{calc_args}->[$i]->{is_exchange}) {
          $values->{calc_args}->[$i] = {"arg_type" => "string_value", "arg_item" => $self->{calc_res} * 60, "is_exchange" => "1"};
        }
      }

      $self->_proc_calculation($values, $src, $proc_res);
    } else {
      $self->{log_msg} .= sprintf(", not found recursive information - finished");
    }
  } else {
    $self->{log_msg} .= sprintf(", not for recursive calculation");
  }

  return;
}

1;