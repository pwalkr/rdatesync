#!/usr/bin/perl

use warnings;
use strict;

my $DESTINATION;
my @BACKUPS = ();
my @MOUNTS = ();
my @DAYS = ();
my $DATE_TODAY = `date +%Y-%m-%d`;
chomp($DATE_TODAY);
my $LINK_DEST = "";
my $MAX_DAYS = 7;
my $RESULTS_DIR = "";

if ($#ARGV < 0) {
	&usage();
	exit 0;
}
&readConf($ARGV[0]);
&getDays();
&rsync();
#&trimDays();

sub usage {
	print "Usage:\n"
		. "    rdatesync.pl [config file]\n"
		. "\n"
		. "    config file must be of the format:\n"
		. "        destination /path/to/backups/destination\n"
		. "        backup /path/to/backup\n"
		. "        backup /path/to/another/backup\n"
		. "        backup ...\n"
		. "        mount /path/to/mount/point\n"
		. "        mount ...\n"
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
			elsif ($_ =~ /^results\s+(.*)$/) {
				if (! -e $RESULTS_DIR or -d $RESULTS_DIR) {
					print "results $1\n";
					$RESULTS_DIR = $1;
				}
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
	my $command = "/usr/bin/rsync"
		. " --archive"
		. " --delete";

	if ($LINK_DEST) {
		$command .= " --link-dest \"$LINK_DEST\"";
	}

	if ($RESULTS_DIR) {
		system('mkdir -p "' . $RESULTS_DIR . '"');
		$command .= " --itemize-changes";
		$command .= ' --log-file "' . $RESULTS_DIR . '/' . $DATE_TODAY . '.log"';
	}

	foreach (@BACKUPS) {
		$command .= " \"$_\"";
	}
	$command .= " \"$DESTINATION/$DATE_TODAY\"";

	system("mkdir -p \"$DESTINATION\"");

	print "$command\n";
	system("$command");

	unshift(@DAYS, $DATE_TODAY);
}

sub trimDays {
	while ($#DAYS ge $MAX_DAYS) {
		system("rm -rf \"$DESTINATION/$DAYS[$#DAYS]\"");
		pop(@DAYS);
	}
}
