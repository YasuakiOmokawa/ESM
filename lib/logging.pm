umask 000;

use strict;
package logging;

use Exporter();
use Sys::Hostname;
use FileHandle;
use File::Path;
use Time::HiRes qw(gettimeofday);

my @ISA = qw(Exporter);
my @EXPORT_OK = qw();

sub GetFilename{

    my( $filename ) = shift @_;
    my( @work, $logdir, $subdir, $logfile, $basename );

    $filename = $0  if( $filename eq '' );

    @work = split( '/', $filename );
    $basename = pop( @work );
    $basename =~ s#\.cgi#-cgi#;  # .cgi => -cgi
    $basename =~ s#\..*##;

    $subdir   = pop( @work );
    $subdir   = "contents"  unless( $subdir =~ m/\w/ );

    $logdir = "/usr/wvgs/log";
    &mkpath( "$logdir/$subdir", 0, 0777 )  unless( -d "$logdir/$subdir" ); 

    $logfile = "$logdir/$subdir/$basename.log";
    print STDERR "logfile : $logfile\n";
    return $logfile;
}


sub Rotate{
    my( $logfile ) = shift @_;
    my( $limit_size, $i, $oldfile, $newfile );
    my( $lockfile ) = "$logfile.lock";

    $limit_size = 1024 * 1024 * 10;

    open( LOCK, ">$lockfile" );
    flock( LOCK, 2 );

    if( -f $logfile && ( (stat $logfile)[7] > $limit_size ) ){
	umask 000;

	### create new file ###
	open( TMP, ">> $logfile" );
	print(TMP "=== Log Rotated !!!==\n");
	close( TMP );

	system( "cp $logfile $logfile.0" );

	truncate( $logfile, 0 );
    }

    close(LOCK);
    unlink( $lockfile );
}


sub Open{

    my( $pkg, $logfile ) =  @_;
    my( $host ) = hostname();
    my( $login ) = getlogin || (getpwuid($<))[0];
    my( $ret ) = undef;
    my( $obj ) = new FileHandle;

    $logfile = GetFilename()  if( $logfile eq '' );

    Rotate( $logfile );

    ### open logfile ###
    if( $obj->open( ">> $logfile" ) ){

	$obj->autoflush(1);
	$obj->printf( "- %s[%05d] --- start ---\n", &TimeStamp, $$ );

    } else {
	warn( "Can't open Logfile $logfile\n" );
    }

    bless $obj, $pkg;
}


sub Close{
    my $r_obj = shift;

    ### close logfile ###
    $r_obj->Info( "CPU time: %.3fu %.3fs %.3fcu %.3fcs\n", times); 

    printf( $r_obj "- %s[%05d] --- finish  ---\n", TimeStamp(), $$ );
    close( $r_obj );
}


sub Info{
    my $r_obj = shift;
    printf $r_obj "I %s[%05d] %s", &TimeStamp, $$, Format( @_ );
}

sub Warn{
    my $r_obj = shift;
    printf $r_obj "W %s[%05d] %s", &TimeStamp, $$, Format( @_ );
    warn Format( @_ ), "\n";
}

sub Error{
    my $r_obj = shift;
    printf $r_obj "E %s[%05d] %s", &TimeStamp, $$, Format( @_ );
    warn Format( @_ ), "\n";
}

sub Die{
    my $r_obj = shift;
    printf $r_obj "E %s[%05d] %s", &TimeStamp, $$, Format( @_ );
    die Format( @_ ), "\n";
}

sub Format{
    my( $format );
    if( @_ > 1 ){ $format = shift; } else { $format = "%s"; }

    sprintf( $format, @_ );
}


sub TimeStamp{
    my($tv_sec, $tv_usec) = gettimeofday;

    my( $t_sec, $t_min, $t_hour, $t_day, $t_mon, $t_year )
	= localtime( $tv_sec );

    return sprintf( "%04d/%02d/%02d %02d:%02d:%02d.%03d", 
	     $t_year+1900, $t_mon+1, $t_day, $t_hour, $t_min, $t_sec,
	     $tv_usec/1000 );
}


sub OpenLog {  shift; open_logfile( @_ );  }
sub CloseLog{  shift; close_logfile();     }
sub PrintLog{
    my $r_obj = shift;
    my $msg = shift;
    chomp( $msg );
    Info( $r_obj, $msg );
}

1;