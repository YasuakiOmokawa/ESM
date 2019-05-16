package DataFormat;

use JSON;
use Encode;
use DateTime;
use File::Path qw(mkpath);
use Data::Dumper;
use open ":utf8";
use Time::Local;
use POSIX qw(strftime);
use EsmConf;
use EsmLogger;
use EsmLib;

# コンストラクタ
sub new {
  my ($class, $log) = @_;

  my $self = bless {
    log => $log
  }, $class;

  my $path = sprintf("%s/def_emission_per_voyage_items.json", $EsmConf::DATA_FORMAT_DEF);
  my $format_result = $self->fetchingFiles($path);
  my $port_info = $self->load_port_file();

  $self->{format_def} = $format_result;
  $self->{port_info} = $port_info;

  return $self;
}

#==========================================================
# PUBLIC Function
#==========================================================
sub load_format_def {
  my $self = shift;
  my ($target_id,$display_data,$record_type) = @_;

  $self->{log}->Info("load_format_def start \n");

  my $format_def = $self->load_format_file($target_id, $record_type);
  my $port_def = $self->{port_info};

  $self->{log}->Info("load_format_def end \n");

  return $self->format_proc($format_def,$display_data,$port_def,$target_id);
}

#==========================================================
# PUBLIC Function
#==========================================================
sub range_check_proc {
  my $self = shift;
  my ($key, $value, $threshold) = @_;

  $self->{log}->Info("range_check_proc start \n");

  my $min = $threshold->{min};
  my $max = $threshold->{max};

  # min
  if ($min ne '' && $value < $min) {
    $self->{log}->Error("Input value is lower than the lower limit.\n");
    return 0;
  }
  # max
  if ($max ne '' && $value > $max) {
    $self->{log}->Error("Input value is higher than the upper limit.\n");
    return 0;
  }

  $self->{log}->Info("range_check_proc end \n");

  return 1;
}

#==========================================================
# PUBLIC Function
#==========================================================
sub range_check_proc_outside {
  my $self = shift;
  my ($key, $value, $target_id) = @_;

  $self->{log}->Info("range_check_proc_outside start \n");

  my $format_def = $self->load_format_file_outside($target_id);

  my $min = $format_def->{$key}->{threshold}->{min};
  my $max = $format_def->{$key}->{threshold}->{max};

  $self->{log}->Info("min = [%s] , max = [%s] .\n", $min, $max );

  if ($min eq '' || $max eq ''){
    return 1;
  }

  # min
  if ($min ne '' && $value < $min) {
    $self->{log}->Error("Input value is lower than the lower limit.\n");
    return 0;
  }
  # max
  if ($max ne '' && $value > $max) {
    $self->{log}->Error("Input value is higher than the upper limit.\n");
    return 0;
  }

  $self->{log}->Info("range_check_proc_outside end \n");

  return 1;
}

#==========================================================
# Private Function
#==========================================================
sub load_format_file {
  my $self = shift;
  my $target_id = shift;
  my $record_type = shift;

  $self->{log}->Info("load_format_file start \n");

  my $format_def = $self->{format_def};

  my $row_annual_key = "";
  if ($target_id eq "voyage"){
    $row_annual_key = "for_row";
    $target_id = $record_type;
  } else {
    $row_annual_key = "for_annual";
  }

  my $return_hash = {};
  foreach my $data (@{$format_def->{data}->{$row_annual_key}->{$target_id}}){
    my @key = keys(%{$data});
    $return_hash->{$key[0]} = $data->{$key[0]};
  }

  $self->{log}->Info("load_format_file end \n");

  return $return_hash;
}

#==========================================================
# Private Function
#==========================================================
sub load_format_file_outside {
  my $self = shift;
  my ($target_id) = @_;

  $self->{log}->Info("load_format_file_outside start \n");

  my $format_def = $self->{format_def};

  my $row_annual_key = "";
  if ($target_id eq "voyage" || $target_id eq "in_port"){
    $row_annual_key = "for_row";
  } else {
    $row_annual_key = "for_annual";
  }

  my $return_hash = {};
  foreach my $data (@{$format_def->{data}->{$row_annual_key}->{$target_id}}){
    my @key = keys(%{$data});
    $return_hash->{$key[0]} = $data->{$key[0]};
  }

  $self->{log}->Info("load_format_file_outside end \n");

  return $return_hash;
}

#==========================================================
# Private Function
#==========================================================
sub load_port_file {
  my $self = shift;
  my $path = sprintf("%s/wni_port_list.json", $EsmConfigWeb::ESM_TBL_DIR);

  $self->{log}->Info("load_port_file start \n");

  my $column_list = {};
  if(-f $path){
    $column_list = $self->fetchingFiles($path);
  }
  my $return_hash = {};
  foreach my $data (@{$column_list}){
    $key = $data->{AREA};
    $return_hash->{$key} = $data;
  }

  $self->{log}->Info("load_port_file end \n");

  return $return_hash;
}

#==========================================================
# Private Function for fetching files
#==========================================================
sub fetchingFiles {
  my $self = shift;
  my $path = shift;
  # ファイルのload
  my $result = undef;

  $self->{log}->Info("fetchingFiles load $path\n");

  EsmLib::LoadJson($path, \$result);

  $self->{log}->Info("fetchingFiles load finish.\n");

  return $result;
}

