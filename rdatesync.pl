#!/usr/bin/perl

use warnings;
use strict;

my $DESTINATION;
my @BACKUPS = ();
my @DAYS = ();
my $DATE_TODAY = `date +%Y-%m-%d`;
chomp($DATE_TODAY);
my $LINK_DEST;

if ($#ARGV < 0) {
	&usage();
	exit 0;
}
&readConf($ARGV[0]);
&getDays();
&rsync();

sub usage {
	print "Usage:\n"
		. "    rdatesync.pl [config file]\n"
		. "\n"
		. "    config file must be of the format:\n"
		. "        destination /path/to/backups/destination\n"
		. "        backup /path/to/backup\n"
		. "        backup /path/to/another/backup\n"
		. "        backup ...\n"
		. "\n";
}

sub readConf {
	my $filename = shift;
	if (open CFH, $filename) {
		while (<CFH>) {
			if ($_ =~ /^destination\s+(.*)$/) {
				print "destination: $1\n";
				$DESTINATION = $1;
			}
			elsif ($_ =~ /^backup\s+(.*)$/) {
				print "backup: $1\n";
				push(@BACKUPS, $1);
			}
		}
		close(CFH);
	}
}

sub getDays {
	if (opendir DH, $DESTINATION) {
		while (readdir DH) {
			if (-d "$DESTINATION/$_" and $_ =~ /^\d{4}-\d{2}-\d{2}$/) {
				push(@DAYS, $_);
			}
		}
		closedir DH;
		# Most recent (highest) day first
		@DAYS = sort {$b cmp $a} @DAYS;
		if ($#DAYS >= 0) {
			if ($DAYS[0] ne $DATE_TODAY) {
				$LINK_DEST = "$DESTINATION/$DAYS[0]";
			}
		}
	}
}

sub rsync {
	my $DATE_TODAY = `date +%Y-%m-%d`;
	my $command = "/usr/bin/rsync"
		. " --archive"
		. " --delete";

	if ($LINK_DEST) {
		$command .= " --link-dest $LINK_DEST";
	}

	foreach (@BACKUPS) {
		$command .= " $_";
	}
	$command .= " $DESTINATION/$DATE_TODAY";

	system("mkdir -p '$DESTINATION'");

	print "$command\n";
	system("$command");
}
