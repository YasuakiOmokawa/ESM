#! /usr/local/bin/perl
# $Id: data_format_test.t 36246 2019-03-15 03:33:35Z p0660 $

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
use JSON;

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../lib";
use lib '/usr/amoeba/lib/perl';

use logging;
use TsvToJson qw(tsv_to_json);

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

#############################
# 取得対象識別子のテスト  START #
#############################
# テスト項目　No.1
# 取得対象識別子[voyage]のテスト
# 引数　$get_target_id = 'voyage';
#
subtest "data target voyage test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type}
        ], 'target voyage test diff ok'
    );
    done_testing;
};
#
# テスト項目　No.2
# 取得対象識別子[eu_mrv]のテスト
# 引数　$get_target_id = 'eu_mrv';
#
subtest "data target eu_mrv test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => '',
    };
    my $get_target_id = 'eu_mrv';
    my $record_type = '';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type}
        ],
        'target eu_mrv test diff ok'
    );
    done_testing;
};
#############################
# 取得対象識別子のテスト  END   #
#############################
#################################################################################################################

##############################
# EU MRV変換処理のテスト  START #
##############################
# テスト項目　No.3
# 引数　$get_target_id = 'voyage';
# 引数　$record_type = 'voyage';
# 引数　eu_mrv' = 'dep_from_eu_port
# 返却値　eu_mrv_display = from EU
subtest "voyage from EU test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'eu_mrv' => 'dep_from_eu_port',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'from EU'
        ],
        'voyage from EU test diff ok'
    );
    done_testing;
};
# テスト項目　No.4
# 引数　$get_target_id = 'voyage';
# 引数　$record_type = 'voyage';
# 引数　eu_mrv' = 'arr_at_eu_port
# 返却値　eu_mrv_display = to EU
subtest "voyage to EU test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'eu_mrv' => 'arr_at_eu_port',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'to EU'
        ],
        'voyage to EU test diff ok'
    );
    done_testing;
};
# テスト項目　No.5
# 引数　$get_target_id = 'voyage';
# 引数　$record_type = 'voyage';
# 引数　eu_mrv' = 'eu_to_eu
# 返却値　eu_mrv_display = EU to EU
subtest "voyage EU to EU test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'eu_mrv' => 'eu_to_eu',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'EU to EU'
        ],
        'voyage EU to EU test diff ok'
    );
    done_testing;
};
# テスト項目　No.6
# 引数　$get_target_id = 'voyage';
# 引数　$record_type = 'in_port';
# 引数　eu_mrv' = 'in_eu_port
# 返却値　eu_mrv_display = In EU port
subtest "in-port In EU port test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'in_port',
        'eu_mrv' => 'in_eu_port',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'In EU port'
        ],
        'in-port In EU port test diff ok'
    );
    done_testing;
};
# テスト項目　No.7
# 引数　$get_target_id = 'voyage';
# 引数　$record_type = 'in_port';
# 引数　eu_mrv' = 'no_eu
# 返却値　eu_mrv_display = ---
subtest "in-port no_eu port test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'in_port',
        'eu_mrv' => 'no_eu',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            '---'
        ],
        'in-port no_eu port test diff ok'
    );
    done_testing;
};
# テスト項目　No.8
# 引数　$get_target_id = 'eu_mrv';
# 引数　$record_type = '';
# 引数　eu_mrv' = 'in_eu_port
# 返却値　eu_mrv_display = In EU port
subtest "eu_mrv In EU port test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => '',
        'eu_mrv' => 'in_eu_port',
    };
    my $get_target_id = 'eu_mrv';
    my $record_type = '';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'In EU port'
        ],
        'eu_mrv In EU port test diff ok'
    );
    done_testing;
};
# テスト項目　No.9
# 引数　$get_target_id = 'eu_mrv';
# 引数　$record_type = '';
# 引数　eu_mrv' = 'dep_from_eu_port
# 返却値　eu_mrv_display = from EU
subtest "eu_mrv from EU test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => '',
        'eu_mrv' => 'dep_from_eu_port',
    };
    my $get_target_id = 'eu_mrv';
    my $record_type = '';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'from EU'
        ],
        'eu_mrv from EU test diff ok'
    );
    done_testing;
};
# テスト項目　No.10
# 引数　$get_target_id = 'eu_mrv';
# 引数　$record_type = '';
# 引数　eu_mrv' = 'arr_at_eu_port
# 返却値　eu_mrv_display = to EU
subtest "eu_mrv to EU test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => '',
        'eu_mrv' => 'arr_at_eu_port',
    };
    my $get_target_id = 'eu_mrv';
    my $record_type = '';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'to EU'
        ],
        'eu_mrv to EU test diff ok'
    );
    done_testing;
};
# テスト項目　No.11
# 引数　$get_target_id = 'eu_mrv';
# 引数　$record_type = '';
# 引数　eu_mrv' = 'eu_to_eu
# 返却値　eu_mrv_display = EU to EU
subtest "eu_mrv EU to EU test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => '',
        'eu_mrv' => 'eu_to_eu',
    };
    my $get_target_id = 'eu_mrv';
    my $record_type = '';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'EU to EU'
        ],
        'eu_mrv EU to EU test diff ok'
    );
    done_testing;
};
# テスト項目　No.12
# 引数　$get_target_id = 'eu_mrv';
# 引数　$record_type = '';
# 引数　eu_mrv' = 'summary
# 返却値　eu_mrv_display = Total
subtest "eu_mrv Total test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => '',
        'eu_mrv' => 'summary',
    };
    my $get_target_id = 'eu_mrv';
    my $record_type = '';

    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);

    eq_or_diff(
        [
            $result->{voyage_key},
            $result->{record_type},
            $result->{eu_mrv},
            $result->{eu_mrv_display}
        ],
        [
            $target_value->{voyage_key},
            $target_value->{record_type},
            $target_value->{eu_mrv},
            'Total'
        ],
        'eu_mrv Total test diff ok'
    );
    done_testing;
};
##############################
# EU MRV変換処理のテスト   END  #
##############################
##################################################################################################################

##############################
# ポート変換処理のテスト   START  #
##############################
# テスト項目　No.13
# 引数　dep_port' = 'MLG'
# 返却値　dep_port_display' => MALAGA, ES
subtest "dep_port test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'dep_port' => 'MLG',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{dep_port},
        $result->{dep_port_display}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{dep_port},
        'MALAGA, ES'
      ], 'dep_port test diff ok');
  done_testing;
};
# テスト項目　No.14
# 引数　dep_port' = 'KOB'
# 返却値　dep_port_display' => KOBE, JP
subtest "dep_port test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'arr_port' => 'KOB',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{arr_port},
        $result->{arr_port_display}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{arr_port},
        'KOBE, JP'
      ], 'dep_port test diff ok');
  done_testing;
};
##############################
# ポート変換処理のテスト     END  #
##############################
##################################################################################################################

