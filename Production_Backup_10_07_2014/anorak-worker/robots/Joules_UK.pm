#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Joules_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Joules_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Joules-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Jou';
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
	my $mflag=0;
	if($product_object_key)
	{
		
		# my $url = $hashUrl{$product_object_key};
		my $url3=$url;
		print"$url\n";
		my $content2 = get_content($url3);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my %sku_objectkey;
		my %image_objectkey;
		my %hash_default_image;
		my %hash_default_image;
		my @query_string;
		my ($price,$brand,$sub_category,$product_name,$productname,$product_id,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$select_var,$i,$size,$price_text,$color,$sku,$j,$pricetext,$unit);
		##
		my $productid4ref,$pid;
		if($content2=~m/<P\s*itemprop\=\"name\">Product\s*Code\:\s*([^>]*?)</is)
		{
			$productid4ref=$1;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($productid4ref, $product_object_key, $dbh,$robotname);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		##productname for product table 
		if ($content2=~m/<h1\s*itemprop\=\"name\">\s*([^>]*?)\s*</is)
		{
			$productname=$1;
			$productname=&DBIL::Trim($productname);
		}
		elsif($content2=~m/<h1\s*itemprop\=\"name\">\s*([^>]*?)\s*</is)
		{
			$productname=$1;
			$productname=&DBIL::Trim($productname);
		}
		my $item=0;
		my $content22=$content2;
		my %AllColor;
		my $inc=2;
		while($content2=~m/<a\s*href\=[^>]*?class[^>]*?name\=\"([^>]*?\|([^>]*?)\s*)\">/igs)#entry for mulitple swatch colour 
		{
			my $alt=$1;
			my $color1=$2;
			my $color;
			my $alt_url="http://www.joules.com$alt";
			my $content3 = get_content($alt_url);
			if($content3=~m/<h1\s*itemprop\=\"name\">\s*[^>]*?\,([^>]*?)\s*</is)#colour form product name 
			{
				$color=$1;
			}
			# if($content3=~m/<img\s*src\=\"([^>]*?)\"\s*title\=\"\s*$color[^>]*?\"/is)#swacth image 
			if($content3=~m/<img\s*src\=\"([^>]*?)\"\s*title\=\"\s*[^>]*?\s*[^>]*?\"\s*\/>\s*<\/a>\s*<\/li>\s*<\/ul>\s*<form>/is)#swacth image 
			{
				
				my $swac_img=$1;
				#same colour repeating 
				if($AllColor{$color} eq '')
				{
				 $AllColor{$color}=$color;
				}
				else
				{
				 $color=$color.' ('.$inc.')';
				 $inc++;
				}
				$item++;
				my ($imgid,$img_file) = &DBIL::ImageDownload($swac_img,'swatch',$retailer_name);
				my ($img_object,$flag) = &DBIL::SaveImage($imgid,$swac_img,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				if($content3=~m/span\s*class\=\"price([\w\W]*?)<\/p>/is)#price text
				{
					$price_text=$1;
					$price_text=~s/itemprop\=\"price\">//igs;
					$price_text=~s/\s*//igs;
					$price_text=~s/<\/span>//igs;
					$price_text=~s/<span\s*class\=\"price\-was\"\s*itemprop\=\"highPrice\">/ /igs;
					$price_text=~s/\-from\"itemprop\=\"lowPrice\">//igs;
					$price_text=~s/\Â//igs;
					$price_text=~s/\"//igs;
				}
				if($content3=~m/<h1\s*itemprop\=\"name\">\s*([^>]*?)\s*</is)#product name sku table 
				{
					$product_name=$1;
				}	
				if($content3=~m/<select\s*id\=\"Size\">([\w\W]*?)<\/select>/is)#selecting mulitple size group 
				{	
					my $block=$1;
					while($block=~m/<option\s*value\=[^>]*?>\s*([\w\W]*?)\s*<\/option>/igs)#size and price (varies for each size)
					{
						
						my $size_price=$1; # out of stock,price and size  group
						$size_price=~s/\&nbsp\;//igs;
						print"SIZE_PRICE===>>>$size_price\n";
						if($size_price=~m/([\w\W]*)\s*\-\s*([^>]*?)\s*(Sold\s*out\s*online)/is)#out of stock,price and size
						{
							$size=$1;
							$price=$2;
							my $stock=$3;
							$price=~s/\£//igs;
							$price=~s/\s*//igs;
							$price=~s/\Â//igs;
							$price=~s/\Â//igs;
							$price=~s/.00//igs;
							$price=~s/Low\s*stock[^>]*?$//igs;
							if($stock=~m/Sold\s*out\s*online/is)#out of stock
							{
								$out_of_stock='y';
							
							}
							else
							{
								$out_of_stock='n';
							
							}
						}
						elsif($size_price=~m/([\w\W]*)\-([^>]*)\s*\([^>]*?pre\-order[^>]*\)/is)#size and price 
						{
							$size=$1;
							$price=$2;
							$price=~s/\£//igs;
							$price=~s/\s*//igs;
							$price=~s/\Â//igs;
							$price=~s/.00//igs;
							$price=~s/Low\s*stock[^>]*?$//igs;
							$price=~s/Low\s*stock//igs;
							$out_of_stock='y';
						
						}
						elsif($size_price=~m/([\w\W]*)\-\s*([^>]*?)$/is)#size and price 
						{
							$size=$1;
							$price=$2;
							$price=~s/\£//igs;
							$price=~s/\s*//igs;
							$price=~s/\Â//igs;
						#	$price=~s/.00//igs;
							$price=~s/Low\s*stock[^>]*?$//igs;
							$price=~s/Low\s*stock//igs;
							$out_of_stock='n';
						
						}
						elsif($size_price=~m/([^>]*?)\s*\-\s*([^>]*?)$/is)#size and price 
						{

							$size=$1;
							$price=$2;
							$price=~s/\£//igs;
							$price=~s/\s*//igs;
							$price=~s/\Â//igs;
							$price=~s/.00//igs;
							$price=~s/Low\s*stock[^>]*?$//igs;
							$price=~s/Low\s*stock//igs;
							$out_of_stock='n';
					
						}	
					print"price==>>$price\n";	
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;	
						push(@query_string,$query);
					}
					my $count=1;
					while($content3=~m/superZoomImageSrc\=\"([^>]*?)\"/igs)#product Image
					{
						my $product_image1="http:$1";
						
						# print"$product_image1\n\n";
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
			}
		
		}	
		my($des3,$Details);
		if($content2=~m/itemprop\=\"description\">\s*(?:<p>)?\s*([\w\W]*?)\s*<\/p>/is)#
		{
			$des3=$1;
			$des3=~s/\s+/ /igs;
			$des3=~s/<[^>]*?>/ /igs;
			$des3=~s/\&rsquo\;//igs;
			$des3=&DBIL::Trim($des3);
		}
		if($content2=~m/<ul\s*class\=\"prod_bull\">\s*([\w\W]*?)\s*<\/ul>/is)#Detail
		{
			$Details=$1;
		}
		if(($product_name ne '' or $product_id ne '' ) && ($des3 eq '' and $Details eq ''))#if product name , deatil and description are empty inside 'Space' in  description else flag will set 'X'
		{
		   $des3=' ';
		}
			
		$Details=~s/\s+/ /igs;
		$Details=~s/<li>/\*/igs;
		$Details=~s/\&rsquo\;//igs;
		$Details=~s/<[^>]*?>//igs;
		$Details=&DBIL::Trim($Details);
		# print"des====>>$des3\n\n";
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$productid4ref,$productname,$brand,$des3,$Details,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		$dbh->commit;
	}
}1;
sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	Home:
	
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
	$req->header("Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
		$req->header("Content-Type"=>"text/html;charset=UTF-8");
		$req->header("Referer"=> "http://www.neimanmarcus.com/en-us/index.jsp");
		$req->header("Host"=> "www.neimanmarcus.com");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	print "\nCODE :: $code";
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
