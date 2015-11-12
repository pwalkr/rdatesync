#!/usr/bin/perl

use Test::Simple tests => 3;

my $RDATESYNC = `printf \$(cd \$(dirname $0) && pwd)/rdatesync.pl`;

sub PrintUsageNoArgs {
	my $output = `perl $RDATESYNC`;
	ok( $output =~ "Usage" );
}

# TestBasicConfig - test that rdatesync.pl can read a config file
sub TestBasicConfig {
	my $output;
	my $config = "/tmp/rds_test.conf";
	my $destination = "/tmp/archive";
	my $source = "/tmp/source";

	open (CFH, '>', $config) or die "Failed to generate test conf file";
	print CFH "destination $destination\n";
	print CFH "backup $source\n";
	close(CFH);

	$output = `perl $RDATESYNC $config`;
	ok( $output =~ "destination: $destination" );
	ok( $output =~ "backup: $source" );
}

sub TestConfigComments {
	# backup /thing works
	# #backup /thing does not work
}

# TestFirstBackup - can create backup destination and first backup
sub TestFirstBackup {
}

# TestMultiBackup - Test that multiple directories can be backed up
sub TestMultiBackup {
}

# TestTrailingSlash - Test that backup directives can have trailing slashes
sub TestTrailingSlash {
}

# TestSecondBackup - can create second backup
sub TestSecondBackup {
	# Check for all hard links to previous backup
}

# TestBadBackupSource - do not break if conf contains a nonexistant source directory
sub TestBadBackupSource {
}

# TestDefaultDays - test that a default of 7 days are backed up
sub TestDefaultDays {
}

# TestMaxDays - test that "days X" means no more than X days are backed up
sub TestMaxDays {
}

# Backup Log - in each days backup, compared to previous day.

# TestLogFirst - Log should note that there is no previous backup. All files new
sub TestLogFirst {
}

# TestLogSecond - Log should note which day it is compared to. No modified files
sub TestLogSecond {
}

# TestLogNewFile - test that the nightly log shows a new file
sub TestLogNewFile {
}

# TestLogModifiedFile - test that the nightly log shows a modified file
sub TestLogModifiedFile {
}

# TestLogRemoveFile - test that the nightly log shows a removed file
sub TestLogRemoveFile {
}

# Utility functions

# _inode - return the inode number of a file. -1 if missing
sub _inode {
	my $filename = shift;
	if (-f $filename and `/bin/ls -i '$filename' 2>/dev/null` =~ /^([0-9]+)\s/) {
		return $1;
	}
	return -1;
}

# _md5sum - return the md5sum of a file. Otherwise undefined
sub _md5sum {
	my $filename = shift;
	if (-f $filename and `/usr/bin/md5sum '$filename' 2>/dev/null` =~ /^([a-z0-9]+)\s/) {
		return $1;
	}
}

&PrintUsageNoArgs();
&TestBasicConfig();
