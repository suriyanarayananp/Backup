#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Davidjones_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";

# Required Variable declaration 
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Davidjones_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger = shift;
	$robotname='Davidjones-AU--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='dav';
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
		my @query_string;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://shop.davidjones.com.au'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content = &GetContent($url3);
		$content=decode_entities($content);
		# utf8::decode($content);
		my $ofs=$1 if($url3=~m/^\s*(htt[^>]*?)\/[^\/]*?$/is);
		
		my (%sku_objectkey,%image_objectkey,%hash_default_image,%color_code);
		my @color_arr;
		my ($product_name,$product_id,$price,$price_text,$brand,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		#Product_name
		if ($content =~ m/<h1[^>]*?id="catalog[^>]*?>\s*([\w\W]*?)\s*<\/h1>/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		#Product_id
		if($content=~m/<input[^>]*?id="productId"[^>]*?value="([^>"]*?)"[^>]*?>/is)
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		elsif ($content =~ m/productId\s*\:\s*\"([^>"]*?)\"/is)
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#Price & Price_text
		if ($content =~ m/(<span[^>]*?="price[^>]*?>[\w\W]*?)<\/span>\s*<\/div>/is)
		{
			$price_text = $1;
			if($price_text=~m/Price\s*pending/is)
			{
				goto XP;
			}
			if ($price_text =~ m/sale\"[^>]*?>\s*([^>]*?)\s*</is)
			{
				$price = $1;
			}
			else
			{
				$price=$price_text;
			}
			$price=~s/\$//gs;
			$price_text=~s/<span[^>]*?>\s*(\$[^>]*?)<span[^>]*?>\s*([^>]*?)\s*<\/span>/$2 $1/igs;
			$price_text=~s/(?:\h)+/ /gs;
			$price_text =~ s/<[^>]*?>/ /igs;
			$price_text =~ s/\s+/ /igs;
			$price_text =~ s/^\s+//is;
			$price_text =~ s/\s+$//is;			
			if($price=~m/(\d+\.\d+)\s*\-\s*(\d+\.\d+)/is)
			{
				my $v1=$1;
				my $v2=$2;
				if($v1<$v2)
				{
					$price=$v1;
				}
				else
				{
					$price=$v2;
				}	
			}
			$price=~s/<[^>]*?>/ /igs;
			$price=~s/\s+/ /igs;
			$price=~s/^\s+//is;
			$price=~s/\s+$//is;
			$price=~s/[^\d\.]//igs;
		}
		#Brand
		if($content =~ m/<input[^>]*?id="manufacturerName"[^>]*?value="\s*([^>"]*?)\s*"[^>]*?>/is)
		{
			$brand =$1;
		}
		elsif ($content =~ m/\'brand\'\s*:\s*\'\s*([^>\}]*?)\s*\'\s*\}/is)
		{
			$brand =$1;
		}
		$brand=~s/\\//igs;
		#DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid) if($brand ne '');
		
		#Description & Product Details
		
		if($content =~ m/<\![^>]*?Product\s*Information[^>]*?>\s*<div[^>]*?class="tab-content"[^>]*?>\s*(<p[^>]*?>[\w\W]*?<\/p>)/is)
		{
			my $prod_info=$1;
			$prod_info=~s/<p[^>]*?>\s*\d+\-\d+\s*<\/p>//is;
			if($prod_info=~m/<p[^>]*?>\s*([^>]+?)\s*(<br[^>]*?>[\w\W]*?)<\/p>/is)
			{
				$description = &DBIL::Trim($1);
				$prod_detail = $2;
				$prod_detail=~s/<BR[^>]*?>\s*\-/ * /igs;
				$prod_detail=~s/<[^>]*?>/ /igs;
				$prod_detail=~s/\s+/ /igs;
				$prod_detail=~s/^\s+//is;
				$prod_detail=~s/\s+$//is;
			}	
			else
			{
				$description = &DBIL::Trim($prod_info);
			}
		}
		if(($description=~m/^\s*$/is) && ($prod_detail=~m/^\s*$/is))
		{
			$description='-';
		}
		####Size Collection
		$content=~s/<option[^>]*?>\s*SELECT\s*<\/option>//igs;
		my (@sizes,@colours);
		if($content=~m/<label[^>]*?>\s*Size\s*\:?\s*<\/label>\s*<select[^>]*?>([\w\W]*?)<\/select>/is)
		{
			my $size_block=$1;
			while($size_block=~m/<option[^>]*?>\s*([^<]*?)\s*<\/option>/igs)
			{
				push(@sizes,$1);
			}
		}
		elsif($content=~m/<p[^>]*?>\s*Size\s*\:?\s*([^<]+?)\s*</is)
		{
			push(@sizes,$1);
		}
		if($content=~m/<label[^>]*?>\s*Colour\s*\:?\s*<\/label>\s*<select[^>]*?>([\w\W]*?)<\/select>/is)
		{
			my $colour_block=$1;
			while($colour_block=~m/<option[^>]*?>\s*([^<]*?)\s*<\/option>/igs)
			{
				push(@colours,$1);
			}
		}
		elsif($content=~m/<p[^>]*?>\s*Colour\s*\:\s*([^<]+?)\s*</is)
		{
			push(@colours,$1);
		}
		elsif($content=~m/<div[^>]*?id="skuSelectionArea"[^>]*?>\s*<p[^>]*?>\s*Colour\s*\:?\s*([^<]+?)\s*</is)
		{
			push(@colours,$1);
		}
		my $size_len=scalar(@sizes);
		my $colour_len=scalar(@colours);
		####SKU and Out of Stock
		if($content=~m/<div[^>]*?id="entitledItem[^>]*?>\s*\[\s*(\{[\w\W]*?\})\s*\]\s*<\/div>/is)
		{	
			my $item_block=$1;
			if(($size_len>0) && ($colour_len>0))
			{
				foreach my $size_name(@sizes)
				{
					$size_name=~s/\s*\"\s*$/inches/is;
					foreach my $color_name(@colours)
					{
						while($item_block=~m/"catentry_id"\s*\:\s*"([^>"]*?)"\s*\,\s*"Attributes"\s*\:\s*\{([^\{\}]*?)\}/igs)
						{
							my $catentryid=$1;
							my $catentryid_blk=$2;
							if(($catentryid_blk=~m/"Size_\Q$size_name\E"\s*\:\s*"/is) && ($catentryid_blk=~m/"Colour_\Q$color_name\E"\s*\:\s*"/is)) 
							{
								my $outofstock_url=$ofs.'/GetCatalogEntryInventoryData';
								my $clen='storeId=10051&langId=-1&catalogId=10051&itemId='.$catentryid.'&nodesType=online';
								my $ofs_content = &GetContent($outofstock_url,'POST',$clen);
								$out_of_stock='n';
								if($ofs_content!~m/"name"\s*:\s*"Available"/is)
								{
									$out_of_stock='y';
								}
								my $price_url='http://shop.davidjones.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID';
								my $price_clen='storeId=10051&langId=-1&catalogId=10051&productId='.$catentryid.'&fromPage=&parentProductId=';
								my $price_content = &GetContent($price_url,'POST',$price_clen);
								if($price_content=~m/"offerPriceNoFormat"\s*:\s* "([^>"]*?)"/is)
								{
									$price=$1;
								}
								my $color_variation=$1 if($content=~m/\{\s*"colour"\s*:\s*"\s*\Q$color_name\E\s*"\s*,\s*"variation"\s*:\s*"([^>]*?)"\s*\}/is);
								if($color_variation=~m/^\s*$/is)
								{
									$color_variation=$color_name;
									$color_variation=~s/\s+//igs;
								}
								$size_name=~s/inches\s*$/"/is;
								$price='NULL' if($price=~m/^\s*$/is);
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size_name,$color_name,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color_variation;
							}
						}	
					}
				}
			}
			elsif($size_len>0)
			{
				foreach my $size_name(@sizes)
				{
					$size_name=~s/\s*\"\s*$/inches/is;
					while($item_block=~m/"catentry_id"\s*\:\s*"([^>"]*?)"\s*\,\s*"Attributes"\s*\:\s*\{\s*"Size_\Q$size_name\E"\s*\:\s*"/igs)
					{
						my $catentryid=$1;
						my $outofstock_url=$ofs.'/GetCatalogEntryInventoryData';
						my $clen='storeId=10051&langId=-1&catalogId=10051&itemId='.$catentryid.'&nodesType=online';
						my $ofs_content = &GetContent($outofstock_url,'POST',$clen);
						$out_of_stock='n';
						if($ofs_content!~m/"name"\s*:\s*"Available"/is)
						{
							$out_of_stock='y';
						}
						my $price_url='http://shop.davidjones.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID';
						my $price_clen='storeId=10051&langId=-1&catalogId=10051&productId='.$catentryid.'&fromPage=&parentProductId=';
						my $price_content = &GetContent($price_url,'POST',$price_clen);
						if($price_content=~m/"offerPriceNoFormat"\s*:\s* "([^>"]*?)"/is)
						{
							$price=$1;
						}
						my $color_variation='NA';
						if($content=~m/\{\s*"colour"\s*:\s*"\s*default\s*"\s*,\s*"variation"\s*:\s*"([^>]*?)"\s*\}/is)
						{
							$color_variation=$1;
							$color_variation=~s/\s+//igs;
						}
						$size_name=~s/inches\s*$/"/is;
						$price='NULL' if($price=~m/^\s*$/is);
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size_name,'no raw colour',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color_variation;
					}	
				}
			}
			elsif($colour_len>0)
			{
				foreach my $color_name(@colours)
				{
					while($item_block=~m/"catentry_id"\s*\:\s*"([^>"]*?)"\s*\,\s*"Attributes"\s*\:\s*\{\s*"Colour_\Q$color_name\E"\s*\:\s*"/igs)
					{
						my $catentryid=$1;
						my $outofstock_url=$ofs.'/GetCatalogEntryInventoryData';
						my $clen='storeId=10051&langId=-1&catalogId=10051&itemId='.$catentryid.'&nodesType=online';
						my $ofs_content = &GetContent($outofstock_url,'POST',$clen);
						$out_of_stock='n';
						if($ofs_content!~m/"name"\s*:\s*"Available"/is)
						{
							$out_of_stock='y';
						}
						my $price_url='http://shop.davidjones.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID';
						my $price_clen='storeId=10051&langId=-1&catalogId=10051&productId='.$catentryid.'&fromPage=&parentProductId=';
						my $price_content = &GetContent($price_url,'POST',$price_clen);
						if($price_content=~m/"offerPriceNoFormat"\s*:\s* "([^>"]*?)"/is)
						{
							$price=$1;
						}
						my $color_variation=$1 if($content=~m/\{\s*"colour"\s*:\s*"\s*\Q$color_name\E\s*"\s*,\s*"variation"\s*:\s*"([^>]*?)"\s*\}/is);
						if($color_variation=~m/^\s*$/is)
						{
							$color_variation=$color_name;
							$color_variation=~s/\s+//igs;
						}
						$price='NULL' if($price=~m/^\s*$/is);
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'no size',$color_name,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color_variation;
					}	
				}
			}
			else
			{
				if($item_block=~m/"catentry_id"\s*\:\s*"([^>"]*?)"\s*\,\s*"Attributes"\s*\:\s*\{\s*\}/is)
				{
					my $catentryid=$1;
					my $outofstock_url=$ofs.'/GetCatalogEntryInventoryData';
					my $clen='storeId=10051&langId=-1&catalogId=10051&itemId='.$catentryid.'&nodesType=online';
					my $ofs_content = &GetContent($outofstock_url,'POST',$clen);
					$out_of_stock='n';
					if($ofs_content!~m/"name"\s*:\s*"Available"/is)
					{
						$out_of_stock='y';
					}
					my $price_url='http://shop.davidjones.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID';
					my $price_clen='storeId=10051&langId=-1&catalogId=10051&productId='.$catentryid.'&fromPage=&parentProductId=';
					my $price_content = &GetContent($price_url,'POST',$price_clen);
					if($price_content=~m/"offerPriceNoFormat"\s*:\s* "([^>"]*?)"/is)
					{
						$price=$1;
					}
					my $color_variation='NA';
					if($content=~m/\{\s*"colour"\s*:\s*"\s*default\s*"\s*,\s*"variation"\s*:\s*"([^>]*?)"\s*\}/is)
					{
						$color_variation=$1;
						$color_variation=~s/\s+//igs;
					}
					$price='NULL' if($price=~m/^\s*$/is);
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'no size','no raw colour',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color_variation;
				}
				elsif($item_block=~m/<div[^>]*?class="fluid-display"[^>]*?>\s*<img[^>]*?src="[^>"]*?\/main_variation_([^>]*?)_view_\d+_/is)
				{
					my $color_variant=$1;
					if($item_block=~m/"catentry_id"\s*\:\s*"([^>"]*?)"\s*\,\s*"Attributes"\s*\:\s*\{[^\}]*?"(?:Colour|DM\s*Briefed)_[^>"]*?"\s*\:\s*"[^\}]*?}/is)
					{	
						my $catentryid=$1;
						my $outofstock_url=$ofs.'/GetCatalogEntryInventoryData';
						my $clen='storeId=10051&langId=-1&catalogId=10051&itemId='.$catentryid.'&nodesType=online';
						my $ofs_content = &GetContent($outofstock_url,'POST',$clen);
						$out_of_stock='n';
						if($ofs_content!~m/"name"\s*:\s*"Available"/is)
						{
							$out_of_stock='y';
						}
						my $price_url='http://shop.davidjones.com.au/webapp/wcs/stores/servlet/GetCatalogEntryDetailsByID';
						my $price_clen='storeId=10051&langId=-1&catalogId=10051&productId='.$catentryid.'&fromPage=&parentProductId=';
						my $price_content = &GetContent($price_url,'POST',$price_clen);
						if($price_content=~m/"offerPriceNoFormat"\s*:\s* "([^>"]*?)"/is)
						{
							$price=$1;
						}
						my $color_variation=$color_variant;
						if($content=~m/\{\s*"colour"\s*:\s*"\s*default\s*"\s*,\s*"variation"\s*:\s*"([^>]*?)"\s*\}/is)
						{
							$color_variation=$1;
							$color_variation=~s/\s+//igs;
						}
						$price='NULL' if($price=~m/^\s*$/is);
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'no size','no raw colour',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color_variation;
					}
				}
			}	
		}
		###Swatch
		while($content=~m/<li[^>]*?id="swatch_([^>"]*?)"[^>]*?>\s*<a[^>]*?>\s*<img[^>]*?class=["']productSwatch["'][^>]*?src=['"]([^>]*?)['"]\s*alt/igs)
		{
			my $color_variation=$1;
			my $imageurl=$2;
			my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'swatch',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$color_variation;
			$hash_default_image{$img_object}='n';
		}
		# Image
		my $mainimage_url_forming=$1.'/js/data.js' if($content=~m/<div[^>]*?class="fluid-display"[^>]*?>\s*<img[^>]*?src="([^>"]*?)\/main_variation[^>"]*?"/is);
		my $mainimage_content=&GetContent($mainimage_url_forming);
		while($mainimage_content=~m/\{\s*"url"\s*\:\s*"[\.\/]*([^>\{\}"]*?)"\s*\,\s*"category_mapping"\s*:\s*\[[^>\]]*?\{\s*"group_id"\s*:\s*"IMAGETYPE"\s*,\s*"id"\s*:\s*"MAIN"[^>\]]*?\}\s*\]\s*\}/igs)
		{
			my $imageurl = $1;
			if($imageurl!~m/^\s*http/is)
			{
				$imageurl='http://cdncf-au.fluidretail.net/'.$imageurl;
			}
			my ($color_variation,$type); 
			if($imageurl=~m/_variation_([^>]*?)_view_(\d+)_/is)
			{
				$color_variation=$1;
				$type=$2;
			}
			my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$color_variation;
			if($type=~m/^\s*0?1\s*$/is)
			{
				$hash_default_image{$img_object}='y';
			}	
			else
			{
				$hash_default_image{$img_object}='n';
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
		XP:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		#DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag);
		LAST:
		$dbh->commit();
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