##############################
# 年月日時間の変換処理   START #
##############################
# テスト項目　No.15
# 正常値
# 引数　dep_date_time　 = 2018-07-04T11:00:00Z
# 返却値　dep_date_time　 => 07/04 11:00
subtest "dep_port　normal test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'dep_date_time' => '2018-07-04T11:00:00Z',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{dep_date_time}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        '07/04 11:00'
      ], 'dep_port　normal test diff ok');
  done_testing;
};
# テスト項目　No.16
# 異常値
# 引数　dep_date_time　 = 123456789
# 返却値　system error
subtest "dep_port system error test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'dep_date_time' => '123456789',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
    # （dep_date_time/arr_date_timeの異常値のシステムエラーを取得）
    throws_ok(
        sub {
            $data_format->load_format_def($get_target_id, $target_value, $record_type);
        },
        qr/Validation failed for type named DayOfMonth declared/,'dep_port system error test ok'
    );
  done_testing;
};
# テスト項目　No.17
# 空値
# 引数　dep_date_time　 = ''
# 返却値　dep_date_time　 = ''
subtest "dep_port null test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'dep_date_time' => '',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{dep_date_time}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{dep_date_time}
      ], 'dep_port　null test diff ok');
  done_testing;
};
# テスト項目　No.18
# 未定義
# 引数　dep_date_time＜＝削除
# 返却値　dep_date_time　 = ''
subtest "dep_port def test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{dep_date_time}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        ''
      ], 'dep_port　def test diff ok');
  done_testing;
};
# テスト項目　No.19
# 正常値
# 引数　arr_date_time　 = 2018-07-04T11:00:00Z
# 返却値　arr_date_time　 => 07/04 11:00
subtest "arr_date_time　normal test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'arr_date_time' => '2018-07-04T11:00:00Z',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{arr_date_time}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        '07/04 11:00'
      ], 'arr_date_time　normal test diff ok');
  done_testing;
};
# テスト項目　No.20
# 異常値
# 引数　arr_date_time　 = 123456789
# 返却値　system error
subtest "arr_date_time system error test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'arr_date_time' => '123456789',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
    # （dep_date_time/arr_date_timeの異常値のシステムエラーを取得）
    throws_ok(
        sub {
            $data_format->load_format_def($get_target_id, $target_value, $record_type);
        },
        qr/Validation failed for type named DayOfMonth declared/,'arr_date_time system error test ok'
    );
  done_testing;
};
# テスト項目　No.21
# 空値
# 引数　arr_date_time　 = ''
# 返却値　arr_date_time　 = ''
subtest "arr_date_time null test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'arr_date_time' => '',
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{arr_date_time}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{arr_date_time}
      ], 'arr_date_time　null test diff ok');
  done_testing;
};
# テスト項目　No.22
# 未定義
# 引数　dep_date_time＜＝削除
# 返却値　dep_date_time　 = ''
subtest "arr_date_time def test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{arr_date_time}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        ''
      ], 'arr_date_time　def test diff ok');
  done_testing;
};
##############################
# 年月日時間の変換処理    END  #
##############################
##################################################################################################################

#################################
# voyage_numberの変換処理  START #
#################################
# テスト項目　No.23
# 数字
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 引数　voyage_number = ０１２３４＿567_89
# 返却値　voyage_number　 => ０１２３４＿567_89
subtest "voyage_number voyage　num test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'voyage_number' => '０１２３４＿567_89'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{voyage_number}
      ], 'voyage_number voyage　num test diff ok');
  done_testing;
};
# テスト項目　No.24
# ハイフン「-」
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 引数　voyage_number = -123456
# 返却値　voyage_number　 => -123456
subtest "voyage_number voyage hyphen test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'voyage_number' => '-123456'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{voyage_number}
      ], 'voyage_number voyage hyphen test diff ok');
  done_testing;
};
# テスト項目　No.25
# 文字
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 引数　voyage_number = 'abcde_ｆｇｈｉｊｋ\LMN＿ＯＰＱＲ'
# 返却値　voyage_number　 => 'abcde_ｆｇｈｉｊｋ\LMN＿ＯＰＱＲ'
subtest "voyage_number voyage string test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'voyage_number' => 'abcde_ｆｇｈｉｊｋ\LMN＿ＯＰＱＲ'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{voyage_number}
      ], 'voyage_number voyage string test diff ok');
  done_testing;
};
# テスト項目　No.26
# 空値
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 引数　voyage_number = ''
# 返却値　voyage_number　 => ''
subtest "voyage_number voyage null test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage',
        'voyage_number' => ''
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{voyage_number}
      ], 'voyage_number voyage null test diff ok');
  done_testing;
};
# テスト項目　No.27
# 未定義
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 引数　voyage_number＜＝削除
# 返却値　voyage_number　 = ''
subtest "voyage_number voyage def test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'voyage'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        ''
      ], 'voyage_number voyage def test diff ok');
  done_testing;
};
# テスト項目　No.28
# 数字
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 引数　voyage_number = ０１２３４＿567_89
# 返却値　voyage_number　 => ０１２３４＿567_89
subtest "voyage_number in-port　num test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'in_port',
        'voyage_number' => '０１２３４＿567_89'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{voyage_number}
      ], 'voyage_number in-port　num test diff ok');
  done_testing;
};
# テスト項目　No.29
# ハイフン「-」
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 引数　voyage_number = -123456
# 返却値　voyage_number　 => -123456
subtest "voyage_number in-port hyphen test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'in_port',
        'voyage_number' => '-123456'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{voyage_number}
      ], 'voyage_number in-port hyphen test diff ok');
  done_testing;
};
# テスト項目　No.30
# 文字
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 引数　voyage_number = 'abcde_ｆｇｈｉｊｋ\LMN＿ＯＰＱＲ'
# 返却値　voyage_number　 => 'abcde_ｆｇｈｉｊｋ\LMN＿ＯＰＱＲ'
subtest "voyage_number in-port string test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'in_port',
        'voyage_number' => 'abcde_ｆｇｈｉｊｋ\LMN＿ＯＰＱＲ'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        $target_value->{voyage_number}
      ], 'voyage_number in-port string test diff ok');
  done_testing;
};
# テスト項目　No.31
# 空値
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 引数　voyage_number = ''
# 返却値　voyage_number　 => ''
subtest "voyage_number in-port null test" => sub {
    my $target_value = {
        'voyage_number' => '',
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'in_port'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_number},
        $result->{voyage_key},
        $result->{record_type}
      ],
      [
        $target_value->{voyage_number},
        $target_value->{voyage_key},
        $target_value->{record_type}
      ], 'voyage_number in-port null test diff ok');
  done_testing;
};
# テスト項目　No.32
# 未定義
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 引数　voyage_number＜＝削除
# 返却値　voyage_number　 = ''
subtest "voyage_number in-port def test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => 'in_port'
    };
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_number},
        $result->{voyage_key},
        $result->{record_type}
      ],
      [
        '',
        $target_value->{voyage_key},
        $target_value->{record_type}
      ], 'voyage_number in-port def test diff ok');
  done_testing;
};

# テスト項目　No.33
# 未定義
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 引数　voyage_number＜＝削除
# 返却値　voyage_number　 = '---'
subtest "voyage_number eu_mrv def test" => sub {
    my $target_value = {
        'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        'record_type' => ''
    };
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, $target_value, $record_type);
    eq_or_diff(
      [
        $result->{voyage_key},
        $result->{record_type},
        $result->{voyage_number}
      ],
      [
        $target_value->{voyage_key},
        $target_value->{record_type},
        '---'
      ], 'voyage_number eu_mrv def test diff ok');
  done_testing;
};
################################
# voyage_numberの変換処理  END  #
################################
##################################################################################################################

