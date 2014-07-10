#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Nordstrom_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm"; # USER DEFINED MODULE DBIL.PM
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Nordstrom_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Nordstrom-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Nor';
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
	
	my $skuflag = 0;
	my $imageflag = 0;
	my $mflag = 0;
	if($product_object_key)
	{
		my $url3=$url;		
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://shop.nordstrom.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &lwp_get($url3);
		goto MP if($content2 =~ m/<h2>\s*The\s*page\s*you\'re\s*trying\s*to\s*reach\s*cannot\s*be\s*found\.\s*<\/h2>/is);
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$img_file,$imagei,$imagelist,$imageid,$colorid,$imageurl,$image1,$size,$defualtimage,$multicol, $filter,$FCavailable,$swatch_url,$arry,$dbretun);
		my $uncolor="Emty";
		my $mflag;
		my (%colorid_hash,%image_hash,%sku_objectkey,%image_objectkey,%hash_default_image,%swatch_hash);
		my (@colorarry,@sizearry,@imagearry,@swatcharry,@field,@arr);
		my @query_string;
		if($content2=~m/This\s*item\s*is\s*currently\s*unavailable\./is)
		{
			goto MP;
		}
		####Multi product
		if($content2=~m/Select\s*this\s*item/is)
		{
			$mflag = 1;
		}
		####product_id
		if($content2=~m/<div\s*class\=\"item\-number\-wrapper\"\s*>\s*Item\s*\#\s*([^>]*?)\s*<\/div>/is)
		{
			$product_id=&trim($1);
			# print"product_id::$product_id\n";
		}
		elsif($content2=~m/<span>\s*Item\s*\#([^>]*?)\s*<\/span>/is)
		{
			$product_id=&trim($1);
			# print"product_id::$product_id\n";
		}
		my $sql = "select detail_collected from Product where retailer_id=\'$retailer_id\' and retailer_product_reference=\'$product_id\' limit 2";
		my $sth = $dbh->prepare($sql) or die "Cannot prepare: " . $dbh->errstr();
		$sth->execute() or die "Cannot execute: " . $sth->errstr();
		while(@field = $sth->fetchrow_array())
		{
			push(@arr, $field[0]);
		}
		$arry=@arr;
		$dbretun=$arr[0];
		if($arry == 0)
		{
			print"Product enter first time::$product_id\n";
		}
		####New Data ########
		elsif($arry == 1)
		{
			####DB Product M Current Product M ########
			if($dbretun eq "m" )
			{
				if($mflag == 1)
				{
					my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
					goto LAST if($ckproduct_id == 1);
					undef ($ckproduct_id);
				}
				
			}
			####DB Product y Current Product y ########
			elsif($dbretun eq "y")
			{
				if($mflag != 1)
				{
					my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
					goto LAST if($ckproduct_id == 1);
					undef ($ckproduct_id);
				}
			}
		}
		####DB Product M & y ########
		elsif($arry == 2)
		{
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		####Multi product
		if($content2=~m/Select\s*this\s*item/is)
		{
			goto MP;
		}
		####product_name
		$product_name=trim($1) if($content2=~m/\"\s*name\s*\"\s*\:\s*\"\s*([^>]*?)\s*\"\s*\,/is);
		# print"product_name::$product_name\n";
		####Brand
		$brand=trim($1) if($content2=~m/\"\s*brandName\s*\"\s*\:\s*\"\s*([^>]*?)\s*\"\,/is); 
		# print"brand::$brand\n";
		####description
		$description=trim($1) if($content2=~m/<div\s*id\s*\=\s*\"size\-details\"\s*>\s*([^^]*?)\s*<\/ul>/is); 
		# print"description::$description\n";
		####prod_detail
		$prod_detail=trim($1) if($content2=~m/<div\s*class\s*\=\s*\"accordion\-content\"\s*>\s*([^^]*?)\s*<\/ul>/is); 
		# print"prod_detail::$prod_detail\n";
		####price_text
		if($content2=~m/<td\s*class\s*\=\s*\"\s*item\-price\s*heading\-2\"\s*>\s*<span>\s*([^>]*?)\s*<\/span>/is)
		{
			$price_text=trim($1);
		}
		elsif($content2=~m/<\s*span\s*class\s*\=\s*\"regular\-price\"\s*>\s*([^>]*?)\s*<\/span>\s*<\s*span\s*class\s*\=\"sale\-price\"\s*>\s*([^>]*?)\s*<\/span>/is)
		{
			my $price_text1=trim($1);
			my $price_text2=trim($2);
			$price_text=$price_text1." ".$price_text2;
		}
		# print"price_text::$price_text\n";
		#####Image######
		#####Main Image ######
		my $imagecont=$1 if($content2=~m/<div\s*class\=\"hidden\">([\w\W]*?)<h2>Color\:<\/h2>/is);
		while($imagecont=~m/data\-img\-zoom\-filename\=\"\s*([^>]*?)\s*\"\s*title\=\"\s*([^>]*?)\"[^^]*?src\=\"\s*([^>]*?)\s*\"/igs)
		{
			my $image="http://g.nordstromimage.com/imagegallery/store/product/".$1;
			$color=trim($2);
			my $swatchimage=$3;
			$image_hash{$image}=$color;
			$swatch_hash{$swatchimage}=$color;
			push(@imagearry,$image);
			push(@swatcharry,$swatchimage);
			push(@colorarry,$color);
			# print"image::$image\n";
			# print"color::$color\n";
			# print"swatchimage::$swatchimage\n";
		}
		@imagearry=keys %{{ map { $_ => 1 } @imagearry }};
		@swatcharry=keys %{{ map { $_ => 1 } @swatcharry }};
		@colorarry=keys %{{ map { $_ => 1 } @colorarry }};
		##main_Image
		foreach(@imagearry)
		{
			my $imageurl=$_;
			$color=$image_hash{$imageurl};
			my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=lc($color);
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);
		}
		foreach(@swatcharry)
		{
			my $swatchurl=$_;
			$color=$swatch_hash{$swatchurl};
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatchurl,'swatch',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatchurl,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
			$image_objectkey{$img_object}=lc($color);
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
		}
		###AleterImage
		my $alter_Image_con=$1 if($content2=~m/<ul\s*class\=\"image\-thumbs\">([\w\W]*?)<\/ul>/is);
		while($alter_Image_con=~m/data\-img\-zoom\-filename\=\"([^>]*?)\"/igs)
		{
			my $alter_image="http://g.nordstromimage.com/imagegallery/store/product/".$1;
			my $color1=$image_hash{$alter_image};
			if($color1)
			{
				$color=$color1;
				next;
			}
			unless($content2=~m/Select\s*a\s*color/is)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$uncolor;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
				next;
			}
			# print"color::$color\n";
			# print"alter_image::$alter_image\n";
			my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=lc($color);
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
		}
		##Skucont
		my $skucon=$1 if($content2=~m/skus\"\:\s*\[([^>]*?)\]/is);
		##sizecont
		if($content2=~m/<h2>Width\:<\/h2>/is)
		{
			
			if($content2=~m/<div\s*id\=\"size\-buttons\">([^^]*?)<\/div>/is)
			{
				my $sizecont=$1;
				while($sizecont=~m/class\=\"option\-label\"\s*value\=\"([^>]*?)\"/igs)
				{
					my $tempsize=trim($1);
					push(@sizearry,$tempsize);
				}
			}
			@sizearry=keys %{{ map { $_ => 1 } @sizearry }};
			while($skucon=~m/available\"\:\s*(\d)\,[^>]*?size\"\:\s*(?:\")?([^>]*?)(?:\")?\s*\,\s*\"color\"\:\s*(?:\")?([^\"]*?)(?:\")?\,[^>]*?\"width\"\:\s*(?:\")?([^\"]*?)(?:\")?\,[^>]*?price\"\:\s*\"(\$[\d\,\.]*?)\"\,\s*\"choiceGroup/igs)
			{
				my $availabe=$1;
				my $size1=trim($2);
				$color=trim($3);
				my $with=trim($4);
				my $price1=trim($5);
				next if(($size1 eq 'null') || ($color eq 'null') ||($with eq 'null'));
				$out_of_stock='n';
				$out_of_stock='y' if($availabe==0);
				$price=$price1;
				$price=trim($1) if($price=~m/\$([\d\,\.]*?)$/is);
				$price=~s/\,//ig;
				$size="width : ".$with." , "."size : ".$size1;
				if($content2=~m/<div\s*class\s*\=\s*\"radio\-wrapper\">/is)
				{
					$price_text=$price1;
				}
				# print"availabe::$availabe\n";
				# print"size::$size\n";
				# print"color::$color\n";
				# print"price::$price\n";
				# print"out_of_stock:::::::::$out_of_stock\n";
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=lc($color);
				push(@query_string,$query);
			}
		
		}
		else
		{
			
			if($content2=~m/<div\s*id\=\"size_filter_([^>]*?)\"[^>]*?>\s*<ul>([^^]*?)<\/ul>/is)
			{
				while($content2=~m/<div\s*id\=\"size_filter_([^>]*?)\"[^>]*?>\s*<ul>([^^]*?)<\/ul>/igs)
				{
					my $filter=trim($1);
					my $size_con=$2;
					while($size_con=~m/class\=\"option\-label\"\s*value\=\"([^>]*?)\"/igs)
					{
						my $tempsize=trim($1);
						my $tempsize1=$filter." ".$tempsize;
						push(@sizearry,$tempsize1);
					}
				}
				@sizearry=keys %{{ map { $_ => 1 } @sizearry }};
				while($skucon=~m/available\"\:\s*(\d)\,[^>]*?size\"\:\s*\"([^>]*?)\"\s*\,\s*\"color\"\:\s*\"([^\"]*?)\"\,[^>]*?price\"\:\s*\"(\$[\d\,\.]*?)\"\,\s*\"choiceGroup\"\:\s*\"([^\"]*?)\"\s*\}/igs)
				{
					my $availabe=$1;
					my $size1=trim($2);
					$color=trim($3);
					$price=trim($4);
					my $filter=$5;
					$out_of_stock='n';
					$out_of_stock='y' if($availabe==0);
					$price=trim($1) if($price=~m/\$([\d\,\.]*?)$/is);
					$price=~s/\,//ig;
					$size=$filter." ".$size1;
					# print"availabe::$availabe\n";
					# print"size::$size\n";
					# print"color::$color\n";
					# print"price::$price\n";
					# print"filter::$filter\n";
					# print"out_of_stock:::::::::$out_of_stock\n";
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=lc($color);
					push(@query_string,$query);
				}
				foreach(@sizearry)
				{
					$size=$_;
					my $filter;
					my $tempsize;
					if($size=~m/^([^>]*?)\s([^>]*?)$/is)
					{
						$filter=$1;
						$tempsize=$2;
						$tempsize =~ s/\W+/[^>]*?/g;
					}
					foreach(@colorarry)
					{
						$color=$_;
						$color=join(' ',map{ucfirst(lc($_))}split(/\s/,$color));
						my $color1=$color;
						$color1 =~ s/\W+/[^>]*?/g;
						if($skucon=~m/available\"\:\s*(\d)\,[^>]*?size\"\:\s*\"$tempsize\"\s*\,\s*\"color\"\:\s*\"$color1\"\,[^>]*?price\"\:\s*\"(\$[\d\,\.]*?)\"\,\s*\"choiceGroup\"\:\s*\"$filter\"\s*\}/is)
						{
							my $available=$1;
							$price=trim($2);
							$price=trim($1) if($price=~m/\$([^>]*?)$/is);
							$price=~s/\,//ig;
							$out_of_stock='n';
						}
						else
						{
							$out_of_stock='y';
							# print"elseprice::$price\n";
							# print"elsesize::$size\n";
							# print"elsecolor::$color\n";
							# print"elseout_of_stock::************************$out_of_stock\n";
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=lc($color);
							push(@query_string,$query);
						}
					}
				}
				
			}
			else
			{
				if($content2=~m/<div\s*id\=\"size\-buttons\">([^^]*?)<\/div>/is)
				{
					my $sizecont=$1;
					while($sizecont=~m/class\=\"option\-label\"\s*value\=\"([^>]*?)\"/igs)
					{
						my $tempsize=trim($1);
						push(@sizearry,$tempsize);
					}
				}
				@sizearry=keys %{{ map { $_ => 1 } @sizearry }};
				while($skucon=~m/available\"\:\s*(\d)\,[^>]*?size\"\:\s*(?:\")?([^>]*?)(?:\")?\s*\,\s*\"color\"\:\s*(?:\")?([^\"]*?)(?:\")?\,[^>]*?price\"\:\s*\"(\$[\d\,\.]*?)\"\,\s*\"choiceGroup/igs)
				{
					my $availabe=$1;
					my $size1=trim($2);
					$color=trim($3);
					my $price1=trim($4);
					next if(($size1 eq 'null') || ($color eq 'null'));
					$out_of_stock='n';
					$out_of_stock='y' if($availabe==0);
					$price=$price1;
					$price=trim($1) if($price=~m/\$([\d\,\.]*?)$/is);
					$price=~s/\,//ig;
					$size=$size1;
					if($content2=~m/<div\s*class\s*\=\s*\"radio\-wrapper\">/is)
					{
						$price_text=$price1;
					}
					# print"availabe::$availabe\n";
					# print"size::$size\n";
					# print"color::$color\n";
					# print"price::$price\n";
					# print"out_of_stock:::::::::$out_of_stock\n";
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=lc($color);
					push(@query_string,$query);
				}
				foreach(@sizearry)
				{
					$size=$_;
					foreach(@colorarry)
					{
						$color=$_;
						$color=join(' ',map{ucfirst(lc($_))}split(/\s/,$color));
						my $color1=$color;
						$color1 =~ s/\W+/[^>]*?/g;
						if($skucon=~m/available\"\:\s*(\d)\,[^>]*?size\"\:\s*\"$size\"\s*\,\s*\"color\"\:\s*\"$color1\"\,[^>]*?price\"\:\s*\"(\$[\d\,\.]*?)\"\,\s*\"choiceGroup/is)
						{
							my $available=$1;
							$price=trim($2);
							$price=trim($1) if($price=~m/\$([^>]*?)$/is);
							$price=~s/\,//ig;
							$out_of_stock='n';
						}
						else
						{
							$out_of_stock='y';
							# print"elseprice::$price\n";
							# print"elsesize::$size\n";
							# print"elsecolor::$color\n";
							# print"elseout_of_stock::************************$out_of_stock\n";
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=lc($color);
							push(@query_string,$query);
						}
					}
				}
			}
			unless($content2=~m/<div\s*id\=\"size\-buttons\">/is)
			{
				while($skucon=~m/color\"\:\s*\"([^\"]*?)\"\,[^>]*?price\"\:\s*\"(\$[\d\,\.]*?)\"\,\s*\"choiceGroup/igs)
				{
					$color=trim($1);
					$price=trim($2);
					$size="NO SIZE";
					$out_of_stock='n';
					$price=trim($1) if($price=~m/\$([\d\,\.]*?)$/is);
					$price=~s/\,//ig;
					# print"size::$size\n";
					# print"color::$color\n";
					# print"price::$price\n";
					# print"out_of_stock:::::::::$out_of_stock\n";
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=lc($color);
					push(@query_string,$query);
				}
			}
			unless($content2=~m/Select\s*a\s*color/is)
			{
				while($skucon=~m/size\"\:\s*\"([^\"]*?)\"\,[^>]*?price\"\:\s*\"(\$[\d\,\.]*?)\"\,\s*\"choiceGroup/igs)
				{
					$size=trim($1);
					$price=trim($2);
					$color="NO COLOR";
					$out_of_stock='n';
					$price=trim($1) if($price=~m/\$([\d\,\.]*?)$/is);
					$price=~s/\,//ig;
					# print"size::$size\n";
					# print"color::$color\n";
					# print"price::$price\n";
					# print"out_of_stock:::::::::$out_of_stock\n";
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$uncolor;
					push(@query_string,$query);
				}
			}
			unless($content2=~m/Select\s*a\s*color/is)
			{
				unless($content2=~m/<div\s*id\=\"size\-buttons\">/is)
				{
					if($skucon=~m/price\"\:\s*\"(\$[\d\,\.]*?)\"/is)
					{
						$price=trim($2);
						$size="NO SIZE";
						$color="NO COLOR";
						$out_of_stock='n';
						$price=trim($1) if($price=~m/\$([\d\,\.]*?)$/is);
						$price=~s/\,//ig;
						# print"size::$size\n";
						# print"color::$color\n";
						# print"price::$price\n";
						# print"out_of_stock:::::::::$out_of_stock\n";
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$uncolor;
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
		MP:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		print"";
	}
}1;
sub lwp_get() 
{ 
    # REPEAT: 
    my $url = $_[0];
    my $req = HTTP::Request->new(GET=>$url);
    $req->header("Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"); 
    $req->header("Content-Type"=>"application/x-www-form-urlencoded"); 
    my $res = $ua->request($req); 
    $cookie->extract_cookies($res); 
    $cookie->save; 
    $cookie->add_cookie_header($req); 
    my $code = $res->code(); 
    print $code,"\n"; 
    open LL,">>".$retailer_file;
    print LL "$url=>$code\n";
    close LL;
    # if($code =~ m/50/is) 
    # {        
        # goto REPEAT; 
    # } 
    return($res->content()); 
}

sub trim
{
	my $txt = shift;
	
	$txt =~ s/\<[^>]*?\>//ig;
	$txt =~ s/\n+/ /ig;
	$txt =~ s/\"/\'\'/g;
	$txt =~ s/^\s+|\s+$//ig;
	$txt =~ s/\s+/ /ig;
	$txt =~ s/\&nbsp\;//ig;
	$txt =~ s/\&amp\;/\&/ig;
	$txt =~ s/\&bull\;/•/ig;
	$txt =~ s/[^[:print:]]+//igs;
	$txt =~ s/&pound;/£/ig;
	$txt =~ s/Item\s*number//ig;
	$txt =~ s/\{//igs;
	$txt =~ s/\&\#174\;\-/ /igs;
	$txt =decode_entities($txt);
	
	return $txt;
}

