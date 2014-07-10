#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

# Location of the config file with all settings
my $ini_file = '/opt/anorak-worker/anorak-worker.ini';

# Anorak packages
package AnorakStats;
require "/opt/anorak-worker/AnorakStats.pm";

# Detail collection packages
package DBIL;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";

package Abercrombie_US;
require "/opt/home/merit/Merit_Robots/Abercrombie_US.pm";

package Aeropostale_US;
require "/opt/home/merit/Merit_Robots/Aeropostale_US.pm";

package Americaneagle_US;
require "/opt/home/merit/Merit_Robots/Americaneagle_US.pm";

package Anntaylor_US;
require "/opt/home/merit/Merit_Robots/Anntaylor_US.pm";

package Anthropologie_US;
require "/opt/home/merit/Merit_Robots/Anthropologie_US.pm";

package Asdageorge_UK;
require "/opt/home/merit/Merit_Robots/Asdageorge_UK.pm";

package Asos_UK;
require "/opt/home/merit/Merit_Robots/Asos_UK.pm";

package Asos_US;
require "/opt/home/merit/Merit_Robots/Asos_US.pm";

package Bananarepublic_US;
require "/opt/home/merit/Merit_Robots/Bananarepublic_US.pm";

package Bealls_US;
require "/opt/home/merit/Merit_Robots/Bealls_US.pm";

package Bhs_UK;
require "/opt/home/merit/Merit_Robots/Bhs_UK.pm";

package Bloomingdales_US;
require "/opt/home/merit/Merit_Robots/Bloomingdales_US.pm";

package Boohoo_UK;
require "/opt/home/merit/Merit_Robots/Boohoo_UK.pm";

package Charlotterusse_US;
require "/opt/home/merit/Merit_Robots/Charlotterusse_US.pm";

package Chicos_US;
require "/opt/home/merit/Merit_Robots/Chicos_US.pm";

package Coaststores_UK;
require "/opt/home/merit/Merit_Robots/Coaststores_UK.pm";

package Countryroad_AU;
require "/opt/home/merit/Merit_Robots/Countryroad_AU.pm";

package Davidlawrence_AU;
require "/opt/home/merit/Merit_Robots/Davidlawrence_AU.pm";

package Davidjones_AU;
require "/opt/home/merit/Merit_Robots/Davidjones_AU.pm";

package Debenhams_UK;
require "/opt/home/merit/Merit_Robots/Debenhams_UK.pm";

package Delias_US;
require "/opt/home/merit/Merit_Robots/Delias_US.pm";

package Dorothy_Perkins_UK;
require "/opt/home/merit/Merit_Robots/Dorothy_Perkins_UK.pm";

package Evans_UK;
require "/opt/home/merit/Merit_Robots/Evans_UK.pm";

package Express_US;
require "/opt/home/merit/Merit_Robots/Express_US.pm";

package Fatface_UK;
require "/opt/home/merit/Merit_Robots/Fatface_UK.pm";

package Forever21_US;
require "/opt/home/merit/Merit_Robots/Forever21_US.pm";

package Gap_UK;
require "/opt/home/merit/Merit_Robots/Gap_UK.pm";

package Gap_US;
require "/opt/home/merit/Merit_Robots/Gap_US.pm";

package Harrods_UK;
require "/opt/home/merit/Merit_Robots/Harrods_UK.pm";

package HarveyNichols_UK;
require "/opt/home/merit/Merit_Robots/HarveyNichols_UK.pm";

package Hm_UK;
require "/opt/home/merit/Merit_Robots/Hm_UK.pm";

package Hollister_US;
require "/opt/home/merit/Merit_Robots/Hollister_US.pm";

package Houseoffraser_UK;
require "/opt/home/merit/Merit_Robots/Houseoffraser_UK.pm";

package JCPenney_US;
require "/opt/home/merit/Merit_Robots/JCPenney_US.pm";

package Jcrew_US;
require "/opt/home/merit/Merit_Robots/Jcrew_US.pm";

package Jigsaw_UK;
require "/opt/home/merit/Merit_Robots/Jigsaw_UK.pm";

package Johnlewis_UK;
require "/opt/home/merit/Merit_Robots/Johnlewis_UK.pm";

package Joules_UK;
require "/opt/home/merit/Merit_Robots/Joules_UK.pm";