###########################
# 上記以外のformat  START  #
###########################
###################
# 下記のテスト用引数 #
###################
# 上限値内用引数 (Voyage/in-port専用)
my $upper_limit_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '99999',
    'time_at_sea' => '9999.9',
    'hours_underway' => '9999.9',
    'foc_dogo'  => '999.99',
    'foc_lfo'   => '9999.99',
    'foc_hfo'   => '9999.99',
    'foc_other' => '9999.99',
    'co2_dogo'  => '999.99',
    'co2_lfo'   => '99999.99',
    'co2_hfo'   => '99999.99',
    'co2_other' => '99999.99',
    'cargo_weight' => '999999',
    'passenger' => '999999',
    'unit_laden' => '999999',
    'unit_empty' => '999999',
    'cars' => '999999',
    'dwt_carried' => '999999',
    'volume' => '999999',
    'transport_work' => '99999999',
    'foc_dogo_per_distance' => '9999.9999',
    'foc_lfo_per_distance' => '9999.9999',
    'foc_hfo_per_distance' => '9999.9999',
    'foc_other_per_distance' => '9999.9999',
    'foc_dogo_per_transport_work'  => '99.99999999',
    'foc_lfo_per_transport_work'   => '99.99999999',
    'foc_hfo_per_transport_work'   => '99.99999999',
    'foc_other_per_transport_work' => '99.99999999',
    'co2_per_distance' => '9999.9999',
    'eeoi' => '99.99999999'
};
# 上限値内用引数 (eumrv専用)
my $eumrv_upper_limit_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '99999',
    'time_at_sea' => '9999.9',
    'hours_underway' => '9999.9',
    'foc_dogo'  => '99999.99',
    'foc_lfo'   => '99999.99',
    'foc_hfo'   => '99999.99',
    'foc_other' => '99999.99',
    'co2_dogo'  => '999999.99',
    'co2_lfo'   => '999999.99',
    'co2_hfo'   => '999999.99',
    'co2_other' => '999999.99',
    'cargo_weight' => '9999999',
    'passenger' => '999999',
    'unit_laden' => '999999',
    'unit_empty' => '999999',
    'cars' => '999999',
    'dwt_carried' => '999999',
    'volume' => '999999',
    'transport_work' => '99999999999',
    'foc_dogo_per_distance' => '9999.9999',
    'foc_lfo_per_distance' => '9999.9999',
    'foc_hfo_per_distance' => '9999.9999',
    'foc_other_per_distance' => '9999.9999',
    'foc_dogo_per_transport_work'  => '99.99999999',
    'foc_lfo_per_transport_work'   => '99.99999999',
    'foc_hfo_per_transport_work'   => '99.99999999',
    'foc_other_per_transport_work' => '99.99999999',
    'co2_per_distance' => '9999.9999',
    'eeoi' => '99.99999999'
};
#　下限値内 / 0用引数 (Voyage/In-port用)
my $lower_limit_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '0',
    'time_at_sea' => '0.0',
    'hours_underway' => '0.0',
    'foc_dogo'  => '0.00',
    'foc_lfo'   => '0.00',
    'foc_hfo'   => '0.00',
    'foc_other' => '0.00',
    'co2_dogo'  => '0.00',
    'co2_lfo'   => '0.00',
    'co2_hfo'   => '0.00',
    'co2_other' => '0.00',
    'cargo_weight' => '0',
    'passenger' => '0',
    'unit_laden' => '0',
    'unit_empty' => '0',
    'cars' => '0',
    'dwt_carried' => '0',
    'volume' => '0',
    'transport_work' => '0',
    'foc_dogo_per_distance' => '0.0000',
    'foc_lfo_per_distance' => '0.0000',
    'foc_hfo_per_distance' => '0.0000',
    'foc_other_per_distance' => '0.0000',
    'foc_dogo_per_transport_work'  => '0.00000000',
    'foc_lfo_per_transport_work'   => '0.00000000',
    'foc_hfo_per_transport_work'   => '0.00000000',
    'foc_other_per_transport_work' => '0.00000000',
    'co2_per_distance' => '0.0000',
    'eeoi' => '0.00000000'
};
#　下限値内 / 0用引数 (for eu_mrv)
my $eumrv_lower_limit_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '0',
    'time_at_sea' => '0.0',
    'hours_underway' => '0.0',
    'foc_dogo'  => '0.00',
    'foc_lfo'   => '0.00',
    'foc_hfo'   => '0.00',
    'foc_other' => '0.00',
    'co2_dogo'  => '0.00',
    'co2_lfo'   => '0.00',
    'co2_hfo'   => '0.00',
    'co2_other' => '0.00',
    'cargo_weight' => '0',
    'passenger' => '0',
    'unit_laden' => '0',
    'unit_empty' => '0',
    'cars' => '0',
    'dwt_carried' => '0',
    'volume' => '0',
    'transport_work' => '0',
    'foc_dogo_per_distance' => '0.0000',
    'foc_lfo_per_distance' => '0.0000',
    'foc_hfo_per_distance' => '0.0000',
    'foc_other_per_distance' => '0.0000',
    'foc_dogo_per_transport_work'  => '0.00000000',
    'foc_lfo_per_transport_work'   => '0.00000000',
    'foc_hfo_per_transport_work'   => '0.00000000',
    'foc_other_per_transport_work' => '0.00000000',
    'co2_per_distance' => '0.0000',
    'eeoi' => '0.00000000'
};
#　上限値外用引数 (Voyage/in-port専用)
my $upper_over_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
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
    'unit_laden' => '1000000',
    'unit_empty' => '1000000',
    'cars' => '1000000',
    'dwt_carried' => '1000000',
    'volume' => '1000000',
    'transport_work' => '10000000000',
    'foc_dogo_per_distance' => '10000.0000',
    'foc_lfo_per_distance' => '10000.0000',
    'foc_hfo_per_distance' => '10000.0000',
    'foc_other_per_distance' => '10000.0000',
    'foc_dogo_per_transport_work'  => '100.00000000',
    'foc_lfo_per_transport_work'   => '100.00000000',
    'foc_hfo_per_transport_work'   => '100.00000000',
    'foc_other_per_transport_work' => '100.00000000',
    'co2_per_distance' => '10000.0000',
    'eeoi' => '100.00000000'
};
#　上限値外用引数 (eumrv専用)
my $eumrv_upper_over_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '100000',
    'time_at_sea' => '10000.0',
    'hours_underway' => '10000.0',
    'foc_dogo'  => '100000.00',
    'foc_lfo'   => '100000.00',
    'foc_hfo'   => '100000.00',
    'foc_other' => '100000.00',
    'co2_dogo'  => '1000000.00',
    'co2_lfo'   => '1000000.00',
    'co2_hfo'   => '1000000.00',
    'co2_other' => '1000000.00',
    'cargo_weight' => '10000000',
    'passenger' => '1000000',
    'unit_laden' => '1000000',
    'unit_empty' => '1000000',
    'cars' => '1000000',
    'dwt_carried' => '1000000',
    'volume' => '1000000',
    'transport_work' => '100000000000',
    'foc_dogo_per_distance' => '10000.0000',
    'foc_lfo_per_distance' => '10000.0000',
    'foc_hfo_per_distance' => '10000.0000',
    'foc_other_per_distance' => '10000.0000',
    'foc_dogo_per_transport_work'  => '100.00000000',
    'foc_lfo_per_transport_work'   => '100.00000000',
    'foc_hfo_per_transport_work'   => '100.00000000',
    'foc_other_per_transport_work' => '100.00000000',
    'co2_per_distance' => '10000.0000',
    'eeoi' => '100.00000000'
};
#　下限値外用引数
my $lower_over_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '-1',
    'time_at_sea' => '-1',
    'hours_underway' => '-1',
    'foc_dogo'  => '-1',
    'foc_lfo'   => '-1',
    'foc_hfo'   => '-1',
    'foc_other' => '-1',
    'co2_dogo'  => '-1',
    'co2_lfo'   => '-1',
    'co2_hfo'   => '-1',
    'co2_other' => '-1',
    'cargo_weight' => '-1',
    'passenger' => '-1',
    'unit_laden' => '-1',
    'unit_empty' => '-1',
    'cars' => '-1',
    'dwt_carried' => '-1',
    'volume' => '-1',
    'transport_work' => '-1',
    'foc_dogo_per_distance' => '-1',
    'foc_lfo_per_distance' => '-1',
    'foc_hfo_per_distance' => '-1',
    'foc_other_per_distance' => '-1',
    'foc_dogo_per_transport_work'  => '-1',
    'foc_lfo_per_transport_work'   => '-1',
    'foc_hfo_per_transport_work'   => '-1',
    'foc_other_per_transport_work' => '-1',
    'co2_per_distance' => '-1',
    'eeoi' => '-1'
};
# 四捨五入切上げ用引数 (Voyage/In-port用)
my $round_up_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '999.5',
    'time_at_sea' => '999.95',
    'hours_underway' => '999.95',
    'foc_dogo'  => '99.995',
    'foc_lfo'   => '999.995',
    'foc_hfo'   => '999.995',
    'foc_other' => '999.995',
    'co2_dogo'  => '99.995',
    'co2_lfo'   => '999.995',
    'co2_hfo'   => '999.995',
    'co2_other' => '999.995',
    'cargo_weight' => '99999.5',
    'passenger' => '99999.5',
    'unit_laden' => '99999.5',
    'unit_empty' => '99999.5',
    'cars' => '99999.5',
    'dwt_carried' => '99999.5',
    'volume' => '99999.5',
    'transport_work' => '9999999.5',
    'foc_dogo_per_distance' => '999.99995',
    'foc_lfo_per_distance' => '999.99995',
    'foc_hfo_per_distance' => '999.99995',
    'foc_other_per_distance' => '999.99995',
    'foc_dogo_per_transport_work'  => '0.9999999995',
    'foc_lfo_per_transport_work'   => '0.9999999995',
    'foc_hfo_per_transport_work'   => '0.9999999995',
    'foc_other_per_transport_work' => '0.9999999995',
    'co2_per_distance' => '999.99995',
    'eeoi' => '0.9999999995'
};
# 四捨五入切上げ用引数 (for eu_mrv)
my $eumrv_round_up_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '999.5',
    'time_at_sea' => '999.95',
    'hours_underway' => '999.95',
    'foc_dogo'  => '99.995',
    'foc_lfo'   => '999.995',
    'foc_hfo'   => '999.995',
    'foc_other' => '999.995',
    'co2_dogo'  => '99.995',
    'co2_lfo'   => '999.995',
    'co2_hfo'   => '999.995',
    'co2_other' => '999.995',
    'cargo_weight' => '99999.5',
    'passenger' => '99999.5',
    'unit_laden' => '99999.5',
    'unit_empty' => '99999.5',
    'cars' => '99999.5',
    'dwt_carried' => '99999.5',
    'volume' => '99999.5',
    'transport_work' => '9999999.5',
    'foc_dogo_per_distance' => '999.99995',
    'foc_lfo_per_distance' => '999.99995',
    'foc_hfo_per_distance' => '999.99995',
    'foc_other_per_distance' => '999.99995',
    'foc_dogo_per_transport_work'  => '9.999999995',
    'foc_lfo_per_transport_work'   => '9.999999995',
    'foc_hfo_per_transport_work'   => '9.999999995',
    'foc_other_per_transport_work' => '9.999999995',
    'co2_per_distance' => '999.99995',
    'eeoi' => '9.999999995'
};
# 四捨五入切下げ用引数 (Voyage/in-port専用)
my $round_lower_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '999.4',
    'time_at_sea' => '999.94',
    'hours_underway' => '999.94',
    'foc_dogo'  => '99.994',
    'foc_lfo'   => '999.994',
    'foc_hfo'   => '999.994',
    'foc_other' => '999.994',
    'co2_dogo'  => '99.994',
    'co2_lfo'   => '999.994',
    'co2_hfo'   => '999.994',
    'co2_other' => '999.994',
    'cargo_weight' => '99999.4',
    'passenger' => '99999.4',
    'unit_laden' => '99999.4',
    'unit_empty' => '99999.4',
    'cars' => '99999.4',
    'dwt_carried' => '99999.4',
    'volume' => '99999.4',
    'transport_work' => '9999999.4',
    'foc_dogo_per_distance' => '9999.99994',
    'foc_lfo_per_distance' => '9999.99994',
    'foc_hfo_per_distance' => '9999.99994',
    'foc_other_per_distance' => '9999.99994',
    'foc_dogo_per_transport_work'  => '9.999999994',
    'foc_lfo_per_transport_work'   => '9.999999994',
    'foc_hfo_per_transport_work'   => '9.999999994',
    'foc_other_per_transport_work' => '9.999999994',
    'co2_per_distance' => '9999.99994',
    'eeoi' => '9.999999994'
};

