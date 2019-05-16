package EsmDataDetector;

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

# Static settings
my $top_dir = dirname(__FILE__) . "/..";

sub new {
  my ($class, $log, $client_code, $imo_no) = @_;

  my $self = bless {
    log => $log,
    client_code => $client_code,
    imo_no => $imo_no
  }, $class;

  return $self;
}

sub imo_dcs_annual {
  my $self = shift;

  my $year = shift;

  my $res = "";
  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  my $path = sprintf("%s/data/annual/%s/%s/%s/imo_dcs_annual.json", $top_dir, $client_code, $imo_no, $year);

  $self->{log}->Info("  imo_dcs_annual_path: %s\n", $path);

  if (-f $path) {
    $res = $path;
  } else {
    $self->{log}->Info("  file not found: %s\n", $path);
  }

  return $res;
}

sub annual_path {
  my $self = shift;

  my $year = shift;

  my $res;

  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  my $path = sprintf("%s/data/annual/%s/%s/%s", $top_dir, $client_code, $imo_no, $year);

  $self->{log}->Info("  annual_dir: %s\n", $path);

  $res = $path;
  return $res;
}

sub voyage_info {
  my $self = shift;

  my $voy_key = shift;

  my $res = "";
  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  my $dir = $self->voyage_info_dir;

  $self->{log}->Info("  voyage info search path: %s\n", $dir);

  if (-d $dir) {

    my $exp = sprintf("%s/%s*", $dir, $voy_key);
    my @files = glob($exp);

    if (@files && scalar(@files) == 1) {
      $res = $files[0];
    } else {
      $self->{log}->Info("  voyage info not found\n");
    }
  } else {
    $self->{log}->Info("  directory not found: %s\n", $dir);
  }

  return $res;
}

sub voyage_edit_path {
  my $self = shift;

  my $voy_key = shift;
  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  return sprintf("%s/data/esm3_voyage/%s/%s/edit/%s_edit.json", $top_dir, $client_code, $imo_no, $voy_key);
}

sub imodcs_annual_trigger {
  my $self = shift;

  my $year = shift;
  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  return sprintf("%s/spool/annual_spool/%s/%s/imodcs_%s_%s.json", $top_dir, $client_code, $imo_no, $imo_no, $year);
}

sub eumrv_annual_trigger {
  my $self = shift;

  my $year = shift;
  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  return sprintf("%s/spool/annual_spool/%s/%s/eumrv_%s_%s.json", $top_dir, $client_code, $imo_no, $imo_no, $year);
}

sub voyage_index_dir {
  my $self = shift;

  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  return sprintf("%s/data/esm3_voyage/%s/%s/voyage_index", $top_dir, $client_code, $imo_no);
}

sub voyage_info_dir {
  my $self = shift;

  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  return sprintf("%s/data/esm3_voyage/%s/%s/voyage", $top_dir, $client_code, $imo_no);
}

sub voyage_edit {
  my $self = shift;

  my $voy_key = shift;

  my $res = "";
  my $client_code = $self->{client_code};
  my $imo_no = $self->{imo_no};

  my $dir = sprintf("%s/data/esm3_voyage/%s/%s/edit", $top_dir, $client_code, $imo_no);

  $self->{log}->Info("  voyage edit search path: %s\n", $dir);

  if (-d $dir) {

    my $exp = sprintf("%s/%s*", $dir, $voy_key);
    my @files = glob($exp);

    if (@files && scalar(@files) == 1) {
      $res = $files[0];
    } else {
      $self->{log}->Info("  voyage edit not found\n");
    }
  } else {
    $self->{log}->Info("  directory not found: %s\n", $dir);
  }

  return $res;
}

sub template_edit_voyage {

  return sprintf("%s/conf/esm3_voyage/template_edit_voyage.json", $top_dir);
}

sub template_eu_mrv_annual {

  return sprintf("%s/conf/esm3_voyage/template_eu_mrv_annual.json", $top_dir);
}

sub template_imo_dcs_annual {

  return sprintf("%s/conf/esm3_voyage/template_imo_dcs_annual.json", $top_dir);
}

sub template_voyage_info {

  return sprintf("%s/conf/esm3_voyage/template_summarize_voyage.json", $top_dir);
}

sub def_emission_per_voyage_items {

  return sprintf("%s/conf/esm3_voyage/def_emission_per_voyage_items.json", $top_dir);
}

sub eu_country {

  return sprintf("%s/conf/EU_country.json", $top_dir);
}

sub wni_port_list {

  return sprintf("%s/tbl/wni_port_list.json", $top_dir);
}

sub create_eumrv_annual_data_program {

  return sprintf("%s/bin/annual/create_eumrv_annual_data.pl", $top_dir);
}

sub create_imodcs_annual_data_program {

  return sprintf("%s/bin/annual/create_imodcs_annual_data.pl", $top_dir);
}

sub judge_voyage_program {

  return sprintf("%s/bin/esm3_voyage/judge_voyage.pl", $top_dir);
}


1;