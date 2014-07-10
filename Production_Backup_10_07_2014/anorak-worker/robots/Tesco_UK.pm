#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Tesco_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
### require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Tesco_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;

	####Variable Initialization##############
	$robotname='Tesco-UK--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Tes';
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
	
	my @brand=("AX Paris","D-Struct","Dare 2b","Diesel","Disney","Dress Up By Design","Gola","Gossard","Jeff Banks","Julia","Just Sheepskin","Maidenform","Marie Meili","Moda in Pelle","Moshi Monsters","Panache","Peppa Pig","Pineapple","Playtex","Pretty Polly","Proskins","Threadbare","Tia","Timeout","Timex","Tokyo Tigers","Totes","Tricky Tracks","Trinny & Susannah","Trespass","Truffle","Brave Soul","Ebound","Ella","Elle Sport","Emma Jane Maternity","Emoi","Envy","Harvey James","Heavenly Bump","Hello Kitty","Hi-Tec","HNY Vintage","Hot Honi","Kappa","Name It","Nike","RG512","Regatta","Rhino Rugby","Ripstop","Ultimo","Wedge Welly","Wonderbra","Casio","Charlie&me","Cherokee","Curvy Kate","F&F","F&F Limited Edition","F&F Signature","F&F True","Ice Blossom","Lisa Butcher by Made","ONeill","Scottys Little Soldiers","Shock Absorber","Smith & Canova","Smith & Jones","South Beach","Speedo","Stella Morgan","Very Victoria","Zip Zap","Zoggs");

	my $skuflag = 0;my $imageflag = 0;
	if($product_object_key)
	{
		my $url3=$url;		
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.clothingattesco.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &get_content($url3);
		my @query_string;	
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$brand,$product_id,$product_name,$description,$prod_detail);
		
		#price_text
		if($content2 =~ m/<div\s*[^>]*?\"oneProductContent\s*hide\">\s*([\w\W]*?)\s*<\/div>\s*<div\s*[^>]*?\"size\-qty\-add\">/is)
		{
			$price_text = $1;
			
			$price_text =~ s/<[^>]*?>/ /igs;
			$price_text =~ s/\&nbsp\;|amp\;/ /igs;
			$price_text =~ s/\s+/ /igs;
			$price_text =~ s/^\s+|\s+$//igs;
			$price_text =~ s/\£/\Â\£/igs;
			$price_text =~ s/\s+save$//igs;
			
		}
		if($content2=~m/<div\s*[^>]*?\"oneProductContent\s*hide\">\s*([\w\W]*?)\s*<\/div>\s*<div\s*[^>]*?\"size\-qty\-add/is)
		{
			my $price_cont=$1;
			# price
			if($price_cont=~m/<span\s*[^>]*?\"pricenow\s*[^>]*?\">\s*([\w\W]*?)?<\/span>\s*<\/span>/is)
			{
				$price = trim($1);
				if($price=~m/([^>]*?)\-[^>]*?$/is)
				{
					$price=$1;
				}
			}
			$price=~s/^Â//igs;
			$price=~s/£//igs;
			$price=~s/\,//igs;						
		}
		$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
		#product_id
		if ( $url3 =~ m/invt\/([a-z]{2}\d+)/is )
		{
			$product_id = trim($1);		

			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if ( $content2 =~ m/og\:title\"\s*content\=\"([^>]*?)\"[^>]*?>/is )
		{
			$product_name = trim($1);
			
			$product_name =~s/amp\;//igs;
			$product_name =~s/\&\#39\;/\'/igs;			
			$product_name=~s/\&reg\;/Â®/igs;
			$product_name=~s/\&eacute\;/Ã©/is;
			$product_name=~s/\&egrave\;/Ã©/is;
			$product_name=~s/\&trade\;/â„¢/igs;
			$product_name=~s/<[^>]*?>/ /igs;
			$product_name=~s/^\s+|\s+$//igs;
			$product_name=~s/\s+/ /igs;	
		}
		
		if ( $content2 =~ m/Description\s*\:?\s*(<\/h\d+>\s*[\w\W]*?\s*\/h\d+>\s*[\w\W]*?)\s*<\/div>/is )
		{
			my $sub_cont=$1;
			if ( $sub_cont =~ m/<p\s*[^>]*?sku\-number\s*[^>]*?>\s*[^>]*?\s*<\/p>\s*([\w\W]*?)\s*<\/div>\s*/is )
			{
				$description = trim($1);
				$description = decode_entities($description);
			}
			if ( $sub_cont =~ m/Materials\s*[^>]*?<\/h\d+>\s*([\w\W]*?)\s*<[^>]*?>\s*$/is )
			{
				$prod_detail = trim($1);
				$prod_detail = "Materials, Care &Information ".$prod_detail;
				$prod_detail = decode_entities($prod_detail);
			}
		}
		elsif ( $content2 =~ m/<a\s*[^>]*?href\=\"([^>]*?)\"\s*[^>]*?>\s*<[^>]*?>\s*More\s*Details/is )
		{
			my $details_url=$1;
			my $sub_cont = get_content($details_url);
			if ( $sub_cont =~ m/Description\s*\:?\s*(<\/h\d+>\s*[\w\W]*?\s*\/h\d+>\s*[\w\W]*?)\s*<\/div>/is )
			{
				my $sub_cont1=$1;
				if ( $sub_cont1 =~ m/<p\s*[^>]*?sku\-number\s*[^>]*?>\s*[^>]*?\s*<\/p>\s*([\w\W]*?)\s*<\/div>\s*/is )
				{
					$description = trim($1);
				}
				if ( $sub_cont1 =~ m/Materials\s*[^>]*?<\/h\d+>\s*([\w\W]*?)\s*<[^>]*?>\s*$/is )
				{
					$prod_detail = trim($1);
					$prod_detail = "Materials, Care &Information ".$prod_detail;
				}
			}
		}
		#Brand		
		foreach my $brand_name (@brand)
		{
			if($product_name=~m/^$brand_name\s*/is)
			{
				$brand=$brand_name;
			}
		}
		
		#colour
		my($color,$color_code);
		if($content2=~m/alt\-colour[^>]*?>\s*<[^>]*?>\s*([^>]*?)\s*<[^>]*?>\s*<[^>]*?>\s*<[^>]*?>\s*<a\s*[^>]*?href\=\"([^>]*?)\"[^>]*?>\s*<img\s*[^>]*?\s*selected\"/is)
		{
			$color 		= trim($1);
			$color_code = trim($2);			
		}
		elsif($content2=~m/alt\-?colour[^>]*?>\s*(?:<[^>]*?>)?\s*([^>]*?)\s*<[^>]*?>\s*<[^>]*?>\s*<[^>]*?>\s*<a\s*[^>]*?href\=\"([^>]*?)\"[^>]*?>\s*<img\s*[^>]*?\s*selected\"/is)
		{
			$color 		= trim($1);
			$color_code = trim($2);
		}
		elsif($content2=~m/select\s*colour\s*<\/option>\s*<option\s*value\=[\"\']([^<]*?)[\"\']/is)
		{
			$color = trim($1);			
		}
		else
		{
			$color='No color';
		}
		# size & out_of_stock
		my $sku_count=0;
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my @size_array;
		if($content2=~m/(?:<\/form>|<\/p>)\s*<script[^<]*?>\s*([\w\W]*?)\s*<\/script>/is)
		{
			my $size_block=$1;
			
			while($size_block=~m/Venda\.Attributes\.StoreJSON\s*([\w\W]*?)\s*\;/igs)
			{
				my $size_content = $1;
				my ($size,$size_value,$color_value,$sku_price);
				if($size_content=~m/att1[\"\']\:[\"\']([^<]*?)[\"\'][^<]*?atronhand\s*\"\:\s*([\d]+)\s*\,\"[^>]*?atr2\"\:\"([^>]*?)\"\,\"atrsku[^M]*?atrsell\"\:\"([^<]*?)\"/is)
				{
					$color_value = trim($1);
					$size_value  = trim($2);
					$size        = trim($3);
					$sku_price   = trim($4);
					
					next if($size eq '');
					
					####Duplicate Size######
					if(grep( /^$size$/, @size_array ))
					{
						next;
					}
					push(@size_array,$size);
					
					if($sku_price ne '')
					{
						$price=$sku_price;
						
						if($price_text eq '')
						{
							$price_text='£'.$sku_price;
						}
					}
					
					if($size_value>=1)
					{
						my $out_of_stock='n';
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_value,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=lc($color);
						push(@query_string,$query);
					}
					else
					{
						my $out_of_stock='y';
						
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_value,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=lc($color);
						push(@query_string,$query);
						
					}
				}
			}
		}
		
		if($content2=~m/<img\s*[^>]*?\s*selected\"\s*[^>]*?src\=\"([^>]*?)\"[^>]*?alt\=\"([^<]*?)\"[^<]*?>/is)
		{
			my $swatch 	= trim($1);
			my $swatch_color 	= trim($2);
			
			unless($swatch=~m/^\s*http\:/is)
			{
				$swatch='http:'.$swatch;
			}
			
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
			$image_objectkey{$img_object}=lc($swatch_color);
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
		}
		
		#Image
		if($content2 =~ m/pdp-thumbnails\s*[^>]*?>\s*[\w\W]*?\s*<\/div>/is)
		{
			while ( $content2 =~ m/pdp-thumbnails\s*[^>]*?>\s*([\w\W]*?)\s*<\/div>/igs )
			{
				my $alt_image_content = $1;
				my $count=1;
				while ( $alt_image_content =~ m/<a\s*[^>]*?href\=\"([^>]*?)\"\s*[^>]*?>\s*<img/igs )
				{
					my $alt_image = trim($1);
					unless($alt_image=~m/^\s*http\:/is)
					{
						$alt_image='http:'.$alt_image;
					}
					$alt_image =~ s/\$//g;
					$alt_image =~ s/([^>]*?)\_(\d{3})\_([^>]*?)/$1\_\$code\_$3/ig;
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					if ( $count == 1 )
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=lc($color);
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=lc($color);
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					$count++;
				}
			}
		}
		else
		{
			if($content2=~m/<div class="pdp-main-image">([\w\W]*?)<\/div>/is)
			{
				my $alt_image_content = $1;
				my $count=1;
				while($alt_image_content=~m/<a\s*[^>]*?href\=\"([^>]*?)\"\s*[^>]*?>\s*<img/igs)
				{
					my $alt_image = trim($1);
					unless($alt_image=~m/^\s*http\:/is)
					{
						$alt_image='http:'.$alt_image;
					}
					$alt_image =~ s/\$//g;
					$alt_image =~ s/([^>]*?)\_(\d{3})\_([^>]*?)/$1\_\$code\_$3/ig;
					
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					if ( $count == 1 )
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=lc($color);
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=lc($color);
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					$count++;
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
		
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id );
		push(@query_string,$query1);
		push(@query_string,$query2);
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);
		LAST:
		print "";
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
			sleep 100;
			goto Home;
		}
	}
	return $content;
}

sub trim()
{
	my $txt = shift;
	
	$txt =~ s/\<[^>]*?\>/ /ig;
	$txt =~ s/\n+/ /ig;
	$txt =~ s/\"/\'\'/g;
	$txt =~ s/^\s+|\s+$//ig;
	$txt =~ s/\s+/ /ig;
	$txt =~ s/\&nbsp\;//ig;
	$txt =~ s/\&amp\;/\&/ig;
	$txt =~ s/\&bull\;/•/ig;
	
	return $txt;
}