#! /usr/local/bin/perl
# $Id: data_format_test_sample.t 35732 2019-01-18 06:02:06Z p0660 $

use strict;
use warnings;

use Capture::Tiny qw/ capture /;
use Test::More;
use Test::Exception;
use Data::Dumper;
use Benchmark;
use File::Basename;
use POSIX qw(strftime);
use constant { TRUE => 1, FALSE => 0 };
use Test::Deep;
use Test::Deep::Matcher;
use Test::Differences;

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";
use lib '/usr/amoeba/lib/perl';

use logging;

# test module
use DataFormat;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $debug_path = '/usr/home/partner/p0660/test_data_v3/';
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;
my $test_data_dir = "$top_dir/t/data/$prog_base";
my $test_out_dir = "$top_dir/t/out";

my $log  = logging->Open( $log_fname ) ;

###############################
# input data
###############################
my $voyage_rec_upper_limit = {
          'voyage_number' => '1801',
          'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
          'eu_mrv' => 'dep_from_eu_port',
          'record_type' => 'voyage',
          'dep_port' => 'MLG',
          'dep_date_time' => '2018-07-04T11:00:00Z',
          'arr_port' => 'KOB',
          'arr_date_time' => '2018-07-20T10:00:00Z',
          'distance_travelled' => '100000',
          'time_at_sea' => '10000.0',
          'hours_underway' => '10000.0',
          'foc_dogo'  => '10000.00',
          'foc_lfo'   => '10000.00',
          'foc_hfo'   => '10000.00',
          'foc_other' => '10000.00',
          'co2_dogo'  => '1000.00',
          'co2_lfo'   => '100000.00',
          'co2_hfo'   => '100000.00',
          'co2_other' => '100000.00',
          'cargo_weight' => '1000000',
          'passenger' => '1000000',
          'unit' => '1000000',
          'cars' => '1000000',
          'dwt_carried' => '1000000',
          'volume' => '1000000',
          'transport_work' => '100000000',
          'foc_dogo_per_distance' => '1.0000',
          'foc_lfo_per_distance' => '1.0000',
          'foc_hfo_per_distance' => '1.0000',
          'foc_other_per_distance' => '1.0000',
          'foc_dogo_per_transport_work'  => '0.00010000',
          'foc_lfo_per_transport_work'   => '0.00010000',
          'foc_hfo_per_transport_work'   => '0.00010000',
          'foc_other_per_transport_work' => '0.00010000',
          'co2_per_distance' => '1.0000',
          'eeoi' => '0.00010000'
};

# test
subtest "data format upper limit test" => sub {

  # この↓の2つの変数は、試験ごとに変える事
  my $get_target_id = 'voyage';
  my $record_type = 'voyage';
  # データフォーマットインスタンス生成
  my $data_format = DataFormat->new($log);
  my $result = $data_format->load_format_def($get_target_id, $voyage_rec_upper_limit, $record_type);

    eq_or_diff(
      [
        $result->{voyage_number},
        $result->{voyage_key},
        $result->{eu_mrv},
        $result->{eu_mrv_display},
        $result->{record_type},
        $result->{dep_port},
        $result->{dep_port_display},
        $result->{dep_date_time},
        $result->{arr_port},
        $result->{arr_port_display},
        $result->{arr_date_time},
        $result->{distance_travelled},
        $result->{time_at_sea},
        $result->{hours_underway},
        $result->{foc_dogo},
        $result->{foc_lfo},
        $result->{foc_hfo},
        $result->{foc_other},
        $result->{co2_dogo},
        $result->{co2_lfo},
        $result->{co2_hfo},
        $result->{co2_other},
        $result->{cargo_weight},
        $result->{passenger},
        $result->{unit},
        $result->{cars},
        $result->{dwt_carried},
        $result->{volume},
        $result->{transport_work},
        $result->{foc_dogo_per_distance},
        $result->{foc_lfo_per_distance},
        $result->{foc_hfo_per_distance},
        $result->{foc_other_per_distance},
        $result->{foc_dogo_per_transport_work},
        $result->{foc_lfo_per_transport_work},
        $result->{foc_hfo_per_transport_work},
        $result->{foc_other_per_transport_work},
        $result->{co2_per_distance},
        $result->{eeoi}
      ],
      [
        '1801',
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'dep_from_eu_port',
        'from EU',
        'voyage',
        'MLG',
        'MALAGA, ES',
        '07/04 11:00',
        'KOB',
        'KOBE, JP',
        '07/20 10:00',
        '',
        '',
        '',
        '***',
        '***',
        '***',
        '',
        '***',
        '***',
        '***',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '***',
        '***',
        '***',
        '***',
        '***',
        '***',
        '***',
        '***',
        '***',
        '***',
        '***'
      ], 'upper limit diff ok');

  done_testing;
};

subtest "sisyagonyuu outside test" => sub {

  my $key = 'foc_hfo';
  my $value = '100.005';
  my $target_id = 'voyage';

  my $df = DataFormat->new($log);
  is($df->rounding_off_proc_outside($key, $value, $target_id), '100.01', 'result ok');

  done_testing;
};


done_testing;



