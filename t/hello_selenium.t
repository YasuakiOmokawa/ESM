use strict;
use warnings;

# use Selenium::Remote::Driver;
use Selenium::Chrome;

# my $driver = Selenium::Remote::Driver->new;
my $driver = Selenium::Chrome->new(
  binary => 'C:/Users/texsol-omokawa/Downloads/chromedriver_win32/chromedriver.exe',
  custom_args => '--headless --log-path=C:/Users/texsol-omokawa/Downloads/chromedriver_win32/exec_log.txt',
  );
$driver->get('http://www.google.com');
print $driver->get_title . "\n";
$driver->shutdown_binary;
