#!/usr/bin/perl

use Test::Simple tests => 16;

my $WORKSPACE = "/tmp/rds_ws";
my $RDATESYNC = `printf \$(cd \$(dirname $0) && pwd)/rdatesync.pl`;

sub _setup {
	system("rm -rf $WORKSPACE");

	system("mkdir -p '$WORKSPACE'");
}

sub _teardown {
	system("rm -rf $WORKSPACE");
}

sub _runTest {
	my $test = shift;
	&_setup();
	&{$test}();
}

=head2 TestUsageOutput

If run without arguments, rdatesync.pl should print usage.

=cut

sub TestUsageOutput {
	my $output = `perl $RDATESYNC`;
	ok( $output =~ "Usage" );
}

=head2 TestConfigRead

By default, rdatesync.pl will print the contents of its configuration as it
parses the config. This allows a test to confirm that it is reading the config
correctly.

=cut

sub TestConfigRead {
	my $output;
	my $config = "$WORKSPACE/rds_test.conf";
	my $destination = "$WORKSPACE/archive";
	my $source = "$WORKSPACE/source";

	open (CFH, '>', $config) or die "Failed to generate test conf file";
	print CFH "destination $destination\n";
	print CFH "backup $source\n";
	close(CFH);

	$output = `perl $RDATESYNC $config 2>&1`;
	ok( $output =~ "destination: $destination" );
	ok( $output =~ "backup: $source" );
}

=head2 TestConfigComments

Comments should be ignored.

=cut

sub TestConfigComments {
	# backup /thing works
	# #backup /thing does not work
}

=head2 TestConfigTrailingSlash

rsync behaves differently if the source directories have trailing slashes.

To back up local/source/file,

	rsync local/source remote

will produce

	remote/source/file

whereas

	rsync local/source/ remote

will produce

	remote/file

To avoid potential name conflicts between the contents of a backup and
a separate backup, rdatesync.pl should strip any trailing slash

=head3 TODO

	Print ERROR message that a backup had a trailing slash

=cut

sub TestConfigTrailingSlash {
}

=head2 TestConfigDuplicateBackup

Since rsync produces a directory containing the basename of each source input,
these two backups:

	destination /archive
	backup /source/mybackup
	backup /source/subdir/mybackup

Would produce a single C</archive/yyyy-mm-dd/mybackup> directory with a
combination of contents from both backup directories. This is unpredictable.

rdatesync.pl will take the first instance of an I<mybackup> and issue a warning
if it needs to skip a subsequent directory.

=cut

=head2 TestConfigDuplicateBackup

=head3 TODO

=cut

sub TestConfigDuplicateBackup {
}

=head2 TestConfigNoDestination

=head3 TODO

	Warn user that no destination was configured

=cut

sub TestConfigNoDestination {
}

=head2 TestConfigNoBackups

=head3 TODO

	Warn no backups were specified or no specified backups were present.

=cut

sub TestConfigNoBackups {
}

=head2 TestFirstBackup

