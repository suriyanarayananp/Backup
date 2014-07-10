#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Riverisland_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
#use utf8;
use HTTP::Cookies;
use Encode;
use String::Random;
use WWW::Mechanize;
use DateTime;
use DBI;
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Riverisland_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;
	$robotname='Riverisland-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Riv';
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
	if($product_object_key)
	{		
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		my @query_string;
		my %prod_objkey;
		my $content2 = get_content($url3);
		$content2=decode_entities($content2);
		##### 40/50 code Page ##########
		if($content2=~m/>[^>]*?Product\s*Not\s*Found<\/h1>/is)
		{
			goto PNF;
		}
		if($content2 eq 1)
		{
			goto PNF;
		}
		my %tag_hash;
		my %size_hash;
		my ($price,$price_text,$brand,$sub_category,$item_no,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$id,$product_id);
		# id
		if($url=~m/[^>]*\-(\d+)\s*$/is)
		{
			$id=$1;
		}	
		#### Product_Name ##########
		if ( $content2 =~m/<h1>\s*([^>]*?)\s*<\/h1>/is )
		{
			$product_name= &DBIL::Trim($1);
					
		}
		###### Retailer_Product_Reference #######
		if ( $content2 =~m/>Product\s*no\s*\:\s*([^>]*?)</is )
		{
			$item_no=&DBIL::Trim($1);
			$product_id=$item_no;
		}
		if($item_no eq "")
		{
			$item_no=$id;
			$product_id=$item_no;
		}
		######### Price ##############
		if($content2=~m/<div[^>]*?price\">\s*(?:<span>\s*)?([\w\W]*?)<\/div/is)
		{
			$price_text= $1;
			# utf8::decode($price_text);
			# binmode STDOUT, ":utf8";
			#$price_text =~ s/<[^>]*?>|\Â/ /igs;
			#$price_text =~ s/\s+/ /igs;
			#$price_text =~ s/^\s+|\s+$//igs;
			# $price_text = decode_entities($price_text);
			$price_text=&DBIL::Trim($price_text);
			# $price_text=~s/(?:\h)+/ /gs;
			# $price_text=~s/\s+/ /igs;
			# $price_text=~s/^\s+//is;
			# $price_text=~s/\s+$//is;
			# $price_text=~s/Â/ /igs;
			# $price_text=~s/^Â//igs;
			# $price_text=~s/Â/ /igs;
			$price_text=~s/\&pound\;/\Â\£/igs;
			$price_text =~ s/\&\#163\;/\Â\£/igs;
			$price_text=~s/\£/\Â\£/igs;
			$price_text=~s/Was[^>]*?\£/Was \Â\£/igs;
			$price_text=~s/Now\s*\£/Now \Â\£/igs;
			$price= $price_text;
			if($price=~m/\W*(\d+\.\d+)\s*(?:\-|now)\s*\W*(\d+\.\d+)/is)
			{
				my $v1=$1;
				my $v2=$2;
				if($v1<$v2)
				{
					$price=$v1;
				}
				else
				{
					$price=$v2;
				}
			}		
			#$price_text=~s/\s*\-\s*$//is;
			$price=~s/[^\d\.]//gs;
			$price=~s/^\W//is;
			$price=~s/\£//is;
			$price=~s/Â/ /igs;
			$price=~s/^Â//igs;
			$price=~s/Â/ /igs;
			
			$price=&DBIL::Trim($price);
			print "Price-->$price-->$price_text\n";
			# $logger->send("Item $product_object_key collected price as $price -> $price_text @ $retailer_name");
			
		}
		#$content2=decode_entities($content2);
		##### Description ##########
		if ( $content2 =~ m/<meta\s*name\=\"description\"\s*content\=\"([^>]*?)\s*\"/is )
		{
			$description = &DBIL::Trim($1);
			$description=~s/\&\#39\;/'/igs;
			$description=decode_entities($description);			
		}
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		##### Image ############
		while($content2=~m/<img[^>]*?src\=\"([^>]*?)AltThumb[^>]*?>\s*(?:<\/a>\s*)?<\/li>/igs)	
		{
			my $alt_image="$1";
			my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product','riverisland-uk');
			if($alt_image=~m/main/is)
			{
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$product_id;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
			}	
			else
			{	
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$product_id;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}	
		}
		
		###### Product Detail #############
		if ( $content2 =~ m/<h\d+>Info\s*\&[^>]*?<\/h\d+>([\w\W]*?)<\/ul>/is )
		{
			$prod_detail = &DBIL::Trim($1);			
		}
		
		##### Swatch image ###############
		my $colour;
		my @col;
		if( $content2 =~ m/id\=\"swatches([\w\W]*?)<\/ul>/is )
		{
			my $b=$1;
			my $i=0;
			while($b=~m/<img\s*src\=\"([^>]*?)\"[^>]*?\=\"([^>]*?)\"/igs)
			{
				my $swatch=$1;
				$colour=$2;
				$col[$i]=$colour;
				my $color_id=$1 if($swatch=~m/RiverIsland\/(\d+)/is);
				if($swatch ne "")
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch','riverisland-uk');
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color_id;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
					#&DBIL::SaveTag('Color',lc($colour),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				}
				$i++;
			}
			while($b=~m/href\=\"([^>]*?)\"[^>]*?><[^>]*?alt\=\"([^>]*?)\"/igs)
			{
				my $col_url='http://www.riverisland.com'.$1;
				my $colours=$2;
				
				# Pattern match to take color id from swatch color url for sku image mapping.
				my $color_id=$1 if($col_url=~m/[^>]*\-(\d+)/is);
				my $col_cont=get_content($col_url);
				
				# Pattern match to check if size is avaialble or not.
				if($col_cont=~m/(?:<h\d+>|<option>\s*)SELECT\s*SIZE/is)
				{
					# Pattern match to take size block if size is available.
					while($col_cont=~m/SELECT\s*SIZE<\/option>([\w\W]*?)<\/select>/igs)
					{
						my $b=$1;
						
						# Loop to collect all the available sizes.
						while($b=~m/<option\s*value\=([^>]*?)>\s*([^>]*?)\s*</igs)
						{
							my $block=$1;
							my $size=&DBIL::Trim($2);
							my $out_of_stock;
							if($block=~m/disable/is)
							{
								$out_of_stock='y';
							}
							else
							{
								$out_of_stock='n';
							}		
							
							# Save the collected sku in sku table.
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colours,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color_id;
							push(@query_string,$query);
							
							
						}
					}
				}
				# This block execute when multiple size is not available.
				else
				{
					my $out_of_stock;
					my $size='One Size';
					if($price)
					{
						$out_of_stock='n';
					}
					else
					{
						$out_of_stock='y';
					}
					
					# Save the collected sku in sku table.
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colours,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color_id;
					push(@query_string,$query);
					
				}
				
				# Loop to collect all the product images for different swatch color.
				while($col_cont=~m/<img[^>]*?src\=\"([^>]*?)AltThumb[^>]*?>\s*(?:<\/a>\s*)?<\/li>/igs)	
				{
					my $alt_image="$1";
					
					# Downloading and save entry for product images.
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product','riverisland-uk');
					if($alt_image=~m/main/is)
					{
						
						# Save entry to Image table ,if image download is successful. Otherwise throw error in log.
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_id;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
						
					}	
					else
					{	
						# Save entry to Image table ,if image download is successful. Otherwise throw error in log.
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color_id;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
						
						
					}	
				}
			}
		}
		if($colour eq "")
		{
			$colour='No raw colour';
		}

		# Size & Out_of_stock
		if($content2=~m/(?:<h\d+>|<option>\s*)SELECT\s*SIZE/is)
		{
			while($content2=~m/SELECT\s*SIZE<\/option>([\w\W]*?)<\/select>/igs)
			{
				# my $s=&DBIL::Trim($1);
				my $b=$1;
				while($b=~m/<option\s*value\=([^>]*?)>\s*([^>]*?)\s*</igs)
				{
					my $out_of_stock;
					my $size=&DBIL::Trim($2);
					my $block=$1;
					if($block=~m/disable/is)
					{
						$out_of_stock='y';
					}
					else
					{
						$out_of_stock='n';
					}	
					if($col[0] eq "")
					{
						$col[0]='No raw colour';
					}
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$col[0],$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$product_id;
					push(@query_string,$query);
				}
			}
		}
		else
		{
			my $out_of_stock;
			my $size='One Size';
			if($price)
			{
				$out_of_stock='n';
			}
			else
			{
				$out_of_stock='y';
			}
			if($col[0] eq "")
			{
				$col[0]='No raw colour';
			}
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$col[0],$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$product_id;
			push(@query_string,$query);
		}
		undef $colour;
		undef @col;
		##### Sku_has_Image ############
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
		push(@query_string,$query1);
		push(@query_string,$query2);
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		$dbh->commit();	
	}	
}1;

sub get_content
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	home:
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
		return($content);
	}
	elsif($code =~m/40/is)
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(5);
			goto home;
		}
		return 1;
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(1);
			goto home;
		}
		return 1;
	}
}