package Karenmillen_UK;
require "/opt/home/merit/Merit_Robots/Karenmillen_UK.pm";

package Kmart_US;
require "/opt/home/merit/Merit_Robots/Kmart_US.pm";

package Kohls_US;
require "/opt/home/merit/Merit_Robots/Kohls_US.pm";

package Landsend_US;
require "/opt/home/merit/Merit_Robots/Landsend_US.pm";

package Lillypulitzer_US;
require "/opt/home/merit/Merit_Robots/Lillypulitzer_US.pm";

package Littlewoods_UK;
require "/opt/home/merit/Merit_Robots/Littlewoods_UK.pm";

package Loft_US;
require "/opt/home/merit/Merit_Robots/Loft_US.pm";

package Macys_US;
require "/opt/home/merit/Merit_Robots/Macys_US.pm";

package Matalan_UK;
require "/opt/home/merit/Merit_Robots/Matalan_UK.pm";

package Matches_UK;
require "/opt/home/merit/Merit_Robots/Matches_UK.pm";

package Ms_UK;
require "/opt/home/merit/Merit_Robots/Ms_UK.pm";

package Myer_AU;
require "/opt/home/merit/Merit_Robots/Myer_AU.pm";

package Mywardrobe_UK;
require "/opt/home/merit/Merit_Robots/Mywardrobe_UK.pm";

package Nastygal_US;
require "/opt/home/merit/Merit_Robots/Nastygal_US.pm";

package Neimanmarkus_US;
require "/opt/home/merit/Merit_Robots/Neimanmarkus_US.pm";

package Netaporter_UK;
require "/opt/home/merit/Merit_Robots/Netaporter_UK.pm";

package Netaporter_US;
require "/opt/home/merit/Merit_Robots/Netaporter_US.pm";

package Newlook_UK;
require "/opt/home/merit/Merit_Robots/Newlook_UK.pm";

package Next_UK;
require "/opt/home/merit/Merit_Robots/Next_UK.pm";

package Nordstrom_US;
require "/opt/home/merit/Merit_Robots/Nordstrom_US.pm";

package Oasis_UK;
require "/opt/home/merit/Merit_Robots/Oasis_UK.pm";

package Oldnavy_US;
require "/opt/home/merit/Merit_Robots/Oldnavy_US.pm";

package Peacocks_UK;
require "/opt/home/merit/Merit_Robots/Peacocks_UK.pm";

package Piperlime_US;
require "/opt/home/merit/Merit_Robots/Piperlime_US.pm";

package Reiss_UK;
require "/opt/home/merit/Merit_Robots/Reiss_UK.pm";

package Riverisland_UK;
require "/opt/home/merit/Merit_Robots/Riverisland_UK.pm";

package Saba_AU;
require "/opt/home/merit/Merit_Robots/Saba_AU.pm";

package Saks_US;
require "/opt/home/merit/Merit_Robots/Saks_US.pm";

package Sears_US;
require "/opt/home/merit/Merit_Robots/Sears_US.pm";

package Selfridges_UK;
require "/opt/home/merit/Merit_Robots/Selfridges_UK.pm";

package Simplybe_UK;
require "/opt/home/merit/Merit_Robots/Simplybe_UK.pm";

package Sportsgirl_AU;
require "/opt/home/merit/Merit_Robots/Sportsgirl_AU.pm";

package Stagestores_US;
require "/opt/home/merit/Merit_Robots/Stagestores_US.pm";

package Sussan_AU;
require "/opt/home/merit/Merit_Robots/Sussan_AU.pm";

package Target_US;
require "/opt/home/merit/Merit_Robots/Target_US.pm";

package Tedbaker_UK;
require "/opt/home/merit/Merit_Robots/Tedbaker_UK.pm";

package Tesco_UK;
require "/opt/home/merit/Merit_Robots/Tesco_UK.pm";

package Thelimited_US;
require "/opt/home/merit/Merit_Robots/Thelimited_US.pm";

package TheIconic_AU;
require "/opt/home/merit/Merit_Robots/TheIconic_AU.pm";

package Topshop_UK;
require "/opt/home/merit/Merit_Robots/Topshop_UK.pm";

package Topshop_US;
require "/opt/home/merit/Merit_Robots/Topshop_US.pm";