The first backup (and each day's backup) will produce a folder with today's
date (yyyy-mm-dd) and a sub-folder for each backup in the config. E.g.

backups.conf:

	destination /archive
	backup /source/myfolder

Will produce (if run on January 2nd, 2000):

	/archive/2000-01-02/myfolder

=cut

sub TestFirstBackup {
	my $destination = "$WORKSPACE/archive";
	my $backup = "$WORKSPACE/source";
	my $date_today = `date +%Y-%m-%d`;
	my $source_file_path;
	my $target_file_path;

	chomp($date_today);
	$source_file_path = "$backup/testFile";
	$target_file_path = "$destination/$date_today/source/testFile";

	&_mkfile($source_file_path);

	&_runconf( &_writeconf(
		$destination,
		$backup
	));

	ok( -f "$target_file_path" );
	ok(  &_md5sum("$target_file_path") eq &_md5sum("$source_file_path") );
	ok(  &_inode("$target_file_path") ne &_inode("$source_file_path") );
}

=head2 TestPathSpaces

Spaces in paths are notorious for breaking things. Test that we can back up
using a destination and backups with spaces in the path names

The following are tested:

=over

=item Destination path contains a space

=item Backup path contains a space

=item Backup basename contains a space

=back

=cut

sub TestPathSpaces {
}

=head2 TestMultiBackup

Multiple folders can be backed up to destination by specifying additional
"backup" options in the configuration file

=cut

sub TestMultiBackup {
	my $destination = "$WORKSPACE/archive";
	my $backup1 = "$WORKSPACE/source1";
	my $backup2 = "$WORKSPACE/source2";
	my $date_today = `date +%Y-%m-%d`;
	my $source_file_path1 = "$backup1/testFile";
	my $source_file_path2 = "$backup2/testFile";
	my $target_file_path1;
	my $target_file_path2;
	my $config = &_writeconf(
		$destination,
		$backup1,
		$backup2
	);

	chomp($date_today);
	$target_file_path1 = "$destination/$date_today/source1/testFile";
	$target_file_path2 = "$destination/$date_today/source2/testFile";

	&_mkfile($source_file_path1);
	&_mkfile($source_file_path2);

	&_runconf($config);

	ok( -f "$target_file_path1" );
	ok(  &_md5sum("$target_file_path1") eq &_md5sum("$source_file_path1") );
	ok(  &_inode("$target_file_path1") ne &_inode("$source_file_path1") );
	ok( -f "$target_file_path2" );
	ok(  &_md5sum("$target_file_path2") eq &_md5sum("$source_file_path2") );
	ok(  &_inode("$target_file_path2") ne &_inode("$source_file_path2") );
}

=head2 TestSecondBackupNoChange

If a file has not changed between backups, a hard link can be used to avoid
duplicating data on the disk. This significantly reduces the disk space needed
to store multiple days. Rsync can do this using the --link-dest argument

Test passes if inodes match between today/yesterday for all files.

=cut

sub TestSecondBackupNoChange {
	# Check for all hard links to previous backup
	my $date_today = `printf \$(date +%Y-%m-%d)`;
	my $date_yesterday = `printf \$(date --date="yesterday" +%Y-%m-%d)`;
	my $file_original =  "$WORKSPACE/folder/file";
	my $file_today =     "$WORKSPACE/target/$date_today/folder/file";
	my $file_yesterday = "$WORKSPACE/target/$date_yesterday/folder/file";
	my $conf;

	&_mkfile("$file_original");

	my $conf = &_writeconf(
		"$WORKSPACE/target",
		"$WORKSPACE/folder"
	);
	&_runconf($conf);

	system("mv $WORKSPACE/target/$date_today $WORKSPACE/target/$date_yesterday");

	&_runconf($conf);

	ok ( -f $file_today and -f $file_yesterday );
	ok ( &_inode($file_today) == &_inode($file_yesterday) );

	# These two are more of an rsync validation, that the extra --link-dest
	# flag doesn't change files or create hard links where there shouldn't be.
	ok ( &_md5sum($file_original) == &_md5sum($file_today) );
	ok ( &_inode($file_original) != &_inode($file_today) );
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

=head1 Utility Functions

=head2 _dirname

Return a path with all preceding directories removed (.*/)

=cut

sub _dirname {
	my $path = shift;
	$path =~ s/\/[^\/]+$//;
	return $path;
}

=head2 _inode

Return the inode number of a file. -1 if missing

=cut

sub _inode {
	my $filename = shift;
	if (-f $filename and `/bin/ls -i '$filename' 2>/dev/null` =~ /^([0-9]+)\s/) {
		return $1;
	}
	return -1;
}

=head2 _md5sum

Return the md5sum of a file. Otherwise undefined

=cut

sub _md5sum {
	my $filename = shift;
	if (-f $filename and `/usr/bin/md5sum '$filename' 2>/dev/null` =~ /^([a-z0-9]+)\s/) {
		return $1;
	}
}

=head2 _mkfile

Make a file and seed with its name as contents

=cut

sub _mkfile {
	my $file = shift;
	system("mkdir -p " . &_dirname($file));
	open (FH, '>', $file) or die "Failed to generate $file";
	print FH $file;
	close(FH)
}

=head2 _writeconf

Generate a configuration file from input destination and backup list. Return
a file path string that can be used with L</_runconf>

=cut

sub _runconf {
	my $config = shift;
	return `perl $RDATESYNC '$config' 2>&1`;
}

=head2 _runconf

Run rdatesync.pl with a configuration file. E.g. one generated by L</_writeconf>

=cut

sub _writeconf {
	my $destination = shift;
	my @backups = @_;
	my $config = "$WORKSPACE/testsync.conf";

	open (CFH, '>', $config) or die "Failed to write test configuration file";
	print CFH "destination $destination\n";
	foreach (@backups) {
		print CFH "backup $_\n";
	}
	close(CFH);

	return $config;
}

&_runTest(\&TestUsageOutput);
&_runTest(\&TestConfigRead);
&_runTest(\&TestFirstBackup);
&_runTest(\&TestMultiBackup);
&_runTest(\&TestSecondBackupNoChange);
&_teardown();
