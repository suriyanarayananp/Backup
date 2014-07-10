package AnorakStats;

use v5.10.1;
use strict;
use warnings;

use Redis;
use Try::Tiny;



# constructor
# arguments: none
# returns: self
sub new {
	my $class = shift;
	my $self = {};

	bless($self, $class);
	return $self;
}



# connects to the supplied server
# arguments: server (string)
# returns: self->{redis}
sub connect {
	my $self = shift;
	my $redis_server = shift;

	try {
		$self->{redis} = Redis->new(server => $redis_server, reconnect => 10, every => 100, cnx_timeout => 5, read_timeout => 0.5, write_timeout => 1.2);
	} catch {
		return;
	};

	return $self->{redis};
}



# increments the given retailer_key
# arguments: retailer, key (strings)
# returns: nothing
sub inc {
	my $self = shift;
	my $retailer = shift;
	my $key = shift;

	$self->{redis}->incr($retailer . "_" . $key)
}



# gets the given retailer_key
# arguments: retailer, key (strings)
# returns: value of retailer_key
sub get {
	my $self = shift;
	my $retailer = shift;
	my $key = shift;

	return $self->{redis}->get($retailer . "_" . $key);
}



# sets the given retailer_key
# arguments: retailer, key, value (strings)
# returns: nothing
sub set {
	my $self = shift;
	my $retailer = shift;
	my $key = shift;
	my $val = shift;

	$self->{redis}->set($retailer . "_" . $key => $val);
}



# adds a timing to a retailer
# arguments: retailer, object, timing (strings)
# returns: nothing
sub zadd {
	my $self = shift;
	my $retailer = shift;
	my $object = shift;
	my $timing= shift;

	$self->{redis}->zadd($retailer . "_timings", time, time . "_" . $object . "_" . $timing);
}



# returns an array with the names of the retailers for which _timings data exist
# arguments: none
# returns: array of retailers (strings)
sub retailers {
	my $self = shift;
	my @retailers;

	my @data = $self->{redis}->keys("*_timings");

	foreach (@data) {
		my $retailer = $_;
		$retailer =~ s/_timings//;
		push(@retailers, $retailer);;;;
	}

	return sort @retailers;
}



# prints a string summarizing the activity for the given retailer at the given time period
# arguments: retailer, period
# returns: nothing
sub printstats {
	my $self = shift;
	my $retailer = shift;
	my $period = shift;

	my @data = $self->{redis}->zrangebyscore($retailer . "_timings", time-$period, "+inf");

	my $timing_num = 0;
	my $timing_min;
	my $timing_avg;
	my $timing_max;
	my $timing_sum;
	my $rate;

	foreach (@data) {
		my $timing = $_;
		$timing =~ s/^.*_.*_//;

		# increment counter
		$timing_num++;

		# increment sum
		$timing_sum += $timing;

		# set min if undefined or if bigger than current value
		if (!defined $timing_min || defined $timing_min && $timing < $timing_min) {
			$timing_min = $timing;
		}

		# set max if undefined or if smaller than current value
		if (!defined $timing_max|| defined $timing_max && $timing > $timing_max) {
			$timing_max = $timing;
		}
	}

	if ($timing_num > 0) {
		$timing_avg = $timing_sum / $timing_num;
		$rate = $timing_num / $period;
		printf "%-20s %8.2f %7d %7.2f %7.2f %7.2f\n", $retailer, $rate, $timing_num, $timing_min, $timing_avg, $timing_max;
	} else {
		$timing_min = 0;
		$timing_avg = 0;
		$timing_max = 0;
		$timing_sum = 0;
		$rate = 0;
	}
}

1;
