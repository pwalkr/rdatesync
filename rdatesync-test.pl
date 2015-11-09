#!/usr/bin/perl

use Test::Simple tests => 1;

my $RDATESYNC = `printf \$(cd \$(dirname $0) && pwd)/rdatesync.pl`;

sub PrintUsageNoArgs {
	my $output = `perl $RDATESYNC`;
	ok( $output =~ "Usage" );
}

&PrintUsageNoArgs();
