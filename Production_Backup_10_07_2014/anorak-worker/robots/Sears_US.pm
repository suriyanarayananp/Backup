#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Sears_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Sears_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Sears-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Sea';
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
	
	my $home_content=&GetContent('http://www.sears.com/','GET','','');
	my $skuflag = 0;my $imageflag = 0;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		my @query_string;
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;my %sku_objectkey;my %image_objectkey;my %hash_default_image;my $mflag=0;my $price_flag=0;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$size);my %colors;
		my $content2=&GetContent($url3,'GET','','');
		
		if($content2=~m/<iframe\s*src\=\"[^\"]*?\"\s*[^>]*?><\/iframe>/is)
		{
			&Function($url3,$product_object_key,$dbh,$robotname,$retailer_id);
			goto end;
		}
		if($content2=~m/if\s*\(storeId\s*\=\=\s*\'[\d]+\'\s*\|\|\s*storeId\s*\=\=\s*\'[\d]+\'\s*\|\|\s*storeId\s*\=\=\s*\'[\d]+\'\s*\)/is)
		{
			$mflag=1;
			#product_id
			if($url3=~m/\/p\-([^<]+?)\?/is)
			{
				$product_id=$1;
			}
			#product_name
			if ( $content2 =~m/itemprop\=\"name\">\s*([^<]*?)\s*</is )
			{
				$product_name = trim($1);
				decode_entities($product_name);
			}
			#Description 
			if ( $content2 =~m/<p\s*id\=\"shortDesc\">\s*([^<]*?)\s*<ul>\s*([\w\W]*?)\s*<\/ul>\s*<\/p>/is )
			{
				$description = trim($1);
				$prod_detail = trim($2);
				decode_entities($prod_detail);
				decode_entities($description);
			}
			goto noinfo;
		}
		if($content2!~m/<a\s*id\=\"descriptionAnchor\">/is)
		{
			goto noinfo;
		}
		
		#product_id
		if($url3=~m/\/p\-([^<]+?)\?/is)
		{
			$product_id=$1;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
		}
		#product_name
		if ( $content2 =~m/<h1\s*itemprop\=\"name\">\s*([^<]*?)\s*</is )
		{
			$product_name = trim($1);
			decode_entities($product_name);
		}
			
		#Brand
		if ( $content2 =~m/rrProdBrand\s*\=\s*\"([^\"]*?)\"\;/is )
		{
			$brand = trim($1);
			decode_entities($brand);
		}
		
		#Description 
		if ( $content2 =~m/<a\s*id\=\"descriptionAnchor\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
		{
			$description = trim($1);
			decode_entities($description);
		}
		elsif ( $content2 =~m/>\s*Product\s*Description\s*([\w\W]*?)\s*<\/p>\s*<\/p>/is )
		{
			$description = trim($1);
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
		elsif( $content2 =~m/<span\s*class\=\"regPrice\"\s*itemprop\=\"price\">\s*([^<]*?)\s*<\/span>/is )
		{
			$price_text = trim($1);
			decode_entities($price_text);
		}
		elsif( $content2 =~m/<span\s*class\=\"salePrice\"\s*itemprop\=\"price\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>\s*<\/div>/is )
		{
			$price_text = trim($1);
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
							# $out_of_stock='y' unless($sku_detail=~m/\"\s*stk\s*\"\s*\:\s*true\s*\,/is);
							# $price=$1 if($sku_detail=~m/\"price\s*\"\s*\:\s*([^<]*?)\s*\,/is);
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
											# $size.=$size_val;
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
								# push(@color_array,$final_color);
								$final_size=$size2_name.': '.$size2_value.', '.$final_size;
								$final_size=~s/\s+$|^\s+//igs;$final_size=~s/\,+/\,/igs;$final_size=~s/\,$|^\,//igs;$final_size=~s/\,\s+\,/\,/igs;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								
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
						# $out_of_stock='y' unless($sku_detail=~m/\"\s*stk\s*\"\s*\:\s*true\s*\,/is);
						# $price=$1 if($sku_detail=~m/\"price\s*\"\s*\:\s*([^<]*?)\s*\,/is);
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
										# $size.=$size_val;
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
							# push(@color_array,$final_color);
							# $final_size=$size2_name.': '.$size2_value.', '.$final_size;
							$final_size=~s/\s+$|^\s+//igs;$final_size=~s/\,+/\,/igs;$final_size=~s/\,$|^\,//igs;$final_size=~s/\,\s+\,/\,/igs;
							$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
							
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
							}	
						}
					}
				}
			}
		}
		elsif( $content2=~m/jsonColorBaseID\s*\=\{([\w\W]*?)Pd\.prod\s*\=/is)
		{
			my $json_block=$1;
			# if($json_block=~m/(\"aStory[\w\W]*?)\"\s*\]/is)
			# {
				# my $price_block=$1;
				# if($price_block=~m/<span\s*class\=\'salePrice\'\s*itemprop[^<]*?price[^<]*?>([\w\W]*?)<\/del>/is)
				# {
					# $price_text=trim($1); 
				# }
				# elsif($price_block=~m/<span\s*class\=\'salePrice\'\s*itemprop[^<]*?price[^<]*?>([\w\W]*?)<\/span>/is)
				# {
					# $price_text=trim($1); 
				# }
				# elsif($price_block=~m/<span\s*class[^<]*?itemprop[^<]*?price[^<]*?>([\w\W]*?)<\/span>/is)
				# {
					# $price_text=trim($1); 
				# }
				# decode_entities($price_text);
			# }
			
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
							# $out_of_stock='y' unless($sku_detail=~m/\"\s*stk\s*\"\s*\:\s*true\s*\,/is);
							# $price=$1 if($sku_detail=~m/\"price\s*\"\s*\:\s*([^<]*?)\s*\,/is);
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
											# $size.=$size_val;
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
								# push(@color_array,$final_color);
								$final_size=$size2_name.': '.$size2_value.', '.$final_size;
								$final_size=~s/\s+$|^\s+//igs;$final_size=~s/\,+/\,/igs;$final_size=~s/\,$|^\,//igs;$final_size=~s/\,\s+\,/\,/igs;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$final_color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$final_color;
								$colors{$final_color}=1;
								push(@query_string,$query);
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
						# $out_of_stock='y' unless($sku_detail=~m/\"\s*stk\s*\"\s*\:\s*true\s*\,/is);
						# $price=$1 if($sku_detail=~m/\"price\s*\"\s*\:\s*([^<]*?)\s*\,/is);
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
										# $size.=$size_val;
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
							# push(@color_array,$final_color);
							# $final_size=$size2_name.': '.$size2_value.', '.$final_size;
							$final_size=~s/\s+$|^\s+//igs;$final_size=~s/\,+/\,/igs;$final_size=~s/\,$|^\,//igs;$final_size=~s/\,\s+\,/\,/igs;
							$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$final_color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$final_color;
							$colors{$final_color}=1;
							push(@query_string,$query);
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
			# if($content2=~m/<div\s*class\=\"ProductUpsellVertView\">([\w\W]*?<\/div>)/is) # Price Text
			# {
				# my $price_block=$1;
				# if($price_block=~m/<span\s*class[^<]*?salePrice[^<]*?itemprop[^<]*?price[^<]*?>([\w\W]*?)<\/del>/is)
				# {
					# $price_text=trim($1); 
				# }
				# elsif($price_block=~m/<span\s*class[^<]*?salePrice[^<]*?itemprop[^<]*?price[^<]*?>([\w\W]*?)<\/span>/is)
				# {
					# $price_text=trim($1); 
				# }
				# elsif($price_block=~m/<span\s*class[^<]*?itemprop[^<]*?price[^<]*?>([\w\W]*?)<\/span>/is)
				# {
					# $price_text=trim($1); 
				# }
				# elsif($price_block=~m/<span\s*class[^<]*?pric[^<]*?>([\w\W]*?)<\/span>/is)
				# {
					# $price_text=trim($1); 
				# }
				# elsif($price_block=~m/<span\s*class[^<]*?pric[^<]*?>([\w\W]*?)<\/del>/is)
				# {
					# $price_text=trim($1); 
				# }
				
				# my $temp_price1=$price_text;
				# my $temp_price2=$price;
				
				# $temp_price1=~s/\W+//igs;$temp_price2=~s/\W+//igs;
				
				# if($temp_price1 eq $temp_price2)
				# {
				# }
				# else
				# {
					# $price_text=$price_text.' $'.$price;
				# }
			# }
			
			my $out_of_stock='n';
			my $colour;
			# my $colour=trim($1) if($content2=~m/Color\s*\:\s*<\/strong>\s*<\/td>\s*<td>\s*([^<]*?)\s*<\/td>/is);
			$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$product_id;
			push(@query_string,$query);			
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
		noinfo:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit;
	}
}1;	
sub GetContent($$$$)
{
    my $mainurl=shift;
    my $method=shift;
    my $parameter=shift;
    my $referer=shift;
	my $coookie=shift;
	
    my $err_count=0;
    home:
    my $req=HTTP::Request->new($method=>"$mainurl");
    if($method eq 'POST')
    {        
        $req->content("$parameter");
    }
    $req->header("Host"=> "www.sears.com");
    $req->header("Cookie"=> 'JSESSIONID=0000PkzAQdFXtA6NX8Yn6FSSh8l:176muqv4l; WC_PERSISTENT=HiOlPRGZ49VNBikdf6vIdOOcR0Y%3d%0a%3b2014%2d02%2d17+09%3a29%3a33%2e77%5f1392650960437%2d221296%5f10153%5f3250953954%2c%2d1%2cUSD%5f10153; ot=prod-vX-Cqk1WtruJPu3jasoWwxaPcK-; IntnlShip=US%7CUSD%7C1%7C12425778%7C%7C%7CN; akaau=1392652760~id=05b6536f3aa92d26745ef3a40fbfd6ff; _br_uid_2=uid%3D6065520846256%3A_uid%3D5222661621379%3Av%3D11.5%3Ats%3D1392651171593%3Ahc%3D4; s_pers=%20s_vnum%3D1550331171998%2526vn%253D2%7C1550331171998%3B%20s_dfa%3Dsearscom%252Csearsinternational%7C1392701084712%3B%20s_depth%3D2%7C1392701086501%3B%20s_fid%3D3313706E032C0DB7-096BF12AEA08D8FF%7C1455771317066%3B%20s_invisit%3Dtrue%7C1392701117068%3B%20gpv_pn%3DHomepage%2520%253E%2520Sears%7C1392701117069%3B%20gpv_sc%3DHomepage%7C1392701117070%3B%20gpv_pt%3DHomepage%7C1392701117072%3B; s_sso=s_r%7CY%7C; s_sess=%20s_e47%3DDAP%2520%253E%2520Shopping%2520in%2520the%2520US%2520United%2520States%3B%20s_cc%3Dtrue%3B%20s_sq%3D%3B%20s_ppv%3DDAP%252520%25253E%252520Shopping%252520in%252520the%252520US%252520United%252520States%252C13%252C7%252C827%3B%20s_e30%3DAnonymous%3B; ra_id=0000Cqk1WtruJPu3jasoWwxaPcK%3A176muqv4l%7CG%7C%7C%7C0%7C%7C%7C%7C; KI_FLAG=false; WC_SESSION_ESTABLISHED=true; WC_ACTIVEPOINTER=%2d1%2c10153; c_i=%7B%22Akamai%22%3A%20%7B%22uN%22%3A%22%22%2C%22cI%22%3A%220%22%2C%22cA%22%3A%22%22%2C%22sP%22%3A0%2C%22sA%22%3A0%2C%22eStat%22%3A%22%22%2C%22cbOpt%22%3A%22%22%2C%22ccA%22%3A%22%22%7D%7D; s_a=s%5fa; s_vi=[CS]v1|298115690501354B-6000011240000FD0[CE]; btpdb.PCNPFl9.Y3JpdGVvIHNpbmdsZSBzaG90=dHJ1ZQ; btpdb.PCNPFl9.Y3JpdGVvIGFsbCBwYWdlcyBjb3VudGVy=dnY; aam_chango=crt%3Dsears%2Ccrt%3Dshoesenthusiast%2Ccrt%3Dapplianceenthusiast%2Ccrt%3Dclothingenthusiast%2Ccrt%3Dmovers%2Ccrt%3Drehabber; aamsears=aam%3D2%26aam%3D3%26aam%3D4; aam_criteo=crt%3Dsears; sears_offers=offers%3D1; aam_uuid=72101707565931100364251619526977404937; s_r=s%5fr; WC_USERACTIVITY_3250953954=3250953954%2c10153%2cnull%2cnull%2cnull%2cnull%2cnull%2cnull%2cnull%2cnull%2cPNBqxLrfb%2fftx8NOf1VKHsrABae09DAuscXzEo2d0YgrS65pguX0qKpM9qSAz24riA%2btLdXaSU2a%0aRzuhLD%2fX25fHKJ00v47abkPncLeygJZT4wudhmV6o%2f%2f%2fPUBJdSOrpk5P%2bBYosIOxiunReE7ZEA%3d%3d; mbox=check#true#1392699345|session#1392699266772-961424#1392701145|PC#1392699266772-961424.22_06#1393908885; userDealDetails=0%7C%7C%7C; btpdb.PCNPFl9.X2J0X2NyX2R1cmF0aW9u=eA; btpdb.PCNPFl9.Y3VycmVudCB2aXNpdG9y=dHJ1ZQ; SessionPersistence=CLIENTCONTEXT%3A%3DvisitorId%253D; _br_uid_1=uid%3D5222661621379; OAX=tkfqAlMC5sIAC65a');
	$req->header("X-Requested-With"=> "XMLHttpRequest");
    $req->header("Accept"=> "application/json");
    $req->header("Referer"=> "$referer");

    my $res=$ua->request($req);
    $cookie->extract_cookies($res);
    $cookie->save;
    $cookie->add_cookie_header($req);
    
    my $code=$res->code;    
    print "\nCODE :: $code\n";    
	open JJ,">>$retailer_file";
	print JJ "$mainurl->$code\n";
	close JJ;
    if($code=~m/50|40/is)
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
sub trim
{
	my $txt = shift;
	
	$txt =~ s/\<script[^>]*?\>[^<]*?\<\/script\>//ig;
	$txt =~ s/<li>/\*/ig;
	$txt =~ s/\<[^>]*?\>/ /ig;
	$txt =~ s/Product\s*Description//ig;
	$txt =~ s/\n+/ /ig;
	$txt =~ s/\&nbsp\;/ /ig;
	$txt =~ s/\s+/ /ig;
	$txt =~ s/^\s+|\s+$//ig;
	# $txt =~ s/\&amp\;/\&/ig;
	# $txt =~ s/\&pound\;/£/ig;
	$txt =~ s/\\\&\#039\;/\'/ig;
	$txt =~ s/\&\#039\;/\'/ig;
	$txt =~ s/\&\#45\;/\-/ig;
	$txt =~ s/\&\#8221\;/\'\'/ig;
	$txt =~ s///ig;
	$txt =~ s/^\.$//ig;$txt =~ s/^\,$//ig;$txt =~ s/^\:|\:$//ig;$txt =~ s/\\//ig;
	$txt =~ s/^\-//ig;$txt =~ s/^\#//ig;$txt =~ s/^\*//ig;$txt =~ s/^\,|\,$//ig;
	$txt =~ s/^\.//ig;$txt =~ s/^\?//ig;$txt =~ s/^|//ig;$txt =~ s/\&loz\;//ig;
	$txt =~ s/\&\#174\;|\&reg\;/®/ig;
	$txt =~ s/\&\#8482\;|\&trade\;/™/ig;
	$txt =~ s/\&bull\;//ig;
	$txt =~ s/\&\#8217\;|\&rsquo\;/\'/ig;
	$txt =~ s/\s*Read\s*full\s*description[\w\W]+//ig;
	
	return $txt;
}
sub Function($$$$)
{
	my $url3=shift;
	my $product_object_key=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	
	my @query_string;
	my $skuflag = 0;my $imageflag = 0;my %sku_objectkey;my %image_objectkey;my %hash_default_image;
	my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$size);
	#product_id
	if($url3=~m/\/p\-([^<]+?)\?/is)
	{
		$product_id=$1;
		my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh, $robotname,$retailer_id);
		goto end1 if($ckproduct_id == 1);
	}
	my $url11='http://www.sears.com/content/pdp/config/products/Sears/'.$product_id.'?referer=other&productDataSource=greenbox';
	my $conte3=&GetContent($url11,'GET','','');
	if($conte3 eq '') ### sometimes $url11 is throwing error. if it throws error, another url is need to ping.
	{
		my $url='http://www.sears.com/content/pdp/sellers/'.$product_id;
		my $conte13=&GetContent($url,'GET','',$url3);
		if($conte13=~m/\"availability\"\:[^<]*?\,(?:\"brand\"\:\"[^<]*?\"\,)?\"id\"\:\"([^<]*?)\"/is)
		{
			my $new_id=$1;
			my $url31='http://www.sears.com/content/pdp/config/products/Sears/'.$new_id.'?referer=other&productDataSource=greenbox';
			my $content=&GetContent($url31,'GET','','');
			### Brand Name
			if( $content =~m/\"brandName\"\:\"([^\"]*?)\"/is )
			{
				$brand = trim($1);
				decode_entities($brand);
			}
			### Product Name
			if( $content =~m/\"name\"\:\"([^\"]*?)\"\,\"operational/is )
			{
				$product_name = trim($1);
				decode_entities($product_name);
				$product_name=$brand." $product_name";
			}
			### Description
			if ( $content =~m/\"shortDesc\"\:\"([^\"]*?)\"/is )
			{
				$description = trim($1);
				decode_entities($description);
			}
			else
			{
				$description=" ";
			}
			#### Price and Price text
			if ( $content =~m/regPrice\"\:\"([^<]*?)\"\,\"sale\"\:\{\"price\"\:\"([^<]*?)\"/is )
			{
				$price_text='$'.$1." ".'$'.$2;
				$price=$2;
				$price=~s/\,//igs;
			}
			elsif( $content =~m/regPrice\"\:\"([^<]*?)\"/is )
			{
				$price_text='$'.$1;
				$price=$1;
				$price=~s/\,//igs;
			}
			#### Default image
			if($content=~m/assets\"\:\{\"imgs\"([^<]*?)\"brand/is)
			{
				my $image_block=$1;
				if($image_block=~m/\"src\"\:\"([^<]*?)\"/is)
				{
					my $default_image=$1;					
					my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_id;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
			}
			### Sku part. color and size is not available
			$price="null" if($price eq '');
			my ($color,$size);my $out_of_stock='n';
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$product_id;
			push(@query_string,$query);
					
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
			
			if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
			{
				$prod_detail='-';
			}
			my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
			push(@query_string,$query1);push(@query_string,$query2);
			&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
			$dbh->commit();
		}
	}
	else
	{
		#Brand
		if ( $conte3 =~m/\"brand\"\:\"([^\"]*?)\"/is )
		{
			$brand = trim($1);
			decode_entities($brand);
		}
		elsif( $conte3 =~m/\"brandName\"\:\"([^\"]*?)\"/is )
		{
			$brand = trim($1);
			decode_entities($brand);
		}
		#product_name
		if ( $conte3 =~m/\"modelNo\"\:\"[^\"]*?\"\,\"title\"\:\"([^\"]*?)\"/is )
		{
			$product_name = trim($1);
			decode_entities($product_name);
			$product_name=$brand." ".$product_name;
		}
		#Description 
		if ( $conte3 =~m/\"shortDesc\"\:\"([^\"]*?)\"/is )
		{
			$description = trim($1);
			decode_entities($description);
		}
		else
		{
			$description=" ";
		}
		### This content is getting for price only
		my $url12='http://www.sears.com/shc/s/ItemSavestoryAjax?storeId=10153&region=0&mkt=false&regionalPricingEligible=N&prdType=VARIATION&prdBeanType=ProductBean&ajaxFlow=true&shcAJAX=1&partNumber='.$product_id;
		my $conte4=&GetContent($url12,'GET','','');
		if ( $conte4 =~m/<span\s*class\=\\\"(?:sale|reg)Price\\\"\s*itemprop\=\\\"price\\\">([\w\W]*?)\"\}/is )
		{
			$price_text = trim($1);
			decode_entities($price_text);
		}
		if ( $conte4 =~m/\"prodDispPrice\"\:\"([^\"]*?)\"/is )
		{
			$price = trim($1);
			decode_entities($price);
			$price=~s/\,//igs;$price=~s/\s*\-\s*[^<]*//igs;
		}
		#### If price is empty, it is capturing for conte3.
		if($price eq '')
		{
			if ( $conte3 =~m/price\"\:\{\"regPrice\"\:\"([^\"]*?)\"\}/is )
			{
				$price = trim($1);
				decode_entities($price);
				$price=~s/\,//igs;
				$price_text='$'.$price;
			}
		}
		### if it is still empty, it is capturing from another url
		if($price eq '')
		{
			my $product_id1=$product_id;
			$product_id1=~s/[a-z]$//igs;
			$product_id1=~s/-//igs;
			my $price_url='http://www.sears.com/content/pdp/products/pricing/'.$product_id1.'?variation=0&regionCode=0';
			my $price_cont=&GetContent($price_url,'GET','','');
			if($price_cont=~m/\"regular\-price\"\:\"?([^<]*?)\"?\,\"promo\-price\"\:\"?([^<]*?)\"?\,/is)
			{
				$price_text='$'.$1.' '.'$'.$2;
				$price=$2;
				$price=~s/\,//igs;
				if($price=~m/^0\.00$/is)
				{
					if($price_cont=~m/\"sell\-price\"\:\{\"\@type\"\:\"[a-z]+\"\,\"\$\"\:\"([^\"]*?)\"\}/is)
					{
						$price=$1;
						$price_text='$'.$1;
					}
				}
				$price=~s/\$0\.00\s*\$0\.00//igs;
				$price_text=~s/^0.00$//igs;
			}
		}
		$price="null" if($price eq '');
		##### Sku part  - color , size and out of stock
		#### color flag for checking product whether it is having color or not
		my $color_flag=0;my %colors;
		if($conte3=~m/definingAttrs\"\:\[\{\"dispType\"\:\"COMBOBOX|DROPDOWN|SWATCH\"/is)
		{
			while($conte3=~m/\"name\"\:(\"[^\"]*?\")\,\"operational\"/igs)
			{
				my $size=$1;
				my $out_of_stock='n';
				
				my $color;
				if($size=~m/Color\s*\:\s*([^\,]*?)\,/is)
				{
					$color=$1;
					$size=~s/Color\s*\:\s*[^\,]*?\,//igs;
					$size=~s/^\"|\"$//igs;
					$size=~s/^\,|\,$//igs;
					$colors{$color}=1;
				}
				elsif($size=~m/Color\s*\:\s*([^\"]*?)\"/is)
				{
					$color=$1;
					$size=~s/Color\s*\:\s*[^\"]*?\"//igs;
					$size=~s/^\"|\"$//igs;
					$size=~s/^\,|\,$//igs;
					$colors{$color}=1;
				}
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				$color_flag=1;
				push(@query_string,$query);
			}
		}
		else #### No color and No size
		{
			my ($color,$size);my $out_of_stock='n';
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$product_id;
			push(@query_string,$query);
		}
		
		###### Image part - Default , Alternate and Swatch
		if($color_flag == 1)  ### this if loop for color
		{
			my @colours = keys %colors;
			my %dup_image;
			#### this if loop for color which is given in swatch
			if($conte3=~m/\{\"familyName\"\:\"[^\"]*?\"\,\"id\"\:\"[\d]+\"\,\"name\"\:\"([^\"]*?)\"\,\"primaryImg\"\:\{\"attrs\"\:\{\"height\"\:\"[^\"]*?\"\,\"src\"\:\"([^\"]*?)\"\,(?:\"title\"\:\"[^\"]*?\"\,)?\"width\"\:\"[^\"]*?\"\}\}\,\"seq\"\:\"[^\"]*?\"\,\"swatchImg\"\:\{\"attrs\"\:\{\"height\"\:\"[^\"]*?\"\,\"src\"\:\"([^\"]*?)\"/is)
			{
				my ($colour,$default_image,$swatch_image);
				while($conte3=~m/\{\"familyName\"\:\"[^\"]*?\"\,\"id\"\:\"[\d]+\"\,\"name\"\:\"([^\"]*?)\"\,\"primaryImg\"\:\{\"attrs\"\:\{\"height\"\:\"[^\"]*?\"\,\"src\"\:\"([^\"]*?)\"\,(?:\"title\"\:\"[^\"]*?\"\,)?\"width\"\:\"[^\"]*?\"\}\}\,\"seq\"\:\"[^\"]*?\"\,\"swatchImg\"\:\{\"attrs\"\:\{\"height\"\:\"[^\"]*?\"\,\"src\"\:\"([^\"]*?)\"/igs)
				{
					$colour=$1;
					$default_image=$2;
					$swatch_image=$3;
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$colour;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_image,'swatch',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_image,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$colour;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				while($conte3=~m/\"alternateImg\"\:\[\{\"height\"\:\"[^\"]*?\"\,\"src\"\:\"([^\"]*?)\"/igs)
				{
					my $alternate_image=$1;
					my $dupe=$alternate_image;
					$dupe=~s/\W//igs;
					
					if($dup_image{$dupe} eq '')
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alternate_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alternate_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$colour;
						$hash_default_image{$img_object}='n';
						$dup_image{$dupe}=1;
						push(@query_string,$query);
					}	
				}
			}
			else  #### this else loop for color which is given in dropdown list
			{
				if($conte3=~m/assets\"\:\{\"imgs\"([^<]*?)\"automotive\"/is)
				{
					my $block=$1;
					my $alt_image=1;
					while($block=~m/\"src\"\:\"([^\"]*?)\"/igs)
					{
						my $default_image=$1;
						if($alt_image == 1)
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colours[0];
							$hash_default_image{$img_object}='y';
							$alt_image++;
							push(@query_string,$query);
						}
						else
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colours[0];
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
					}
				}
				elsif($conte3=~m/assets\"\:\{\"imgs\"([^<]*?)\"brand\"/is)
				{
					my $block=$1;
					my $alt_image=1;
					while($block=~m/\"src\"\:\"([^\"]*?)\"/igs)
					{
						my $default_image=$1;
						if($alt_image == 1)
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colours[0];
							$hash_default_image{$img_object}='y';
							$alt_image++;
							push(@query_string,$query);
						}
						else
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colours[0];
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
					}
				}
			}
		}
		else  ### this else loop for no color
		{
			if($conte3=~m/assets\"\:\{\"imgs\"([^<]*?)\"automotive\"/is)
			{
				my $block=$1;
				my $alt_image=1;
				while($block=~m/\"src\"\:\"([^\"]*?)\"/igs)
				{
					my $default_image=$1;
					if($alt_image == 1)
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
						$hash_default_image{$img_object}='y';
						$alt_image++;
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
				}
			}
			elsif($conte3=~m/assets\"\:\{\"imgs\"([^<]*?)\"brand\"/is)
			{
				my $block=$1;
				my $alt_image=1;
				while($block=~m/\"src\"\:\"([^\"]*?)\"/igs)
				{
					my $default_image=$1;
					if($alt_image == 1)
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
						$hash_default_image{$img_object}='y';
						$alt_image++;
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
		if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
			$prod_detail='-';
		}
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		$dbh->commit();
	}
	end1:
	print "";
}