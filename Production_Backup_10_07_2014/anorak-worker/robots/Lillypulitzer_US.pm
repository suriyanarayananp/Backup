#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Lillypulitzer_US;
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
sub Lillypulitzer_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Lillypulitzer-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Lil';
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
	# $ua->proxy(['http', 'https', 'ftp'] => $ENV{HTTP_proxy});
	$ua->env_proxy;
	###########################################

	############Cookie File Creation###########
	($cookie_file,$retailer_file) = &DBIL::LogPath($robotname);
	$cookie = HTTP::Cookies->new(file=>$cookie_file,autosave=>1); 
	$ua->cookie_jar($cookie);
	###########################################
	my @query_string;
	my $skuflag = 0;my $imageflag = 0;my $mflag=0;
	if($product_object_key)
	{
		# my $url = $hashUrl{$product_object_key};
		my $url3=$url;		
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		# open TXT,">>Url_check.txt";
        # print TXT "$url3\n";
		# close TXT;
		# $url3='http://us.anthropologie.com'.$url3 unless($url3=~m/^\s*http\:/is);		
		my $content2 = &get_content($url3);
		goto PNF if($content2==1);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);

		#price_text over
		if ( $content2 =~ m/\"price\"\:\"([^>]*?)\"/is )
		{
			$price_text = &DBIL::Trim($1);
		}

		#price over
		if ( $content2 =~ m/\"price\"\:\"([^>]*?)\"/is )
		{
			$price = &DBIL::Trim($1);
			$price=~s/\$//igs;
		}
		else
		{
			$price='null';
		}
		
		#product_id over
		if ( $content2 =~ m/\"style\"\:\"([^>]*?)\"\,\"name\"/is )
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto dup_productid if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}

		#product_name over
		if ( $content2 =~ m/\"name\"\:\"([^>]*?)\"/is )
		{
			$product_name = &DBIL::Trim($1);
			$product_name =~s/\'//igs;
			$product_name =~s/\\//igs;
		}

		$brand = 'Lillypulitzer';
		# DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		
		#description over
		if ( $content2 =~ m/<div\s*id\=\"productDescription\">([^>]*?)<\/div>/is )
		{		
			$description = &DBIL::Trim($1);		
			$description  =~s/\'//igs;	
			$description  =~s/\"//igs;
		}
		elsif( $content2 =~ m/<p\s*class\=\"MsoNormal\">([^>]*?)<\/p>/is )
		{
			$description = &DBIL::Trim($1);
			$description =~s/\'//igs;
			$description  =~s/\"//igs;
		}

		#details over
		if ( $content2 =~ m/<div\s*id\=\"moreProductInfo\">([^>]*?)<\/div>/is )
		{		
			$prod_detail = &DBIL::Trim($1);
			 $prod_detail  =~s/\'//igs;
		}
		
		
		my $sku_block;
		if($content2=~m/var\s*variantData([^<]*?)\;/is) ### sku block
		{
			$sku_block=$1;
			# print "\nsku block capatured\n";
		}

		my %size;my %colour;
		while($sku_block=~m/\"sku\"\:\"[^<]*?\"\,\"swatches\"\:\[(\d+)\,(\d+)\]\}/igs)
		{
			$colour{$1}=1;
			$size{$2}=1;
		}

		my @sizes= keys %size;
		my @colours= keys %colour;
		my @block; my %color_tol;
		while($sku_block=~m/(\{\"icon\"\:\"[^_]*?_[a-z]+\"\,[^<]*?\"DISPLAY_ATTRIBUTE_NAME_1\"\})/igs)
		{
			my $block=$1;
			push(@block,$block);
		}

		#### taking color names using color ids
		foreach my $id(@block)
		{
			foreach my $cls_id(@colours)
			{
				if($id=~m/\{\"icon\"\:\"([^\"]*?)\"\,\"selectedSwatch\"\:\"[^\"]*?\"\,\"sequence\"\:[^\"]*?\,\"value\"\:\"([^\"]*?)\"\,\"images\"\:\[[^<]*?\]\,\"recoloredImage\"\:\"[^\"]*?\"\,\"label\"\:\"Color\"\,\"swatchId\"\:$cls_id\,\"key\"\:\"DISPLAY_ATTRIBUTE_NAME_1\"\}/is)
				{
					my $swatch ="http://s7d1.scene7.com/is/image/sugartown/$1";
					$color_tol{$cls_id}=$2;
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$image_objectkey{$img_object}=$color_tol{$cls_id};
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
					if($id=~m/recoloredImage\"\:\"([^\"]*?)\"\,/is)
					{
						my $default_img ="http://s7d1.scene7.com/is/image/sugartown/$1";
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_img,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_img,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_tol{$cls_id};
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					while($id=~m/src\"\:\"([^\"]+?)\"/igs)
					{
						my $default_img ="http://s7d1.scene7.com/is/image/sugartown/$1";
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_img,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_img,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_tol{$cls_id};
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}	
				
			}
		}
		### Check the stock using color and size id..
		foreach my $colors_id(@colours)
		{
			foreach my $sizes_id(@sizes)
			{
				if($sku_block=~m/\"inventoryLevel\"\:\"(\d+)\"\,\"onSale\"\:\"[^\"]*?\"\,\"price\"\:\"[^\"]*?\"\,\"backOrderDate\"\:\"[^\"]*?\"\,\"thresholdInvLevel\"\:\"[^\"]*?\"\,\"image\"\:\"[^<]*?\"\,\"backOrderFlag\"\:\"[^\"]*?\"\,\"backOrderQuantity\"\:\"[^\"]*?\"\,\"salePrice\"\:\"[^\"]*?\"\,\"inStorePickUpFlag\"\:\"[^\"]*?\"\,\"sku\"\:\"[^\"]*?\"\,\"swatches\"\:\[$colors_id\,$sizes_id\]/is)
				{
					my $stock_count=$1;
					if($stock_count == 0) ### inventoryLevel is 0 means out of stock
					{
						my $color=$color_tol{$colors_id};
						my $size=$1 if($sku_block=~m/\"value\"\:\"([^\"]*?)\"\,\"recoloredImage\"\:\"[^\"]*?\"\,\"label\"\:\"Size\"\,\"swatchId\"\:$sizes_id\,/is);
						my $out_of_stock='y';
						$out_of_stock='n' if($content2=~m/ value\=\'Pre\-Order\'/is);
						 my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
					else #### inventoryLevel is greater than 0.
					{
						if($sku_block=~m/\"image\"\:\"[^<]*?\"\,\"backOrderFlag\"\:\"[^\"]*?\"\,\"backOrderQuantity\"\:\"[^\"]*?\"\,\"salePrice\"\:\"[^\"]*?\"\,\"inStorePickUpFlag\"\:\"[^\"]*?\"\,\"sku\"\:\"[^\"]*?\"\,\"swatches\"\:\[$colors_id\,$sizes_id\]/is)
						{					
							my $color=$color_tol{$colors_id};
							my $size=$1 if($sku_block=~m/\"value\"\:\"([^\"]*?)\"\,\"recoloredImage\"\:\"[^\"]*?\"\,\"label\"\:\"Size\"\,\"swatchId\"\:$sizes_id\,/is);
							my $out_of_stock='n';
							 my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
					}
				}
				else
				{
					my $color=$color_tol{$colors_id};
					my $size=$1 if($sku_block=~m/\"value\"\:\"([^\"]*?)\"\,\"recoloredImage\"\:\"[^\"]*?\"\,\"label\"\:\"Size\"\,\"swatchId\"\:$sizes_id\,/is);
					my $out_of_stock='y';
					$out_of_stock='n' if($content2=~m/ value\=\'Pre\-Order\'/is);
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;
					push(@query_string,$query);
				}		
			}
		}

		
		#swatch new 
			
		#Image over
		# my %altimage_hash;
		# while ( $content2 =~ m/\{\"icon\"\:\"[^>]*?\"\,\"selectedSwatch\"\:\"([a-zA-Z]{1})\"\,\"sequence[^>]*?\"images\"\:([^^]*?)DISPLAY_ATTRIBUTE_NAME[^>]*?\} /igs )
		# {
			# my $default_img=$1;
			# my $alt_image_content = $2;
			# if($alt_image_content=~m/\"recoloredImage\"\:\"([^>]*?)",/is)
			# {
				# my $check=$1;
				# my $imaaage=$check;
				# $check=~s/^[^>]*?_([^>]*?)$/$1/igs;
				# if(($check ne '') && (%swatch_hash~~/$check/))
				# {
					# my $alt_image ='http://s7d1.scene7.com/is/image/sugartown/'.DBIL::Trim($imaaage);
					# my ($imgid,$img_file) = DBIL::ImageDownload($alt_image,'product',$retailer_name);
					# my ($img_object,$flag) = DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					# $imageflag = 1 if($flag);
					# $image_objectkey{$img_object}=lc($color_hash{$check});
					# $hash_default_image{$img_object}='y';	
				
					# while ( $alt_image_content =~ m/\{\"sequence[^>]*?src\"\:\"([^>]*?)\"\}/igs )
					# {
						# my $imaaage=$1;
						# if($imaaage ne '')
						# {
							# my $col_id=$1;
							# my $alt_image ='http://s7d1.scene7.com/is/image/sugartown/'.DBIL::Trim($imaaage);
							# my $img_file;
							# $alt_image =~ s/\\\//\//g;			
							# $img_file = (split('\/',$alt_image))[-1];
							# if(%altimage_hash~~/$alt_image/)
							# {
								# print "alt image already exist\n";
							# }
							# else
							# {
								# $altimage_hash{$alt_image}='';
								# my ($imgid,$img_file) = DBIL::ImageDownload($alt_image,'product',$retailer_name);
							
								# my ($img_object,$flag) = DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								# $imageflag = 1 if($flag);
								# $image_objectkey{$img_object}=lc($color_hash{$check});
								# $hash_default_image{$img_object}='n';
							# }
						# }
					
					# }
				# }
			# }	
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
		PNF:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		dup_productid:
		$dbh->commit;
	}
}1;
sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $ua=LWP::UserAgent->new;
	$ua->agent("User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (.NET CLR 3.5.30729)");
	my $cookie = HTTP::Cookies->new(file=>$0."_cookie.txt",autosave=>1);
	$ua->cookie_jar($cookie);
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	open fh,">>$retailer_file";
	print fh "Code $code\n";
	close fh;
	my $content;
	if($code =~m/20/is)
	{
		print "\n----\n$url-----\n";
		$content = $res->content;
	}	
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			goto Home;
		}
		return 1;
	}	
}
