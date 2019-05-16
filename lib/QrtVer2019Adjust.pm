package QrtVer2019Adjust;

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
use EsmLib;
use DailyReportHandler;

sub new {
  my ($class, $log, $data) = @_;

  $data = ref($data) eq "DailyReportHandler" ? $data : DailyReportHandler->new($log, $data);

  my $self = bless {
    log => $log,
    data => $data,
  }, $class;

  return $self;
}

sub interchange {
  my $self = shift;

  $self->_add_flag_for_judge_voyage;
  $self->_set_report_time;
  $self->_completion_start_time;
  $self->_interchange_report_categories;
  $self->_interchange_lat_lon;

  if ($self->{data}->get_esm_status
    && $self->{data}->get_esm_status eq $EsmConf::BERTHING_STATUS) {

    $self->_summarize_report_terms;
    $self->_interchange_berth_items;
  }
}

sub _add_flag_for_judge_voyage {
  my $self = shift;

  my $value = $self->{data}->get_report_type eq $EsmConf::DEPARTURE_REPORT                        ? 'voyage_start'
            : $self->{data}->get_esm_status eq $EsmConf::BERTHING_STATUS                          ? 'voyage_end'
            : $EsmConfigWeb::ANCHORING_END_REPORT_REPO_TABLE{$self->{data}->get_report_type_repo}
              && $self->{data}->get_report_type_id eq $EsmConf::ANCHORING_START_REPORT_TYPE_ID    ? 'anchor_start'
            : $EsmConfigWeb::ANCHORING_END_REPORT_REPO_TABLE{$self->{data}->get_report_type_repo}
              && $self->{data}->get_report_type_id ne $EsmConf::ANCHORING_START_REPORT_TYPE_ID    ? 'anchor_end'
            : "";

  $self->{data}->set_report_value(["report_info", "for_judge_voyage"], $value);
}

sub _set_report_time {
  my $self = shift;

  my $value = $self->{data}->get_report_type      eq $EsmConf::DEPARTURE_REPORT                   ? $self->{data}->get_dep_berth_time
            : $self->{data}->get_report_type      eq $EsmConf::NOON_REPORT                        ? $self->{data}->get_noon_time
            : $EsmConfigWeb::DRIFTING_END_REPORT_REPO_TABLE{$self->{data}->get_report_type_repo}
              && $self->{data}->get_report_type_id eq $EsmConf::DRIFTING_START_REPORT_TYPE_ID     ? $self->{data}->get_drft_start_time
            : $EsmConfigWeb::DRIFTING_END_REPORT_REPO_TABLE{$self->{data}->get_report_type_repo}
              && $self->{data}->get_report_type_id ne $EsmConf::DRIFTING_START_REPORT_TYPE_ID     ? $self->{data}->get_drft_end_time
            : $EsmConfigWeb::ANCHORING_END_REPORT_REPO_TABLE{$self->{data}->get_report_type_repo}
              && $self->{data}->get_report_type_id eq $EsmConf::ANCHORING_START_REPORT_TYPE_ID    ? $self->{data}->get_anch_start_time
            : $EsmConfigWeb::ANCHORING_END_REPORT_REPO_TABLE{$self->{data}->get_report_type_repo}
              && $self->{data}->get_report_type_id ne $EsmConf::ANCHORING_START_REPORT_TYPE_ID    ? $self->{data}->get_anch_end_time
            : $self->{data}->get_report_type_repo eq $EsmConf::BUNKERING_REPORT_REPO
              && $self->{data}->get_report_type_id eq $EsmConf::BUNKERING_REPORT_TYPE_ID          ? $self->{data}->get_bunkering_end_time
            : $self->{data}->get_report_type_repo eq $EsmConf::CARGO_INFORMATION_REPORT_REPO      ? $self->{data}->get_raw_report_time
            : $self->{data}->get_esm_status eq $EsmConf::BERTHING_STATUS                          ? $self->{data}->get_arr_berth_time # this class only
            : "";

  if ($value){
    $self->{data}->set_report_value(["calc", "report_time"], $value);
  }
}

sub _completion_start_time {
  my $self = shift;

  my $value = $self->{data}->get_report_type eq $EsmConf::DEPARTURE_REPORT
                && $self->{data}->get_raw_dep_berth_time
                && $self->{data}->get_inport_time                        ? EsmLib::EpochToStr(EsmLib::StrToEpoch($self->{data}->get_raw_dep_berth_time) - ($self->{data}->get_inport_time * 60))
            : $self->{data}->get_esm_status eq $EsmConf::BERTHING_STATUS
                && $self->{data}->get_raw_dep_berth_time                 ? $self->{data}->get_raw_dep_berth_time
            : $self->{data}->get_esm_status eq $EsmConf::BERTHING_STATUS
                && !$self->{data}->get_raw_dep_berth_time
                && $self->{data}->get_raw_arr_berth_time
                && $self->{data}->get_berth_berth_total_hours            ? EsmLib::EpochToStr(EsmLib::StrToEpoch($self->{data}->get_raw_arr_berth_time) - ($self->{data}->get_berth_berth_total_hours * 60))
            : "";

  $self->{data}->set_report_value(["calc", "start_time"], $value);
}

