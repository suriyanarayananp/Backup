#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
### Package Name ####
package DBIL;  
use strict;
use DBI;
use String::Random;
use DateTime;
use Time::HiRes;
use LWP::Simple;
use Net::AMQP::RabbitMQ;
use Try::Tiny;
use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;
require Exporter;
my @ISA = qw(Exporter);
my @EXPORT = qw(ImageDownload);
#########################

###### Object Creation ###
my $random = new String::Random;
#########################

######## CONFIGURATION TUNABLES ########

my $rabbitmq_server = 'frawspcmq01';
my $rabbitmq_exchange = 'anorak.workers';
my $rabbitmq_queue = 'anorak.workers';
my $rabbitmq_prefetch = 2;

### Table Name ##########
my $tag_table_name = 'Tag';
my $product_table_name = 'Product';
my $product_has_tag_table_name = 'Product_has_Tag';
my $image_table_name='Image';
my $sku_table_name='Sku';
my $sku_has_image_table_name='Sku_has_Image';
my $Product_Completed='Product_Completed';
my ($date,$time,$day)=&Updatedate();
# my $date = DateTime->now()->date;
# my $day= lc($1) if(DateTime->now()->day_name=~m/(\s*[a-z]{3})/is);
my $db_name = "meritproddata_".$day;
my $cpath = '/var/tmp/Cookies/';
my $rpath = '/var/tmp/RetailerLog/';
my $dpath = '/var/tmp/DBErrorLog/';
my @char=('c','n');
my $mqh;
#########################

################# Die Handler ######
$SIG{__DIE__} = \&die_handler;
####################################

######### Die Handler ###############
sub die_handler()
{
	my $err_stmt;
	$err_stmt = $err_stmt . $_ foreach (@_);
    $err_stmt =~s/\n/ /igs;
	open fh,">>".$dpath."Error_".$date.".txt";
	print FH $err_stmt;
	close FH;
}
#########################
my $ua1=LWP::UserAgent->new(); 
$ua1->agent("Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (.NET CLR 3.5.30729)");
$ua1->timeout(30); 
### Proxy Configure #####
# sub ProxyConfig()
# {
	# my $country = shift;
	# if($country eq "US")
	# {	
		#$ENV{HTTP_proxy} = 'http://frawspcpx.cloud.trendinglines.co.uk:3129';
		#$ENV{HTTP_proxy} = 'http://edge-squid-us-west.cloud.trendinglines.co.uk:3128';
		# $ENV{HTTP_proxy} = 'http://edge-squid-us-east.cloud.trendinglines.co.uk:3128';
	# }
	# elsif($country eq "UK")
	# {
		# $ENV{HTTP_proxy} = 'http://frawspcpx.cloud.trendinglines.co.uk:3128';
	# }
	# elsif($country eq "AU")
	# {
		# $ENV{HTTP_proxy} = 'http://edge-squid-ap-southeast.cloud.trendinglines.co.uk:3128';
	# }
	
# }
sub ProxyConfig()
{
	my $country = shift;
	$ENV{HTTP_proxy} = 'http://frawspcpx.cloud.trendinglines.co.uk:3128';
	if($country eq "US")
	{
		$ENV{HTTP_proxy} = 'http://frawspcpx.cloud.trendinglines.co.uk:3129';
	}
	elsif($country eq "AU")
	{
		$ENV{HTTP_proxy} = 'http://frawspcpx.cloud.trendinglines.co.uk:3130';
	}
}
#########################

#### Log Path ###########
sub LogPath()
{
	my $robotname = shift;
	unless( -d $cpath)
	{	
		system(`mkdir $cpath`);
	}
	unless( -d $rpath)
	{       
		system(`mkdir $rpath`);
	}
	unless( -d $dpath)
	{
		system(`mkdir $dpath`);
	}
	my $cookie_file = $cpath.$robotname."_".$date.".txt"; 
	my $retailer_file = $rpath.$robotname."_".$date.".log";
	return($cookie_file, $retailer_file);	
}

