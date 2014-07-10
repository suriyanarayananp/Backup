#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Bloomingdales_US;
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
sub Bloomingdales_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Bloomingdales-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Blo';
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
		my $content2 = get_content($url3);
		if($content2=~m/This\s*product\s*is\s*currently\s*unavailable|currently\s*unavailable\.\s*Please\s*check\s*back\s*later/is)
		{
			goto PNF;
		}
		my %tag_hash;
		my %prod_objkey;
		my %size_hash;
		my %color_hash;
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		
		#product_id
		if ( $content2 =~ m/>\s*web\s*id\:([^<]*?)\s*</is )
		{
			$product_id = trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if ( $content2 =~ m/cleanProductDescription\s*=\s*\"([^\"]*?)\"/is )
		{
			$product_name = trim($1);
		}
		#Brand
		if ( $content2 =~ m/product_brand\s*\:\s*\[\"([\w\W]*?)\"\]?/is )
		{
			$brand = trim($1);
			if ( $brand !~ /^\s*$/igs )
			{
				&DBIL::SaveTag('Brand',lc($brand),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			}
		}
		
		#description&details
		if ( $content2 =~ m/(<div\s*class=\"pdp_longDescription\"\s*itemprop=\"description\">\s*[\w\W]*?\s*<\/ul>\s*<\/div>)/is )
		{
			my $desc_content = $1;
			if ( $desc_content =~ m/>([\w\W]*?)<\/div>\s*<ul>([\w\W]*?)<\/ul>\s*<\/div>/is )
			{
				$description = trim($1);
				$prod_detail = trim($2);
			}
			else
			{
				$description = trim($desc_content);
				$prod_detail = trim($desc_content);
			}
		}
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my %duplicate_color;
		my $product_name1;
		my $con=$content2;
		######## TO HAVE ALL SKUS ###
		my $mflag=0;
		my $no_colour_size_flag=0;
		if($content2 =~ m/\{\"productID\"\:\s*\"([^>]*?)\"\s*\,\s*\"swatchLength\"\:[\d]+\s*\}/is) #Multi Product
		{
			$mflag=1;
			goto PNF;
		}
		else 
		{
			my $price_text;
			
			###price_text
			if($content2=~m/<div\s*class\=\"priceSale\">([\w\W]*?)<input[^<]*?class\=\"netPrice\"[^<]*?>/is)
			{
				$price_text = trim($1);
			}
			
			###price
			if ( $content2 =~ m/class=\"pricesale\">\s*(?:NOW|sale)\s*\$([\d\.\,]*?)<\/span>/is )
			{
				$price = trim($1);
			}
			elsif ( $content2 =~ m/class=\"priceBig\">\s*\$([\d\.\,]*?)<\/span>/is )
			{
				$price = trim($1);
			}
			elsif ( $content2 =~ m/class=\"priceBig\">\s*\$([^<]*?)<\/span>/is )
			{
				$price = trim($1);
				if ( $price =~ m/\-/is )
				{
					$price = (split('\-',$price))[0];
				}
			}
			$price=~s/\,//igs;
			#$price_text=~s/PRICE\s*\://igs;
			my @size_array;
			# Size
			if ( $content2 =~ m/<ul\s*id=\"sizeList[^>]*?\">([\W\w]*?)<\/ul>/is )	
			{
				my $size_cont = $1;
				while($size_cont =~m/<li\s*title=\"([^\"]*?)"[^>]*?>\s*<span>\s*[^<]*?<\/span>/igs)
				{
					my $siz = trim($1);
					if($siz ne '')
					{
						push (@size_array , $siz);
					}
				}
			}
			elsif($content2 =~ m/<span\s*id\=\"selectedSize[^<]*?>\s*([^<]*?)\s*<\/span>/is )
			{
				my $siz = trim($1);
				$siz='' if($siz=~m/select\s*size/is);
				if($siz ne '')
				{
					push (@size_array , $siz);
				}
			}
			
			### Color Codes and Color
			if ( $content2 =~ m/(swatchmap[\w\W]*?\s*\]\;)/is )
			{
				my $swatch_content = $1;
				$swatch_content =~s/\s+/ /igs;
				if($swatch_content =~m/Color/is)
				{
					while ( $swatch_content =~ m/\{\"color\"\:\s*\"([^\"]*?)\"\s*\,\"value\"\:\s*\"([^\"]*?)\"\s*\}/igs )
					{
						my $color 		= trim($1);
						my $color_code 	= trim($2);
						$color_hash{$color_code} = trim($color);
					}
				}
				elsif($content2 =~ m/<span\s*id=\"([^\"]*?)\">\s*COLOR\:\s*<\/span>\s*<[^>]*?>\s*([^<]*?)<\/span>/is)
				{
					my $color_code 	= trim($1);
					my $color 		= trim($2);
					$color_hash{$color_code} = trim($color);
				}
			}
			my $no_colour_size_flag=0;
			########################################
			###size & out_of_stock
			my @color_code = keys %color_hash;
			my $color_size = $#color_code;
			$color_size = $color_size +1;
			
			if(@size_array and @color_code)
			{
				foreach my $size (@size_array)
				{
					foreach my $code (@color_code)
					{
						my $temp_colour=$color_hash{$code};
						$temp_colour=quotemeta($temp_colour);
						if($content2 =~ m/{\s*\"upcID\"\:\s*([\d]+)\,[^<]*?color\"\:\s*\"\s*($temp_colour)\s*\"\,\s*\"size\"\:\s*\"($size)\"\,\s*\"type\"\:\s*\"[^\"]*?\"\,\"upc\"\:\s*\"[^\"]*?"\,\s*\"([^\"]*?)\"\:[^\}]*}/is)
						{
							$out_of_stock='n';
						}
						else
						{
							my $out_of_stock='y';
						}
						
						my $dup_check=$temp_colour.$size;
						$dup_check=~s/\W//igs;
						if($duplicate_color{$dup_check} eq '')
						{
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$product_id;
							push(@query_string,$query);
							$duplicate_color{$dup_check}=1;
						}
					}
				}
			}
			elsif(@color_code)
			{
				foreach my $code (@color_code)
				{
					my $temp_colour=$color_hash{$code};
					$temp_colour=quotemeta($temp_colour);
					
					while ( $content2 =~ m/{\s*\"upcID\"\:\s*([\d]+)\,[^<]*?color\"\:\s*\"\s*($temp_colour)\s*\"\,\s*\"size\"\:\s*\"([\w\W]*?)\"\,\s*\"type\"\:\s*\"[^\"]*?\"\,\"upc\"\:\s*\"[^\"]*?"\,\s*\"([^\"]*?)\"\:[^\}]*}/igs) #regex updated
					{
						my $Color = trim($2);
						my $stock_text = trim($4);
						if ( $stock_text =~ m/isAvailable/is )
						{
							$out_of_stock = 'n';
						}
						else
						{
							$out_of_stock = 'y';
						}
						
						my $dup_check=$Color;
						$dup_check=~s/\W//igs;
						if($duplicate_color{$dup_check} eq '')
						{
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'',$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$product_id;
							push(@query_string,$query);
							$duplicate_color{$dup_check}=1;
						}
					}
				}
			}
			else
			{
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'','','',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$product_id;
				$no_colour_size_flag=1;
				push(@query_string,$query);
			}
			
			##################################################
		}
		##### Here the SKU details ENDS
		#swatchimage
		my $swatch_link;
		if ( $content2 =~ m/<input\s*type=\"hidden\"\s*id=\"BLM_imageHostName\"\s*value=\"([^\"]*?)\"\s*\/>/is )
		{
			$swatch_link = $1.'/'; 
		}
		if ( $content2 =~ m/(swatchmap[\w\W]*?\}\s*\]\;)/is )
		{
			my $swatch_content = $1;
			while ( $swatch_content =~ m/\{\"color\"\:\s*\"([^\"]*?)\"\s*\,\"value\"\:\s*\"([^\"]*?)\"\s*\}/igs )
			{
				my $color=trim($1);
				my $swatch = trim($2);
				unless($swatch=~m/^\s*http\:/is)
				{
					$swatch='http://images.bloomingdales.com/is/image/BLM/products/'.$swatch;
				}
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$product_id;
				$hash_default_image{$img_object} = 'n';
				push(@query_string,$query);
			}
		}
		#Default Image
		
		if ( $content2 =~ m/primaryImages\[[\d]+\]\s*\=\s*\{([^<]*?)\}\;/is )
		{
			my $pri_image_block=$1;
			if($pri_image_block ne '')
			{
				while($pri_image_block=~m/\'([^<]*?)\'\:\'([^<]*?)\'/igs)
				{
					my $colour=$1;
					my $pri_image=$2;
					if($pri_image=~m/\,/is)
					{
						while($pri_image=~m/([\d]\/[^<]*?\.tif)/igs)
						{
							my $pri_image="$swatch_link"."products/".$1;
							my ($imgid,$img_file) = &DBIL::ImageDownload($pri_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$pri_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object} = $product_id;;
							$hash_default_image{$img_object} = 'y';
							push(@query_string,$query);
						}
					}
					else
					{
						$pri_image="$swatch_link"."products/"."$pri_image";
						my ($imgid,$img_file) = &DBIL::ImageDownload($pri_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$pri_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
						$hash_default_image{$img_object} = 'y';
						push(@query_string,$query);
					}
				}
			}
			elsif($content2=~m/productLvlPrimaryImage\s*=\s*"([^<]*?)\"\;/is)
			{
				if($1 ne '')
				{
					my $pri_image="$swatch_link"."products/".$1;
					my ($imgid,$img_file) = &DBIL::ImageDownload($pri_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$pri_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_id;
					$hash_default_image{$img_object} = 'y';
					push(@query_string,$query);
				}
			}
		}
		#Alternate Images
		if ( $content2 =~ m/additionalImages\[[\d]+\]\s*\=\s*\{([^<]*?)\}\;/is )
		{
			my $alt_image_block=$1;
			if($alt_image_block ne '')
			{
				while($alt_image_block=~m/\'([^<]*?)\'\:\'([^<]*?)\'/igs)
				{
					my $colour=$1;
					my $alt_image=$2;
					if($alt_image=~m/\,/is)
					{
						while($alt_image=~m/([\d]\/[^<]*?\.tif)/igs)
						{
							my $alt_image="$swatch_link"."products/".$1;
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$product_id;
							$hash_default_image{$img_object} = 'n';
							push(@query_string,$query);
						}
					}
					else
					{
						$alt_image="$swatch_link"."products/"."$alt_image";
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
						$hash_default_image{$img_object} = 'n';
						push(@query_string,$query);
					}
				}
			}
			elsif($content2=~m/productLvlAddImgs\s*=\s*\"([^<]*?)\"\;/is)
			{
				if($1 ne '')
				{
					my $alt_image="$swatch_link"."products/".$1;
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_id;
					$hash_default_image{$img_object} = 'n';
					push(@query_string,$query);
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
		PNF:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit;
	}
}1;

sub get_content
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
			sleep rand 5;
			goto Home;
		}
	}
	return $content;
}

sub trim
{
	my $txt = shift;
	$txt =~ s/\<[^>]*?\>/ /igs;
	$txt =~ s/\n+/ /igs;
	$txt =~ s/\"/\'\'/igs;
	$txt =~ s/&#039;/\'/igs;
	$txt =~ s/\s+/ /igs;
	$txt =~ s/\&nbsp\;/ /igs;
	$txt =~ s/\&amp\;/\&/igs;
	$txt =~ s/\&bull\;/•/igs;
	$txt =~ s/^\s+|\s+$//igs;
	return $txt;
}
