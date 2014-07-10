#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Macys_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
use utf8;
#require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Macys_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger = shift;
	$dbh->do("set character set utf8");
	$dbh->do("set names utf8");
	my @query_string;
	$robotname='Macys-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Mac';
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
		$content2=~s/<script[^>]*?>[^<]*?colorSwatchs\s*=[\w\W]*?<\/script>//igs;
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;	
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock);
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		
		#product_id
		if($content2=~m/>[^>]*?Web\s*ID\s*\:\s*([^>]*?)\s*</is)
		{
			$product_id=&DBIL::Trim($1);
			my $ckproduct_id=&DBIL::UpdateProducthasTag($product_id, $product_object_key,$dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if($content2=~m/<h1[^>]*?(?:id|class)="productTitle[^>"]*?"[^>]*?>\s*([\w\W]*?)\s*<\/h1>/is)
		{
			$product_name=&DBIL::Trim($1);
		}
		elsif($content2=~m/<div[^>]*?class="emailFriendDesc"[^>]*?>\s*Item\s*\:\s*([^<]+?)\s*<\/div>/is)
		{
			$product_name=&DBIL::Trim($1);
		}
		utf8::decode($product_name);
		$product_name=~s/[^!@#$%^&*()_+-={}|\[\]\:"<>?;',\.\/a-zA-Z0-9\s]//gs;		
		# description & details
		if ($content2=~m/<div[^>]*?itemprop="description[^>"]*?"[^>]*?>\s*([\w\W]*?)\s*<\/div>\s*(?:<[^>]*?>\s*)*<ul[^>]*?>\s*([\w\W]*?)\s*<\/ul>/is)
		{		
			$description=&DBIL::Trim($1);
			$prod_detail = $2;	
			# $description=~s/Â//gs;
			# $description=~s/\Â//gs;
			$prod_detail =~s/<li[^>]*?>/ * /igs;
			$prod_detail=&DBIL::Trim($prod_detail);
			# $prod_detail=~s/Â//gs;
			# $prod_detail=~s/\Â//gs;
			
		}
		elsif($content2=~m/<div[^>]*?itemprop="description[^>"]*?"[^>]*?>\s*([\w\W]*?)\s*<\/div>/is)
		{
			$description=&DBIL::Trim($1);
			# $description=~s/Â//gs;
			# $description=~s/\Â//gs;
			
		}
		utf8::decode($description);
		utf8::decode($prod_detail);
		$description=~s/[^!@#$%^&*()_+-={}|\[\]\:"<>?;',\.\/a-zA-Z0-9\s]//gs;
		# Brand
		if($content2=~m/class="pdpBrandLogo[^>"]*?"[^>]*?>\s*(?:<[^>]*?>\s*)*<img[^>]*?alt="\s*([^<"]+?)\s*"/is)
		{
			$brand=&DBIL::Trim($1);
			$brand=make_proper($brand);
			$brand=~s/^\s+//is;
			$brand=~s/\s+$//is;
		}
		if($brand=~m/^\s*$/is)
		{
			my $brand_url='http://macys.ugc.bazaarvoice.com/7129aa/'.$product_id.'/reviews.djs?format=embeddedhtml';
			
			my $brand_con=&GetContent($brand_url);
			if($brand_con=~m/"brand"\s*:\s*"\s*([^>]*?)\s*"\s*\,/is)
			{
				$brand=&DBIL::Trim($1);
				$brand=~s/^\s+//is;
				$brand=~s/\s+$//is;
			}
			if($brand=~m/^\s*$/is)
			{
				if($content2=~m/"productID"\s*:\s*"([^>"]+?)"/is)
				{
					my $prod_id=$1;
					my $brand_url='http://macys.ugc.bazaarvoice.com/7129aa/'.$prod_id.'/reviews.djs?format=embeddedhtml';
					my $brand_con = &GetContent($brand_url);
					if($brand_con=~m/"brand"\s*:\s*"\s*([^>]*?)\s*"\s*\,/is)
					{
						$brand=&DBIL::Trim($1);
						$brand=~s/^\s+//is;
						$brand=~s/\s+$//is;
					}
				}	
			}
			$brand=make_proper($brand);
		}
		utf8::decode($brand);
		&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid) if($brand ne '');
		if($content2=~m/<em[^>]*?>\s*Choose\s*Your\s*Items\s*<\/em>/is)
		{
			$mflag = 1;
			goto MP;
		}
		#price_text&price
		if($content2 =~m/<div[^>]*?id="priceInfo"[^>]*?>([\w\W]*?)(?:<\/div>\s*<div[^<]*?itemprop="offers|<span[^>]*?class="pricingPolicy)/is)
		{
			$price_text=$1;
		}
		elsif($content2 =~m/<div[^>]*?class="standardProdPricingGroup"[^>]*?>\s*([\w\W]*?)\s*<\/div>/is)
		{
			$price_text=$1;
		}
		my $price_container=$price_text;
		$price_text=~s/<[^>]*?>\s*Pricing\s*Policy\s*<[^>]*?>//is;
		$price_text=&DBIL::Trim($price_text);
		# $price_text=~s/Â//gs;
		$price_text=~s/\s+/ /igs;
		$price_text=~s/^\s+//is;
		$price_text=~s/\s+$//is;
		if($price_container=~m/<span[^>]*?class="priceSale"[^>]*?>\s*([^>]*?)\s*</is)
		{
			$price=$1;
		}
		elsif($price_container=~m/>\s*(?:Sale|Now)\s*([^>]*?)\s*</is)
		{
			$price=$1;
		}
		if($price=~m/^\s*$/is)
		{
			$price=$price_text;
		}
		$price =~s/\$//is;
		$price=~s/[^\d\.]//gs;
		$price=&DBIL::Trim($price);
		# $price=~s/Â//gs;
		$price=~s/\s+/ /igs;
		$price=~s/^\s+//is;
		$price=~s/\s+$//is;
		$price="NULL" if($price=~m/^\s*$/is);
		utf8::decode($price_text);
		$price_text=~s/^\s*(?:\n|\r|\t|\h|\v)//s;
		if($content2=~m/>\s*This\s*product\s*is\s*currently\s*unavailable\s*</is)
		{
			if($content2=~m/(?:class="productImageSection"[^>]*?>\s*<img\s*|MACYS\.pdp\.mainImg)src\s*=\s*"([^>"]*?)"/is)
			{
				$main_image= $1;
				$main_image=~s/\?[^>]*?$//is;
				my ($imgid,$img_file)=&DBIL::ImageDownload($main_image,'product',$retailer_name);
				my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}='unavailable';
				$hash_default_image{$img_object}='y';
				if($content2=~m/<ul[^>]*?id="altImages[^>"]*?"[^>]*?>([\w\W]*?)<\/ul>/is)
				{
					my $content2_altimg_blk=$1;
					while($content2_altimg_blk=~m/<img[^>]*?src="([^>"]*?)"[^>]*?>/igs)
					{
						my $alter_image=$1;
						$alter_image=~s/\?[^>]*?$//is;
						$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
						$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
						if($alter_image=~m/^\s*http/is)
						{
							my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
							my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}='unavailable';
							$hash_default_image{$img_object}='n';
						}
					}
				}
				elsif($content2=~m/MACYS\.pdp\.productLvlAddImgs\s*=\s*"([^<"]+?)"\s*\;/is)
				{
					my $alter_image=$1;
					$alter_image=~s/\?[^>]*?$//is;
					$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
					$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
					if($alter_image=~m/^\s*http/is)
					{
						my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
						my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='unavailable';
						$hash_default_image{$img_object}='n';
					}
				}				
				$out_of_stock='y';
				my ($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'','',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}='unavailable';
				goto KEY_CHECK;
			}	
		}
		#Colour & Size List
		my (@colours,@sizes);
		if($content2=~m/<ul[^>]*?id="colorList[^>"]*?"[^>]*?>([\w\W]*?)<\/ul>/is)
		{
			my $color_list=$1;
			while($color_list=~m/<li[^>]*?>\s*<img[^>]*?id="swatch[^>]*?(?:title|alt)="([^<"]*?)"[^>]*?>/igs)
			{
				my $color_val=&DBIL::Trim($1);
				push(@colours,$color_val);
			}
		}
		elsif($content2=~m/class="productColor[^>"]*?"[^>]*?>\s*([^<]*?)\s*</is)
		{
			push(@colours,$1);
		}
		elsif($content2=~m/MACYS\.pdp\.primaryImages\[\d+\]\s*=\s*\{\s*"(No\s*Color)"\s*\:\s*"[^"\}]*?"\s*\}/is)
		{
			push(@colours,$1);
		}
		else
		{
			push(@colours,'No Color');
		}
		if($content2=~m/<ul[^>]*?id="sizeList[^>"]*?"[^>]*?>([\w\W]*?)<\/ul>/is)
		{
			my $size_list=$1;
			while($size_list=~m/<li[^>]*?>\s*([\w\W]*?)\s*<\/li>/igs)
			{
				my $size_val=&DBIL::Trim($1);
				push(@sizes,$size_val);
			}
		}
		elsif($content2=~m/id="selectedSize[^>"]*?"[^>]*?class="productSize[^>"]*?"[^>]*?>\s*([^<]*?)\s*</is)
		{
			push(@sizes,$1);
		}
		my ($size,$color,$main_image_blk,$alt_img_flag,$addi_altimg_blk,$addi_altimg_flag);
		$alt_img_flag=0;
		#MainImage_Block
		if ($content2=~m/MACYS\.pdp\.primaryImages\[\d+\]\s*=\s*\{\s*("[^\}]*?")\s*\}/is)
		{
			$main_image_blk=$1;
		}	
		if($content2=~m/MACYS\.pdp\.additionalImages\[\d+\]\s*=\s*\{\s*("[^\}]*?")\s*\}/is)
		{
			$addi_altimg_blk=$1;
			$addi_altimg_flag=1;
		}
		my  $size_arr_len=scalar(@sizes);
		my %dup;
		foreach my $color_valu(@colours)
		{
			my $val=++$dup{lc($color_valu)};
			if($size_arr_len>=1)
			{
				foreach my $size_valu(@sizes)
				{
					if($content2=~m/\{\s*"upcID"\s*:\s*[^\}]*?"color"\s*:\s*"\s*(\Q$color_valu\E)\s*"[^>\}]*?"size"\s*:\s*"\s*(\Q$size_valu\E)\s*"[^>\}]*?"isAvailable"\s*:\s*"true"[^>\}]*?"availabilityMsg"\s*:\s*"([^"\}]*?)"[^>\}]*?\}/is)
					{
						$color=$1;
						$size=$2;
						my $stock_msg=$3;
						$out_of_stock=($stock_msg=~m/out\s*of\s*stock/is)?'y':'n';
					}
					else
					{
						$color=$color_valu;
						$size=$size_valu;
						$out_of_stock='y';
					}
					$color=~s/^\s*No\s*Color\s*$//is;
					my $color_inc=$color;
					if(($val>=2) && ($color ne ''))
					{
						$color_inc=$color.' ('.$val.')';
					}
					my ($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_inc,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;
				}
			}
			else
			{
				if($content2=~m/\{\s*"upcID"\s*:\s*[^\}]*?"color"\s*:\s*"\s*(\Q$color_valu\E)\s*"[^>\}]*?"size"\s*:\s*"\s*"[^>\}]*?"isAvailable"\s*:\s*"true"[^>\}]*?"availabilityMsg"\s*:\s*"([^"\}]*?)"[^>\}]*?\}/is)
				{
					$color=$1;
					my $stock_msg=$2;
					$size='';
					$out_of_stock=($stock_msg=~m/out\s*of\s*stock/is)?'y':'n';
				}
				else
				{
					$color=$color_valu;
					$size='';
					$out_of_stock='y';
				}
				$color=~s/^\s*No\s*Color\s*$//is;
				my $color_inc=$color;
				if(($val>=2) && ($color ne ''))
				{
					$color_inc=$color.' ('.$val.')';
				}
				my ($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_inc,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
			}			
			#MainImage
			if($main_image_blk=~m/"\s*(\Q$color_valu\E)\s*"\s*:\s*"([^>\,"]*?)"/is)
			{
				$color=$1;
				my $imageurl = $2;
				$color=~s/^\s*No\s*Color\s*$//is;
				$imageurl=~s/\?[^>]*?$//is;
				$imageurl='http://slimages.macys.com/is/image/MCY/products/'.$imageurl if($imageurl!~m/^\s*http/is);
				$main_image=$imageurl;
				my ($imgid,$img_file)=&DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
				$main_image_blk=~s/"\s*\Q$color_valu\E\s*"\s*:\s*"([^>\,"]*?)"//is;
			}
			elsif(($content2=~m/MACYS\.pdp\.mainImgSrc\s*=\s*"[^>"]*?"\s*\;/is) && ($size=~m/^\s*$/is) && ($color_valu=~m/^\s*(?:No\s*color\s*|\s*)$/is))
			{
				my $imageurl = $1 if ($content2=~m/MACYS\.pdp\.mainImgSrc\s*=\s*"([^>"]*?)"\s*\;/is);
				$color=$color_valu;
				$color=~s/^\s*No\s*Color\s*$//is;
				$imageurl=~s/\?[^>]*?$//is;
				$imageurl='http://slimages.macys.com/is/image/MCY/products/'.$imageurl if($imageurl!~m/^\s*http/is);
				$main_image=$imageurl;
				my ($imgid,$img_file)=&DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
			}
			elsif($content2=~m/MACYS\.pdp\.mainImgSrc\s*=\s*"([^>"]*?)"\s*\;/is)
			{
				my $imageurl = $1;
				$color=$color_valu;
				$color=~s/^\s*No\s*Color\s*$//is;
				$imageurl=~s/\?[^>]*?$//is;
				$imageurl='http://slimages.macys.com/is/image/MCY/products/'.$imageurl if($imageurl!~m/^\s*http/is);
				$main_image=$imageurl;
				my ($imgid,$img_file)=&DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
			}
			#AltImage
			if($addi_altimg_flag==1)
			{
				if($addi_altimg_blk=~m/"\Q$color_valu\E"\s*:\s*"([^>"]*?)"/is)
				{
					my $addi_altimg_blk_urls=$1;
					$color=$color_valu;
					$color=~s/^\s*No\s*Color\s*$//is;
					if($addi_altimg_blk_urls=~m/\,/is)
					{
						while($addi_altimg_blk_urls=~m/([^\,]+?)(?:\s*\,\s*|\s*$)/igs)
						{
							my $alter_image=$1;
							$alter_image=~s/\?[^>]*?$//is;
							$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
							$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
							if($alter_image=~m/^\s*http/is)
							{
								my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='n';
								$alt_img_flag=1;
							}
						}
					}
					else
					{
						my $alter_image=$addi_altimg_blk_urls;
						$alter_image=~s/\?[^>]*?$//is;
						$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
						$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
						if($alter_image=~m/^\s*http/is)
						{
							my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
							my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='n';
							$alt_img_flag=1;
						}
					}
					$addi_altimg_blk=~s/"\Q$color_valu\E"\s*:\s*"[^>"]*?"//is;
				}
				if($alt_img_flag==0)
				{
					$color=$color_valu;
					$color=~s/^\s*No\s*Color\s*$//is;
					if($content2=~m/<ul[^>]*?id="altImages[^>"]*?"[^>]*?>([\w\W]*?)<\/ul>/is)
					{
						my $content2_altimg_blk=$1;
						while($content2_altimg_blk=~m/<img[^>]*?src="([^>"]*?)"[^>]*?>/igs)
						{
							my $alter_image=$1;
							$alter_image=~s/\?[^>]*?$//is;
							$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
							$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
							if($alter_image=~m/^\s*http/is)
							{
								my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='n';
							}
						}
						$alt_img_flag=1;
					}
					elsif($content2=~m/MACYS\.pdp\.productLvlAddImgs\s*=\s*"\s*([^<"]+?)\s*"\s*\;/is)
					{
						my $alter_image_blk=$1;
						if($alter_image_blk=~m/\,/is)
						{
							while($alter_image_blk=~m/([^\,]+?)(?:\s*\,\s*|\s*$)/igs)
							{
								my $alter_image=$1;
								$alter_image=~s/\?[^>]*?$//is;
								$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
								$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
								if($alter_image=~m/^\s*http/is)
								{
									my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
									my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									push(@query_string,$query);
									$imageflag = 1 if($flag);
									$image_objectkey{$img_object}=$color;
									$hash_default_image{$img_object}='n';
								}
							}
						}
						else
						{
							my $alter_image=$alter_image_blk;
							$alter_image=~s/\?[^>]*?$//is;
							$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
							$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
							if($alter_image=~m/^\s*http/is)
							{
								my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='n';
							}
						}
						$alt_img_flag=1;
					}
				}	
			}
			elsif($alt_img_flag==0)
			{
				$color=$color_valu;
				$color=~s/^\s*No\s*Color\s*$//is;
				if($content2=~m/<ul[^>]*?id="altImages[^>"]*?"[^>]*?>([\w\W]*?)<\/ul>/is)
				{
					my $content2_altimg_blk=$1;
					while($content2_altimg_blk=~m/<img[^>]*?src="([^>"]*?)"[^>]*?>/igs)
					{
						my $alter_image=$1;
						$alter_image=~s/\?[^>]*?$//is;
						$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
						$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
						if($alter_image=~m/^\s*http/is)
						{
							my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
							my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='n';
						}
					}
					$alt_img_flag=1;
				}
				elsif($content2=~m/MACYS\.pdp\.productLvlAddImgs\s*=\s*"\s*([^<"]+?)\s*"\s*\;/is)
				{
					my $alter_image_blk=$1;
					if($alter_image_blk=~m/\,/is)
					{
						while($alter_image_blk=~m/([^\,]+?)(?:\s*\,\s*|\s*$)/igs)
						{
							my $alter_image=$1;
							$alter_image=~s/\?[^>]*?$//is;
							$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
							$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
							if($alter_image=~m/^\s*http/is)
							{
								my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='n';
							}
						}
					}
					else
					{
						my $alter_image=$alter_image_blk;
						$alter_image=~s/\?[^>]*?$//is;
						$alter_image='http://slimages.macys.com/is/image/MCY/products/'.$alter_image if($alter_image!~m/^\s*http/is);
						$alter_image=~s/^\s*\Q$main_image\E\s*$//is;
						if($alter_image=~m/^\s*http/is)
						{
							my ($imgid,$img_file)=&DBIL::ImageDownload($alter_image,'product',$retailer_name);
							my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='n';
						}
					}
					$alt_img_flag=1;
				}
			}	
			#Swatch
			if($content2=~m/<li[^>]*?>\s*<img[^>]*?id="swatch[^>]*?(?:tiltle|alt)="\s*(\Q$color_valu\E)\s*"[^>]*?>\s*<input[^>]*?value="\/*([^<"]*?)"[^>]*?>/is)
			{
				$color=$1;
				my $swatch_url=$2;
				$swatch_url=~s/\?[^>]*?$//is;
				$swatch_url='http://slimages.macys.com/is/image/MCY/products/'.$swatch_url if($swatch_url!~m/^\s*http/is);
				my ($imgid,$img_file)=&DBIL::ImageDownload($swatch_url,'swatch',$retailer_name);
				my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$swatch_url,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				$content2=~s/<li[^>]*?>\s*<img[^>]*?id="swatch[^>]*?(?:tiltle|alt)="\s*\Q$color_valu\E\s*"[^>]*?>\s*<input[^>]*?value="\/*([^<"]*?)"[^>]*?>//is;
			}
		}
		KEY_CHECK:
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
		MP:
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
sub make_proper
{
	my ($string) = @_;
	my @words = split (/\s/, $string);
	my @new_words;
	foreach my $word (@words) 
	{
		my $new_word = ucfirst lc $word;
		push (@new_words, $new_word);
	}
	my $new_string = join(" ", @new_words);
	return ($new_string);
}
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