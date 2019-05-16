package VoyageDataJudge;

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

use parent 'DataJudge';
use JsonHandler;
use DailyReportHandler;
use VoyageJudgeHandler;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";

sub new {
  my ($class, $log, $data, $recv_report) = @_;

  my $self = DataJudge->new($log, $data);

  $self = bless $self, $class;

  $self->{prev_report_type} = "";
  $self->{recv_report} = $recv_report;

  return $self;
}

sub judge {
  my $self = shift;

  $self->{log}->Info("  Start : %s\n", (caller 0)[3]);

  if (@{ $self->{data} }) {

    # create voyage box
    $self->_create_voyage_box;

    # extract judge result for display
    $self->_extract_voyage_for_display;

    # convert voyage start time by esm_version
    for my $r (@{$self->get_judge_result}) {
      my $v   = VoyageJudgeHandler->new($self->{log}, $r);
      $v->convert_start_time();
    }

    # add report during the voyage period
    $self->_set_additional_report;

  } else {
    $self->{log}->Error("    please input collected data\n");
  }

  $self->{log}->Info("  End : %s\n", (caller 0)[3]);
}

sub _get_prev_judge_type {
  my $self = shift;

  return $self->{prev_report_type};
}

sub _exists_prev_report {
  my $self = shift;

  my $res = FALSE;
  if ($self->_get_prev_judge_type) {
    $res = TRUE;
  }

  return $res;
}

sub _add_voyage_box {
  my $self = shift;

  my $voy_box = shift;

  my $jh = JsonHandler->new($self->{log}, $voy_box);
  $jh->set_item(["ship_info"], $self->{recv_report}->get_ship_info); # for download file information

  push @{$self->{judge_group}}, $jh->get_data;
}

