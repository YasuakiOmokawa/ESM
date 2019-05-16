use strict;
use warnings;

use File::Basename;
use Test::More;
use Selenium::Waiter qw(wait_until);
use Test::Selenium::Chrome;

# add search path to our modules
my $MY_DIR  = "";
BEGIN {
  $MY_DIR = dirname(__FILE__);
};
use lib "$MY_DIR/../../lib";
use lib '/usr/amoeba/lib/perl';

use logging;

# Static settings
my $top_dir = dirname(__FILE__) . "/../../";
my $driver_dest = "$top_dir/t/util/driver";
my $prog_name = basename(__FILE__);
my $prog_base = $prog_name;
$prog_base =~ s/^(.*)\..*$/$1/;
my $output_dest = "$top_dir/t/output/$prog_base";

# テストしたいブラウザ用のドライバを立ち上げる
my $driver = Test::Selenium::Chrome->new(
  # webdriverのパスを指定
  binary => "$driver_dest/chromedriver.exe",
  # ver.1.27で足りない要素を指定
  webelement_class => 'Test::Selenium::Remote::WebElement',
  # ヘッドレス(GUI非表示)で立ち上げるために設定
  extra_capabilities => {chromeOptions => {args => ['headless', 'disable-gpu', 'window-size=1920,1080', 'no-sandbox' ]}}
  );

# ログイン
my ($user_id, $password) = ('hoge_id', 'hoge_pass');
$driver->get('for_test_url');
$driver->title_is('Emission Status Monitoring', 'top page title');
## 必要な要素の確認
wait_until { $driver->find_element_ok("button.login-btn", "css", 'enable login button') };
## ブラウザ操作の実施
$driver->find_element_by_css("#login-email")->send_keys($user_id);
$driver->find_element_by_css("#login-password")->send_keys($password);
## スクリーンショットの取得
$driver->capture_screenshot("$output_dest/1_login.png");
## 次操作のためのトリガーとなるアクション
$driver->find_element_by_css("button.login-btn")->click();

# フリートリスト画面から[List of Voyage]へ遷移
## 必要な要素の確認
wait_until { $driver->find_element_ok(".dgc-list-body > tr:nth-child(1)", "css", 'get fleet list') };
## スクリーンショットの取得
$driver->capture_screenshot("$output_dest/2_fleetlist.png");
## 次操作のためのトリガーとなるアクション
my $link_list_of_voyage = $driver->find_element_by_css(".dgc-list-body > tr:nth-child(1) > td:nth-child(4) > a:nth-child(2)");
$link_list_of_voyage->click();

# List of Voyage画面からダウンロードリンクの数を表示
my $dl_elem;
## 必要な要素の確認
wait_until {
  $dl_elem = $driver->find_element("#dl", "css");
  $dl_elem->is_enabled;
  $dl_elem->click;
};
$driver->click_element_ok("#dl", "css", " download link");
## ブラウザ操作の実施
$dl_elem->click();
## スクリーンショットの取得
$driver->capture_screenshot("$output_dest/3_download_list.png");
## ダウンロードリンクの数が想定と合っているか確認
my @dl_list = $driver->find_elements(".download-add-window", "css");
is(scalar @dl_list, 1, 'valid nums of download list');
is($dl_list[0]->get_text, 'List of Voyage', 'download type');

# テスト完了
$driver->quit;
done_testing;
