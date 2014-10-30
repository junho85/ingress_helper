#!/usr/local/bin/perl

#use warnings;
#use strict;
#use utf8;

my $cnt = 1;

my $S2_ID = '***';
my $NOTE2_ID = '***';
my $NEXUS_ID = '***';

while (1) {
	print "try $cnt start\n";

	my @devices = (
		#$S2_ID,
		#$NOTE2_ID,
		$NEXUS_ID,
	);

=pod
	my $timeout = 5;

	eval {
		local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
		alarm $timeout;
		# do something
		alarm 0;
	};

	if ($@) {
		die unless $@ eq "alarm\n"; # propagate unexpected errors
		# timed out
	} else {
		# didn't
	}
=cut

=pod
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
=cut

	foreach my $device_id (@devices) {

		print "start $device_id\n";

		my $portal_x = 0;
		my $portal_y = 0;

		my $hack_x = 0;
		my $hack_y = 0;

		#print "$device_id screen turn on\n";
		#my $screen = screen_control($device_id, "on");
		#sleep(10);

		#print $screen."\n";

		unless ($device_id eq $NEXUS_ID) {
			next;
		}

		$item_x = 300;
		$item_y = 300;

		$recycle_x = 600;
		$recycle_y = 1100;
=pod
		if ($device_id eq $S2_ID) {
			$portal_x = 200;
			$portal_y = 600;

			$hack_x = 400;
			$hack_y = 300;
		} elsif ($device_id eq $NOTE2_ID) {
			$portal_x = 350;
			$portal_y = 900;

			$hack_x = 500;
			$hack_y = 500;
		} elsif ($device_id eq $NEXUS_ID) {
			$portal_x = 300;
			$portal_y = 900;

			$hack_x = 500;
			$hack_y = 400;
		}
=cut

		print "touch item $item_x $item_y\n";
		$cmd = "adb -s $device_id shell input tap $item_x $item_y";
		print $cmd."\n";
		system($cmd);

		sleep(1);

		# touch recycle 
		print "touch recycle $recycle_x $recycle_y\n";
		$cmd = "adb -s $device_id shell input tap $recycle_x $recycle_y";
		print $cmd."\n";
		system($cmd);

		sleep(0.5);

		# back
		#$cmd = "adb -s $device_id shell input keyevent 4";
		#print $cmd."\n";
		#system($cmd); # close result

		sleep(0.5);

		#print "$device_id screen turn off\n";
		#screen_control($device_id, "off");
	}

	#system("adb kill-server"); # kill adb

	print "try $cnt end\n";
	$cnt++;

	sleep(0.5);
} # end of while

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
