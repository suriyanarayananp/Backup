#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Myer_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Myer_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Myer-AU--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Chi';
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
	# $cookie = HTTP::Cookies->new(file=>$cookie_file,autosave=>1); 
	# $ua->cookie_jar($cookie);
	###########################################
	
	my $skuflag = 0;my $imageflag = 0;my @query_string;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		print "\nUrl : $url3\n";
		
		my $content2=&GetContent($url3,'GET','','');
		# $content2=replace($content2);
		my($product_id,$brand,$product_name,$description,$prod_detail);
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;my %sku_objectkey;my %image_objectkey;my %hash_default_image;
		### Loop for checking x products
		if( $content2!~m/<div\s*class\=\"product\-code\">\s*Product\s*Code\s*([^<]*?)\s*</is )
		{
			goto NOINFO;
		}
		
		### Product id
		if( $content2 =~m/<div\s*class\=\"product\-code\">\s*Product\s*Code\s*([^<]*?)\s*</is )
		{
			$product_id=$1;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
		}
		### Brand and Prodcut Name
		if( $content2 =~m/<title>\s*([^<]*?)\s*\|\s*([^<]*?)\s*\|[^<]*?<\/title>/is )
		{
			$brand=decode_entities($1);
			$product_name=$2;
			if ( $brand !~ /^\s*$/g )
			{
				&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			}
		}
		elsif( $content2 =~m/<span\s*class\=\"brand\s*myriad\-bold\">\s*([^<]*?)\s*<\/span><\/h2>\s*<h2\s*class\=\"myriad\-light\">\s*([^<]*?)\s*</is )
		{
			$brand=decode_entities($1);
			$product_name=$2;
			if ( $brand !~ /^\s*$/g )
			{
				&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			}
		}
		### Product Description
		if ( $content2 =~ m/<h2[^>]*?>\s*Product\s*Info\s*<\/h2>\s*([\w\W]*?)\s*<\/div>/is )
		{
			$description=decode_entities($1);
			$description=&trim($description);
		}
		else
		{$description=" ";}
		
		my ($sku_id);my $color_flag=0;my %color;
		if($content2=~m/productId\:\s*\"([^\"]*?)\"/is)
		{
			$sku_id=$1;
		}
		### This below content is using for checking the stock whether it is in or not.
		my $post_cont='productId='.$sku_id.'&requesttype=ajax';
		my $content1=&GetContent('http://www.myer.com.au/webapp/wcs/stores/servlet/AvailabitySelectedProduct','POST',$post_cont,'');
		
		### all color which is available in the page source is captured and pushed into hash.
		if($content2=~m/>\s*Select\s*colour\s*([\w\W]*?)\s*<\/div>\s*<\/div>\s*<\/div>\s*<\/div>/is)
		{
			my $block=$1;
			while($block=~m/<option\s*value\=\'([^<]*?)\'\s*>\s*([^<]*?)\s*<\/option>/igs)
			{
				$color{$1}=$2;
			}
			$color_flag=1;
		}
		elsif($content2=~m/<div[^>]*?>\s*colour\s*<\/div>\s*<div\s*class\=\"active\-size\">\s*([^<]*?)\s*<\/div>/is)
		{
			$color{$1}=$1;
			$color_flag=1;
		}

		### Sku information ( Price , price text , color , size and out of stock )
		
		my $block;my %color_dup;
		if($content2=~m/<div\s*id\=\"myerEntitledItem_[^\"]*?\"\s*style\=\"[^\"]*?\">\s*([\w\W]*?)\s*<\/div>/is)
		{
			$block=$1;
		}	
		if($color_flag==1)
		{
			while($content1=~m/\"([\d]+)\"\:\s*\{\s*\"class\"\:\s*[^\,]*?\,\s*\"partNumber\"\:[^\,]*?\,\s*\"ageLimit\"\:[^\,]*?\,\s*\"minQuantity\"\:[^\,]*?\,\s*\"inventoryStatus\"\:\s*\"?\s*(IS|LS|NL)\s*\"?\s*\,\s*\"maxQuantity\"\:[^<]*?\s*\}/igs)
			{
				my $catentry_id=$1;
				my $out_of_stock='n';
				my $loop=0;
				if($block=~m/\{\s*\"catentry_id\"\s*\:\s*\"$catentry_id\"\,\s*\"partNumber\"\s*\:\s*\"[^\"]*?\",\s*([^<]*?)\s*\}/is)
				{
					my $sku_block=$1;
					if($sku_block ne '')
					{
						my ($color,$size1,$size2);
						while($sku_block=~m/\"([^\"]*?)\"\s*\:\s*\"([^\"]*?)\"/igs)
						{
							my $size_name=$1;
							my $size_value=$2;
							
							if($size_name=~m/Color/is)
							{
								$color=$color{$size_value};
							}
							else
							{
								$size1.=$size_name.' : '."$size_value ";
								$size2=$size_value;
							}
							$loop++;
						}
						$size1=~s/^\s+|\s+$//igs;$size2=~s/^\s+|\s+$//igs;$color=~s/^\s+|\s+$//igs;
						
						my $price_url='http://www.myer.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID?storeId=10251&langId=-1&catalogId=10051&productId='.$catentry_id.'&onlyCatalogEntryPrice=true';
						my $price_cont=&GetContent($price_url,'GET','','');
						my ($price,$price_text);
						if($price_cont=~m/\"offerPrice\"\:\s*\"([^\"]*?)\"/is)
						{
							$price=$1;
							$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;
						}
						if($price_cont=~m/<span\s*class\=\'price\'>\s*([\w\W]*?)\s*<\/span>/is)
						{
							$price_text=$1;
							$price_text=~s/<[^>]*?>//igs;$price_text=~s/\s+/ /igs;$price_text=~s/^\s+|\s+$//igs;
						}
						if(($price eq '') and ($price_text eq ''))
						{
							if( $content2=~m/<span\s*class\=\'price\'>\s*([^<]*?)\s*<span\s*class\=\'price\-now\'>\s*([^<]*?)\s*<\/span>/is )
							{
								$price_text=$1." $2";
								$price=$2;
								$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;$price=~s/[a-z]+//igs;$price=~s/\s+/ /igs;$price=~s/^\s+|\s+$//igs;
							}
							elsif( $content2=~m/<span\s*class\=\'price\'>\s*([^<]*?)\s*<\/span>/is )
							{
								$price_text=$1;
								$price=$price_text;
								$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;
							}
						}
						$price="null" if($price eq '');
						my $dup_color=$color.$size2;
						$dup_color=~s/\W//igs;
						if($color_dup{$dup_color} eq '')
						{
							if($loop > 2) ### Some product url is having different types of size and it is needed to combine.
							{
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size1,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
							else  ### for single type of size
							{
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size2,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
							$color_dup{$dup_color}=1;
						}
					}
				}
			}
			while($content1=~m/\"([\d]+)\"\:\s*\{\s*\"class\"\:\s*[^\,]*?\,\s*\"partNumber\"\:[^\,]*?\,\s*\"ageLimit\"\:[^\,]*?\,\s*\"minQuantity\"\:[^\,]*?\,\s*\"inventoryStatus\"\:\s*\"?\s*(OS|null)\s*\"?\s*\,\s*\"maxQuantity\"\:[^<]*?\s*\}/igs)
			{
				my $catentry_id=$1;
				my $out_of_stock='y';
				
				my $loop=0;
				if($block=~m/\{\s*\"catentry_id\"\s*\:\s*\"$catentry_id\"\,\s*\"partNumber\"\s*\:\s*\"[^\"]*?\",\s*([^<]*?)\s*\}/is)
				{
					my $sku_block=$1;
					if($sku_block ne '')
					{
						my ($color,$size1,$size2);
						while($sku_block=~m/\"([^\"]*?)\"\s*\:\s*\"([^\"]*?)\"/igs)
						{
							my $size_name=$1;
							my $size_value=$2;
							
							if($size_name=~m/Color/is)
							{
								$color=$color{$size_value};
							}
							else
							{
								$size1.=$size_name.' : '."$size_value ";
								$size2=$size_value;
							}
							$loop++;
						}
						$size1=~s/^\s+|\s+$//igs;$size2=~s/^\s+|\s+$//igs;$color=~s/^\s+|\s+$//igs;
						
						my $price_url='http://www.myer.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID?storeId=10251&langId=-1&catalogId=10051&productId='.$catentry_id.'&onlyCatalogEntryPrice=true';
						my $price_cont=&GetContent($price_url,'GET','','');
						my ($price,$price_text);
						if($price_cont=~m/\"offerPrice\"\:\s*\"([^\"]*?)\"/is)
						{
							$price=$1;
							$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;
						}
						if($price_cont=~m/<span\s*class\=\'price\'>\s*([\w\W]*?)\s*<\/span>/is)
						{
							$price_text=$1;
							$price_text=~s/<[^>]*?>//igs;$price_text=~s/\s+/ /igs;$price_text=~s/^\s+|\s+$//igs;
						}
						if(($price eq '') and ($price_text eq ''))
						{
							if( $content2=~m/<span\s*class\=\'price\'>\s*([^<]*?)\s*<span\s*class\=\'price\-now\'>\s*([^<]*?)\s*<\/span>/is )
							{
								$price_text=$1." $2";
								$price=$2;
								$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;$price=~s/[a-z]+//igs;$price=~s/\s+/ /igs;$price=~s/^\s+|\s+$//igs;
							}
							elsif( $content2=~m/<span\s*class\=\'price\'>\s*([^<]*?)\s*<\/span>/is )
							{
								$price_text=$1;
								$price=$price_text;
								$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;
							}
						}
						$price="null" if($price eq '');
						my $dup_color=$color.$size2;
						$dup_color=~s/\W//igs;
						if($color_dup{$dup_color} eq '')
						{
							if($loop > 2) ### Some product url is having different types of size and it is needed to combine.
							{
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size1,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
							else  ### for single type of size
							{
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size2,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
							$color_dup{$dup_color}=1;
						}
					}
				}
			}
		}
		else
		{
			while($content1=~m/\"([\d]+)\"\:\s*\{\s*\"class\"\:\s*[^\,]*?\,\s*\"partNumber\"\:[^\,]*?\,\s*\"ageLimit\"\:[^\,]*?\,\s*\"minQuantity\"\:[^\,]*?\,\s*\"inventoryStatus\"\:\s*\"?\s*(IS|LS|NL)\s*\"?\s*\,\s*\"maxQuantity\"\:[^<]*?\s*\}/igs)
			{
				my $catentry_id=$1;
				my $out_of_stock='n';
				my $loop=0;
				if($block=~m/\{\s*\"catentry_id\"\s*\:\s*\"$catentry_id\"\,\s*\"partNumber\"\s*\:\s*\"[^\"]*?\",\s*([^<]*?)\s*\}/is)
				{
					my $sku_block=$1;
					my ($color,$size1,$size2);
					while($sku_block=~m/\"([^\"]*?)\"\s*\:\s*\"([^\"]*?)\"/igs)
					{
						my $size_name=$1;
						my $size_value=$2;
						
						if($size_name=~m/Color/is)
						{
							$color=$color{$size_value};
						}
						else
						{
							$size1.=$size_name.' : '."$size_value ";
							$size2=$size_value;
						}
						$loop++;
					}
					$size1=~s/^\s+|\s+$//igs;$size2=~s/^\s+|\s+$//igs;$color=~s/^\s+|\s+$//igs;
				
					my $price_url='http://www.myer.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID?storeId=10251&langId=-1&catalogId=10051&productId='.$catentry_id.'&onlyCatalogEntryPrice=true';
					my $price_cont=&GetContent($price_url,'GET','','');
					my ($price,$price_text);
					if($price_cont=~m/\"offerPrice\"\:\s*\"([^\"]*?)\"/is)
					{
						$price=$1;
						$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;
					}
					if($price_cont=~m/<span\s*class\=\'price\'>\s*([\w\W]*?)\s*<\/span>/is)
					{
						$price_text=$1;
						$price_text=~s/<[^>]*?>//igs;$price_text=~s/\s+/ /igs;$price_text=~s/^\s+|\s+$//igs;
					}
					if(($price eq '') and ($price_text eq ''))
					{
						if( $content2=~m/<span\s*class\=\'price\'>\s*([^<]*?)\s*<span\s*class\=\'price\-now\'>\s*([^<]*?)\s*<\/span>/is )
						{
							$price_text=$1." $2";
							$price=$2;
							$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;$price=~s/[a-z]+//igs;$price=~s/\s+/ /igs;$price=~s/^\s+|\s+$//igs;
						}
						elsif( $content2=~m/<span\s*class\=\'price\'>\s*([^<]*?)\s*<\/span>/is )
						{
							$price_text=$1;
							$price=$price_text;
							$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;
						}
					}
					$price="null" if($price eq '');
					my $dup_color=$color.$size2;
					$dup_color=~s/\W//igs;
					if($color_dup{$dup_color} eq '')
					{
						if($loop > 2) ### Some product url is having different types of size and it is needed to combine.
						{
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size1,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}='No raw color';
							push(@query_string,$query);
						}
						else  ### for single type of size
						{
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size2,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}='No raw color';
							push(@query_string,$query);
						}
						$color_dup{$dup_color}=1;
					}
				}
			}
			while($content1=~m/\"([\d]+)\"\:\s*\{\s*\"class\"\:\s*[^\,]*?\,\s*\"partNumber\"\:[^\,]*?\,\s*\"ageLimit\"\:[^\,]*?\,\s*\"minQuantity\"\:[^\,]*?\,\s*\"inventoryStatus\"\:\s*\"?\s*(OS|null)\s*\"?\s*\,\s*\"maxQuantity\"\:[^<]*?\s*\}/igs)
			{
				my $catentry_id=$1;
				my $out_of_stock='y';
				
				my $loop=0;
				if($block=~m/\{\s*\"catentry_id\"\s*\:\s*\"$catentry_id\"\,\s*\"partNumber\"\s*\:\s*\"[^\"]*?\",\s*([^<]*?)\s*\}/is)
				{
					my $sku_block=$1;
					my ($color,$size1,$size2);
					while($sku_block=~m/\"([^\"]*?)\"\s*\:\s*\"([^\"]*?)\"/igs)
					{
						my $size_name=$1;
						my $size_value=$2;
						
						if($size_name=~m/Color/is)
						{
							$color=$color{$size_value};
						}
						else
						{
							$size1.=$size_name.' : '."$size_value ";
							$size2=$size_value;
						}
						$loop++;
					}
					$size1=~s/^\s+|\s+$//igs;$size2=~s/^\s+|\s+$//igs;$color=~s/^\s+|\s+$//igs;
					
					my $price_url='http://www.myer.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID?storeId=10251&langId=-1&catalogId=10051&productId='.$catentry_id.'&onlyCatalogEntryPrice=true';
					my $price_cont=&GetContent($price_url,'GET','','');
					my ($price,$price_text);
					if($price_cont=~m/\"offerPrice\"\:\s*\"([^\"]*?)\"/is)
					{
						$price=$1;
						$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;
					}
					if($price_cont=~m/<span\s*class\=\'price\'>\s*([\w\W]*?)\s*<\/span>/is)
					{
						$price_text=$1;
						$price_text=~s/<[^>]*?>//igs;$price_text=~s/\s+/ /igs;$price_text=~s/^\s+|\s+$//igs;
					}
					if(($price eq '') and ($price_text eq ''))
					{
						if( $content2=~m/<span\s*class\=\'price\'>\s*([^<]*?)\s*<span\s*class\=\'price\-now\'>\s*([^<]*?)\s*<\/span>/is )
						{
							$price_text=$1." $2";
							$price=$2;
							$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;$price=~s/[a-z]+//igs;$price=~s/\s+/ /igs;$price=~s/^\s+|\s+$//igs;
						}
						elsif( $content2=~m/<span\s*class\=\'price\'>\s*([^<]*?)\s*<\/span>/is )
						{
							$price_text=$1;
							$price=$price_text;
							$price=~s/\,//igs;$price=~s/\$//igs;$price=~s/\.00//igs;
						}
					}
					$price="null" if($price eq '');
					my $dup_color=$color.$size2;
					$dup_color=~s/\W//igs;
					if($color_dup{$dup_color} eq '')
					{
						if($loop > 2) ### Some product url is having different types of size and it is needed to combine.
						{
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size1,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}='No raw color';
							push(@query_string,$query);
						}
						else  ### for single type of size
						{
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size2,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}='No raw color';
							push(@query_string,$query);
						}
						$color_dup{$dup_color}=1;
					}
				}
			}
		}
			
		### Main , alternate and swatch image
		### color_flag will be set to 1 if color is available.
		if($color_flag==1)
		{
			my @color_keys = keys %color;
			if($content2=~m/<img\s*id\=\"swatchColour0\"\s*class\=\"thumb\-swatch\"\s*alt\=\"[^\"]*?\"\s*title\=\"[^\"]*?\"\s*src\=\"([^\"]*?)\"/is)
			{
				my $swatch='http://www.myer.com.au'.$1;
				my $code=&GetCode($swatch); ### Color is given in two format (swatch and dropdown). IF the code of first swatch url is 400, then the color is given in dropdown model. If 200, it is in swatch.
				if($code=~m/40/is)
				{
					foreach(@color_keys)
					{
						my $colour=$color{$_};
						my $alt_imgae=1;
						if($content2=~m/<div\s*class\=\"main\-image\">\s*<ul\s*id\=\"product\-slider\">\s*([\w\W]*?)\s*<\/ul>\s*<\/div>/is)
						{
							my $image_block=$1;
							while($image_block=~m/<img\s*class\=\"[^<]*?\"\s*src\=\"([^<]*?)\"\s*alt\=\"[^<]*?\"\s*title\=\"[^<]*?\"\s*style\=\"[^<]*?\"\s*\/>/igs)
							{
								my $main_url='http://www.myer.com.au'.$1;
								if($alt_imgae==1)
								{
									my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product',$retailer_name);
									my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$imageflag = 1 if($flag);
									$image_objectkey{$img_object}=$colour;
									$hash_default_image{$img_object}='y';
									$alt_imgae++;
									push(@query_string,$query);
								}
								else
								{
									my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product',$retailer_name);
									my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$imageflag = 1 if($flag);
									$image_objectkey{$img_object}=$colour;
									$hash_default_image{$img_object}='n';
									push(@query_string,$query);
								}
							}
						}
					}
				}
				elsif($code=~m/200/is)
				{
					foreach(@color_keys)
					{
						my $colour=$color{$_};
						if($content2=~m/title\=\"$colour\"\s*src\=\"([^\"]*?)\"/is)
						{
							my $swatch_url='http://www.myer.com.au'.$1;
							my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_url,'swatch',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_url,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colour;
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
						if($content2=~m/<img[^<]*?src\=\"([^<]*?$colour[^<]*?)\"\s*style\=\"[^\"]*?\"\s*onerror\=\"[^\"]*?\"\s*\/>/is)
						{
							my $main_url='http://www.myer.com.au'.$1;
							my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colour;
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
					}
				}
			}
			else
			{
				foreach(@color_keys)
				{
					my $colour=$color{$_};
					my $alt_imgae=1;
					if($content2=~m/<div\s*class\=\"main\-image\">\s*<ul\s*id\=\"product\-slider\">\s*([\w\W]*?)\s*<\/ul>\s*<\/div>/is)
					{
						my $image_block=$1;
						while($image_block=~m/<img\s*class\=\"[^<]*?\"\s*src\=\"([^<]*?)\"\s*alt\=\"[^<]*?\"\s*title\=\"[^<]*?\"\s*style\=\"[^<]*?\"\s*\/>/igs)
						{
							my $main_url='http://www.myer.com.au'.$1;
							if($alt_imgae==1)
							{
								my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$colour;
								$hash_default_image{$img_object}='y';
								$alt_imgae++;
								push(@query_string,$query);
							}
							else
							{
								my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$colour;
								$hash_default_image{$img_object}='n';
								push(@query_string,$query);
							}
						}
					}
				}
			}
		}
		else
		{
			my $alt_imgae=1;
			if($content2=~m/<div\s*class\=\"main\-image\">\s*<ul\s*id\=\"product\-slider\">\s*([\w\W]*?)\s*<\/ul>\s*<\/div>/is)
			{
				my $image_block=$1;
				while($image_block=~m/<img\s*class\=\"[^<]*?\"\s*src\=\"([^<]*?)\"\s*alt\=\"[^<]*?\"\s*title\=\"[^<]*?\"\s*style\=\"[^<]*?\"\s*\/>/igs)
				{
					my $main_url='http://www.myer.com.au'.$1;
					if($alt_imgae==1)
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No raw color';
						$hash_default_image{$img_object}='y';
						$alt_imgae++;
						push(@query_string,$query);
					}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No raw color';
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}
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
		NOINFO:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit();
	}
}1;

sub GetContent($$$$)
{
    my $mainurl=shift;
    my $method=shift;
    my $parameter=shift;
    my $referer=shift;
    my $err_count=0;
    home:
    my $req=HTTP::Request->new($method=>"$mainurl");
    if($method eq 'POST')
    {     
        $req->content("$parameter");
    }
    $req->header("Content-Type"=> "application/x-www-form-urlencoded");
    $req->header("Referer"=> "$referer");

    my $res=$ua->request($req);
    
    # $cookie->extract_cookies($res);
    # $cookie->save;
    # $cookie->add_cookie_header($req);
    
    my $code=$res->code;    
    print "\nCODE :: $code\n";    
    open JJ,">>$retailer_file";
	print JJ "$mainurl->$code\n";
	close JJ;
    if($code=~m/5|4/is)
    {
        print "\nNET FAILURE\n";
        print "\nCHECK :: $mainurl\n";
		$err_count++;
		if($err_count<=3)
		{
			sleep(1);
			goto home;	
		}
    }
    elsif($code=~m/20/is)
    {
        my $con=$res->content;                
        return $con;
    }
    elsif($code=~m/30/is)
    {
        my $loc=$res->header('location');                
        $loc=decode_entities($loc);    
        my $loc_url=url($loc,$mainurl)->abs;
        print "\nLocation url : $loc_url\n";
        $mainurl=$loc_url;
        goto home;
    }
}
sub trim($) {
  my $string = shift;
  $string =~ s/<[^>]*?>/ /igs;
  $string =~ s/\&\#8226\;/*/igs;
  $string =~ s/\s+/ /igs;
  $string =~ s/^\s+|\s+$//g;
  $string =~ s/\&\#039\;/'/g;
  return $string;
}
sub replace($)
{
	my $text=shift;
	$text=~s/\&trade\;/™/igs;$text=~s/\&euro\;/€/igs;$text=~s/\&euml\;/ë/igs;$text=~s/\&ecirc\;/ê/igs;$text=~s/\&eacute\;/é/igs;$text=~s/\&egrave\;/è/igs;$text=~s/\&aring\;/å/igs;$text=~s/\&auml\;/ä/igs;$text=~s/\&atilde\;/ã/igs;$text=~s/\&acirc\;/â/igs;$text=~s/\&aacute\;/á/igs;$text=~s/\&agrave\;/à/igs;$text=~s/\&Ouml\;/ö/igs;$text=~s/\&Otilde\;/õ/igs;$text=~s/\&Ocirc\;/ô/igs;$text=~s/\&Oacute\;/ó/igs;$text=~s/\&Ograve\;/ò/igs;$text=~s/\&quot\;/"/igs;$text=~s/\&amp\;/&/igs;$text=~s/\&apos\;/'/igs;$text=~s/\&nbsp\;/ /igs;$text=~s/\&pound\;/£/igs;$text=~s/\&copy\;/©/igs;$text=~s/\&reg\;/®/igs;$text=~s/\&acute\;/´/igs;$text=~s/\&Igrave\;/ì/igs;$text=~s/\&Iacute\;/í/igs;$text=~s/\&Icirc\;/î/igs;$text=~s/\&Iuml\;/ï/igs;$text=~s/\&mdash\;/—/igs;$text=~s/\&ndash\;/–/igs;$text=~s/\&iexcl\;/¡/igs;$text=~s/\&cent\;/¢/igs;$text=~s/\&curren\;/¤/igs;$text=~s/\&yen\;/¥/igs;$text=~s/\&brvbar\;/¦/igs;$text=~s/\&ordf\;/ª/igs;$text=~s/\&macr\;/¯/igs;$text=~s/\&deg\;/°/igs;$text=~s/\&plusmn\;/±/igs;$text=~s/\&Ugrave\;/ù/igs;$text=~s/\&Uacute\;/ú/igs;$text=~s/\&Ucirc\;/û/igs;$text=~s/\&Uuml\;/ü/igs;$text=~s/\&Yacute\;/Ý/igs;$text=~s/\&lsquo\;/‘/igs;$text=~s/\&rsquo\;/’/igs;$text=~s/\&sbquo\;/‚/igs;$text=~s/\&ldquo\;/“/igs;$text=~s/\&rdquo\;/”/igs;$text=~s/\&bdquo\;/„/igs;$text=~s/\&bull\;/·/igs;$text=~s/\&sdot\;/·/igs;
	return $text;
}
sub GetCode($$$$)
{
	my $imageurl=shift;
	my $req=HTTP::Request->new(GET=>"$imageurl");
	$req->header("Content-Type"=> "application/x-www-form-urlencoded");
	my $res=$ua->request($req);
    my $code=$res->code;
	return $code;
}