package Uniqlo_UK;
require "/opt/home/merit/Merit_Robots/Uniqlo_UK.pm";

package Urbanoutfitters_US;
require "/opt/home/merit/Merit_Robots/Urbanoutfitters_US.pm";

package Walmart_US;
require "/opt/home/merit/Merit_Robots/Walmart_US.pm";

package Wetseal_US;
require "/opt/home/merit/Merit_Robots/Wetseal_US.pm";

package Whistles_UK;
require "/opt/home/merit/Merit_Robots/Whistles_UK.pm";

package Witchery_AU;
require "/opt/home/merit/Merit_Robots/Witchery_AU.pm";

package Zalando_UK;
require "/opt/home/merit/Merit_Robots/Zalando_UK.pm";

package Zappos_US;
require "/opt/home/merit/Merit_Robots/Zappos_US.pm";

package Zara_UK;
require "/opt/home/merit/Merit_Robots/Zara_UK.pm";

# package Zara_US;
# require "/opt/home/merit/Merit_Robots/Zara_US.pm";



use JSON;
use Daemon::Control;
use Net::Domain qw(hostname);
use DBI;
use Redis;
use Log::Syslog::Fast ':all';
use Time::HiRes;
use Time::Out qw(timeout);
use Net::AMQP::RabbitMQ;
use Config::Tiny;
use Try::Tiny;
use Proc::ProcessTable;

# Set worker_id
my $worker_id = 'default';
if (defined $ARGV[1]) {
	$worker_id = sprintf("%03d", $ARGV[1]);
}

# Read the settings from the config file
my $ini = Config::Tiny->new;
$ini = Config::Tiny->read($ini_file);
if (!defined $ini) {
	# Die if reading the settings failed
	die "FATAL: ", Config::Tiny->errstr;
}

# Setup logging to syslog
my $logger = Log::Syslog::Fast->new(LOG_UDP, $ini->{logs}->{server}, $ini->{logs}->{port}, LOG_LOCAL3, LOG_INFO, hostname(), 'aw-' . $worker_id . '@' . hostname());

# Define the daemon
Daemon::Control->new({
		name		=> 'Anorak Worker' . $worker_id,
		lsb_start	=> '$syslog $remote_fs',
		lsb_stop	=> '$syslog',
		lsb_sdesc	=> 'Anorak Worker Short',
		lsb_desc	=> 'Anorak Worker Long',
		path		=> '/tmp',

		program		=> \&msg_consumer,
		program_args	=> [ 'aw-' . $worker_id ],

		pid_file	=> '/var/run/aw-' . $worker_id . '.pid',
		stderr_file	=> '/var/log/aw-' . $worker_id . '.out',
		stdout_file	=> '/var/log/aw-' . $worker_id . '.out',

		fork		=> 2,
})->run;

# Returns the memory usage of the current process in MB
sub memory_usage() {
	my $t = new Proc::ProcessTable;
	foreach my $got (@{$t->table}) {
		next unless $got->pid eq $$;
		return int($got->rss/1024/1024);
	}
}

