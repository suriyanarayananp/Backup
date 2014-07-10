#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Bananarepublic_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
#require "/opt/home/merit/Merit_Robots/DBIL.pm"; # USER DEFINED MODULE DBIL.PM
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm"; 
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Bananarepublic_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Bananarepublic-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Ban';
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
	my $skuflag = 0;my $imageflag = 0;my $mflag=0;
	if($product_object_key)
	{
		my $url3=$url;
		my $price_url=$url3;
		my ($product_id,$var_price_con,%price_text_hash,%price_hash);
		if($url3=~m/pid\=([\d]{6}?)/is)
		{
			$price_url='http://bananarepublic.gap.com/browse/productData.do?pid='.$1;
			$product_id=$1;
		}
		
		my $default_image_id;
		if($url3=~m/pid\=([^<]+?)\s*$/is)
		{
			$default_image_id=$1;
			
		}
		my $content2 = get_content($url3);
		goto PNF if($content2=~m/this\s*item\s*is\s*currently\s*out\s*of\s*stock/is);
		while($content2=~m/<br[^>]*?>\s*([^<]*?)\s*\-\s*(\$[^<]*?)\s*<br[^>]*?>\s*([^<]*?)\s*<br[^>]*?>/igs)
		{
			$price_text_hash{$1}=$2.' '.$3;
			$price_hash{$1}=$3;
			$price_hash{$1}=~s/[^\d\.]+//igs;
		}
		# print "price_url :: $price_url--\n";
		my $price_content2 = get_content($price_url);
		$price_content2=~s/\s*\&\#189\;/.5/igs;
		my $defaultImg = $1 if($price_content2 =~ m/objP\.StyleColor\(\"$default_image_id\"\,[\w\W]*?\'z\'\s*\:\s*\'([^>]*?)\'/is);
		my $defaultSwa = $1 if($price_content2 =~ m/objP\.StyleColor\(\"$default_image_id\"\,[\w\W]*?\'S\'\s*\:\s*\'([^>]*?)\'/is);
		my (@json_array,%regulartall_type,@var_array);
		my ($prod_detail,$description,$brand,$product_name);
		# print "price_content2 :: $price_content2\n";
		# open sr, ">play.html";
		# print sr $price_content2;
		# # print  $content;
		# close sr;
		# <STDIN>;
		if($price_content2=~m/setProductVariantStyles\(([\w\W]*?)\)/is)
		{
			my $variant_con=$1;
			# print "variant_con :: $variant_con\n";
			while($variant_con=~m/(\d+?)\^\,\^([\d]+)\^\,\^([\w]+?)\^\,\^(?:true|false)/isg)
			{
				my $url='http://bananarepublic.gap.com/browse/productData.do?pid='.$1.'&vid='.$2;
				my $pid=$1;
				$regulartall_type{$url}=$3;
				push(@var_array,$url);
				# push(@var_match_pid,$pid);
				push(@json_array,$url) if($pid eq $product_id);
			}
		}
		# print "json_array :: @json_array \n";
		my $Var_len=$#var_array;
		my $Json_len=$#json_array;
		# print "Json_len :: $Json_len \n";
		if($Var_len<=0 or $Json_len<0)
		{
			@json_array=();
			push(@json_array,$price_url);
		}
		# print "json_array1 :: @json_array \n";
		while ( $price_content2 =~m/setArrayInfoTabInfoBlocks\(([\w\W]*?)\)/igs )
		{
			my $description_content = $1;
			if($description_content=~m/\,\^0\^\,\^([^<]*?)$/is)
			{
				$description .= &DBIL::Trim($1);
				$description=decode_entities($description);
				$description=~s/\^\,\^false\|\|\d+\^\,\^\d+\^\,\^/ /igs;
				$description=~s/\^\,\^true\|\|\d+\^\,\^\d+\^\,\^/ /igs;
				$description=~s/\^\,\^false\"/ /igs;
				$description=~s/\^\,\^true\"/ /igs;
				$description=~s/\^\,\^false\'\'/ /igs;
				$description=~s/\^\,\^true\'\'/ /igs;
				$description=&DBIL::Trim($description);
			}
		}
		if ( $price_content2 =~ m/objP.arrayFabricContent\,\"[^\"]+?(\^\,\^[\w\W]*?)\)/is )
		{
			$prod_detail = $1;
			$prod_detail=decode_entities($prod_detail);
			$prod_detail=~s/\|\|\d+/% /igs;
			$prod_detail=~s/\^\,\^/ /igs;
			$prod_detail=~s/\"\s*$/%/igs;
			$prod_detail=&DBIL::Trim($prod_detail);
		}
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my %hash_image;
		if ( $content2 =~ m/<h1[^>]*?>\s*([\w\W]*?)\s*<\/h1>/is )
		{
			$product_name = &DBIL::Trim($1);
		}
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		foreach my $json(@json_array)
		{
			my $price_content2 = get_content($json);
			# open sr, ">play.html";
			# print sr $price_content2;
			# print  $content;
			# close sr;
			# exit;
			# $json=~s/\&vid\=[^<]*?$//igs;
			# $json=~s/productdata/product/igs;
			$price_content2=~s/\s*\&\#189\;/.5/igs;
			my ($price,$price_text,$sub_category,$product_id,$main_image,$alt_image,$out_of_stock,$color);
			
			#Size & Out_of_stoc
			if ( $price_content2 =~ m/\.SizeInfoSummary\(([\w\W]*?)\);/is )
			{
				my $size_info = $1;
				
				if($size_info=~m/short|regular|long/is)
				{
					my (@inseam_id,@inseam_value,@size_value,@size_id,%inseam_hash,%size_hash,$zise_value,$inseamvalue);
					#print "size_info :: $size_info\n";
					if($size_info=~m/^\s*[^<]*?\,[^<]*?\,\"([^>]*?)\"\,/is)
					{
						my $value=$1;
						($zise_value,$inseamvalue)=split(',',$value)
						
					}
					while($size_info=~m/(short[\d\&\#\;\s\(\)]*|regular[\d\&\#\;\s\(\)]*|long[\d\&\#\;\s\(\s]*|short|regular|long)\^\,\^(\w+)(?:\||\")/igs)
					{
						my $inseam_value=$1;
						my $inseam_id=$2;
						decode_entities($inseam_value);
						$inseam_hash{$inseam_id}=$inseam_value;
						push(@inseam_id,$inseam_id);
						push(@inseam_value,$inseam_value);
						# print "inseam_value :: @inseam_value \n";
					}
					while ($size_info =~ m/([\w\&\#\;\. ]+)\^\,\^([\w\&\#\; \.]+)(?:\||\")/igs )
					{
						my $size 		= &DBIL::Trim($1);
						my $size_id 	= &DBIL::Trim($2);
						# print "size :: $size \n";
						# $size=~s/\s*&#189\;/.5/igs;
						# $size_id=~s/\s*&#189\;/.5/igs;
						push(@size_value,$size) unless($size=~m/short|regular|long/is);
						push(@size_id,$size_id) unless($size=~m/short|regular|long/is);
						$size_hash{$size_id}=$size unless($size=~m/short|regular|long/is);
					}
					my %AllColor;
					while($price_content2=~m/objP\.StyleColor\(([\w\W]*?)\)[^<]*?\.styleColorImagesMap\s*\=\s*\{([\w\W]*?)\}/igs)
					{
						my $single_color_content=$1.$2;
						my ($old_price,$new_price,$price_text,$color,@image_obj_keys,@sku_obj_keys,$tcolor);
						if($single_color_content=~m/^\"[^\"]+\"\,\"([^\"]+)\"/is)
						{
							$color=&DBIL::Trim($1);
							if($AllColor{$color}++>=1)
							{
								$tcolor = $color.' ('.$AllColor{$color}.')';
								
							}
							else
							{
								$tcolor =$color;
							}
							
							#print "$tcolor\n";
						}
						if($single_color_content=~m/\"\s*(\$[^\"]+?)\"\,*\"*(\$*[\d\,\. ]+?)\"|\"\s*(\$[^\"]+?)\"\,*\"*(\$*[\d\,\. ]*?)\"*/is)
						{
							$old_price=$1.$3;
							$new_price=$2.$4;
							$price_text=$old_price.' '.$new_price;
							$new_price=$old_price if($new_price=~m/^\s*$/is);
							$new_price=~s/\$//is;
							$price_text=&DBIL::Trim($price_text);
						}
						foreach my $size_id(@size_id)
						{
							foreach my $inseam_id(@inseam_id)
							{
								my $regex='\^'.$size_id.'\^\,\^'.$inseam_id.'\^';
								my $size_inseam;
								if($regulartall_type{$json}=~m/tall|petite/is)
								{
									$size_inseam=$zise_value.': '.$size_hash{$size_id}.' '.$regulartall_type{$json}.', '.$inseamvalue.': '.$inseam_hash{$inseam_id};
								}
								else
								{
									$size_inseam=$zise_value.': '.$size_hash{$size_id}.', '.$inseamvalue.': '.$inseam_hash{$inseam_id};
								}
								if($single_color_content=~m/$regex/is)
								{
									$out_of_stock='n';
									my ($sku_object,$flag,$query);
									($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price_hash{$color},$price_text_hash{$color},$size_inseam,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid) if($price_text_hash{$color}=~m/now/is);
									($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$new_price,$price_text,$size_inseam,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid)unless($price_text_hash{$color}=~m/now/is);
									push(@sku_obj_keys,$sku_object);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$tcolor;
									push(@query_string,$query);
								}
								else
								{
									$out_of_stock='y';
									my ($sku_object,$flag,$query);
									($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price_hash{$color},$price_text_hash{$color},$size_inseam,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid) if($price_text_hash{$color}=~m/now/is);
									($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$new_price,$price_text,$size_inseam,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid)unless($price_text_hash{$color}=~m/now/is);
									push(@sku_obj_keys,$sku_object);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$tcolor;
									push(@query_string,$query);
								}
							}
						}
						if($single_color_content =~ m/\'(?:z)\'\:\s*\'([^>]*?)\'/is)
						{
							my $image = $1;
							$image="http://www1.assets-gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# next if($hash_image{$image}++ >= 1);
							# if($image eq $defaultImg)
							# {
								# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$image."\"".","."\"".''."\"".","."\"".'product'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\""."\n";
								
								my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag =1 if($flag);
								$hash_default_image{$img_object}='y';
								push(@image_obj_keys,$img_object);
								push(@query_string,$query);
							# }
						}
						elsif($single_color_content =~ m/\'(?:vli)\'\:\s*\'([^>]*?)\'/is)
						{
							my $image = $1;
							$image="http://www1.assets-gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# next if($hash_image{$image}++ >= 1);
							# if($image eq $defaultImg)
							# {
								# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$image."\"".","."\"".''."\"".","."\"".'product'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\""."\n";
								
								my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag =1 if($flag);
								$hash_default_image{$img_object}='y';
								push(@image_obj_keys,$img_object);
								push(@query_string,$query);
							# }
						}
						while($single_color_content =~ m/\'(?:AV\d+_VLI)\'\:\s*\'([^>]*?)\'/igs)
						{
							my $image = $1;
							$image="http://www1.assets-gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# next if($hash_image{$image}++ >= 1);
							# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$image."\"".","."\"".''."\"".","."\"".'product'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'n'."\""."\n";
							my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag =1 if($flag);
							$hash_default_image{$img_object}='n';
							push(@image_obj_keys,$img_object);
							push(@query_string,$query);
						}
						while($single_color_content =~ m/\'S\'\:\s*[\"|\']([^\']*?)[\"|\']/igs)
						{
							my $swatch = $1;
							$swatch="http://www1.assets-gap.com".$swatch unless($swatch=~m/^http/is);
							my $res2;
							# next if($hash_image{$swatch}++ >=1);
							# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$swatch."\"".","."\"".''."\"".","."\"".'swatch'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'n'."\""."\n";
							my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch','bananarepublic-us');
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag =1 if($flag);
							$hash_default_image{$img_object}='n';
							push(@image_obj_keys,$img_object);
							push(@query_string,$query);
							# open FH , ">>$Imagefile" or die "File not found\n";
							# print FH $res2;
							# close FH;
						}
						foreach my $img_obj_key(@image_obj_keys)
						{
							foreach my $sku_obj_key(@sku_obj_keys)
							{
								# if($image_objectkey{$img_obj_key} eq $sku_objectkey{$sku_obj_key})
								# {
									my $query=&DBIL::SaveSkuhasImage($sku_obj_key,$img_obj_key,$hash_default_image{$img_obj_key},$product_object_key,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									push(@query_string,$query);
								# }
							}
						}
					}
				}
				elsif($size_info=~m/Waist/is)
				{
					my (@inseam_id,@inseam_value,@size_value,@size_id,%inseam_hash,%size_hash);
					while($size_info=~m/([\w\&\#\;\. ]+L)\^\,\^([\w\&\#\; \.]+)(?:\||\")/igs)
					{
						my $inseam_value=$1;
						my $inseam_id=$2;
						$inseam_hash{$inseam_id}=$inseam_value;
						push(@inseam_id,$inseam_id);
						push(@inseam_value,$inseam_value);
					}
					while ($size_info =~ m/([\w\&\#\;\. ]+)\^\,\^([\w\&\#\; \.]+)(?:\||\")/igs )
					{
						my $size 		= &DBIL::Trim($1);
						my $size_id 	= &DBIL::Trim($2);
						# print "size :: $size \n";
						# $size=~s/\s*&#189\;/.5/igs;
						# $size_id=~s/\s*&#189\;/.5/igs;
						push(@size_value,$size) unless($size=~m/L/is);
						push(@size_id,$size_id) unless($size=~m/L/is);
						$size_hash{$size_id}=$size unless($size=~m/L/is);
					}
					my %AllColor;
					while($price_content2=~m/objP\.StyleColor\(([\w\W]*?)\)[^<]*?\.styleColorImagesMap\s*\=\s*\{([\w\W]*?)\}/igs)
					{
						my $single_color_content=$1.$2;
						my ($old_price,$new_price,$price_text,$color,@image_obj_keys,@sku_obj_keys,$tcolor);
						if($single_color_content=~m/^\"[^\"]+\"\,\"([^\"]+)\"/is)
						{
							$color=&DBIL::Trim($1);
							if($AllColor{$color}++>=1)
							{
								$tcolor = $color.' ('.$AllColor{$color}.')';
								
							}
							else
							{
								$tcolor =$color;
							}
							
							#print "$tcolor\n";
						}
						if($single_color_content=~m/\"\s*(\$[^\"]+?)\"\,*\"*(\$*[\d\,\. ]+?)\"|\"\s*(\$[^\"]+?)\"\,*\"*(\$*[\d\,\. ]*?)\"*/is)
						{
							$old_price=$1.$3;
							$new_price=$2.$4;
							$price_text=$old_price.' '.$new_price;
							$new_price=$old_price if($new_price=~m/^\s*$/is);
							$new_price=~s/\$//is;
							$price_text=&DBIL::Trim($price_text);
						}
						foreach my $size_id(@size_id)
						{
							foreach my $inseam_id(@inseam_id)
							{
								my $regex='\^'.$size_id.'\^\,\^'.$inseam_id.'\^';
								my $size_inseam;
								# print "$regulartall_type{$json}\n";
								if($regulartall_type{$json}=~m/tall|petite/is)
								{
									$size_inseam='Waist: '.$size_hash{$size_id}.' '.$regulartall_type{$json}.', Length: '.$inseam_hash{$inseam_id};
								}
								else
								{
									$size_inseam='Waist: '.$size_hash{$size_id}.', Length: '.$inseam_hash{$inseam_id};
								}
								if($single_color_content=~m/$regex/is)
								{
									# my $res3 = "\"".$product_id."\"".","."\"".$prod_objkey{$url3}."\"".","."\"".$url3."\"".","."\"".$product_name."\"".","."\"".$new_price."\"".","."\"".$price_text."\"".","."\"".$size_inseam."\"".","."\"".$color."\"".","."\"".'n'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Detail\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\""."\n";
									my $out_of_stock='n';
									my ($sku_object,$flag,$query);
									($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price_hash{$color},$price_text_hash{$color},$size_inseam,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid) if($price_text_hash{$color}=~m/now/is);
									# print "sku_object :: - $sku_object -\n";
									($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$new_price,$price_text,$size_inseam,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid)unless($price_text_hash{$color}=~m/now/is);
									$skuflag = 1 if($flag);
									push(@sku_obj_keys,$sku_object);
									push(@query_string,$query);
									# open FH , ">>$Skufile" or die "File not found\n";
									# print FH $res3;
									# close FH;
								}
								else
								{
									# my $res3 = "\"".$product_id."\"".","."\"".$prod_objkey{$url3}."\"".","."\"".$url3."\"".","."\"".$product_name."\"".","."\"".$new_price."\"".","."\"".$price_text."\"".","."\"".$size_inseam."\"".","."\"".$color."\"".","."\"".'y'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Detail\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\""."\n";
									# open FH , ">>$Skufile" or die "File not found\n";
									# print FH $res3;
									# close FH;
									my $out_of_stock='y';
									my ($sku_object,$flag,$query) ;
									($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price_hash{$color},$price_text_hash{$color},$size_inseam,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid) if($price_text_hash{$color}=~m/now/is);
									# print "sku_object :: - $sku_object -\n";
									($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$new_price,$price_text,$size_inseam,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid)unless($price_text_hash{$color}=~m/now/is);
									$skuflag = 1 if($flag);
									# print "sku_object :: - $sku_object -\n";
									push(@sku_obj_keys,$sku_object);
									push(@query_string,$query);
								}
							}
						}
						if($single_color_content =~ m/\'(?:z)\'\:\s*\'([^>]*?)\'/is)
						{
							my $image = $1;
							$image="http://www1.assets-gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# next if($hash_image{$image}++ >= 1);
							# if($image eq $defaultImg)
							# {
								# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$image."\"".","."\"".''."\"".","."\"".'product'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\""."\n";
								my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag =1 if($flag);
								$hash_default_image{$img_object}='y';
								# print "img_object :: -$img_object-\n";
								push(@image_obj_keys,$img_object);
								push(@query_string,$query);
							# }
						}
						elsif($single_color_content =~ m/\'(?:vli)\'\:\s*\'([^>]*?)\'/is)
						{
							my $image = $1;
							$image="http://bananarepublic.gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# next if($hash_image{$image}++ >= 1);
							# if($image eq $defaultImg)
							# {
								# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$image."\"".","."\"".''."\"".","."\"".'product'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\""."\n";
								my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag =1 if($flag);
								$hash_default_image{$img_object}='y';
								push(@image_obj_keys,$img_object);
								push(@query_string,$query);
							# }
						}
						while($single_color_content =~ m/\'(?:AV\d+_VLI)\'\:\s*\'([^>]*?)\'/igs)
						{
							my $image = $1;
							$image="http://www1.assets-gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# next if($hash_image{$image}++ >= 1);
							# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$image."\"".","."\"".''."\"".","."\"".'product'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'n'."\""."\n";
							my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag =1 if($flag);
							$hash_default_image{$img_object}='n';
							# print "img_object :: -$img_object-\n";
							push(@image_obj_keys,$img_object);
							push(@query_string,$query);
						}
						while($single_color_content =~ m/\'S\'\:\s*[\"|\']([^\']*?)[\"|\']/igs)
						{
							my $swatch = $1;
							$swatch="http://www1.assets-gap.com".$swatch unless($swatch=~m/^http/is);
							
							my $res2;
							# next if($hash_image{$swatch}++ >=1);
							# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$swatch."\"".","."\"".''."\"".","."\"".'swatch'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'n'."\""."\n";
							my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch','bananarepublic-us');
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag =1 if($flag);
							$hash_default_image{$img_object}='n';
							# print "img_object :: -$img_object-\n";
							push(@image_obj_keys,$img_object);
							push(@query_string,$query);
						}
						# print "image_obj_keys :: $#image_obj_keys\n";
						# print "sku_obj_keys :: $#sku_obj_keys\n";
						foreach my $img_obj_key(@image_obj_keys)
						{
							foreach my $sku_obj_key(@sku_obj_keys)
							{
								# if($image_objectkey{$img_obj_key} eq $sku_objectkey{$sku_obj_key})
								# {
									# print "SaveSkuhasImage :: -$sku_obj_key-:: -$img_obj_key- \n";
									my $query=&DBIL::SaveSkuhasImage($sku_obj_key,$img_obj_key,$hash_default_image{$img_obj_key},$product_object_key,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									push(@query_string,$query);
								# }
							}
						}
					}
				}
				else
				{
					my (@size_value,@size_id,%size_hash);
					while ($size_info =~ m/([\w\&\#\;\. ]+)\^\,\^([\w\&\#\; \.]+)(?:\||\")/igs )
					{
						my $size 		= &DBIL::Trim($1);
						my $size_id 	= &DBIL::Trim($2);
						push(@size_value,$size);
						push(@size_id,$size_id);
						$size_hash{$size_id}=$size;
					}
					my %AllColor;
					while($price_content2=~m/objP\.StyleColor\(([\w\W]*?)\)[^<]*?\.styleColorImagesMap\s*\=\s*\{([\w\W]*?)\}/igs)
					{
						my $single_color_content=$1.$2;
						my ($old_price,$new_price,$price_text,$color,@image_obj_keys,@sku_obj_keys,$tcolor);
						if($single_color_content=~m/^\"[^\"]+\"\,\"([^\"]+)\"/is)
						{
							$color=&DBIL::Trim($1);
							if($AllColor{$color}++>=1)
							{
								$tcolor = $color.' ('.$AllColor{$color}.')';
								
							}
							else
							{
								$tcolor =$color;
							}
							
							#print "$tcolor\n";
						}
						if($single_color_content=~m/\"\s*(\$[^\"]+?)\"\,*\"*(\$*[\d\,\. ]+?)\"|\"\s*(\$[^\"]+?)\"\,*\"*(\$*[\d\,\. ]*?)\"*/is)
						{
							$old_price=$1.$3;
							$new_price=$2.$4;
							$price_text=$old_price.' '.$new_price;
							$new_price=$old_price if($new_price=~m/^\s*$/is);
							$new_price=~s/\$//is;
							$price_text=&DBIL::Trim($price_text);
						}
						foreach my $size_id(@size_id)
						{
							my $regex='\^'.$size_id.'\^\,\^';
							if($single_color_content=~m/$regex/is)
							{
								my $out_of_stock='n';
								my ($sku_object,$flag,$query,$size);
								$size=$size_hash{$size_id} if($regulartall_type{$json}=~m/regular|^\s*$/is);
								$size=$size_hash{$size_id}.' '.$regulartall_type{$json} if($regulartall_type{$json}=~m/tall|petite/is);
								
								($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price_hash{$color},$price_text_hash{$color},$size,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid) if($price_text_hash{$color}=~m/now/is);
								($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$new_price,$price_text,$size,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid)unless($price_text_hash{$color}=~m/now/is);
								push(@sku_obj_keys,$sku_object);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$tcolor;
								push(@query_string,$query);
							}
							else
							{
								my $out_of_stock='y';
								my ($sku_object,$flag,$query,$size);
								$size=$size_hash{$size_id} if($regulartall_type{$json}=~m/regular|^\s*$/is);
								$size=$size_hash{$size_id}.' '.$regulartall_type{$json} if($regulartall_type{$json}=~m/tall|petite/is);
								
								($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price_hash{$color},$price_text_hash{$color},$size,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid) if($price_text_hash{$color}=~m/now/is);
								($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$new_price,$price_text,$size,$tcolor,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid)unless($price_text_hash{$color}=~m/now/is);
								push(@sku_obj_keys,$sku_object);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$tcolor;
								push(@query_string,$query);
							}
						}
						if($single_color_content =~ m/\'(?:z)\'\:\s*\'([^>]*?)\'/is)
						{
							my $image = $1;
							$image="http://www1.assets-gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# print "image :: $image \n";
							# next if($hash_image{$image}++ >= 1);
							my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag =1 if($flag);
							push(@image_obj_keys,$img_object);
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						elsif($single_color_content =~ m/\'(?:vli)\'\:\s*\'([^>]*?)\'/is)
						{
							my $image = $1;
							$image="http://www1.assets-gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# next if($hash_image{$image}++ >= 1);
							# if($image eq $defaultImg)
							# {
								# $res2 = "\"".$product_id."\"".","."\"".&generate_random_string()."\"".","."\"".$image."\"".","."\"".''."\"".","."\"".'product'."\"".","."\"".&generate_random_string()."\"".","."\"bananarepublic-us--Details\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\""."\n";
								my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag =1 if($flag);
								$hash_default_image{$img_object}='y';
								push(@image_obj_keys,$img_object);
								push(@query_string,$query);
							# }
						}
						while($single_color_content =~ m/\'(?:AV\d+_VLI)\'\:\s*\'([^>]*?)\'/igs)
						{
							my $image = $1;
							$image="http://www1.assets-gap.com".$image unless($image=~m/^http/is);
							my $res2;
							# next if($hash_image{$image}++ >= 1);
							
							my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','bananarepublic-us');
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag =1 if($flag);
							push(@image_obj_keys,$img_object);
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
						while($single_color_content =~ m/\'S\'\:\s*[\"|\']([^\']*?)[\"|\']/igs)
						{
							my $swatch = $1;
							$swatch="http://www1.assets-gap.com".$swatch unless($swatch=~m/^http/is);
							my $res2;
							# next if($hash_image{$swatch}++ >=1);
							
							my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch','bananarepublic-us');
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);	
							$hash_default_image{$img_object}='n';
							$imageflag =1 if($flag);
							push(@image_obj_keys,$img_object);
							push(@query_string,$query);
						}
						# print "image_obj_keys :: $#image_obj_keys\n";
						# print "sku_obj_keys :: $#sku_obj_keys\n";
						foreach my $img_obj_key(@image_obj_keys)
						{
							foreach my $sku_obj_key(@sku_obj_keys)
							{
								# if($image_objectkey{$img_obj_key} eq $sku_objectkey{$sku_obj_key})
								# {
									my $query=&DBIL::SaveSkuhasImage($sku_obj_key,$img_obj_key,$hash_default_image{$img_obj_key},$product_object_key,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									push(@query_string,$query);
								# }
							}
						}
					}
				}
				
			}
		}
		PNF:
		my($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		$dbh->commit();
	}
}1;

sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	$url =~ s/amp\;//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
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
			sleep(2);
			goto Home;
		}
	}
	return $content;
}