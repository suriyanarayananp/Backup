#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Jcrew_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Jcrew_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	
	####Variable Initialization##############
	$robotname='Jcrew-US--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Jcr';
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
	$ua->proxy(['http', 'https', 'ftp'] => $ENV{HTTP_proxy});
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
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		my $content2 = &get_content($url3);
		my @query_string;	
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$product_id,$product_name,$description,$prod_detail);
	
		#product ID	
		if($url3=~m/\~\s*([^>]*?)\s*\//is)
		{
			$product_id=$1;
			$product_id =~ s/^\s+|\s+$//igs;

			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);	
		}
		elsif($url3=~m/\=\s*([^>]*?)\s*\-/is)
		{
			$product_id=$1;
			
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#description&details
		if($content2=~m/Product\s*Details(\s*[\w\W]*?\s*<\/div>)\s*<\/div>/is)
		{
			my $desc_content=$1;
			
			if($desc_content=~m/<\/div>\s*([\w\W]*?)\s*<ul>/is)
			{
				$description=&DBIL::Trim($1);
				$description=~s/\&ndash\;/-/igs;
				$description=decode_entities($description);
			}
			if($desc_content=~m/<ul>\s*<li>\s*([\w\W]*?)\s*<\/div>/is)
			{
				$prod_detail=&DBIL::Trim($1);
				$prod_detail=~s/\&ndash\;/-/igs;
				$prod_detail=decode_entities($prod_detail);
			}
		}		
		
		#colour
		my $url_2;
		if($url3=~m/Sale\=true/is)
		{
			$url_2="http://www.jcrew.com/browse2/ajax/product_details_ajax.jsp?sRequestedURL=$url3&isFiftyOneContext=false&isProdSellable=true&bRestrictedProduct=false&isIgnoreOutOfStock=false&prodCode=$product_id&color_name=&nav_type=PRMNAV&imgPersonalShopperWedding=/media/images/productDetail/pscallout_wedding_v2_m56577569830829636.gif&imgPersonalShopperMen=/media/images/productDetail/pscallout_men_v2_m56577569832078069.gif&imgSkuCode=&imgPersonalShopperKids=/media/images/productDetail/pscallout_kids_v2_m56577569831381103.gif&imgPersonalShopperWomen=/media/images/productDetail/pscallout_women_v2_m56577569832078070.gif&addToBagLabel=add+to+bag&updateBagLabel=update+bag&outOfStockLabel=Out+Of+Stock&isPriceBook=false&index=0&isSaleItem=true&_=";
		}
		else
		{
			$url_2="http://www.jcrew.com/browse2/ajax/product_details_ajax.jsp?sRequestedURL=$url3&isFiftyOneContext=false&isProdSellable=true&bRestrictedProduct=false&isIgnoreOutOfStock=false&prodCode=$product_id&color_name=&nav_type=PRMNAV&imgPersonalShopperWedding=/media/images/productDetail/pscallout_wedding_v2_m56577569830829636.gif&imgPersonalShopperMen=/media/images/productDetail/pscallout_men_v2_m56577569832078069.gif&imgSkuCode=&imgPersonalShopperKids=/media/images/productDetail/pscallout_kids_v2_m56577569831381103.gif&imgPersonalShopperWomen=/media/images/productDetail/pscallout_women_v2_m56577569832078070.gif&addToBagLabel=add+to+bag&updateBagLabel=update+bag&outOfStockLabel=Out+Of+Stock&isPriceBook=false&index=0&isSaleItem=&_=";
		}
		
		my $content90 = get_content($url_2);
		
		#price
		if($content90=~m/<div\s*class\s*\=\s*\"\s*product\-pricing\-wrapper\s*\">\s*(?:<span[^<]*?full-price[^<]*?>)\s*([\w\W]*?)\s*<\/div>/is)
		{
			$price_text=$1;
			$price_text=~s/<[^>]*?>//igs;
			$price_text=~s/\s+/ /igs;
			$price_text=~s/\&ndash\;/-/igs;
		
			if($price_text=~m/(now)/is)
			{
				$price=$';
				$price=~s/\$//igs;
				$price=~s/\s*//igs;
				$price=~s/INR//igs;
				$price=~s/\,//igs;
			}
			elsif($price_text=~m/(?:\$|INR|EUR|USD)/is)
			{
				$price=$';
				$price=~s/\s*//igs;
				$price=~s/\,//igs;
			}
			elsif($price_text=~m/<span\s*>\s*([^<]*?)\s*$/is)
			{
				$price=$1;
				$price=~s/\$//igs;
				$price=~s/\s*//igs;
				$price=~s/INR//igs;
				$price=~s/USD//igs;
				$price=~s/EUR//igs;
				$price=~s/\,//igs;
			}			
		}
		elsif($content90=~m/<div\s*class\s*\=\s*\"full\s*\-\s*price\">\s*([\w\W]*?)\s*<\/span>\s*(?:<\/div>|<div\s*class)/is)
		{
			$price_text=$1;
			$price_text=~s/<[^>]*?>//igs;
			$price_text=~s/\s+/ /igs;
			$price_text=~s/\&ndash\;/-/igs;
			
			if($price_text=~m/(now)/is)
			{
				$price=$';
				$price=~s/\$//igs;
				$price=~s/\s*//igs;
				$price=~s/INR//igs;
				$price=~s/\,//igs;
			}
			elsif($price_text=~m/(?:\$|INR|EUR|USD)/is)
			{
				$price=$';
				$price=~s/\s*//igs;
				$price=~s/\,//igs;
			}
			elsif($price_text=~m/<span\s*>\s*([^<]*?)\s*$/is)
			{
				$price=$1;
				$price=~s/\$//igs;
				$price=~s/\s*//igs;
				$price=~s/INR//igs;
				$price=~s/USD//igs;
				$price=~s/EUR//igs;
				$price=~s/\,//igs;
			}
		}		
		#product_name
		if ( $content90 =~ m/<h1>\s*([\w\W]*?)\s*<\/h1>/is )
		{
			$product_name = $1;
			$product_name=~s/&reg\;/®/igs;
			$product_name=~s/\&eacute\;/é/is;
			$product_name=~s/\&egrave\;/é/is;
			$product_name=~s/\&trade\;/™/igs;
			$product_name=~s/<[^>]*?>/ /igs;
			$product_name=~s/^\s+|\s+$//igs;
			$product_name=~s/\s+/ /igs;
		}
		
		#If product is available without description and product detail, set prod_detail eq '-'.
		if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
			$prod_detail = '-';
		}
		
		##color
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my $Total_size;
		my @Total_size1;
		if($content90=~m/<h2>\s*Size\s*\:\s*([\w\W]*?)\s*<\/section>/is)
		{
			my $sample_Size=$1;
			while($sample_Size=~m/data\s*\-\s*size\s*\=\s*\"\s*([^>]*?)\s*\"/igs)
			{
				$Total_size=lc($1);
				push(@Total_size1,$Total_size);
			}
		}
		######Size Type##
		my $type=$1 if($content90=~m/data-variant\=\"$product_id\"[^<]*?>\s*<\/div>\s*<div[^<]*?>\s*<span>\s*([^<]*?)\s*</is);
		####Select Colour##########
		if($content90=~m/<div\s*class\=\"product-detail-price[^<]*?>\s*([^<]*?)\s*<\/div>\s*<section[^<]*?>([\w\W]*?)<\/section>/is)
		{
			while($content90=~m/<div\s*class\=\"product-detail-price[^<]*?>\s*([^<]*?)\s*<\/div>\s*<section[^<]*?>([\w\W]*?)<\/section>/igs)
			{
				my $colour_price = $1;
				my $colour_content = $2;
				
				$colour_price=~s/\$//igs;
				$colour_price=~s/\,//igs;
				$colour_price=~s/\s*//igs;
				$colour_price=~s/INR//igs;
				$colour_price=~s/USD//igs;
				$colour_price=~s/EUR//igs;
				
				while($colour_content=~m/<a\s*id\=\"([^<]*?)\"/igs)
				{
					my $price_color_code 	= &DBIL::Trim($1);				
					$color_hash{$price_color_code} = &DBIL::Trim($colour_price);
				}
			}
			######Sku########
			my $colour_count=2;
			my (@dup_color,@all_color);
			
			my @color_code= keys %color_hash;
			foreach my $code(@color_code)
			{
				while($content90=~m/\{\"sizes\"\s*([\w\W]*?)\s*\}\]\s*\,\"color\"\s*\:\"([^>]*?)\"[^<]*?\s*colordisplayname\"\:\"\s*([^>]*?)\s*\"/igs)
				{
					my $ajax_size_content=$1;
					my $color_code=$2;
					my $color=$3;
					
					if($color_code eq $code)
					{
						####Duplicate Colour######
						unless(grep(/^$color$/,@dup_color))
						{
							$colour_count=2;
						}
						if(grep( /^$color$/, @all_color ))
						{
							push(@dup_color,$color);
							$color=$color." ($colour_count)";
							$colour_count++;
						}
						
						push(@all_color,$color);
						
						my @size_in_stock;
						while($ajax_size_content=~m/sizelabel\s*\"\:\s*\"\s*([^>]*?)\s*\"/igs)
						{
							my $size=lc($1);
							
							$size=~s/\\//igs;
							
							push(@size_in_stock,$size);
							
							my $out_of_stock='n';
							
							if($type ne '')
							{
								my $sizetype;
								if($size!~m/$type/is)
								{
									$sizetype=$type." ".$size;
								}
								else
								{																
									$sizetype=$size;
								}
								
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$color_hash{$code},$price_text,$sizetype,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color_code;
								push(@query_string,$query);	
							}
							else
							{							
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$color_hash{$code},$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color_code;
								push(@query_string,$query);	
							}							
						}
						foreach my $size (@Total_size1)
						{
							$size=~s/\\//igs;
							
							if(grep( /^$size$/, @size_in_stock ))
							{
								goto next;
							}
							else
							{
								my $out_of_stock='y';
								
								if($type ne '')
								{
									my $sizetype;									
									if($size!~m/$type/is)
									{
										$sizetype=$type." ".$size;
									}
									else
									{																
										$sizetype=$size;
									}
									
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$color_hash{$code},$price_text,$sizetype,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color_code;
									push(@query_string,$query);	
								}
								else
								{
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$color_hash{$code},$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color_code;
									push(@query_string,$query);	
								}	
							}
						}
					}				
				}
			}
		}
		else
		{
			my $colour_count=2;
			my (@dup_color,@all_color);
			
			######Sku########
			while($content90=~m/\{\"sizes\"\s*([\w\W]*?)\s*\}\]\s*\,\"color\"\s*\:\"([^>]*?)\"[^<]*?\s*colordisplayname\"\:\"\s*([^>]*?)\s*\"/igs)
			{
				my $ajax_size_content=$1;
				my $color_code=$2;
				my $color=$3;
				
				####Duplicate Colour######
				unless(grep(/^$color$/,@dup_color))
				{
					$colour_count=2;
				}
				if(grep( /^$color$/, @all_color ))
				{
					push(@dup_color,$color);
					$color=$color." ($colour_count)";
					$colour_count++;
				}
				
				push(@all_color,$color);
				
				my @size_in_stock;
				while($ajax_size_content=~m/sizelabel\s*\"\:\s*\"\s*([^>]*?)\s*\"/igs)
				{
					my $size=lc($1);
					
					$size=~s/\\//igs;
					
					push(@size_in_stock,$size);
					
					my $out_of_stock='n';
					
					if($type ne '')
					{
						my $sizetype;
						if($size!~m/$type/is)
						{
							$sizetype=$type." ".$size;
						}
						else
						{																
							$sizetype=$size;
						}
						
						$price='null' if($price eq '');
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$sizetype,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color_code;
						push(@query_string,$query);	
					}
					else
					{
						$price='null' if($price eq '');
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color_code;
						push(@query_string,$query);	
					}
				}
				foreach my $size (@Total_size1)
				{
					$size=~s/\\//igs;
					
					if(grep( /^$size$/, @size_in_stock ))
					{
						goto next;
					}
					else
					{
						my $out_of_stock='y';
						
						if($type ne '')
						{
							my $sizetype;
							if($size!~m/$type/is)
							{
								$sizetype=$type." ".$size;
							}
							else
							{																
								$sizetype=$size;
							}

							$price='null' if($price eq '');	
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$sizetype,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color_code;
							push(@query_string,$query);	
						}
						else
						{
							$price='null' if($price eq '');
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color_code;
							push(@query_string,$query);	
						}
					}				
				}
			}
		}
		
		#Swatch_image
		if($content90=~m/<div\s*class\s*\=\s*\"color\s*\-\s*box\s*selected\"\s*[^>]*?\s*>\s*<a\s*id\s*\=\s*\"\s*([^>]*?)\s*\">\s*<img\s*[^>]*?\s*src\s*\=\s*\"([^>]*?)\"/is)
		{
			my $swatch_color=$1;
			my $swatch=$2;
			
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
			$image_objectkey{$img_object}=$swatch_color;
			$hash_default_image{$img_object}='n';	
			push(@query_string,$query);			
		}
		while($content90=~m/<div\s*class\s*\=\s*\"color\s*\-\s*box\s*\"\s*[^>]*?\s*>\s*<a\s*id\s*\=\s*\"\s*([^>]*?)\s*\">\s*<img\s*[^>]*?\s*src\s*\=\s*\"([^>]*?)\"/igs)
		{
			my $swatch_color=$1;
			my $swatch=$2;
			
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
			$image_objectkey{$img_object}=$swatch_color;
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
		}
		
		##product_image - Direct
		my ($direct_image,$direct_color);
		my $dflag=0;
		if($content2=~m/class\s*\=\s*\"\s*prod\-main\-img\"\s*src\s*\=\s*\"\s*([^>]*?)\s*\"/is)
		{
			my $alt_image=$1;
			
			my $alt_color=$1 if($alt_image=~m/_([^<]*?)(?:_|\?)/is);
			
			$direct_image=$alt_image;
			$direct_color=$alt_color;
			
			my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
			
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$alt_color;
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);
			$dflag++;
		}
		while($content90=~m/<img\s*data-imgurl\=[\"\']([^<]*?)[\"\']/igs)
		{
			my $alt_image=$1;
			
			my $alt_color=$1 if($alt_image=~m/_([^<]*?)(?:_|\?)/is);
			
			if($alt_image ne $direct_image)
			{			
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$alt_color;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
			}
			elsif($dflag == 0)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$alt_color;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
			}
		}
		
		#product_image - Alternative
		while($content2=~m/class\s*\=\s*\"product\-detail\-images\s*\"\s*src\s*\=\s*\"\s*[^>]*?\s*\"\s*data\-imgurl\=\"([^<]*?)\"/igs)
		{
			my $alt_image=$1;
			
			my $alt_color=$1 if($alt_image=~m/_([^<]*?)(?:_|\?)/is);
			
			if($alt_image ne $direct_image)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
			
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$alt_color;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
			elsif($dflag == 0)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$alt_color;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
			}
		}
		###Product - Out of Stock###########		
		if($content90=~m/has\s*sold\s*out/is)
		{
			my $out_of_stock='y';
			
			$price='null' if($price eq '');
			
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"","",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$direct_color;
			push(@query_string,$query);
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,"",$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		# push(@query_string,$query);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
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