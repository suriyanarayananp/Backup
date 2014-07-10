package Whistles_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################

my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Whistles_UK_DetailProcess()
{	
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;	
	my $retailer_id=shift;
	$robotname='Whistles-UK--Detail';
	####Variable Initialization##############
$robotname =~ s/\.pl//igs;
$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
my $retailer_name=$robotname;
my $robotname_detail=$robotname;
my $robotname_list=$robotname;
$robotname_list =~ s/\-\-Detail/--List/igs;
$retailer_name =~ s/\-\-Detail\s*$//igs;
$retailer_name = lc($retailer_name);
my $Retailer_Random_String='Whi';
my $pid = $$;
my $ip = `/sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`;
$ip = $1 if($ip =~ m/inet\s*addr\:([^>]*?)\s+/is);
my $excuetionid = $ip.'_'.$pid;
###########################################

############Proxy Initialization#########
my $country = $1 if($robotname =~ m/\-([A-Z]{2})\-\-/is);
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
	my @query_string;

	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;	
		$url3=~s/&amp;/&/igs;
		$url3=~s/\?[^>]*?$//igs;
		my $content2 = lwp_get($url3);		
		#goto PNF if($content2=~m/No\s*pricing\s*information\s*available/is);
		goto PNF if($content2==1);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;	
		my ($price,$price_text,$brand,$product_id,$color,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$size);
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);


	#product_name
	if($content2=~m/itemprop\=\"name\">([^>]*?)</is )
	{
		$product_name=&DBIL::Trim($1);
			
	}
	#product_id
	if($content2=~m/Product\s*Key:\s*(?:\s*<[^>]*?>\s*)*([^<]*?)</is)
	{
		$product_id=&DBIL::Trim($1);
		my $ckproduct_id=&DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
		goto ckp if($ckproduct_id==1);
		undef($ckproduct_id);
		
	}
	#description
	if($content2=~m/<div\s*itemprop\=\"description\">\s*<div\s*class\=\"content\">\s*([^>]*?)\s*</is)
	{		
		$description = DBIL::Trim($1);	
	}
	
	#details
	if ( $content2 =~ m/Details<\/h3>([\w\W]*?)<\/li>/is)
	{
		$prod_detail = $1;
		$prod_detail=~s/<\/p>/,/igs;	
		$prod_detail=~s/<[^>]*?>//igs;	
		$prod_detail = DBIL::Trim($prod_detail);		
	}
	#BRAND
	$brand='Whistles';
	#mulit colour
	while($content2 =~ m/<li\s*class\=\"emptyswatch[^>]*?\">\s*<a\s*href\=([^>]*?)\s*title/igs )
	{		
		my $url4 = $1;
		$url4=~s/\&amp\;/&/igs;
		print "Colour based URL:: $url4\n";
		####$url4=$url4.'&Quantity=1&biw=1903&format=ajax';		### Add to Bag Option ## Removed
		###my $url4 = "$1&Quantity=1&biw=1903&format=ajax";
		##&Quantity=1&biw=1903&format=ajax"
		my $content3 = lwp_get($url4);
		
		#price_text
		
		if($content3=~m/<div class="product-price">([\w\W]*?)<\/div>/is)
		{
			my $price_content=$1;
			if($price_content=~m/<span\s*class\=\"price\-current\">([^>]*?)<\/span>/is)
			{
				$price_text = $1;
				$price_text=~s/\&pound\;/\£/igs;
				$price_text=~s/\s*<[^>]*?>\s*/ /igs;
				$price_text = DBIL::Trim($price_text);
				$price=$price_text;
			}
			else
			{
				while($price_content=~m/<span\s*class\=\"price[^>]*?>([^>]*?)<\/span>/igs)
				{
					$price_text = $price_text.' '.&DBIL::Trim($1);
					$price_text=~s/\&pound\;/\£/igs;					
				}
				$price_text =~s/^\s+//igs;
				if($price_content=~m/<span\s*class\=\"price\-discounted\">\s*([^>]*?)\s*<\/span>/is)
				{
					$price=&DBIL::Trim($1);
				}
			}
	
			$price=~s/\£//igs;
			$price=~s/\&pound\;//igs;
			
			if($price=~m/\s*NULL\s*/is)
			{
				$price='NULL';
			}
			elsif($price=~m/^\s*$/is)
			{
				$price='NULL';
			}

		}
		
		#color
		#color
		if($content3=~m/Colour\s*\:\s*<span>\s*([^>]*?)\s*</is)
		{		
			$color = DBIL::Trim($1);	
			if($color=~m/NULL/is)
			{
				if($url4=~m/\=([\w\\\/\d\s\%\-]+?)$/is)
				{
					$color=DBIL::Trim($1);
					$color=~s/\%20/ /igs;
				}
				else
				{
					$color='no raw colour';
				}
			}
			
			if($color=~m/^\s*$/is)
			{
				$color='no raw colour';
			}			
		}
		else
		{
			$color='no raw colour';
		}
		
		# if($content3=~m/Colour\:\s*<span>\s*([^>]*?)\s*</is)
		# {		
			# $color = DBIL::Trim($1);	
		# }	
		
		
		#size		
		if($content3=~m/Select\s*SIZE<\/span>([\w\W]*?<\/a>)\s*<\/li>\s*<\/ul>/is)
		{
			my $block=$1;
			while($block=~m/<span>([^>]*?)<\/span>(?:([^>]*?))?\s*</igs)
			{
				$size=$1;
				my $instock=$2;
				$out_of_stock='n';
				if($instock=~m/Out\s*of\s*Stock/is)
				{
					$out_of_stock='y';
				}
				print "Entered into the Sku\n";
				my($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag=1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				print "SKU Query:: $query\n";
			}
		}
		else
		{
			###if($content3=~m/<span\s*class\=\"selected\-value\s*no\-dropdown\">\s*<span>([^>]*?)<\/span>\s*<\/span>/is)
			if($content3=~m/<span\s*class\=\"selected\-value\s*no\-dropdown\"><span>([^>]*?)<\/span>([^>]*?)<\/span>/is)
			{
				$size=$1;
				my $instock=$2;
				$out_of_stock='n';
				if($instock=~m/Out\s*of\s*Stock/is)
				{
					$out_of_stock='y';
				}
				# if($content3=~m/disabled\">\s*Out\s*of\s*Stock\s*<\/button>/is) ### Removed, this is logically wrong for Out of stock mapping
				# {
					# $out_of_stock='y';
				# }
				print "SKU PART 2:: Colour:: $color -----> $out_of_stock :: $url3 , $product_name , $price , $price_text , $size\n";
				my($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag=1 if($flag);
				$sku_objectkey{$sku_object}=$color;
			}
			elsif($content3=~m/<span\s*class\=\"selected\-value\s*no\-dropdown\"><span>([^>]*?)<\/span>/is)
			{
				$size=$1;				
				$out_of_stock='n';	
				# if($content3=~m/disabled\">\s*Out\s*of\s*Stock\s*<\/button>/is) ### Removed, this is logically wrong for Out of stock mapping
				# {
					# $out_of_stock='y';
				# }				
				print "SKU PART 2:: Colour:: $color -----> $out_of_stock :: $url3 , $product_name , $price , $price_text , $size\n";
				my($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag=1 if($flag);
				$sku_objectkey{$sku_object}=$color;
			}
		}
		
		#swatch image
		###if($content3=~m/class\=\"swatchanchor\"\s*[^>]*?\=\"background\:\s*url\(([^>]*?)\)/is)
		if($content3=~m/title\=\"\s*$color\s*\"\s*class\=\"swatchanchor\"\s*[^>]*?\=\"background\:\s*url\(([^>]*?)\)/is)
		{
			my $swac_img=$1;
			my ($imgid,$img_file) = &DBIL::ImageDownload($swac_img,'swatch',$retailer_name);
			my ($img_object,$flag) = &DBIL::SaveImage($imgid,$swac_img,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$color;
			$hash_default_image{$img_object}='n';
		}	
		#Mainimage
		my $count=1;
		while($content3=~m/rel\=\"mainImage\"\s*href\=\"([^>]*?)\"/igs)#product Image
		{
			my $product_image1=$1;
			if ($count eq 1)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
			}
			else		
			{
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
			$count++;
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);		
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		ckp:
		$dbh->commit();
	}	
}1;

sub lwp_get()
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
	my $content;
	if($code =~m/20/is)
	{
		$content = $res->content;
		return $content;
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep 1;
			goto Home;
		}
		return 1;
	}	
}
	
		