sub MqConnection()
{
	# Setup connection to RabbitMQ cluster
	my $mqh = Net::AMQP::RabbitMQ->new();
	try {
		$mqh->connect($rabbitmq_server, { user => 'guest', password => 'guest' });
	} catch {
		die "FATAL: Can't connect to RabbitMQ server $rabbitmq_server";
	};

	# Open a channel to RabbitMQ cluster
	try {
		$mqh->channel_open(1);
	} catch {
		die "FATAL: Can't open a channel to RabbitMQ server $rabbitmq_server";
	};

	# Set prefetch
	try {
		$mqh->basic_qos(1, { prefetch_count => $rabbitmq_prefetch });
	} catch {
		die "FATAL: Can't adjust prefetch count on RabbitMQ channel to $rabbitmq_prefetch";
	};

	# Declare exchange
	try {
		$mqh->exchange_declare(1, $rabbitmq_exchange, { exchange_type => 'direct', auto_delete => '0' });
	} catch {
		die "FATAL: Can't declare exchange $rabbitmq_exchange";
	};

	# Declare queue
	try {
		$mqh->queue_declare(1, $rabbitmq_queue, { auto_delete => '0' });
	} catch {
		die "FATAL: Can't declare queue $rabbitmq_queue";
	};
	return $mqh;
}

sub MqPublish
{
	my $objectkey = shift;
	my $robotname = shift;
	my $url = shift;
	my $retailerid = shift;

        my $body = "{\"ObjectKey\": \"$objectkey\", \"RobotName\": \"$robotname\", \"url\": \"$url\", \"RetailerId\": \"$retailerid\"}";
	try {
		$mqh->publish(1, $rabbitmq_queue, $body, { exchange => $rabbitmq_exchange });
	} catch {
		die "FATAL: Can't publish messate to queue $rabbitmq_queue";
	};
}

###### DB Connection ####
sub DbConnection()
{
	my $dbh = DBI->connect("DBI:mysql:database=$db_name;host=collection-db-prod-merit.cloud.trendinglines.co.uk;port=3306","merit","dfFDG567HGf45",{AutoCommit => 0, mysql_enable_utf8 => 1})  or die "Cannot connect to MySQL server\n";
	return $dbh;
}
#########################

###### Image Download ################
sub ImageDownload
{
	my $imageurl = shift;
	my $imagetype= shift;
	my $retailer = shift;
	my ($cookiefile, $retailerfile) = &LogPath($retailer);
	if ( $imageurl =~ m/^\s*$/ || $imagetype =~ m/^\s*$/ || $retailer =~ m/^\s*$/ )
	{
		open ff,">>$retailerfile";
		print ff "You need to provide the ImageURL , Imagetype and retailer details ... \n";
		close ff;
		return;
	}
	my ($Imagetypepath,$imagefilename,$id,$imagefilepath,$imagefile);
	if($imagetype =~ /\s*product\s*/is)
	{
		$Imagetypepath = "ProductImages";
	}
	elsif($imagetype =~ /\s*swatch\s*/is)
	{
		$Imagetypepath = "SwatchImages";
	}
	$imagefilename = uc(md5_hex($imageurl)).".jpg";	$id = uc(md5_hex("$imageurl$retailer"));
	my $foldera = substr($imagefilename,0,1);
	my $folderb = substr($imagefilename,1,1);
	my $folderc = substr($imagefilename,2,1);
	$imagefilepath = "/opt/kapow-images/$Imagetypepath/$retailer/$foldera/$folderb/$folderc";
	$imagefile = "$imagefilepath/$imagefilename";
	if( ! -e $imagefile)
	{
		eval
		{
			getstore($imageurl,$imagefile);
		};
		if(! -e $imagefile)
		{
			eval
			{
				mirror($imageurl,$imagefile);
			};
			if(! -e $imagefile)
			{
				eval
				{
					$ua1->mirror($imageurl,$imagefile);
				};
			}
		}
	}
	return($id,$imagefilename);
}
#########################

