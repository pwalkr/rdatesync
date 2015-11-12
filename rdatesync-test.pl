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

&PrintUsageNoArgs();
&TestBasicConfig();
