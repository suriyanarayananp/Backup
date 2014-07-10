#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Piperlime_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
# use DBI;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Piperlime_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Piperlime-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Pip';
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
		my $content=&GetContent($url3,'GET','','');
		my $url1;
		if($content=~m/productPage\.loadProductData\(\"(\d+)\"\,\"initial\"\,\"[\d]+\"\)\;/is)
		{
			$url1='http://piperlime.gap.com/browse/productData.do?pid='.$1.'&vid=1&scid=&actFltr=false&locale=en_US&internationalShippingCurrencyCode=&internationalShippingCountryCode=us&globalShippingCountryCode=us';
		}
		else
		{
			goto NOINFO;
		}
		my $content2=&GetContent($url1,'GET','','');
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;my %sku_objectkey;my %image_objectkey;my %hash_default_image;
		my ($price,$price_text,$brand,$product_id,$product_name,$description,$main_image,$prod_detail,$prod_detail1,$prod_detail2,$alt_image,$out_of_stock,$color,$size);
		### Product id
		if( $content2 =~m/ProductStyle\s*\(\"[\d]+\"\,\"(\d+)\"/is )
		{
			$product_id=&DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
		}
		### Product Description
		if ( $content2 =~ m/objP\.setArrayInfoTabInfoBlocks\(objP\.arrayInfoTabs\[[\d]+\]\,\s*\"[\d]+([\w\W]*?)\,\^false\"\)\;/is )
		{
			$description = $1;
			$description=~s/\^[\d]+\^/\n* /igs;
			$description=~s/\^\,\^false||[\d]+\^\,//igs;
			$description=~s/\^//igs;
			$description=~s/\,//igs;
			$description=~s/\&\#39\;/\'/igs;
			$description=~s/\|\|//igs;
			$description=~s/^\s+|\s+$//igs;
			$description=decode_entities($description);
			$description=&DBIL::Trim($description);
		}
		### Product Detail
		if ( $content2 =~ m/objP\.setFabricContent\(objP\.arrayFabricContent\,\"([^<]*?)\"\)\;/is )
		{
			$prod_detail1=$1;
			$prod_detail1=~s/[\d]+\^\,\^//igs;
			$prod_detail1=~s/\^\,\^/ /igs;
			$prod_detail1=~s/\|\|/\, /igs;
			$prod_detail1=~s/\&\#39\;/\'/igs;
			$prod_detail1=~s/\.[\d]/%/igs;
			$prod_detail1=~s/^\s+|\s+$//igs;
			$prod_detail1=decode_entities($prod_detail1);
			$prod_detail1=&DBIL::Trim($prod_detail1);
		}
		if ( $content2 =~ m/\"([^\"]*?)\"\,\"[^\"]*?\"\,\"[a-z]+\"\,\"[a-z]+\"\,\"[a-z]+\"\,[\d]+\,[\d]+\,\"[^\"]*?"\,\"[\d]+\",\"[^\"]*?\"\,[a-z]+\)\;var\s*objP\s*\=\s*objProduct[\d]+\;objP\.strProductId/is )
		{
			$prod_detail2=$1;
			$prod_detail2=decode_entities($prod_detail2);
			$prod_detail2=&DBIL::Trim($prod_detail2);
		}
		$prod_detail=$prod_detail1." ".$prod_detail2;
		$prod_detail=~s/^\s+|\s+$//igs;
		$prod_detail=~s/^\,|\,$//igs;
		undef $prod_detail1;undef $prod_detail2;
		### Title and Brand
		if ( $content2 =~ m/\"([^\"]*?)\"\,\'[^\']*?\'\,\"[^\"]*?\"\,\"[^\"]*?\"\,\"[^\"]*?\"\,\"[a-z]+\"\,\"[a-z]+\"\,\"[a-z]+\"\,[\d]+\,[\d]+\,\"[^\"]*?"\,\"[\d]+\",\"([^\"]*?)\"\,[a-z]+\)\;var\s*objP\s*\=\s*objProduct[\d]+\;objP\.strProductId/is )
		{
			$product_name=&DBIL::Trim($1);
			$brand=&DBIL::Trim($2);
			decode_entities($product_name);
			$brand=~s/\\//igs;
		}
		### Color, Price, size and out of stock
		my $content3=$content2;
		while ( $content2 =~m/arrayVariantStyleColors\[[\d]+\]\s*\=\s*new\s*objP\.StyleColor\s*([^<]*?)\s*arrayVariantStyleColors\[[\d]+\]\.onlyAvailableOnline\s*\=\s*\"[a-z]+\"\;/igs )
		{
			my $block=$1;
			if($block=~m/\"[\d]+\"\,\"([^\"]*?)\"\,[a-z]+\,[a-z]+\,[a-z]+\,[a-z]+\,[a-z]+\,[\d]+\,\"([^\"]*?)\"\,\"([^\"]*?)\"\,undefined\,/is)
			{
				$color=&DBIL::Trim($1);
				$price_text=$2." ".$3;
				$price_text=&DBIL::Trim($price_text);
				$price=$3;
				$price=~s/\$//igs;
				$price=~s/\.00//igs;
			}
			elsif($block=~m/\"[\d]+\"\,\"([^\"]*?)\"\,[a-z]+\,[a-z]+\,[a-z]+\,[a-z]+\,[a-z]+\,[\d]+\,\"([^\"]*?)\"\,undefined\,/is)
			{
				$color=&DBIL::Trim($1);
				$price_text=$2;
				$price=$price_text;
				$price=~s/\$//igs;
				$price=~s/\.00//igs;
			}
			# &DBIL::SaveTag('Colour',lc($color),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		
			my ($size1,$size2);
			if($content3 =~m/objP\.SizeInfoSummary\([\d]+\,[\d]+\,\"([a-z]+)\s*\,\s*([a-z]+)"\,\"[a-z]+"\,\"[a-z]+\"\,\"[\d]+\"\,\"[\d]+\"\,\"([^<]*?)\",\"([^<]+?\|\|[^<]+?)\"\,[a-z]+\,[a-z]+\)\;/is )
			{
				$size1=$1;
				$size2=$2;
				my $size_block=$3;
				my $size_block1=$4;
				
				my (%size1_hash,%size2_hash);
				while($size_block=~m/([\w]*?)\^\,\^(\d+)/igs)
				{
					$size1_hash{$2}=$1;
				}
				while($size_block1=~m/([\w]*?)\^\,\^(\d+)/igs)
				{
					$size2_hash{$2}=$1;
				}
				
				my @size1_keys=keys %size1_hash;
				my @size2_keys=keys %size2_hash;
				foreach my $size1_id(@size1_keys)
				{
					foreach my $size2_id(@size2_keys)
					{
						my $size=$size1_hash{$size1_id};my $size3=$size2_hash{$size2_id};
						my $size_new=$size1.': '.$size.', '.$size2.': '.$size3;
						my $reg=$size1_id.'\^\,\^'.$size2_id;
						if($block=~m/$reg/is)
						{
							my $out_of_stock='n';
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size_new,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
						else
						{
							my $out_of_stock='y';
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size_new,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
					}
				}
			}
			elsif($content3 =~m/objP\.SizeInfoSummary\([\d]+\,[\d]+\,\"([a-z]+)\s*\,\s*([a-z]+)"\,\"[a-z]+"\,\"[a-z]+\"\,\"[\d]+\"\,\"[\d]+\"\,\"([^<]*?)\",\"([^<]*?)\^\,\^[\d]+\"\,[a-z]+\,[a-z]+\)\;/is)
			{
				$size1=$1;
				$size2=$2;
				my $size_block=$3;
				my$size3=$4;
			
				while($size_block=~m/([^<]*?)\^\,\^(\d+)/igs)
				{
					$size=$1;
					my $size_id=$2;
					
					$size=decode_entities($size);
					$size=&DBIL::Trim($size);
					$size=~s/\,\,/\,/igs;$size =~ s/\&\#39\;/\'/ig;$size =~ s/\|//ig;$size =~ s/\|\|//ig;$size =~ s/\\//ig;
					
					if($block=~m/[\d]+\^\,\^$size_id\^\,/igs)
					{
						$out_of_stock='n';
						my $size_new=$size1.': '.$size.', '.$size2.': '.$size3;
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size_new,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
					else
					{
						$out_of_stock='y';
						my $size_new=$size1.': '.$size.', '.$size2.': '.$size3;
						
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size_new,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
				}
			}
			elsif($content3 =~m/objP\.SizeInfoSummary\([\d]+\,[\d]+\,\"([a-z]+)"\,\"[a-z]+\"\,\"\"\,\"[\d]+\"\,\"\"\,\"([^<]*?)\,\"\",[a-z]+\,[a-z]+\)\;/is )
			{
				$size1=$1;
				my $size_block=$2;
				
				while($size_block=~m/([^<]*?)\^\,\^(\d+)/igs)
				{
					$size=$1;
					my $size_id=$2;
					$size=decode_entities($size);
					$size=&DBIL::Trim($size);
					$size=~s/\,\,/,/igs;$size =~ s/\&\#39\;/\'/ig;$size =~ s/\|//ig;$size =~ s/\|\|//ig;$size =~ s/\\//ig;
					
					if($block=~m/[\d]+\^\,\^$size_id\^\,/igs)
					{
						$out_of_stock='n';
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
					else
					{
						$out_of_stock='y';
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
				}
			}
			### Main image
			if ( $block =~m/\'P01\'\:\s*\'([^\']*?)\'/is )
			{
				my $imageurl=$1;
				# $imageurl=url($url3,$imageurl)->abs;
				$imageurl='http://www3.assets-gap.com'.$imageurl unless($imageurl=~m/^http/is);
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
			}
			### Alternate image
			while ( $block =~m/\'AV[\d]+\'\:\s*\'([^\']*?)\'|\'[A-Z]{1,2}VLI\'\:\s*\'([^\']*?)\'/igs )
			{
				my $imageurl=$1.$2;
				# $imageurl=url($url3,$imageurl)->abs;
				$imageurl='http://www3.assets-gap.com'.$imageurl unless($imageurl=~m/^http/is);
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
			
			### swatch
			if ( $block =~m/\'S\'\:\s*\'([^\']*?)\'/is )
			{
				my $imageurl=$1;
				# $imageurl=url($url3,$imageurl)->abs;
				$imageurl='http://www3.assets-gap.com'.$imageurl unless($imageurl=~m/^http/is);
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}			
		}
		undef $content3;undef $content2;
		
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
		undef @image_obj_keys;undef @sku_obj_keys;
		
		NOINFO:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
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
    my $req=HTTP::Request->new($method=>"$mainurl");
    if($method eq 'POST')
    {     
        $req->content("$parameter");
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
    if($code=~m/5|4/is)
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