sub _interchange_report_categories {
  my $self = shift;

  if ($self->{data}->get_report_type eq $EsmConf::ARRIVAL_REPORT
    && $self->{data}->get_esm_status && $self->{data}->get_esm_status eq $EsmConf::BERTHING_STATUS) {

    $self->{data}->set_report_value(["report_info", "report_type"], $EsmConf::STATUS_REPORT);
    $self->{data}->set_report_value(["report_info", "status"], $EsmConf::BERTHING_STATUS);
    $self->{data}->set_report_value(["calc", "report_type"], $EsmConf::STATUS_REPORT);
  }
}

sub _summarize_report_terms {
  my $self = shift;

  # BUG-099 : Does not calculation for steaming_time. Delete 'steaming_time' value.
  my @items = qw/steaming_distance time_spent_hours
              cons_total_ls-hfo cons_total_hs-hfo cons_total_ls-lfo
              cons_total_ulsfo cons_total_ulsdogo cons_total_hsdo
              cons_total_lsdo cons_total_hsgo cons_total_lsgo/;
  my @ext  = $self->_extract_no_edit_items(\@items);
  my @loop = @ext;

  for my $i (@loop) {

    my @args;
    @args = map { $self->_convert_zero_but_true($_) } (
      $self->{data}->_get_report_value(["raw", "arr_eosp_${i}"]),
      $self->{data}->_get_report_value(["raw", "eosptoberth_${i}"])
    );

    $self->{data}->set_report_value(["calc", "$i"], EsmLib::CalcSum(@args));

    $self->{log}->Info( "  Calc [arr_eosp_" . ${i} . "][" . $args[0] . "] + [eosptoberth_" . $i . + "][" . $args[1] . "] = [" . $i . "][" . $self->{data}->_get_report_value(["calc", "${i}"] ) . "])\n" );
  }

  # BUG-099 : Does not calculation for steaming_time. 
  # For 'steaming_time' calculatin. This is special logic.
  my @args;
  @args = map { $self->_convert_zero_but_true($_) } (
      $self->{data}->_get_report_value(["raw", "arr_eosp_steaming_hours"]),
      $self->{data}->_get_report_value(["raw", "eosptoberth_steaming_hours"])
  );
  $self->{data}->set_report_value(["calc", "steaming_time"], EsmLib::CalcSum(@args));

  $self->{log}->Info( "  Calc [arr_eosp_steaming_hours][" . $args[0] . "] + [eosptoberth_steaming_hours][" . $args[1] . "] = [steaming_time][" . $self->{data}->_get_report_value(["calc", "steaming_time"] ) . "])\n" );
}

sub _interchange_berth_items {
  my $self = shift;

  my @items = grep { /^berth_berth_/ } keys(%{$self->{data}->_get_report_value(["raw"])});
  my @ext   = $self->_extract_no_edit_items(\@items);
  my @loop  = @ext;

  for my $i (@loop) {

    $self->{data}->set_report_value(["calc", "$i"],
      $self->_convert_zero_but_true($self->{data}->_get_report_value(["raw", "$i"])));
  }
}

# Set Lat/Lon for ESM
sub _interchange_lat_lon {
  my $self = shift;

  my $lat = undef;
  my $lon = undef;
  my $lat_msg = "";
  my $lon_msg = "";

  # Get dep_berth_{lat,lon} at Departure Report
  if ($self->{data}->get_report_type eq $EsmConf::DEPARTURE_REPORT){
    $lat = $self->{data}->_get_dep_berth_lat ;
    $lon = $self->{data}->_get_dep_berth_lon ;
    $lat_msg = "dep_berth_lat";
    $lon_msg = "dep_berth_lon";
  }

  # Get pos_{lat,lon} at without Departure report or can't get dep_berth_{lat,lon}
  if (!$lat){
    $lat = $self->{data}->_get_pos_lat ;
    $lat_msg = "pos_lat";
  }
  if (!$lon){
    $lon = $self->{data}->_get_pos_lon ;
    $lon_msg = "pos_lon";
  }

  # Convert/Set lat/lon string (-99999.9 to DDD-mm.m{EWNS})
  if ($lat){
    my $value = EsmLib::MinToLatLon_sec( $lat, 'lat', $self->{log} );
    $self->{data}->set_report_value(["calc", "lat"], $value);
    $self->{log}->Info( "  Convert Lat [$lat_msg][$lat] to [$value]\n" );
  }
  if ($lon){
    my $value = EsmLib::MinToLatLon_sec( $lon, 'lon', $self->{log} );
    $self->{data}->set_report_value(["calc", "lon"], $value);
    $self->{log}->Info( "  Convert Lon [$lon_msg][$lon] to [$value]\n" );
  }
}

sub _ext_no_edit {
  my $self = shift;

  my ($a, $b) = @_;
  my @res;

  for my $i (@{$a}) {
    push @res, $i if !grep {/^$i$/} @{$b};
  }
  return @res;
}

sub _convert_zero_but_true {
  my $self = shift;

  my $v = shift;

  return $v eq ZERO_BUT_TRUE ? "0" : $v if $v;
}

sub _extract_no_edit_items {
  my $self = shift;

  my $items = shift;
  my @customs = ();
  my @ext     = @$items;

  if (@{$self->{data}->_get_report_value(["custom"])}) {

    @customs = map { $_->{calc_key} } @{$self->{data}->_get_report_value(["custom"])};
    if (@customs) {
      @ext = $self->_ext_no_edit($items, \@customs);
    }
  }
  return @ext;
}

1;
