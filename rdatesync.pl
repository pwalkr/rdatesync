#!/usr/bin/perl

my $DESTINATION;
my $BACKUP;

if ($#ARGV < 0) {
	&usage();
	exit 0;
}
&readConf($ARGV[0]);
&rsync();

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
				$DESTINATION = $1;
			}
			elsif ($_ =~ /^backup\s+(.*)$/) {
				print "backup: $1\n";
				$BACKUP = $1;
			}
		}
		close($cfh);
	}
}

sub rsync {
	my $date_today = `date +%Y-%m-%d`;
	my $command = "/usr/bin/rsync"
		. " --archive"
		. " --delete";

	chomp($date_today);
	$command .= " $BACKUP";
	$command .= " $DESTINATION/$date_today";

	system("mkdir -p '$DESTINATION'");

	print "$command\n";
	system("$command");
}