# 四捨五入切下げ用引数(for eu_mrv)
my $eumrv_round_lower_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '999.4',
    'time_at_sea' => '999.94',
    'hours_underway' => '999.94',
    'foc_dogo'  => '99.994',
    'foc_lfo'   => '999.994',
    'foc_hfo'   => '999.994',
    'foc_other' => '999.994',
    'co2_dogo'  => '99.994',
    'co2_lfo'   => '999.994',
    'co2_hfo'   => '999.994',
    'co2_other' => '999.994',
    'cargo_weight' => '99999.4',
    'passenger' => '99999.4',
    'unit_laden' => '99999.4',
    'unit_empty' => '99999.4',
    'cars' => '99999.4',
    'dwt_carried' => '99999.4',
    'volume' => '99999.4',
    'transport_work' => '9999999.4',
    'foc_dogo_per_distance' => '9999.99994',
    'foc_lfo_per_distance' => '9999.99994',
    'foc_hfo_per_distance' => '9999.99994',
    'foc_other_per_distance' => '9999.99994',
    'foc_dogo_per_transport_work'  => '9.999999994',
    'foc_lfo_per_transport_work'   => '9.999999994',
    'foc_hfo_per_transport_work'   => '9.999999994',
    'foc_other_per_transport_work' => '9.999999994',
    'co2_per_distance' => '9999.99994',
    'eeoi' => '9.999999994'
};

#　空値用引数
my $null_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
    'distance_travelled' => '',
    'time_at_sea' => '',
    'hours_underway' => '',
    'foc_dogo'  => '',
    'foc_lfo'   => '',
    'foc_hfo'   => '',
    'foc_other' => '',
    'co2_dogo'  => '',
    'co2_lfo'   => '',
    'co2_hfo'   => '',
    'co2_other' => '',
    'cargo_weight' => '',
    'passenger' => '',
    'unit_laden' => '',
    'unit_empty' => '',
    'cars' => '',
    'dwt_carried' => '',
    'volume' => '',
    'transport_work' => '',
    'foc_dogo_per_distance' => '',
    'foc_lfo_per_distance' => '',
    'foc_hfo_per_distance' => '',
    'foc_other_per_distance' => '',
    'foc_dogo_per_transport_work'  => '',
    'foc_lfo_per_transport_work'   => '',
    'foc_hfo_per_transport_work'   => '',
    'foc_other_per_transport_work' => '',
    'co2_per_distance' => '',
    'eeoi' => ''
};
# 未定義引数
my $undefined_value = {
    'voyage_key' => '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230'
};

#####################################################################################################################################
########取得対象識別子　「voyage」#################################################################################################
#####################################################################################################################################
# テスト項目　No.34～60　(上限値内)
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 返却値　引数がそのまま返される
subtest "voyage　upper limit test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    my %val = %{$upper_limit_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        $upper_limit_value->{voyage_key},
        $upper_limit_value->{distance_travelled},
        $upper_limit_value->{time_at_sea},
        $upper_limit_value->{hours_underway},
        $upper_limit_value->{foc_dogo},
        $upper_limit_value->{foc_lfo},
        $upper_limit_value->{foc_hfo},
        $upper_limit_value->{foc_other},
        $upper_limit_value->{co2_dogo},
        $upper_limit_value->{co2_lfo},
        $upper_limit_value->{co2_hfo},
        $upper_limit_value->{co2_other},
        $upper_limit_value->{cargo_weight},
        $upper_limit_value->{passenger},
        $upper_limit_value->{unit_laden},
        $upper_limit_value->{unit_empty},
        $upper_limit_value->{cars},
        $upper_limit_value->{dwt_carried},
        $upper_limit_value->{volume},
        $upper_limit_value->{transport_work},
        $upper_limit_value->{foc_dogo_per_distance},
        $upper_limit_value->{foc_lfo_per_distance},
        $upper_limit_value->{foc_hfo_per_distance},
        $upper_limit_value->{foc_other_per_distance},
        $upper_limit_value->{foc_dogo_per_transport_work},
        $upper_limit_value->{foc_lfo_per_transport_work},
        $upper_limit_value->{foc_hfo_per_transport_work},
        $upper_limit_value->{foc_other_per_transport_work},
        $upper_limit_value->{co2_per_distance},
        $upper_limit_value->{eeoi}
    ], 'voyage　upper limit test diff ok');
    done_testing;
};

# テスト項目　No.34～60　(下限値内 / 0)
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 返却値　引数がそのまま返される
subtest "voyage lower limit value test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    my %val = %{$lower_limit_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        $lower_limit_value->{voyage_key},
        $lower_limit_value->{distance_travelled},
        $lower_limit_value->{time_at_sea},
        $lower_limit_value->{hours_underway},
        $lower_limit_value->{foc_dogo},
        $lower_limit_value->{foc_lfo},
        $lower_limit_value->{foc_hfo},
        $lower_limit_value->{foc_other},
        $lower_limit_value->{co2_dogo},
        $lower_limit_value->{co2_lfo},
        $lower_limit_value->{co2_hfo},
        $lower_limit_value->{co2_other},
        $lower_limit_value->{cargo_weight},
        $lower_limit_value->{passenger},
        $lower_limit_value->{unit_laden},
        $lower_limit_value->{unit_empty},
        $lower_limit_value->{cars},
        $lower_limit_value->{dwt_carried},
        $lower_limit_value->{volume},
        $lower_limit_value->{transport_work},
        $lower_limit_value->{foc_dogo_per_distance},
        $lower_limit_value->{foc_lfo_per_distance},
        $lower_limit_value->{foc_hfo_per_distance},
        $lower_limit_value->{foc_other_per_distance},
        $lower_limit_value->{foc_dogo_per_transport_work},
        $lower_limit_value->{foc_lfo_per_transport_work},
        $lower_limit_value->{foc_hfo_per_transport_work},
        $lower_limit_value->{foc_other_per_transport_work},
        $lower_limit_value->{co2_per_distance},
        $lower_limit_value->{eeoi}
    ], 'voyage lower limit test diff ok');
    done_testing;
};