#==========================================================
# Private Function
#==========================================================
sub format_proc {
  my $self = shift;
  my ($format_def, $display_data, $port_def, $target_id) = @_;

  $self->{log}->Info("format_proc start \n");

  unless (defined $format_def) {
    my $format_def = $self->load_format_file_outside($target_id);
  }

  my $sum_judge_flg = '0';
  if ($display_data->{eu_mrv} eq 'summary'){
    $sum_judge_flg = '1';
  }

  while (my ($key,$value) = each(%{$format_def})) {

    if (exists($display_data->{$key})) {

      if ($key eq 'eu_mrv') {

        my $eu_mrv = $self->eu_mrv_convert_proc($display_data->{eu_mrv});
        $display_data->{eu_mrv_display} = $eu_mrv;

      } elsif ($key eq 'dep_port') {

        my $port = $self->port_convert_proc($display_data->{dep_port},$port_def);
        $display_data->{dep_port_display} = $port;

      } elsif ($key eq 'arr_port') {

        my $port = $self->port_convert_proc($display_data->{arr_port},$port_def);
        $display_data->{arr_port_display} = $port;

      } else {

        if ($display_data->{$key} eq '') {

          next;

        } else {

          # フォーマット処理
          $display_data->{$key} = $self->format($display_data->{$key},$format_def->{$key}->{format});

          if (defined $format_def->{$key}->{threshold}){

            if ($sum_judge_flg eq "0"){
              # 上下限チェック
              my $range_result = $self->range_check_proc($key, $display_data->{$key}, $format_def->{$key}->{threshold});

              if (!$range_result){
                $display_data->{$key} = $format_def->{$key}->{format}->{init_val};
              }
            }
          }
        }
      }
    } else {
      # init_value
      $display_data->{$key} = $format_def->{$key}->{format}->{init_val};

      if ($key eq 'eu_mrv'){
        $display_data->{eu_mrv_display} = $format_def->{eu_mrv_display}->{format}->{init_val};
      }

      if ($key eq 'dep_port'){
        $display_data->{dep_port_display} = $format_def->{dep_port_display}->{format}->{init_val};
      }

      if ($key eq 'arr_port'){
        $display_data->{arr_port_display} = $format_def->{arr_port_display}->{format}->{init_val};
      }
    }
  }

  $self->{log}->Info("format_proc end \n");

  return $display_data;
}

#==========================================================
# Private Function
#==========================================================
sub format {
  my $self = shift;
  my ($display_data, $format_def) = @_;

  $self->{log}->Info("format start \n");

  if ($format_def->{datetime} ne '') {
    # 日付変換処理 2018-05-20T10:00:00Z
    ($yyyy, $mm, $dd, $hh,$min,$sec) = ($display_data =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/);
    my $dt = DateTime->new(
        time_zone => 'UTC',
        year => $yyyy, month => $mm,   day => $dd,
        hour => $hh,   minute => $min, second => $sec
    );
    return $dt->strftime($format_def->{datetime} );
  } elsif ($format_def->{round} ne '') {
    # 数値桁数変換
    my $data = $self->rounding_off_proc($display_data, $format_def->{round});
    my $float_format = "%.".$format_def->{round}."f";
    return sprintf("$float_format", $data);
  }

  $self->{log}->Info("format end \n");

  return $display_data;
}

#==========================================================
# Private Function
#==========================================================
sub rounding_off_proc {
  my $self = shift;
  my $val = shift;    # 四捨五入する数
  my $col = shift;    # 小数点以下のどこまで残すか

  $self->{log}->Info("rounding_off_proc start \n");

  my $r = 10 ** $col;
  my $a = ($val > 0) ? 0.5 : -0.5;
  my $result = int($val * $r + $a) / $r;

  $self->{log}->Info("rounding_off_proc end \n");

  return $result;
}

#==========================================================
# Private Function
#==========================================================
sub rounding_off_proc_outside {
  my $self = shift;
  my ($key, $value, $target_id) = @_;

  $self->{log}->Info("rounding_off_proc_outside start \n");

  my $format_def = $self->load_format_file_outside($target_id);
  my $col = $format_def->{$key}->{format}->{round};

  if ($col ne "") {

    my $r = 10 ** $col;
    my $a = ($value > 0) ? 0.5 : -0.5;
    my $data = int($value * $r + $a) / $r;

    my $float_format = "%.".$col."f";
    return sprintf("$float_format", $data);
  }

  # roundに値が設定されていない場合何もしないで値のみ返却
  return $value;
}

#==========================================================
# Private Function
#==========================================================
sub port_convert_proc {
  my $self = shift;
  my ($display_data,$port_def) = @_;

  my $port_name = $port_def->{$display_data}->{ENAME};
  my $port_cntry = $port_def->{$display_data}->{CNTRY};
  my $result = '';

  if ($port_name && $port_cntry){
    $result = $port_name.", ".$port_cntry;
  }
  return $result;
}

#==========================================================
# Private Function
#==========================================================
sub port_convert_proc_outside {
  my $self = shift;
  my ($display_data) = @_;

  my $port_def = $self->{port_info};

  return $port_def->{$display_data}->{ENAME}.", ".$port_def->{$display_data}->{CNTRY};
}

#==========================================================
# Private Function
#==========================================================
sub eu_mrv_convert_proc {
  my $self = shift;
  my $eu_mrv = shift;

  $self->{log}->Info("eu_mrv_convert_proc \n");

  if($eu_mrv eq 'dep_from_eu_port') {
    return 'from EU';
  } elsif ($eu_mrv eq 'arr_at_eu_port') {
    return 'to EU';
  } elsif ($eu_mrv eq 'eu_to_eu') {
    return 'EU to EU';
  } elsif ($eu_mrv eq 'in_eu_port') {
    return 'In EU port';
  } elsif ($eu_mrv eq 'beginning_of_year') {
    return 'beginning of year';
  } elsif ($eu_mrv eq 'end_of_year') {
    return 'end of year';
  } elsif ($eu_mrv eq 'middle_of_year') {
    return 'middle of year';
  } elsif ($eu_mrv eq 'summary') {
    return 'Total';
  } else {
    return '---';
  }
}

1;