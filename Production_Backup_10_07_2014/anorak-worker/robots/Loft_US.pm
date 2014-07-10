#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Loft_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
##require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Loft_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger;
	
	####Variable Initialization##############
	$robotname='Loft-US--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Lof';
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
		$url3='http://www.loft.com'.$url3 unless($url3=~m/^\s*http\:/is);		
		my $content2 = &get_content($url3);
		
		my %tag_hash;
		my %color_hash;
		my %sku_hash;
		my %prod_objkey;
		my %size_hash;
	
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$details,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
				
		#Price_text & Price
		if($content2=~m/price\">\s*<[^<]*?dollars\">\s*([^<]*?)\s*<\/sup>\s*([^<]*?)\s*<[^<]*?cents\">\s*([^<]*?)\s*<\/sup>/is)
		{
			my $text1=$1;
			my $text2=$2;
			my $text3=$3;
			
			if($text3 ne '')
			{
				$text3=".".$text3 unless($text3=~m/\./is);
			}
			my $price_text1=$text1.$text2.$text3;
						
			if($content2=~m/<[^<]*?\"(was)\">\s*[\w\W]*?<div[^<]*?offers[^<]*?>\s*<span[^<]*?price\">([\w\W]*?)<\/span>/is)
			{
				my $was=$1;
				my $was_price=&DBIL::Trim($2);
				$was_price=~s/\$\s*/\$/igs;
				
				$was=~s/(\w+)/\u\L$1/g;
				$price_text=$was." ".$was_price." Now ".$price_text1;				
			}
			else
			{
				$price_text=$price_text1;
			}
			
			#price
			$price=$price_text1;
			$price=~s/\$//igs;
		}
		elsif($content2=~m/<[^<]*?\"sale\">\s*([\w\W]*?)<\/p>/is)
		{
			$price_text=$1;
			$price_text=~s/<sup[^<]*?cents\">/./igs;			
			$price_text=&DBIL::Trim($price_text);
			$price_text=~s/\$\s/\$/igs;
			$price_text=~s/\.\s*\././igs;
			
			#price
			$price=$price_text;
			$price=~s/\$//igs;			
		}
		elsif($content2=~m/<p>([^<]*?)<\/p>\s*<\![^<]*ATPrice[^<]*?>/is)
		{
			$price_text=$1;
			$price_text=&DBIL::Trim($price_text);
			
			# price
			$price=$price_text;
			$price=~s/\$//igs;			
		}
		elsif($content2=~m/Product_Price\=\"([^<]*?)\"/is)
		{
			$price_text=$1;
			$price_text=&DBIL::Trim($price_text);
			
			# price
			$price=$price_text;
			$price=~s/\$//igs;			
		}
		$price=&DBIL::Trim($price);
		$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
		
		# product_id
		my $pid=$1 if($url3=~m/\/([\d]*?)\?/is);
		my $ckproduct_id = &DBIL::UpdateProducthasTag($pid, $product_object_key, $dbh,$robotname,$retailer_id);
		goto LAST if($ckproduct_id == 1);
		undef ($ckproduct_id);
		#product_name
		if($content2=~m/Product_Name\=\"([^<]*?)\"/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		#Brand
		if($content2=~m/product_brand\s*\:\s*\[\"([\w\W]*?)\"\]?/is)
		{
			$brand = &DBIL::Trim($1);			
		}
		#description&details
		if($content2=~m/<meta\s*name\=\"description\"\s*content\=[\'\"]([^<]*?)[\'\"]/is)
		{
			$description = &DBIL::Trim($1);
			$description=decode_entities($description);
		}
		if($content2=~m/<div\s*class\=\"details\">([\w\W]*?)<\/p>\s*<p[^<]*?>\s*<a[^<]*?>/is)
		{
			$prod_detail = &DBIL::Trim($1);
			$prod_detail=decode_entities($prod_detail);
		}
		#colour		
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		if ($content2=~m/Select\s*a\s*color([\w\W]*?)<\/fieldset>/is)
		{
			my $colour_content = $1;
			
			while($colour_content=~m/<li\s*id\=\"color([^<]*?)\"[^<]*?>\s*<[^<]*?title\=\"([^<]*?)\"/igs)
			{		
				my $color_code=$1;
				my $color=&DBIL::Trim($2);
				
				$color_hash{$color_code} = &DBIL::Trim($color);
			}
		}
		elsif($content2=~m/currently\s*sold\s*out/is)
		{
			my $out_of_stock = 'y';
		
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"","",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}='No colour';
			push(@query_string,$query);
		}
		#size type
		my $sku=$1 if($url3=~m/skuId\=([^<]*?)$/is);
		
		if($content2=~m/SizeType\-([^<]*?)\"\s*name[^<]*?value\=\"([^<]*?)\"/is)
		{
			while($content2=~m/SizeType\-([^<]*?)\"\s*name[^<]*?value\=\"([^<]*?)\"/igs)
			{
				my $size_type=$1;
				my $sku=&DBIL::Trim($2);
				
				$sku_hash{$size_type} = &DBIL::Trim($sku);
			}
		}
		else
		{
			my $product_id = &DBIL::Trim($1) if($content2=~m/productId\:\s*\"([^<]*?)"/is);
				
			my @color_code = keys %color_hash;
			foreach my $code (@color_code)
			{
				my $size_content=$1 if($content2=~m/selectSize\">([\w\W]*?)<\/fieldset>/is);
							
				my $size_url="http://www.loft.com/catalog/skuSize.jsp?prodId=".$product_id."&colorCode=".$code."&sizeCode=&imageId=productImage&skuId=".$sku."&productPageType=&colorExplode=false";
							
				my $size_type_cont = get_content($size_url);
							
				while($size_content=~m/class\=\"size([^<]*?)\"/igs)
				{
					my $size = &DBIL::Trim($1);
					
					my $out_of_stock;
					if($size_type_cont=~m/size$size\s*disable/is)
					{
						$out_of_stock = 'y';						
					}
					else
					{
						$out_of_stock = 'n';						
					}
					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color_hash{$code};
					push(@query_string,$query);
				}
				if($size_content!~m/class\=\"size([^<]*?)\"/is)
				{
					my $out_of_stock;	
					if($content2=~m/currently\s*sold\s*out/is)
					{
						$out_of_stock = 'y';
					}
					else
					{
						$out_of_stock = 'n';
					}						
					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"",$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color_hash{$code};
					push(@query_string,$query);
				}								
			}		
		}
		# size & size type & out_of_stock		
		my @size_type = keys %sku_hash;
		foreach my $type (@size_type)
		{
			my $size_url1="http://www.loft.com/catalog/skuSize.jsp?prodId=".$sku_hash{$type}."&skuId=".$sku."&productPageType=";						
			my $size_content = get_content($size_url1);
			
			my $skuColor_url="http://www.loft.com/catalog/skuColor.jsp?prodId=".$sku_hash{$type}."&imageId=productImage&skuId=".$sku."&productPageType=&colorExplode=false";
			my $skuColor_cont = get_content($skuColor_url);
			
			while($skuColor_cont=~m/<li\s*id\=\"color([^<]*?)\"[^<]*?>\s*<a[^<]*?title\=\"([^<]*?)\"/igs)
			{
				my $code=$1;
				my $skuColor=&DBIL::Trim($2);
				
				my $size_url="http://www.loft.com/catalog/skuSize.jsp?prodId=".$sku_hash{$type}."&colorCode=".$code."&sizeCode=&imageId=productImage&skuId=".$sku."&productPageType=&colorExplode=false";				
				
				my $size_type_cont = get_content($size_url);
				
				while($size_content=~m/class\=\"size([^<]*?)\"/igs)
				{
					my $size = &DBIL::Trim($1);
									
					my $out_of_stock;
					if($size_type_cont=~m/size$size\s*disable/is)
					{
						$out_of_stock = 'y';							
					}
					else
					{
						$out_of_stock = 'n';						
					}
					
					$size=ucfirst($type)." ".$size;
					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$skuColor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$skuColor;
					push(@query_string,$query);
				}
				if($size_content!~m/class\=\"size([^<]*?)\"/is)
				{
					my $out_of_stock;
					if($content2=~m/currently\s*sold\s*out/is)
					{
						$out_of_stock = 'y';
					}
					else
					{
						$out_of_stock = 'n';
					}					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"",$skuColor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$skuColor;
					push(@query_string,$query);
				}				
			}			
		}
		
		#Getting Profile ID & Item ID
		my ($profileid,$itemid,$direct_swatch,$product_image);
		if($content2=~m/productImage\"\s*src\=\"([^<]*?)\"/is)
		{
			$product_image=$1;
		}
		elsif($content2=~m/Product_Image_URL\=\"([^<]*?)\"/is)
		{
			$product_image=$1;
		}
		
		if($product_image=~m/profileId\=([^<]*?)\&itemID\=([^<]*?)\&swatchID\=([^<]*?)\&/is)
		{
			$profileid=$1;
			$itemid=$2;
			$direct_swatch=$3;
		}		
	
		#Images
		my @swatch;
		my $image_count=0;
		foreach my $type (@size_type)
		{
			my $skuColor_url="http://www.loft.com/catalog/skuColor.jsp?prodId=".$sku_hash{$type}."&imageId=productImage&skuId=".$sku."&productPageType=&colorExplode=false";
			my $image_content = get_content($skuColor_url);
			
			# Swatch image.
			while($image_content=~m/productImage\$_\$\s*([^<]*?)\$_\$\s*([^<]*?)\$/igs)
			{
				my $swatchid=$1;
				my $swatch_color=$2;
				
				my $swatch_url="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid."&swatchid=".$swatchid."&viewerid=274&callback=productXmlCallbackImagePanZoomprofileid".$profileid."itemid".$itemid."swatchid".$swatchid;
				
				my $swatch_cont=get_content($swatch_url);
				
				if($swatch_cont=~m/swatches\"\:\s*\[\s*\{\s*[^<]*?\@path\"\:\s*\"([^<]*?)\"/is)
				{
					my $swatch=$1;
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
									
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
					$image_objectkey{$img_object}=$swatch_color;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);					
				}
			}
			
			# Product image.
			while($image_content=~m/productImage\$_\$\s*([^<]*?)\$_\$\s*([^<]*?)\$/igs)
			{
				my $swatchid=$1;
				my $product_color=$2;
				
				my $alt_url="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid."&swatchid=".$swatchid."&viewerid=274&callback=productXmlCallbackImagePanZoomprofileid".$profileid."itemid".$itemid."swatchid".$swatchid;
				
				my $alt_cont=get_content($alt_url);	
				
				my $count=1;
				my (@alt_image_array,@unique);
				while($alt_cont=~m/initial\"\,\s*\"\@path\"\:\s*\"([^<]*?)\"/igs)
				{
					my $alt_image=$1;
					
					$alt_image=~s/recipeId\=160/recipeId=230/igs;

					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					
					#Direct Images
					if($count == 1)
					{				
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_color;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						push(@alt_image_array,$alt_image);						
					}
					
					$count++;
				}
				#Other Images
				my %seen;
				@unique = grep { ! $seen{$_} ++ } @alt_image_array;
				
				foreach my $alt_image1 (@unique)
				{
					$alt_image1=~s/recipeId\=160/recipeId=230/igs;
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image1,'product',$retailer_name);
				
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_color;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				
				push(@swatch,$swatchid);
			}
			
			$image_count++;
		}
		
		if($image_count == 0)
		{
			if($content2=~m/Select\s*a\s*color([\w\W]*?)<\/fieldset>/is)
			{
				my $image_content = $1;
				
				# Swatch image.
				while($image_content=~m/productImage\$_\$\s*([^<]*?)\$_\$\s*([^<]*?)\$/igs)
				{
					my $swatchid=$1;
					my $swatch_color=$2;
					
					my $swatch_url="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid."&swatchid=".$swatchid."&viewerid=274&callback=productXmlCallbackImagePanZoomprofileid".$profileid."itemid".$itemid."swatchid".$swatchid;
					
					my $swatch_cont=get_content($swatch_url);
					
					if($swatch_cont=~m/swatches\"\:\s*\[\s*\{\s*[^<]*?\@path\"\:\s*\"([^<]*?)\"/is)
					{
						my $swatch=$1;
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
										
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
						$image_objectkey{$img_object}=$swatch_color;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);					
					}
				}
				
				# Product image.
				while($image_content=~m/productImage\$_\$\s*([^<]*?)\$_\$\s*([^<]*?)\$/igs)
				{
					my $swatchid=$1;
					my $product_color=$2;
					
					my $alt_url="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid."&swatchid=".$swatchid."&viewerid=274&callback=productXmlCallbackImagePanZoomprofileid".$profileid."itemid".$itemid."swatchid".$swatchid;
					
					my $alt_cont=get_content($alt_url);	
					
					my $count=1;
					my (@alt_image_array,@unique);
					while($alt_cont=~m/initial\"\,\s*\"\@path\"\:\s*\"([^<]*?)\"/igs)
					{
						my $alt_image=$1;
						
						$alt_image=~s/recipeId\=160/recipeId=230/igs;

						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						
						#Direct Images
						if($count == 1)
						{				
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$product_color;
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						else
						{
							push(@alt_image_array,$alt_image);						
						}
						
						$count++;
					}
					#Other Images
					my %seen;
					@unique = grep { ! $seen{$_} ++ } @alt_image_array;
					
					foreach my $alt_image1 (@unique)
					{
						$alt_image1=~s/recipeId\=160/recipeId=230/igs;
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image1,'product',$retailer_name);
					
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_color;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					
					push(@swatch,$swatchid);
				}
				if($image_content!~m/productImage\$_\$\s*([^<]*?)\$/is)
				{
					my $alt_url="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid."&swatchid=".$direct_swatch."&viewerid=274&callback=productXmlCallbackImagePanZoomprofileid".$profileid."itemid".$itemid."swatchid".$direct_swatch;
					
					my $alt_cont=get_content($alt_url);				
					
					my $count1=1;
					my (@alt_image_array,@unique);	
					while($alt_cont=~m/initial\"\,\s*\"\@path\"\:\s*\"([^<]*?)\"/igs)
					{
						my $alt_image=$1;
						
						$alt_image=~s/recipeId\=160/recipeId=230/igs;
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);

						#Direct Images
						if($count1 == 1)
						{
							my ($img_object,$flag,,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}='No colour';
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						else
						{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}='No colour';
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);						
							
						}
						$count1++;
					}
				}
			
				unless(grep( /^$direct_swatch$/, @swatch ))
				{
					my $alt="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid."&swatchid=".$direct_swatch."&viewerid=274&callback=productXmlCallbackImagePanZoomprofileid".$profileid."itemid".$itemid."swatchid".$direct_swatch;
					
					my $alt_cont=get_content($alt);
					
					my $did;
					my $dcount=0;
					
					while($alt_cont=~m/name\"\:\s*\"([^<]*?)\"[\w\W]*?initial\"\,\s*\"\@path\"\:\s*\"([^<]*?)\"/igs)
					{
						my $name=$1;
						my $alt_image=$2;
						
						$alt_image=~s/recipeId\=160/recipeId=230/igs;
				
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						
						if($name eq "default")
						{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}='No colour';
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
							if($alt_image=~m/&id\=([^<]*?)\&/is)
							{
								$did=$1;
							}
							
							$dcount++;
						}
						else
						{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}='No colour';
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
							$dcount++;					
						}
					}
					if($dcount <= 1)
					{				
						my $alt1="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid;
						
						my $alt_cont1=get_content($alt1);
						
						my (@alt_image_array1,@unique1);			
						while($alt_cont1=~m/path\=\"([^<]*?)\"/igs)
						{
							my $missed=&DBIL::Trim($1);
							
							my $temp_id=$1 if($missed=~m/id\=([\d]*?)$/is);
							
							if($temp_id eq $did)
							{
								next;
							}
							else
							{
								my $alt_image1=$missed."&recipeId=230";
								
								push(@alt_image_array1,$alt_image1);					
								
							}
						}
						my %seens;
						@unique1 = grep { ! $seens{$_} ++ } @alt_image_array1;
						
						foreach my $alt_image1 (@unique1)
						{						
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image1,'product',$retailer_name);
							
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}='No colour';
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
					}
				}
			}
			else
			{
				my $alt="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid."&swatchid=".$direct_swatch."&viewerid=274&callback=productXmlCallbackImagePanZoomprofileid".$profileid."itemid".$itemid."swatchid".$direct_swatch;
					
				my $alt_cont=get_content($alt);
				
				my $did;
				my $dcount=0;
				
				while($alt_cont=~m/name\"\:\s*\"([^<]*?)\"[\w\W]*?initial\"\,\s*\"\@path\"\:\s*\"([^<]*?)\"/igs)
				{
					my $name=$1;
					my $alt_image=$2;
					
					$alt_image=~s/recipeId\=160/recipeId=230/igs;
			
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);				
					
					if($name eq "default")
					{
						my ($img_object,$flag, $query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No colour';
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
						if($alt_image=~m/&id\=([^<]*?)\&/is)
						{
							$did=$1;
						}
						
						$dcount++;
					}
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No colour';
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
						$dcount++;
					}
				}
				if($dcount <= 1)
				{
					my $alt1="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=".$profileid."&itemid=".$itemid;
					
					my $alt_cont1=get_content($alt1);
					
					my (@alt_image_array1,@unique1);			
					while($alt_cont1=~m/path\=\"([^<]*?)\"/igs)
					{
						my $missed=&DBIL::Trim($1);
						
						my $temp_id=$1 if($missed=~m/id\=([\d]*?)$/is);
						
						if($temp_id eq $did)
						{
							next;
						}
						else
						{
							my $alt_image1=$missed."&recipeId=230";
							
							push(@alt_image_array1,$alt_image1);					
							
						}
					}
					my %seens;			
					@unique1 = grep { ! $seens{$_} ++ } @alt_image_array1;
					
					foreach my $alt_image1 (@unique1)
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image1,'product',$retailer_name);
							
						my ($img_object,$flag, $query) = &DBIL::SaveImage($imgid,$alt_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No colour';
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$pid,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);	
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);		
		LAST:
		print " ";
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
			goto Home;
		}
	}
	return $content;
}