# テスト項目　No.34～60　(四捨五入切上げ)
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 返却値　引数が四捨五入が切上げで変換されて返却
subtest "voyage round up value test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    my %val = %{$round_up_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '1000',
        '1000.0',
        '1000.0',
        '100.00',
        '1000.00',
        '1000.00',
        '1000.00',
        '100.00',
        '1000.00',
        '1000.00',
        '1000.00',
        '100000',
        '100000',
        '100000',
        '100000',
        '100000',
        '100000',
        '100000',
        '10000000',
        '1000.0000',
        '1000.0000',
        '1000.0000',
        '1000.0000',
        '1.00000000',
        '1.00000000',
        '1.00000000',
        '1.00000000',
        '1000.0000',
        '1.00000000'
    ], 'voyage round up value test diff ok');
    done_testing;
};

# テスト項目　No.34～60　(四捨五入切捨て)
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 返却値　引数が四捨五入が切捨てで変換されて返却
subtest "voyage round lower test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    my %val = %{$round_lower_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '999',
        '999.9',
        '999.9',
        '99.99',
        '999.99',
        '999.99',
        '999.99',
        '99.99',
        '999.99',
        '999.99',
        '999.99',
        '99999',
        '99999',
        '99999',
        '99999',
        '99999',
        '99999',
        '99999',
        '9999999',
        '9999.9999',
        '9999.9999',
        '9999.9999',
        '9999.9999',
        '9.99999999',
        '9.99999999',
        '9.99999999',
        '9.99999999',
        '9999.9999',
        '9.99999999'
    ], 'voyage round lower test diff ok');
    done_testing;
};

# テスト項目　No.34～60　(空値)
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 返却値　引数がそのまま返される
subtest "voyage null test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    my %val = %{$null_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        $null_value->{voyage_key},
        $null_value->{distance_travelled},
        $null_value->{time_at_sea},
        $null_value->{hours_underway},
        $null_value->{foc_dogo},
        $null_value->{foc_lfo},
        $null_value->{foc_hfo},
        $null_value->{foc_other},
        $null_value->{co2_dogo},
        $null_value->{co2_lfo},
        $null_value->{co2_hfo},
        $null_value->{co2_other},
        $null_value->{cargo_weight},
        $null_value->{passenger},
        $null_value->{unit_laden},
        $null_value->{unit_empty},
        $null_value->{cars},
        $null_value->{dwt_carried},
        $null_value->{volume},
        $null_value->{transport_work},
        $null_value->{foc_dogo_per_distance},
        $null_value->{foc_lfo_per_distance},
        $null_value->{foc_hfo_per_distance},
        $null_value->{foc_other_per_distance},
        $null_value->{foc_dogo_per_transport_work},
        $null_value->{foc_lfo_per_transport_work},
        $null_value->{foc_hfo_per_transport_work},
        $null_value->{foc_other_per_transport_work},
        $null_value->{co2_per_distance},
        $null_value->{eeoi}
    ], 'voyage null diff ok');
    done_testing;
};

#  テスト項目　No.34～60　(未定義)
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 返却値　未定義の項目が作成される
subtest "voyage undefined test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    my %val = %{$undefined_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
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
    ], 'voyage undefined test diff ok');
done_testing;
};

# テスト項目　No.34～60　(上限値外)
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 返却値　エラーメッセージが返される
subtest "voyage　upper　over　test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    my %val = %{$upper_over_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
    my $result;
    # エラーメッセージの取得
    my ($stdout, $strerr) = capture {
        # 判定結果の取得
        $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    };
    # エラーメッセージの数を取得
    my $count = (() = $strerr =~ /upper limit/g);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
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
    ], 'voyage　upper　over test diff ok');
    # エラーメッセージがエラー分表示されたか確認
    like($count, qr/29/, 'upper error message ok');
    done_testing;
};

# テスト項目　No.34～60　(#下限値外)
# 引数　$get_target_id = voyage
# 引数　$record_type = voyage
# 返却値　エラーメッセージが返される
subtest "voyage　lower　over　test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'voyage';
    my %val = %{$lower_over_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
    my $result;
    # エラーメッセージの取得
    my ($stdout, $strerr) = capture {
        # 判定結果の取得
        $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    };
    # エラーメッセージの数を取得
    my $count = (() = $strerr =~ /lower limit/g);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
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
    ], 'voyage　lower　over　test diff ok');
    # エラーメッセージがエラー分表示されたか確認
    like($count, qr/29/, 'lower　error message ok');
    done_testing;
};

#####################################################################################################################################
########取得対象識別子　「in-port」#################################################################################################
#####################################################################################################################################
# テスト項目　No.61～87　(上限値内)
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 返却値　引数がそのまま返される
subtest "in-port　upper limit test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    my %val = %{$upper_limit_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        # $result->{cargo_weight},
        # $result->{passenger},
        # $result->{unit_laden},
        # $result->{unit_empty},
        # $result->{cars},
        # $result->{dwt_carried},
        # $result->{volume},
        # $result->{transport_work},
        # $result->{foc_dogo_per_distance},
        # $result->{foc_lfo_per_distance},
        # $result->{foc_hfo_per_distance},
        # $result->{foc_other_per_distance},
        # $result->{foc_dogo_per_transport_work},
        # $result->{foc_lfo_per_transport_work},
        # $result->{foc_hfo_per_transport_work},
        # $result->{foc_other_per_transport_work},
        # $result->{co2_per_distance},
        # $result->{eeoi}
    ],
    [
        $upper_limit_value->{voyage_key},
        $upper_limit_value->{distance_travelled},
        $upper_limit_value->{time_at_sea},
        $upper_limit_value->{hours_underway},
        $upper_limit_value->{foc_dogo},
        $upper_limit_value->{foc_lfo},
        $upper_limit_value->{foc_hfo},
        $upper_limit_value->{foc_other},
        $upper_limit_value->{co2_dogo},
        $upper_limit_value->{co2_lfo},
        $upper_limit_value->{co2_hfo},
        $upper_limit_value->{co2_other},
        # $upper_limit_value->{cargo_weight},
        # $upper_limit_value->{passenger},
        # $upper_limit_value->{unit_laden},
        # $upper_limit_value->{unit_empty},
        # $upper_limit_value->{cars},
        # $upper_limit_value->{dwt_carried},
        # $upper_limit_value->{volume},
        # $upper_limit_value->{transport_work},
        # $upper_limit_value->{foc_dogo_per_distance},
        # $upper_limit_value->{foc_lfo_per_distance},
        # $upper_limit_value->{foc_hfo_per_distance},
        # $upper_limit_value->{foc_other_per_distance},
        # $upper_limit_value->{foc_dogo_per_transport_work},
        # $upper_limit_value->{foc_lfo_per_transport_work},
        # $upper_limit_value->{foc_hfo_per_transport_work},
        # $upper_limit_value->{foc_other_per_transport_work},
        # $upper_limit_value->{co2_per_distance},
        # $upper_limit_value->{eeoi}
    ], 'in-port　upper limit test diff ok');
    done_testing;
};

# テスト項目　No.61～87　(下限値内 / 0)
# 引数　$get_target_id = voyage
# 引数　$record_type = in-port
# 返却値　引数がそのまま返される
subtest "in-port lower limit value test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    my %val = %{$lower_limit_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        # $result->{cargo_weight},
        # $result->{passenger},
        # $result->{unit_laden},
        # $result->{unit_empty},
        # $result->{cars},
        # $result->{dwt_carried},
        # $result->{volume},
        # $result->{transport_work},
        # $result->{foc_dogo_per_distance},
        # $result->{foc_lfo_per_distance},
        # $result->{foc_hfo_per_distance},
        # $result->{foc_other_per_distance},
        # $result->{foc_dogo_per_transport_work},
        # $result->{foc_lfo_per_transport_work},
        # $result->{foc_hfo_per_transport_work},
        # $result->{foc_other_per_transport_work},
        # $result->{co2_per_distance},
        # $result->{eeoi}
    ],
    [
        $lower_limit_value->{voyage_key},
        $lower_limit_value->{distance_travelled},
        $lower_limit_value->{time_at_sea},
        $lower_limit_value->{hours_underway},
        $lower_limit_value->{foc_dogo},
        $lower_limit_value->{foc_lfo},
        $lower_limit_value->{foc_hfo},
        $lower_limit_value->{foc_other},
        $lower_limit_value->{co2_dogo},
        $lower_limit_value->{co2_lfo},
        $lower_limit_value->{co2_hfo},
        $lower_limit_value->{co2_other},
        # $lower_limit_value->{cargo_weight},
        # $lower_limit_value->{passenger},
        # $lower_limit_value->{unit_laden},
        # $lower_limit_value->{unit_empty},
        # $lower_limit_value->{cars},
        # $lower_limit_value->{dwt_carried},
        # $lower_limit_value->{volume},
        # $lower_limit_value->{transport_work},
        # $lower_limit_value->{foc_dogo_per_distance},
        # $lower_limit_value->{foc_lfo_per_distance},
        # $lower_limit_value->{foc_hfo_per_distance},
        # $lower_limit_value->{foc_other_per_distance},
        # $lower_limit_value->{foc_dogo_per_transport_work},
        # $lower_limit_value->{foc_lfo_per_transport_work},
        # $lower_limit_value->{foc_hfo_per_transport_work},
        # $lower_limit_value->{foc_other_per_transport_work},
        # $lower_limit_value->{co2_per_distance},
        # $lower_limit_value->{eeoi}
    ], 'in-port lower limit test diff ok');
    done_testing;
};

