#!/usr/local/bin/perl

use warnings;
use strict;
use utf8;

use Term::ANSIColor;
use POSIX;

my $cnt = 1;

my $S2_ID = '8647374e';
my $NOTE2_ID = '42f60b19af259f7f';
my $NEXUS_ID = '0149A8CD0F01100E';

while (1) {

	my $timeout = 60*7;

	eval {
		local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
		alarm $timeout;

		# do something
		hack();

		alarm 0;
	};

	if ($@) {
		die unless $@ eq "alarm\n"; # propagate unexpected errors
		# timed out
		print colored("error", 'bold red on_blue');

	} else {
		# didn't
	}

} # end of while

sub hack {

	print colored("[".get_datetime()."] try $cnt start", 'bold yellow on_magenta');
	print "\n";

	my @devices = (
		#$S2_ID,
		#$NOTE2_ID,
		#$NEXUS_ID,
	);

	# device check
	my $cmd = "adb devices";
	my @device_info_lines = `$cmd`;

	foreach my $line (@device_info_lines) {
		chomp($line);
		print $line."\n";

		if ($line =~ /^\*/) {
			#print "pass $line\n";
			next;
		} elsif ($line =~ /^List/) {
			#print "pass $line\n";
			next;
		} elsif ($line =~ /(\S+)\t(device)/) {
			my $device_id = $1;
			print "1:$1 2:$2\n";

			if ($device_id eq $S2_ID) {
				push @devices, $S2_ID;
			}

			if ($device_id eq $NOTE2_ID) {
				push @devices, $NOTE2_ID;
			}

			if ($device_id eq $NEXUS_ID) {
				push @devices, $NEXUS_ID;
			}

		} else {
			print "device not found or error: $line\n";
		}
	}

	foreach my $device_id (@devices) {

		print "start $device_id\n";

		my $portal_x = 0;
		my $portal_y = 0;

		my $hack_x = 0;
		my $hack_y = 0;

		if ($device_id eq $S2_ID) {
			print colored("S2", 'bold yellow');
			print "\n";
			$portal_x = 200;
			$portal_y = 600;

			$hack_x = 400;
			$hack_y = 300;
		} elsif ($device_id eq $NOTE2_ID) {
			print colored("NOTE 2", 'bold yellow');
			print "\n";
			$portal_x = 350;
			$portal_y = 900;

			$hack_x = 500;
			$hack_y = 500;
		} elsif ($device_id eq $NEXUS_ID) {
			print colored("NEXUS", 'bold yellow');
			print "\n";
			$portal_x = 300;
			$portal_y = 900;

			$hack_x = 500;
			$hack_y = 400;
		}

		print "$device_id screen turn on\n";
		my $screen = screen_control($device_id, "on");
		sleep(10);

		print $screen."\n";


		# touch portal (approximate point)
		print "touch portal $portal_x $portal_y\n";
		$cmd = "adb -s $device_id shell input tap $portal_x $portal_y";
		print $cmd."\n";
		system($cmd);

		sleep(2);

		# touch hack
		print "touch hack $hack_x $hack_y\n";
		$cmd = "adb -s $device_id shell input tap $hack_x $hack_y";
		print $cmd."\n";
		system($cmd);

		sleep(12);

		$cmd = "adb -s $device_id shell input tap $hack_x $hack_y";
		print $cmd."\n";
		system($cmd); # close result

		sleep(2);

		print "$device_id screen turn off\n";
		screen_control($device_id, "off");
	}

	system("adb kill-server"); # kill adb

	print "try $cnt end\n";
	$cnt++;

	sleep(300);
}

sub screen_check {
	my $device_id = shift;

	my $result = `adb -s $device_id shell dumpsys input_method | grep mScreenOn`;
	
	if ($result =~ /mScreenOn=true/) {
		return "on";
	} elsif ($result =~ /mScreenOn=false/) {
		return "off";
	} else {
		return "error";
	}
}

sub screen_control {
	my $device_id = shift;
	my $command = shift;

	my $screen = screen_check($device_id);

	if ($command ne $screen) {
		system("adb -s $device_id shell input keyevent 26");
	}
	return $screen;
}

sub get_datetime {
	return strftime("%Y-%m-%d %H:%M:%S", localtime(time));
}

