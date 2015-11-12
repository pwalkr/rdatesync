#!/usr/bin/perl

if ($#ARGV < 0) {
	&usage();
	exit 0;
}
&readConf($ARGV[0]);

sub usage {
	print "Usage:\n"
		. "    rdatesync.pl [config file]\n"
		. "\n"
		. "    config file must be of the format:\n"
		. "        destination /path/to/backups/destination\n"
		. "        backup /path/to/backup\n"
		. "\n";
}

sub readConf {
	my $filename = shift;
	if (open CFH, $filename) {
		while (<CFH>) {
			if ($_ =~ /^destination\s+(.*)$/) {
				print "destination: $1\n";
			}
			elsif ($_ =~ /^backup\s+(.*)$/) {
				print "backup: $1\n";
			}
		}
		close($cfh);
	}
}
