#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Reiss_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Reiss_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;
	$robotname='Reiss-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Rei';
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
	
	my $skuflag = 0;my $imageflag = 0;my @query_string;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.reiss.com/'.$url3 unless($url3=~m/^\s*http\:/is);
		my $Final_cont = &get_content($url3);
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;
		my ($product_id,$brand,$product_name,$description,$prod_detail);
		$brand="Reiss";
		#product_id
		if ( $Final_cont =~ m/>\s*Product\s*Code\s*(?:\:\s*)?\s*([^<]*?)\s*<\/div>/is )
		{
			$product_id = Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
			# undef ($ckproduct_id);
		}
		#product_name
		if ( $Final_cont =~ m/<h2\s*class\=\"product_short_desc\"[^<]*?>\s*([\w\W]*?)\s*<\/\s*h2>/is )
		{
			$product_name = Trim($1);
			if($product_name eq '')
			{
				if ($Final_cont=~ m/<h1[^<]*?itemprop[^<]*?product_title\">([\w\W]*?)<\/h1>/is)
				{
					$product_name = Trim($1);
				}
			}
		}
		#description
		if ( $Final_cont =~ m/DESIGN\s*NOTES([\w\W]*?)<\/li>\s*<\/ul>/is )
		{
			$description = Trim($1);		
		}
		#details
		if ( $Final_cont =~ m/<a\s*class\=\"accordion_link\"[^<]*?>\s*<span>(TRENDS[\w\W]*?)<\/li>\s*<\/ul>/is )
		{
			my $pr_detail =$1;		
			$prod_detail =$pr_detail;
			$prod_detail =~ s/<\/tr>/ | /igs;		
			$prod_detail = Trim($prod_detail);	
			$prod_detail =~ s/(?:\s*\|\s*)+/ | /igs;	
			$prod_detail =~ s/(?:\s*\:\s*)+/:/igs;	
			$prod_detail =~ s/\s*\|\s*$//igs;	
			$prod_detail =~ s/\s*\:\s*$//igs;
			$prod_detail = Trim($prod_detail);			
		}
		elsif($Final_cont =~ m/<a\s*class\=\"accordion_link\"[^<]*?>\s*<span>(SIZE[\w\W]*?)<\/li>\s*<\/ul>/is)
		{
			my $pr_detail =$1;		
			$prod_detail =$pr_detail;
			$prod_detail =~ s/<\/tr>/ | /igs;		
			$prod_detail = Trim($prod_detail);	
			$prod_detail =~ s/(?:\s*\|\s*)+/ | /igs;	
			$prod_detail =~ s/(?:\s*\:\s*)+/:/igs;	
			$prod_detail =~ s/\s*\|\s*$//igs;	
			$prod_detail =~ s/\s*\:\s*$//igs;
			$prod_detail = Trim($prod_detail);
		}
		elsif($Final_cont =~ m/<a\s*class\=\"accordion_link\"[^<]*?>\s*<span>(CARE[\w\W]*?)<\/li>\s*<\/ul>/is)
		{
			my $pr_detail =$1;		
			$prod_detail =$pr_detail;
			$prod_detail =~ s/<\/tr>/ | /igs;		
			$prod_detail = Trim($prod_detail);	
			$prod_detail =~ s/(?:\s*\|\s*)+/ | /igs;	
			$prod_detail =~ s/(?:\s*\:\s*)+/:/igs;	
			$prod_detail =~ s/\s*\|\s*$//igs;	
			$prod_detail =~ s/\s*\:\s*$//igs;
			$prod_detail = Trim($prod_detail);
		}
		
		&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		#colour
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		my $C_count=0;
		if($Final_cont =~ m/<select\s*[^>]*?id=\"colour_select\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/select>/is)
		{
			my $colour_content = $1;		
			while( $colour_content =~ m/<option[^<]*?value=\"([^\"]*?)\"\s*[^>]*?>\s*([^<]*?)\s*<\/option>/igs )
			{
				my $color_code 	= Trim($1);
				my $temp_colour = $2;
				$temp_colour=~s/\///igs;
				my $color = &upper_case_fist(lc(Trim($temp_colour)));
				$C_count++;
				$color_hash{$color_code} =$color;
			}
		}
		my $content2;
		if($C_count>1)
		{
			my @color_code = keys %color_hash;
			if($Final_cont =~ m/<form\s*[^>]*?action=\"([^\"]*?)\"\s*[^>]*?id=\"colour_change_form\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/form>/is)
			{
				my $url=$1;
				my $C_Block=$2;
				foreach my $code(@color_code)
				{
					my $act= Trim($1) if ($C_Block =~ m/<input\s*[^>]*?name=\"act\"\s*[^>]*?value=\"([^\"]*?)\"\s*[^>]*?>/is);
					my $category_id= Trim($1) if ($C_Block =~ m/<input\s*type\=\"hidden\"\s*name\=\"category_id\"\s*value\=\"([^<]*?)\"[^<]*?>/is);
					my $P_Con='?act='.$act.'&q=&category_id='.$category_id.'&style_colour_code='.$code;
					$url = $url.$P_Con;
					$content2 = &get_content($url);
					my ($price,$price_text,$sub_category,$main_image,$alt_image,$out_of_stock,$colour);
					if ( $content2 =~ m/<div\s*[^>]*?class=\"product_price\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/div>/is )
					{
						my $price_Block =$1;
						if( $price_Block =~ m/<span\s*[^>]*?class=\"now_price\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/span>/is )
						{
							$price = $1;
						}
						else
						{
							$price=$price_Block;
						}
						$price_Block=~s/\&pound\;/\Â\£/igs;
						$price_text=Trim($price_Block);
					}
					$price=~s/\&nbsp\;/ /igs;
					#$price=decode_entities($price);
					$price=~s/\£//igs;
					$price=~s/\&pound\;//igs;
					$price=~s/\W+//igs;
					$price=~s/[a-zA-Z]+|\$//igs;
					$price_text=$price_text if(length($price)<2);
					print "\nprice Text 1 :: $price_text\n";
					my $qcount=0;
					# size & out_of_stock
					if ( $content2 =~ m/>\s*please\s*select\s*a\s*size\s*<\/option>\s*([\w\W]*?)\s*<\/select>/is )
					{
						my $size_content = $1;
						while ( $size_content =~ m/<option\s*[^>]*?value=[^>]*?class=\"([^\"]*?)\"\s*[^>]*?>\s*([^<]*?)\s*<\/option>/igs)
						{
							my $stock_text = Trim($1);
							my $size = Trim($2);
							my $out_of_stock;
							if ( $stock_text =~ m/\s*size_not_available\s*/is )
							{
								$out_of_stock = 'y';
							}
							else
							{
								$out_of_stock = 'n';
							}
							print "\nprice Text 2 :: $price_text\n";
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color_hash{$code};
							push(@query_string,$query);
							if($qcount == 0)
							{
								# $logger->send("$robotname SkuQuery :: $query");
								$qcount++;
							}
						}						
						
					}
					if ( $content2 =~ m/<div\s*[^>]*?id=\"main_product_carousel\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
					{
						my $alt_image_content = $1;
						my $count;
						while ( $alt_image_content =~ m/<a\s*[^>]*?href=\"([^\"]*?)\"\s*[^>]*?>/igs )
						{
							$count++;
							my $alt_image =$1;
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							if ( $count == 1 )
							{
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object} = $color_hash{$code};
								$hash_default_image{$img_object} = 'y';
								push(@query_string,$query);
							}
							else
							{
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object} = $color_hash{$code};
								$hash_default_image{$img_object} = 'n';
								push(@query_string,$query);
							}
						}
					}
				}
			}
		}
		elsif($C_count==0)
		{
			$content2=$Final_cont;		
			my ($price,$price_text,$sub_category,$main_image,$alt_image,$out_of_stock,$colour);
			if ( $content2 =~ m/<div\s*[^>]*?class=\"product_price\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/div>/is )
			{
				my $price_Block =$1;
				#price
				if( $price_Block =~ m/<span\s*[^>]*?class=\"now_price\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/span>/is )
				{
					$price = $1;
				}
				else
				{
					$price=$price_Block;
				}
				#price_text
				$price_Block=~s/\&pound\;/\Â\£/igs;
				$price_text=Trim($price_Block);
			}
			$price=~s/\&nbsp\;//igs;
			#$price=decode_entities($price);
			$price=~s/\£//igs;
			$price=~s/\&pound\;//igs;
			$price=~s/\W+//igs;
			$price=~s/[a-zA-Z]+|\$//igs;
			$price=$price_text if(length($price)<2);	
			print "\nprice Text 3 :: $price_text\n";
			my $colorss;
			my $qcount=0;
			if($content2=~m/<h2\s*class\=\"product_colour_desc\">\s*([\w\W]*?)\s*<\/h2>/is)
			{
				my $temp_colour=~s/\///igs;
				$colorss=&upper_case_fist(lc($temp_colour));
			}
			# size & out_of_stock
			if ( $content2 =~ m/>\s*please\s*select\s*a\s*size\s*<\/option>\s*([\w\W]*?)\s*<\/select>/is )
			{
				my $size_content = $1;
				while ( $size_content =~ m/<option\s*[^>]*?class=\"([^\"]*?)\"\s*[^>]*?>\s*([^<]*?)\s*<\/option>/igs)
				{
					my $stock_text = $1;
					my $size =$2;
					my $out_of_stock;
					if ( $stock_text =~ m/\s*size_not_available\s*/is )
					{
						$out_of_stock = 'y';
					}
					else
					{
						$out_of_stock = 'n';
					}
					print "\nprice Text 4 :: $price_text\n";
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colorss,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$colorss;
					push(@query_string,$query);
					
					if($qcount == 0)
					{
						# $logger->send("$robotname SkuQuery :: $query");
						$qcount++;
					}
				}
			}
			if ( $content2 =~ m/<div\s*[^>]*?id=\"main_product_carousel\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
			{
				my $alt_image_content = $1;
				my $count;
				while ( $alt_image_content =~ m/<a\s*[^>]*?href=\"([^\"]*?)\"\s*[^>]*?>/igs )
				{
					$count++;
					my $alt_image =$1;
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					if ($count == 1)
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object} = $colorss;
						$hash_default_image{$img_object} = 'y';
						push(@query_string,$query);
					}
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object} = $colorss;
						$hash_default_image{$img_object} = 'n';
						push(@query_string,$query);
					}
				}
			}
		}
		else
		{
			$content2=$Final_cont;		
			my ($price,$price_text,$sub_category,$main_image,$alt_image,$out_of_stock,$colour);
			if ( $content2 =~ m/<div\s*[^>]*?class=\"product_price\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/div>/is )
			{
				my $price_Block =$1;
				#price
				if( $price_Block =~ m/<span\s*[^>]*?class=\"now_price\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/span>/is )
				{
					$price = $1;
				}
				else
				{
					$price=$price_Block;
					$price=~s/^\s+//igs;
				}
				#price_text
				$price_Block=~s/\&pound\;/\Â\£/igs;
				$price_text=Trim($price_Block);
			}
			$price=$price_text if(length($price)<2);		
			$price=~s/[a-zA-Z]+|\$//igs;
			print "\nprice Text 5 :: $price_text\n";
			my $qcount=0;
			# size & out_of_stock
			if ( $content2 =~ m/>\s*please\s*select\s*a\s*size\s*<\/option>\s*([\w\W]*?)\s*<\/select>/is )
			{
				my $size_content = $1;
				my @color_code = keys %color_hash;
				foreach my $code (@color_code)
				{
					my $C_code= Trim($1) if ($code =~ m/\s*\d+\-\s*(\d+)\s*/is);
					
					while ( $size_content =~ m/<option\s*[^>]*?value=\"$C_code\d+\"\s*[^>]*?class=\"([^\"]*?)\"\s*[^>]*?>\s*([^<]*?)\s*<\/option>/igs)
					{
						my $stock_text = Trim($1);
						my $size = Trim($2);
						my $out_of_stock;
						if ( $stock_text =~ m/\s*size_not_available\s*/is )
						{
							$out_of_stock = 'y';
						}
						else
						{
							$out_of_stock = 'n';
						}
						$price=~s/\&nbsp\;//igs;
						#$price=decode_entities($price);
						$price=~s/\£//igs;
						$price=~s/\&pound\;//igs;
						$price=~s/\W+//igs;
						print "\nprice Text 6 :: $price_text\n";
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color_hash{$code};
						push(@query_string,$query);
						
						if($qcount == 0)
						{
							# $logger->send("$robotname SkuQuery :: $query");
							$qcount++;
						}
					}
					if ( $content2 =~ m/<div\s*[^>]*?id=\"main_product_carousel\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
					{
						my $alt_image_content = $1;
						my $count;
						while ( $alt_image_content =~ m/<a\s*[^>]*?href=\"([^\"]*?)\"\s*[^>]*?>/igs )
						{
							$count++;
							my $alt_image =$1;
							my ($imgid,$img_file);
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							my $res2;				
							if ( $count == 1 )
							{
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object} = $color_hash{$code};
								$hash_default_image{$img_object} = 'y';
								push(@query_string,$query);
							}
							else
							{
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object} = $color_hash{$code};
								$hash_default_image{$img_object} = 'n';
								push(@query_string,$query);
							}
						}
					}		
				}
			}
		}
		#swatchimage
		foreach my $color_codes(keys %color_hash)
		{
			my $temp_code=$color_codes;
			$temp_code=~s/[\w\W]*?\-([\d]{6})([\d]*)/$1\\-$2/is;
			my $rep='<div\s*[^>]*?class=\"colour_swatch_inner\s*colour_swatch_inner_1\"\s*[^>]*?>\s*<img\s*[^>]*?src=\"([^>]*?'.$temp_code.'[^\"]*)\"\s*[^>]*?>';
			if ( $Final_cont =~ m/$rep/is )
			{
				my $swatch=$1;		
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object} = $color_hash{$color_codes};
				$hash_default_image{$img_object} = 'n';
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit;
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

sub upper_case_fist()
{
	my $string=shift;
	$string=lc($string);
	$string=~s/([\w']+)/\u\L$1/igs;
	return $string;
}
sub Trim()
{
    my $var=shift;
    $var=~s/<[^>]*?>//igs;
    $var=~s/&nbsp;/ /igs;
	#$var=decode_entities($var);
    $var=~s/\s+/ /igs;
	$var =~ s/^\s+//igs;
	$var =~ s/\s+$//igs;
	return ($var);
}