###### Return Single Value ####
sub Objectkey_Checking
{
	my $select_query = shift;
	my $dbh = shift;
	my $robotname = shift;
	my $sth_in = $dbh->prepare($select_query);
	my $objectkey_value;
	Refetch4:
        if($sth_in->execute())
        {
			$objectkey_value = $sth_in->fetchrow_array;
			$sth_in->finish();
        }
        else
        {
			open fh,">>".$dpath.$robotname."_".$date."_Error.txt";
			print fh "$select_query query get following error $DBI::errstr\n";
			close fh;
			sleep 10;
			goto Refetch4;
        }
	return($objectkey_value);
}
#########################
sub SaveTag()
{
	my $tag_name = Dbvalidate(Trim(shift));
	my $tag_value = Dbvalidate(Trim(shift));
	my $product_object_key = Dbvalidate(Trim(shift));
	my $dbh = shift;
	my $robotname = shift;
	my $retailer_char = shift;
	my $executionid = shift;
	my $tag_query = &Generate_Tag_Query($tag_name,$tag_value,$robotname);
	my $tag_object_key = &Objectkey_Checking($tag_query,$dbh,$robotname);
	unless($tag_object_key)
	{
		my ($cdate,$ctime,$cday)=&Updatedate();
		my $current_time = $cdate.' '.$ctime;
		$tag_object_key = &GenerateRandom_String($tag_table_name,$retailer_char,$dbh,$robotname);
		my $insert_query = "insert into $tag_table_name (name,value,ObjectKey,RobotName,ExecutionId,FirstExtracted,LastExtracted,ExtractedInLastRun,LastUpdated) values(\'$tag_name\',\'$tag_value\',\'$tag_object_key\',\'$robotname\',\'$executionid\',\'$current_time\',\'$current_time\',\'y\',\'$current_time\')";
		&SaveDB($insert_query,$dbh,$robotname);
	}
	&SaveProducthasTag($product_object_key,$tag_object_key,$dbh,$robotname,$retailer_char,$executionid);
}
sub UpdateProducthasTag()
{
	my ($ref_no,$existkey, $dbh, $robotname, $retailer_id)= @_;
	my $Query = "Select ObjectKey from $product_table_name where retailer_id =\'$retailer_id \' and retailer_product_reference=\'$ref_no\' limit 1";
	my $Product_ObjectKey = &Objectkey_Checking($Query, $dbh, $robotname);
	if($Product_ObjectKey)
	{
		my $robotname_list = $robotname;
		$robotname_list =~ s/\-\-Detail\s*$//igs;
		my ($cdate,$ctime,$cday)=&Updatedate();
		my $current_time = $cdate.' '.$ctime;
		my $updateQuery = "update $product_has_tag_table_name set product_id=\'$Product_ObjectKey\' where product_id=\'$existkey\' limit 100";
		# my $status = &SaveDB($updateQuery,$dbh,$robotname);
		&SaveDB($updateQuery,$dbh,$robotname);
		
		# my $insert_qry = "insert into $Product_Completed (retailer_id, product_id, LastUpdated) values(\'$retailer_id\',\'$existkey\',\'$current_time\')";
		# &SaveDB($insert_qry,$dbh,$robotname);
		my $update_query = "update Product_List set detail_collected=\'d\',LastUpdated=\'$current_time\' where retailer_id=\'$retailer_id\' and ObjectKey=\'$existkey\' limit 1";
		&SaveDB($update_query,$dbh,$robotname);
		
		# if($status == 1)
		# {
			# my $updateQuery = "Delete from $product_table_name where ObjectKey=\'$existkey\' and retailer_id =\'$retailer_id \' limit 1";
			# my $status2 = &SaveDB($updateQuery,$dbh,$robotname);
			# if($status2 == 1)
			# {
				# $dbh->commit();
			# }
			# elsif($status2 == 0)
			# {
				# $dbh->rollback();
			# }
		# }
		# elsif($status == 0)
		# {
			# $dbh->rollback();
		# }
		return 1;
	}
}
######### SKU ################
sub SaveSku()
{
	my $product_id=&Dbvalidate(Trim(shift));
	my $url=&Dbvalidate(Trim(shift));
	my $sku_product_name=&Dbvalidate(Trim(shift));
	my $current_price=&Dbvalidate(Trim(shift));
	my $price_text=&Dbvalidate(Trim(shift));
	my $size=&Dbvalidate(Trim(shift));
	my $raw_color=&Dbvalidate(Trim(shift));
	my $out_of_stock=&Dbvalidate(Trim(shift));
	my $dbh = shift;
	my $retailer_char = shift;
	my $robotname = shift;
	my $executionid = shift;
	my ($cdate,$ctime,$cday)=&Updatedate();
	my $current_time = $cdate.' '.$ctime;
	my $sku_object_key = &GenerateRandom_String($sku_table_name,$retailer_char,$dbh,$robotname);
	my $insert_query = "insert into $sku_table_name (product_id,url,sku_product_name,current_price,price_text,size,raw_colour,out_of_stock,ObjectKey,RobotName,ExecutionId,FirstExtracted,LastExtracted,ExtractedInLastRun,Lastupdated) values(\'$product_id\',\'$url\',\'$sku_product_name\',$current_price,\'$price_text\',\'$size\',\'$raw_color\',\'$out_of_stock\',\'$sku_object_key\',\'$robotname\',\'$executionid\',\'$current_time\',\'$current_time\',\'y\',\'$current_time\')";
	# SaveDB($insert_query,$dbh,$robotname);
	my $skuflag = 1 if($current_price eq '' and $price_text eq '' and $size eq '' and $raw_color eq '' and $out_of_stock eq '');
	return ($sku_object_key,$skuflag,$insert_query);
}
###############################

