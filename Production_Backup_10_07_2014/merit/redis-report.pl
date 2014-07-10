#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

######## CONFIGURATION TUNABLES ########

my $redis_server = 'frawspcts01:6379';

########################################

package AnorakStats;
require "/opt/anorak-worker/AnorakStats.pm";

use Redis;

# connect to redis
my $stats = AnorakStats->new();
$stats->connect($redis_server);

# get list of retailers
my @retailers = $stats->retailers;

# print header
printf "Retailer             --rate-- --num-- --min-- --avg-- --max--\n";
printf "-------------------------------------------------------------\n";

# iterate through retailers
foreach (@retailers) {
	# call display stats for last 300 seconds
	$stats->printstats($_, 300);
}
