#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package JCPenney_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use URI::Escape;
use DBI;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub JCPenney_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='JCPenney-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='JCP';
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
		$url3 =~ s/^\s+|\s+$//g;
		$url3="http://www.jcpenney.com/".$url3 unless($url3=~m/^\s*http\:/is);
		
		my $content2 = get_content($url3);

		goto PNF if( $content2 =~m/The\s*item\s*you\s*want\s*is\s*currently\s*unavailable|<h1>\s*We\s*Apologize\s*<\/h1>/is);
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$select_var,$select_var2);
		#price_text
		if ($content2 =~ m/id\s*\=\s*\"\s*priceDetails\s*\">\s*([\w\W]*?)\s*(?:<\/a>)?\s*<\/span>\s*<\/div>|<span\s*class\=\"price\">([\w\W]*?)<\/div>/is)
		{
			$price_text = $1.$2;
			$price_text =~ s/<[^>]*?>//igs;
			$price_text = trim($price_text);
			$price_text =~ s/\s+/ /igs;
			$price_text =~ s/^\s+|\s+$//igs;
		}
		#price
		if ($content2=~ m/(<span\s*class\s*[^>]*?\s*itemprop\s*\=\s*\"price\s*\">\s*[\w\W]*?\s*(?:<\/a>)?\s*<\/span>\s*<\/div>)|<span\s*class\=\"price\">([\w\W]*?)<\/div>/is)
		{
			$price = trim($1.$2);
			$price =~ s/<[^>]*?>/ /igs;
			$price =~ s/INR|USD//igs;
			#$price =~ s/[a-zA-Z]+//igs;
			$price =~ s/\s+/ /igs;
			$price =~ s/^\s+|\s+$//igs;
			if($price=~m/original\s\$([\d\.\,]+)/is)
			{
				$price = trim($1);
			}
			elsif($price=~m/\$\s*([\d\.\,]+)\s*\-\s*\$\s*([\d\.\,]+)/is)
			{
				$price = trim($1);
			}
			$price =~ s/\$//igs;
			$price =~ s/\,//igs;
		}
		
		#product_name
		if ( $content2 =~ m/<div\s*class\=\"pdp_details\">\s*<h1[^<]*?>([\w\W]*?)<\/h1>/is )
		{
			$product_name = $1;
			$product_name =~ s/\<[^>]*?\>/ /igs;
			$product_name =~ s/^\s+|\s+$//ig;
		}
		if($product_name =~/^([^>]*?)\s*(?:®|™)\s*([^>]*?)$/is)
		{
			$brand=$1;
			#$product_name =trim($2); 
		}
		my $flag;
		$flag=0;
		
		#description&details
		my ($prod_detail,$description);
		
		if ( $content2 =~ m/<div[^<]*?description\">([\w\W]*?)<\/div>/is )
		{
			my $desc_content=$1;
			$description=trim($desc_content);
		}
		if ( $content2 =~ m/<div[^<]*?desc\">[\w\W]*?<\/div>([\w\W]*?)<\/div>/is )
		{
			$prod_detail=$1;
			$prod_detail=trim($prod_detail);
		}

		$description=' ' if($description eq '' and $prod_detail eq '');	
		
		#product_id
		my $product_id1;
		my $mflag=0;
		if($content2=~m/var\sprodId\s*\=\s*\'([^>]*?)\'/is)
		{
			$product_id=trim($1);
			$mflag=1 if($product_id=~m/ens/is);
			$product_id1=$product_id;
			$product_id1=~ s/pp|ens//igs;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id1, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
			goto PNF if($mflag == 1);
			undef ($ckproduct_id);
		}
		
		my @size_colour_array;
		my %size_content_hash;
		if ($content2=~m/<span>\s*select\s*a\s*color\s*\:\s*([\w\W]*?)\s*<script\s*type\s*\=\s*\"text\/javascript\s*\">/is)
		{
			my $selection=$1;
			while($selection=~m/<p>\s*([^>]*?)\s*<\/p>/igs)
			{
				my $color = trim($1);
				push(@size_colour_array,$color);
				
			}
		}
		my $count=0;
		my @hash_keys_ref;
		while($content2=~m/<div\s*id\s*\=\s*\"skuOptions\s*\">\s*<span>\s*select\s*(?:an|a)\s*([^>]*?)\s*<\/span>([\w\W]*?)<\/ul>\s*<\/div>/igs)
		{
			my $lot=$1;
			my $size_block=$2;
			$size_content_hash{$lot}=$size_block;
			push(@hash_keys_ref,$lot);
			$count++;
		}
		my @lot_name_array;
		while($content2=~m/<li[^<]*?id\=[^<]*?>\s*<a[^<]*?>([^<]*?)<\/a>\s*<\/li>/igs)
		{
			my $name=$1;
			$name=decode_entities($name);
			$name=uri_escape($name);
			push(@lot_name_array,$name);
		}
		my @hash_keys=keys %size_content_hash;
		my $Sku_flag=0;
		my @colour_array;
		my $img_status=0;
		if($count > 1)
		{
			my (@size_array1,@size_array2);
			foreach my $keys(@hash_keys)
			{
				if(lc($hash_keys_ref[0]) eq lc($keys))
				{
					while($size_content_hash{$keys}=~m/<a[^<]*?>\s*([^<]*?)\s*<\/a>/igs)
					{
						my $size=$1;
						push(@size_array1,$size);
					}
				}
				else
				{
					while($size_content_hash{$keys}=~m/<a[^<]*?>\s*([^<]*?)\s*<\/a>/igs)
					{
						my $size=$1;
						push(@size_array2,$size);
					}
				}
			}
			
			foreach my $lot_name(@lot_name_array)
			{
				foreach my $size(@size_array1)
				{
					my $cup_url='http://www.jcpenney.com/dotcom/jsp/browse/pp/graphical/graphicalLotSKUSelection.jsp?_dyncharset=UTF-8&_dynSessConf=-3859034251972292097&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName='.uc($hash_keys_ref[0]).'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=test&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=regular&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId='.$product_id.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedLotValue='.$lot_name.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedLotValue=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[0]).'='.$size.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[0]).'=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[1]).'=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[1]).'=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=+&_DARGS=%2Fdotcom%2Fjsp%2Fbrowse%2Fpp%2Fgraphical%2FgraphicalLotSKUSelection.jsp';

					my $content90 = get_content($cup_url);
					my @tcolor;
					if($content90=~m/\{\"key\"\:\"COLOR\"\,\"options\"\:\[\{([^<]*?)\}\]/is)
					{
						my $colour_block=$1;
						while($colour_block=~m/\"option\"\:\"([^\"]*?)\"/igs)
						{
							my $tcolour=trim($1);
							push(@tcolor,$tcolour); 
						}
					}
					if($content90=~m/\"option\"\:\"$size\"\,\"availability\"\:\"true\"/is)  
					{
						foreach my $size2 (@size_array2)
						{
							if($content90=~m/\"option\"\:\"$size2\"\,\"availability\"\:\"true\"/is)
							{
								foreach my $color(@tcolor)
								{
									my $temp_name=$lot_name;
									$temp_name=uri_unescape($temp_name);
									$Sku_flag=1;
									my $final_size=ucfirst($hash_keys_ref[0]) .' : '. $size .', LOT : '.$temp_name .', '.ucfirst($hash_keys_ref[1]).' : '.$size2;
									
									$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color;
									push(@query_string,$query);
								}
							}
							else
							{
								foreach my $color(@tcolor)
								{
									my $temp_name=$lot_name;
									$temp_name=uri_unescape($temp_name);
									$Sku_flag=1;
									my $final_size=ucfirst($hash_keys_ref[0]) .' : '. $size .', LOT : '.$temp_name .', '.ucfirst($hash_keys_ref[1]).' : '.$size2;
									$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color;
									push(@query_string,$query);
								}
							}
						}
					}
					else
					{
						foreach my $size2 (@size_array2)
						{
							foreach my $color(@tcolor)
							{
								my $temp_name=$lot_name;
								$temp_name=uri_unescape($temp_name);
								$Sku_flag=1;
								my $final_size=ucfirst($hash_keys_ref[0]) .' : '. $size .', LOT : '.$temp_name .', '.ucfirst($hash_keys_ref[1]).' : '.$size2;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
						}
					}
				}
			}
			if(!@lot_name_array)
			{
				foreach my $size(@size_array1)
				{
					my $cup_url='http://www.jcpenney.com/dotcom/jsp/browse/pp/graphical/graphicalLotSKUSelection.jsp?_dyncharset=UTF-8&_dynSessConf=2995258380841327941&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName='.uc($hash_keys_ref[0]).'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=test&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=regular&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId='.$product_id.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[0]).'='.$size.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[0]).'=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[1]).'=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[1]).'=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=+&_DARGS=%2Fdotcom%2Fjsp%2Fbrowse%2Fpp%2Fgraphical%2FgraphicalLotSKUSelection.jsp';

					my $content90 = get_content($cup_url);
					my @tcolor;
					if($content90=~m/\{\"key\"\:\"COLOR\"\,\"options\"\:\[\{([^<]*?)\}\]/is)
					{
						my $colour_block=$1;
						while($colour_block=~m/\"option\"\:\"([^\"]*?)\"/igs)
						{
							my $tcolour=trim($1);
							push(@tcolor,$tcolour); 
						}
					}
					if($content90=~m/\"option\"\:\"$size\"\,\"availability\"\:\"true\"/is)  
					{
						foreach my $size2 (@size_array2)
						{
							if($content90=~m/\"option\"\:\"$size2\"\,\"availability\"\:\"true\"/is)
							{
								foreach my $color(@tcolor)
								{
									$Sku_flag=1;
									my $final_size=ucfirst($hash_keys_ref[0]) .' : '. $size .' , '.ucfirst($hash_keys_ref[1]).' : '.$size2;
									$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color;
									push(@query_string,$query);
								}
							}
							else
							{
								foreach my $color(@tcolor)
								{
									$Sku_flag=1;
									my $final_size=ucfirst($hash_keys_ref[0]) .' : '. $size .', '.ucfirst($hash_keys_ref[1]).' : '.$size2;
									$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color;
									push(@query_string,$query);
								}
							}
						}
					}
					else
					{
						foreach my $size2 (@size_array2)
						{
							foreach my $color(@tcolor)
							{
								$Sku_flag=1;
								my $final_size=ucfirst($hash_keys_ref[0]) .' : '. $size .', '.ucfirst($hash_keys_ref[1]).' : '.$size2;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
						}
					}
				}
			}
		}
		else
		{
			my (@size_array1,@size_array2);
			foreach my $keys(@hash_keys)
			{
				while($size_content_hash{$keys}=~m/<a[^<]*?>\s*([^<]*?)\s*<\/a>/igs)
				{
					my $size=$1;
					push(@size_array1,$size);
				}
			}
			foreach my $lot_name(@lot_name_array)
			{
				my $cup_url='http://www.jcpenney.com/dotcom/jsp/browse/pp/graphical/graphicalLotSKUSelection.jsp?_dyncharset=UTF-8&_dynSessConf=-3859034251972292097&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName=Lot&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=test&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=regular&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId='.$product_id.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedLotValue='.$lot_name.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedLotValue=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[0]).'=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[0]).'=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=+&_DARGS=%2Fdotcom%2Fjsp%2Fbrowse%2Fpp%2Fgraphical%2FgraphicalLotSKUSelection.jsp';

				my $content90 = get_content($cup_url);
				my (@tcolor,@tsize);
				if($content90=~m/\{\"key\"\:\"COLOR\"\,\"options\"\:\[\{([^<]*?)\}\]/is)
				{
					my $colour_block=$1;
					while($colour_block=~m/\"option\"\:\"([^\"]*?)\"/igs)
					{
						my $tcolour=trim($1);
						push(@tcolor,$tcolour); 
					}
				}
				if($content90=~m/\{\"key\"\:\"SIZE\"\,\"options\"\:\[\{([^<]*?)\}\]/is)
				{
					my $colour_block=$1;
					while($colour_block=~m/\"option\"\:\"([^\"]*?)\"/igs)
					{
						my $tsiz=$1;
						push(@tsize,$tsiz); 
					}
				}
				foreach my $color(@tcolor)
				{
					foreach my $size(@tsize)
					{
						my $temp_name=$lot_name;
						$temp_name=uri_unescape($temp_name);
						$Sku_flag=1;
						my $final_size=ucfirst($hash_keys_ref[0]) .' : '. $size .', LOT : '.$temp_name;
						$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
				}
				if(!@tsize)
				{
					my @tcolor;
					if($content90=~m/\{\"key\"\:\"COLOR\"\,\"options\"\:\[\{([^<]*?)\}\]/is)
					{
						my $colour_block=$1;
						while($colour_block=~m/\"option\"\:\"([^\"]*?)\"/igs)
						{
							my $tcolour=trim($1);
							push(@tcolor,$tcolour); 
						}
					}
					foreach my $color(@tcolor)
					{
						if($content90=~m/option\s*\"\s*\:\s*\"\s*$color\s*\"\s*\,\s*\"\s*availability":"\s*true\s*\"/is)
						{
							$Sku_flag=1;
							my $temp_name=$lot_name;
							$temp_name=uri_unescape($temp_name);
							my $final_size='LOT : '.$temp_name;
							$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
						else
						{
							$Sku_flag=1;
							my $temp_name=$lot_name;
							$temp_name=uri_unescape($temp_name);
							my $final_size='LOT : '.$temp_name;
							$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$final_size,$color,'y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
					}
				}
			}
			if(!@lot_name_array)
			{
				if(@size_array1)
				{
					foreach my $size(@size_array1)
					{
						my $cup_url='http://www.jcpenney.com/dotcom/jsp/browse/pp/graphical/graphicalLotSKUSelection.jsp?_dyncharset=UTF-8&_dynSessConf=-1485980000062785154&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName='.uc($hash_keys_ref[0]).'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=test&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=regular&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId='.$product_id.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[0]).'='.$size.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.'.uc($hash_keys_ref[0]).'=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=+&_DARGS=%2Fdotcom%2Fjsp%2Fbrowse%2Fpp%2Fgraphical%2FgraphicalLotSKUSelection.jsp';
						my $content90 = get_content($cup_url);
						my @tcolor;
						if($content90=~m/\{\"key\"\:\"COLOR\"\,\"options\"\:\[\{([^<]*?)\}\]/is)
						{
							my $colour_block=$1;
							while($colour_block=~m/\"option\"\:\"([^\"]*?)\"/igs)
							{
								my $tcolour=trim($1);
								push(@tcolor,$tcolour); 
							}
						}
						foreach my $color(@tcolor)
						{
							if($content90=~m/option\s*\"\s*\:\s*\"\s*$color\s*\"\s*\,\s*\"\s*availability":"\s*true\s*\"/is)
							{
								$Sku_flag=1;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,'n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
							else
							{
								$Sku_flag=1;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,'y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$color;
								push(@query_string,$query);
							}
						}
						if(!@tcolor)
						{
							if($content90=~m/option\s*\"\s*\:\s*\"\s*$size\s*\"\s*\,\s*\"\s*availability":"\s*true\s*\"/is)
							{
								$Sku_flag=1;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,'','n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$product_id1;
								push(@query_string,$query);
							}
							else
							{
								$Sku_flag=1;
								$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,'','y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$product_id1;
								push(@query_string,$query);
							}
						}
					}
				}
				else
				{
					my $cup_url='http://www.jcpenney.com/dotcom/jsp/browse/pp/graphical/graphicalLotSKUSelection.jsp?_dyncharset=UTF-8&_dynSessConf=2521372785575283833&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName=color&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.selectedSKUAttributeName=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=test&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.lotSKUSelectionChange=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=regular&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppType=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId='.$product_id.'&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.ppId=+&%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=&_D%3A%2Fcom%2Fjcpenney%2Fcatalog%2Fformhandler%2FGraphicalLotSKUSelectionFormHandler.skuSelectionMap.COLOR=+&_DARGS=%2Fdotcom%2Fjsp%2Fbrowse%2Fpp%2Fgraphical%2FgraphicalLotSKUSelection.jsp';
					my $content90 = get_content($cup_url);
					
					my @tcolor;
					if($content90=~m/\{\"key\"\:\"COLOR\"\,\"options\"\:\[\{([^<]*?)\}\]/is)
					{
						my $colour_block=$1;
						while($colour_block=~m/\"option\"\:\"([^\"]*?)\"/igs)
						{
							my $tcolour=trim($1);
							push(@tcolor,$tcolour);
							push(@colour_array,$tcolour);
							$img_status=1;
							print "\nImage Status Set\n";
						}
					}
					foreach my $color(@tcolor)
					{
						if($content90=~m/option\s*\"\s*\:\s*\"\s*$color\s*\"\s*\,\s*\"\s*availability":"\s*true\s*\"/is)
						{
							$Sku_flag=1;
							$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'',$color,'n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
						else
						{
							$Sku_flag=1;
							$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'',$color,'y',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);
						}
					}
				}
			}
		}
		
		if($Sku_flag == 0 and $product_name ne '') 
		{
			print "\nNo Size and Colour\n";
			$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'','','n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$product_id1;
			push(@query_string,$query);
		}
		#Swatch_image
		
		if ($content2=~m/<span>\s*select\s*a\s*color\s*\:\s*([\w\W]*?)\s*<script\s*type\s*\=\s*\"text\/javascript\s*\">/is)
		{
			my $swatch_content=$1;
			if($swatch_content=~m/<a\s*class\s*\=\s*\"swatch\s*\"[^<]*?onmouseover\s*\=\s*\"updateRender\s*\(\s*\'\s*([^<]*?\.tif)\s*\'\s*\)[^<]*?>\s*<img\s*src\s*\=\s*\"\s*([^>]*?)\s*"[^<]*?alt\=\"([^<]*?)\"[^<]*?>/is)
			{
				while($swatch_content=~m/<a\s*class\s*\=\s*\"swatch\s*\"[^<]*?onmouseover\s*\=\s*\"updateRender\s*\(\s*\'\s*([^<]*?\.tif)\s*\'\s*\)[^<]*?>\s*<img\s*src\s*\=\s*\"\s*([^>]*?)\s*"[^<]*?alt\=\"([^<]*?)\"[^<]*?>/igs)
				{
					my $default_image=trim($1);
					my $color = trim($3);
					$alt_image="http://zoom.jcpenney.com/is/image/".$default_image."?hei=1500&wid=1500";
					push(@colour_array,$color);
					#Dfault Image
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				
				while($swatch_content=~m/<a\s*class\s*\=\s*\"swatch\s*\"[^<]*?>\s*<img\s*src\s*\=\s*\"\s*([^>]*?)\s*"[^<]*?alt\=\"([^<]*?)\"[^<]*?>/igs)
				{
					my $swatch = trim($1);
					my $color = trim($2);
					push(@colour_array,$color);
					#Swatch
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object} = 'n';
					push(@query_string,$query);
				}
			}
			elsif($swatch_content=~m/<a\s*class\s*\=\s*\"swatch\s*\"[^<]*?>\s*<img\s*src\s*\=\s*\"\s*([^>]*?)\s*"[^<]*?alt\=\"([^<]*?)\"[^<]*?>/is)
			{
				while($swatch_content=~m/<a\s*class\s*\=\s*\"swatch\s*\"[^<]*?>\s*<img\s*src\s*\=\s*\"\s*([^>]*?)\s*"[^<]*?alt\=\"([^<]*?)\"[^<]*?>/igs)
				{
					my $swatch = trim($1);
					my $color = trim($2);
					push(@colour_array,$color);
					$img_status=1;
					#Swatch
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object} = 'n';
					push(@query_string,$query);
				}
			}
		}
		
		##product_image
		if($content2=~m/var\s*imageName\s*\=\s*\"\s*([^>]*?)\s*\"/is)
		{
			my $product_image1=$1;
			$product_image1=~s/^\s+|\s+$//igs;
			my @product_image=split(/,/,$product_image1);
			my ($i,$alt_image,@image_array);
			for($i=0;$i<=$#product_image;$i++)
			{
				my $id_first=$product_image[$i];
				my $img_file=(split('\/',$id_first))[-1];
				$alt_image="http://zoom.jcpenney.com/is/image/".$id_first."?hei=1500&wid=1500";
				my $count=0;
				push(@image_array,$id_first);
				if(!@colour_array)
				{
					if($i ==0 and $count ==0)
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id1;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id1;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					$count++;
				}
			}
			#---------------------------------------------
			my @imagearry1=keys %{{ map { $_ => 1 } @image_array }};
			my @colour_array1=keys %{{ map { $_ => 1 } @colour_array }};
			foreach my $color(@colour_array1)
			{
				my $i=0;
				my $count1=0;
				foreach(@imagearry1)
				{
					my $alt_image="http://zoom.jcpenney.com/is/image/".$_."?hei=1500&wid=1500";
					
					if($img_status == 1)
					{
						if($i ==0 and $count1 ==0)
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						else
						{
							my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
						$count1++;
					}
					$i++;
				}
			}
			#------------------------------------------- Alt Images --------------------------------
			my $i1=0;
			my $count2=0;
			if(@colour_array1)
			{
				foreach(@imagearry1)
				{
					my $alt_image="http://zoom.jcpenney.com/is/image/".$_."?hei=1500&wid=1500";
					if($i1 ==0 and $count2 ==0){}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$colour_array1[0];
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					$count2++;
					$i1++;
				}
			}
			#------------------------------------------- Alt Images --------------------------------
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id1,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		$dbh->commit;
	}	
}1;

sub get_content
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	#unlink($cookie_file);
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
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
sub trim
{
	my $txt = shift;
	
	$txt =~ s/\<[^>]*?\>/ /ig;
	$txt =~ s/\n+/ /ig;
	$txt =~ s/\"/\'\'/g;
	$txt =~ s/\s+/ /ig;
	$txt=decode_entities($txt);
	$txt =~ s/^\s+|\s+$//ig;
	return $txt;
}

