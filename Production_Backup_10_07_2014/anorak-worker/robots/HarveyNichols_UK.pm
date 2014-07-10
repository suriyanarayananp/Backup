#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package HarveyNichols_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub HarveyNichols_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='HarveyNichols-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Har';
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
		print "\nUrl : $url3\n";
			
		my $content2=&GetContent($url3,'GET','',''); #### Content Fetching
		$content2=replace($content2);  ### Encoding html code to corresponding char.
		my($product_id,$brand,$product_name,$description,$prod_detail,$imag_id,$sku_content,$price_text,$price);
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;my %sku_objectkey;my %image_objectkey;my %hash_default_image;
		### Loop for checking x products
		if( $content2!~m/<div\s*class\=\"product\-name\">\s*<h1>\s*<a[^>]*?>\s*([^<]*?)\s*<\/a>\s*<strong>\s*([^<]*?)\s*<\/strong>\s*<small\s*class\=\"product\-ids\">\s*\(\s*([^<]*?)\s*\)\s*<\/small>\s*<\/h1>\s*<\/div>/is )
		{
			goto NOINFO;
		}
		### Product id and Product Name
		if( $content2=~m/<div\s*class\=\"product\-name\">\s*<h1>\s*<a[^>]*?>\s*[^<]*?\s*<\/a>\s*<strong>\s*([^<]*?)\s*<\/strong>\s*<small\s*class\=\"product\-ids\">\s*\(\s*([^<]*?)\s*\)\s*<\/small>\s*<\/h1>\s*<\/div>/is )
		{
			$product_name=$1;
			$product_id=$2;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
		}
		### Brand
		if( $content2=~m/<div\s*class\=\"product\-name\">\s*<h1>\s*<a[^>]*?>\s*([^<]*?)\s*<\/a>\s*<strong>\s*([^<]*?)\s*<\/strong>\s*<small\s*class\=\"product\-ids\">\s*\(\s*([^<]*?)\s*\)\s*<\/small>\s*<\/h1>\s*<\/div>/is )
		{
			$brand=$1;
			# if ( $brand !~ /^\s*$/g )
			# {
				# &DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			# }
		}
		### Product Description
		if ( $content2=~m/<div\s*class\=\"overview\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
		{
			$description=$1;
			$description=~s/<li>/* /igs;$description=~s/<[^>]*?>//igs;$description=~s/\s+/ /igs;$description=~s/^\s*|\s*$//igs;
		}
		else
		{$description=" ";}
		
		### Price text
		if ( $content2=~m/<\/span>\s*<\/li>\s*<li\s*class\=\"product\-price\">([\w\W]*?)<\/div>/is )
		{
			$price_text = $1;
			$price_text =~ s/<[^>]*?>/ /igs;
			$price_text =~ s/\&nbsp\;|amp\;/ /igs;
			$price_text =~ s/\s+/ /igs;
			$price_text =~ s/^\s+|\s+$//igs;
		}
		### Price
		if($content2 =~ m/property\=\"og\:price\:amount\"\s*content\=\"([^>]*?)\"/is)
		{
			$price = $1;
			$price=~s/\,//igs;
		}
		else{$price='NULL';}
		##### Sku part
		if($content2=~m/<label\s*class\=\'colour\-label\'>\s*Colour\s*\:\s*<\/label>/is) ### This IF loop will be executed if the product is having color.
		{
			my ($color,$swatch);
			if($content2=~m/<li\s*class\=\"swatch\s*selected\">\s*([\w\W]*?)\s*<\/b>\s*<\/li>/is)
			{
				my $block=$1;
				if($block=~m/<em[^>]*?>\s*([^<]*?)\s*<\/em>/is)
				{
					$color=$1; ### Color
				}
				if($block=~m/<img\s*src\=\"([^\"]*?)\"/is)
				{
					$swatch=$1; ### Swatch url
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
			}
			elsif($content2=~m/\{\"id\"\:\"[^\"]*?\"\,\"label\"\:\"([^\"]*?)\"\,\"price\"\:\"[^\"]*?\"\,\"oldPrice\"\:\"[^\"]*?\"\,\"products\"\:\[\"[^\"]*?\"\]\,\"_hidden\"\:[a-z]+\,\"swatch\"\:\"([^\"]*?)\"\,\"selected\"\:true\}/is)
			{
				$color=$1;
				$swatch=$2;
				$swatch=~s/\\//igs;
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
			
			#### Default and Alternative Image
			if($content2=~m/<div\s*class\=\"imageslider\">\s*<ul\s*id\=\"imageslider\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/igs)
			{
				my $image_block=$1;
				my $alt_image=1;
				while($image_block=~m/<li>\s*<img\s*src\=\"([^<]*?)\"\s*[^>]*?>\s*<\/li>/igs)
				{	
					my $default_image=$1;
					if($alt_image==1)#### Default Image
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='y';
						$alt_image++;
						push(@query_string,$query);
					}
					else  ### Alternative Image
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}
				undef $image_block;
			}
			
			my %stock_hash;
			if($content2=~m/<dt><label\s*class\=\"required\">\s*Size\s*<\/label><\/dt>/is) #### IF loop for size
			{
				if($content2=~m/\"lowStock\"\:\{([^<]*?)\}/is)
				{
					my $stock_block=$1; ### block
					while($stock_block=~m/\"(\d+)\"\:(\d+)/igs)
					{
						$stock_hash{$1}=$2;#### key has size id and value has 0's or 1's.
					}
					undef $stock_block;
					while($content2=~m/\[\"(\d+)\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/igs)
					{
						my $size_id=$1;
						my $size=$2;
						
						my $stock_value=$stock_hash{$size_id};
						
						my $out_of_stock;
						$out_of_stock='n' if(($stock_value eq '1') or ($stock_value eq ''));#### In stock
						$out_of_stock='y' if($stock_value eq '0'); #### out of stock
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
				}
				else
				{
					if($content2=~m/\[\"(\d+)\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/is)
					{
						while($content2=~m/\[\"(\d+)\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/igs)
						{
							my $size_id=$1;
							my $size=$2;
							
							my $stock_value=$stock_hash{$size_id};
							
							my $out_of_stock;
							$out_of_stock='n' if(($stock_value eq '1') or ($stock_value eq ''));#### In stock
							$out_of_stock='y' if($stock_value eq '0'); #### out of stock
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
					}
					else
					{
						my $size;my $out_of_stock='n';
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
				}
			}
			else #### Product- color with no size
			{
				my ($size);my $out_of_stock='n';
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
			}
		}
		else  #### product Without color 
		{
			#### Default and Alternative Image
			if($content2=~m/<div\s*class\=\"imageslider\">\s*<ul\s*id\=\"imageslider\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/igs)
			{
				my $image_block=$1;
				my $alt_image=1;
				while($image_block=~m/<li>\s*<img\s*src\=\"([^<]*?)\"\s*[^>]*?>\s*<\/li>/igs)
				{
					my $default_image=$1;
					if($alt_image==1)#### Default Image
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No color';
						$hash_default_image{$img_object}='y';
						$alt_image++;
						push(@query_string,$query);
					}
					else### Alternative Image
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No color';
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}
				undef $image_block;
			}
			
			my %stock_hash;my $color='no raw colour';
			if($content2=~m/<dt><label\s*class\=\"required\">\s*Size\s*<\/label><\/dt>/is)#### IF loop for size
			{
				if($content2=~m/\"lowStock\"\:\{([^<]*?)\}/is)
				{
					my $stock_block=$1;
					while($stock_block=~m/\"(\d+)\"\:(\d+)/igs)
					{
						$stock_hash{$1}=$2;#### key has size id and value has 0's or 1's.
					}
					undef $stock_block;
					if($content2=~m/\[\"(\d+)\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/is)
					{
						while($content2=~m/\[\"(\d+)\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/igs)
						{
							my $size_id=$1;
							my $size=$2;
							
							my $stock_value=$stock_hash{$size_id};
							my $out_of_stock;
							$out_of_stock='n' if(($stock_value eq '1') or ($stock_value eq ''));#### In stock
							$out_of_stock='y' if($stock_value eq '0');#### out of stock
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}='No color';
							push(@query_string,$query);
						}
					}
					elsif($content2=~m/\[\"(\d+)\"\,\"\d+\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/is)
					{
						while($content2=~m/\[\"(\d+)\"\,\"\d+\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/igs)
						{
							my $size_id=$1;
							my $size=$2;
							
							my $stock_value=$stock_hash{$size_id};
							my $out_of_stock;
							$out_of_stock='n' if(($stock_value eq '1') or ($stock_value eq ''));#### In stock
							$out_of_stock='y' if($stock_value eq '0');#### out of stock
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}='No color';
							push(@query_string,$query);
						}
					}
				}
				else #### Product with no size
				{
					if($content2=~m/\[\"(\d+)\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/is)
					{
						while($content2=~m/\[\"(\d+)\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/igs)
						{
							my $size_id=$1;
							my $size=$2;
							
							my $stock_value=$stock_hash{$size_id};
							my $out_of_stock;
							$out_of_stock='n' if(($stock_value eq '1') or ($stock_value eq ''));#### In stock
							$out_of_stock='y' if($stock_value eq '0');#### out of stock
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}='No color';
							push(@query_string,$query);
						}
					}
					elsif($content2=~m/\[\"(\d+)\"\,\"\d+\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/is)
					{
						while($content2=~m/\[\"(\d+)\"\,\"\d+\"\]\,\"brand_size\"\:[^\,]*?\,\"merret_size\"\:[^\,]*?\,\"hn_size\"\:[^\,]*?\,\"shoe_size\"\:[^\,]*?\,\"display_size\"\:\"([^<]*?)\"\}/igs)
						{
							my $size_id=$1;
							my $size=$2;
							
							my $stock_value=$stock_hash{$size_id};
							my $out_of_stock;
							$out_of_stock='n' if(($stock_value eq '1') or ($stock_value eq ''));#### In stock
							$out_of_stock='y' if($stock_value eq '0');#### out of stock
							
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}='No color';
							push(@query_string,$query);
						}
					}
					else
					{
						my ($size);my $out_of_stock='n';
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}='No color';
						push(@query_string,$query);
					}
				}
			}
			else #### Product with no size
			{
				my ($size);my $out_of_stock='n';
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}='No color';
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
sub replace($)
{
	my $text=shift;
	$text=~s/\&trade\;|\&\#8482\;|\&\#0153\;/™/igs;$text=~s/\&euro\;|\&\#8364\;/€/igs;$text=~s/\&euml\;|\&\#203\;/ë/igs;$text=~s/\&ecirc\;|\&\#202\;/ê/igs;$text=~s/\&eacute\;|\&\#201\;/é/igs;$text=~s/\&egrave\;|\&\#200\;/è/igs;$text=~s/\&aring\;|\&\#197\;|\&\#229\;/å/igs;$text=~s/\&auml\;|\&\#228\;|\&\#196\;/ä/igs;$text=~s/\&atilde\;|\&\#195\;|\&\#227\;/ã/igs;$text=~s/\&acirc\;|\&\#194\;|\&\#226\;/â/igs;$text=~s/\&aacute\;|\&\#193\;|\&\#225\;/á/igs;$text=~s/\&agrave\;|\&\#192\;|\&\#224\;/à/igs;$text=~s/\&Ouml\;|\&\#214\;|\&\#246\;/ö/igs;$text=~s/\&Otilde\;|\&\#213\;|\&\#245\;/õ/igs;$text=~s/\&Ocirc\;|\&\#212\;|\&\#244\;/ô/igs;$text=~s/\&Oacute\;|\&\#211\;|\&\#243\;/ó/igs;$text=~s/\&Ograve\;|\&\#210\;|\&\#242\;/ò/igs;$text=~s/\&quot\;|\&\#34\;/"/igs;$text=~s/\&amp\;|\&\#38\;/&/igs;$text=~s/\&apos\;/'/igs;$text=~s/\&nbsp\;|\&\#160\;/ /igs;$text=~s/\&pound\;|\&\#163\;/£/igs;$text=~s/\&copy\;|\&\#169\;/©/igs;$text=~s/\&reg\;|\&\#174\;/®/igs;$text=~s/\&acute\;|\&\#180\;/´/igs;$text=~s/\&Igrave\;|\&\#204\;|\&\#236\;/ì/igs;$text=~s/\&Iacute\;|\&\#205\;|\&\#237\;/í/igs;$text=~s/\&Icirc\;|\&\#206\;|\&\#238\;/î/igs;$text=~s/\&Iuml\;|\&\#207\;|\&\#239\;/ï/igs;$text=~s/\&mdash\;|\&\#8212\;/—/igs;$text=~s/\&ndash\;|\&\#8211\;/–/igs;$text=~s/\&iexcl\;|\&\#161\;/¡/igs;$text=~s/\&cent\;|\&\#162\;/¢/igs;$text=~s/\&curren\;| \&\#164\;/¤/igs;$text=~s/\&yen\;|\&\#165\;/¥/igs;$text=~s/\&brvbar\;|\&\#166\;/¦/igs;$text=~s/\&ordf\;|\&\#170\;/ª/igs;$text=~s/\&macr\;|\&\#175\;/¯/igs;$text=~s/\&deg\;|\&\#176\;/°/igs;$text=~s/\&plusmn\;|\&\#177\;/±/igs;$text=~s/\&Ugrave\;|\&\#217\;|\&\#249\;/ù/igs;$text=~s/\&Uacute\;|\&\#218\;|\&\#250\;/ú/igs;$text=~s/\&Ucirc\;|\&\#219\;|\&\#251\;/û/igs;$text=~s/\&Uuml\;|\&\#220\;|\&\#252\;/ü/igs;$text=~s/\&Yacute\;|\&\#253\;/Ý/igs;$text=~s/\&lsquo\;|\&\#8216\;/‘/igs;$text=~s/\&rsquo\;|\&\#8217\;/’/igs;$text=~s/\&sbquo\;|\&\#8218\;/‚/igs;$text=~s/\&ldquo\;|\&\#8220\;/“/igs;$text=~s/\&rdquo\;|\&\#8221\;/”/igs;$text=~s/\&bdquo\;|\&\#8222\;/„/igs;$text=~s/\&bull\;|\&\#8226\;/·/igs;$text=~s/\&sdot\;|\&\#8901\;/·/igs;$text=~s/\&ccedil\;|\&\#199\;/ç/igs;$text=~s/\&sup1\;|\&\#185\;/¹/igs;$text=~s/\&sup2\;|\&\#178\;/²/igs;$text=~s/\&sup3\;|\&\#179\;/³/igs;$text=~s/\&szlig\;|\&\#223\;/ß/igs;$text=~s/\&THORN\;|\&\#222\;/Þ/igs;$text=~s/\&yuml\;|\&\#255\;/ÿ/igs;$text=~s/\&ordm\;|\&\#186\;/º/igs;$text=~s/\&raquo\;|\&\#187\;/»/igs;$text=~s/\&frac14\;|\&\#188\;/¼/igs;$text=~s/\&frac12\;|\&\#189\;/½/igs;$text=~s/\&frac34\;|\&\#190\;/¾/igs;$text=~s/\&\#39\;/'/igs;
	return $text;
}