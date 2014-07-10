#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Kohls_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
#require "/opt/home/merit/Merit_Robots/DBIL_Updated/DBIL.pm"; # USER DEFINED MODULE DBIL.PM
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Kohls_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Kohls-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Koh';
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
		$url3='http://www.kohls.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &lwp_get($url3);
		my $cont1=$content2;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$img_file,$imagei,$imageid,$colorid,$imageurl,$image1,$size,$defualtimage,$multicol,$swatchid,$swatchurl,$sizeid,$sizes,$skucon,$pricecon);
		my(@imagearry,@imageconarry,@swatcharry,@sizearry);
		my @query_string;
		my (%swat_hash,%size_hash);
		my (%size_hash,%swatch_hash,%sku_objectkey,%image_objectkey,%hash_default_image);
		my $mflag;
		if($content2=~m/<title>\s*Product_Not_Available\s*<\/title>|We\'re\s*sorry\,\s*this\s*item\s*is\s*no\s*longer\s*available/is)
		{
			goto MP;
		}
		my $block1=$1 if($content2=~m/<div[^>]*?class\s*\=\s*\"\s*size\s*\-\s*waist\s*\"\s*>([\w\W]*?)\s*<\s*\/div>\s*<\s*\/div>/is);
		###product_id
		if ( $content2 =~ m/productID\s*\=\s*\'\s*([^>]*?)\s*\'/is )
		{
			$product_id = trim($1);  
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		###product_name
		if ($content2=~m/<title>\s*([^>]*?)\s*<\/title>/is)
		{
			$product_name = trim($1);
		}
		elsif($content2=~m/<h1\s*class\=\"title\s*productTitleName\">\s*([^>]*?)\s*<\/h1>/is)
		{
			$product_name = trim($1);
		}
		if($product_name eq "")
		{
			if($content2=~m/<h1\s*class\=\"title\s*productTitleName\">\s*([^>]*?)\s*<\/h1>/is)
			{
				$product_name = trim($1);
			}
		}
		###Brand
		$brand = trim($1) if ($content2=~m/kohlscom_product_recommendations\s*[^>]*?brand\s*\=([^>]*?)\"/is);
		if ( $brand !~ /^\s*$/g )
		{
			&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		}
		###Description
		$description = trim($1) if ( $content2=~m/<div\s*class\s*\=\s*\"Bdescription\s*\"\s*>([\w\W]*?)<\/p>/is);
		###Product_Detail
		$prod_detail = trim($1) if ( $content2=~m/<div\s*class\s*\=\s*\"Bdescription\s*\"\s*>[\w\W]*?<\/p>([\w\W]*?)<\/div>\s*<\/div>/is);
		$prod_detail =~s/\\//igs;
		### Mulitiple Product#####
		if($content2=~m/Collection\s*Details/s)
		{
			$mflag = 1;
			goto MP;
		}
		###color
		if($content2=~m/class\=\"swatch\-container\-new\">([\w\W]*?)class\=\"spacer\-dotted\"/is)
		{
			my $imagecont=$1;
			while($imagecont=~m/<div\s*id\=\"([^>]*?)\"[^>]*?>\s*<a[^>]*?title\=\"([^>]*?)\"[^>]*?url\(\'([^>]*?)\'[^>]*?rel\=\"([^>]*?)\?/igs)
			{
				$swatchid=$1;
				$color=trim($2);
				$swatchurl=trim($3);
				$imageurl=$4."?wid=1000&hei=1000&op_sharpen=1";
				$swat_hash{$swatchid}=$color;
				push(@swatcharry,$swatchid);
				######Swatch url######
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatchurl,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatchurl,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
				#########main image#######
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
				
			}
		}
		unless($content2=~m/class\=\"swatch\-container\-new\">([\w\W]*?)class\=\"spacer\-dotted\"/is)
		{
			$imageurl=$1 if($content2=~m/class\=\"cloud\-zoom\"[^>]*?href\=\"([^>]*?)\"/is);
			my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$product_id;
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);
			
		}
		if($content2=~m/id\=\"size\-waist\"([\w\W]*?)class\=\"spacer\-dotted\"/is)
		{
			my $sizecont=$1;
			while($sizecont=~m/<div\s*id\=\"([^>]*?)\"[^>]*?>\s*<a[^>]*?>\s*([^>]*?)\s*<\/a>/igs)
			{
				$sizeid=$1;
				$sizes=trim($2);
				$size_hash{$sizeid}=$sizes;
				push(@sizearry,$sizeid);
				
			}
		}
		$skucon=$1 if($content2=~m/allVariants\=([\w\W]*?)\]/is);
		if($skucon=~m/\"SkuSalePrice\"\:\"\s*([^>]*?)\s*\"\,\s*\"SkuRegularPrice\"\:\"\s*([^>]*?)\"\,[^>]*?\"salePriceLabel\"\:\"([^>]*?)\s*\"\,\s*\"regularPriceLabel\"\:\"\s*([^>]*?)\"/is)
		{
			my $Salepric=trim($1);
			my $regularprice=trim($2);
			my $slaelabel=trim($3);
			my $regularlabel=trim($4);
			if($Salepric eq "")
			{
				$price_text=$regularlabel." ".$regularprice;
				$price=trim($1) if($regularprice=~m/\$([\d+\,\.]*?)$/is);
				$price=~s/\,//igs;	
			}
			else
			{
				$price_text=$slaelabel." ".$Salepric." ".$regularlabel." ".$regularprice;
				$price=trim($1) if($Salepric=~m/\$([\d+\,\.]*?)$/is);
				$price=~s/\,//igs;	
			}
			if($Salepric=~m/\//is)
			{
				$price=trim($1) if($regularprice=~m/\$([\d+\,\.]*?)$/is);
				$price=~s/\,//igs;
			}
		}
		if($content2=~m/<ul\s*class\=\"\s*productcdMenu\s*\"\s*>/is)
		{
			if($content2=~m/Please\s*Select\s*a\s*Size/is)
			{
				if($content2=~m/select\-color\-here/is)
				{
					foreach(@swatcharry)
					{
						my $tempSwatid=$_;
						$color=$swat_hash{$tempSwatid};
						foreach(@sizearry)
						{
							my $tempSize=$_;
							$size=$size_hash{$tempSize};
							if($skucon=~m/color\"\:\"\Q$tempSwatid\E\"\,\s*\"size2\"\:\"\Q$tempSize\E\"\,[^>]*?\"inventoryStatus\"\:\"\s*([^>]*?)\"/is)
							{
								my $invace=trim($1);
								$out_of_stock="n";
								$out_of_stock="y" unless($invace eq "true");
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
							else
							{
								$out_of_stock="y";
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
						}
					}
				}
			}
			if($content2=~m/Please\s*Select\s*a\s*Size/is)
			{
				unless($content2=~m/select\-color\-here/is)
				{
					foreach(@sizearry)
					{
						my $tempSize=$_;
						$size=$size_hash{$tempSize};
						$color="NO COLOR";
						if($skucon=~m/size2\"\:\"\Q$tempSize\E\"\,[^>]*?\"inventoryStatus\"\:\"\s*([^>]*?)\"/is)
						{
							my $invace=trim($1);
							$out_of_stock="n";
							$out_of_stock="y" if($invace ne 'true');
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$product_id;
							push(@query_string,$query);
						}
						else
						{
							$out_of_stock="y";
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$product_id;
							push(@query_string,$query);
						}
					}
					
				}
			}
			unless($content2=~m/Please\s*Select\s*a\s*Size/is)
			{
				if($content2=~m/select\-color\-here/is)
				{
					foreach(@swatcharry)
					{
						my $tempSwatid=$_;
						$color=$swat_hash{$tempSwatid};
						$size="NO SIZE";
						if($skucon=~m/color\"\:\"\Q$tempSwatid\E\"[^>]*?inventoryStatus\"\:\"\s*([^>]*?)\"/is)
						{
							my $invace=trim($1);
							$out_of_stock="n";
							$out_of_stock="y" if($invace ne 'true');
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
						else
						{
							$out_of_stock="y";
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
						
					}
				}
			}
			unless($content2=~m/Please\s*Select\s*a\s*Size/is)
			{
				unless($content2=~m/select\-color\-here/is)
				{
					$out_of_stock="n";
					$size="NO SIZE";
					$color="NO COLOR";
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$product_id;
					push(@query_string,$query);
				}
			}
		}
		# unless($content2=~m/<ul\s*class\=\"\s*productcdMenu\s*\"\s*>/is)
		# {
			# $out_of_stock="y";
			# $size="NO SIZE";
			# $color="NO COLOR";
			# $price=~s/\,//igs;
			# $price='NULL' if($price eq '');
		   # my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
		   # $skuflag = 1 if($flag);
		   # $sku_objectkey{$sku_object}=$product_id;
		   # push(@query_string,$query);
		# }
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
		# my $query=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		print "";
		$dbh->commit();
	}
}1;
sub lwp_get() 
{ 
    REPEAT: 
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
    if($code =~ m/50/is) 
    {        
        goto REPEAT; 
    } 
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
	$txt =~ s/\&\#163\;/£/ig;
	$txt =~ s/\&pound\;/£/ig;
	$txt =~ s/\&bull\;/•/ig;
	return $txt;
}

