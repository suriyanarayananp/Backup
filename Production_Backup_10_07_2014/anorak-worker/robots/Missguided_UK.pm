#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Missguided_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# use utf8;
#require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Missguided_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	# $dbh->do("set character set utf8");
	# $dbh->do("set names utf8");
	my @query_string;
	$robotname='Missguided-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Mis';
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
		#my $url = $hashUrl{$product_object_key};
		my $url3=$url;	
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3 =~ s/^\s+|\s+$//g;
		my $content2 = &GetContent($url3);
		$content2=decode_entities($content2);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;	
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock);
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		my $color;
		
		#product_id
		if ($content2=~m/"productId"\s*:\s*"([^>"]*?)"/is)
		#if ($content2=~m/<p[^>]*?class="prod_code"[^>]*?>\s*([^>]*?)\s*<\/p>/is)
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if ( $content2 =~m/="product-[^>]*?>\s*<h\d+[^>]*?>\s*([\w\W]*?)\s*<\/h\d+>\s*(?:<h\d+[^>]*?>\s*([^>]*?)\s*<)?/is)
		{
			$product_name = &DBIL::Trim($1);
			$color=&DBIL::Trim($2);
			$product_name=decode_entities($product_name);
			utf8::decode($product_name);
		}
		if($color=~m/^\s*$/is)
		{
			$color='no raw colour';
		}
		#Description
		if ($content2 =~ m/<div[^>]*?(?:"accordion"|"description")[^>]*?>\s*<h[^>]*?>\s*(?:<a[^>]*?>\s*)?(?:Product\s*Detail[^<]*?|Information[^>]*?)(?:<\/a>\s*)?<\/h\d+>([\w\W]*?)<\/div>/is)
		{
			$description = $1;
		}
		if ($content2 =~ m/<h[^>]*?>\s*(?:<[^>]*?>\s*)*Care\s*Details?\s*(?:<[^>]*?>\s*)*<\/h\d+>([\w\W]*?)<\/div>/is)
		{
			$description =$description.$1;
		}
		$description=~s/<[^>]*?>\s*No\s*<[^>]*?>//igs;
		$description=~s/<p[^>]*?>/ * /igs;
		$description=~s/(?:<br\s*\/*>\s*)+/ * /igs;
		$description = &DBIL::Trim($description);
		$description=~s/(?:\*\s*)+$//is;
		$description=decode_entities($description);
		utf8::decode($description);
		$description=~s/Â//gs;
		$description=~s/\Â//gs;
		
		#Brand
		$brand='Missguided';
		
		#Price & Price Text
		#if ($content2 =~m/<h\d+[^>]*?class="price[^>]*?>([\w\W]*?)<\/h\d+>/is)
		if ($content2 =~m/<p[^>]*?class="prod_code"[^>]*?>\s*[^>]*?<\/p>(?:\s*<\!--[\w\W]*?-->\s*)?<div[^>]*?class="price-box"[^>]*?>([\w\W]*?)<\/div>/is)
		{
			$price_text=$1;
			$price_text=~s/<\!--[\w\W]*?-->/ /igs;
			$price_text =~ s/\&pound\;/\£/ig;
			if($price_text=~m/<span[^>]*?id="product-price[^>"]*?"[^>]*?>\s*([\w\W]*?)\s*<\/span>/is)
			{
				$price=$1;
				$price=~s/[^\d\.]//gs;
			}
			$price_text = &DBIL::Trim($price_text);
			$price_text=decode_entities($price_text);
			$price_text=~s/Â//gs;
			$price_text=~s/\Â//gs;
			$price_text =~s/á//igs;
			utf8::decode($price_text);
			$price_text=~s/\s+/ /igs;
			$price_text=~s/^\s+//is;
			$price_text=~s/\s+$//is;
		}
		$price="NULL" if($price=~m/^\s*$/is);
		# size & out_of_stock
		if($content2 =~m/\(\s*\{\s*"attributes"\s*:\s*\{[^>]*?"options"\s*:\s*\[\s*((?:\{[^>\}]*?"products"\s*\:\s*\[\s*\{\s*[^>\}]*?\}\s*\]\s*\}\s*(?:\,|\])\s*)+)/is)
		{
			my $size_content = $1;
			while($size_content=~m/"label"\s*:\s*"([^\}"]*?)"[^>\}]*?"stock"\s*:\s*"([^>"\}]*?)"/igs)
			{
				my $size=&DBIL::Trim($1);
				my $stock_status=$2;
				$size=~s/\\\//\//igs;
				my $out_of_stock='n';
				if($stock_status=~m/^\s*no(?:\s*$|\s+)/is)
				{
					$out_of_stock='y';
				}
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=lc($color);
			}
		}	
		#MainImage
		if($content2=~m/<img[^>]*?id="main-product-image[^>"]*?"[^>]*?src="([^>"]*?)"/is)
		{
			my $imageurl = &DBIL::Trim($1);
			$main_image=$imageurl;
			my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=lc($color);
			$hash_default_image{$img_object}='y';
		}	
		#AltImage
		if($content2=~m/<ul[^>]*?id="more-views-images[^>"]*?"[^>]*?>([\w\W]*?)<\/ul>/is)
		{
			my $alternate_img_blk=$1;
			while($alternate_img_blk=~m/smallimage\s*:\s*(?:\"|\')([^>\,]*?)(?:\"|\')\s*\,/igs)
			{
				my $imageurl = &DBIL::Trim($1);	
				$imageurl=~s/^\s*$main_image\s*$//is;
				if($imageurl ne '')
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=lc($color);
					$hash_default_image{$img_object}='n';
				}	
			}
		}	
		#swatch
		if($content2=~m/<ul[^>]*?id="swatches[^>"]*?"[^>]*?>([\w\W]*?)<\/ul>/is)
		{
			my $swatch_blk=$1;
			if($swatch_blk=~m/<li[^>]*?class="selected[^>]*?>\s*<img[^>]*?src="([^>"]*?)"/is)
			{
				my $imageurl=&DBIL::Trim($1);
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=lc($color);
				$hash_default_image{$img_object}='n';
			}		
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
		#&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$mflag);
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		print "";
		#$dbh->commit();
	}
}1;
sub Trim
{
	my $string=shift;
	$string=~s/<[^>]*?>/ /igs;
	$string =~ s/\&nbsp\;/ /gs;
	$string =~ s/^\s*n\/a\s*$//igs;
	$string =~ s/\&\#039\;/'/gs;
	$string =~ s/\&\#43\;/+/gs;
	$string =~ s/amp;//gs;
	$string=~s/\s+/ /igs;
	$string=~s/^\s+//is;
	$string=~s/\s+$//is;
	return($string);
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