######## SKU Has Image #######
sub SaveSkuhasImage()
{
	my $sku_id=&Dbvalidate(Trim(shift));
	my $image_id=&Dbvalidate(Trim(shift));
	my $default=&Dbvalidate(Trim(shift));
	my $product_object_key=&Dbvalidate(Trim(shift));
	my $dbh = shift;
	my $retailer_char = shift;
	my $robotname = shift;
	my $excuetionid = shift;
	my ($cdate,$ctime,$cday)=&Updatedate();
	my $current_time = $cdate.' '.$ctime;
	my $sku_has_image_object_key = &GenerateRandom_String($sku_has_image_table_name,$retailer_char,$dbh);
	my $insert_query = "insert into $sku_has_image_table_name (sku_id,image_id,default_image,ObjectKey,RobotName,ExecutionId,FirstExtracted,LastExtracted,ExtractedInLastRun,Lastupdated) values(\'$sku_id\',\'$image_id\',\'$default\',\'$sku_has_image_object_key\',\'$robotname\',\'$excuetionid\',\'$current_time\',\'$current_time\',\'y\',\'$current_time\')";
	# &SaveDB($insert_query,$dbh,$robotname);
	# if($default eq 'y')
	# {
		# my $update_product_has_tag="update $product_has_tag_table_name set image_id =\'$image_id\' where product_id=\'$product_object_key\'";
		# &SaveDB($update_product_has_tag,$dbh,$robotname);
	# }
	return $insert_query;
}
###############################

#######Save Image###########
sub SaveImage()
{
	my $id=&Dbvalidate(Trim(shift));
	my $url=&Dbvalidate(Trim(shift));
	my $image_filename=&Dbvalidate(Trim(shift));
	my $image_type=&Dbvalidate(Trim(shift));
	my $dbh = shift;
	my $retailer_char = shift;
	my $robotname = shift;
	my $excuetionid = shift;
	my ($cdate,$ctime,$cday)=&Updatedate();
	my $current_time = $cdate.' '.$ctime;
	my $img_object_key = &GenerateRandom_String($image_table_name,$retailer_char,$dbh,$robotname);
	my $insert_query = "insert into $image_table_name (id,url,image_filename,image_type,ObjectKey,RobotName,ExecutionId,FirstExtracted,LastExtracted,ExtractedInLastRun,Lastupdated) values(\'$id\',\'$url\',\'$image_filename\',\'$image_type\',\'$img_object_key\',\'$robotname\',\'$excuetionid\',\'$current_time\',\'$current_time\',\'y\',\'$current_time\')";
	# &SaveDB($insert_query,$dbh,$robotname);
	my $imageflag = 1 if($id eq '' and $image_filename eq '' and $image_type eq '');
	return ($img_object_key, $imageflag,$insert_query);
}
###############################

