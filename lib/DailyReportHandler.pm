package DailyReportHandler;

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

use EsmLib;
use EsmConf;
use JsonHandler;

sub new {
  my ($class, $log, $data) = @_;

  $data = ref($data) eq "JsonHandler" ? $data : JsonHandler->new($log, $data);

  my $self = bless {
    log => $log,
    data => $data
  }, $class;

  return $self;
}

sub get_imo_number {
  my $self = shift;

  my $keys = ["calc", "imo_num_repo"];
  return $self->_get_report_value($keys);
}

sub get_client_code {
  my $self = shift;

  my $keys = ["calc", "data_path"];
  my $value = $self->_get_report_value($keys);

  my @f = split /\//, $value;

  return $f[0];
}

sub get_report_year {
  my $self = shift;

  return substr($self->get_report_time, 0, 4);
}

sub get_report_type_repo {
  my $self = shift;

  my $keys = ["report_info", "report_type_repo"];
  return $self->_get_report_value($keys);
}

sub get_message_id {
  my $self = shift;

  my $keys = ["report_info", "messageid"];
  my $value = $self->_get_report_value(["raw", "messageid"]) ? $self->_get_report_value(["raw", "messageid"]) : $self->_get_report_value($keys);

  return $value;
}

sub get_latest_report_time {
  my $self = shift;

  my $value = "";

  my $customs = $self->_get_report_value(["custom"]);
  my $upd = $self->_get_report_value(["report_info", "updated_at"]);
  my $cus = "";

  if (@$customs && $customs->[$#{$customs}]->{exec_time}) {
    $cus = $customs->[$#{$customs}]->{exec_time};
  };

  $value = $cus && (EsmLib::StrToEpoch($cus) > EsmLib::StrToEpoch($upd)) ? $cus : $upd;

  return $value;
}

sub get_report_time {
  my $self = shift;

  my $keys = ["calc", "report_time"];
  return $self->_get_report_value($keys);
}

sub get_for_judge_voyage {
  my $self = shift;

  my $keys = ["report_info", "for_judge_voyage"];
  return $self->_get_report_value($keys);
}

sub is_invalid {
  my $self = shift;

  my $res = FALSE;

  my $keys = ["report_info", "invalid"];
  my $value = $self->_get_report_value($keys);

  if ($value && $value eq 'true') { $res = TRUE; }

  return $res;
}

sub get_start_time {
  my $self = shift;

  my $keys = ["calc", "start_time"];
  return $self->_get_report_value($keys);
}

sub get_report_type {
  my $self = shift;

  my $keys = ["report_info", "report_type"];
  return $self->_get_report_value($keys);
}

sub get_dep_berth_time {
  my $self = shift;

  my $keys = ["calc", "dep_berth_time"];
  return $self->_get_report_value($keys);
}

sub get_noon_time {
  my $self = shift;

  my $keys = ["calc", "noon_time"];
  return $self->_get_report_value($keys);
}

sub get_ship_info {
  my $self = shift;

  return $self->{data}->get_item(["ship_info"]);
}

sub get_drft_start_time {
  my $self = shift;

  my $keys = ["calc", "drft_start_time"];
  return $self->_get_report_value($keys);
}

sub get_drft_end_time {
  my $self = shift;

  my $keys = ["calc", "drft_end_time"];
  return $self->_get_report_value($keys);
}

sub get_anch_start_time {
  my $self = shift;

  my $keys = ["calc", "anch_start_time"];
  return $self->_get_report_value($keys);
}

sub get_anch_end_time {
  my $self = shift;

  my $keys = ["calc", "anch_end_time"];
  return $self->_get_report_value($keys);
}

sub get_bunkering_start_time {
  my $self = shift;

  my $keys = ["calc", "bunkering_start_time"];
  return $self->_get_report_value($keys);
}

sub get_bunkering_end_time {
  my $self = shift;

  my $keys = ["calc", "bunkering_end_time"];
  return $self->_get_report_value($keys);
}

sub get_raw_report_time {
  my $self = shift;

  my $keys = ["raw", "report_time"];
  return $self->_get_report_value($keys);
}

sub get_arr_berth_time {
  my $self = shift;

  my $keys = ["calc", "arr_berth_time"];
  return $self->_get_report_value($keys);
}

sub get_status {
  my $self = shift;

  my $keys = ["report_info", "status"];
  return $self->_get_report_value($keys);
}

sub get_esm_status {
  my $self = shift;

  my $keys = ["raw", "esm_status"];
  return $self->_get_report_value($keys);
}

sub get_raw_dep_berth_time {
  my $self = shift;

  my $keys = ["raw", "dep_berth_time"];
  return $self->_get_report_value($keys);
}

sub get_inport_time {
  my $self = shift;

  my $keys = ["raw", "arrtodep_total_hours"];
  return $self->_get_report_value($keys);
}

sub get_raw_arr_berth_time {
  my $self = shift;

  my $keys = ["raw", "arr_berth_time"];
  return $self->_get_report_value($keys);
}

sub get_berth_berth_total_hours {
  my $self = shift;

  my $keys = ["raw", "berth_berth_total_hours"];
  return $self->_get_report_value($keys);
}

sub get_steaming_time {
  my $self = shift;

  my $keys = ["calc", "steaming_time"];
  return $self->_get_report_value($keys);
}

sub get_interchange_steaming_hours {
  my $self = shift;

  my $keys = ["calc", "interchange_steaming_hours"];
  return $self->_get_report_value($keys);
}

sub get_arr_eosp_steaming_hours {
  my $self = shift;

  my $keys = ["raw", "arr_eosp_steaming_hours"];
  return $self->_get_report_value($keys);
}

sub get_eosp_berth_steaming_hours {
  my $self = shift;

  my $keys = ["raw", "eosptoberth_steaming_hours"];
  return $self->_get_report_value($keys);
}

sub get_report_type_id {
  my $self = shift;

  my $keys = ["report_info", "report_type_id"];
  return $self->_get_report_value($keys);
}

sub get_calc_report_type {
  my $self = shift;

  my $keys = ["calc", "report_type"];
  return $self->_get_report_value($keys);
}

sub get_time_spent_hours {
  my $self = shift;

  my $keys = ["calc", "time_spent_hours"];
  return $self->_get_report_value($keys);
}

# Appended by toyohiro@wni.com at 2019/02/27
sub _get_dep_berth_lat {
  my $self = shift;

  my $keys = ["raw", "dep_berth_lat"];
  return $self->_get_report_value($keys);
}

# Appended by toyohiro@wni.com at 2019/02/27
sub _get_dep_berth_lon {
  my $self = shift;

  my $keys = ["raw", "dep_berth_lon"];
  return $self->_get_report_value($keys);
}

# Appended by toyohiro@wni.com at 2019/02/27
sub _get_pos_lat {
  my $self = shift;

  my $keys = ["raw", "pos_lat"];
  return $self->_get_report_value($keys);
}

# Appended by toyohiro@wni.com at 2019/02/27
sub _get_pos_lon {
  my $self = shift;

  my $keys = ["raw", "pos_lon"];
  return $self->_get_report_value($keys);
}

sub _get_report_value {
  my $self = shift;

  my $keys = shift;
  my $data = $self->{data}->get_item(["data"]);
  my $value = $data ? $self->{data}->get_item($keys, $data->[$#{$data}]) # daily
              : $self->{data}->get_item($keys); # monthly

  return $value;
}

sub set_report_value {
  my $self = shift;
  my ($keys, $value) = @_;
  my $res = TRUE;

  my $data = $self->{data}->get_item(["data"]);
  if ($data) {

    # set to daily data
    $self->{data}->set_item($keys, $value, $data->[$#{$data}]);
  } else {

    # set to monthly report data
    $self->{data}->set_item($keys, $value);
  }

  return $res;
}

sub get_esm_version {
  my $self = shift;

  my $keys = ["calc", "esm_version"];
  return $self->_get_report_value($keys);
}

sub get_status_repo_type {
  my $self = shift;

  my $keys = ["raw", "status_repo_type"];
  return $self->_get_report_value($keys);
}

sub is_not_save {
  my $self = shift;

  my $res = FALSE;

  my $keys = ["report_info", "is_not_save"];
  my $value = $self->_get_report_value($keys);

  if (defined $value && $value) { $res = TRUE; }

  return $res;
}

1;