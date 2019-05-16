package VoyageDataEditReSummarizer;

use strict;
use warnings;
use File::Basename;
use Data::Dumper;
use POSIX qw(strftime);
use constant { TRUE => 1, FALSE => 0, };

my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";

use EsmLib;
use EsmConf;
use EsmConfigWeb;
use VoyageJudgeHandler;
use EsmDataDetector;
use Totalizer;
use VoyageDataDailyChangeReSummarizer;
use VoyageRowDataSummarizer;
use VoyageEuMrvDataSummarizer;
use JsonHandler;
use Carp qw/croak/;

sub new {
  my ($class, $log) = @_;

  my $self = bless {
    log => $log
  }, $class;

  return $self;
}

sub edit_and_save {
  my $self = shift;

  $self->{log}->Info("Start : %s\n", (caller 0)[3]);

  my ($imo_no,
    $client_code,
    $voy_key,
    $imo_type,
    $year,
    $editor,
    $edit_key,
    $edit_value,
    $pre_edit_value) = @_;

  my $result = FALSE;

  # 2. get system time
  my $proc_time = time;
  my $file_name_str_edit_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
  my $history_edit_time = EsmLib::EpochToLTStr($proc_time);

  $self->{log}->Info("  edit time file name str: %s\n", $file_name_str_edit_time);
  $self->{log}->Info("  edit time history str  : %s\n", $history_edit_time);

  ## edit info
  my $add_edit_info = {
    exec_time            => $history_edit_time,
    exec_user            => $editor,
    updated_value        => $edit_value,
    before_updated_value => $pre_edit_value
  };

  my $new_edit_info_voyage = {
    key       => $edit_key,
    edit_info => [$add_edit_info]
  };

  my $ed = EsmDataDetector->new($self->{log}, $client_code, $imo_no);

  ## edit
  if ($voy_key) {

    $self->{log}->Info("  edit type is list of voyage, voyage_key => %s\n", $voy_key);

    # read voyage info
    my $voy_info_path = $ed->voyage_info($voy_key);
    if ($voy_info_path) {

      my $voy_info_jh = JsonHandler->new($self->{log}, $voy_info_path);

      # read or create voyage edit
      my $voy_edit_jh;
      my $voy_edit_path = $ed->voyage_edit($voy_key);
      if ($voy_edit_path) {

        $self->{log}->Info("  edit info exist, update edit info\n");

        $voy_edit_jh = JsonHandler->new($self->{log}, $voy_edit_path);
        $voy_edit_jh->write_lock();
      } else {

        $self->{log}->Info("  edit info not exist, create edit info\n");

        my $tmp_edit_voyage = EsmDataDetector::template_edit_voyage();
        if (-f $tmp_edit_voyage) {
          $voy_edit_jh = JsonHandler->new($self->{log}, $tmp_edit_voyage);
          $voy_edit_jh->set_save_path($ed->voyage_edit_path($voy_key));
          $voy_edit_jh->write_lock();
        } else {
          my $msg = "voyage edit template not exist";
          $self->{log}->Error("  $msg: %s\n", $tmp_edit_voyage);
          croak("$msg");
        }
      }

      $self->{log}->Info("  update voyage info\n");
      $self->{log}->Info("    edit_key : %s\n", $edit_key);
      $voy_info_jh->set_item(["data", "for_row", "data", $edit_key], $edit_value);
      my $calc_categories = undef;
      my $calc_items = undef;

      if ($edit_key =~ /foc_*/) {

        my @category = split /_/, $edit_key;
        $calc_categories = ["calculate_phase2", "calculate_phase3"];
        $calc_items      = ["co2_$category[1]", "foc_$category[1]_per_distance", "foc_$category[1]_per_transport_work", "co2_per_distance", "eeoi"];
        shift @{$calc_items} if $edit_key eq 'foc_other';
      }
      elsif (grep {/^$edit_key$/} ('dep_port', 'arr_port')) {

        $calc_categories = ["calculate_phase1"];
        $calc_items      = ["eu_mrv"];
      }
      elsif (grep {/^$edit_key$/} ('distance_travelled', 'cargo_weight')) {

        $calc_categories = ["calculate_phase1", "calculate_phase2", "calculate_phase3"];
        $calc_items      = ["transport_work", "foc_dogo_per_distance", "foc_lfo_per_distance",
                            "foc_hfo_per_distance", "foc_dogo_per_transport_work",
                            "foc_lfo_per_transport_work", "foc_hfo_per_transport_work", "co2_per_distance", "eeoi"];
      }
      elsif (grep {/^$edit_key$/} ('co2_other')) {

        $calc_categories = ["calculate_phase3"];
        $calc_items      = ["co2_per_distance", "eeoi"];
      }

      if ($calc_categories && $calc_items) {

        my $ds = VoyageDataDailyChangeReSummarizer->new($self->{log});
        $ds->summarize($voy_info_jh->get_data, $calc_categories, $calc_items);
      }

      $self->{log}->Info("  update voyage edit file\n");

      my $hists = $voy_edit_jh->get_item(["data", "for_row", "data"]);
      if (@$hists && grep { $_->{key} eq $edit_key } @$hists) {

        # add item
        my @match = grep { $_->{key} eq $edit_key } @$hists;
        $self->{log}->Info("  add history\n");
        push @{$match[0]->{edit_info}}, $add_edit_info;

      } else {
        # create item
        $self->{log}->Info("  create history\n");
        $voy_edit_jh->set_item(["data", "for_row", "data"], $new_edit_info_voyage);
      }

      # save voyage info
      my $old_voy_info = $voy_info_path;
      my $new_file_str = "_" . $file_name_str_edit_time . '.json';
      $voy_info_path =~ s/_\d{14}\.json/$new_file_str/;
      $self->{log}->Info("  new voyage info path : %s\n", $voy_info_path);

      $voy_info_jh->set_save_path($voy_info_path);
      $voy_info_jh->save;

      unlink $old_voy_info; # delete obsolete info

      my $trg_data = {
        imo_no => $imo_no,
        client_code => $client_code,
        year => $year
      };
      my $trg_jh = JsonHandler->new($self->{log}, $trg_data);
      my $imodcs_trig = $ed->imodcs_annual_trigger($year);
      my $eumrv_trig = $ed->eumrv_annual_trigger($year);
      $trg_jh->set_save_path($imodcs_trig); $trg_jh->save();
      $self->{log}->Info("  create annual trigger : %s\n", $imodcs_trig);
      $trg_jh->set_save_path($eumrv_trig); $trg_jh->save();
      $self->{log}->Info("  create annual trigger : %s\n", $eumrv_trig);

      $self->{log}->Info("  save voyage edit : %s\n", $voy_edit_path);
      $voy_edit_jh->save();
      $voy_edit_jh->undo_lock();
      $voy_edit_jh->unlink_lock();

      # overwrite voyage index
      my $vj = VoyageJudgeHandler->new($self->{log}, $voy_info_jh->get_item(["data", "include_reports"]));
      my $idx_file = $vj->get_index_file_name();

      my $idx_jh = JsonHandler->new($self->{log}, { voyage_file_path => $voy_info_path });
      my $idx_path = sprintf("%s/%s", $ed->voyage_index_dir(), $idx_file);
      $idx_jh->set_save_path($idx_path);
      $idx_jh->save;
      $self->{log}->Info("  overwrite voyage index : %s\n", $idx_path);

      # annual process immediately
      $self->{log}->Info("  start annual process immediately\n");
      my @cmd1 = (
        EsmDataDetector::create_eumrv_annual_data_program,
        "2"
      );

      my $r1 = system @cmd1;

      my @cmd2 = (
        EsmDataDetector::create_imodcs_annual_data_program,
        "2"
      );

      my $r2 = system @cmd2;

      $result = TRUE if !$r1 && !$r2;
    }
  }

  $self->{log}->Info("End : %s\n", (caller 0)[3]);
  return $result;
}

1;