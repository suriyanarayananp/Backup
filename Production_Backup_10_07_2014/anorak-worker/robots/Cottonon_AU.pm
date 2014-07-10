#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Cottonon_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# use utf8;
#require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Cottonon_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	# $dbh->do("set character set utf8");
	# $dbh->do("set names utf8");
	$robotname='Cottonon-AU--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Cottonon';
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
	if($product_object_key)
	{
		my $skuflag = 0;
		my $imageflag = 0;
		my $url3=$url;		
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		my @query_string;
		unless($url3=~m/^\s*http\:/is)
		{			
			$url3="http://shop.cottonon.com/".$url3;
		}
		
		my $content= get_content($url3);
		# open FH , ">sportsgirl12.html" or die "File not found\n";
		# print FH $content;
		# close FH;
	
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$imageurl,$out_of_stock,$colour,$select_var);	
		$brand="cotton on";
		#description&details
		
		if ($content=~ m/id\s*\=\s*\"tab\s*\-\s*description\s*\">\s*([\w\W]*?)\s*Product\s*code/is)
		{
			$description=$1;
			$description=trim($description);										
			print"\nprod_detail------------->$description\n";
		}
		#product id
		if($content=~m/Product\s*code\s*\:\s*<span\s*id\s*\=\s*\"\s*master_item_code\s*\">\s*([^>]*?)\s*</is)
		{
			$product_id=$1;
			$product_id=~s/-[a-zA-z0-9]+//igs;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
			print"\nproduct_id------------->$product_id\n";
		}
		
		#product_name
		if ( $content=~ m/<h2>\s*([\w\W]*?)\s*<\/h2>/is )
		{
			$product_name = $1;
			$product_name = trim($1);
			print"\nproduct_name------------->$product_name\n";
		}
		#price_Text
		if ( $content=~ m/<span\s*class\s*\=\s*\"old\s*\-\s*price\s*\">([^>]*?)<\/span>\s*<span\s*class\s*\=\s*\"now\">\s*([^>]*?)\s*<\/span>\s*<span\s*class\s*\=\s*\"sale\s*\-\s*price\"> \s*([^>]*?)\s*<\/span>/is )
		{
			$price_text = "$1"." "."$2"." "."$3";
			$price_text = trim($price_text);
			print"\nprice_text------------->$price_text\n";
		}
		elsif( $content=~m/(product\s*\-\s*details\s*[\w\W]*?\s*<\/li>)/is)
		{
			my $Gr_price=$1;
			if($Gr_price=~m/>([^>]*?)<\/li>/is)
			{
				$price_text=$1;	
				$price_text = trim($price_text);
				print"\nprice_text1------------->$price_text\n";
			}
		}
		
		#price
		if ( $content=~ m/<span\s*class\s*\=\s*\"old\s*\-\s*price\s*\">([^>]*?)<\/span>\s*<span\s*class\s*\=\s*\"now\">\s*([^>]*?)\s*<\/span>\s*<span\s*class\s*\=\s*\"sale\s*\-\s*price\"> \s*([^>]*?)\s*<\/span>/is )
		{
			$price = "$3";
			$price =~s/^\s+|\s+$//igs;
			$price=~s/A\$//igs;
			$price=~s/\$//igs;
			$price = trim($price);
			print"\nprice------------->$price\n";
		}
		elsif( $content=~m/(product\s*\-\s*details\s*[\w\W]*?\s*<\/li>)/is)
		{
			my $Gr_price=$1;		
			if($Gr_price=~m/>([^>]*?)<\/li>/is)
			{
				$price = "$1";
				$price =~s/^\s+|\s+$//igs;
				$price=~s/A\$//igs;
				$price=~s/\$//igs;
				$price = trim($price);
				print"\nprice1------------->$price\n";
			}
		}
		
		print"\nExit\n";
		my $flag1;
		$flag1=0;	
		my (%sku_objectkey,%image_objectkey,%hash_default_image);			
	##color		
		my $color;
		if($content=~m/<h3>\s*Colour\s*[\w\W]*?\s*(?:<option>|<p>)\s*([^>]*?)\s*(?:<\/option>|<\/p>)/is)
		{
			$color=$1;		
			$color=trim($color);
			$color_hash{$color}=$color;	
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
		if($content=~m/var\s*variations\s*\=\s*([\w\W]*?)var\s*variation/is)
		{
			my $available_color=$1;
			while($available_color=~m/total_in_stock\s*\"\s*\:\s*([^>]*?)\s*\,\s*\"\s*image_id\s*[^>]*?\s*option2\s*\"\s*\:\s*\"\s*([^>]*?)\s*\"/igs)
			{
				my $Stock_count=$1;
				my $size=$2;
				$Stock_count=~s/^\s+|\s+$//igs;
				# print"\nStock_count------------->$Stock_count\n";
				# print"\nSize------------->$size\n";
				if($Stock_count eq '0')
				{
					my $out_of_stock='y';					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;									
				}
				else
				{			
					my $out_of_stock='n';
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;	
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
				push(@query_string,$query);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;	
			}	
		}		

		
	##product_image	
		if($content=~m/(<div\s*id\s*\=\s*\"\s*product\s*\-\s*images\s*\-\s*thumb">\s*[\w\W]*?\s*<\/div>)/is)
		{
			my $product_image=$1;	
			my $flag1=0;	
			while($product_image=~m/href\s*\=\s*\"([^>]*?)\s*\"/igs)
			{
				my $imageurl=$1;			
				# my $img_file = (split('\/',$imageurl))[-1];
				if($flag1 eq '0')
				{	
					# print"\nimageurl------------->$imageurl\n";
					# print"\nimg_file------------->$img_file\n";	
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='y';
					$flag1++;	
				}
				else
				{
					# print"\nimageurl------------->$imageurl\n";
					# print"\nimg_file------------->$img_file\n";	
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';				
				}	
			}
		}
		elsif($content=~m/product\s*\-\s*images\s*\-\s*large\s*\">\s*[\w\W]*?\s*<a\s*href\s*\=\s*\"([^>]*?)\s*\"/is)
		{		
			my $imageurl=$1;
			# my $img_file = (split('\/',$imageurl))[-1];	
			# print"\nimageurl------------->$imageurl\n";
			# print"\nimg_file------------->$img_file\n";	
			my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$color;
			$hash_default_image{$img_object}='y';				
		}
		
		my $mflag;
		# &DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$mflag);
		
	#getting more color
		if($content=~m/(<h3>\s*Colour\s*[\w\W]*?\s*<\/section>)/is)
		{	
			my $color_Content=$1;
			my $inc=2;
			while($color_Content=~m/<option\s*data[^>]*?\s*\"\s*([^>]*?)\s*\">/igs)
			{	
				my $Colour_Url1="http://shop.cottonon.com"."$1";
				$Colour_Url1 =~s/^\s+|\s+$//igs;
				my $content10= get_content($Colour_Url1);
				# open FH , ">Cotton11.html" or die "File not found\n";
				# print FH $content10;
				# close FH;
				
				#price_Text
				my($price_text,$price,$color);
				if ( $content10=~ m/<span\s*class\s*\=\s*\"old\s*\-\s*price\s*\">([^>]*?)<\/span>\s*<span\s*class\s*\=\s*\"now\">\s*([^>]*?)\s*<\/span>\s*<span\s*class\s*\=\s*\"sale\s*\-\s*price\"> \s*([^>]*?)\s*<\/span>/is )
				{
					$price_text = "$1"." "."$2"." "."$3";
					$price_text = trim($price_text);
					print"\nprice_text------------->$price_text\n";
				}
				elsif( $content10=~m/(product\s*\-\s*details\s*[\w\W]*?\s*<\/li>)/is)
				{
					my $Gr_price=$1;
					if($Gr_price=~m/>([^>]*?)<\/li>/is)
					{
						$price_text=$1;	
						$price_text = trim($price_text);
						print"\nprice_text1------------->$price_text\n";
					}
				}
				
				#price
				if ( $content10=~ m/<span\s*class\s*\=\s*\"old\s*\-\s*price\s*\">([^>]*?)<\/span>\s*<span\s*class\s*\=\s*\"now\">\s*([^>]*?)\s*<\/span>\s*<span\s*class\s*\=\s*\"sale\s*\-\s*price\"> \s*([^>]*?)\s*<\/span>/is )
				{
					$price = "$3";
					$price =~s/^\s+|\s+$//igs;
					$price=~s/A\$//igs;
					$price=~s/\$//igs;
					$price = trim($price);
					print"\nprice------------->$price\n";
				}
				elsif( $content10=~m/(product\s*\-\s*details\s*[\w\W]*?\s*<\/li>)/is)
				{
					my $Gr_price=$1;		
					if($Gr_price=~m/>([^>]*?)<\/li>/is)
					{
						$price = "$1";
						$price =~s/^\s+|\s+$//igs;
						$price=~s/A\$//igs;
						$price=~s/\$//igs;
						$price = trim($price);
						print"\nprice1------------->$price\n";
					}
				}	
						
			##color						
				if($content10=~m/<h3>\s*Colour\s*[\w\W]*?\s*(?:<option>|<p>)\s*([^>]*?)\s*(?:<\/option>|<\/p>)/is)
				{
					$color=$1;		
					$color=trim($color);
					if($color_hash{$color} eq '')
					{
						$color_hash{$color}=$color;
					}
					else
					{
						$color=$color.' ('.$inc.')';
						$inc++;
					}
				}	
				else
				{			
					# &DBIL::SaveTag('Color',$color,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				}
				if($color eq '')
				{
					$color="no raw color";
				}		
				if($content10=~m/var\s*variations\s*\=\s*([\w\W]*?)var\s*variation/is)
				{
					my $available_color=$1;
					while($available_color=~m/total_in_stock\s*\"\s*\:\s*([^>]*?)\s*\,\s*\"\s*image_id\s*[^>]*?\s*option2\s*\"\s*\:\s*\"\s*([^>]*?)\s*\"/igs)
					{
						my $Stock_count=$1;
						my $size=$2;
						$Stock_count=~s/^\s+|\s+$//igs;
						# print"\nStock_count------------->$Stock_count\n";
						# print"\nSize------------->$size\n";
						if($Stock_count eq '0')
						{
							my $out_of_stock='y';
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;				
						}
						else
						{			
							my $out_of_stock='n';
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;	
						}
						
					}
				}		

				
			##product_image	
				if($content10=~m/(<div\s*id\s*\=\s*\"\s*product\s*\-\s*images\s*\-\s*thumb">\s*[\w\W]*?\s*<\/div>)/is)
				{
					my $product_image=$1;	
					my $flag1=0;	
					while($product_image=~m/href\s*\=\s*\"([^>]*?)\s*\"/igs)
					{
						my $imageurl=$1;			
						# my $img_file = (split('\/',$imageurl))[-1];
						if($flag1 eq '0')
						{	
							my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='y';
							$flag1++;	
						}
						else
						{
							# print"\nimageurl------------->$imageurl\n";
							# print"\nimg_file------------->$img_file\n";	
							my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='n';				
						}	
					}
				}
				elsif($content10=~m/product\s*\-\s*images\s*\-\s*large\s*\">\s*[\w\W]*?\s*<a\s*href\s*\=\s*\"([^>]*?)\s*\"/is)
				{		
					my $imageurl=$1;
					# my $img_file = (split('\/',$imageurl))[-1];	
					# print"\nimageurl------------->$imageurl\n";
					# print"\nimg_file------------->$img_file\n";	
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
		
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='y';				
					
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
		#&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$mflag);
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:		
		print "";
			$dbh->commit();
	}
}1;
sub trim
{
	my $string=shift;
	$string=~s/<[^>]*?>/ /igs;
	$string =~ s/\&nbsp\;/ /gs;
	$string =~ s/^\s*n\/a\s*$//igs;
	$string =~ s/\&\#039\;/'/gs;
	$string =~ s/\&\#43\;/+/gs;
	$string =~ s/amp;//gs;
	$string=~s/\s+/ /igs;
	$string=~s/^\s+//is;
	$string=~s/\s+$//is;
	return($string);
}
sub get_content()
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