# This function is called when the daemon is created and contains the main loop
sub msg_consumer {

	# Following two are used to report runtime and messagess processed at shutdown
	my $lifetime_timer = [Time::HiRes::gettimeofday()];
	my $lifetime_counter = 0;

	# Setup connection to RabbitMQ cluster
	my $mqh = Net::AMQP::RabbitMQ->new();
	try {
		$mqh->connect($ini->{rabbitmq}->{server}, { user => $ini->{rabbitmq}->{user}, password => $ini->{rabbitmq}->{pass} });
	} catch {
		my $message = "FATAL: Can't connect to RabbitMQ server $ini->{rabbitmq}->{server}\n";
		$logger->send($message);
		sleep(5);
		die $message;
	};

	# Open a channel to RabbitMQ cluster
	try {
		$mqh->channel_open(1);
	} catch {
		my $message = "FATAL: Can't open a channel to RabbitMQ server $ini->{rabbitmq}->{server}\n";
		$logger->send($message);
		sleep(5);
		die $message;
	};

	# Set prefetch
	try {
		$mqh->basic_qos(1, { prefetch_count => $ini->{rabbitmq}->{prefetch} });
	} catch {
		my $message = "FATAL: Can't adjust prefetch count on RabbitMQ channel to $ini->{rabbitmq}->{prefetch}\n";
		$logger->send($message);
		sleep(5);
		die $message;
	};

	# Declare exchange
	try {
		$mqh->exchange_declare(1, $ini->{rabbitmq}->{exchange}, { exchange_type => 'direct', auto_delete => '0' });
	} catch {
		my $message = "FATAL: Can't declare exchange $ini->{rabbitmq}->{exchange}\n";
		$logger->send($message);
		sleep(5);
		die $message;
	};

	# Declare queue
	try {
		$mqh->queue_declare(1, $ini->{rabbitmq}->{queue}, { auto_delete => '0' });
	} catch {
		my $message = "FATAL: Can't declare queue $ini->{rabbitmq}->{queue}\n";
		$logger->send($message);
		sleep(5);
		die $message;
	};

	# Bind the queue
	try {
		$mqh->queue_bind(1, $ini->{rabbitmq}->{queue}, $ini->{rabbitmq}->{queue}, $ini->{rabbitmq}->{queue});
	} catch {
		my $message = "FATAL: Can't bind to queue $ini->{rabbitmq}->{queue}\n";
		$logger->send($message);
		sleep(5);
		die $message;
	};

	# Start consuming from queue
	try {
		$mqh->consume(1, $ini->{rabbitmq}->{queue}, { no_ack => 0 });
	} catch {
		my $message = "FATAL: Can't consume from queue $ini->{rabbitmq}->{queue}\n";
		$logger->send($message);
		sleep(5);
		die $message;
	};

	# If stats are enabled in the config
	my $stats;
	if ($ini->{redis}->{enabled} eq "yes") {
		$stats = AnorakStats->new();
		# Connect to Redis server
		$stats->connect($ini->{redis}->{server} . ":" . $ini->{redis}->{port});
		# But if it fails just disable stats
		if (!defined $stats->{redis}) {
			undef $stats;
			$logger->send("WARNING: Can't connect to Redis server $ini->{redis}->{server}:$ini->{redis}->{port}, no stats will be reported\n");
		}
	}

	# Connect to database
	my $dbh = DBIL::DbConnection();

	$logger->send("Waiting for messages from $ini->{rabbitmq}->{queue}\n");

	# Infinite loop around recv()
	LOOP: while (1) {
		my $message;
		my $decoded;
		my $process;

		# Receive message
		try {
			$message = $mqh->recv();
		} catch {
			my $message = "FATAL: Invalid message received ($_)\n";
			$logger->send($message);
			sleep(5);
			die $message;
		};

		# Confirm DB connection is still up
		if ( !$dbh->ping ) {
			$dbh = DBIL::DbConnection();
			$logger->send("WARNING: Lost connection to database, reconnecting\n");
		}

		# If not and reconnection failed, die
		if ( !$dbh->ping ) {
			my $message = "FATAL: Lost connection to database ($@)\n";
			$logger->send($message);
			sleep(5);
			die $message;
		}

		# Extract body from message
		my $body;
		try {
			$body = $message->{'body'};
		} catch {
			my $message = "FATAL: Invalid message body ($_)\n";
			$logger->send($message);
			sleep(5);
			die $message;
		};

		# Extract delivery tag from message
		my $dtag;
		try {
			$dtag = $message->{'delivery_tag'};
		} catch {
			my $message = "FATAL: Invalid delivery tag ($_)\n";
			$logger->send($message);
			sleep(5);
			die $message;
		};

		# Ensure message is valid JSON
		if (!eval { $decoded = decode_json($body); }) {
			$logger->send("ERROR:$@" . $body);
			$mqh->reject(1, $dtag, 0);
			next LOOP;
		}

		# Ensure ObjectKey is defined
		if (!defined $decoded->{'ObjectKey'}) {
			$logger->send("ObjectKey missing in " . $body);
			$mqh->reject(1, $dtag, 0);
			next LOOP;
		}

		# Ensure RobotName is defined
		if (!defined $decoded->{'RobotName'}) {
			$logger->send("RobotName missing in " . $body);
			$mqh->reject(1, $dtag, 0);
			next LOOP;
		}

		# Ensure RetailerId is defined
		if (!defined $decoded->{'RetailerId'}) {
			$logger->send("RetailerId missing in " . $body);
			$mqh->reject(1, $dtag, 0);
			next LOOP;
		}

		# Ensure url is defined
		if (!defined $decoded->{'url'}) {
			$logger->send("url missing in " . $body);
			$mqh->reject(1, $dtag, 0);
			next LOOP;
		}

		# Select the apropriate process procedure
		given ($decoded->{'RobotName'}) {
			when('Abercrombie-US')		{ $process = \&Abercrombie_US::Abercrombie_US_DetailProcess };
			when('Aeropostale-US')          { $process = \&Aeropostale_US::Aeropostale_US_DetailProcess };
			when('Americaneagle-US')	{ $process = \&Americaneagle_US::Americaneagle_US_DetailProcess };
			when('Anntaylor-US')		{ $process = \&Anntaylor_US::Anntaylor_US_DetailProcess };
			when('Anthropologie-US')	{ $process = \&Anthropologie_US::Anthropologie_US_DetailProcess };
			when('Asdageorge-UK')		{ $process = \&Asdageorge_UK::Asdageorge_UK_DetailProcess };
			when('Asos-UK')			{ $process = \&Asos_UK::Asos_UK_DetailProcess };
			when('Asos-US')			{ $process = \&Asos_US::Asos_US_DetailProcess };
			when('Bananarepublic-US')	{ $process = \&Bananarepublic_US::Bananarepublic_US_DetailProcess };
			when('Bealls-US')		{ $process = \&Bealls_US::Bealls_US_DetailProcess };
			when('Bhs-UK')			{ $process = \&Bhs_UK::Bhs_UK_DetailProcess };
			when('Bloomingdales-US')	{ $process = \&Bloomingdales_US::Bloomingdales_US_DetailProcess };
			when('Boohoo-UK')		{ $process = \&Boohoo_UK::Boohoo_UK_DetailProcess };
			when('Chicos-US')		{ $process = \&Chicos_US::Chicos_US_DetailProcess };
			when('Charlotterusse-US')		{ $process = \&Charlotterusse_US::Charlotterusse_US_DetailProcess };
			when('Coaststores-UK')		{ $process = \&Coaststores_UK::Coaststores_UK_DetailProcess };
			when('Countryroad-AU')      { $process = \&Countryroad_AU::Countryroad_AU_DetailProcess };
			when('Davidlawrence-AU')      { $process = \&Davidlawrence_AU::Davidlawrence_AU_DetailProcess };
			when('Davidjones-AU')      { $process = \&Davidjones_AU::Davidjones_AU_DetailProcess };
			when('Debenhams-UK')		{ $process = \&Debenhams_UK::Debenhams_UK_DetailProcess };
			when('Delias-US')      { $process = \&Delias_US::Delias_US_DetailProcess };
			when('Dorothy_Perkins-UK')	{ $process = \&Dorothy_Perkins_UK::Dorothy_Perkins_UK_DetailProcess };
			when('Evans-UK')		{ $process = \&Evans_UK::Evans_UK_DetailProcess };
			when('Express-US')		{ $process = \&Express_US::Express_US_DetailProcess };
			when('Fatface-UK')		{ $process = \&Fatface_UK::Fatface_UK_DetailProcess };
			when('Forever21-US')		{ $process = \&Forever21_US::Forever21_US_DetailProcess };
			when('Gap-UK')			{ $process = \&Gap_UK::Gap_UK_DetailProcess };
			when('Gap-US')			{ $process = \&Gap_US::Gap_US_DetailProcess };
			when('Harrods-UK')              { $process = \&Harrods_UK::Harrods_UK_DetailProcess };
			 when('HarveyNichols-UK')       { $process = \&HarveyNichols_UK::HarveyNichols_UK_DetailProcess };
			when('Hm-UK')			{ $process = \&Hm_UK::Hm_UK_DetailProcess };
			when('Hollister-US')		{ $process = \&Hollister_US::Hollister_US_DetailProcess };
			when('Houseoffraser-UK')	{ $process = \&Houseoffraser_UK::Houseoffraser_UK_DetailProcess };
			when('JCPenney-US')		{ $process = \&JCPenney_US::JCPenney_US_DetailProcess };
			when('Jcrew-US')		{ $process = \&Jcrew_US::Jcrew_US_DetailProcess };
			when('Jigsaw-UK')		{ $process = \&Jigsaw_UK::Jigsaw_UK_DetailProcess };
			when('Johnlewis-UK')		{ $process = \&Johnlewis_UK::Johnlewis_UK_DetailProcess };
			when('Joules-UK')		{ $process = \&Joules_UK::Joules_UK_DetailProcess };
			when('Kmart-US')		{ $process = \&Kmart_US::Kmart_US_DetailProcess };
			when('Kohls-US')		{ $process = \&Kohls_US::Kohls_US_DetailProcess };
			when('Landsend-US')		{ $process = \&Landsend_US::Landsend_US_DetailProcess };
			when('Lillypulitzer-US')		{ $process = \&Lillypulitzer_US::Lillypulitzer_US_DetailProcess };
			when('Littlewoods-UK')		{ $process = \&Littlewoods_UK::Littlewoods_UK_DetailProcess };
			when('Loft-US')			{ $process = \&Loft_US::Loft_US_DetailProcess };
			when('Macys-US')		{ $process = \&Macys_US::Macys_US_DetailProcess };
			when('Matalan-UK')		{ $process = \&Matalan_UK::Matalan_UK_DetailProcess };
			when('Matches-UK')		{ $process = \&Matches_UK::Matches_UK_DetailProcess };
			when('Ms-UK')			{ $process = \&Ms_UK::Ms_UK_DetailProcess };
			when('Myer-AU')			{ $process = \&Myer_AU::Myer_AU_DetailProcess };
			when('Mywardrobe-UK')			{ $process = \&Mywardrobe_UK::Mywardrobe_UK_DetailProcess };
			when('Nastygal-US')			{ $process = \&Nastygal_US::Nastygal_US_DetailProcess };
			when('Neimanmarkus-US')		{ $process = \&Neimanmarkus_US::Neimanmarkus_US_DetailProcess };
			when('Net-a-porter-UK')		{ $process = \&Netaporter_UK::Netaporter_UK_DetailProcess };
			when('Net-a-porter-US')		{ $process = \&Netaporter_US::Netaporter_US_DetailProcess };
			when('Newlook-UK')		{ $process = \&Newlook_UK::Newlook_UK_DetailProcess };
			when('Next-UK')			{ $process = \&Next_UK::Next_UK_DetailProcess };
			when('Nordstrom-US')		{ $process = \&Nordstrom_US::Nordstrom_US_DetailProcess };
			when('Oasis-UK')		{ $process = \&Oasis_UK::Oasis_UK_DetailProcess };
			when('Oldnavy-US')		{ $process = \&Oldnavy_US::Oldnavy_US_DetailProcess };
			when('Peacocks-UK')		{ $process = \&Peacocks_UK::Peacocks_UK_DetailProcess };
			when('Piperlime-US')		{ $process = \&Piperlime_US::Piperlime_US_DetailProcess };
			when('Reiss-UK')		{ $process = \&Reiss_UK::Reiss_UK_DetailProcess };
			when('Riverisland-UK')		{ $process = \&Riverisland_UK::Riverisland_UK_DetailProcess };
			when('Saba-AU')		{ $process = \&Saba_AU::Saba_AU_DetailProcess };
			when('Saks-US')			{ $process = \&Saks_US::Saks_US_DetailProcess };
			when('Sears-US')		{ $process = \&Sears_US::Sears_US_DetailProcess };
			when('Selfridges-UK')		{ $process = \&Selfridges_UK::Selfridges_UK_DetailProcess };
			when('Simplybe-UK')		{ $process = \&Simplybe_UK::Simplybe_UK_DetailProcess };
			when('Sportsgirl-AU')		{ $process = \&Sportsgirl_AU::Sportsgirl_AU_DetailProcess };
			when('Stagestores-US')		{ $process = \&Stagestores_US::Stagestores_US_DetailProcess };
			when('Target-US')		{ $process = \&Target_US::Target_US_DetailProcess };
			when('Tedbaker-UK')		{ $process = \&Tedbaker_UK::Tedbaker_UK_DetailProcess };
			when('Tesco-UK')		{ $process = \&Tesco_UK::Tesco_UK_DetailProcess };
			when('Thelimited-US')		{ $process = \&Thelimited_US::Thelimited_US_DetailProcess };
			when('TheIconic-AU')      	{ $process = \&TheIconic_AU::TheIconic_AU_DetailProcess };
			when('Topshop-UK')		{ $process = \&Topshop_UK::Topshop_UK_DetailProcess };
			when('Topshop-US')		{ $process = \&Topshop_US::Topshop_US_DetailProcess };
			when('Uniqlo-UK')		{ $process = \&Uniqlo_UK::Uniqlo_UK_DetailProcess };
			when('Urbanoutfitters-US')	{ $process = \&Urbanoutfitters_US::Urbanoutfitters_US_DetailProcess };
			when('Walmart-US')		{ $process = \&Walmart_US::Walmart_US_DetailProcess };
			when('Wetseal-US')      { $process = \&Wetseal_US::Wetseal_US_DetailProcess };
			when('Whistles-UK')      { $process = \&Whistles_UK::Whistles_UK_DetailProcess };
			when('Witchery-AU')      { $process = \&Witchery_AU::Witchery_AU_DetailProcess };
			when('Zalando-UK')		{ $process = \&Zalando_UK::Zalando_UK_DetailProcess };
			when('Zappos-US')		{ $process = \&Zappos_US::Zappos_US_DetailProcess };
			when('Zara-UK')			{ $process = \&Zara_UK::Zara_UK_DetailProcess };
			# when('Zara-US')			{ $process = \&Zara_US::Zara_US_DetailProcess };
		}

		# Call the process procedure if one is defined
		if (defined $process) {
			eval {
				# Pre-acknowledge message
				$mqh->ack(1, $dtag, 0);

				# Increment processed messages counter
				$lifetime_counter++;

				# Increment retailer's processed counter
				if (defined $stats) {
					$stats->inc($decoded->{'RobotName'}, 'processed');
				}

				# Start the timer
				my $tic = [Time::HiRes::gettimeofday()];

				# $logger->send("Item $decoded->{'ObjectKey'} calling process to collect $decoded->{'RobotName'}\n");

				# To protect the worker from getting stuck we enforce a timeout
				my $rc = timeout $ini->{worker}->{timeout} => sub {
					&$process($decoded->{'ObjectKey'},$decoded->{'url'}, $dbh, $decoded->{'RobotName'} . '--Worker', $decoded->{'RetailerId'}, $logger);
				} ;
				if ($@) {
					# Report a timeout
					my $elapsed = sprintf("%6.2f", Time::HiRes::tv_interval($tic));
					my $elapsed_int = sprintf("%6f", Time::HiRes::tv_interval($tic));
					$dbh->rollback(); # Transaction Rollback for Timeout
					$logger->send("Item $decoded->{'ObjectKey'} timed out at $elapsed sec by $decoded->{'RobotName'} (timeout was set to $ini->{worker}->{timeout}.00 sec). Item getting rollback\n");
					# Increment retailer's timedout counter and add timing
					if (defined $stats) {
						$stats->inc($decoded->{'RobotName'}, 'timedout');
						$stats->zadd($decoded->{'RobotName'}, $decoded->{'ObjectKey'}, $elapsed_int);
					}
				} else {
					# Report success
					my $elapsed = sprintf("%6.2f", Time::HiRes::tv_interval($tic));
					my $elapsed_int = sprintf("%6f", Time::HiRes::tv_interval($tic));
					$logger->send("Item $decoded->{'ObjectKey'} collected in $elapsed sec by $decoded->{'RobotName'}\n");

					# Increment retailer's collected counter & add timing
					if (defined $stats) {
						$stats->inc($decoded->{'RobotName'}, 'collected');
						$stats->zadd($decoded->{'RobotName'}, $decoded->{'ObjectKey'}, $elapsed_int);
					}
				}
			};
		} else {
			# Report an ignored message
			$logger->send("Item $decoded->{'ObjectKey'} ignored due to unkown RobotName $decoded->{'RobotName'}\n");
			$mqh->reject(1, $dtag, 0);
		}

		# To protect the host from memory leaks we enforce a max process size
		my $mem_size = memory_usage();
		if ($mem_size > $ini->{worker}->{mem_limit}) {
			my $elapsed = sprintf("%6.2f", Time::HiRes::tv_interval($lifetime_timer));
			my $message = "WARNING: Memory usage is $mem_size MB which is over the limit of $ini->{worker}->{mem_limit} MB, aborting after processing $lifetime_counter in $elapsed sec\n";
			$logger->send($message);
			die $message;
		}
	}
}
