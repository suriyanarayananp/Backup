#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Chicos_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
# use DBI;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Chicos_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Chicos-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Chi';
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
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.chicos.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = get_content($url3);
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;my %sku_objectkey;my %image_objectkey;my %hash_default_image;
		##### Loop for checking x Products
		if($content2=~m/>[^>]*?this\s*item\s*sold\s*out\s*sooner\s*than\s*expected\s*\.\s*[^<]*?</is)
		{
			goto noinfo;
		}
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$prod_detail,$out_of_stock,$colour);
		#product_id
		if ( $content2 =~ m/var\s*defaultProdId\s*\=\s*\"([^\"]*?)\"\;/is )
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
		}
		#product_name
		if ( $content2 =~ m/\"name\"\:\"([^\"]*?)\"/is )
		{
			$product_name = &DBIL::Trim($1);
		}
		#Brand
		if ( $content2 =~ m/brandName=\'([^\']*)?\'/is )
		{
			$brand = &DBIL::Trim($1);
			if ( $brand !~ /^\s*$/g )
			{
				&DBIL::SaveTag('Brand',lc($brand),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			}
		}
		
		#description&details
		if ( $content2 =~ m/(<div\s*id=\"product\-description\">\s*[\w\W]*?\s*<\/div>)/is )
		{
			my $desc_content = $1;
			$desc_content=~s/’/'/igs;
			$desc_content=replace($desc_content);
			if ( $desc_content =~ m/>([\w\W]*?)\s*<ul>([\w\W]*?)\s*<\/div>/is )
			{
				$description = &DBIL::Trim($1);
				$prod_detail = &DBIL::Trim($2);
			}
			else
			{
				$description = &DBIL::Trim($desc_content);
				$prod_detail = &DBIL::Trim($desc_content);
			}
		}
		my %duplicate_color;
		if($product_id!~m/prod/is)
		{
			if($product_id=~m/[a-z]+/is)
			{
				if ( $content2 =~ m/<option\s*value\=\"(\d+)">/is )
				{
					$product_id = $1;
				}
			}
			my ($sku_content,$imag_count);	
			if( $content2=~m/var\s*product\s*$product_id\s*\=([^<]*?)\]\,/is)
			{
				$sku_content=$1;
			}
			if( $sku_content=~m/\"imageCount\"\:\"(\d+)\"/is )
			{
				$imag_count=$1;
			}
			my $flag_image=0;
			if( $content2=~m/<div\s*id\=\"swatches_$product_id\"\s*style="[^\"]*?\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
			{ 
				my $block=$1;
				
				$block=~s/(<div\s*id\=\"product\-price\">)/price_block$1/igs;
				$block.='price_block';
				### price and price text
				while( $block=~m/<div\s*id\=\"product\-price\">\s*([\w\W]*?)\s*price_block/igs )
				{
					my $price_block=$1;
					if($price_block=~m/<span\s*class\=\"regular\-price\">\s*<[^>]*?>\s*([^<]*?)\s*<\/span>/is)
					{
						$price_text=$1;
						$price=$price_text;
						$price=~s/\$//igs;$price=~s/\,//igs;
						$price=~s/\.00//igs;
					}
					elsif($price_block=~m/<span\s*class\=\"list\-price\">\s*<[^>]*?>\s*([^<]*?)\s*<\/span>\s*<span\s*class\=\"sale\-price\">\s*<[^>]*?>\s*([^<]*?)\s*<\/span>/is)
					{
						$price_text=$1." ".$2;
						$price=$2;
						$price=~s/\$//igs;$price=~s/\,//igs;
						$price=~s/\.00//igs;
					}
					
					### swatch
					while( $price_block=~m/onerror\=\"document\.getElementById\(\'swatch_([\d]+)\'\)\.style\.display\s*\=\s*\'[^\']*?\'\;\"\s*alt\=\'([^\']*?)\'\s*src\=\'([^\']*?)\'>/igs )
					{
						my $swatch_id=$1;
						$colour=$2;
						my $swatch_url='http://www.chicos.com'.$3;
						### size and out of stock
						while($sku_content=~m/\{\"colorCode\"\:\"$swatch_id\"\,\s*\"colorName\"\:\"[^\"]*?\"\,\s*\"sku\"\:\"[^\"]*?\"\,\s*\"size\"\:\"([^\"]*?)\"\}/igs)
						{
							my $size=$1;
							$out_of_stock = 'n';
							
							my $duplicate_check=$colour.$size;
							$duplicate_check=~s/\W//igs;
							if($duplicate_color{$duplicate_check} eq '')
							{
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$colour;
								$duplicate_color{$duplicate_check}=1;
								push(@query_string,$query);
							}
						}
						
						my $img_url='http://www.chicos.com/store/browse/altviews.jsp?style='.$product_id.'&color='.$swatch_id.'&imgCount='.$imag_count;
						my $img_content2 = get_content($img_url);
						
						### Main image
						if($img_content2=~m/<div\s*id\=\"large\-image\"><img\s*src\=\"([^\"]*?)\"/is)
						{
							my $main_url='http://www.chicos.com'.$1;
							
							my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product','chicos-us');
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$colour;
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						### Alternative image
						
						if($flag_image == 0)
						{
							while($img_content2=~m/<a\s*href\=\"javascript\:imgSwap\([\d]+\,\'\'\,\'[^\"]*?\'\)\;\"><img\s*src\=\"([^\"]*?)\"/igs)
							{
								my $alt_url='http://www.chicos.com'.$1;
								$alt_url=~s/_thumb//igs;
							
								my ($imgid,$img_file) = &DBIL::ImageDownload($alt_url,'product','chicos-us');
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$colour;
								$hash_default_image{$img_object}='n';
								$flag_image=1;
								push(@query_string,$query);
							}
						}
						### swatch image
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_url,'swatch','chicos-us');
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_url,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$colour;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}	
				}
			}
		}
		else
		{
			my $cont3=$content2;
			my $product_id_add=$product_id;
			my %dupe;my $flag_image=0;
			if ( $content2 =~ m/<option\s*value\=\"(\d+)">/is )
			{
				$product_id = $1;
			}
			while($content2=~m/<option\s*value\=\"(\d+)">\s*([^<]*?)\s*<\/option>/igs)
			{
				my $product_id1=$1;
				my $lenth=$2;
				decode_entities($lenth);
				my ($sku_content,$imag_count);	
				if( $cont3=~m/var\s*product\s*$product_id1\s*\=([^<]*?)\]\,/is)
				{
					$sku_content=$1;
				}
				if( $sku_content=~m/\"imageCount\"\:\"(\d+)\"/is )
				{
					$imag_count=$1;
				}
				
				if( $cont3=~m/<div\s*id\=\"swatches_$product_id1\"\s*style="[^\"]*?\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
				{
					my $block=$1;
					
					$block=~s/(<div\s*id\=\"product\-price\">)/price_block$1/igs;
					$block.='price_block';
					### price and price text
					while( $block=~m/<div\s*id\=\"product\-price\">\s*([\w\W]*?)\s*price_block/igs )
					{
						my $price_block=$1;
						if($price_block=~m/<span\s*class\=\"regular\-price\">\s*<[^>]*?>\s*([^<]*?)\s*<\/span>/is)
						{
							$price_text=$1;
							$price=$price_text;
							$price=~s/\$//igs;$price=~s/\,//igs;
							$price=~s/\.00//igs;
						}
						elsif($price_block=~m/<span\s*class\=\"list\-price\">\s*<[^>]*?>\s*([^<]*?)\s*<\/span>\s*<span\s*class\=\"sale\-price\">\s*<[^>]*?>\s*([^<]*?)\s*<\/span>/is)
						{
							$price_text=$1." ".$2;
							$price=$2;
							$price=~s/\$//igs;$price=~s/\,//igs;
							$price=~s/\.00//igs;
						}
						### swatch
						while( $price_block=~m/onerror\=\"document\.getElementById\(\'swatch_([\d]+)\'\)\.style\.display\s*\=\s*\'[^\']*?\'\;\"\s*alt\=\'([^\']*?)\'\s*src\=\'([^\']*?)\'>/igs )
						{
							my $swatch_id=$1;
							$colour=$2;
							my $swatch_url='http://www.chicos.com'.$3;
							### size and out of stock
							while($sku_content=~m/\{\"colorCode\"\:\"$swatch_id\"\,\s*\"colorName\"\:\"([^\"]*?)\"\,\s*\"sku\"\:\"[^\"]*?\"\,\s*\"size\"\:\"([^\"]*?)\"\}/igs)
							{
								my $colour1=$1;
								my $size=$2;
								$out_of_stock = 'n';
								
								my $size_add=$size." ".$lenth;
								my $duplicate_check=$colour1.$size_add;
								$duplicate_check=~s/\W//igs;
								if($duplicate_color{$duplicate_check} eq '')
								{
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size_add,$colour1,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$colour;
									$duplicate_color{$duplicate_check}=1;
									push(@query_string,$query);
								}
							}
							
							my $img_url='http://www.chicos.com/store/browse/altviews.jsp?style='.$product_id_add.'&color='.$swatch_id.'&imgCount='.$imag_count;
							if($dupe{$img_url} eq '')
							{
								$dupe{$img_url}=1;
								my $img_content2 = get_content($img_url);
								### Main image
								if($img_content2=~m/<div\s*id\=\"large\-image\"><img\s*src\=\"([^\"]*?)\"/is)
								{
									my $main_url='http://www.chicos.com'.$1;
									my ($imgid,$img_file) = &DBIL::ImageDownload($main_url,'product','chicos-us');
									my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$imageflag = 1 if($flag);
									$image_objectkey{$img_object}=$colour;
									$hash_default_image{$img_object}='y';
									push(@query_string,$query);
								}
								### Alternative image
								
								if($flag_image == 0)
								{
									while($img_content2=~m/<a\s*href\=\"javascript\:imgSwap\([\d]+\,\'\'\,\'[^\"]*?\'\)\;\"><img\s*src\=\"([^\"]*?)\"/igs)
									{
										my $alt_url='http://www.chicos.com'.$1;
										$alt_url=~s/_thumb//igs;
										my ($imgid,$img_file) = &DBIL::ImageDownload($alt_url,'product','chicos-us');
										my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
										$imageflag = 1 if($flag);
										$image_objectkey{$img_object}=$colour;
										$hash_default_image{$img_object}='n';
										$flag_image=1;
										push(@query_string,$query);
									}
								}
								## swatch image
								
								my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_url,'swatch','chicos-us');
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_url,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$colour;
								$hash_default_image{$img_object}='n';
								push(@query_string,$query);
							}
						}	
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
		noinfo:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit();
	}
}1;

sub get_content
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
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
sub replace($)
{
	my $text=shift;
	$text=~s/\&trade\;|\&\#8482\;|\&\#0153\;/™/igs;$text=~s/\&euro\;|\&\#8364\;/€/igs;$text=~s/\&euml\;|\&\#203\;/ë/igs;$text=~s/\&ecirc\;|\&\#202\;/ê/igs;$text=~s/\&eacute\;|\&\#201\;/é/igs;$text=~s/\&egrave\;|\&\#200\;/è/igs;$text=~s/\&aring\;|\&\#197\;|\&\#229\;/å/igs;$text=~s/\&auml\;|\&\#228\;|\&\#196\;/ä/igs;$text=~s/\&atilde\;|\&\#195\;|\&\#227\;/ã/igs;$text=~s/\&acirc\;|\&\#194\;|\&\#226\;/â/igs;$text=~s/\&aacute\;|\&\#193\;|\&\#225\;/á/igs;$text=~s/\&agrave\;|\&\#192\;|\&\#224\;/à/igs;$text=~s/\&Ouml\;|\&\#214\;|\&\#246\;/ö/igs;$text=~s/\&Otilde\;|\&\#213\;|\&\#245\;/õ/igs;$text=~s/\&Ocirc\;|\&\#212\;|\&\#244\;/ô/igs;$text=~s/\&Oacute\;|\&\#211\;|\&\#243\;/ó/igs;$text=~s/\&Ograve\;|\&\#210\;|\&\#242\;/ò/igs;$text=~s/\&quot\;|\&\#34\;/"/igs;$text=~s/\&amp\;|\&\#38\;/&/igs;$text=~s/\&apos\;/'/igs;$text=~s/\&nbsp\;|\&\#160\;/ /igs;$text=~s/\&pound\;|\&\#163\;/£/igs;$text=~s/\&copy\;|\&\#169\;/©/igs;$text=~s/\&reg\;|\&\#174\;/®/igs;$text=~s/\&acute\;|\&\#180\;/´/igs;$text=~s/\&Igrave\;|\&\#204\;|\&\#236\;/ì/igs;$text=~s/\&Iacute\;|\&\#205\;|\&\#237\;/í/igs;$text=~s/\&Icirc\;|\&\#206\;|\&\#238\;/î/igs;$text=~s/\&Iuml\;|\&\#207\;|\&\#239\;/ï/igs;$text=~s/\&mdash\;|\&\#8212\;/—/igs;$text=~s/\&ndash\;|\&\#8211\;/–/igs;$text=~s/\&iexcl\;|\&\#161\;/¡/igs;$text=~s/\&cent\;|\&\#162\;/¢/igs;$text=~s/\&curren\;| \&\#164\;/¤/igs;$text=~s/\&yen\;|\&\#165\;/¥/igs;$text=~s/\&brvbar\;|\&\#166\;/¦/igs;$text=~s/\&ordf\;|\&\#170\;/ª/igs;$text=~s/\&macr\;|\&\#175\;/¯/igs;$text=~s/\&deg\;|\&\#176\;/°/igs;$text=~s/\&plusmn\;|\&\#177\;/±/igs;$text=~s/\&Ugrave\;|\&\#217\;|\&\#249\;/ù/igs;$text=~s/\&Uacute\;|\&\#218\;|\&\#250\;/ú/igs;$text=~s/\&Ucirc\;|\&\#219\;|\&\#251\;/û/igs;$text=~s/\&Uuml\;|\&\#220\;|\&\#252\;/ü/igs;$text=~s/\&Yacute\;|\&\#253\;/Ý/igs;$text=~s/\&lsquo\;|\&\#8216\;/‘/igs;$text=~s/\&rsquo\;|\&\#8217\;/’/igs;$text=~s/\&sbquo\;|\&\#8218\;/‚/igs;$text=~s/\&ldquo\;|\&\#8220\;/“/igs;$text=~s/\&rdquo\;|\&\#8221\;/”/igs;$text=~s/\&bdquo\;|\&\#8222\;/„/igs;$text=~s/\&bull\;|\&\#8226\;/·/igs;$text=~s/\&sdot\;|\&\#8901\;/·/igs;$text=~s/\&ccedil\;|\&\#199\;/ç/igs;$text=~s/\&sup1\;|\&\#185\;/¹/igs;$text=~s/\&sup2\;|\&\#178\;/²/igs;$text=~s/\&sup3\;|\&\#179\;/³/igs;$text=~s/\&szlig\;|\&\#223\;/ß/igs;$text=~s/\&THORN\;|\&\#222\;/Þ/igs;$text=~s/\&yuml\;|\&\#255\;/ÿ/igs;$text=~s/\&ordm\;|\&\#186\;/º/igs;$text=~s/\&raquo\;|\&\#187\;/»/igs;$text=~s/\&frac14\;|\&\#188\;/¼/igs;$text=~s/\&frac12\;|\&\#189\;/½/igs;$text=~s/\&frac34\;|\&\#190\;/¾/igs;$text=~s/\&\#39\;/'/igs;
	return $text;
}