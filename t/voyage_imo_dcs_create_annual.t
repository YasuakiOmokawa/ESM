# $Id: voyage_imo_dcs_create_annual.t 36117 2019-03-06 06:18:09Z p0660 $

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
use JsonHandler;
use VoyageImoDcsCreateAnnual;
use EsmDataDetector;

# Static settings
my $top_dir = dirname(__FILE__) . "/..";
my $prog_name = basename(__FILE__);
my $proc_time = time;
my $local_time = strftime("%Y%m%d%H%M%S", localtime($proc_time));
my $ymd = substr($local_time, 0, 8);
my $log_fname = sprintf( "%s/log/%s.%d.log", $top_dir, $prog_name, $ymd );
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;
my $test_data_dir = "$top_dir/t/data/$prog_base";

my $log  = logging->Open( $log_fname ) ;

my $start_msg = "=== Subtest %s Start ===\n";
my $end_msg   = "=== Subtest %s End   ===\n";
my $name;
my $num;
my $func;

# test
$num = '1';
$func = '_judge_year_over';
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # $DB::single = 1; # ブレークポイント
  my $res = get_judge_year_over_res({year => '2018', voyage_data => '1.json'});
  is($res, 'beginning_of_year', 'this voyage is beggining of year');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '2';
$func = '_judge_year_over';
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # $DB::single = 1; # ブレークポイント
  my $res = get_judge_year_over_res({year => '2018', voyage_data => '2.json'});
  is($res, 'end_of_year', 'this voyage is end of year');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '3';
$func = '_judge_year_over';
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # $DB::single = 1; # ブレークポイント
  my $res = get_judge_year_over_res({year => '2018', voyage_data => '3.json'});
  is($res, 'middle_of_year', 'this voyage is middle of year');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '4';
$func = '_judge_year_over';
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # $DB::single = 1; # ブレークポイント
  my ($stdout, $stderr) = capture {
    my $res = get_judge_year_over_res({year => '2018', voyage_data => '4.json'});
    is($res, 'middle_of_year', 'this voyage is middle of year');
  };
  like($stderr, qr/can not get all parameter for judge year over/, 'start year undefined');

  $log->Info($end_msg, $name);
  done_testing;
};

$num = '5';
$func = '_judge_year_over';
$name = "$func - $num";
subtest $name => sub {

  $log->Info($start_msg, $name);

  # $DB::single = 1; # ブレークポイント
  my ($stdout, $stderr) = capture {
    my $res = get_judge_year_over_res({year => '2018', voyage_data => '5.json'});
    is($res, 'middle_of_year', 'this voyage is middle of year');
  };
  like($stderr, qr/can not get all parameter for judge year over/, 'end year undefined');

  $log->Info($end_msg, $name);
  done_testing;
};

$func = '_calc_begin';
$num  = '1';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  my $res = get_calc_begin_res({year => '2018', voyage_data => "$num.json"});
  is($res->{data}{beginning_of_year}{data}{foc_lfo}, 1.33333333333333, 'valid calculation');

  $log->Info($end_msg, $name);
  done_testing;
};

$func = '_calc_begin';
$num  = '2';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  throws_ok {
    get_calc_begin_res({year => '2018', voyage_data => "$num.json"})
  } qr/there is no required parameter/, 'lack of end time';

  $log->Info($end_msg, $name);
  done_testing;
};

$func = '_calc_begin';
$num  = '3';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  throws_ok {
    get_calc_begin_res({year => '2018', voyage_data => "$num.json"})
  } qr/there is no required parameter/, 'lack of start time';

  $log->Info($end_msg, $name);
  done_testing;
};

$func = '_calc_begin';
$num  = '4';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  throws_ok {
    get_calc_begin_res({year => '2018', voyage_data => "$num.json"})
  } qr/there is no required key/, 'there is no key';

  $log->Info($end_msg, $name);
  done_testing;
};

$func = '_calc_middle';
$num  = '1';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  my $res = get_calc_middle_res({year => '2018', voyage_data => "$num.json"});
  is($res->{foc_lfo}, 4, 'foc_lfo valid');
  cmp_ok($res->{foc_hfo}, '==', '0', 'foc_hfo valid');

  $log->Info($end_msg, $name);
  done_testing;
};