# テスト項目　No.61～87　(四捨五入切上げ)
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 返却値　引数が四捨五入が切上げで変換されて返却
subtest "in-port　round　up　value test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    my %val = %{$round_up_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        # $result->{cargo_weight},
        # $result->{passenger},
        # $result->{unit_laden},
        # $result->{unit_empty},
        # $result->{cars},
        # $result->{dwt_carried},
        # $result->{volume},
        # $result->{transport_work},
        # $result->{foc_dogo_per_distance},
        # $result->{foc_lfo_per_distance},
        # $result->{foc_hfo_per_distance},
        # $result->{foc_other_per_distance},
        # $result->{foc_dogo_per_transport_work},
        # $result->{foc_lfo_per_transport_work},
        # $result->{foc_hfo_per_transport_work},
        # $result->{foc_other_per_transport_work},
        # $result->{co2_per_distance},
        # $result->{eeoi}
    ],
    [
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '1000',
        '1000.0',
        '1000.0',
        '100.00',
        '1000.00',
        '1000.00',
        '1000.00',
        '100.00',
        '1000.00',
        '1000.00',
        '1000.00',
        # '100000',
        # '100000',
        # '100000',
        # '100000',
        # '100000',
        # '100000',
        # '100000',
        # '10000000',
        # '0.1000',
        # '0.1000',
        # '0.1000',
        # '0.1000',
        # '0.00001000',
        # '0.00001000',
        # '0.00001000',
        # '0.00001000',
        # '0.1000',
        # '0.00001000'
    ], 'in-port　round　up　value test diff ok');
    done_testing;
};

# テスト項目　No.61～87　(四捨五入切捨て)
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 返却値　引数が四捨五入が切捨てで変換されて返却
subtest "in-port round lower test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    my %val = %{$round_lower_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        # $result->{cargo_weight},
        # $result->{passenger},
        # $result->{unit_laden},
        # $result->{unit_empty},
        # $result->{cars},
        # $result->{dwt_carried},
        # $result->{volume},
        # $result->{transport_work},
        # $result->{foc_dogo_per_distance},
        # $result->{foc_lfo_per_distance},
        # $result->{foc_hfo_per_distance},
        # $result->{foc_other_per_distance},
        # $result->{foc_dogo_per_transport_work},
        # $result->{foc_lfo_per_transport_work},
        # $result->{foc_hfo_per_transport_work},
        # $result->{foc_other_per_transport_work},
        # $result->{co2_per_distance},
        # $result->{eeoi}
    ],
    [
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '999',
        '999.9',
        '999.9',
        '99.99',
        '999.99',
        '999.99',
        '999.99',
        '99.99',
        '999.99',
        '999.99',
        '999.99',
        # '99999',
        # '99999',
        # '99999',
        # '99999',
        # '99999',
        # '99999',
        # '99999',
        # '9999999',
        # '0.0999',
        # '0.0999',
        # '0.0999',
        # '0.0999',
        # '0.00000999',
        # '0.00000999',
        # '0.00000999',
        # '0.00000999',
        # '0.0999',
        # '0.00000999'
    ], 'in-port round lower test diff ok');
    done_testing;
};
# テスト項目　No.61～87　(空値)
# 引数　$get_target_id = voyage
# 引数　$record_type = in-port
# 返却値　引数がそのまま返される
subtest "in-port null test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    my %val = %{$null_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        $null_value->{voyage_key},
        $null_value->{distance_travelled},
        $null_value->{time_at_sea},
        $null_value->{hours_underway},
        $null_value->{foc_dogo},
        $null_value->{foc_lfo},
        $null_value->{foc_hfo},
        $null_value->{foc_other},
        $null_value->{co2_dogo},
        $null_value->{co2_lfo},
        $null_value->{co2_hfo},
        $null_value->{co2_other},
        $null_value->{cargo_weight},
        $null_value->{passenger},
        $null_value->{unit_laden},
        $null_value->{unit_empty},
        $null_value->{cars},
        $null_value->{dwt_carried},
        $null_value->{volume},
        $null_value->{transport_work},
        $null_value->{foc_dogo_per_distance},
        $null_value->{foc_lfo_per_distance},
        $null_value->{foc_hfo_per_distance},
        $null_value->{foc_other_per_distance},
        $null_value->{foc_dogo_per_transport_work},
        $null_value->{foc_lfo_per_transport_work},
        $null_value->{foc_hfo_per_transport_work},
        $null_value->{foc_other_per_transport_work},
        $null_value->{co2_per_distance},
        $null_value->{eeoi}
    ], 'in-port null diff ok');
    done_testing;
};

#  テスト項目　No.61～87　(未定義)
# 引数　$get_target_id = voyage
# 引数　$record_type = in-port
# 返却値　未定義の項目が作成される
subtest "in-port undefined test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    my %val = %{$undefined_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '---',
        '---',
        '---',
        '***',
        '***',
        '***',
        '',
        '***',
        '***',
        '***',
        '',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
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
    ], 'in-port undefined test diff ok');
done_testing;
};

# テスト項目　No.61～87　(上限値外)
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 返却値　エラーメッセージが返される
subtest "in-port　upper　over　test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    my %val = %{$upper_over_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
    my $result;
    # エラーメッセージの取得
    my ($stdout, $strerr) = capture {
        # 判定結果の取得
        $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    };
    # エラーメッセージの数を取得
    my $count = (() = $strerr =~ /upper limit/g);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '---',
        '---',
        '---',
        '***',
        '***',
        '***',
        '',
        '***',
        '***',
        '***',
        '',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
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
    ], 'in-port　upper　over test diff ok');
    # エラーメッセージがエラー分表示されたか確認
    like($count, qr/29/, 'upper error message ok');
    done_testing;
};

# テスト項目　No.61～87　(#下限値外)
# 引数　$get_target_id = voyage
# 引数　$record_type = in_port
# 返却値　エラーメッセージが返される
subtest "in-port　lower　over　test" => sub {
    my $get_target_id = 'voyage';
    my $record_type = 'in_port';
    my %val = %{$lower_over_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
    my $result;
    # エラーメッセージの取得
    my ($stdout, $strerr) = capture {
        # 判定結果の取得
        $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    };
    # # エラーメッセージの数を取得
    my $count = (() = $strerr =~ /lower limit/g);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '---',
        '---',
        '---',
        '***',
        '***',
        '***',
        '',
        '***',
        '***',
        '***',
        '',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
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
    ], 'in-port　lower　over　test diff ok');
    # エラーメッセージがエラー分表示されたか確認
    like($count, qr/29/, 'lower　error message ok');
    done_testing;
};

