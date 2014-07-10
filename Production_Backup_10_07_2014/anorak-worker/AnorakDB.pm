package AnorakDB;

use v5.10.1;
use strict;
use warnings;

use DBI;
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
# arguments: server host, port, database name, user pass
# returns: self->{dbi}
sub connect {
	my $self = shift;
	my $db_host = shift;
	my $db_port = shift;
	my $db_name = shift;
	my $db_user = shift;
	my $db_pass = shift;

	my $day = "fri";

	try {
		$self->{dbi} =  DBI->connect("DBI:mysql:database=$db_name" . "_" . "$day;host=$db_host;port=$db_port", $db_user, $db_pass, {AutoCommit => 0}) 
	} catch {
		die "Cannot connect to MySQL server\n";	
	};

	return $self->{dbi};
}



# checks the connection is still alive
# arguments: none
# returns 1 for success 0 for failure
sub ping {
	my $self = shift;

	return $self->{dbi}->ping;
}



# rollsback the current transaction
# arguments: none
# returns 1 for success 0 for failure
sub rollback {
	my $self = shift;

	return $self->{dbi}->rollback;
}



# 
# arguments: retailer_id
# returns: hash with url,ObjectKey pairs that have 'y' for given retailer_id
sub Objectkey_Url()
{
	my $self = shift;
	my $retailer_id = shift;

	my %hashUrl;
	my $select_query = "SELECT url,ObjectKey FROM Product_List where retailer_id =\'$retailer_id\' and detail_collected = \'y\' limit 10";
	my $sth_in = $self->{dbi}->prepare($select_query);

	Refetch:
	if($sth_in->execute())
	{
		while(my @row = $sth_in->fetchrow_array)
		{
			$hashUrl{$row[1]}=$row[0];
		}
		$sth_in->finish(); 
		return \%hashUrl;
	}
	else
	{
		sleep 10;
		goto Refetch;
	}
}

1;
