#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Sportsgirl_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name, $robotname_detail, $robotname_list, $Retailer_Random_String, $pid, $ip, $excuetionid, $country, $ua, $cookie_file, $retailer_file, $cookie);

sub Sportsgirl_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;
	my $mflag=0;
	
	####Variable Initialization##############
	$robotname='Sportsgirl-AU--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Sport';
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
	my $rcount = 0;
	############Database Initialization########
	$dbh = &DBIL::DbConnection();
	###########################################
	ReVisit:
	my $select_query = "select ObjectKey from Retailer where name=\'$retailer_name\'";
	my $retailer_id = &DBIL::Objectkey_Checking($select_query, $dbh, $robotname);

	my $hashref = &DBIL::Objectkey_Url($robotname_list, $dbh, $robotname,$retailer_id);
	my %hashUrl = %$hashref;
	my $pcount = 0;
		
	my $skuflag = 0; my $imageflag = 0;	
	
	if($product_object_key)
	{
		# my $url = $hashUrl{$product_object_key};
		my $url3=$url;	
		my @query_string;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		
		unless($url3=~m/^\s*http\:/is)
		{
			$url3="http://www.sportsgirl.com.au/".$url3;			
		}
		
		my $content= get_content($url3);
		# open FH , ">sportsgirl12.html" or die "File not found\n";
		# print FH $content;
		# close FH;
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$select_var);	
		
		#description	
		if ($content=~ m/<div\s*class\s*\=\s*\"description\s*\">\s*([\w\W]*?)\s*<\/div>/is)
		{
			$description=$1;		
			$description=trim($description);										
			print"\nprod_detail------------->$description\n";
		}
		#product details
		if ($content=~ m/<ul\s*class\s*\=\s*\"product\s*\-\s*attribute\s*\-\s*specs\s*\-\s*table\">\s*([\w\W]*?)\s*<\/ul>/is)
		{
			$prod_detail=$1;
			$prod_detail=trim($prod_detail);										
			print"\nprod_detail------------->$prod_detail\n";
		}
		#product id
		if($content=~m/<span\s*class\s*\=\s*\"sku-code\s*\">\s*([^>]*?)\s* <\/span>/is)
		{
			$product_id=$1;
			$product_id=trim($product_id);
			# $product_id=~s/\-//igs;
			$product_id=~s/-[a-zA-z0-9]+//igs;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			##next if($ckproduct_id == 1);
			goto PNF if($ckproduct_id == 1);
			undef ($ckproduct_id);
			print"\nproduct_id------------->$product_id\n";
		}
		
		#product_name
		if ( $content=~ m/<h1>\s*([\w\W]*?)\s*<\/h1>/is )
		{
			$product_name = $1;
			$product_name = trim($product_name);
			print"\nproduct_name------------->$product_name\n";
		}
		
		#price_Text
		if ( $content=~ m/<div\s*class\s*\=\s*\"\s*price\s*\-\s*box\s*\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
		{
			$price_text=$1;	
			my $Pric=$price_text;
			$price_text = trim($price_text);
			$price_text = $price_text." "."AUD";
			print"\nprice_text------------->$price_text\n";	
			if($Pric=~m/<span\s*class\s*\=\s*\"\s*price\"\s*[^>]*?\s*>\s*([\w\W]*?)<\/span>/is)
			{
				$price = "$1";
				$price =~s/^\s+|\s+$//igs;
				$price=~s/A\$//igs;
				$price=~s/\$//igs;
				$price = trim($price);
				print"\nprice------------->$price\n";
			}	
		}
				
		my $flag1;
		$flag1=0;	
		my (%sku_objectkey,%image_objectkey,%hash_default_image);		
	##color		
		my $color;
		if($content=~m/<span\s*class\s*\=\s*\"\s*pdpLabel\s*\">\s*Colour\s*<\/span>\s*([\w\W]*?)\s*<\/option>/is)
		{
			$color=$1;		
			$color=trim($color);		
			# &DBIL::SaveTag('Color',$color,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		}
		else
		{			
			# &DBIL::SaveTag('Color',$color,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		}
		if($color eq '')
		{
			$color="no raw color";
		}	
		
		if($content=~m/var\s*spConfig\s*[^>]*?\s*id([\w\W]*?)\s*jQuery/is)
		{
			my $available_color=$1;
			while($available_color=~m/\{\s*[\w\W]*?\s*label\s*\"\s*\:\s*\"\s*([\w\W]*?)\s*\"\s*\,\s*[^>]*?\s*outofstock\s*\"\s*\:\s*([\w\W]*?)\s*\,/igs)
			{
				my $size=$1;
				$size=~s/\-([^>]*?)$//igs;
				my $Stock_count=$2;
				$Stock_count=~s/^\s+|\s+$//igs;
				print"\nStock_count------------->$Stock_count\n";
				print"\nSize------------->$size\n";				
				if($Stock_count eq 'false')
				{
				
					my $out_of_stock='n';				
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;		
					push(@query_string,$query);	
				}
				else
				{			
					my $out_of_stock='y';
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;	
					push(@query_string,$query);
				}
				
			}
		}
		else
		{
			if($price ne '')
			{
				my $out_of_stock='n';
				my $size='one size';
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;	
				push(@query_string,$query);
			}
		}	
	# print"\nExit\n";exit;
		
	##product_image	
		
			my $flag1=0;	
			while($content=~m/<div\s*class\s*\=\s*\"\s*slider\s*[^>]*?\s*\=\s*\"\s*([^>]*?)\s*\">/igs)
			{
				my $imageurl=$1;			
				my $img_file = (split('\/',$imageurl))[-1];
				if($flag1 eq '0')
				{	
					print"\nalt_image------------->$imageurl\n";
					print"\nimg_file------------->$img_file\n";	
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='y';
					$flag1++;
					push(@query_string,$query);	
				}
				else
				{
					print"\nalt_image------------->$alt_image\n";
					print"\nimg_file------------->$img_file\n";	
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);	
				}	
			}
			
			
		
		
		
	#getting more color
		my $Jack=0;
		
		if($content=~m/<span\s*class\s*\=\s*\"\s*pdpLabel\s*\">\s*Colour\s*([\w\W]*?)<\/select>/is)
		{	
			my $color_Content=$1;
			while($color_Content=~m/<option\s*value\s*\=\s*\"\s*([^>]*?)\s*\"/igs)
			{	
				my $Colour_Url1="$1";
				$Colour_Url1 =~s/^\s+|\s+$//igs;
				my $content10= get_content($Colour_Url1);
				# open FH , ">Sports11.html" or die "File not found\n";
				# print FH $content10;
				# close FH;
				if($Jack eq '0')
				{
					$Jack++;
					next;
				}
				# $mflag=1;
				#color
				#price_Text
				if ( $content10=~ m/<div\s*class\s*\=\s*\"\s*price\s*\-\s*box\s*\">\s*([\w\W]*?)\s*<\/div>\s*<\/div>/is )
				{
					$price_text=$1;	
					my $Pric=$price_text;
					$price_text = trim($price_text);
					$price_text = $price_text." "."AUD";
					print"\nprice_text------------->$price_text\n";	
					if($Pric=~m/<span\s*class\s*\=\s*\"\s*price\"\s*[^>]*?\s*>\s*([\w\W]*?)<\/span>/is)
					{
						$price = "$1";
						$price =~s/^\s+|\s+$//igs;
						$price=~s/A\$//igs;
						$price=~s/\$//igs;
						$price = trim($price);
						print"\nprice------------->$price\n";
					}	
				}
				my $color;
				if($content10=~m/<span\s*class\s*\=\s*\"\s*pdpLabel\s*\">\s*Colour\s*<\/span>\s*([\w\W]*?)\s*<\/option>/is)
				{
					$color=$1;		
					$color=trim($color);		
					# &DBIL::SaveTag('Color',$color,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				}
				else
				{			
					# &DBIL::SaveTag('Color',$color,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				}
				if($color eq '')
				{
					$color="no raw color";
				}	
				if($content10=~m/var\s*spConfig\s*[^>]*?\s*id([\w\W]*?)\s*jQuery/is)
				{
					my $available_color=$1;
					while($available_color=~m/\{\s*[\w\W]*?\s*label\s*\"\s*\:\s*\"\s*([\w\W]*?)\s*\"\s*\,\s*[^>]*?\s*outofstock\s*\"\s*\:\s*([\w\W]*?)\s*\,/igs)
					{
						my $size=$1;
						$size=~s/\-([^>]*?)$//igs;
						my $Stock_count=$2;
						$Stock_count=~s/^\s+|\s+$//igs;
						print"\nStock_count------------->$Stock_count\n";
						print"\nSize------------->$size\n";
						if($Stock_count eq 'false')
						{
						
							my $out_of_stock='n';				
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;
							push(@query_string,$query);		
						}
						else
						{			
							my $out_of_stock='y';
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;	
							push(@query_string,$query);	
						}
						
					}
				}
				else
				{
					my $out_of_stock='n';
					my $size='one size';
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;
					push(@query_string,$query);		
				}						
			##product_image	
			
				my $flag1=0;	
				while($content10=~m/<div\s*class\s*\=\s*\"\s*slider\s*[^>]*?\s*\=\s*\"\s*([^>]*?)\s*\">/igs)
				{
					my $imageurl=$1;			
					my $img_file = (split('\/',$imageurl))[-1];
					if($flag1 eq '0')
					{	
						print"\nalt_image------------->$imageurl\n";
						print"\nimg_file------------->$img_file\n";	
						my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
					
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='y';	
						$flag1++;
						push(@query_string,$query);	
					}
					else
					{
						print"\nalt_image------------->$alt_image\n";
						print"\nimg_file------------->$img_file\n";	
						my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
					
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
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
		
		
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3, $retailer_id, $mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);
		PNF:		
		print "End\n";		
		$dbh->commit();
		##$dbh->commit();
		##&DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
		# $dbh->commit();	
	}		
	##&DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
	# $dbh->commit();	
	# &DBIL::SaveDB("Delete from Product where detail_collected='d' and RobotName=\'$robotname_list\'",$dbh,$robotname);	
}1;			
sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>$url);
	$req->header("Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
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

sub trim
{
	my $txt = shift;
	
	$txt =~ s/\<[^>]*?\>//igs;
	$txt =~ s/\n+/ /igs;	
	$txt =~ s/^\s+|\s+$//igs;
	$txt =~ s/\s+/ /igs;
	$txt =~ s/\&nbsp\;//igs;
	$txt =~ s/\&amp\;/\&/igs;
	$txt =~ s/\&bull\;//igs;
	$txt =~ s/\&quot\;/"/igs;	
	$txt =~ s/\"/\'\'/g;
	$txt =~ s/\!//g;
	$txt =~ s/\Â//g;
	# $txt =~ s/\"/\'\'/g;
	# $txt =~ s/&frac34;/3\/4/igs;
	# $txt =~ s/â„¢/™/igs;
	# $txt =~ s/\&eacute\;/é/igs;
	# $txt =~ s/Â®/®/igs;
	# $txt =~ s/â€™/\'/igs;
	# $txt =~ s/Â/®/igs;
	# $txt =~ s/\(/ /igs;
	# $txt =~ s/\)/ /igs;
	
	return $txt;
}
