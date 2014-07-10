#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Anthropologie_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
#require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Anthropologie_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my @query_string;
	####Variable Initialization##############
	$robotname='Anthropologie-US--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Ant';
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

	my $skuflag = 0;my $imageflag = 0;
	if($product_object_key)
	{		
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://us.anthropologie.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &get_content($url3);
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$size,$type,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);
		
		#product_id
		if($content2=~m/productId"\s*content\=\"([^<]*?)\"/is)
		{
			$product_id = &DBIL::Trim($1);			
			
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		
		###API Content#######
		my $api_url="http://us.anthropologie.com/api/v1/product/$product_id";
		my $api_content = &get_content($api_url);
		
		###Multi Product######
		my $mflag;
		my $count=0;
		while($api_content=~m/brand\"\:\"\"\,\"description\"\:\"/igs)
		{			
			$count++;
		}
		if($count > 1)
		{
			$mflag=1;
		}		
		
		#product_name
		if($content2=~m/<h1\s*itemprop\=\"name\">([\w\W]*?)<\/h1>/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		
		#price
		if($api_content=~m/salePrice\"\:([^<]*?)\,\"(?:[\w\W]*?salePrice\"\:([^<]*?)\,\")?/is)
		{
			$price      = &DBIL::Trim($1);
			my $price_2 = &DBIL::Trim($2);
			
			if($price_2 > $price)
			{
				$price_text='$'.$price.' - $'.$price_2;
			}
			elsif($api_content=~m/listPrice\"\:([^<]*?)\,\"/is)
			{
				my $listprice = &DBIL::Trim($1);
				
				if($listprice > $price)
				{
					$price_text = '$'.$price.' (was $'.$listprice.')';
				}
				else
				{
					$price_text='$'.$price;
				}
			}
			$price_text=decode_entities($price_text);
		}
		##If price not available
		$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
				
		#Description & Product_Detail
		if($content2=~m/<span\s*itemprop\=\"description\">\s*<ul>([\w\W]*?<span>(?:\s*style\s*\#[\w\W]*?)?)<\/span>\s*([\w\W]*?)<\/span>/is)
		{
			$prod_detail = &DBIL::Trim($1);
			$description = &DBIL::Trim($2);
			
			$prod_detail=decode_entities($prod_detail);
			$description=decode_entities($description);
		}
		
		#If product is available without description and product detail
		if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
			$prod_detail='-';
		}
		
		#Brand
		if($content2=~m/<[^>]*?itemprop\s*\=\s*\"brand\s*\"\s*content\s*\=\s*\"([^>]*?)\"/is)
		{
			$brand = &DBIL::Trim($1);
			if ( $brand !~ /^\s*$/g )
			{
				&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			}
		}
	
		#colour
		my (@color_id,@color);		
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		while($api_content=~m/\"colorCode\"\:\"([^<]*?)\"\,\"displayName\"\:\"([^<]*?)\"/igs)
		{
			my $code  = &DBIL::Trim($1);			
			my $color = &DBIL::Trim($2);
			
			push(@color_id,$code);
			push(@color,$color);
		}
		
		####Size Type
		my $type_count=0;
		my (@type_arr,@size_array);
		if($api_content=~m/sizeCategories\"\:\[([^<]*?)\]/is)
		{
			my $type_content=$1;
			
			while($type_content=~m/\"([^<]*?)\"/igs)
			{
				my $type=$1;
				
				push(@type_arr,$type);
				$type_count++;
			}
		}		
		
		###SKU Collection
		my $colour_count=2;
		my (@dup_color,@all_color,@all_code);
		while($api_content=~m/productIds\"\:\[\"([^<]*?)\"[^<]*?stockLevel\"\:([^<]*?)\,\"[^<]*?\"size\"\:\"([^<]*?)\"\,\"colorId\"\:\"([^<]*?)\"\,\"color\"\:\"([^<]*?)\"\,\"type\"\:\"([^<]*?)\"\,\"[^<]*?salePrice\"\:([^<]*?)\,\"/igs)
		{
			my $prod_id   = &DBIL::Trim($1);
			my $stock     = &DBIL::Trim($2);
			my $size      = &DBIL::Trim($3);
			my $color_id  = &DBIL::Trim($4);
			my $color     = &DBIL::Trim($5);
			my $type_code = &DBIL::Trim($6);
			my $price1    = &DBIL::Trim($7);
			
			###Remove Irrelavent SKU by matching product_id
			if($prod_id ne $product_id)
			{
				next;
			}
			
			####Skip irrelavent colours for the product######
			unless(grep( /^$color$/, @color ))
			{
				next;
			}
			
			####Duplicate Colour######
			my $color1=lc($color);
			unless(grep(/^$color1$/,@dup_color))
			{
				$colour_count=2;
			}
			unless(grep( /^$color_id$/, @all_code ))
			{
				if(grep( /^$color1$/, @all_color ))
				{
					push(@dup_color,lc($color));
					$color = $color." ($colour_count)";
					$colour_count++;
				}
			}
			
			push(@all_color,lc($color));
			push(@all_code,$color_id);
			
			###out_of_stock
			my $out_of_stock;
			if($stock == 0)
			{
				$out_of_stock='y';
			}
			else
			{
				$out_of_stock='n';
			}
			
			###Adding Size Type(Regular,Petite,Tall) with Size
			if($type_count > 1)
			{
				if($type_code == 1)
				{
					$type='Regular';
				}
				elsif($type_code == 0)
				{
					$type='Petite';
				}
				elsif($type_code == 2)
				{
					$type='Tall';
				}
				
				$size=$type." ".$size;
			}
			
			##If SKU Price available
			if($price1 ne '')
			{
				$price=$price1;
			}
			
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$color_id;
			push(@query_string,$query);
		}
		
		# Default & Alternate Images
		foreach my $id (@color_id)
		{
			while($api_content=~m/$id\"\,\"displayName\"\:\"[^<]*?\"\,\"viewCode\"\:\[([^<]*?)\]/igs)
			{
				my $image_array=$1;
				$image_array=~s/\"//igs;	

				my @image_array = split(/\,/,$image_array);				
				
				foreach my $img (@image_array)
				{
					my $imageurl = "http://images.anthropologie.com/is/image/Anthropologie/".$product_id."_".$id."_".$img."?\$redesign-zoom-5x\$";			
					
					my $image_status;
					if($imageurl=~m/_b\?/is)
					{
						$image_status='y';						
					}
					else
					{
						$image_status='n';						
					}
					unless($imageurl=~m/^\s*http/is)
					{
						$imageurl='http://'.$imageurl;
					}
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
			
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$id;
					$hash_default_image{$img_object}=$image_status;
					push(@query_string,$query);
				}
			}
		}
		
		###If Multi item - product_name & Price
		if($mflag == 1)
		{
			#Alternate URL
			my $alternate=$1 if($content2=~m/<link\s*rel\=\"alternate\"\s*href\=\"([^<]*?)\"/is);
			my $alternate_content = &get_content($alternate);
		
			if($alternate_content=~m/<h1[^<]*?>([\w\W]*?)<\/h1>\s*(?:<[^>]*?>\s*)*?\s*<[^<]*?productdetail-price\">\s*(?:<[^<]*?price-label\">[^<]*?<\/span>)?\s*([\w\W]*?)(?:<\/span>\s*<\/span>|<\/p>)/is)
			{
				$product_name = &DBIL::Trim($1);
				$price_text   = &DBIL::Trim($2);
				
				$price=$price_text;
			
				$price=~s/\,\$[^>]*?$//igs;
				$price=~s/\$//igs;
				$price=~s/\&\#150;[^>]*$//igs;
				$price=~s/-[^>]*$//igs;			
				$price=~s/<span[\w\W]*?$//igs;			
				$price=~s/[^\d\.\,]+//igs;
				$price=~s/\,//igs;
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
		push(@query_string,$query1);
		push(@query_string,$query2);
		##my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		##push(@query_string,$qry);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		print" ";
		$dbh->commit();	
	}
}1;

sub get_content()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>$url);
	$req->header("Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"); 
    $req->header("Content-Type"=>"application/x-www-form-urlencoded");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	print "\nCODE :: $code";
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
			goto Home;
		}
	}
	return $content;
}

