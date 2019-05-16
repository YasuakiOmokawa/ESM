#! /usr/local/bin/perl

use strict;
use warnings;
use File::Basename;
use POSIX qw(strftime);
use constant { TRUE => 1, FALSE => 0 };
use Data::Dumper;

my $MY_DIR  = "";
my $TOP_DIR = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
  $TOP_DIR = "$MY_DIR/../..";
};

use lib "$TOP_DIR/lib";
use lib '/usr/amoeba/lib/perl';
use EsmConf;
use EsmConfigWeb;
use logging;

use JsonHandler;
use DailyReportHandler;
use VoyageJudgeDataCollector;
use VoyageDataJudge;
use VoyageJudgeHandler;
use VoyageDataDailyChangeReSummarizer;
use VoyageRowDataSummarizer;
use MonthlyReportHandler;
use EsmDataDetector;

# result flag
my $res = FALSE;

# Static settings
my $top_dir = dirname(__FILE__) . "/../..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $voyage_info_root_dir = sprintf("%s/data/esm3_voyage", $top_dir);

# Initialize Logging Object
my $log  = logging->Open( $log_fname ) ;

sub main {

  $log->Info("judge voyage main starts...\n");

  my $rms_daily = $ARGV[0];
  if ($rms_daily) {

    ## set data into daily report class
    my $daily_json_handler = JsonHandler->new($log, $rms_daily);
    my $daily_handler = DailyReportHandler->new($log, $daily_json_handler);
    unlink $rms_daily if $rms_daily =~ /\/tmp/;

    my $client_code        = $daily_handler->get_client_code();
    my $imo_no             = $daily_handler->get_imo_number();
    my $year               = $daily_handler->get_report_year();
    my $judge_voyage_type  = $daily_handler->get_for_judge_voyage();

    $log->Info("  this report type repo : %s\n", $daily_handler->get_report_type_repo());
    $log->Info("  this report type      : %s\n", $daily_handler->get_report_type());
    $log->Info("  this report status    : %s\n", $daily_handler->get_status());
    $log->Info("  client_code           : %s\n", $client_code);
    $log->Info("  imo_no                : %s\n", $imo_no);
    $log->Info("  year                  : %s\n", $year);
    $log->Info("  messageId             : %s\n", $daily_handler->get_message_id);
    $log->Info("  for judge voyage      : %s\n", $judge_voyage_type);

    ## exit program if this report is not for judge voyage
    if ($judge_voyage_type) {

      $log->Info("  this report type is for judge voyage\n");

      ## data collect for judge voyage
      $log->Info("  data collect for judge voyage start\n");

      my $judge_data_collector = VoyageJudgeDataCollector->new($log, $daily_handler);
      $judge_data_collector->acquire();

      ## judge voyage
      $log->Info("  judge voyage start\n");

      my $voyage_data_judge = VoyageDataJudge->new($log, $judge_data_collector->get_collector_result, $daily_handler);
      $voyage_data_judge->judge();

      ## summarize voyage
      $log->Info("  summarize voyage start\n");

      my $latest_report_time = $daily_handler->get_latest_report_time();
      my $report_time        = $daily_handler->get_report_time();

      my $ed = EsmDataDetector->new($log, $client_code, $imo_no);

      my $voyage_info_file_dir       = sprintf("%s/%s/%s/voyage", $voyage_info_root_dir, $client_code, $imo_no);
      my $voyage_info_index_file_dir = sprintf("%s/%s/%s/voyage_index", $voyage_info_root_dir, $client_code, $imo_no);
      my $judge_list                 = [];
      my $new_summarize_results      = [];
      my $is_create_trigger          = FALSE;
      my $existing_db                = [];

      my $exp = sprintf("%s/*.json", $voyage_info_index_file_dir);
      my @voyage_index_files = glob($exp);

      my @extracted;
      @extracted = grep {
        my @idx = split /_/, basename($_);
        my ($from, $to) = ($idx[0], $idx[1]);
       ( ($year - 1) <= substr($from, 0, 4) && substr($from, 0, 4) <= $year ) &&
       ( $year <= substr($to, 0, 4) && substr($to, 0, 4) <= ($year + 1) )
      } @voyage_index_files;

      for my $i (@extracted) {
        my $jh = JsonHandler->new($log, $i);
        my $voy_path = $jh->get_data->{voyage_file_path};
        my $voy_f = basename($voy_path);
        my $target_num = rindex($voy_f, "_");
        my $v_key = substr($voy_f, 0, $target_num);

        push @{$existing_db}, { idx => $i, voy_key => $v_key };
      }

      foreach my $judge_result (@{$voyage_data_judge->get_judge_result}) {

        my $voyage_judge_handler   = VoyageJudgeHandler->new($log, $judge_result);

        my $voyage_index_file_name = $voyage_judge_handler->get_index_file_name();
        my $voyage_key             = $voyage_judge_handler->get_voyage_key();

        push @{$judge_list}, { idx => $voyage_index_file_name, voy_key => $voyage_key };

        # if new voyage then create new voyage
        $log->Info("    generated judge voyage key   : %s\n", $voyage_key);
        $log->Info("    generated judge voyage index : %s\n", $voyage_index_file_name);
        $log->Info("    generated voyage update time : %s\n", $voyage_judge_handler->get_latest_time);

        if (! grep { $_->{idx} =~ /$voyage_index_file_name/ && $_->{voy_key} eq $voyage_key } @{$existing_db}) {

          $log->Info("      it is new judge voyage, summarize start\n");

          # summarize voyage
          my $new_row_data_summarizer = VoyageRowDataSummarizer->new($log);
          $new_row_data_summarizer->summarize($judge_result);

          # add summarize result
          my $upd_time_str = EsmLib::EpochToStr(EsmLib::StrToEpoch($voyage_judge_handler->get_latest_time), "%Y%m%d%H%M%S");
          my $summarize_result = {
            file_data => $new_row_data_summarizer->get_summarize_result->get_data,
            voy_file_name => sprintf("%s_%s.json", $voyage_key, $upd_time_str),
            voy_index_file_name => $voyage_index_file_name
          };

          push @{$new_summarize_results}, $summarize_result;
        } else {
          $log->Info("      it is already voyage, no summarize\n");
        }
      }

      # if daily report contains voyage already and updatable,
      # update voyage and re-summarize voyage
      $log->Info("  search voyage this report contain start\n");
      $log->Info("    this report time : %s\n", $report_time);

      my @report_contain_voyage_indexes = grep {

        my @index = split(/_/, basename($_));
        if ($index[0] && $index[1]) {

          EsmLib::StrToEpoch(cng_fmt_tmz($index[0])) <= EsmLib::StrToEpoch($report_time)
            && EsmLib::StrToEpoch($report_time) <= EsmLib::StrToEpoch(cng_fmt_tmz($index[1]));
        }
      } @extracted;

      if (@report_contain_voyage_indexes) {

        foreach my $index_file (@report_contain_voyage_indexes) {

          $log->Info("    contains voyage index : %s\n", $index_file);

          my $index_json_handler = JsonHandler->new($log, $index_file);
          my @voy_path = split /_/, $index_json_handler->get_item(["voyage_file_path"]);
          my $update_time = $voy_path[-1];
          $update_time =~ s/.json$//;

          $log->Info("    voyage update time : %s\n", cng_fmt_tmz($update_time));
          $log->Info("    report latest time : %s\n", $latest_report_time);

          # voyage updatable?
          if ( EsmLib::StrToEpoch(cng_fmt_tmz($update_time)) < EsmLib::StrToEpoch($latest_report_time) ) {

            # update or insert voyage-contain reports
            $log->Info("    update voyage contains report start\n");

            my $voyage_json_handler = JsonHandler->new($log, $index_json_handler->get_item(["voyage_file_path"]));

            # get update monthly data
            my $message_id = $daily_handler->get_message_id();
            my $rep_id = $daily_handler->get_report_type_id();
            my $rep_str = EsmLib::EpochToStr( EsmLib::StrToEpoch($report_time), "%Y%m%d%H%M%S" );
            my $month = substr($rep_str, 4, 2);

            my $month_file = sprintf("%s/data/esm3_daily/%s/%s/%s/%s.json", $top_dir, $client_code, $imo_no, $year, $month);
            my $jh = JsonHandler->new($log, $month_file);
            my $mh = MonthlyReportHandler->new($log, $jh);
            my $m_data = $mh->search_data($message_id, $rep_id);

            my $already_voyage_judge_handler = VoyageJudgeHandler->new($log, $voyage_json_handler->get_item(["data", "include_reports"]));
            my $upsert_res = $already_voyage_judge_handler->upsert_report($m_data);

            if ($upsert_res) {

              # convert by esm_version
              $already_voyage_judge_handler->convert_start_time();

              # check whether index file name is correct or not
              if ($already_voyage_judge_handler->is_correct_index_file_name) {

                $log->Info("      changed index file name is correct\n");

                my $idx_file_changed = $already_voyage_judge_handler->get_index_file_name();

                # re-summarize voyage
                my $re_sum = VoyageDataDailyChangeReSummarizer->new($log);
                $re_sum->summarize($voyage_json_handler->get_data);

                # save voyage info
                my $old_voy_info = $index_json_handler->get_item(["voyage_file_path"]);
                my $voy_info_path = $index_json_handler->get_item(["voyage_file_path"]);
                my $latest_rep_str = '_' . EsmLib::EpochToStr( EsmLib::StrToEpoch($latest_report_time), "%Y%m%d%H%M%S" ) . '.json';
                $voy_info_path =~ s/_\d{14}\.json/$latest_rep_str/;
                $log->Info("        new voyage info path : %s\n", $voy_info_path);
                $voyage_json_handler->set_save_path($voy_info_path);
                $voyage_json_handler->save;
                unlink $old_voy_info; # delete obsolete info

                # save changed voyage index
                my $idx_jh = JsonHandler->new($log, { voyage_file_path => $voy_info_path });
                my $idx_path = sprintf("%s/%s", $ed->voyage_index_dir(), $idx_file_changed);
                $idx_jh->set_save_path($idx_path);
                $idx_jh->save;
                $log->Info("        write voyage index : %s\n", $idx_path);

                # index file name changed?
                if ($idx_file_changed ne basename($index_file)) {

                  unlink $index_file;
                  $log->Info("        delete obsolete index file : %s\n", $index_file);

                  # delete item from existing db
                  for my $i (0..$#{$existing_db}) {
                    if ($existing_db->[$i]->{idx} eq $index_file) {
                      splice @{$existing_db}, $i, 1;
                      $log->Info("        delete item from existing db\n");
                      last;
                    }
                  }
                }
              } else {

                $log->Info("      changed index file name is incorrect\n");

                my $v_info = $index_json_handler->get_item(["voyage_file_path"]);
                unlink $v_info;
                unlink $index_file;
                $log->Info("        delete incorrect index file  : %s\n", $index_file);
                $log->Info("        delete incorrect voyage file : %s\n", $v_info);

                # delete item from existing db
                for my $i (0..$#{$existing_db}) {
                  if ($existing_db->[$i]->{idx} eq $index_file) {
                    splice @{$existing_db}, $i, 1;
                    $log->Info("        delete item from existing db\n");
                    last;
                  }
                }
              }

              # trigger flag on
              $is_create_trigger = TRUE;
            }
          }
        }
      }

      ## delete obsolete voyage info
      $log->Info("  delete obsolete voyage start\n");

      $log->Info("    report year: %s\n", $year);

      foreach my $i (@{$existing_db}) {

        my $ex_idx   = $i->{idx};
        my $ex_voy_k = $i->{voy_key};

        $log->Info("    existing index      : %s\n", $ex_idx);
        $log->Info("    existing voyage key : %s\n", $ex_voy_k);

        my $ex_idx_n = basename($ex_idx);

        if (! grep { $_->{idx} =~ /$ex_idx_n/ && $_->{voy_key} eq $ex_voy_k } @{$judge_list}) {

          $log->Info("      obsolete\n");

          # delete obsolete voyage file
          my $obs_json = JsonHandler->new($log, $ex_idx);
          my $voy_path = $obs_json->get_item(["voyage_file_path"]);
          if (-f $voy_path) {

            unlink $voy_path;
            $log->Info("        delete obsolete voyage info : %s\n", $voy_path);
          } else {
            $log->Error("        voyage info not found      : %s\n", $voy_path);
          }

          # delete obsolete index file
          unlink $ex_idx;
          $log->Info("        delete obsolete index file\n");
        } else {
          $log->Info("      it is up-to-date or updatable voyage, not obsolete\n");
        }
      }

      ## save new summarize voyage
      $log->Info("  save new voyage start\n");

      if (!@{$new_summarize_results}) {
        $log->Info("    not exist save voyage\n");
      }

      foreach my $result (@{$new_summarize_results}) {

        my $new_voy_path = sprintf("%s/%s", $voyage_info_file_dir, $result->{voy_file_name});
        my $new_voy_idx_path = sprintf("%s/%s", $voyage_info_index_file_dir, $result->{voy_index_file_name});

        my $new_json = JsonHandler->new($log);

        $log->Info("    save voyage start\n");

        # save new voyage
        $new_json->set_save_path($new_voy_path);
        $new_json->set_data($result->{file_data});
        $new_json->save();
        $log->Info("      voyage info  : %s\n", $new_voy_path);

        # save new voyage index
        $new_json->set_save_path($new_voy_idx_path);
        my $index_data = { voyage_file_path => $new_voy_path };
        $new_json->set_data($index_data);
        $new_json->save();
        $log->Info("      voyage index : %s\n", $new_voy_idx_path);

        # trigger flag on
        $is_create_trigger = TRUE;
      }

      ## create trigger file
      if ($is_create_trigger) {

        $log->Info("  create annual trigger start\n");

        my $trig_file_data = {imo_no => $imo_no, client_code => $client_code, year => $year};
        my $trig_json = JsonHandler->new($log, $trig_file_data);
        my $imodcs_trig = $ed->imodcs_annual_trigger($year);
        my $eumrv_trig = $ed->eumrv_annual_trigger($year);
        $trig_json->set_save_path($imodcs_trig); $trig_json->save();
        $log->Info("    save annual trigger : %s\n", $imodcs_trig);
        $trig_json->set_save_path($eumrv_trig); $trig_json->save();
        $log->Info("    save annual trigger : %s\n", $eumrv_trig);

      }
      $res = TRUE;

    } else {

      $log->Info("  this report is not for judge voyage, exit\n");
      exit;
    }
  } else {
    $log->Error("  do not transfer RMS daily data\n");
  }
  exit $res;
}

sub cng_fmt_tmz {
  my $tm = shift;

  my $fmt_tm = sprintf("%s-%s-%sT%s:%s:%s", substr($tm, 0, 4), substr($tm, 4, 2), substr($tm, 6, 2),
    substr($tm, 8, 2), substr($tm, 10, 2), substr($tm, 12, 2));
  return $fmt_tm;
}

# Start process
eval{
  &main();
};
if($@){
  $log->Error("  Error : ".$@."\n");
}

END{
  $log->Close() if( defined( $log ) );
}