$func = '_calc_middle';
$num  = '2';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  throws_ok {
    get_calc_middle_res({year => '2018', voyage_data => "$num.json"})
  } qr/there is no required key/, 'there is no key';

  $log->Info($end_msg, $name);
  done_testing;
};

$func = '_calc_end';
$num  = '1';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  my $res = get_calc_end_res({year => '2018', voyage_data => "$num.json"});
  is($res->{foc_lfo}, 1.33333333333333, 'valid calculation');

  $log->Info($end_msg, $name);
  done_testing;
};

$num  = '2';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  throws_ok {
    get_calc_end_res({year => '2018', voyage_data => "$num.json"})
  } qr/there is no required parameter/, 'lack of end time';

  $log->Info($end_msg, $name);
  done_testing;
};

$num  = '3';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  throws_ok {
    get_calc_end_res({year => '2018', voyage_data => "$num.json"})
  } qr/there is no required parameter/, 'lack of start time';

  $log->Info($end_msg, $name);
  done_testing;
};

$num  = '4';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  throws_ok {
    get_calc_end_res({year => '2018', voyage_data => "$num.json"})
  } qr/there is no required key/, 'there is no key';

  $log->Info($end_msg, $name);
  done_testing;
};

$func = 'new(constructor)';
$num  = '1';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  my ($add, $year, $cli_code, $imo_no) = ([], '2018', undef, '1234567');
  throws_ok {
    VoyageImoDcsCreateAnnual->new($log, $add, $year, $cli_code, $imo_no);
  } qr/there is no required parameter/, 'lack of client code';

  $log->Info($end_msg, $name);
  done_testing;
};

$num  = '2';
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  my ($add, $year, $cli_code, $imo_no) = ([], '2018', 'CBA', '');
  throws_ok {
    VoyageImoDcsCreateAnnual->new($log, $add, $year, $cli_code, $imo_no);
  } qr/there is no required parameter/, 'lack of imo number';

  $log->Info($end_msg, $name);
  done_testing;
};

$num  = 3;
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  my ($add, $year, $cli_code, $imo_no) = ([], "", 'CBA', '1234567');
  throws_ok {
    VoyageImoDcsCreateAnnual->new($log, $add, $year, $cli_code, $imo_no);
  } qr/there is no required parameter/, 'lack of year';

  $log->Info($end_msg, $name);
  done_testing;
};

$func = 'totalize';
$num  = 1;
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);
# $ENV{a} = 1; # 条件付きブレークポイント用の環境変数設定
  my $res = get_totalize_res({year => '2018', voyage_data => "$num.json"});
  # print Dumper $res;

  # データ構造が想定通りか？
  cmp_deeply($res,
    +{
      data => {
        beginning_of_year => { data => is_hash_ref },
        middle_of_year => { data => is_hash_ref },
        end_of_year => { data => is_hash_ref },
        summary => { data => is_hash_ref },
        ship_info => is_hash_ref,
      }
    }, 'data structure');

  # データの値は想定通りか？
  eq_or_diff(
    [
      $res->{data}{beginning_of_year}{data}{foc_dogo},
      $res->{data}{middle_of_year}{data}{foc_dogo},
      $res->{data}{end_of_year}{data}{foc_dogo},
      $res->{data}{summary}{data}{foc_dogo},
      $res->{data}{summary}{data}{foc_lfo},
    ],
    [
      undef,
      undef,
      undef,
      undef,
      undef,
    ],
    'removed item exceed over a limit'
  );
  cmp_deeply(
    [
      $res->{data}{beginning_of_year}{data}{foc_lfo},
      $res->{data}{middle_of_year}{data}{foc_lfo},
      $res->{data}{end_of_year}{data}{foc_lfo},
      $res->{data}{middle_of_year}{data}{foc_hfo},
    ],
    [
      is_value,
      is_value,
      is_value,
      '2.00',
    ],
    'exists item under a limit'
  );

  $log->Info($end_msg, $name);
  done_testing;
};

$num  = 2;
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);
# $ENV{a} = 1; # 条件付きブレークポイント用の環境変数設定
  my $res = get_totalize_res({year => '2018', voyage_data => "$num.json"});
  is($res, undef, 'only exists item which is not for total');

  $log->Info($end_msg, $name);
  done_testing;
};