sub SaveProducthasTag
{
	my $product_object_key = Dbvalidate(shift);
	my $tag_object_key = Dbvalidate(Trim(shift));
	my $dbh = shift;
	my $robotname = shift;
	my $retailer_char = shift;
	my $executionid = shift;
	my $product_has_tag_query = &Generate_Product_has_Tag_Query($product_object_key,$tag_object_key);
	my $product_has_tag_object_key = &Objectkey_Checking($product_has_tag_query,$dbh,$robotname);
	unless($product_has_tag_object_key)
	{
		my ($cdate,$ctime,$cday)=&Updatedate();
		my $current_time = $cdate.' '.$ctime;
		$product_has_tag_object_key = &GenerateRandom_String($product_has_tag_table_name,$retailer_char,$dbh,$robotname);
		my $insert_query = "insert into $product_has_tag_table_name (product_id,tag_id,ObjectKey,RobotName,ExecutionId,FirstExtracted,LastExtracted,ExtractedInLastRun,LastUpdated) values(\'$product_object_key\',\'$tag_object_key\',\'$product_has_tag_object_key\',\'$robotname\',\'$executionid\',\'$current_time\',\'$current_time\',\'y\',\'$current_time\')";
		&SaveDB($insert_query,$dbh,$robotname);
	}
}
sub SaveDB()
{
	my $insert_query = shift;
	my $dbh = shift;
	my $robotname = shift;
	my $sth_in = $dbh->prepare($insert_query);
	if($sth_in->execute())
	{
		$sth_in->finish();
		return 1;
	}
	else
	{
		open fh,">>".$dpath.$robotname."_".$date."_Error.txt";
		print fh "$insert_query query get following error $DBI::errstr\n";
		close fh;
		return 0;
		eval{$sth_in->finish();}	
	}
}
sub SaveInsertDB
{
	my $insert_query = shift;
	my $dbh = shift;
	my $robotname = shift;
	my $sth_in = $dbh->prepare($insert_query);
	my $object_key;
	if($sth_in->execute())
	{
		$sth_in->finish(); 
	}
	else
	{
		open fh,">>".$dpath.$robotname."_".$date."_Error.txt";
		print fh "$insert_query query get following error $DBI::errstr\n";
		close fh;
		eval{$sth_in->finish();}
	}
}
sub Generate_Tag_Query
{	
	my $tag_name = shift;
	my $tag_value = shift;
	my $robotname = shift;
	my $tag_query = "select ObjectKey from $tag_table_name where name =\'$tag_name\' and value=\'$tag_value\'";
	return($tag_query);
}
sub Generate_Product_Query
{	
	my $product_url = Dbvalidate(shift);
	my $retailer_id = Dbvalidate(shift);
	my $product_query = "select ObjectKey from $product_table_name where retailer_id = \'$retailer_id\' and url =\'$product_url\' limit 1";
	return($product_query);
}
sub Generate_Product_has_Tag_Query
{	
	my $product_id = Dbvalidate(shift);
	my $tag_id = Dbvalidate(shift);
	my $product_has_tag_query = "select ObjectKey from $product_has_tag_table_name where product_id =\'$product_id\' and tag_id=\'$tag_id\'";
	return($product_has_tag_query);
}
sub Dbvalidate
{
	my  $txt = shift;
	$txt =~ s/\'/''/g;
	return $txt;
}
sub SaveProduct
{
	my $url = Dbvalidate(shift);
	my $dbh = shift;
	my $robotname = shift;
	my $retailer_id = shift;
	my $retailer_name = shift;
	my $executionid = shift;
	# my $product_query = &Generate_Product_Query($url, $retailer_id);
	# my $product_object_key = &Objectkey_Checking($product_query, $dbh,$robotname);
	# unless($product_object_key)
	# {
		my ($cdate,$ctime,$cday)=&Updatedate();
		my $current_time = $cdate.' '.$ctime;
		my $product_object_key = uc(md5_hex($retailer_name.$url));
		my $insert_query = "insert into Product_List (retailer_id,scrape_start_date,url,detail_collected,ObjectKey,RobotName,ExecutionId,FirstExtracted,LastExtracted,ExtractedInLastRun,LastUpdated) values(\'$retailer_id\',\'$current_time\',\'$url\',\'n\',\'$product_object_key\',\'$robotname\',\'$executionid\',\'$current_time\',\'$current_time\',\'y\',\'$current_time\')";
		my $status=&SaveDB($insert_query, $dbh, $robotname);
		if($status == 1)
		{
			$dbh->commit();
			$robotname =~ s/\-\-List//igs;
			#MqPublish($product_object_key,$robotname,$url,$retailer_id);
		}
	# }
	return($product_object_key);
}
sub UpdateProductDetail()
{
	my $object_key=&Dbvalidate(Trim(shift));
	my $retailer_product_reference=&Dbvalidate(Trim(shift));
	my $product_name=&Dbvalidate(Trim(shift));
	my $brand=&Dbvalidate(Trim(shift));
	my $product_desc=&Dbvalidate(Trim(shift));
	my $product_detail=&Dbvalidate(Trim(shift));
	my $dbh = shift;
	my $robotname = shift;
	my $excuetionid = shift;
	my $skuflag = shift;
	my $imageflag = shift;
	my $url = &Dbvalidate(shift);
	my $retailer_id = shift;
	my $mflag = shift;
	my $detail_collected;
	my $productflag=0;
	my ($cdate,$ctime,$cday)=&Updatedate();
	my $current_time = $cdate.' '.$ctime;
	$productflag = 1 if($product_name eq '' or ($product_desc eq '' && $product_detail eq '') or $retailer_product_reference eq '');
	if($mflag == 1)
	{
		$detail_collected = 'm';
	}
	elsif(($productflag == 1 && $skuflag == 1 && $imageflag == 1) or ($productflag == 1 && $skuflag == 0 && $imageflag == 0))
	{
		$detail_collected = 'x';
		$dbh->rollback();
	}
	elsif($productflag == 0 && $skuflag==0 && $imageflag == 0)
	{
		$detail_collected = 'y';		
	}
	else
	{
		$detail_collected = 's';		
	}
	# my $update_query = "update $product_table_name set retailer_product_reference=\'$retailer_product_reference\',product_name=\'$product_name\',brand=\'$brand\',product_description=\'$product_desc\',product_detail=\'$product_detail\',detail_collected=\'$detail_collected\',RobotName=\'$robotname\',ExecutionId=\'$excuetionid\',LastUpdated=\'$current_time\' where ObjectKey=\'$object_key\'";
	# my $status = &SaveDB($update_query, $dbh, $robotname);
	# if($status == 1)
	# {
		# $dbh->commit();
	# }
	# elsif($status == 0)
	# {
		# $dbh->rollback();
	# }	
	my $update_query = "update Product_List set detail_collected=\'$detail_collected\',LastUpdated=\'$current_time\' where retailer_id=\'$retailer_id\' and ObjectKey=\'$object_key\'";
	my $insert_query = "insert into Product (retailer_id,scrape_start_date,url,retailer_product_reference,product_name,brand,product_description,product_detail,detail_collected,ObjectKey,RobotName,ExecutionId,FirstExtracted,LastExtracted,ExtractedInLastRun,LastUpdated) values(\'$retailer_id\',\'$current_time\',\'$url\',\'$retailer_product_reference\',\'$product_name\',\'$brand\',\'$product_desc\',\'$product_detail\',\'$detail_collected\',\'$object_key\',\'$robotname\',\'$excuetionid\',\'$current_time\',\'$current_time\',\'y\',\'$current_time\')";
	return ($insert_query,$update_query);
}

