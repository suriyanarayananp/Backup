#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Asdageorge_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Asdageorge_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;
	$robotname='Asdageorge-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Asd';
	$pid = $$;
	$ip = `/sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`;
	$ip = $1 if($ip =~ m/inet\s*addr\:([^>]*?)\s+/is);
	$excuetionid = $ip.'_'.$pid;
	my $img_ret_name='asda_george-uk';
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
	if($product_object_key)
	{		
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		my @query_string;
		$product_object_key =~ s/^\s+|\s+$//g;
		# $logger->send("$product_object_key --> Start Processing");
		my $id;
		if($url3=~m/\/([\w]+?)\Wdefault/is)
		{
			$id=$1;
		}
		my $sam_link="http://direct.asda.com/on/demandware.store/Sites-ASDA-Site/default/Product-GetVariantsJson?pid=".$id."&format=json";
		my $test=get_content($sam_link);
		$test=decode_entities($test);
		
		my $content2 = get_content($url3);
		$content2=decode_entities($content2);
		goto end if($content2 =~ m/>\s*Our\s*Apologies\s*<\/h2>/is);
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		$description=' ';
		if($content2 eq 1)
		{
			goto Noinfo;
		}
		if($content2=~m/spanItem\">\s*Item\s*selected\s*</is)
		{
			$mflag=1;
			if ( $content2 =~ m/name\:\s*\"([^>]*?)\"\s*\,\s*ID\:\s*\"\s*([^>]*?)\s*\"/is )
			{			
				$product_name = &DBIL::Trim($1);
				$product_id = &DBIL::Trim($2);
			}
			if ( $content2 =~ m/setDesc\">\s*([^>]*?)<\/p>/is )
			{
				$description = &DBIL::Trim($1);
			}
			goto Noinfo;
		}
		if ( $content2 !~ m/<h\d+[^<]*?id\=\"productName\">\s*([\w\W]*?)\s*<\/h1>/is )
		{
			if($content2 =~ m/CurrentPName\s*\=\s*\"([^>]*?)\"/is)
			{
				$product_name = &DBIL::Trim($1);
			}
			if ( $content2 =~ m/Description<\/h3>\s*([\w\W]*?)<\/div>/is )
			{
					$description = &DBIL::Trim($1);
			}
			#goto Noinfo;
		}
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		#price_text
		if ( $content2 =~ m/productPrice\">([\w\W]*?)<\/span>\s*<\/span>/is )
		{
			$price_text="$1";
			$price_text = &DBIL::Trim($price_text);
			$price=$price_text;
			if($price=~m/now\s*([^>]*?)(?:\s*Save[^>]*?)?\s*$/is)
			{
				$price=$1;
			}
			$price=~s/[^\d\.]//gs;
			$price=~s/from\s*//igs;
			$price_text=~s/\Â//igs;
			$price=~s/^\W\s*//is;
			$price_text=~s/\&pound\;/\Â\£/igs;
			$price_text =~ s/\&\#163\;/\Â\£/igs;
			$price_text=~s/\£/\Â\£/igs;
			$price_text=~s/Was[^>]*?\£/Was \Â\£/igs;
			$price_text=~s/Now\s*\£/Now \Â\£/igs;
			if($price eq "")
			{
				$price='null';
			}
		}	
		#product_id
		 if ( $url3 =~ m/\/(\d+)\Wdefault/is )
   		{
			$product_id = &DBIL::Trim($1);
		}
		if ( $content2 =~ m/\(\{id\:\'(\d+)\'\}\)\}\;/is )
		{
				$product_id = &DBIL::Trim($1);
		}
		# if ( $content2 =~ m/<td[^>]*?>Model\s*Number<\/td>\s*<td[^>]*?>\s*([^>]*?)</is )
		# {
			# $product_id = &DBIL::Trim($1);
		# }
		if ( $content2 =~ m/>\s*Product\s*Code\s*\:\s*([^<]*?)\s*</is )
		{
			$product_id = &DBIL::Trim($1);
		}
		$product_id=~s/\s*\/[^>]*?$//is;
		my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname, $retailer_id);
		goto end if($ckproduct_id == 1);
		undef ($ckproduct_id);
		#product_name
		if ( $content2 =~ m/<h\d+[^<]*?id\=\"productName\">\s*([\w\W]*?)\s*<\/h1>/is )
		{
			$product_name = &DBIL::Trim($1);
		}
		#Brand
		if ( $content2 =~ m/<meta[^<]*?itemprop\=\"brand\"[^<]*?content\=\"([^\"]+?)\"[^>]*?>/is )
		{
			$brand = &DBIL::Trim($1);
			if ( $brand !~ /^\s*$/g )
			{
				&DBIL::SaveTag('Brand',lc($brand),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				
			}
		}
		#description&details
		if ( $content2 =~ m/(?:<span>\s*Product\s*Details\s*<\/span>[\w\W]*?)?<div[^<]*?class\=\"description\">([\w\W]*?)<\/div>/is )
		{
			#$prod_detail = &DBIL::Trim($1);
			$description = &DBIL::Trim($1);
			$description=~s/product\s*code\s*\:\s*[^>]*?>//igs;
			$prod_detail=~s/product\s*code\s*\:\s*[^>]*?>//igs;
		}
		#colour
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		my ($color,$color_value);
		my $i=1;
		my @c;
		if ( $content2 =~ m/<label[^>]*?>\s*Colour\s*<\/label>\s*<select[^>]*?>([\w\W]*?)\s*<\/select>/is )
		{
			my $color_content=$1;
			while($color_content=~m/<option[^<]*?value\=\"\w+[^>]*?>\s*([^<]*?)\s*<\/op/igs)
			{
				$color = &DBIL::Trim($1);
				push (@c, $color);
				if ( $color !~ m/^\s*$/ )
				{
					#&DBIL::SaveTag('Color',lc($color),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
					
				}
				$i++;
			}
		}
		
		if($i>=3)
		{
			foreach (@c)
			{
				my $color=$_;
				# print "first...";
				if($content2=~m/size\">\s*<option\s*value\=\"\">Select\s*size<([\w\W]*?)<\/select>/is)
				{
					my $b=$1;
					my @size;
					while($b=~m/<option\s*value[^>]*?>([^>]*?)</igs)
					{	
						my $val=$1;
						push (@size, $val);
					}
					# print "@size\n";
					
					foreach (@size)
					{
						my $size=$_;
						my $ch=$size;
						$size=~s/\s*sold\s*out//igs;
						$size=~s/\W*\s*low\s*stock//igs;
						if($test=~m/\"size\"\:\s*\"$size\"\s*\,\s*\"colour\"\:\s*\"$color\"/is)
						{
							$out_of_stock='n';
						}	
						else
						{
							$out_of_stock='y';
						}
						# print "$out_of_stock";
						my ($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
				}
				else
				{
					my $size='No Size';
					my $out_of_stock='n';
					my ($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;
					push(@query_string,$query);
				}
			}
		}		
		else
		{
			if ( $content2 =~ m/selectedColour\"\s*value\=\"([^>]*?)\"\s*\/>[\w\W]*?>Select\s*size<\/option>([\w\W]*?)<\/select>/is )
			{
				my $color=$1;
				my $block=$2;
				# print "Hi...";
				my @size;
				if($block=~m/^\s*$/is)
				{
					# print "Hi...";
					if($content2=~m/<html[\w\W]*>\s*Select\s*colour<\/option>(?:\s*<[^>]*?>\s*)+([^>]*?)<[\w\W]*?>Select\s*size<\/option>([\w\W]*?)<\/select>/is)
					{
						$color=$1;
						$block=$2;
						if($block=~m/^\s*$/is)
						{
							if($content2=~m/selectedColour\"\s*value\=\"([^>]*?)\"\s*\/>[\w\W]*?size\">\s*<option\s*value\=\"\">Select\s*size<([\w\W]*?)<\/select>/is)
							{
								$color=$1;
								$block=$2;
								push (@c, $color);
							}
						}
					}
				}
				while($block=~m/<option\s*value[^>]*?>([^>]*?)</igs)
				{	
					my $val=$1;
					push (@size, $val);
				}
				# print "@size\n";
				
				foreach (@size)
				{
					my $size=$_;
					my $ch=$size;
					$size=~s/\s*sold\s*out//igs;
					$size=~s/\W*\s*low\s*stock//igs;
					if($ch=~m/Sold\s*out/is)
					{
						$out_of_stock='y';
					}	
					else
					{
						$out_of_stock='n';
					}
					my ($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;
					push(@query_string,$query);
					$i++;
				}
			}	
			else
			{
				# my $price_text='';
				my $size='No Size';
				my $color='';
				my $out_of_stock='';
				if($price ne "")
				{
					$out_of_stock='n';
				}
				else
				{
					$out_of_stock='y';
				}
				my ($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
				while ( $content2 =~ m/<img\s*src\=\"([^<]*?)\"[^>]*?title=\"(alternative|main)\s*view\"[^>]*?>/igs )
				{
					my $alt_image_content = $1;
					my $imagetype = &DBIL::Trim($2);
					my $imageurl;
					if ( $alt_image_content =~ m/([^>]*?)\?/is )
					{
						$imageurl = &DBIL::Trim($1);
					}
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$img_ret_name);
					# $img_file = (split('\/',$imageurl))[-1];
					
					if ( $imagetype =~ m/main/is )
					{
						my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}
				
				
				# my $res3 = "\"".$hash_url{$url3}."\"".","."\"".$prod_objkey{$url3}."\"".","."\"".$url3."\"".","."\"".$product_name."\"".","."\"".$price."\"".","."\"".$price_text."\"".","."\"".$size."\"".","."\"".$color."\"".","."\"".$out_of_stock."\"".","."\"".&generate_random_string('nccnnncccncncncncnnnnccccncncncncnnnncnc')."\"".","."\"Asda_george-UK--Detail\"".","."\"\"".","."\"".&Ex_time()."\"".","."\"".&Ex_time()."\"".","."\"".'y'."\"".","."\"".&Ex_time()."\""."\n";
				# open FH , ">>$Skufile" or die "File not found\n";
				# print FH $res3;
				# close FH;
			}
		}	
		#Image
		foreach (@c)
		{
			my $color_value=$_;
			while ( $content2 =~ m/<img\s*src\=\"([^<]*?)\"[^>]*?title=\"(alternative|main)\s*view\"[^>]*?>/igs )
			{
				my $alt_image_content = $1;
				my $imagetype = &DBIL::Trim($2);
				my $imageurl;
				if ( $alt_image_content =~ m/([^>]*?)\?/is )
				{
					$imageurl = &DBIL::Trim($1);
				}
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$img_ret_name);
				# $img_file = (split('\/',$imageurl))[-1];
				
				if ( $imagetype =~ m/main/is )
				{
					my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color_value;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				else
				{
					my ($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color_value;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
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
					# $logger->send("$product_object_key --> Sku Has Image Processing");
				}
			}
		}
		Noinfo:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# push(@query_string,$query1);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
		print "";
		$dbh->commit();
		# $logger->send("$product_object_key --> Processed Successfully");
	}
}1;

sub get_content()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>$url);
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
		# print "Entered\n";
		$content = $res->content;
		return($content);
	}
	elsif($code =~m/(?:404|410)/is)
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(1);
			goto Home;
		}
		return 1;
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(1);
			goto Home;
		}
		return 1;
	}
}