#####################################################################################################################################
########取得対象識別子　「eu_mrv」#################################################################################################
#####################################################################################################################################
# テスト項目　No.88～114　(上限値内)
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 返却値　引数がそのまま返される
subtest "eu_mrv　upper limit test" => sub {
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    my %val = %{$eumrv_upper_limit_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        $eumrv_upper_limit_value->{voyage_key},
        $eumrv_upper_limit_value->{distance_travelled},
        $eumrv_upper_limit_value->{time_at_sea},
        $eumrv_upper_limit_value->{hours_underway},
        $eumrv_upper_limit_value->{foc_dogo},
        $eumrv_upper_limit_value->{foc_lfo},
        $eumrv_upper_limit_value->{foc_hfo},
        $eumrv_upper_limit_value->{foc_other},
        $eumrv_upper_limit_value->{co2_dogo},
        $eumrv_upper_limit_value->{co2_lfo},
        $eumrv_upper_limit_value->{co2_hfo},
        $eumrv_upper_limit_value->{co2_other},
        $eumrv_upper_limit_value->{cargo_weight},
        $eumrv_upper_limit_value->{passenger},
        $eumrv_upper_limit_value->{unit_laden},
        $eumrv_upper_limit_value->{unit_empty},
        $eumrv_upper_limit_value->{cars},
        $eumrv_upper_limit_value->{dwt_carried},
        $eumrv_upper_limit_value->{volume},
        $eumrv_upper_limit_value->{transport_work},
        $eumrv_upper_limit_value->{foc_dogo_per_distance},
        $eumrv_upper_limit_value->{foc_lfo_per_distance},
        $eumrv_upper_limit_value->{foc_hfo_per_distance},
        $eumrv_upper_limit_value->{foc_other_per_distance},
        $eumrv_upper_limit_value->{foc_dogo_per_transport_work},
        $eumrv_upper_limit_value->{foc_lfo_per_transport_work},
        $eumrv_upper_limit_value->{foc_hfo_per_transport_work},
        $eumrv_upper_limit_value->{foc_other_per_transport_work},
        $eumrv_upper_limit_value->{co2_per_distance},
        $eumrv_upper_limit_value->{eeoi}
    ], 'eu_mrv upper limit test diff ok');
    done_testing;
};

# テスト項目　No.88～114　(下限値内 / 0)
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 返却値　引数がそのまま返される
subtest "eu_mrv lower limit value test" => sub {
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    my %val = %{$eumrv_lower_limit_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        $eumrv_lower_limit_value->{voyage_key},
        $eumrv_lower_limit_value->{distance_travelled},
        $eumrv_lower_limit_value->{time_at_sea},
        $eumrv_lower_limit_value->{hours_underway},
        $eumrv_lower_limit_value->{foc_dogo},
        $eumrv_lower_limit_value->{foc_lfo},
        $eumrv_lower_limit_value->{foc_hfo},
        $eumrv_lower_limit_value->{foc_other},
        $eumrv_lower_limit_value->{co2_dogo},
        $eumrv_lower_limit_value->{co2_lfo},
        $eumrv_lower_limit_value->{co2_hfo},
        $eumrv_lower_limit_value->{co2_other},
        $eumrv_lower_limit_value->{cargo_weight},
        $eumrv_lower_limit_value->{passenger},
        $eumrv_lower_limit_value->{unit_laden},
        $eumrv_lower_limit_value->{unit_empty},
        $eumrv_lower_limit_value->{cars},
        $eumrv_lower_limit_value->{dwt_carried},
        $eumrv_lower_limit_value->{volume},
        $eumrv_lower_limit_value->{transport_work},
        $eumrv_lower_limit_value->{foc_dogo_per_distance},
        $eumrv_lower_limit_value->{foc_lfo_per_distance},
        $eumrv_lower_limit_value->{foc_hfo_per_distance},
        $eumrv_lower_limit_value->{foc_other_per_distance},
        $eumrv_lower_limit_value->{foc_dogo_per_transport_work},
        $eumrv_lower_limit_value->{foc_lfo_per_transport_work},
        $eumrv_lower_limit_value->{foc_hfo_per_transport_work},
        $eumrv_lower_limit_value->{foc_other_per_transport_work},
        $eumrv_lower_limit_value->{co2_per_distance},
        $eumrv_lower_limit_value->{eeoi}
    ], 'eu_mrv lower limit test diff ok');
    done_testing;
};

# テスト項目　No.88～114　(四捨五入切上げ)
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 返却値　引数が四捨五入が切上げで変換されて返却
subtest "eu_mrv round up value test" => sub {
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    my %val = %{$eumrv_round_up_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '1000',
        '1000.0',
        '1000.0',
        '100.00',
        '1000.00',
        '1000.00',
        '1000.00',
        '100.00',
        '1000.00',
        '1000.00',
        '1000.00',
        '100000',
        '100000',
        '100000',
        '100000',
        '100000',
        '100000',
        '100000',
        '10000000',
        '1000.0000',
        '1000.0000',
        '1000.0000',
        '1000.0000',
        '10.00000000',
        '10.00000000',
        '10.00000000',
        '10.00000000',
        '1000.0000',
        '10.00000000'
    ], 'eu_mrv　round　up　value test diff ok');
    done_testing;
};

# テスト項目　No.88～114　(四捨五入切捨て)
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 返却値　引数が四捨五入が切捨てで変換されて返却
subtest "eu_mrv round lower test" => sub {
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    my %val = %{$eumrv_round_lower_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '999',
        '999.9',
        '999.9',
        '99.99',
        '999.99',
        '999.99',
        '999.99',
        '99.99',
        '999.99',
        '999.99',
        '999.99',
        '99999',
        '99999',
        '99999',
        '99999',
        '99999',
        '99999',
        '99999',
        '9999999',
        '9999.9999',
        '9999.9999',
        '9999.9999',
        '9999.9999',
        '9.99999999',
        '9.99999999',
        '9.99999999',
        '9.99999999',
        '9999.9999',
        '9.99999999'
    ], 'eu_mrv round lower test diff ok');
    done_testing;
};
# テスト項目　No.88～114　(空値)
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 返却値　引数がそのまま返される
subtest "eu_mrv null test" => sub {
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    my %val = %{$null_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        $null_value->{voyage_key},
        $null_value->{distance_travelled},
        $null_value->{time_at_sea},
        $null_value->{hours_underway},
        $null_value->{foc_dogo},
        $null_value->{foc_lfo},
        $null_value->{foc_hfo},
        $null_value->{foc_other},
        $null_value->{co2_dogo},
        $null_value->{co2_lfo},
        $null_value->{co2_hfo},
        $null_value->{co2_other},
        $null_value->{cargo_weight},
        $null_value->{passenger},
        $null_value->{unit_laden},
        $null_value->{unit_empty},
        $null_value->{cars},
        $null_value->{dwt_carried},
        $null_value->{volume},
        $null_value->{transport_work},
        $null_value->{foc_dogo_per_distance},
        $null_value->{foc_lfo_per_distance},
        $null_value->{foc_hfo_per_distance},
        $null_value->{foc_other_per_distance},
        $null_value->{foc_dogo_per_transport_work},
        $null_value->{foc_lfo_per_transport_work},
        $null_value->{foc_hfo_per_transport_work},
        $null_value->{foc_other_per_transport_work},
        $null_value->{co2_per_distance},
        $null_value->{eeoi}
    ], 'eu_mrv null diff ok');
    done_testing;
};

#  テスト項目　No.88～114　(未定義)
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 返却値　未定義の項目が作成される
subtest "eu_mrv undefined test" => sub {
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    my %val = %{$undefined_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    my $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '',
        '---',
        '',
        '***',
        '***',
        '***',
        '',
        '***',
        '***',
        '***',
        '',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
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
    ], 'eu_mrv undefined test diff ok');
done_testing;
};

# テスト項目　No.88～114　(上限値外)
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 返却値　エラーメッセージが返される
subtest "eu_mrv　upper　over　test" => sub {
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    my %val = %{$eumrv_upper_over_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
    my $result;
    # エラーメッセージの取得
    my ($stdout, $strerr) = capture {
    # 判定結果の取得
    $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    };
    # エラーメッセージの数を取得
    my $count = (() = $strerr =~ /upper limit/g);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '',
        '---',
        '',
        '***',
        '***',
        '***',
        '',
        '***',
        '***',
        '***',
        '',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
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
    ], 'eu_mrv　upper　over test diff ok');
    # エラーメッセージがエラー分表示されたか確認
    like($count, qr/29/, 'upper error message ok');
    done_testing;
};