sub _get_last_voyage_box {
  my $self = shift;

  return $self->{judge_group}->[$#{ $self->{judge_group} }];
}

sub _extract_voyage_for_display {
  my $self = shift;

  $self->{log}->Info("    Start : %s\n", (caller 0)[3]);

  my $year = $self->{recv_report}->get_report_year();
  my ($prev_y, $next_y) = ($year - 1, $year + 1);

  my @res = grep {

    my $h = JsonHandler->new($self->{log}, $_);
    my $d = $h->get_data;
    ($d->{type} eq "in_port" && $d->{to}) || ($d->{type} eq "underway" && $d->{to})
  } @{$self->{judge_group}};

  @res = grep {

    my $h = JsonHandler->new($self->{log}, $_);
    my $drh_g = DailyReportHandler->new($self->{log}, $h->get_data->{to});

    my ($from, $to) = (substr($drh_g->get_start_time, 0, 4), substr($drh_g->get_report_time, 0, 4));
    ( ($prev_y <= $from && $from <= $year) && ($year <= $to && $to <= $next_y) )
  } @res;

  if (@res) {

    $self->{log}->Info("      after extracted below\n");
    for my $i (@res) {
      my $h = JsonHandler->new($self->{log}, $i);
      my $drh_g = DailyReportHandler->new($self->{log}, $h->get_data->{to});
      $self->{log}->Info("        type => %s, from => %s, to => %s\n", $h->get_data->{type}, $drh_g->get_start_time, $drh_g->get_report_time);
    }
  } else {
    $self->{log}->Info("      no data exists after extract\n");
  }

  $self->{judge_group} = \@res;

  $self->{log}->Info("    End : %s\n", (caller 0)[3]);
}

sub _set_prev_judge_type {
  my $self = shift;
  my $val = shift;

  $self->{prev_report_type} = $val if ($val eq "voyage_start" || $val eq "voyage_end");
}

sub _set_additional_report {
  my $self = shift;

  eval {

    # create search source
    my @source = grep {
      my $h = JsonHandler->new($self->{log}, $_);
      my $d = DailyReportHandler->new($self->{log}, $h);
      my $t = $d->get_for_judge_voyage;
      $t && $t ne "voyage_start" && $t ne "voyage_end"
    } @{$self->{data}};

    if (@source) {

      # create search key data
      my @key = grep {
        my $h = JsonHandler->new($self->{log}, $_);
        my $d = $h->get_data;
        $d->{type} eq "underway" && $d->{to}
      } @{$self->{judge_group}};

      if (@key) {

        # search additional report
        for my $key (@key) {
          my $h1 = JsonHandler->new($self->{log}, $key);
          my $th = JsonHandler->new($self->{log}, $h1->get_data->{to});
          my $d1 = DailyReportHandler->new($self->{log}, $th);
          my $from = EsmLib::StrToEpoch($d1->get_start_time);
          my $to = EsmLib::StrToEpoch($d1->get_report_time);

          $self->{log}->Info("    search additional report start \n");

          # addition
          my @add = grep {
            my $h2 = JsonHandler->new($self->{log}, $_);
            my $d2 = DailyReportHandler->new($self->{log}, $h2);
            my $rep_time = EsmLib::StrToEpoch($d2->get_report_time);
            $self->{log}->Info("      From => %s, Target => %s, To => %s \n", $d1->get_start_time, $d2->get_report_time, $d1->get_report_time) if $EsmConf::IS_DEV;
            $from < $rep_time && $rep_time < $to
          } @source;

          # add result
          if (@add) {

            $self->{log}->Info("      additional report found %s items\n", scalar @add);

            my $item = [];
            for my $i (@add) {

              my $h3 = JsonHandler->new($self->{log}, $i);
              my $d3 = DailyReportHandler->new($self->{log}, $h3);

              push @{$item}, {$d3->get_for_judge_voyage => $h3->get_data};
            }

            $h1->set_item(["addition_report"], $item);
          } else {
            $self->{log}->Info("      additional report not found\n") if $EsmConf::IS_DEV;
          }
        }
      } else {
        $self->{log}->Info("      additional report search key not found\n");
      }
    } else {
      $self->{log}->Info("      additional source report not found\n");
    }
  };
  if($@){
    $self->{log}->Error("      Error _set_additional_report : %s\n" . $@);
  }
}

sub get_judge_result {
  my $self = shift;

  return $self->{judge_group};
}

sub _create_voyage_box {
  my $self = shift;

  my $year = $self->{recv_report}->get_report_year;

  # judge using collected data
  foreach my $dt (@{ $self->{data} }) {

    my $jh = JsonHandler->new($self->{log}, $dt);
    my $data = $jh->get_data;
    my $col_dh = DailyReportHandler->new($self->{log}, $jh);

    my $jdg_type = $col_dh->get_for_judge_voyage;
    my $rep_type = $col_dh->get_report_type_repo;
    my $rep_time = $col_dh->get_report_time;

    $self->{log}->Info("    report_type_repo => %s, report_time => %s, judge_type => %s\n", $rep_type, $rep_time, $jdg_type);

    my $prev_jdg_type = $self->_exists_prev_report ? $self->_get_prev_judge_type : "none";

    # judge voyage using judge type and prev judge type
    if ( $jdg_type eq "voyage_start" && ($prev_jdg_type eq "voyage_start" || $prev_jdg_type eq "none") ) {

      $self->{log}->Info("      this report add voyage box case1 \n");

      $self->_add_voyage_box( {type => "in_port", from => "", to => $data} );

      $self->_add_voyage_box( {type => "underway", from => $data, to => ""} );

    } elsif ( ($jdg_type eq "voyage_start" && $prev_jdg_type eq "voyage_end") || ($jdg_type eq "voyage_end" && $prev_jdg_type eq "voyage_start") ) {

      $self->{log}->Info("      this report add voyage box case2 \n");

      $self->_get_last_voyage_box->{to} = $data;

      my $add_type = $jdg_type eq "voyage_start" ? "underway"
                   : $jdg_type eq "voyage_end"   ? "in_port"
                   : FALSE;

      if ($add_type) {
        $self->_add_voyage_box( {type => $add_type, from => $data, to => ""} );
      }

    } elsif ( $jdg_type eq "voyage_end" && ($prev_jdg_type eq "voyage_end" || $prev_jdg_type eq "none") ) {

      $self->{log}->Info("      this report add voyage box case3 \n");

      $self->_add_voyage_box( {type => "underway", from => "", to => $data} );

      $self->_add_voyage_box( {type => "in_port", from => $data, to => ""} );

    }

    # set report type to prev one
    $self->_set_prev_judge_type($jdg_type);
  }
}

1;