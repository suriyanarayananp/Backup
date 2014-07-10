#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Urbanoutfitters_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBIL_Updated/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Urbanoutfitters_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my @query_string;
	####Variable Initialization##############
	$robotname='Urbanoutfitters-US--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Urb';
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
		$url3='http://www.urbanoutfitters.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = get_content($url3);
		
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		
		####Out of stock products - detail_collected='x'		
		if($content2=~m/<div\s*class\=\"soldout\">\s*Sold\s*Out\s*<\/div>/is)
		{
			goto PNF;
		}
		
		#price_text	
		if($content2=~m/<span\s*[^>]*?price[^>]*?>\s*([\w\W]*?)\s*<meta/is)
		{
			$price_text = &DBIL::Trim($1);
			$price_text=~s/&bull\;//igs;
		}
		#price
		if($content2=~m/<span\s*class\=\"promo\-price\">\s*\$([\d\.]+)\s*<\/span>/is)
		{
			$price = &DBIL::Trim($1);
		}
		elsif($content2=~m/product_selling_price\s*\:\s*\[\"([\w\W]*?)\"\]?/is)
		{
			$price = &DBIL::Trim($1);
			if ( $price =~ m/\-/is )
			{
				$price = (split('\-',$price))[0];
			}
		}
		#product_id
		if($content2=~m/product_id\s*\:\s*\[\"([\w\W]*?)\"\]?/is)
		{
			$product_id = &DBIL::Trim($1);
			
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if($content2=~m/product_name\s*\:\s*\[\"([\w\W]*?)\"\]?/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		#Brand
		if($content2=~m/product_brand\s*\:\s*\[\"([\w\W]*?)\"\]?/is)
		{
			$brand = &DBIL::Trim($1);			
		}
		#description&details
		if($content2=~m/<div\s*id\=\"detailsDescription\"[^>]*?>\s*([\w\W]*?)\s*<\/div>/is)
		{
			my $desc_content = $1;
			if($desc_content =~ m/([\w\W]*?)\s*CONTENT\s*([\w\W]+)/is)
			{
				$description = &DBIL::Trim($1);
				$prod_detail = &DBIL::Trim($2);
				$prod_detail = "CONTENT ".$prod_detail;
			}
			else
			{
				$description = &DBIL::Trim($desc_content);
				# $prod_detail = DBIL::Trim($desc_content);
			}
			$description=decode_entities($description);
			$prod_detail=decode_entities($prod_detail);
		}
		
		#If product is available without description and product detail
		if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
			$prod_detail='-';
		}
		
		#colour
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		if($content2=~m/<div\s*class\=\"color[^>]*?>\s*([\w\W]*?)\s*<\/div>/is)
		{
			my $colour_content = $1;
			while($colour_content=~m/<img\s*id\=\"(\d+)\"\s*src\=\s*\"\s*([^<]*?)\s*\"\s*alt\=\s*\"\s*([^<]*?)\s*\"\s*[^>]*?>/igs)
			{
				my $color_code 	= &DBIL::Trim($1);
				my $color 		= &DBIL::Trim($3);
				$color_hash{$color_code} = &DBIL::Trim($color);
			}
		}
		# size & out_of_stock
		if ( $content2 =~ m/<div\s*class\=\"size[^>]*?>\s*([\w\W]*?)\s*<\/div>/is )
		{
			my $size_content = $1;
			my @color_code = keys %color_hash;
			foreach my $code (@color_code)
			{
				while ( $size_content =~ m/<span\s*class\=\"sizes\"\s*id\=\"$code\"[^>]*?>\s*([\w\W]*?)\s*<\/span>/igs)
				{
					my $size_content1 = $1;
					while ( $size_content1 =~ m/<a[^<]*?data-msg\=\"([^<]*?)\s*\"\s*[^>]*?>\s*([^>]*?)\s*<\/a>/igs )
					{
						my $stock_text = &DBIL::Trim($1);
						my $size = &DBIL::Trim($2);
						my $out_of_stock;
						if ( $stock_text =~ m/^\s*Sold\s*Out\s*$/is )
						{
							$out_of_stock = 'y';
						}
						else
						{
							$out_of_stock = 'n';
						}

						my $color_lc=lc($color_hash{$code});
						$color_lc=~s/\s/_/igs;
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_lc,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$code;
							push(@query_string,$query);
					}
				}
				
				# DBIL::SaveTag('Color',$color_hash{$code},$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				
			}
		}
		#swatchimage
		if ( $content2 =~ m/<div\s*class\=\"color[^>]*?>\s*([\w\W]*?)\s*<\/div>/is )
		{
			my $swatch_content = $1;
			while ( $swatch_content =~ m/<img\s*id\=\"(\d+)\"\s*src\=\s*\"\s*([^<]*?)\s*\"\s*alt\=\s*\"\s*([^<]*?)\s*\"\s*[^>]*?>/igs )
			{
				my $swatch_code	 = &DBIL::Trim($1);
				my $swatch 		 = &DBIL::Trim($2);
				my $swatch_color = &DBIL::Trim($3);
				
				unless($swatch=~m/^\s*http\:/is)
				{
					$swatch='http://www.urbanoutfitters.com'.$swatch;
				}			
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
				$image_objectkey{$img_object}=$swatch_code;
				$hash_default_image{$img_object}='n';
					push(@query_string,$query);
			}
		}
		#Image
		if($content2=~m/<ul\s*id\=\"thumbnails[^>]*?>\s*([\w\W]*?)\s*<\/ul>/is)
		{
			my $alt_image_content = $1;
			my @color_code = keys %color_hash;
			foreach my $code (@color_code)
			{
				my $count;
				while ( $alt_image_content =~ m/<img[^<]*?src\=\"([^<]*?)\$/igs )
				{
					my $alt_image = &DBIL::Trim($1);
				
					$count++;
					$alt_image =~ s/\$//g;
					$alt_image =~ s/([^>]*?)\_(\d{3})\_([^>]*?)/$1\_$code\_$3/ig;
					
					$alt_image="http:".$alt_image unless($alt_image=~m/^\s*http\:/is);
					
					$alt_image .= '$zoom$';
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);					

					if ( $count == 1 )
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$code;
						$hash_default_image{$img_object}='y';
							push(@query_string,$query);
					}
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$code;
						$hash_default_image{$img_object}='n';
							push(@query_string,$query);
					}
				}
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
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		end:
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
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