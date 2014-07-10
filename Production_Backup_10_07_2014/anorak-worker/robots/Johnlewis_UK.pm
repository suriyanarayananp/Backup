#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Johnlewis_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
#require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Johnlewis_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Johnlewis-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Joh';
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
	my @query_string;
	my $skuflag = 0;my $imageflag = 0;
	if($product_object_key)
	{
		my $url3=$url;
		$url3=decode_entities($url3);

		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.johnlewis.com'.$url3 unless($url3=~m/^\s*http\:/is);
		
		my $content2 = get_content($url3);

		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$size,$colour);
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		#price_text
		if ( $content2 =~ m/<div[^<]*?\"prod-price\"[^<]*?>([\w\W]*?)<\/div>/is )
		{
			$price_text=trim($1);
		}
		#price
		if ( $content2 =~ m/id\=\"prod\-price\"[\w\W]*?<strong>[\w\W]*?([\d\.\,]+)\s*<\/strong>/is )
		{
			$price = trim($1);
			$price=~s/[a-zA-Z]+//igs;
			#$price=~s/\£//igs;
			if ($price=~m/\-/is)
			{
				$price = (split('\-',$price))[0];
			}
			
		}
		elsif ( $content2 =~ m/product_selling_price\s*\:\s*\[\"([\w\W]*?)\"\]?/is )
		{
			$price = trim($1);
			$price=~s/[a-zA-Z]+//igs;
			#$price=$1 if($price=~m/([\d\.\,]+)/is);
			$price=~s/\£//igs;
			if ($price=~m/\-/is)
			{
				$price = (split('\-',$price))[0];
			}
		}
		#product_id
		if ( $content2 =~ m/var\s*bvProductID\s*=\s*\'([^<]*?)\'\;/is )
		{
			$product_id = trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if ( $content2 =~ m/<h1\s*id\=\"prod-title\"[^<]*?>([\w\W]*?)<\/h1>/is )
		{
			unless($1)
			{
				goto PNF;
			}
			$product_name = trim($1);
		}
		#Brand
		if ( $content2 =~ m/class\=\"mod\s*mod\-brand\-logo\"[^<]*?title\=\"([^>]*?)\"/is )
		{
			$brand = trim($1);
		}
		elsif($content2=~m/<dt>\s*Brand\s*<\/dt>\s*<dd>\s*([\w\W]*?)\s*<\/dd>/is)
		{
			$brand = trim($1);
		}
		
		#description&details
		if($content2 =~ m/<h2>Features<\/h2>([\w\W]*?)<\/div>/is)
		{
			$prod_detail = trim($1);
		}

		if ( $content2 =~ m/id\=\"tabinfo\-care\-info\">([\w\W]*?)id\=\"tabinfo\-delivery\">/is )
		{
			my $desc_content = $1;
			if ( $desc_content =~ m/([\w\W]*?)\s*Brand\s*([\w\W]*?)<div\s*class/is )
			{
				$description = trim($1);
				$prod_detail = trim($2);
				$description =~ s/Product\sinformation//igs;
			}
			else
			{
				$description = trim($desc_content);
				$prod_detail = trim($desc_content);
			}
		}
		elsif($content2=~m/<h2>\s*Delivery\s*<\/h2>([\w\W]*?)<\/div>/is)
		{
			$prod_detail = trim($1);
		}
		
		if($content2=~m/<h2>\s*Colour\s*\:<\/h2>([\w\W]*?)<\/ul>/is) #Multiple Colour & Size
		{
			my $url_block=$1;
			while($url_block=~m/<a\s*href\=\"([^<]*?)\"[^<]*?>\s*<img\s*src\=\"([^>]*?)\"[^<]*>/igs)
			{
				my $pdt_url='http://www.johnlewis.com'.$1 unless($1=~m/^\s*http\:/is);
				my $swatch=$2;
				my $pid=$1 if($pdt_url=~m/sku\=([\d]+)/is);
				my $content3 = get_content($pdt_url);
				my $colour=$1 if($content3=~m/<h2>\s*Colour\s*\:\s*<\/h2>\s*<p>\s*([^<]*?)\s*<\/p>/is);
				
				$product_name =~s/\s*\,\s*$colour//igs;
				#--------------
				# Swatch Image
				$swatch='http:'.$swatch unless($swatch=~m/^\s*http\:/is);
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$colour;
				$hash_default_image{$img_object} = 'n';
				push(@query_string,$query);
				#--------------
				if($content3=~m/<li[^<]*?class\=\"([^<]*?)\"[^<]*?data\-jl\-stock\=\'([^<]*?)\'[^<]*?>\s*<a[^<]*?>\s*<span\s*class\=\"size\">\s*([^<]*?)\s*<\/span>/is)
				{
					#while($content3=~m/<li[^<]*?class\=\"([^<]*?)\"[^<]*?data\-jl\-stock\=\'([^<]*?)\'[^<]*?>\s*<a[^<]*?>\s*<span\s*class\=\"size\">\s*([^<]*?)\s*<\/span>/igs)
					while($content3=~m/<li\s*data-jl-price\=\'[^<]*?([\d\.\,]+)\'\s*class\=\"([^<]*?)\"[^<]*?data\-jl\-stock\=\'([^<]*?)\'[^<]*?>\s*<a[^<]*?>\s*<span\s*class\=\"size\">\s*([^<]*?)\s*<\/span>/igs)
					{
						my $price=$1;
						my $out_of_stock_cont=$2;
						my $size=$4;
						my $out_of_stock;
						if($out_of_stock_cont=~m/out\-of\-stock/is)
						{
							$out_of_stock='y';
						}
						else
						{
							$out_of_stock='n';
						}
						$price=~s/^\s+|\s+$//igs;$price=~s/\,//igs;
						$price="Null" if($price eq '');
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$colour;
						push(@query_string,$query);
					}
				}
				#elsif($content3=~m/<li[^<]*?data\-jl\-sku\=[\'|\"]$pid[\'|\"][^<]*?(?:class\=[\'|\"]([^<]*?)[\'|\"][^<]*?)?data\-jl\-stock\=[\'|\"]([^<]*?)[\'|\"][^<]*?>/is)
				elsif($content3=~m/<li[^<]*?data\-jl\-sku\=[\'|\"]$pid[\'|\"][^<]*?(?:class\=[\'|\"]([^<]*?)[\'|\"][^<]*?)?data\-jl\-stock\=[\'|\"]([^<]*?)[\'|\"][^<]*?data-jl-price\=\'[^<]*?([\d\.\,]+)\'[^<]*?>/is)
				{
					my $out_of_stock_cont=$1.$2;
					my $price=$3;
					my $out_of_stock;
					if($out_of_stock_cont=~m/email/is)
					{
						$out_of_stock='y';
					}
					else
					{
						$out_of_stock='n';
					}
					$price=~s/^\s+|\s+$//igs;$price=~s/\,//igs;
					$price="Null" if($price eq '');
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$colour;
					push(@query_string,$query);
				}
				# Image
				if ( $content3 =~ m/class\=\"media\-player\"([\w\W]*?)<\/ul>\s*<\/div>/is )
				{
					my $alt_image_content = $1;
					my $count=0;
					while ( $alt_image_content =~ m/src\=\"([^>]*?)\?\$prod_main\$\"[^<]*?>\s*<\/[\w]+>/igs )
					{
						$count++;
						my $alt_image = trim($1);
						$alt_image='http:'.$alt_image unless($alt_image=~m/^\s*http\:/is);
						if ( $count == 1 )
						{	
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colour;
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						else
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colour;
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
					}	
				}	
			}
		}
		elsif($content2=~m/<strong class="colour">\s*([^<]*?)\s*<\/strong>/is) #Single Colour & Size
		{
			my $size=trim($1) if($content2=~m/<strong\s*class\=\"size\">\s*([^<]*?)\s*<\/strong>/is);
			my $colour=trim($1) if($content2=~m/<strong class="colour">\s*([^<]*?)\s*<\/strong>/is);
			my $out_of_stock;
			if($content2=~m/<[\w]+\s*class\=\"out\-of\-stock\">/is)
			{
				$out_of_stock='y';
			}
			else
			{
				$out_of_stock='n';
			}
			$product_name =~s/\s*\,\s*$colour//igs;
			$price=~s/^\s+|\s+$//igs;$price=~s/\,//igs;
			$price="Null" if($price eq '');
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$colour;
			push(@query_string,$query);
			
			#Image
			if ( $content2 =~ m/class\=\"media\-player\"([\w\W]*?)<\/ul>\s*<\/div>/is )
			{
				my $alt_image_content = $1;
				my $count=0;
				while ( $alt_image_content =~ m/src\=\"([^>]*?)\?\$prod_main\$\"[^<]*?>\s*<\/[\w]+>/igs )
				{
					$count++;
					my $alt_image = trim($1);
					$alt_image='http:'.$alt_image unless($alt_image=~m/^\s*http\:/is);
					if ( $count == 1 )
					{	
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$colour;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$colour;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}	
			}
		}
		else #No Colour & Multiple Size or Single Size
		{
			if($content2=~m/<li[^<]*?class\=\"([^<]*?)\"[^<]*?data\-jl\-stock\=\'([^<]*?)\'[^<]*?>\s*<a[^<]*?>\s*<span\s*class\=\"size\">\s*([^<]*?)\s*<\/span>/is)
			{
				#while($content2=~m/<li[^<]*?class\=\"([^<]*?)\"[^<]*?data\-jl\-stock\=\'([^<]*?)\'[^<]*?>\s*<a[^<]*?>\s*<span\s*class\=\"size\">\s*([^<]*?)\s*<\/span>/igs)
				while($content2=~m/<li\s*data-jl-price\=\'[^<]*?([\d\.\,]+)\'\s*class\=\"([^<]*?)\"[^<]*?data\-jl\-stock\=\'([^<]*?)\'[^<]*?>\s*<a[^<]*?>\s*<span\s*class\=\"size\">\s*([^<]*?)\s*<\/span>/igs)
				{
					my $price=$1;
					my $out_of_stock_cont=$2;
					my $size=$4;
					my $out_of_stock;
					if($out_of_stock_cont=~m/out\-of\-stock/is)
					{
						$out_of_stock='y';
					}
					else
					{
						$out_of_stock='n';
					}
					$colour='no raw colour' if($colour eq '');
					$price=~s/^\s+|\s+$//igs;$price=~s/\,//igs;
					$price="Null" if($price eq '');
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$product_id;
					push(@query_string,$query);
				}
			}
			else 
			{
				my $size=trim($1) if($content2=~m/<strong\s*class\=\"size\">\s*([^<]*?)\s*<\/strong>/is);
				my $out_of_stock;
				if($content2=~m/<[\w]+\s*class\=\"out\-of\-stock\">/is)
				{
					$out_of_stock='y';
				}
				else
				{
					$out_of_stock='n';
				}
				$colour='no raw colour' if($colour eq '');
				$price=~s/^\s+|\s+$//igs;$price=~s/\,//igs;
				$price="Null" if($price eq '');
				if($product_name ne '')
				{

					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$product_id;
					push(@query_string,$query);
				}
			}
			#Image
			if ( $content2 =~ m/class\=\"media\-player\"([\w\W]*?)<\/ul>\s*<\/div>/is )
			{
				my $alt_image_content = $1;
				my $count=0;
				while ( $alt_image_content =~ m/src\=\"([^>]*?)\?\$prod_main\$\"[^<]*?>\s*<\/[\w]+>/igs )
				{
					$count++;
					my $alt_image = trim($1);
					$alt_image='http:'.$alt_image unless($alt_image=~m/^\s*http\:/is);
					if ( $count == 1 )
					{	
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
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
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit;
	}
}1;

sub trim
{
	my $var=shift;
    $var=~s/<[^>]*?>//igs;
    $var=~s/&nbsp;/ /igs;
	$var=decode_entities($var);
    $var=~s/\s+/ /igs;
	$var =~ s/^\s+//igs;
	$var =~ s/\s+$//igs;
	return ($var);
}
sub get_content()
{
	my $url = shift;
	$url=decode_entities($url);
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"); 
	$req->header("Content-Type"=>"application/x-www-form-urlencoded");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
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
			sleep 5;
			goto Home;
		}
	}
	return $content;
}