# テスト項目　No.88～114　(#下限値外)
# 引数　$get_target_id = eu_mrv
# 引数　$record_type =
# 返却値　エラーメッセージが返される
subtest "eu_mrv　lower　over　test" => sub {
    my $get_target_id = 'eu_mrv';
    my $record_type = '';
    my %val = %{$lower_over_value};
    # test
    # データフォーマットインスタンス生成
    my $data_format = DataFormat->new($log);
    # 標準エラー出力($log->Error()の出力)をキャッチするためのコード
    my $result;
    # エラーメッセージの取得
    my ($stdout, $strerr) = capture {
    # 判定結果の取得
    $result = $data_format->load_format_def($get_target_id, \%val, $record_type);
    };
    # エラーメッセージの数を取得
    my $count = (() = $strerr =~ /lower limit/g);
    eq_or_diff(
    [
        $result->{voyage_key},
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
        $result->{unit_laden},
        $result->{unit_empty},
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
        '20180113114233-ca3ec2b6206c664f83edc7d21b1e7b68_20180115121547-60008f036e82936b4118b44b259a9230',
        '',
        '---',
        '',
        '***',
        '***',
        '***',
        '',
        '***',
        '***',
        '***',
        '',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
        '---',
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
    ], 'eu_mrv　lower　over　test diff ok');
    # エラーメッセージがエラー分表示されたか確認
    like($count, qr/29/, 'lower　error message ok');
    done_testing;
};

#####################################################################################################################################
########取得対象識別子　「imo_dcs」#################################################################################################
#####################################################################################################################################

# テストデータ準備
my $get_target_id = 'imo_dcs';
my $record_type = '';
my $checkers;
subtest "prepare item json" => sub {

  # tsvの元データは、以下のスプレッドシートで管理している。
  # tsvの改行コードはLFにしておかないとうまく動かないので注意すること。
  # https://docs.google.com/spreadsheets/d/1PuqQ-7DqXVZb89OJvkfb-0lveCo0I558rXCbvdgCO8Q/edit#gid=1797666165&range=AH4
  my $file     = "$test_data_dir/imo_src_of_data_format.tsv";
  my $savefile = "$test_data_dir/imo_src_of_data_format.json";

  open my $fh, "<", $file
    or die "Can't open $file: $!";

  my $json_data = tsv_to_json($fh);
  open(my $out, ">", $savefile);
  print $out $json_data;
  close $out;
  $checkers = create_checker_item();
  is(defined $checkers, 1, 'prepare item');

  done_testing;
};

# 上限値内テスト
subtest "imodcs upper limit" => sub {
  my $id = 'upper_limit';
  my $src    = $checkers->{imo_dcs}{"data_$id"};
  my $expect = $checkers->{imo_dcs}{"expect_$id"};

  format_check($src, $expect);

  done_testing;
};

# 下限値内テスト
subtest "imodcs lower limit" => sub {
  my $id = 'lower_limit';
  my $src    = $checkers->{imo_dcs}{"data_$id"};
  my $expect = $checkers->{imo_dcs}{"expect_$id"};

  format_check($src, $expect);

  done_testing;
};

# 上限値外テスト
subtest "imodcs upper limit over" => sub {
  my $id = 'upper_limit_over';
  my $src    = $checkers->{imo_dcs}{"data_$id"};
  my $expect = $checkers->{imo_dcs}{"expect_$id"};

  format_check($src, $expect);

  done_testing;
};

# 下限値外テスト
subtest "imodcs lower limit over" => sub {
  my $id = 'lower_limit_over';
  my $src    = $checkers->{imo_dcs}{"data_$id"};
  my $expect = $checkers->{imo_dcs}{"expect_$id"};

  format_check($src, $expect);

  done_testing;
};

# 四捨五入切り上げテスト
subtest "round up" => sub {
  my $id = 'round_up';
  my $src    = $checkers->{imo_dcs}{"data_$id"};
  my $expect = $checkers->{imo_dcs}{"expect_$id"};

  format_check($src, $expect);

  done_testing;
};

# 四捨五入切り捨てテスト
subtest "round down" => sub {
  my $id = 'round_down';
  my $src    = $checkers->{imo_dcs}{"data_$id"};
  my $expect = $checkers->{imo_dcs}{"expect_$id"};

  format_check($src, $expect);

  done_testing;
};

# 空値テスト
subtest "empty" => sub {
  my $id = 'empty';
  my $src    = $checkers->{imo_dcs}{"data_$id"};
  my $expect = $checkers->{imo_dcs}{"expect_$id"};

  $expect->{eu_mrv_display} = '---';
  format_check($src, $expect);

  done_testing;
};

# 未定義テスト
subtest "undefined" => sub {
  my $src    = {};
  my $expect = $checkers->{imo_dcs}{expect_default};

  format_check($src, $expect);

  done_testing;
};

# eu_mrv項目の出力テスト
my $check_name = 'beginning_of_year';
subtest $check_name => sub {
  check_eu_mrv_name($check_name);
  done_testing;
};
$check_name = 'end_of_year';
subtest $check_name => sub {
  check_eu_mrv_name($check_name);
  done_testing;
};
$check_name = 'middle_of_year';
subtest $check_name => sub {
  check_eu_mrv_name($check_name);
  done_testing;
};
$check_name = 'summary';
subtest $check_name => sub {
  check_eu_mrv_name($check_name, 'Total');
  done_testing;
};

# 以下、ヘルパーメソッド

sub check_eu_mrv_name {
  my ($check_name, $expect_display) = @_;
  my $src    = {eu_mrv => $check_name};
  my %expect = %{$src};
  if ($expect_display) {
    $check_name = $expect_display;
  } else {
    $check_name =~ s/_/ /g;
  }
  $expect{eu_mrv_display} = $check_name;

  format_check($src, \%expect);
}

# 期待値とフォーマット処理の引数を渡してチェック
sub format_check {
  my ($src, $exp) = @_;
  my $format = DataFormat->new($log);
  my $res = $format->load_format_def($get_target_id, $src, $record_type);

  for my $key (keys(%{$exp})) {
    is($res->{$key}, $exp->{$key}, "$key");
  }
}

sub create_checker_item {
  my $file     = "$test_data_dir/imo_src_of_data_format.json";

  open my $fh, "<", $file
    or die "Can't open $file: $!";

  my $content = do { local $/; <$fh> };
  close $fh;
  my $src = decode_json($content);
  my $src_imo = $src->{'{data}{for_annual}{imo_dcs}'};

  # チェックに使うデータ（フォーマット処理に使うデータと、テストで使う想定値のセット）
  my $results = {
    imo_dcs => {
      data_upper_limit        => {},
      expect_upper_limit      => {},
      data_lower_limit        => {},
      expect_lower_limit      => {},
      data_upper_limit_over   => {},
      expect_upper_limit_over => {},
      data_lower_limit_over   => {},
      expect_lower_limit_over => {},
      data_round_up           => {},
      expect_round_up         => {},
      data_round_down         => {},
      expect_round_down       => {},
      data_empty              => {},
      expect_default          => {},
    }
  };

  my $root = $results->{imo_dcs};
  for my $row (@{$src_imo}) {

    # 上限、下限値用データの生成
    if ($row->{has_limit}) {

      $root->{data_upper_limit}->{$row->{item}}        = $row->{data_upper_limit};
      $root->{expect_upper_limit}->{$row->{item}}      = $row->{expect_upper_limit};
      $root->{data_lower_limit}->{$row->{item}}        = $row->{data_lower_limit};
      $root->{expect_lower_limit}->{$row->{item}}      = $row->{expect_lower_limit};
      $root->{data_upper_limit_over}->{$row->{item}}   = $row->{data_upper_limit_over};
      $root->{expect_upper_limit_over}->{$row->{item}} = $row->{expect_upper_limit_over} eq '""' ? '' : $row->{expect_upper_limit_over};
      $root->{data_lower_limit_over}->{$row->{item}}   = $row->{data_lower_limit_over};
      $root->{expect_lower_limit_over}->{$row->{item}} = $row->{expect_lower_limit_over} eq '""' ? '' : $row->{expect_lower_limit_over};
      $root->{data_round_up}->{$row->{item}}           = $row->{data_round_up};
      $root->{expect_round_up}->{$row->{item}}         = $row->{expect_round_up};
      $root->{data_round_down}->{$row->{item}}         = $row->{data_round_down};
      $root->{expect_round_down}->{$row->{item}}       = $row->{expect_round_down};
    }

    # その他チェック用データの生成
    $root->{data_empty}->{$row->{item}}     = $row->{data_empty} eq '""' ? '' : $row->{data_empty};
    $root->{expect_empty}->{$row->{item}}   = $row->{expect_empty} eq '""' ? '' : $row->{expect_empty};
    $root->{expect_default}->{$row->{item}} = $row->{expect_default} eq '""' ? '' : $row->{expect_default};
  }
  return $results;
}

####################################################################################################################################
done_testing;



