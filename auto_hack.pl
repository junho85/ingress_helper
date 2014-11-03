#!/usr/local/bin/perl

use warnings;
use strict;
use utf8;

use Config::IniFiles;
use Data::Dumper;

use POSIX;

my $cnt = 1;

my $cfg = new Config::IniFiles(-file => "config.ini");

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
		print "error";
	} else {
		# didn't
	}

} # end of while

sub hack {

	print "[".get_datetime()."] try $cnt start";
	print "\n";

	my @devices = (
	);

	# device check
	my $cmd = "adb devices";
	my @device_info_lines = `$cmd`;

	foreach my $line (@device_info_lines) {
		chomp($line);
		#print $line."\n";

		if ($line =~ /^\*/) {
			#print "pass $line\n";
			next;
		} elsif ($line =~ /^List/) {
			#print "pass $line\n";
			next;
		} elsif ($line =~ /(\S+)\t(device)/) {
			my $device_id = $1;
			my $type = $2;
			print "device_id=$device_id; type=$type\n";

			#print "cfg=";
			#print Dumper(\$cfg);
			#print "\n";
			my $section = get_section_by_id($cfg, $device_id);
			print "section=$section\n";
			if ($section) {
				print "add device $device_id\n";
				push @devices, $device_id;
			}
		} else {
			print "device not found or error: $line\n";
		}
	}

	foreach my $device_id (@devices) {

		print "start $device_id\n";

		my ($portal_x, $portal_y, $hack_x, $hack_y) = get_positions($device_id);

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

sub get_section_by_id {
	my $cfg = shift;
	my $id = shift;

	foreach my $section ($cfg->Sections) {
		if ($id eq $cfg->val($section, 'id')) {
			return $section;
		}
	}
}

sub get_positions {
	my $device_id = shift;

	my $section = get_section_by_id($cfg, $device_id);

	my $portal_x = $cfg->val($section, 'portal_x');
	my $portal_y = $cfg->val($section, 'portal_y');

	my $hack_x = $cfg->val($section, 'hack_x');
	my $hack_y = $cfg->val($section, 'hack_y');
	
	return ($portal_x, $portal_y, $hack_x, $hack_y);
}

sub screen_check {
	my $device_id = shift;

	my @lines = `adb -s $device_id shell dumpsys input_method`;

	foreach my $line (@lines) {
		if ($line =~ /mScreenOn=true/) {
			return "on";
		} elsif ($line =~ /mScreenOn=false/) {
			return "off";
		}
	}
	return "error";
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
