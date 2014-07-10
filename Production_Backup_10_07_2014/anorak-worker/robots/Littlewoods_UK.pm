#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Littlewoods_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Littlewoods_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger;
	
	####Variable Initialization##############
	$robotname='Littlewoods-UK--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Lit';
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
		$url3 =~ s/^\s+|\s+$//g;
		my @query_string;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.littlewoods.com'.$url3 unless($url3=~m/^\s*http\:/is);		
		my $content2 = &get_content($url3);
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		#price_text
		my ($was,$save,$now);
		if($content2=~m/priceWas\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is)
		{
			$was=&DBIL::Trim($1);
			
			if($content2=~m/priceNow\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>\s*<\/div>/is)
			{
				$now=&DBIL::Trim($1);
			}
			elsif($content2=~m/priceNow\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is)
			{
				$now=&DBIL::Trim($1);
			}			
			
			$was=~s/Â//igs;			
			$now=~s/Â//igs;
			# $was=~s/\£/\Â\£/igs;
			# $now=~s/\£/\Â\£/igs;
			
			$price_text=$was.' '.$now;
		}
		elsif($content2=~m/priceNow\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>\s*<\/div>/is)
		{
			$price_text = $1;
			$price_text=~s/Â//igs;
			# $price_text =~ s/\£/\Â\£/igs;
		}
		elsif($content2=~m/priceNow\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is)
		{
			$price_text = $1;
			$price_text=~s/Â//igs;
			# $price_text =~ s/\£/\Â\£/igs;
		}		
		#price
		if ( $content2 =~ m/sale_price\:\s*([^<]*?)\s*\}/is )
		{
			$price = $1;	
		}
		$price="null" if($price eq '.' or $price eq ' ' or $price eq ',');
		
		#product_id
		if ( $content2 =~ m/>\s*Item\s*Number\s*<[^>]*?>([\w\W]*?)\s*<\/span>/is)
		{
			$product_id = &DBIL::Trim($1);
			
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if ( $content2 =~ m/<h1[^>]*?>\s*([\w\W]*?)\s*<\/h1>|<meta\s*name\=\'keywords\'\s*content\=\'([^<]*?)\'/is )
		{
			$product_name = &DBIL::Trim($1.$2);
			
			$product_name=~s/&reg\;/®/igs;
			$product_name=~s/\&eacute\;/é/is;
			$product_name=~s/\&egrave\;/é/is;
			$product_name=~s/\&trade\;/™/igs;
			$product_name=~s/Â//igs;
			
			$product_name=decode_entities($product_name);
		}
		#Brand
		if( ( $content2 =~ m/productBrandName\"\s*value\=\"([^<]*?)\"/is ) || ($content2 =~ m/Brand\"\s*value\=\"([^<]*?)\"/is) || ($content2 =~ m/brand\">\s*([^<]*?)\s*<\/span>/is))
		{
			$brand = &DBIL::Trim($1);			
		}
		#description&details
		if($content2=~m/description\"\s*content\=\"([^<]*?)\"/is)
		{
			$prod_detail = &DBIL::Trim($1);
			$prod_detail=~s/\*//igs;
			$prod_detail=decode_entities($prod_detail);
		}
		
		if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
			$prod_detail = '-';
		}
		
		#colour
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my (@color_arr,@size_array);
		if ( $content2 =~ m/COLOUR<\/legend>([\w\W]*?)<\/fieldset>/is )
		{
			my $colour_content = $1;
			while($colour_content=~m/title\=\"([^<]*?)\"/igs)
			{
				my $color 		= &DBIL::Trim($1);
				$color =~ s/(\w+)/\u\L$1/g;	
				$color =~ s/\/(\w+)/\/\L$1/g;
				push(@color_arr,$color);
			}
			if(!@color_arr)
			{
				while($colour_content=~m/<label\s*for\=\"frmCOLOUR([^<]*?)\"/igs)
				{
					my $color 		= &DBIL::Trim($1);
					$color =~ s/(\w+)/\u\L$1/g;
					$color =~ s/\/(\w+)/\/\L$1/g;
					push(@color_arr,$color);
				}
			}
		}
		# size & out_of_stock
		
		my $StockMatrix=$1 if($content2=~m/stockMatrix\s*=\s*\[([\w\W]*?)\]\;/is);
		
		my $leg_inch_content=$1 if($content2=~m/INSIDE\s*LEG<\/legend>([\w\W]*?)<\/fieldset>/is);
		
		if($content2=~m/(?:age|size|chest|bust|waist)[^<]*?<\/legend>([\w\W]*?)<\/fieldset>/is)
		{
			my $size_content = $1;
			foreach my $color (@color_arr)
			{
				while($size_content=~m/rel\=\"([^<]*?)\"/igs)
				{
					my $size = &DBIL::Trim($1);
					
					####Duplicate Size######
					if(grep( /^lc($size)$/, @size_array ))
					{
						next;
					}
					push(@size_array,lc($size));
					
					my $size1=$size;
					$size1=~s/\(/\\(/igs;
					$size1=~s/\)/\\)/igs;
					
					#### If the product has Leg Inch########				
					
					if($leg_inch_content ne "")
					{
						while($leg_inch_content=~m/rel\=\"([^<]*?)\"/igs)
						{
							my $inch = &DBIL::Trim($1);
							
							my $inch1=$inch;
							$inch1=~s/\=/\\=/igs;

							####Stock and Price details
							my ($stock,$stock_price,$out_of_stock);
							if($StockMatrix=~m/\[\"$size1\"\,\"(?:$inch1\"\,\")?$color\"\,\"sku[\d]*\"\,\"(?:\,\"([^<]*?)\")?/is)
							{
								$stock = &DBIL::Trim($1);
								$stock_price = &DBIL::Trim($2);
							}						
							if($stock=~m/Out\s*of\s*stock/is)
							{
								$out_of_stock = 'y';
							}
							else
							{
								$out_of_stock = 'n';
							}
							###If price varies by Sku
							if($stock_price ne '')
							{
								$price=$stock_price;								
							}
							
							my $size_inch=$inch." ".$size;
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size_inch,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=lc($color);
							push(@query_string,$query);
						}
					}
					else
					{
						####Stock and Price details
						my ($stock,$stock_price,$out_of_stock);
						if($StockMatrix=~m/\[\"$size1\"\,\"(?:$color\"\,\")?sku[\d]*\"\,\"([^<]*?)\"(?:\,\"([^<]*?)\")?/is)
						{
							$stock = &DBIL::Trim($1);
							$stock_price = &DBIL::Trim($2);
						}						
						if($stock=~m/Out\s*of\s*stock/is)
						{
							$out_of_stock = 'y';
						}
						else
						{
							$out_of_stock = 'n';
						}
						###If price varies by Sku
						if($stock_price ne '')
						{
							$price=$stock_price;							
						}
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=lc($color);
						push(@query_string,$query);
					}
				}				
				
			}
			if(!@color_arr)
			{
				while($size_content=~m/rel\=\"([^<]*?)\"/igs)
				{
					my $size = &DBIL::Trim($1);
					
					####Duplicate Size######
					if(grep( /^lc($size)$/, @size_array ))
					{
						next;
					}
					push(@size_array,lc($size));
					
					my $size1=$size;
					$size1=~s/\(/\\(/igs;
					$size1=~s/\)/\\)/igs;
					
					####Stock and Price details
					my ($stock,$stock_price,$out_of_stock);
					if($StockMatrix=~m/\[\"$size1\"\,\"sku[\d]*\"\,\"([^<]*?)\"(?:\,\"([^<]*?)\")?/is)
					{
						$stock = &DBIL::Trim($1);
						$stock_price = &DBIL::Trim($2);
					}						
					if($stock=~m/Out\s*of\s*stock/is)
					{
						$out_of_stock = 'y';
					}
					else
					{
						$out_of_stock = 'n';
					}					
					###If price varies by Sku
					if($stock_price ne '')
					{
						$price=$stock_price;
					}
					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,"",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}='No colour';
					push(@query_string,$query);
				}
			}
		}
		else
		{
			foreach my $color (@color_arr)
			{
				my $out_of_stock = 'n';
				
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"",$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=lc($color);	
				push(@query_string,$query);	
				
			}
			if(!@color_arr)
			{
				if($content2 =~ m/stockMatrix\s*=\s*\[\s*\[\"[^\"]*?\"\,\"([Out\s*of\s*stock]*?)\"\s*\,/is)
				{
					$out_of_stock= 'y';
				}
				else
				{
					$out_of_stock= 'n';
				}
				
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"","",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}='No colour';
				push(@query_string,$query);
			}
		}
		
		#Direct Image
		my @direct_image;
		my $default_color;
		my $direct_img=$1 if($content2=~m/image\"\s*content\=\"([^<]*?)\"/is);
		
		if($direct_img=~m/([^<]*?littlewoods\/[^<]*?)\//is)
		{
			$direct_img=$1.'?$1064x1416_standard$';
		}
		
		my $direct_img1=$direct_img;
		$direct_img1=~s/\?\$1064x1416_standard\$//igs;
		
		if($content2=~m/COLOUR<\/legend>([\w\W]*?)<\/fieldset>/is)
		{
			my $alt_image_content = $1;
			
			while($alt_image_content=~m/<input\s*name\=\"\s*([^<]*?)\"\s*class[^<]*?value\=\"([^<]*?)\"/igs)
			{
				my $img_col=&DBIL::Trim($1);
				my $alt_part = &DBIL::Trim($2);				
				
				my $alt_image='http://media.littlewoods.com/i/littlewoods/'.$alt_part.'?$1064x1416_standard$';
				
				my $alt_image1=$alt_image;				
				$alt_image1=~s/\?\$1064x1416_standard\$//igs;
				
				####Duplicate Image######
				if(grep( /^$alt_image1$/, @direct_image ))
				{					
					next;
				}
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);				
				if($alt_image1 eq $direct_img1)
				{
					$default_color=$img_col;
					
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=lc($img_col);
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);	
				}
				else
				{
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=lc($img_col);
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);	
				}
				
				push(@direct_image,$alt_image1);
			}
			unless(grep( /^$direct_img1$/, @direct_image ))
			{	
				my ($imgid,$img_file) = &DBIL::ImageDownload($direct_img,'product',$retailer_name);				
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$direct_img,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}='No colour';
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
				push(@direct_image,$direct_img1);
			}
			
		}
		if(!@color_arr)
		{
			my ($imgid,$img_file) = &DBIL::ImageDownload($direct_img,'product',$retailer_name);			
			
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$direct_img,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}='No colour';
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);
			push(@direct_image,$direct_img1);
		}
		#Other Image
		if($content2=~m/<ul\s*id\=\"amp-thumbnails\">([\w\W]*?)<\/ul>/is)
		{
			my $alt_image_content1 = $1;
			
			while ( $alt_image_content1 =~ m/<a\s*target[^<]*?href\=\"([^<]*?)\"/igs)
			{
				my $alt_image = &DBIL::Trim($1);
				
				my $alt_image1=$alt_image;
				$alt_image1=~s/\?\$1064x1416_standard\$//igs;				
				
				####Duplicate Image######
				if(grep( /^$alt_image1$/, @direct_image ))
				{					
					next;					
				}
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				if($default_color ne '')
				{
					$image_objectkey{$img_object}=lc($default_color);
				}
				else
				{
					$image_objectkey{$img_object}='No colour';
				}
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
		}
		#swatchimage
		if($content2=~m/COLOUR<\/legend>([\w\W]*?)<\/fieldset>/is)
		{
			my $swatch_content = $1;
			while($swatch_content=~m/src\=\"([^<]*?)\"[^<]*?title\=\"([^<]*?)\"/igs)
			{
				my $swatch=&DBIL::Trim($1);
				my $swatch_color=&DBIL::Trim($2);
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
				$image_objectkey{$img_object}=lc($swatch_color);
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url,$retailer_id);
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
