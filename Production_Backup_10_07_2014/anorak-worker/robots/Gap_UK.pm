#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Gap_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use Encode qw(decode encode);
use HTTP::Cookies;
use String::Random;
use URI::Escape;
use DBI;
use DateTime;

# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Gap_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Gap-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Guk';
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
	my $mflag = 0;
	my @query_str;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		my $product_id1;
		if($url3=~m/pid\s*\=([^>]*?)\s*$/is)
		{
			$product_id1=$1;
			
		}
		my $super_url0="http://www.gap.co.uk/browse/productData.do?pid=$product_id1&vid=1&scid=&actFltr=false&locale=en_GB&internationalShippingCurrencyCode=&internationalShippingCountryCode=gb&globalShippingCountryCode=gb";
			
		my $content1 = get_content($super_url0);
		if($content1!~m/\(objP\.arrayVariantStyles([^>]*?)\)/is)
		{
				my ($product_name,$brand,$prod_detail,$description,$product_id,@query_string);
				my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$prod_detail,$description,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
				push(@query_string,$query1);
				push(@query_string,$query2);
				# push(@query_string,$query);
				&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
				goto end;
		}
		
		my $product_id;
		if($content1=~m/strProductId\s*\=\s*\"(?<productID>[^>]*?)\"/is)
		{
			$product_id=$1;
			
		}
		my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname, $retailer_id);
		goto end if($ckproduct_id == 1);
		undef ($ckproduct_id);


	
		my ($b,$counter,$new_size,$type_avail,$tid);
		my (@size_type,@type_id);
		
		if($content1=~m/\(objP\.arrayVariantStyles([^>]*?)\)/is)
		{
			$b=$1;
			while($b=~m/\^(\d+)\^\,\^([a-z]+)\^/igs)
			{
				push(@size_type,$2);
				push(@type_id,$1);
			}
		}
		my $counter=@size_type;
		print "\n$counter\n";
		$tid=0;
		my $count=0;
		foreach my $type_id(@type_id)
		{
		#	my $type_id=2;
			my @query_string;
			my $super_url="http://www.gap.co.uk/browse/productData.do?pid=$product_id1&vid=".$type_id."&scid=&actFltr=false&locale=en_GB&internationalShippingCurrencyCode=&internationalShippingCountryCode=gb&globalShippingCountryCode=gb";
			
			my $content2 = get_content($super_url);
			my $new_size=$size_type[$tid];
			if($counter==1)
			{
				$new_size="";
			}
			$tid++;
			my %tag_hash;
			my %color_hash;
			my %prod_objkey;
			my %size_hash;
			my (@arey,@areye,@suresh);
			my ($price,$brand,$sub_category,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$select_var,$i,$size,$color,$j,$product_id);
			
			#product_id
			if($content2=~m/strProductId\s*\=\s*\"(?<productID>[^>]*?)\"/is)
			{
				$product_id=$1;
				
			}
			#product_name
			my $pn;
			if ($content2 =~ m/99\s*\,5\s*\,\s*\"(?<productname>[^>]*?)\"|\s*\,5\s*\,\s*\"(?<productname>[^>]*?)\"|\d+\,\"(?<productname>[^>]*?)\"\,\'Color\'/is)
			#if ($content2 =~ m/\d+\,\"([^>]*?)\"\,\'Color\'/is)
			{
				$product_name = $1;
				$product_name=decode_entities( $product_name);
				$pn=$product_name;
				if(utf8::is_utf8($product_name))
				{
					# print "product_name is utf8\n";
				}        
				else
				{
					eval
					{
						$product_name = decode_utf8($product_name, Encode::FB_CROAK)
					};
				}
				$product_name=~s/\\u00E9/\é/igs;
					
			}
			if($product_name eq "")
			{
				$product_name=$pn;
			}
			#description&details
			my($des1,$des2,$des3,$des4,$descriptiblock,$descriptionblock2);
			if($content2=~m/\'Color\s*([\w\W]*?)\s*\)/is)
			{
				$des1=$1;
				$des1=~s/false//igs;
				$des1=~s/true//igs;
				$des1=~s/\"M\"//igs;
				$des1=~s/\"N\"//igs;
				$des1=~s/NA//igs;
				$des1=~s/\"S[\d]\"//igs;
				$des1=~s/\"A[\d]\"//igs;
				$des1=~s/\"C[\d]\"//igs;
				$des1=~s/\"//igs;
				$des1=~s/0//igs;
				$des1=~s/1//igs;
				$des1=~s/C2//igs;
				$des1=~s/C1//igs;
				$des1=~s/H1//igs;
				$des1=~s/2//igs;		
				$des1=~s/\^//igs;
				$des1=~s/\)//igs;		
				$des1=~s/\|\|//igs;		
				$des1=~s/\,//igs;
				$des1=~s/^\'//igs;
				$des1=~s/Multi//igs;
				$des1=~s/C$//igs;
				$des1=~s/\&\#39\;/'/igs;
				$des1=~s/S5//igs;
				$des1=~s/MMachine/Machine/igs;
				$des1=~s/\s+/ /igs;
				
			}
			if($content2=~m/FabricContent\,\"[^>]*?\^\,([\w\W]*?)\)\;/is)
			{
				$descriptiblock=$1;
				while ($descriptiblock=~m/\^([\w\(\)(\®)(\-)\s]+\^\,\^[^>]*?)[:?|\,|\"|\)|\']/igs)
				{
				$des2=$des2.",".$1;
				$des2=~s/\^\,\^/ /igs;
				$des2=~s/\s*$/\%/igs;
				$des2=~s/^\,//igs;
				$des2=~s/\&\#39\;/'/igs;
				}
			}
			$des3="$des1"." "."$des2";
			$des3=~s/\s+/ /igs;
			while($content2=~m/setArrayInfoTabInfoBlocks\(objP\.arrayInfoTabs\[[^>]*?\]\s*([\w\W]*?)\s*\)\;/igs)
			{
				my $descriptionblock2=$1;
				while ($descriptionblock2=~m/\^[\d]\^\,\^([^\^]*?)\^/igs)
				{
				$des4=$des4.' '.$1;
				$des4=~s/\&\#39\;/'/igs;
				$des4=~s/\&\#34\;/"/igs;
				}
			}
			$des4="Overview:"." "."$des4";
			$des4=~s/\s+/ /igs;
			$prod_detail=trim($des4);
			$description=trim($des3);
			$description=decode_entities($description);
				if(utf8::is_utf8($description))
				{
					#print "description is utf8\n";
				}        
				else
				{
					eval
					{
						$description = decode_utf8($description, Encode::FB_CROAK)
					};
				}
				$description=~s/u00E9/\é/igs;
				$prod_detail=decode_entities($prod_detail);
				if(utf8::is_utf8($prod_detail))
				{
					# print "prod_detail is utf8\n";
				}        
				else
				{
					eval
					{
						$prod_detail = decode_utf8($prod_detail, Encode::FB_CROAK)
					};
				}	
				$prod_detail=~s/u00E9/\é/igs;
				$prod_detail=~s/\\//igs;
			#colour & pricetext & price
			my @type;
			my @code;
			my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
			if($content2=~m/SizeInfoSummary\s*\(\s*([\w\W]*?)\s*\)\;/is)
				{
					my $cong23=$1;
					my $spec_type2;
					while($cong23=~m/[:?Size]?[^>]*(?:\,\"([^>]*?)\"\,\"([^>]*?)\",\")[\d]\"\,\"[^>]*?\"\,\"([^>]*?)\"\,\"/igs)
					{
						my $spec_type1=$1;
						$spec_type2=$2;
						my $cong231=$3;
						if($spec_type2 eq "")
						{
							if($spec_type1=~m/^size$/is)
							{
								$spec_type1="";
							}	
						}
						# print "blcok size $cong231\n";
						while($cong231=~m/([\w\(\)(\/)(\-)\s]+)\^\,\^([\d]+)/igs)
						{
							my $var234="$spec_type1:".$1;
							my $var2336=$2;
							$var234=~s/^\://is;
							push(@arey,$var234);
							push(@areye,$var2336);	
						}
					}	
					if($cong23=~m/\|\|[^>]*?\"\,\"([^>]*?)\"\,false/is)
					{
						my $cong232=$1;
						while ($cong232=~m/([\w\(\)(\/)(\-)\s]+)\^\,\^([\d]+)/igs)
						{
							my $type1="$spec_type2:".$1;
							my $code1=$2;
							$type1=~s/^\://is;
							push(@type,$type1);
							push(@code,$code1);
						}
					}
				}	
				# print"\nTotl value in areye-->@areye\n";
				my ($price_text,$price_textblock);
				my @col;
				my %hash_color;
				my $inc=2;
				while($content2=~m/(objP\.StyleColor\s*[\w\W]*?\s*\)\;)/igs)
				{
					my $cont3554=$1;
					if($cont3554=~m/Color\("\s*[^>]*?\s*","\s*([^>]*?)\s*"[\w\W]*?(Â?[^>]*?undefined)/is)
					{
						$color=$1;
						$price_textblock=$2;
						if($hash_color{$color} eq '')
    						{
						     $hash_color{$color}=$color;
						}
						else
						{
						     $color=$color.' ('.$inc.')';
						     $inc++;
						}
						# &DBIL::SaveTag('Color',lc($color),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
						push(@col,$color);
						if ($price_textblock=~m/Â?(£[^>]*?)\",undefined/is)
						{
							$price_text=$1;
							$price_text=~s/\"\,\"\Â/ /igs;
							$price_text=~s/\£/\Â\£/igs;
							if($price_text=~m/£[\d]+[:?\.]?[\d]+[^>]*?£([\d]+(:?\.)?[\d]+)/is)
							{
								$price=$1;
							}
							elsif($price_text=~m/£([\d]+[:?\.]?[\d]+)\s*/is)
							{
								$price=$1;
							}
						}
					}
					my @total_value;
					my ($temp,$compare_value,$temp1,$temp2,$temp3,$temp4,$str_val);
						foreach $temp(@code)
						{
							foreach $temp1(@areye)
							{
								$compare_value=$temp1."-".$temp;
								push(@total_value,$compare_value);
							}
						}
						$str_val=join("",@total_value);
						
						my @total_size;
						foreach $temp4(@type)
						{
							foreach $temp3(@arey)
							{
								$compare_value=$temp3.",".$temp4;
								$compare_value=~s/^\,//is;
								$compare_value=~s/\,$//is;
								push(@total_size,$compare_value);
							}
						}
						$str_val=join("",@total_size);
						
						my $numberrrrrrrr;
						if($cont3554=~m/\^([\d]{3,7})\^\,\^([\d]{3,7})\^/is)
						{
							my (@available_size,@available_type);
							while($cont3554=~m/\^([\d]{3,7}\^\,\^[\d]{3,7})\^/igs)
							{
								my $available_sizewittype=$1;
								$available_sizewittype=~s/\^\,\^/-/igs;
								push(@available_size,$available_sizewittype);
								
							}
							
							for($i=0;$i<=$#total_value;$i++)
								{
									$size=$total_size[$i];
									my $number2354=$total_value[$i];
									my $out_of_stock;
									my $fla;
									for($j=0;$j<=$#available_size;$j++)
									{
										if($total_value[$i] eq $available_size[$j] )
										{
											$fla=1;
											goto LAST;
										}
										else
										{
											$fla=0;
											
										}	
													
									}
									LAST:
									if($fla eq '1')
									{
										$out_of_stock='n';
									}
									else
									{
									$out_of_stock='y';
									}
									$size="$new_size".','."$size";
									$size=~s/^\,//igs;	
									$size=~s/\,$//igs;
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color;
									push(@query_string,$query);
								}
							undef @available_size;
						}
						else
						{
							while($cont3554=~m/\^([\d]{3,7})\^/igs)
							{
								$numberrrrrrrr=trim($1);
								push(@suresh,$numberrrrrrrr);
									
							}
								for($i=0;$i<=$#areye;$i++)
								{
									$size=$arey[$i];	
									my $number2354=$areye[$i];
									my $out_of_stock;
									my $fla;
									for($j=0;$j<=$#suresh;$j++)
									{
										if($areye[$i] == $suresh[$j] )
										{
											$fla=1;
											goto LAST1;
										}
										else
										{
											$fla=0;
											
										}	
													
									}
									LAST1:
									if($fla eq '1')
									{
										$out_of_stock='n';
									}
									else
									{
									$out_of_stock='y';
									}
									$size="$new_size".','."$size";
									$size=~s/^\,//igs;
									$size=~s/\,$//igs;
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color;
									push(@query_string,$query);
								}
						}
								undef @suresh;
								undef $out_of_stock;
								# undef $fla;
									
				}
				
				#Swatch_image
				my $i=0;
				while ($content2=~m/Swatch\^\,\^([^>]*?)\|/igs)
				{
					my $swatch = trim($1);
					unless($swatch=~m/^http/is)
					{
						$swatch="http://www1.assets-gap.com".$swatch;
					}
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch','gap-uk');
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$col[$i];
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
					$i++;
				}
				
				##product_image
				my $i=0;
				while($content2=~m/\'VLI\s*\'\s*:\s*\'([^>]*?)\'/igs)
				{
					my $product_image1=$1;
					unless($product_image1=~m/^http/is)
					{
						$product_image1="http://www1.assets-gap.com".$product_image1;
					}
					my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product','gap-uk');
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$col[$i];
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
					$i++;
				}
				my $i=0;
				while($content2=~m/\'AV[\d]_VLI\s*\'\s*:\s*\'([^>]*?)\'/igs)
				{
					my $product_image2=$1;
					unless($product_image2=~m/^http/is)
					{
						$product_image2="http://www1.assets-gap.com".$product_image2;
					}
					my ($imgid,$img_file) = &DBIL::ImageDownload($product_image2,'product','gap-uk');
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image2,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$col[$i];
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
					$i++;
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
				if($count==0)
				{
					my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$prod_detail,$description,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
					# push(@query_string,$query);
					push(@query_string,$query1);
					push(@query_string,$query2);
				}	
					&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
					$dbh->commit();
					$count++;
			}
		end:
			# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
			# push(@query_str,$qry);
			# &DBIL::ExecuteQueryString(\@query_str,$robotname,$dbh);
			print "";
			$dbh->commit();
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
			sleep(10);
			goto Home;
		}
	}
	return $content;
}

sub trim
{
	my $txt = shift;
	
	$txt =~ s/\<[^>]*?\>//igs;
	$txt =~ s/\n+/ /igs;
	$txt =~ s/\"/\'\'/g;
	$txt =~ s/^\s+|\s+$//igs;
	$txt =~ s/\s+/ /igs;
	$txt =~ s/\&nbsp\;//igs;
	$txt =~ s/\&amp\;/\&/igs;
	$txt =~ s/\&bull\;/•/igs;
	$txt =~ s/\&quot\;/"/igs;
	$txt =~ s/&frac34;/3\/4/igs;
	$txt =~ s/â„¢/™/igs;
	$txt =~ s/\&eacute\;/é/igs;
	$txt =~ s/Â®/®/igs;
	$txt =~ s/â€™/\'/igs;
	$txt =~ s/Â/®/igs;
	
	return $txt;
}