$num  = 3;
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  # 必須ファイルの名前を変更
  use File::Copy 'move';
  my $annual_tmpl = EsmDataDetector::template_imo_dcs_annual;
  my $annual_tmpl_rename = $annual_tmpl.'.invalid';
  move $annual_tmpl, $annual_tmpl_rename;

  throws_ok {
    get_totalize_res({year => '2018', voyage_data => "$num.json"})
  } qr/there is no required path/, 'template file not exists exception';

  # 必須ファイルの名前を戻す
  move $annual_tmpl_rename, $annual_tmpl;
  is(-f $annual_tmpl, TRUE, 'returned required file name');

  $log->Info($end_msg, $name);
  done_testing;
};

$num  = 4;
$name = "$func - $num";
subtest $name => sub {
  $log->Info($start_msg, $name);

  my $res = get_totalize_res({year => '2018', voyage_data => "$num.json"});
  is($res, undef, 'no data');

  $log->Info($end_msg, $name);
  done_testing;
};


# ヘルパーメソッドはここから下に書きます

sub get_judge_year_over_res {
  my ($arg_ref) = @_; # リストコンテキストで評価しないとリファレンスが"1"と認識されてしまうので注意。

  my ($year, $voy_file) = ($arg_ref->{year}, $arg_ref->{voyage_data});
  my ($add, $cli_code, $imo_no) = ([], 'CBA', '1234567');
  my $annual = VoyageImoDcsCreateAnnual->new($log, $add, $year, $cli_code, $imo_no);
  my $file   = sprintf("%s/%s/%s", $test_data_dir, $func, $voy_file);
  my $jh     = JsonHandler->new($log, $file);
  return $annual->_judge_year_over($jh->get_data->{data});
}

sub get_calc_begin_res {
  my ($arg_ref) = @_; # リストコンテキストで評価しないとリファレンスが"1"と認識されてしまうので注意。

  my ($jh, $annual) = prepare_calc_res($arg_ref);

  # 計算実施
  $annual->_calc_begin($jh->get_data->{data}{for_row}{data});
  return $annual->{totalize_result};
}

sub get_calc_middle_res {
  my ($arg_ref) = @_; # リストコンテキストで評価しないとリファレンスが"1"と認識されてしまうので注意。

  my ($jh, $annual) = prepare_calc_res($arg_ref);

  # 計算実施
  for my $d (@{$jh->get_data}) {
    $annual->_calc_middle($d->{data}{for_row}{data});
  }
  return $annual->{totalize_result}{data}{middle_of_year}{data};
}

sub get_calc_end_res {
  my ($arg_ref) = @_; # リストコンテキストで評価しないとリファレンスが"1"と認識されてしまうので注意。

  my ($jh, $annual) = prepare_calc_res($arg_ref);

  # 計算実施
  $annual->_calc_end($jh->get_data->{data}{for_row}{data});
  return $annual->{totalize_result}{data}{end_of_year}{data};
}

sub prepare_calc_res {
  my ($arg_ref) = @_;

  my ($year, $voy_file) = ($arg_ref->{year}, $arg_ref->{voyage_data});
  my ($add, $cli_code, $imo_no) = ([], 'CBA', '1234567');
  my $annual = VoyageImoDcsCreateAnnual->new($log, $add, $year, $cli_code, $imo_no);
  my $file   = sprintf("%s/%s/%s", $test_data_dir, $func, $voy_file);
  my $jh     = JsonHandler->new($log, $file);

  # 結果データにテンプレートを読み込ませる
  my $ed = EsmDataDetector->new($log, $cli_code, $imo_no);
  my $tmpl_jh = JsonHandler->new($log, EsmDataDetector::template_imo_dcs_annual);
  $annual->{totalize_result} = $tmpl_jh->get_data;

  return ($jh, $annual);
}

sub get_totalize_res {
  my ($arg_ref) = @_;

  my ($year, $voy_file) = ($arg_ref->{year}, $arg_ref->{voyage_data});
  my $file   = sprintf("%s/%s/%s", $test_data_dir, $func, $voy_file);
  my $jh     = JsonHandler->new($log, $file);
  my ($add, $cli_code, $imo_no) = ($jh->get_data, 'CBA', '1234567');
  my $annual = VoyageImoDcsCreateAnnual->new($log, $add, $year, $cli_code, $imo_no);
  return $annual->totalize;
}


END{
  $log->Close() if( defined( $log ) );
}
done_testing;
