#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Nastygal_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Nastygal_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Nastygal-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Nas';
	$pid = $$;
	$ip = `/sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`;
	$ip = $1 if($ip =~ m/inet\s*addr\:([^>]*?)\s+/is);
	$excuetionid = $ip.'_'.$pid;
	###########################################
	
	############Proxy Initialization#########
	$country = $1 if($robotname =~ m/\-([A-Z]{2})\-\-/is);
	&DBIL::ProxyConfig($country);
	###########################################
	
	##########User Agent######################
	$ua=LWP::UserAgent->new(show_progress=>1);
	$ua->agent("Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (.NET CLR 3.5.30729)");
	$ua->timeout(30); 
	$ua->cookie_jar({});
	$ua->env_proxy;
	###########################################

	############Cookie File Creation###########
	($cookie_file,$retailer_file) = &DBIL::LogPath($robotname);
	$cookie = HTTP::Cookies->new(file=>$cookie_file,autosave=>1); 
	$ua->cookie_jar($cookie);
	###########################################
	my @query_string;
	my $skuflag = 0;
	my $imageflag = 0;
	my $mflag=0;
	if($product_object_key)
	{
		# my $url=$hashUrl{$product_object_key};
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		my $content1 = get_content($url3);
		###############product_id#################
		my $product_id;
		if($content1=~m/<div\s*class\=\'product\-style\'>\s*([^>]*?)\s*</is)
		{
			$product_id=$1;
			$product_id=~s/Style\s*\#\://igs;
			print"PRODUCT==>$product_id\n";
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			next if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		

		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@image_object_key,@sku_object_key);
		my ($price,$brand,$sub_category,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$select_var,$i,$size,$color,$j);

		#################product_name##################
		if ($content1 =~m/<span\s*class=\'divider\'>\/<\/span>\s*([^>]*?)\s*<\/li>/is)
		{
			$product_name = $1;
			$product_name=&DBIL::Trim($product_name);
			$product_name=decode_entities( $product_name);	
			print"$product_name\n";			
		}
		#################Price_Text & Price ##################
		my $price_text,$price;
		if($content1 =~m/<div\s*class\=\'product\-price\'\s*itemprop\=\'offers\'[^>]*?>\s*<span\s*class\=\'current\-price\'\s*itemprop\=\'price\'>([^>]*?)</is)
		{
			$price_text=$1;	
			$price_text=~s/\,//igs;
			$price=$price_text;
			$price=~s/\$//igs;
			$price=~s/\,//igs;
			$price=~s/\.00//igs;
		}
		elsif($content1=~m/temprop\=\'price\'>([^>]*?)<\/span>\s*<span\s*class\=\'original\-price\'>([^>]*?)<\/span>\s*<span\s*class\=\'markdown\'>([^>]*?)<\/span>/is)
		{
			$price_text="Now $1 Was $2 $3";	
			$price_text=~s/\,//igs;
			$price=$price_text;
			if($price_text=~m/Now\s*([^>]*?)\s*Was/is)
			{
				$price=$1;
				$price=~s/\$//igs;
				$price=~s/\$//igs;
				$price=~s/\,//igs;
				$price=~s/\.00//igs;
			}
		
		}
		elsif($content1 =~m/temprop\=\'price\'>([^>]*?)<\/span>\s*<span\s*class\=\'original\-price\'>([^>]*?)<\/span>/is)
		{
			$price_text="now $1 was $2";	
			$price_text=~s/\,//igs;
			$price=$price_text;
			if($price_text=~m/now\s*([^>]*?)\s*was/is)
			{
				$price=$1;
				$price=~s/\$//igs;
				$price=~s/\$//igs;
				$price=~s/\,//igs;
				$price=~s/\.00//igs;
			}
		
		
		}
		# elsif($content1=~m/data-availableinventory\=\'normal\'\s*for[^>]*?>(\$[^>]*?)</igs)
		# {
			# while($content1=~m/data-availableinventory\=\'normal\'\s*for[^>]*?>([^>]*?)</is)
			# {
				
			# }
		
		# }
		############### color ######################
		if($product_name=~m/^[^>]*?\s*\-\s*([^>]*?)$/is)
		{
			
			$colour=$1;
			
		
		}
		############################# SKU #########################
		
		if($colour ne '')
		{	
			while($content1=~m/<label\s*class\=\'([^>]*?)\'\s*data\-availableinventory\=\'[^>]*?>([^>]*?)</igs)
			{	
				
				my $avl=$1;
				$size=$2;
				if($avl=~m/disabled\s*sku\-label/is)
				{
					$out_of_stock='y';
				}
				else
				{
					$out_of_stock='n';
				}
				
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$colour;
				push(@query_string,$query);
		
			}
		}
		else
		{
			while($content1=~m/<label\s*class\=\'([^>]*?)\'\s*data\-availableinventory\=\'[^>]*?>([^>]*?)</igs)
			{	
				
				my $avl=$1;
				$size=$2;
				if($avl=~m/disabled\s*sku\-label/is)
				{
					$out_of_stock='y';
				
				}
				else
				{
					$out_of_stock='n';
				
				}
				$colour='no raw color';
				
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$colour;
				push(@query_string,$query);
		
			}
		
		
		}
		
		
		####### product_image ##############
		my $count=1;
		if($content1=~m/class\=\'product\-image\'\s*data\-zoom\=\'([^>]*?)\'/is)
		{
			while($content1=~m/class\=\'product\-image\'\s*data\-zoom\=\'([^>]*?)\'/igs)
			{
				my $product_image1="http:$1";
				if ($count eq 1)
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$colour;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				else		
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$colour;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				$count++;
			}
		}	
			
		my @image_obj_keys = keys %image_objectkey;
		my @sku_obj_keys = keys %sku_objectkey;
		foreach my $img_obj_key(@image_obj_keys)
		{
			foreach my $sku_obj_key(@sku_obj_keys)
			{
				if($image_objectkey{$img_obj_key} eq $sku_objectkey{$sku_obj_key})
				{
					my $query=&DBIL::SaveSkuhasImage($sku_obj_key,$img_obj_key,$hash_default_image{$img_obj_key},$product_object_key,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
				}
			}
		}
		
		
		if($content1=~m/itemprop\=\'description\'>([\w\W]*?)<\/p>/is)
		{
			$description=$1;
			$description=~s/\&\#x2F\;/\//igs;
			$description=~s/\&quot\;/\*/igs;
			$description=~s/<[^>]*?>//igs;
			$description=&DBIL::Trim($description);
			
		
		}
		if($content1=~m/<\/p>\s*<p>([\w\W]*?)<\/div>\s*<div\s*class\=\'product-accordion\'>/is)
		{
			$prod_detail=$1;
			$prod_detail=~s/\&\#x2F\;/\//igs;
			$prod_detail=~s/\&quot\;/\*/igs;
			$prod_detail=~s/<[^>]*?>//igs;
			$prod_detail=&DBIL::Trim($prod_detail);
		}
		if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
		   $description=' ';
		}
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$prod_detail,$description,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		$dbh->commit;
	}
}1;


sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	print "\nCODE :: $code";
	open JJ,">>$retailer_file";
	print JJ "$url->$code\n";
	close JJ;
	my $content;
	if($code =~m/20/is)
	{
		$content = $res->content;
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(10);
			goto Home;
		}
	}
	return $content;
}

sub trim
{
	my $txt = shift;
	
	$txt =~ s/\<[^>]*?\>//igs;
	$txt =~ s/\n+/ /igs;
	$txt =~ s/\"/\'\'/g;
	$txt =~ s/^\s+|\s+$//igs;
	$txt =~ s/\s+/ /igs;
	$txt =~ s/\&nbsp\;//igs;
	$txt =~ s/\&amp\;/\&/igs;
	$txt =~ s/\&bull\;/•/igs;
	$txt =~ s/\&quot\;/"/igs;
	$txt =~ s/&frac34;/3\/4/igs;
	$txt =~ s/â„¢/™/igs;
	$txt =~ s/\&eacute\;/é/igs;
	$txt =~ s/Â®/®/igs;
	$txt =~ s/â€™/\'/igs;
	$txt =~ s/Â/®/igs;
	
	return $txt;
}
