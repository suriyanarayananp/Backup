#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Kmart_US;
# package DBIL;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
#require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Kmart_US_DetailProcess()
{	
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Kmart-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Kma';
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
	my $Home_url="http://www.kmart.com/shc/s/dap_10151_10104_DAP_Shop+Internationally+with+Sears?countryCd=US";
	getcont($Home_url);
	my $skuflag = 0;
	my $imageflag = 0;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		my @query_string;
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;my %sku_objectkey;my %image_objectkey;my %hash_default_image;my $mflag=0;my $price_flag=0;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$size);my %colors;
		
		#product_id
		
		$url3=$url3.'?PDP_REDIRECT=false';
		
		if($url3=~m/\/p\-([^<]+?)\?/is)
		{
			$product_id=$1;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
		}
		
		my $content2=&getcont($url3);
		
		# Multi product
		if($product_id=~m/B$/is)
		{
			$product_name=&trim($1.$2) if ($content2=~m/<div\s*class\=\"bHeading\">\s*([^<]*?)\s*<\/div>|<(?:h1|span)\s*itemprop\=\"name\"[^<]*?>([\w\W]*?)<\/(?:h1|span)>/is);
			$product_name=~s/\\//igs;
			$product_name=~s/Â//igs;
			#Description
			my ($desc1,$desc2);
			$desc1=$1 if($content2=~m/<div[^<]*?description\"[^<]*?>([\w\W]*?)</is);
			$desc2=$1 if($content2=~m/<div[^<]class\=\"specs[^<]*?>([\w\W]*?)<\/p>/is);
			$description=&trim($desc1).' '.&trim($desc2);
			$description=~s/Â//igs;
			$prod_detail=&trim($1) if($content2=~m/<div\s*id\=\"specifications\"\s*class\=\"prodTabsContent\">([\w\W]*?)<\/div>/is);
			#brand
			if($content2=~m/prodBrand\s*=\s*[\'|\"]([^(?:\'|\")?]*?)\s*[\'|\"]/is)
			{
				$brand=$1;
				decode_entities($brand);
				$brand=~s/\\//igs;
				if ($brand ne '')
				{
					&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				}
			}
			$mflag=1;
			goto PNF;
		}
		
		#product_name
		if ( $content2 =~m/<h1\s*itemprop\=\"name\">\s*([^<]*?)\s*</is )
		{
			$product_name = trim($1);
			decode_entities($product_name);
		}
			
		#Brand
		if ( $content2 =~m/ProdBrand\s*\=\s*\"([^\"]*?)\"\;/is )
		{
			$brand = trim($1);
			decode_entities($brand);
		}
		
		#Description 
		if ( $content2 =~m/<a\s*id\=\"descriptionAnchor\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
		{
			$description = $1;
			$description=~s/<script\s*type\=\"text\/javascript\">[^<]*?<\/script>//igs;
			$description = trim($description);
			decode_entities($description);
		}
		elsif ( $content2 =~m/>\s*Product\s*Description\s*([\w\W]*?)\s*<\/p>\s*<\/p>/is )
		{
			$description = $1;
			$description=~s/<script\s*type\=\"text\/javascript\">[^<]*?<\/script>//igs;
			$description = trim($description);
			decode_entities($description);
		}
		else
		{
			$description=" ";
		}
		
		# Product_Detail
		if ( $content2 =~m/<h4>\s*Specifications\s*\&\s*Dimensions\s*<\/h4>\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
		{
			$prod_detail = trim($1);
			decode_entities($prod_detail);
		}
		if ( $content2 =~m/<div\s*class\=\"JsonPageView\">\s*<script>\s*var\s*js_savestory_[^<]*?\=\'([\w\W]*?)\'\s*<\/script>\s*<\/div>/is )
		{
			$price_text = trim($1);
			decode_entities($price_text);
		}
		elsif( $content2 =~m/\[\"<div\s*class\=\'origPrice\'><span\s*class\=\'text\'>\s*([\w\W]*?)\s*<\/div>\"\]/is )
		{
			$price_text = trim($1);
			decode_entities($price_text);
		}
		elsif( $content2 =~m/<span\s*class\=\"(?:regPrice|pricing)\"\s*itemprop\=\"price\">\s*([^<]*?)\s*<\/span>/is )
		{
			$price_text = trim($1);
			decode_entities($price_text);
		}
		elsif( $content2 =~m/<span\s*class\=\"salePrice\"\s*itemprop\=\"price\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>\s*<\/div>/is )
		{
			$price_text = $1;
			$price_text=~s/<script[^<]*?>[^<]*?<\/script>//igs;
			$price_text = trim($price_text);
			decode_entities($price_text);
		}
		elsif( $content2 =~m/<div\s*class\=\"origPrice\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
		{
			$price_text = trim($1);
			decode_entities($price_text);
		}
		if($content2=~m/<input\s*type\=\"hidden\"\s*id\=\"currPrice\"\s*value\=\"([^\"]*?)\"\/>/is)
		{
			$price=$1;
			if($price!~m/\-/is)
			{
				$price_flag=1;
			}
			else
			{
				$price_flag=0;
				undef $price;
			}
		}
		
		#Sku Information - Json Type
		my $no_color_flag=0;my %duplicate_color;
		if( $content2=~m/jsonText\s*\=\{([\w\W]*?)Pd\.prod\s*\=/is)
		{
			my $json_block=$1;
			my (@attr_array,%hash);
			if($json_block =~m/\"attNames\"\:\[([^>]*?)]/is)
			{
				my $attname = $1;
				$attname =~ s/\"//igs;
				$attname =~ s/\s+$|^\s+//igs;
				@attr_array = split /\,/, $attname;
			}
			for(my $i = 0; $i<@attr_array; $i++)
			{
				my $att_type=$attr_array[$i];
				$hash{$i}=$att_type;
			}
			while($json_block=~m/(\"varName\"\:\s*[^<]*?\}\])/igs)
			{
				my $sku_main_block=$1;
				if($sku_main_block=~m/\"varName\"\:\"([^\"]*?)\"\,\"fitDisplayName\"\:\"([^\"]*?)\"([^<]+)/is)
				{
					while($sku_main_block=~m/\"varName\"\:\"([^\"]*?)\"\,\"fitDisplayName\"\:\"([^\"]*?)\"([^<]+)/igs)
					{
						my $size2_value=$1;
						my $size2_name=$2;
						my $sku_block=$3;
						while($sku_block=~m/\{\"pId\"([^<]*?)\}/igs)
						{
							my $sku_detail=$1;
							my $out_of_stock='n';
							if($price_flag==0)
							{
								if($sku_detail=~m/\"price\s*\"\s*\:\s*([^<]*?)\s*\,/is)
								{
									$price=$1;
								}
							}
							if($sku_detail=~m/\"aVals\s*\"\s*\:\s*\[([^<]*?)\]/is)
							{
								my $block=$1;
								$block =~ s/\"//igs;
								my $final_size;my $final_color;
								foreach my $key(keys %hash)
								{
									my $size;my $colour;
									if($hash{$key}=~m/colour|color/is)
									{
										$colour =(split(',',$block))[$key];
										$colour =~ s/\s+$|^\s+//igs;
									}
									else
									{
										my $size_val=(split(',',$block))[$key];
										$size_val =~ s/\s+$|^\s+//igs;
										if($hash{$key} eq 'Size')
										{
											$size.=$hash{$key}.': '.$size_val;
										}
										else
										{
											$size.=$hash{$key}.': '.$size_val;
										}
									}
									$final_color=$colour if($colour ne '') ;	
									$final_size.=$size.',';
								}
								$final_size=$size2_name.': '.$size2_value.', '.$final_size;
								$final_size=~s/\s+$|^\s+//igs;$final_size=~s/\,+/\,/igs;$final_size=~s/\,$|^\,//igs;$final_size=~s/\,\s+\,/\,/igs;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								
								$final_color='no raw color' if($final_color eq '');
								my $duplicate_check=$final_color.$final_size;
								$duplicate_check=~s/\W//igs;
								if($duplicate_color{$duplicate_check} eq '')
								{
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$final_color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$final_color;
									$colors{$final_color}=1;
									$duplicate_color{$duplicate_check}=1;
									push(@query_string,$query);
									
									# print "\nName1 :: $product_name\n";
									# print "\nPrice :: $price\n";
									# print "\nPrice Text :: $price_text\n";
									# print "\nSize :: $final_size\n";
									# print "\nColour :: $final_color\n";
									# print "\nout_of_stock :: $out_of_stock\n";
								}	
							}
						}
					}
				}
				else
				{
					while($sku_main_block=~m/\{\"pId\"([^<]*?)\}/igs)
					{
						my $sku_detail=$1;
						my $out_of_stock='n';
						if($price_flag==0)
						{
							if($sku_detail=~m/\"price\s*\"\s*\:\s*([^<]*?)\s*\,/is)
							{
								$price=$1;
							}
						}
						if($sku_detail=~m/\"aVals\s*\"\s*\:\s*\[([^<]*?)\]/is)
						{
							my $block=$1;
							$block =~ s/\"//igs;
							my $final_size;my $final_color;
							foreach my $key(keys %hash)
							{
								my $size;my $colour;
								if($hash{$key}=~m/colour|color/is)
								{
									$colour =(split(',',$block))[$key];
									$colour =~ s/\s+$|^\s+//igs;
								}
								else
								{
									my $size_val=(split(',',$block))[$key];
									$size_val =~ s/\s+$|^\s+//igs;
									if($hash{$key} eq 'Size')
									{
										$size.=$hash{$key}.': '.$size_val;
									}
									else
									{
										$size.=$hash{$key}.': '.$size_val;
									}
								}
								$final_color=$colour if($colour ne '') ;	
								$final_size.=$size.',';
							}
							$final_size=~s/\s+$|^\s+//igs;$final_size=~s/\,+/\,/igs;$final_size=~s/\,$|^\,//igs;$final_size=~s/\,\s+\,/\,/igs;
							$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
							$final_color='no raw color' if($final_color eq '');
							
							my $duplicate_check=$final_color.$final_size;
							$duplicate_check=~s/\W//igs;
							if($duplicate_color{$duplicate_check} eq '')
							{
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$final_color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$final_color;
								$colors{$final_color}=1;
								$duplicate_color{$duplicate_check}=1;
								push(@query_string,$query);
								
								# print "\nName2 :: $product_name\n";
								# print "\nPrice :: $price\n";
								# print "\nPrice Text :: $price_text\n";
								# print "\nSize :: $final_size\n";
								# print "\nColour :: $final_color\n";
								# print "\nout_of_stock :: $out_of_stock\n";
							}	
						}
					}
				}
			}
		}
		elsif( $content2=~m/jsonColorBaseID\s*\=\{([\w\W]*?)Pd\.prod\s*\=/is)
		{
			my $json_block=$1;
			my (@attr_array,%hash);
			if($json_block =~m/\"attNames\"\:\[([^>]*?)]/is)
			{
				my $attname = $1;
				$attname =~ s/\"//igs;
				$attname =~ s/\s+$|^\s+//igs;
				@attr_array = split /\,/, $attname;
			}
			for(my $i = 0; $i<@attr_array; $i++)
			{
				my $att_type=$attr_array[$i];
				$hash{$i}=$att_type;
			}
			if($json_block=~m/(\"varName\"\:\s*[^<]*?\}\])/is)
			{
				my $sku_main_block=$1;
				if($sku_main_block=~m/\"varName\"\:\"([^\"]*?)\"\,\"fitDisplayName\"\:\"([^\"]*?)\"([^<]+)/is)
				{
					while($sku_main_block=~m/\"varName\"\:\"([^\"]*?)\"\,\"fitDisplayName\"\:\"([^\"]*?)\"([^<]+)/igs)
					{
						my $size2_value=$1;
						my $size2_name=$2;
						my $sku_block=$3;
						while($sku_block=~m/\{\"pId\"([^<]*?)\}/igs)
						{
							my $sku_detail=$1;
							my $out_of_stock='n';
							if($price_flag==0)
							{
								if($sku_detail=~m/\"price\s*\"\s*\:\s*([^<]*?)\s*\,/is)
								{
									$price=$1;
								}
							}
							if($sku_detail=~m/\"aVals\s*\"\s*\:\s*\[([^<]*?)\]/is)
							{
								my $block=$1;
								$block =~ s/\"//igs;
								my $final_size;my $final_color;
								foreach my $key(keys %hash)
								{
									my $size;my $colour;
									if($hash{$key}=~m/colour|color/is)
									{
										$colour =(split(',',$block))[$key];
										$colour =~ s/\s+$|^\s+//igs;
									}
									else
									{
										my $size_val=(split(',',$block))[$key];
										$size_val =~ s/\s+$|^\s+//igs;
										if($hash{$key} eq 'Size')
										{
											$size.=$hash{$key}.': '.$size_val;
										}
										else
										{
											$size.=$hash{$key}.': '.$size_val;
										}
									}
									$final_color=$colour if($colour ne '') ;	
									$final_size.=$size.',';
								}
								$final_size=$size2_name.': '.$size2_value.', '.$final_size;
								$final_size=~s/\s+$|^\s+//igs;$final_size=~s/\,+/\,/igs;$final_size=~s/\,$|^\,//igs;$final_size=~s/\,\s+\,/\,/igs;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								$final_color='no raw color' if($final_color eq '');
								
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$final_color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$final_color;
								$colors{$final_color}=1;
								push(@query_string,$query);
								
								# print "\nName3 :: $product_name\n";
								# print "\nPrice :: $price\n";
								# print "\nPrice Text :: $price_text\n";
								# print "\nSize :: $final_size\n";
								# print "\nColour :: $final_color\n";
								# print "\nout_of_stock :: $out_of_stock\n";
							}
						}
					}
				}
				else
				{
					while($sku_main_block=~m/\{\"pId\"([^<]*?)\}/igs)
					{
						my $sku_detail=$1;
						my $out_of_stock='n';
						if($price_flag==0)
						{
							if($sku_detail=~m/\"price\s*\"\s*\:\s*([^<]*?)\s*\,/is)
							{
								$price=$1;
							}
						}
						if($sku_detail=~m/\"aVals\s*\"\s*\:\s*\[([^<]*?)\]/is)
						{
							my $block=$1;
							$block =~ s/\"//igs;
							my $final_size;my $final_color;
							foreach my $key(keys %hash)
							{
								my $size;my $colour;
								if($hash{$key}=~m/colour|color/is)
								{
									$colour =(split(',',$block))[$key];
									$colour =~ s/\s+$|^\s+//igs;
								}
								else
								{
									my $size_val=(split(',',$block))[$key];
									$size_val =~ s/\s+$|^\s+//igs;
									if($hash{$key} eq 'Size')
									{
										$size.=$hash{$key}.': '.$size_val;
									}
									else
									{
										$size.=$hash{$key}.': '.$size_val;
									}
								}
								$final_color=$colour if($colour ne '') ;	
								$final_size.=$size.',';
							}
							$final_size=~s/\s+$|^\s+//igs;$final_size=~s/\,+/\,/igs;$final_size=~s/\,$|^\,//igs;$final_size=~s/\,\s+\,/\,/igs;
							$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
							$final_color='no raw color' if($final_color eq '');
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$final_color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$final_color;
							$colors{$final_color}=1;
							push(@query_string,$query);
							
							# print "\nName4 :: $product_name\n";
							# print "\nPrice :: $price\n";
							# print "\nPrice Text :: $price_text\n";
							# print "\nSize :: $final_size\n";
							# print "\nColour :: $final_color\n";
							# print "\nout_of_stock :: $out_of_stock\n";
						}
					}
				}
			}
		}
		else # #Sku Information -  Non Json Type
		{
			$no_color_flag=1;
			if($content2=~m/var\s*salePrice_[\w]+\s*\=\s*\'\s*([^\']*?)\s*\'\s*\;/is) #Price 
			{
				$price=$1;
			}
			
			my $out_of_stock='n';
			my $colour;
			$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$product_id;
			push(@query_string,$query);	

			# print "\nName5 :: $product_name\n";
			# print "\nPrice :: $price\n";
			# print "\nPrice Text :: $price_text\n";
			# print "\nSize :: $size\n";
			# print "\nColour :: $colour\n";
			# print "\nout_of_stock :: $out_of_stock\n";
		}
		############### Image Processing
		my @color_array = keys %colors;
		if(scalar @color_array > 0)
		{
			if($content2=~m/<div\s*class\=\"colors\">([\w\W]*?)<\/div>/is)
			{
				my $image_block=decode_entities($1);
				my $alt_flag=1;
				my $color_n;
				foreach(@color_array)
				{
					$color_n=$_;
					
					if($image_block=~m/<a[^<]*?\'(http[^<]*?)\'[^<]*?>\s*<img[^<]*?\s*title\=\"$color_n\"\s*src\=\"([^<]*?)\"[^<]*?>/is) #Default Image
					{
						my $default_image=decode_entities($1);
						my $swatch_image=decode_entities($2);
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_n;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_image,'swatch',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_image,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_n;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					elsif($image_block=~m/<a[^<]*?\'(http[^<]*?)\'[^<]*?>\s*<img[^<]*?\s*title\=\"$color_n[^<]*?\"\s*src\=\"([^<]*?)\"[^<]*?>/is) #Default Image
					{
						my $default_image=decode_entities($1);
						my $swatch_image=decode_entities($2);
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_n;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_image,'swatch',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_image,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_n;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}	
				if($content2=~m/<div\s*class\=\"slider\">([\w\W]*?)<\/div>/is)  	# Alt Image
				{
					my $image_block=$1;
					while($image_block=~m/<img[^<]*?src\=\"([^<]*?)\"[^<]*?>/igs)
					{
						my $alt_image=decode_entities($1);
						$alt_image=~s/\?[^<]*?$//igs;
						if($alt_flag==1)
						{
							$alt_flag++;
						}
						else
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color_n;
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
					}
				}
			}
			elsif($content2=~m/<div\s*class\=\"slider\">([\w\W]*?)<\/div>/is)  	# Product Image Alone,
			{
				my $image_block=$1;
				my $count=1;
				
				foreach(@color_array)
				{
					my $color_n=$_;
					while($image_block=~m/<img[^<]*?src\=\"([^<]*?)\"[^<]*?>/igs)
					{
						my $default_image=decode_entities($1);
						if($count == 1)
						{
							
							my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color_n;
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						else
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color_n;
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
						$count++;
					}
					last;
				}
			}
		}
		else
		{
			if($content2=~m/<div\s*class\=\"slider\">([\w\W]*?)<\/div>/is)  	# Product Image Alone,
			{
				my $image_block=$1;
				my $count=1;

				while($image_block=~m/<img[^<]*?src\=\"([^<]*?)\"[^<]*?>/igs)
				{
					my $default_image=decode_entities($1);
					if($count == 1)
					{
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					$count++;
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
		#If product is available without description and product detail
		if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
			$prod_detail='-';
		}
		PNF:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit;
	}	
}1;

sub getcont()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	$url =~ s/amp;//igs;
	
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
		if ( $rerun_count <= 7 )
		{
			$rerun_count++;
			sleep 5;
			goto Home;
		}
	}
	return $content;
}	

sub trim($) 
{
  my $string = shift;
  $string =~ s/<[^<]*?>/ /igs;
  $string =~ s/\&nbsp\;/ /igs;
  $string =~ s/\&\#039\;/'/igs;
  $string =~ s/\&\#43\;/+/igs;
  $string =~ s/amp;//igs;
  $string =~ s/\s+/ /igs;
  $string =~ s/^\s+|\s+$//igs;
  return $string;
}
