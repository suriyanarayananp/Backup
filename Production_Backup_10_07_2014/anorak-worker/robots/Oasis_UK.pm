#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Oasis_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
#require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Oasis_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;
	$robotname='Oasis-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Oas';
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
	my $skuflag = 0;my $imageflag = 0;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.oasis-stores.com/'.$url3 unless($url3=~m/^\s*http\:/is);
		my $Final_cont=&get_content($url3);		
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($description,$prod_detail,$product_id);
		#product_id
		if ($url3=~m/\s*(?:[^\/]*?\/)+\s*(\d{8})[^<]*?\s*$/is)
		{
			$product_id =&Trim($1); 
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		my $product_name = &Trim($1) if($Final_cont =~ m/<h1\s*[^>]*?id=\"product_title\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/h1>/is);
		
		if($product_name eq '')
		{
			goto next_product;
		}
		
		#Brand
		my $brand=&Trim($1) if ($Final_cont=~m/<input\s*[^>]*?name=\"brand\"\s*[^>]*?value=\"([^\"]*?)\"\s*[^>]*?>/is);
		if($brand ne '')
		{
			&DBIL::SaveTag('Brand',lc($brand),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		}	
		
		#description
		if( $Final_cont =~ m/<dd\s*[^>]*?class=\"description\s*open\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/dd>/is )
		{
			$description = &Trim($1);		
		}
		#details
		if ( $Final_cont =~ m/<dd\s*[^>]*?class=\"product_specifics\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/dd>/is )
		{
			$prod_detail = $1;
			$prod_detail =~ s/<\/p>/ | /igs;		
			$prod_detail = &Trim($prod_detail);	
			$prod_detail =~ s/(?:\s*\|\s*)+/ | /igs;	
			$prod_detail =~ s/(?:\s*\:\s*)+/:/igs;	
			$prod_detail =~ s/\s*\|\s*$//igs;	
			$prod_detail =~ s/\s*\:\s*$//igs;
			$prod_detail = &Trim($prod_detail);			
		}
		#colour
		my $C_count=0;
		if($Final_cont =~ m/<div\s*[^>]*?id=\"colour_variants\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/div>/is)
		{
			my $colour_content = $1;
			my @total_colour; my %temp_hash;
			while( $colour_content =~ m/<li[^>]*?>\s*([\w\W]*?)\s*<img\s*[^>]*?class=\"product_image\"\s*[^>]*?src=\"[^\"]*?\/swatch\/([^\"]*?)\.jpg\"\s*[^>]*?>/igs )
			{
				my $color= $1;
				my $color_code= &Trim($2);
				$color=~s/triangle//igs;
				$color=&Trim($color);
				$C_count++;
				
				if(grep( /$color/, @total_colour ))
				{
					$temp_hash{$color}++;
					my $tcolor = $color.'('.$temp_hash{$color}.')';
					$color_hash{$color_code} =$tcolor;
					push @total_colour,$tcolor;
				}
				else
				{
					$color_hash{$color_code} =$color;
					push @total_colour,$color;
					$temp_hash{$color}++;
				}
			}
		}
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my $content2;
		if($C_count>1)
		{
			my @color_code = keys %color_hash;
			foreach my $code(@color_code)
			{
				my $url=$1 if($url3=~ m/\s*((?:[^\/]*?\/)+)\s*[^<]*?\s*$/is);
				$url=$url.$code;
				my $content2=&get_content($url);		
				
				my ($price,$price_text,$sub_category,$main_image,$alt_image,$out_of_stock);
				
				if ( $content2 =~ m/<p\s*[^>]*?class=\"product_price\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/p>/is )
				{
					my $price_Block =$1;
					if( $price_Block =~ m/<span\s*[^>]*?class=\"(?:now|rpr|single)\"\s*[^>]*?>\s*((?!Original)[\w\W]*?)\s*<\/span>/is )
					{
						$price = $1;
						$price=~s/\&pound\;//igs;
						$price=Trim($price);
					}
					elsif($price_Block =~ m/price\s*\:\s*\W\s*([\d\.]+)/is)
					{
						$price = $1;
						$price=~s/\&pound\;//igs;
						$price=Trim($price);
					}
					elsif($price_Block =~ m/price\s*\:\s*[^<]*?\s*([\d\.]+)/is)
					{
						$price = $1;
						$price=~s/\&pound\;//igs;
						$price=Trim($price);
					}
					else
					{
						$price = $price_Block;
						$price=~s/\&pound\;//igs;
						$price=Trim($price);
					}
					#price_text
					$price_Block=~s/\&pound\;/\Â\£/igs;
					$price_text=&Trim($price_Block);
					#$price_text=decode_entities($price_text);
					#$price_text=~s/^\s*Price\s*\:\s*//igs;
					$price_text=~s/^\s*\:\s*//igs;
				}					
				$price=$price_text if(length($price)<2);
				$price=~s/[a-zA-Z]+|\$|\£//igs;
				$price=~s/^\s*\:\s*//igs;
				my $qcount=0;
				# size & out_of_stock
				if ( $content2 =~ m/<div\s*[^>]*?id=\"select_size\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/ul>/is )
				{
					my $size_content = $1;
					while ( $size_content =~ m/<li\s*[^>]*?class=\"([^\"]*?)\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/li>/igs)
					{
						my $stock_text = &Trim($1);
						my $size = &Trim($2);
						my $out_of_stock;
						if ( $stock_text =~ m/\s*no_stock\s*|\s*low_stock\s*/is )
						{
							$out_of_stock = 'y';
						}
						else
						{
							$out_of_stock = 'n';
						}
						print "\nPrice Text :: $price_text\n";
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$code;
						push(@query_string,$query);
						if($qcount == 0)
						{
							# $logger->send("$robotname SkuQuery :: $query");
							$qcount++;
						}
					}
				}
				if ( $content2 =~ m/<img\s*[^>]*?class=\"product_image\"\s*[^>]*?id=\'main_image\'\s*[^>]*?src=\"([^\"]*?)\"[^>]*?>/is )
				{
					my $alt_image =$1;
					my $res2;				
					my $NextImage=$alt_image;
					$NextImage=~s/\s*\.jpg\s*$//igs;
					$NextImage=~s/\/xlarge\//\/small\//igs;
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$code;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
					my $count;
					my $flag=1;
					while ($flag)
					{
						$count++;
						my $alt_image =$NextImage.'_'.$count.'.jpg';
						my $Img_Status=&Img_Status($alt_image);
						if($Img_Status==1)
						{
							$alt_image=~s/\/small\//\/xlarge\//igs;
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object} = $code;
							$hash_default_image{$img_object} = 'n';
							push(@query_string,$query);
						}
						else
						{
							$flag=0;
						}
					}
				}
			}
		}
		else
		{
			$content2=$Final_cont;
			my ($price,$price_text,$sub_category,$main_image,$alt_image,$out_of_stock);
			my @color_code = keys %color_hash;
			my $code=$color_code[0];
			if ( $content2 =~ m/<p\s*[^>]*?class=\"product_price\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/p>/is )
			{
				my $price_Block =$1;
				#price
				if( $price_Block =~ m/<span\s*[^>]*?class=\"(?:now|rpr|single)\"\s*[^>]*?>\s*((?!Original)[\w\W]*?)\s*<\/span>/is )
				{
					$price = $1;
					$price=~s/\&pound\;//igs;
					$price=Trim($price);
				}
				elsif($price_Block =~ m/price\s*\:\s*\W\s*([\d\.]+)/is)
				{
					$price = $1;
					$price=~s/\&pound\;//igs;
					$price=Trim($price);
				}
				elsif($price_Block =~ m/price\s*\:\s*[^<]*?\s*([\d\.]+)/is)
				{
					$price = $1;
					$price=~s/\&pound\;//igs;
					$price=Trim($price);
				}
				else
				{
					$price = $price_Block;
					$price=~s/\&pound\;//igs;
					$price=Trim($price);
				}
				#price_text
				$price_Block=~s/\&pound\;/\Â\£/igs;
				$price_text=&Trim($price_Block);
				#$price_text=decode_entities($price_text);
				#$price_text=~s/^\s*Price\s*\:\s*//igs;
				$price_text=~s/^\s*\:\s*//igs;
			}					
			$price=$price_text if(length($price)<2);
			$price=~s/[a-zA-Z]+|\$|\£//igs;
			$price=~s/^\s*\:\s*//igs;
			my $qcount=0;
			# size & out_of_stock
			if ( $content2 =~ m/<div\s*[^>]*?id=\"select_size\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/ul>/is )
			{
				my $size_content = $1;
				while ( $size_content =~ m/<li\s*[^>]*?class=\"([^\"]*?)\"\s*[^>]*?>\s*([\w\W]*?)\s*<\/li>/igs)
				{
					my $stock_text = &Trim($1);
					my $size = &Trim($2);
					my $out_of_stock;
					if ( $stock_text =~ m/\s*no_stock\s*|\s*low_stock\s*/is )
					{
						$out_of_stock = 'y';
					}
					else
					{
						$out_of_stock = 'n';
					}
					print "\nPrice Text :: $price_text\n";
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$code;
					push(@query_string,$query);
					if($qcount == 0)
					{
						# $logger->send("$robotname SkuQuery :: $query");
						$qcount++;
					}
				}
			}
			if ( $content2 =~ m/<img\s*[^>]*?class=\"product_image\"\s*[^>]*?id=\'main_image\'\s*[^>]*?src=\"([^\"]*?)\"[^>]*?>/is )
			{
				my $alt_image =$1;
				my $res2;				
				my $NextImage=$alt_image;
				$NextImage=~s/\s*\.jpg\s*$//igs;
				$NextImage=~s/\/xlarge\//\/small\//igs;
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$code;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
				my $count;
				my $flag_test=1;
				while ($flag_test)
				{
					$count++;
					my $alt_image =$NextImage.'_'.$count.'.jpg';
					my $Img_Status=&Img_Status($alt_image);
					if($Img_Status==1)
					{
						$alt_image=~s/\/small\//\/xlarge\//igs;
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object} = $code;
						$hash_default_image{$img_object} = 'n';
						push(@query_string,$query);
					}
					else
					{
						$flag_test=0;
					}									
				}
			}
		}
		
		#swatchimage
		if ( $Final_cont =~ m/<img\s*[^>]*?class=\"product_image\"\s*[^>]*?src=\"([^\"]*?\/swatch\/[^\"]*?)\"[^>]*?>/is )
		{
			while ( $Final_cont =~ m/<img\s*[^>]*?class=\"product_image\"\s*[^>]*?src=\"([^\"]*?\/swatch\/[^\"]*?)\"[^>]*?>/igs )
			{
				my $swatch=$1;
				my $code;
				if($swatch=~m/swatch\/([^\"]*?)\.jpg/is)
				{
					$code=$1;
				}
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$code;
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
		next_product:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit;
	}
}1;
#------------------------------------------------	Methods	-------------------------------------------------------------------
sub get_content()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
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
			sleep 5;
			goto Home;
		}
	}
	return $content;
}
sub Img_Status()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	open JJ,">>$retailer_file";
	print JJ "$url->$code\n";
	close JJ;

	if($code == 200)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub Trim
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
