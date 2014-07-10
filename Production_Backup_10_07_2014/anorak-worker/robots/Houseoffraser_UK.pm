#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Houseoffraser_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use URI::Escape;
use HTTP::Cookies;
use DBI;
use utf8;
#require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Houseoffraser_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$dbh->do("set character set utf8");
	$dbh->do("set names utf8");
	my @query_string;
	$robotname='Houseoffraser-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Hou';
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
	if($product_object_key)
	{
		my $skuflag = 0;
		my $imageflag = 0;
		my $mflag=0;	
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;	
		my $content2 = &GetContent($url3);
		$content2=decode_entities($content2);
		if($content2=~m/>\s*Sorry[^>]*?looking[^>]*?</is)
		{
			goto PNF;
		}
		elsif($content2=~m/>\s*Sorry[^>]*?this\s*item\s*is\s*not\s*available\s*at\s*the\s*moment\s*</is)
		{
			goto PNF;
		}
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;	
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock);
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		
		#product_id
		#if($content2=~m/<div[^>]*?class\=\"desc[^>]*?>\s*Product\s*code\s*\:\s*([^>]*?)\s*</is)
		if($content2=~m/<div[^>]*?class\=\"desc[^>]*?>\s*Product\s*code\s*\:\s*(?:\&nbsp\;\s*)*([^>]*?)\s*</is)		
		{
			$product_id=$1;
			$product_id=~s/<[^>]*?>/ /igs;
			$product_id=~s/(?:\h)+/ /s;
			$product_id=~s/\s+/ /igs;
			$product_id=~s/^\s+//is;
			$product_id=~s/\s+$//is;
			$product_id=~s/\'/''/igs;
			$product_id=~s/\'/''/igs;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key,$dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		# elsif($content2=~m/<\/h1>\s*<p[^>]*?class\=\"product\-code[^>]*?>\s*Product\s*code\s*\:\s*([\w\W]*?)\s*<\/p>/is)
		elsif($content2=~m/<\/h1>\s*<p[^>]*?class\=\"product[^>]*?>[^>]*?Code\s*\:\s*(?:<[^>]*?>\s*)*([^>]*?)\s*(?:<[^>]*?>\s*)*<\/p>/is)
		{
			$product_id=$1;
			$product_id=~s/<[^>]*?>/ /igs;
			$product_id=~s/(?:\h)+/ /s;
			$product_id=~s/\s+/ /igs;
			$product_id=~s/^\s+//is;
			$product_id=~s/\s+$//is;
			$product_id=~s/\'/''/igs;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key,$dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		if($product_id=~m/^\s*$/is)
		{
			if($content2=~m/<input[^>]*?name="masterproduct_pid"[^>]*?value="([^>"]*?)"\s*\/*\s*>/is)		
			{
				$product_id=$1;
				$product_id=~s/(?:\h)+/ /s;
				$product_id=~s/\s+/ /igs;
				$product_id=~s/^\s+//is;
				$product_id=~s/\s+$//is;
				$product_id=~s/\'/''/igs;
				my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key,$dbh,$robotname,$retailer_id);
				goto LAST if($ckproduct_id == 1);
				undef ($ckproduct_id);
			}
		}	
		#product_name
		if($content2=~m/<span[^>]*?\"product\-name\"[^>]*?>\s*([\w\W]*?)<\/h/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		elsif($content2=~m/<span[^>]*?itemprop\=\"name[^>\"]*?\"[^>]*?>\s*([\w\W]*?)<\/h/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		utf8::decode($product_name);		
		#description
		# if ( $content2 =~ m/<h3>Product\s*Details<\/h3>\-\-\>\s*<p\s*class\=\"short\-description\">\s*(?<Product_Desc>[^>]*?(?:<[^>]*?>[^>]*?)*?)\s*<\/p>/is )
		# {		
			# $description = &DBIL::Trim($1);			
		# }
		
		#details
		if ($content2 =~ m/itemprop\=\"description\"[^>]*?>([\w\W]*?)<\/span>/is)
		{
			$prod_detail = $1;
			$prod_detail =~s/<li[^>]*?>/ * /igs;
			$prod_detail=&DBIL::Trim($prod_detail);
			utf8::decode($prod_detail);
		}
		
		# Brand
		# if($content2=~m/<span[^>]*?\"brandname\"[^>]*?>\s*([\w\W]*?)\s*<\/span>/is)
		if($content2=~m/\;\s*brandOfProduct\s*=\s*\'([^>]+?)\'\s*\;/is)
		{
			$brand = &DBIL::Trim($1);
			$brand=~s/\\//igs;
			$brand=~s/^\s+//is;
			$brand=~s/\s+$//is;
		}
		if($brand=~m/^\s*$/is)
		{
			# if($content2=~m/\;\s*brandOfProduct\s*=\s*\'([^>]+?)\'\s*\;/is)
			if($content2=~m/<span[^>]*?\"brandname\"[^>]*?>\s*([\w\W]*?)\s*<\/span>/is)
			{
				$brand = &DBIL::Trim($1);
			}		
			# elsif($content2=~m/\"productBrand\"\s*\:\s*\"([^>]*?)\"\s*\,/is)
			elsif($content2=~m/\"productBrand\"\s*\:\s*\"([^>]*?)\"\s*\,/is)
			{
				$brand = &DBIL::Trim($1);
				$brand=uri_unescape($brand);
			}		
			$brand=~s/\\//igs;
			$brand=~s/^\s+//is;
			$brand=~s/\s+$//is;
		}
		utf8::decode($brand);
		&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid) if($brand ne '');
		
		#Out_of_stock
		$out_of_stock='n';
		if($content2=~m/itemprop\=\"availability\"[^>]*?content\=\"([^>]*?)\"/is)
		{
			my $stock_status=$1;
			$out_of_stock='y' if($stock_status=~m/out\s*of\s*stock/is);
		}
		# if($content2=~m/>\s*Sorry[^>]*?this\s*item\s*is\s*not\s*available\s*at\s*the\s*moment\s*</is)
		# {
			# $out_of_stock='y';
		# }
		# if($content2=~m/var\s*variations\s*=\s*\(\s*\{\s*"variations"\s*:\s*(?:"|\{)\s*(?:"|\})\s*\}\s*\)\.variations\;/is)
		if($content2=~m/\(\s*\{\s*\"variations\"\s*\:\s*[\"\{\}]*?\)\.variations\;/is)
		{
			my ($size,$color);
			#size
			# if($content2=~m/\.variations\;\s*var\s*variantsSize\s*=\s*1\s*\;/is)
			if($content2=~m/variantsSize\s*=\s*1\s*\;/is)
			{
				if($content2=~m/<span[^>]*?hof\-value\-size\"[^>]*?>\s*([^>]*?)\s*<\/span>/is)
				{
					$size=$1;
				}
			}	
			#Colour
			if($content2=~m/"productColou?r"\s*:\s*"([^>]*?)"\s*\,/is)
			{
				$color=$1;
				$color=uri_unescape($color);
			}
			#MainImage
			# if ($content2=~m/<meta[^>]*?property\s*=\s*"og:image"[^>]*?content="([^>"]*?)"/is)
			if ($content2=~m/og\:image[^>]*?content\=\"([^>]*?)\"/is)
			{
				my $imageurl = $1;
				$imageurl=~s/^\s*(http[^>]*?\/HOF\/[^>]*?)\?[^>]*?$/$1/is;
				$main_image=$imageurl;
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
			}
			#AltImage
			if($main_image ne '')
			{
				# if($content2=~m/<div[^>]*?class="images-slider\s*animate[^>]*?>[\w\W]*?<ul[^>]*?class="train[^>]*?>([\w\W]*?)<\/ul>/is)
				if($content2=~m/<ul[^>]*?class\=\"train[^>]*?>([\w\W]*?)<\/ul>/is)
				{
					my $content2_img_blk=$1;
					# while($content2_img_blk=~m/<li[^>]*?class="coach"[^>]*?>\s*(?:<\![^>]*?>\s*)*<img[^>]*?src="([^>"]*?)"/igs)
					while($content2_img_blk=~m/<img[^>]*?src\=\"([^>]*?)\"/igs)
					{
						my $alter_image=$1;
						$alter_image=~s/^\s*(http[^>]*?\/HOF\/[^>]*?)\?[^>]*?$/$1/is;
						$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
						if($alter_image=~m/^\s*http/is)
						{
							
							my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='n';
						}
					}
				}	
			}
			else
			{
				# if($content2=~m/<div[^>]*?class="images-slider\s*animate[^>]*?>[\w\W]*?<ul[^>]*?class="train[^>]*?>([\w\W]*?)<\/ul>/is)
				if($content2=~m/<ul[^>]*?class\=\"train[^>]*?>([\w\W]*?)<\/ul>/is)
				{
					my $content2_img_blk=$1;
					my $inc=0;
					# while($content2_img_blk=~m/<li[^>]*?class="coach"[^>]*?>\s*(?:<\![^>]*?>\s*)*<img[^>]*?src="([^>"]*?)"/igs)
					while($content2_img_blk=~m/<img[^>]*?src\=\"([^>]*?)\"/igs)
					{
						my $alter_image=$1;
						$alter_image=~s/^\s*(http[^>]*?\/HOF\/[^>]*?)\?[^>]*?$/$1/is;
						if($alter_image=~m/^\s*http/is)
						{
							++$inc;
							if($inc==1)
							{
								my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='y';
							}
							else
							{
								my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='n';
							}	
						}
					}
				}	
			}
			#price_text&price
			if ($content2 =~m/<span[^>]*?class="price-container"[^>]*?>([\w\W]*?<\/p>)\s*(?:<[^>]*?>\s*)*<\/span>/is)
			{
				$price_text=$1;
				my $price_container=$price_text;
				$price_text=~s/\s+/ /igs;
				$price_text=~s/^\s+//is;
				$price_text=~s/\s+$//is;
				if($price_container=~m/<p[^>]*?class="price(?:Now)?"[^>]*?>\s*([\w\W]*?)\s*<\/p>/is)
				{
					$price=$1;
					$price =~ s/\&pound\;//ig;
					$price =~ s/Now//igs;
					$price=~s/[^\d\.]//gs;
					$price=~s/\s+/ /igs;
					$price=~s/^\s+//is;
					$price=~s/\s+$//is;
				}
			}
			$price="NULL" if($price=~m/^\s*$/is);
			utf8::decode($price_text);
			$price_text=~s/^\s*(?:\n|\r|\t|\h|\v)+//s;
			print "\nPrice Text: $price_text";
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$color;
		}	
		# elsif($content2=~m/var\s*variations\s*=\s*\(\s*\{\s*"variations"\s*:\s*\{([\w\W]*?)\}\s*\}\s*\)\.variations\;/is)
		elsif($content2=~m/\(\s*\{\s*"variations"\s*\:([\w\W]*?)\.variation/is)
		{
			my $sku_img_block=$1;
			my (@disabled_sizes);
			# while($content2=~m/<li[^>]*?id\s*=\s*"[^>"]*?"[^>]*?class[^>]*?data-size="([^>"]*?)"/igs)
			while($content2=~m/data\-size\=\"([^>]*?)\"/igs)
			{
				push(@disabled_sizes,$1);
			}
			while($sku_img_block=~m/(\{\s*"sizes?"\s*:\s*[\w\W]*?)\"colourname"\s*:\s*\"([^>]*?)\"\s*}/igs)
			{
				my $each_block_container=$1;
				my $color=$2; #Colour
				if($each_block_container=~m/\"available"\s*\:\s*\"true\"/is)
				{
					my ($size_block,$price_text_block,$price_block,$image_block,$swatch_url);
					my (@size_array,@image_array,@check_sizes);
					# if($each_block_container=~m/"colourname"\s*:\s*"([^>]*?)"/is)
					# {
						# $color=$1;
					# }
					if($each_block_container=~m/\{\s*\"sizes?\"\s*\:\s*\{([^\^]*?)\}\s*\,\s*\"detailedPrices\"/is)
					{
						$size_block=$1;
						# while($size_block=~m/"([^>\:]*?)"\s*:\s*\{\s*"([^>\:]*?)"\s*:\s*"([^\}"]*?)"\s*\}/igs)
						while($size_block=~m/\"([^>]*?)\"\s*\:\s*\{\s*\"(\d+)\"\s*\:\s*"([^>]*?)\"/igs)
						{
							my $siz_val=$1;
							my $size_name=$2.'<br>'.$3;
							$size_name=$siz_val.'<br>'.$size_name;
							push(@size_array,$size_name);
							push(@check_sizes,$siz_val);
						}
					}
					# if($each_block_container=~m/"detailedPrices"\s*\:\s*\{([\w\W]*?)\}\s*\,\s*"deliverychannels"/is)
					if($each_block_container=~m/\"detailedPrices\"\s*\:\s*\{([^\^]*?)\}\s*\,\s*\"deliverychannels\"/is)				
					{
						$price_text_block=$1;
					}
					if($each_block_container=~m/\"prices\"\s*\:\s*\{([^>]*?)\}\s*\,\s*\"images\"/is)
					{
						$price_block=$1;
					}
					#Image - MainImage & AltImage
					if($each_block_container=~m/\"images\"\s*\:\s*\[([^\^]*?)\]/is)
					{
						$image_block=$1;
						while($image_block=~m/\"(http[^>]*?)\"/igs)
						{
							push(@image_array,$1);
						}
						my $img_arr_size=scalar(@image_array);
						if($img_arr_size>=1)
						{
							for(my $i=0;$i<=$#image_array;$i++)
							{
								my $image_url=$image_array[$i];
								if($i==0)
								{
									my ($imgid,$img_file) = &DBIL::ImageDownload($image_url,'product',$retailer_name);
									my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									push(@query_string,$query);
									$imageflag = 1 if($flag);
									$image_objectkey{$img_object}=$color;
									$hash_default_image{$img_object}='y';
								}
								else
								{
									my ($imgid,$img_file) = &DBIL::ImageDownload($image_url,'product',$retailer_name);
									my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									push(@query_string,$query);
									$imageflag = 1 if($flag);
									$image_objectkey{$img_object}=$color;
									$hash_default_image{$img_object}='n';
								}	
							}
						}	
					}
					# Swatch
					if($each_block_container=~m/\"swatch\"\s*\:\s*\"(http[^>]*?)\"/is)
					{
						$swatch_url=$1;
						my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_url,'swatch',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_url,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='n';
					}
					# price_text, price, size & out_of_stock
					foreach my $size_blk(@size_array)
					{
						if($size_blk=~m/^\s*([^>]*?)\s*<br>\s*([^>]+?)\s*<br>\s*([^>]+?)\s*$/is)
						{
							my $size=$1;
							my $size_variant_num=$2;
							my $stock_status=$3;
							$out_of_stock='n';
							if($stock_status=~m/^\s*false/is)
							{
									$out_of_stock='y';
							}
							# if($price_text_block=~m/"variant$size_variant_num"\s*:\s*\{\s*"[^"]*?"\s*\:\s*\{\s*([^\}]*?)\s*\}\s*\,\s*"[^"]*?"\s*\:\s*\{\s*([^\}]*?)\s*\}\s*\,\s*"[^"]*?"\s*\:\s*\{\s*([^\}]*?)\s*\}\s*\,\s*"[^"]*?"\s*\:\s*\{\s*([^\}]*?)\s*\}\s*\}/is)
							if($price_text_block=~m/\"variant\Q$size_variant_num\E\"\s*\:\s*\{([^\^]*?\})\s*\}/is)
							{
								$price_text=$1;
								$price_text=~s/\"price[^"]*?"\s*\:\s*\{\s*"\d+"\s*\:\s*"//igs;
								$price_text=~s/\"price[^"]*?"\s*\:\s*\{\s*\}\s*\,?//igs;
								$price_text=~s/(?:\"|\{|\}|\,)//igs;
								$price_text=~s/<[^>]*?>/ /igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s+//is;
								$price_text=~s/\s+$//is;
								# $price_text=~s/"[^>"]*?"\s*\:\s*"//igs;
								# $price_text=~s/"\s*<br>//igs;
								# $price_text =~ s/\&pound\;/£/igs;
								# $price_text=~s/^\s*"//is;
								# $price_text=~s/\s*"\s*$//is;
								# $price_text = &DBIL::Trim($price_text);
								# $price_text=~s/Â//gs;
								# $price_text=~s/\s+/ /igs;
								# $price_text=~s/^\s+//is;
								# $price_text=~s/\s+$//is;
							}
							if($price_block=~m/\"\Q$size_variant_num\E\"\s*:\s*\"\s*([^>]*?)\s*\"/is)
							{
								$price=$1;
								$price=~s/[^\d\.]//gs;
							}
							# if($price_block=~m/"variant$size_variant_num"\s*:\s*\{\s*"PriceNow"\s*\:\s*\{\s*"[^>"]*?"\s*\:\s*"<p[^>]*?>\s*Now\s*([^>]*?)\s*(?:<\/p>\s*)?"\s*\}\s*\,\s*"price"\s*\:\s*\{\s*\}\s*\,\s*"priceThen"\s*\:\s*\{\s*\}\s*\,\s*"priceWas"\s*\:\s*\{\s*"[^>"]*?"\s*\:\s*"<p[^>]*?>\s*Was\s*\1\s*(?:<\/p>\s*)?"\s*\}/is)
							# {
								# $price_text=$1;
							# }
							$price="NULL" if($price=~m/^\s*$/is);
							utf8::decode($price_text);
							$price_text=~s/^\s*(?:\n|\r|\t|\h|\v)+//s;
							print "\nPrice Text: $price_text";
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
						}
					}
					my $dis_size=scalar(@disabled_sizes);
					if($dis_size>=1)
					{
						foreach my $each_size_val(@disabled_sizes)
						{
							# unless($each_size_val ~~ @check_sizes)
							unless(grep( /^\s*\Q$each_size_val\E\s*$/,@disabled_sizes))
							{
								$price="NULL" if($price=~m/^\s*$/is);
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$each_size_val,$color,'y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
							}	
						}
					}
				}	
			}
		}	
		elsif(($url=~m/\/null\+/is) || ($content2=~m/itemprop="name/is))
		{	
			my ($size,$color);
			$size='No Size';
			#Colour
			if($content2=~m/<span[^>]*?itemprop\=\"[^>]*?colour\"[^>]*?>\s*(?:<[^>]*?>\s*)*([^>]*?)\s*(?:<[^>]*?>\s*)*<\/span>/is)
			{
				$color=&DBIL::Trim($1);
			}
			elsif($content2=~m/<span[^>]*?\"colourName[^>]*?>\s*([^>]*?)\s*</is)
			{
				$color=&DBIL::Trim($1);
			}
			elsif($content2=~m/"productColou?r"\s*\:\s*"([^>]*?)(?:\||"\s*\,)/is)
			{
				$color=$1;
				$color=uri_unescape($color);
			}
			#MainImage
			# if($content2=~m/<meta[^>]*?property\s*=\s*"og:image"[^>]*?content="([^>"]*?)"/is)
			if($content2=~m/og\:image\"[^>]*?content\=\"([^>]*?)\"/is)
			{
				my $imageurl = $1;
				$imageurl=~s/^\s*(http[^>]*?\/HOF\/[^>]*?)\?[^>]*?$/$1/is;
				$main_image=$imageurl;
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
			}
			#AltImage
			if($main_image ne '')
			{
				# if($content2=~m/<div[^>]*?id="productSlides?"[^>]*?>([\w\W]*?)<\/div>/is)
				if($content2=~m/<div[^>]*?productSlides?\"[^>]*?>([\w\W]*?)<\/div>/is)
				{
					my $content2_img_blk=$1;
					while($content2_img_blk=~m/<img[^>]*?src\=\"([^>]*?)\"[^>]*?>/igs)
					{
						my $alter_image=$1;
						$alter_image=~s/^\s*(http[^>]*?\/HOF\/[^>]*?)\?[^>]*?$/$1/is;
						$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
						if($alter_image=~m/^\s*http/is)
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='n';
						}
					}
				}	
			}
			else
			{
				if($content2=~m/<div[^>]*?productSlides?\"[^>]*?>([\w\W]*?)<\/div>/is)
				{
					my $content2_img_blk=$1;
					my $inc=0;
					while($content2_img_blk=~m/<img[^>]*?src\=\"([^>]*?)\"[^>]*?>/igs)
					{
						my $alter_image=$1;
						$alter_image=~s/^\s*(http[^>]*?\/HOF\/[^>]*?)\?[^>]*?$/$1/is;
						if($alter_image=~m/^\s*http/is)
						{
							++$inc;
							if($inc==1)
							{
								my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='y';
							}
							else
							{
								my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='n';
							}
						}	
					}
				}
			}
			# Swatch
			if($content2=~m/id\=\"colourSwatchesContainer\"[^>]*?>\s*(?:<[^>]*?>\s*)*<img[^>]*?src\=\"([^>]*?_swatch)[^>]*?\"/is)
			{
				my $swatch_url=$1;
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_url,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_url,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
			}
			#price_text&price
			# if ( $content2=~m/itemprop="name[^>"]*?"[^>]*?>[\w\W]*?<p[^>]*?class="price[^>"]*?"[^>]*?>([\w\W]*?)<\/p>/is)
			if ( $content2=~m/<p[^>]*?class\=\"price[^>]*?\"[^>]*?>([\w\W]*?)<\/p>/is)
			{
				$price_text=$1;
				my $price_container=$price_text;
				$price_text=~s/\s+/ /igs;
				$price_text=~s/^\s+//is;
				$price_text=~s/\s+$//is;
				if($price_container=~m/From\s*([^>]*?)(?:<[^>]*?>\s*)*to/is)
				{
					$price=$1;
					$price =~ s/\&pound\;//ig;
					$price =~ s/Now//igs;
					$price=~s/[^\d\.]//gs;
					$price=~s/\s+/ /igs;
					$price=~s/^\s+//is;
					$price=~s/\s+$//is;
				}
			}
			$price="NULL" if($price=~m/^\s*$/is);
			utf8::decode($price_text);
			$price_text=~s/^\s*(?:\n|\r|\t|\h|\v)+//s;
			print "\nPrice Text: $price_text";
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$color;
			$mflag=1;
		}
		my @image_obj_keys = keys %image_objectkey;
		my @sku_obj_keys = keys %sku_objectkey;
		foreach my $img_obj_key(@image_obj_keys)
		{
			foreach my $sku_obj_key(@sku_obj_keys)
			{
				$image_objectkey{$img_obj_key}=~s/^\s+//is;
				$image_objectkey{$img_obj_key}=~s/\s+$//is;
				$image_objectkey{$sku_obj_key}=~s/^\s+//is;
				$image_objectkey{$sku_obj_key}=~s/\s+$//is;
				if($image_objectkey{$img_obj_key} eq $sku_objectkey{$sku_obj_key})
				{
					my $query=&DBIL::SaveSkuhasImage($sku_obj_key,$img_obj_key,$hash_default_image{$img_obj_key},$product_object_key,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);					
				}
			}
		}
		PNF:
		# my $query=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		# push(@query_string,$query); 		            
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		print "";
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
	my $req;
    if($method eq 'POST')
    {     
        $req=HTTP::Request->new($method=>"$mainurl");
		$req->content("$parameter");
    }
	else
	{
		$req=HTTP::Request->new('GET'=>"$mainurl");
	}	
    $req->header("Content-Type"=> "application/x-www-form-urlencoded");
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
    if($code=~m/^\s*(?:5|4)/is)
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
