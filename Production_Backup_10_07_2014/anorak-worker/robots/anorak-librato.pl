#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

######## CONFIGURATION TUNABLES ########

my $redis_server = 'frawspcts01:6379';

########################################

package AnorakStats;
require "AnorakStats.pm";

use Redis;

# connect to redis
my $stats = AnorakStats->new();
$stats->connect($redis_server);

while (1) {
	# get list of retailers
	my @retailers = $stats->retailers;

	# print header
	my $datestring = localtime();
	print $datestring, "\n";
	printf "Retailer             --rate-- --num-- --min-- --avg-- --max--\n";
	printf "-------------------------------------------------------------\n";

	# iterate through retailers
	foreach (@retailers) {
		# call display stats for last 300 seconds
		$stats->printstats($_, 60,0);
	}

	# print footer
	printf "-------------------------------------------------------------\n\n";
	sleep(30);
}