########Inserting into Product_Completed Table
sub SaveProductCompleted()
{
	my $object_key=&Dbvalidate(Trim(shift));
	my $retailer_id = shift;
	my ($cdate,$ctime,$cday)=&Updatedate();
	my $current_time = $cdate.' '.$ctime;
	my $insert_qry = "insert into $Product_Completed (retailer_id, product_id, LastUpdated) values(\'$retailer_id\',\'$object_key\',\'$current_time\')";
	return $insert_qry;
}

sub Trim($) 
{
  my $string = shift;
  $string =~ s/<[^>]*?>/ /igs;
  $string =~ s/\&nbsp\;/ /igs;
  $string =~ s/^\s*n\/a\s*$//igs;
  $string =~ s/\&\#039\;/'/igs;
  $string =~ s/\&\#43\;/+/igs;
  $string =~ s/amp;//igs;
  $string =~ s/\s+/ /igs;
  $string =~ s/^\s+|\s+$//igs;
  return $string;
}
sub Objectkey_Url()
{
	my $robotname_list = shift; 
	my $dbh=shift;
	my $robotname = shift;
	my $retailer_id = shift;
	my %hashUrl;
	my $select_query = "SELECT url,ObjectKey FROM Product_List where retailer_id =\'$retailer_id\' and detail_collected = \'n\'";
	my $sth_in = $dbh->prepare($select_query);
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
		open fh,">>".$dpath.$robotname."_".$date."_Error.txt";
		print fh "$select_query query get following error $DBI::errstr\n";
		close fh;
		sleep 10;
		goto Refetch;
	}
}
sub GenerateRandom_String()
{
	my $tablename = shift;
	my $retailerChar = shift;
	my $dbh = shift;
	my $robotname = shift;
	my $currtime = Time::HiRes::time;  # get the current time in as double 
	$currtime =~ s/\.//igs;
	# creates a random pattern to generate a string
	my $pattern = "$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]$char[rand(2)]";
	my $random_string = $random->randpattern($pattern);
	# concatenate the 3 chars for the retailer, the random string and current date time stamp
	$random_string = $retailerChar.$random_string.$currtime;
	# generate md5 hash for the above string
	$random_string = uc(md5_hex($random_string));
	return $random_string;
}
sub RetailerUpdate()
{
	my $retailer_id = shift;
	my $executionid = shift;
	my $dbh = shift;
	my $robotname = shift;
	my $status = shift;
	my $query;
	my ($cdate,$ctime,$cday)=&Updatedate();
	my $current_time = $cdate.' '.$ctime;
	if($status eq 'start')
	{
		$query="update Retailer set ExecutionId=\'$executionid\',FirstExtracted\=\'$current_time\' where ObjectKey=\'$retailer_id\'";
	}
	elsif($status eq 'end')
	{
		$query="update Retailer set ExecutionId=\'$executionid\',LastExtracted\=\'$current_time\',ExtractedInLastRun\=\'y\',LastUpdated\=\'$current_time\' where ObjectKey=\'$retailer_id\'";
	}
	&SaveDB($query, $dbh, $robotname);
}
sub Updatedate() # DEPLOYS DATE, TIME AND WEEK DAY IN BST FORMAT
{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mon++;
	my @week_name = qw(sun mon tue wed thu fri sat);
	my $day=$week_name[$wday];
	$mon= '0'.$mon if ($mon <= 9);
	$mday= '0'.$mday if ($mday <= 9);	
	my $date=1900+$year.'-'.$mon.'-'.$mday;
	my $time=$hour.':'.$min.':'.$sec;	
	return ($date, $time, $day);
}
sub ExecuteQueryString()
{
	my $queryStringref = shift;
	my $robotname = shift;	
	my $dbh = shift;
	my $logger = shift;
	my @queryString = @$queryStringref;
	foreach my $query (@queryString)
	{
		#print $query,"\n";
		my $sth_in = $dbh->prepare($query);
		if($sth_in->execute())
		{
			$sth_in->finish();
		}
		else
		{
			my $error = $DBI::errstr;
			print "$query <> $error \n";
			open fh,">>".$dpath.$robotname."_".$date."_Error.txt";
			print fh "$query query get following error $error\n";
			close fh;
			#$logger->send("$query<-->$error");
			eval{$sth_in->finish();}	
		}
	}
	$dbh->commit();
}
sub ExecuteQueryString2()
{
	my $queryStringref = shift;
	my $robotname = shift;	
	my $dbh = shift;
	my $logger = shift;
	my @queryString = @$queryStringref;
	my $qcount = 0;
	my $xcount = 0;
	my $errquery = 0;
	foreach my $query (reverse @queryString)
	{	
		$qcount++;
		if($qcount == 1)
		{
			if($query =~ m/update\s*Product_List\s*set\s*detail_collected\s*\=\s*\'x\'/is)
			{
				$xcount = 1
			}
			elsif($query =~ m/update\s*Product_List\s*set\s*detail_collected\s*\=\s*\'n\'/is)
			{
				goto RollBack;
			}
			elsif($query =~ m/update\s*Product_List\s*set\s*detail_collected\s*\=\s*\'y\'/is)
			{
				goto QueryProcess;
			}
			elsif($query =~ m/update\s*Product_List\s*set\s*detail_collected\s*\=\s*\'m\'/is)
			{
				goto QueryProcess;
			}
			elsif($query =~ m/update\s*Product_List\s*set\s*detail_collected\s*\=\s*\'s\'/is)
			{
				goto QueryProcess;
			}
			else
			{
				goto RollBack;
			}
		}
		QueryProcess:
		goto RollBack if( ($xcount == 1) && ($qcount > 2) );
		if(( ($xcount == 1) && ($qcount <= 2) ) or ($xcount == 0))
		{
			my $sth_in = $dbh->prepare($query);
			if($sth_in->execute())
			{
				$sth_in->finish();
			}
			else
			{
				my $error = $DBI::errstr;
				open fh,">>".$dpath.$robotname."_".$date."_Error.txt";
				print fh "$query query get following error $error\n";
				close fh;
				$logger->send("$query<-->$error");
				$errquery = 1;
				goto RollBack;
				eval{$sth_in->finish();}	
			}
		}
	}
	RollBack:
	if ($errquery == 1)
	{
		$dbh->rollback();
	}
	$dbh->commit();	
}
