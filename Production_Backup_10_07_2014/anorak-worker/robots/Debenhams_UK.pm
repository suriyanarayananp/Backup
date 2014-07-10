#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Debenhams_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
#require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Debenhams_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;
	####Variable Initialization##############
	$robotname='Debenhams-UK--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Deb';
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

	my $skuflag = 0;my $imageflag = 0;
	if($product_object_key)
	{
		my $url3=$url;
		my @query_string;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.debenhams.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &get_content($url3);
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$brand,$sub_category,$item_no,$product_name,$description,$prod_detail,$out_of_stock,$colour,$off,$sav);
		# price		
		if ( $content2 =~ m/<div\s*id\=\"price[^>]*?>([\w\W]*?)\s*<\/div>/is )
		{
			my $price_text = $1;
			my $price_text2 = &DBIL::Trim($price_text);
			
			if ( $price_text2 =~ m/now\s*\&pound\;?[\d\.]+\s*now\s*\£?([\d\.]+)/is )
			{
				$price = &DBIL::Trim($1);
				$price=~s/[a-z\;\&]*//igs;
			}		
			elsif ( $price_text2 =~ m/now\s*\&pound\;?([\d\.]+)/is )
			{
				$price = &DBIL::Trim($1);
				$price=~s/[a-z\;\&]*//igs;				
			}
			elsif ( $price_text2 =~ m/\&pound\;\s*([\d\.]+)/is )
			{
				$price = &DBIL::Trim($1);
				$price=~s/[a-z\;\&]*//igs;							
			}
			
			if($price_text=~m/class\s*\=\s*\"\s*off\s*\"[^>]*?>([^<]*?)</is)
			{
				$off=$1;
			}
			
			if($price_text=~m/class\s*\=\s*\"\s*save\s*\"[^>]*?>([^<]*?)</is)
			{
				$sav=$1;
			}
			
			$price_text =~ s/<[^>]*?>/ /igs;
			$price_text =~ s/\&nbsp\;|amp\;/ /igs;
			$price_text =~ s/\s+/ /igs;
			$price_text =~ s/^\s+|\s+$//igs;
			$price_text =~ s/\&pound\;/\Â\£/igs;
		}
		# ItemNo
		if ( $content2 =~ m/<meta\s*property\=\"product_number"\s*content=\"([^<]*?)\s*\"\s*\/\s*>/is )
		{
			$item_no = &DBIL::Trim($1);
			
			my $ckproduct_id = &DBIL::UpdateProducthasTag($item_no, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#Brand
		if ( $content2 =~ m/<meta\s*property\=\"brand"\s*content=\"([^>]*?)\s*\"\s*\/\s*>/is )
		{
			$brand = &DBIL::Trim($1);
			
			&DBIL::SaveTag('Brand',lc($brand),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		}		
		# product_name
		if ( $content2 =~ m/<h2\s*class\=\"item\-name[^>]*?>\s*([\w\W]*?)\s*<\/h2>/is )
		{
			$product_name = &DBIL::Trim($1);
		}
		# description
		if ( $content2 =~ m/<div\s*id\=\"view\-more\-detail[^>]*?>([\w\W]*?)\s*<\/div>/is )
		{
			$description = &DBIL::Trim($1);	
			$description=decode_entities($description);
		}
		if ( $content2 =~ m/<div\s*class\=\"pdp_tabcontent\"\s*id\=\"info1\">\s*([\w\W]*?)\s*<\/div>/is )
		{
			$prod_detail = &DBIL::Trim($1);
			$prod_detail=decode_entities($prod_detail);
		}
		#If description and product detail is blank but product available
		if(($product_name ne '' or $item_no ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
			$description='-';
		}
		
		# size & out_of_stock
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my ($price_text1,$price_text2,$price_text3);
		
		if($content2=~m/<div\s*id\=\"entitledItem[^>]*?>\s*([\w\W]*?)<\/div>/is)
		{
			my $size_content = $1;
			my @size_array;
			while($size_content=~m/\{\s*\"\s*catentry[^\}]*\}[^\}]*\}/igs)
			{
				my $blk=$&;			
				
				my $size;
				if ( $blk =~ m/size_([^\']*)(?:\'|\")/is )
				{
					$size = $1;
				}
				
				####Duplicate Size######
				if(grep( /^$size$/, @size_array ))
				{
					next;
				}
				push(@size_array,$size);
				
				if($blk=~m/Colour_([^\'\"]*)(?:\'|\")/is)
				{
					my $sku_colour = $1;					
					$colour = $sku_colour;					
				}
				$colour='no raw colour'	if($colour eq '#N/A' or $colour eq '' or $colour eq ' ');
				
				if ( $blk =~ m/inventory_status\s*(?:\"|\')?\s*\:?\s*(?:\"|\')([^<]*?)(?:\"|\')\s*/is )
				{
					$out_of_stock = $1;
					
					$out_of_stock =~ s/^\s*Unavailable\s*$/y/ig;
					$out_of_stock =~ s/^\s*available\s*$/n/ig;
					$out_of_stock =~ s/^\s*$/n/ig;
				}
				
				if ( $blk =~ m/(?:\"|\')\s*was\s*(?:\"|\')\s*\:\s*(?:\"|\')\s*([^\"]*?)(?:\"|\')/is )
				{
					$price_text1 = $1;
				}
				
				if ( $blk =~ m/(?:\"|\')\s*now\d*\s*(?:\"|\')\s*\:\s*(?:\"|\')\s*([^\"]*?)(?:\"|\')/is )
				{
					$price_text2 = $1;
				}
				
				if ( $blk =~ m/(?:\"|\')\s*offer\w*\W*price\d*\s*(?:\"|\')\s*\:\s*(?:\"|\')\s*([^\"]*?)(?:\"|\')/is )
				{
					$price_text3 = $1;					
				}				
				
				if($price_text3)
				{
					$price=$price_text3;									
				}
				else
				{
					$price=$price_text2;	
				}
				
				if ( $price =~ m/now\s*\&pound\;?([\d\.]+)/is )
				{
					$price = &DBIL::Trim($price);					
					$price=~s/[a-z\;\&]*//igs;					
				}
				elsif ( $price =~ m/\&pound\;\s*([\d\.]+)/is )
				{
					$price = &DBIL::Trim($price);					
					$price=~s/[a-z\;\&]*//igs;					
				}
				
				$price_text= $price_text1." ".$price_text2." ".$price_text3." ".$off." ".$sav;
				
				$price_text =~ s/<[^>]*?>/ /igs;
				$price_text =~ s/\&nbsp\;|amp\;/ /igs;
				$price_text =~ s/\s+/ /igs;
				$price_text =~ s/^\s+|\s+$//igs;
				$price_text =~ s/\&pound\;/\Â\£/igs;
		
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$colour;
				push(@query_string,$query);
				print"sku_colour::$colour\n";
			}
		}
		else
		{
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'','no raw colour','n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}='no raw colour';
			push(@query_string,$query);
			print"sku_colour::no raw colour\n";
		}
		
		# main image		
		if($content2=~m/<div\s*id\=\"pdp\-large[^>]*?>\s*<img\s*src\=\"([^<]*?)\"\s*[^>]*?>\s*<\/div>/is)
		{
			my $main_image = &DBIL::Trim($1);
			$main_image =~ s/\$//g;
			$main_image =~ s/\?V7PdpLarge\s*$/?wid=1250/ig;
			
			my ($imgid,$img_file) = &DBIL::ImageDownload($main_image,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			if($colour ne '')
			{
				$image_objectkey{$img_object}=$colour;
				print"colour::$colour\n";	
			}
			else
			{	
				$image_objectkey{$img_object}='no raw colour';
				print"colour::no raw colour\n";
			}
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);
		}
		#alt_image
		if($content2=~m/<div\s*id\=\"pdp\-alts[^>]*?>\s*([\w\W]*?)\s*<\/div>/is)
		{
			my $alt_image_content = $1;
			while($alt_image_content=~m/<a\s*[^>]*?\s*href\=\"([^<]*?)\"[^>]*?>/igs)
			{
				my $alt_image = &DBIL::Trim($1);
				$alt_image =~ s/\$//g;
				$alt_image =~ s/\?V7PdpLarge\s*$/?wid=1250/ig;
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				if($colour ne '')
				{
					$image_objectkey{$img_object}=$colour;			
					print"colour::$colour\n";		
				}
				else
				{
					$image_objectkey{$img_object}='no raw colour';
					print"colour::no raw colour\n";					
				}
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
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
		
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$item_no,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
	
		LAST:
		$dbh->commit();
	}
}1;

sub get_content()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>$url);
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
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
			goto Home;
		}
	}
	return $content;
}
