#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Selfridges_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Selfridges_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger;
	
	####Variable Initialization##############
	$robotname='Selfridges-UK--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Sel';
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
		my @query_string;
		$product_object_key =~ s/^\s+|\s+$//g;		
		$url3='http://www.selfridges.com'.$url3 unless($url3=~m/^\s*http\:/is);		
		my $Final_cont = get_content($url3);

		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		####Out of stock products - detail_collected='x'
		if($Final_cont=~m/Sorry\,\s*this\s*product\s*is\s*currently\s*out\s*of\s*stock/is)
		{
			goto PNF;
		}		
		
		my ($product_id,$brand,$product_name,$description,$prod_detail,$price_text,$price);
		
		###Product_ID
		if($Final_cont=~m/name\=\"productId\"\s*value\=\"([^\"]*)\"/is)
		{
			$product_id=$1;
			
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		
		#Brand_name
		if ( $Final_cont =~ m/<h1>\s*<span\s*class\=\"brand\">\s*([\w\W]*)\s*<\/\s*span>\s*<span\s*class\=\"descriptionName\">/is)
		{
			$brand = &DBIL::Trim($1);
		}
		elsif( $Final_cont =~ m/<div\s*class\=\"bundleDetails\">\s*<h2\s*class\=\"brand\">\s*([^<]*?)\s*<\/h2>/is)
		{
			$brand = &DBIL::Trim($1);
		}
		#Product_name
		if ( $Final_cont =~ m/<span\s*class\=\"descriptionName\">\s*([\w\W]*)\s*<\/\s*span>\s*<\/\s*h1>/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		elsif ( $Final_cont =~ m/<li\s*class\=\"last\">\s*([^<]*?)\s*<\/li>/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		$product_name=~s/\’/\'/igs;
		$product_name=~s/\“/\"/igs;
		$product_name=decode_entities($product_name);
		
		if($brand ne '')
		{
			&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		}
		if($Final_cont=~m/<div\s*class\=\"prices\">\s*([\w\W]*?)\s*<\/div>/is)
		{
			my $price_block=$1;
			
			if($price_block=~m/<li\s*class\=\"price\">\s*([\w\W]*?)\s*<\/li>/is)
			{
				$price=$1;
				$price=~s/\&pound\;//igs;
				$price=~s/\,//igs;
				$price=&DBIL::Trim($price);
			}
			
			$price_text=&DBIL::Trim($price_block);
			decode_entities($price_text);
			$price_text=~s/Â/ /igs;
			$price=~s/\,//igs;
			$price=~s/\s*[a-zA-Z]+\s*|\$|\£//igs;
		}
		if($Final_cont=~m/<h3>Selfridges\s*Says<\/h3>[\w\W]*?<\/div>\s*<div\s*[^>]*?>\s*([\w\W]*?)\s*<\/\s*div>\s*<\/\s*div>/is)
		{
			$description = &DBIL::Trim($1);
		}
		elsif($Final_cont=~m/<div\s*class\=\"bundleDetails\">\s*<h2\s*class\=\"brand\">[^<]*?<\/h2>\s*<h1>[^<]*?<\/h1>\s*<p>\s*([\w\W]*?)\s*<\/p>\s*<\/div>/is)
		{
			$description = &DBIL::Trim($1);
		}
		$description=~s/\’/\'/igs;
		$description=~s/\“/\"/igs;
		$description=decode_entities($description);
		if($Final_cont=~m/<h3>\s*Details\s*(?:\&\s*MEASUREMENTS)?\s*[^>]*?<\/h3>[\w\W]*?<\/div>\s*<div\s*[^>]*?>\s*([\w\W]*?)\s*<\/\s*div>\s*<\/\s*div>\s*(?:<\/\s*DIV>)?/is)
		{
			$prod_detail = &DBIL::Trim($1);
		}
		$prod_detail=~s/\’/\'/igs;
		$prod_detail=~s/\“/\"/igs;
		$prod_detail=decode_entities($prod_detail);
		
		my($storeId,$langId,$catalogId);		
		if($Final_cont=~m/name\=\"storeId\"\s*value\=\"([^\"]*)\"/is)
		{
			$storeId=$1;
		}
		if($Final_cont=~m/name\=\"langId\"\s*value\=\"([^\"]*)\"/is)
		{
			$langId=$1;
		}
		if($Final_cont=~m/name\=\"catalogId\"\s*value\=\"([^\"]*)\"/is)
		{
			$catalogId=$1;
		}
		my $size_url;
		if($Final_cont=~m/<script\s*type\=\"text\/javascript\"\s*src\=\"([^\"]*?catalogId\=[\d]+)\"><\/script>/is)
		{
			$size_url=$1;
			decode_entities($size_url);
		}
		#color code
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		if($Final_cont=~m/<fieldset>([\w\W]*?)<\/fieldset>/is)
		{
			my $color_block=$1;
			my $count_1=1;
			while($color_block=~m/<label[^>]*?>\s*<img\s*class\=\"([^\"]*)\"[\w\W]*?src\=\"([^\"]*)\"\s*alt\=\"([^\"]*)\"[^>]*?>\s*<\/\s*label>/igs)
			{
				$color_hash{$count_1}=[$1,$2,$3];
				$count_1++;
			}
			my $size_cont=&get_content($size_url);
			
			#size
			my $i=0;		
			my ($productId,$categoryId,$catalogId,$storeId);
			if($Final_cont=~m/<[^<]*?OrderItemAddForm[^<]*?>([\w\W]*?)<\/div>/is)
			{
				my $order_block=$1;
				
				$productId=$1 if($order_block=~m/productId\"\s*value\=\"([^<]*?)\"/is);
				$categoryId=$1 if($order_block=~m/categoryId\"\s*value\=\"([^<]*?)\"/is);
				$catalogId=$1 if($order_block=~m/catalogId\"\s*value\=\"([^<]*?)\"/is);
				$storeId=$1 if($order_block=~m/storeId\"\s*value\=\"([^<]*?)\"/is);
			}
			
			foreach my $id(sort{$a<=>$b} keys %color_hash)
			{
				my $id_color=$color_hash{$id}[0];
				$id_color=~s/\-/\\\-/igs;
				
				my $s_reg='\{\"attributeName\"\:"Size"\,\"attributeValues\"\:\s*\[([^\]]*?)\]\,\"itemSKU\"\:\"[^\"]*\"\,\"staticImage\"\:\"[^\"]*?\"\,\"offerDiscount\"\:\"[^\"]*\"\,\"prices\"\:\[\]\,\"priceHistory\"\:\[\]\,\"imageReference\"\:\"'.$id_color.'\"';
				
				if($size_cont=~m/$s_reg/is)
				{
					my $size_data=$1;
					
					while($size_data=~m/\"([^\"]*)\"/igs)
					{
						my $size = &DBIL::Trim($1);						
						
						my $price_url="http://www.selfridges.com/webapp/wcs/stores/servlet/BasketAdd?productId=".$productId."&storeId=".$storeId."&langId=-1&orderId=.&catalogId=".$catalogId."&catEntryId=&childItemId=&calculationUsageId=-1&shouldCachePage=false&check=**&defaultViewName=OrderItemDisplay&errorViewName=GenericAjaxErrorJSONView&categoryId=".$categoryId."&Colour=".$color_hash{$id}[2]."&quantity=1&Size=".$size."&URL=MiniShoppingBagView&addToBagButton.x=1";
						
						my $price_cont = &LWP_cont($cookie_file, $price_url);
												
						my $bag_price=$1 if($price_cont=~m/price\\\">[^<]*?\&pound\;([^<]*?)\\n/is);
						
						$bag_price=~s/\,//igs;
						if($price ne $bag_price and $bag_price ne '')
						{
							$price=$bag_price;
						}
						
						my $out_of_stock = 'n';
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_hash{$id}[2],$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color_hash{$id}[0];
						push(@query_string,$query);	
					}
				}
				else
				{
					my $out_of_stock = 'n';
					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"",$color_hash{$id}[2],$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color_hash{$id}[0];
					push(@query_string,$query);
				}
				
				# DBIL::SaveTag('Color',$color_hash{$id}[2],$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				
				my $swatch=$color_hash{$id}[1];				
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
				$image_objectkey{$img_object}=$color_hash{$id}[0];
				$hash_default_image{$img_object}='n';
				
			}
			#image 
			foreach my $id(sort{$a<=>$b} keys %color_hash)
			{
				
				my $imge_url='http://images.selfridges.com/is/image/selfridges?req=set,json&imageset={'.$color_hash{$id}[0].'_IMGSET,'.$color_hash{$id}[0].'_VID01,'.$color_hash{$id}[0].'_360}&defaultImage=';
				
				my $img_cont=&get_content($imge_url);
				
				my @imge_url;
				if($img_cont=~m/\[([\w\W]*?)\]/is)
				{
					my $sub_img_block=$1;
					while($sub_img_block=~m/\"i\"\:\{(?:\"mod\"\:\"crop[\w\W]*?)?\"n\"\:\"([^\"]*)\"\}/igs)
					{
						my $img_url='http://images.selfridges.com/is/image/'.$1;
						push(@imge_url,$img_url);
					}
				}
				
				my $countt=0;
				my $jv_imgae=0;
				
				foreach my $f_img_url(@imge_url)
				{
					$jv_imgae=1;
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($f_img_url,'product',$retailer_name);				
					
					if($f_img_url=~m/_M\s*$/is)
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$f_img_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_hash{$id}[0];
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
						$countt++;				
					}
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$f_img_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_hash{$id}[0];
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);	
					}
				}
				#default IMAGE url
				if($countt==0 && $jv_imgae==1)
				{
					my $f_img_urls;
			
					if($Final_cont=~m/<img\s*id\=\"largeImage\"\s*class\=\"[^\"]*\"\s*rel\=\"[^\"]*\"\s*src\=\"([^\"]*)\"\s*/is)
					{
						$f_img_urls=$1;
					}
					elsif($Final_cont=~m/<img\s*itemprop\=\"image\"[^<]*?src\=\"([^<]*?)\"/is)
					{
						$f_img_urls=$1;
					}
					
					$f_img_urls=~s/\?\$[\w\W]*//igs;					
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($f_img_urls,'product',$retailer_name);
					
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$f_img_urls,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color_hash{$id}[0];
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
			}
		}
		else
		{
			#no swatch or color	

			my $color_ids;
			
			if($Final_cont=~m/<img\s*id\=\"largeImage\"\s*class\=\"([^\"]*)\"\s*/is)
			{
				$color_ids=$1;
			}
			elsif($Final_cont=~m/<img\s*itemprop\=\"image\"[^<]*?class\=\"([^<]*?)\"/is)
			{
				$color_ids=$1;
			}
			$color_ids=~s/_M$//is;
			
			if($Final_cont=~m/<option\s*[^>]*?>\s*SELECT\s*SIZE\s*<\/option>([\w\W]*?)<\/select>/is)
			{
				my $size_block=$1;
				
				while($size_block=~m/<option\s*[^>]*?>\s*([\w\W]*?)\s*<\/\s*option>/igs)
				{
					my $size = &DBIL::Trim($1);
					
					my $out_of_stock = 'n';		
					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,"",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color_ids;
					push(@query_string,$query);
				}
			}
			elsif($Final_cont=~m/<p\s*class\=\"stockAvailability\">\s*<span>Sorry\s*\,\s*this\s*product\s*is\s*currently\s*out\s*of \s*stock\s*\.\s*<\/span>/is)
			{
				my $out_of_stock = 'y';
				
				$price='null' if($price eq '');
				
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"","",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color_ids;
				push(@query_string,$query);
			}
			else
			{
				my $out_of_stock = 'n';			
				
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"","",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color_ids;	
				push(@query_string,$query);
			}			
			
			my $imge_url='http://images.selfridges.com/is/image/selfridges?req=set,json&imageset={'.$color_ids.'_IMGSET,'.$color_ids.'_VID01,'.$color_ids.'_360}&defaultImage=';
						
			my $img_cont=&get_content($imge_url);
			
			my @imge_url;
			if($img_cont=~m/\[([\w\W]*?)\]/is)
			{
				my $sub_img_block=$1;
				while($sub_img_block=~m/\"i\"\:\{(?:\"mod\"\:\"crop[\w\W]*?)?\"n\"\:\"([^\"]*)\"\}/igs)
				{
					my $img_url='http://images.selfridges.com/is/image/'.$1;
					push(@imge_url,$img_url);
				}
			}
			#check multiple image
			my $countt=0;
			my $jv_imgae=0;	
			
			foreach my $f_img_url(@imge_url)
			{	
				$jv_imgae=1;				
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($f_img_url,'product',$retailer_name);
				if($f_img_url=~m/_M\s*$/is)
				{
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$f_img_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color_ids;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
					$countt++;				
				}
				else
				{
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$f_img_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color_ids;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
			}
			#default url,Single image
			if($countt==0 && $jv_imgae==1)
			{
				my $f_img_urls;
		
				if($Final_cont=~m/<img\s*id\=\"largeImage\"\s*class\=\"[^\"]*\"\s*rel\=\"[^\"]*\"\s*src\=\"([^\"]*)\"\s*/is)
				{
					$f_img_urls=$1;
				}
				elsif($Final_cont=~m/<img\s*itemprop\=\"image\"[^<]*?src\=\"([^<]*?)\"/is)
				{
					$f_img_urls=$1;
				}
							
				$f_img_urls=~s/\?\$[\w\W]*//igs;
				#To check the image is valid or not
				
				my $result=&image_validate($f_img_urls);
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($f_img_urls,'product',$retailer_name);				
					
				if($result==1)
				{
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$f_img_urls,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color_ids;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);	
				}
			}
		}
		###Product - Out of Stock###########			
		if($Final_cont=~m/currently\s*out\s*of\s*stock/is)
		{
			my $out_of_stock='y';
			
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,"null","","","",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			push(@query_string,$query);
		}
		if ( $Final_cont =~ m/<span\s*class\=\"descriptionName\">\s*([\w\W]*)\s*<\/\s*span>\s*<\/\s*h1>/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		elsif ( $Final_cont =~ m/<li\s*class\=\"last\">\s*([^<]*?)\s*<\/li>/is)
		{
			$product_name = &DBIL::Trim($1);
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
		
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);
		LAST:
		print " ";
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
	$req->header("Content-Type"=> "text/plain");
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
sub LWP_cont()
{
	my $cookies = shift;
	my $url=shift;
	unlink ($cookies);
	my $cookie = HTTP::Cookies->new(file=>$cookies,autosave=>1);
	$ua->cookie_jar($cookie);
	my $req = HTTP::Request->new(GET=>$url);
	$req->header("Content-Type"=> "application/x-www-form-urlencoded");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	print "CODE :: $code\n";
	my ($content,$con);
	if($code =~ m/200/is)
	{
		$content = $res->content();
	}
}

sub image_validate()
{
    my $url = shift;
	
	$url =~ s/^\s+|\s+$//g;
	
	my $req = HTTP::Request->new(GET=>$url);
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	
    if($code==200)
    {
		return 1;
    }
    else
    {
		return 0;
    }
}

