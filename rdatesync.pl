#!/usr/bin/perl

if ($#ARGV < 0) {
	&usage();
	exit 0;
}

sub usage {
	print "Usage:\n"
		. "    rdatesync.pl [config file]\n";
}
