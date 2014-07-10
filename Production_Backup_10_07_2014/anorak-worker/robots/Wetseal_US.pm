#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Wetseal_US;
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
sub Wetseal_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	# $dbh->do("set character set utf8");
	# $dbh->do("set names utf8");
	my @query_string;
	$robotname='Wetseal-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Wet';
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
		my $mflag=0;
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;	
		my $content2 = get_content($url3);
		if($content2=~m/you\s*are\s*looking\s*for\s*cannot\s*be\s*accessed\./is)
		{
			goto PNF;
		}
		if($content2=~m/\">\s*Product\s*is\s*not\s*available\s*</is)
		{
				goto PNF;
		}
		if($content2=~m/>\s*Page\s*not\s*Found\s*</is)
		{		
			goto PNF;
		}
		my $brand="Wetseal";
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my ($price,$price_text,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$price_msg);
		#product_name
		if ( $content2 =~ m/<h1\s*class\=\"product\-name\"\s*itemprop\=\"name\">\s*([^<]*?)\s*<\/h1>/is )
		{
			$product_name = &DBIL::Trim($1);
		}
		
		#price & price_text
		if( $content2 =~ m/product\-price\">\s*([\w\W]*?)<\/div>/is )
		{
			$price_text= &DBIL::Trim($1);
		}
		$price=$price_text;
		if($price_text=~m/Now\s*([^>]*?)$/is)
		{
			$price=$1;
		}
		if($price_text=~m/\$\s*([^>]*?)\-\s*[^>]*?$/is)
		{
			$price=$1;
		}
		$price=~s/^\W\s*//is;
		#if( $content2 =~ m/>([^>]*?)<\/span>\s*<\/span>\s*<\/strong>\s*<\/span>\s*<\/p>/is )
		if( $content2 =~ m/>([^>]*?)(?:\s*<\/strong>\s*)?<\/span>\s*<\/span>\s*(?:<\/strong>\s*)?<\/span>\s*(?:<\/strong>\s*)?(?:<\/p>|<\/div>)/is )
		{
			$price_msg= &DBIL::Trim($1);
		}
		elsif($content2=~m/class="promotion-callout"[^>]*?>\s*(?:<[^>]*?>\s*)*([^>]*?)</is)
		{
			$price_msg= &DBIL::Trim($1);
		}
		$price_text=$price_text.' '.$price_msg;
		$price_text=~s/\s+/ /igs;
		$price_text=~s/^\s*//is;
		$price_text=~s/\s*$//is;
		#if($price_text=~m/Additional\s*([^>]*?)\%\s*Off/is)
		#{
			#my $percentage=$1;
			#my $offer=($percentage*$price)/100;
			#my $offer_twodigit=sprintf("%0.2f",$offer);
			#my $new_price=$price-$offer_twodigit;
			#$price=$new_price;
		#}
		#product_id
		if( $content2 =~ m/Style\s*Number\:\s*<span\s*itemprop\=\"productID\"[^>]*?>\s*([^>]*?)\s*<\/span>/is )
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		
		#description
		# if ($content2 =~m/<div[^>]*?itemprop\=\"description\">\s*(?:\s*<a[^>]*?>\s*Print\s*<\/a>)?\s*<p>\s*([\w\W]*?)\s*<\/p>/is )
		if ($content2 =~m/<div[^>]*?itemprop\=\"description\">\s*(?:\s*<a[^>]*?>\s*Print\s*<\/a>)?\s*\s*([\w\W]*?)\s*(?:<\/p>|<br\s*\/>|<\/ul>)(?:([\w\W]*?)(?:<\/li>\s*<\/ul>|<\/div>))?/is )
		{		
			$description = &DBIL::Trim($1);			
			$prod_detail = &DBIL::Trim($2);
			$description=decode_entities($description);
			utf8::decode($description);
			$prod_detail=decode_entities($prod_detail);
			utf8::decode($prod_detail);		
		}

		#details
		# if ($content2 =~m/<div[^>]*?itemprop\=\"description\">\s*(?:\s*<a[^>]*?>\s*Print\s*<\/a>)?\s*<p>\s*[\w\W]*?\s*<\/p>\s*<p>([\w\W]*?)<\/li>\s*<\/ul>\s*<\/div>/is )
		# {		
			# $prod_detail=$1;
			# $prod_detail=~s/\\n/ /igs;
			# $prod_detail = &DBIL::Trim($prod_detail);
		# }

		# Size and Out of Stock
		my ($color,@color);
		my @color_id=();
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my $count=0;
		my $no_color_size=0;
		if($content2=~m/<ul\s*class\=\"swatches\s*Color\">\s*([\w\W]*?)\s*<\/ul>/is)
		{
			my $swacth_block=$1;
			$no_color_size=1;
			# while($swacth_block=~m/emptyswatch\">\s*<a[^>]*?\"([^>]*?)\"\s*title\=\"([^>]*?)\"/igs)
			while($swacth_block=~m/(?:emptyswatch\">|selected\">)\s*<a[^>]*?\"([^>]*?)\"\s*title\=\"([^>]*?)\"/igs)
			{
				my $swacth_color_url=$1;
				my $color=$2;
				$swacth_color_url=~s/\&amp\;/&/igs;
				my $swacth_cont=get_content($swacth_color_url);
				
				# Price for each swatch content, since price varies for each color.
				my ($price_text,$price,$price_msg);
				if( $swacth_cont =~ m/product\-price\">\s*([\w\W]*?)<\/div>/is )
				{
					$price_text= &DBIL::Trim($1);
				}
				$price=$price_text;
				if($price_text=~m/Now\s*([^>]*?)$/is)
				{
					$price=$1;
				}
				if($price_text=~m/\$\s*([^>]*?)\-\s*[^>]*?$/is)
				{
					$price=$1;
				}
				$price=~s/^\W\s*//is;
				#if( $content2 =~ m/>([^>]*?)<\/span>\s*<\/span>\s*<\/strong>\s*<\/span>\s*<\/p>/is )
				if( $swacth_cont =~ m/>([^>]*?)(?:\s*<\/strong>\s*)?<\/span>\s*<\/span>\s*(?:<\/strong>\s*)?<\/span>\s*(?:<\/strong>\s*)?(?:<\/p>|<\/div>)/is )
				{
					$price_msg= &DBIL::Trim($1);
				}
				elsif($swacth_cont=~m/class="promotion-callout"[^>]*?>\s*(?:<[^>]*?>\s*)*([^>]*?)</is)
				{
					$price_msg= &DBIL::Trim($1);
				}
				$price_text=$price_text.' '.$price_msg;
				$price_text=~s/\s+/ /igs;
				$price_text=~s/^\s*//is;
				$price_text=~s/\s*$//is;
				
				# Size for each swatch content.
				if($swacth_cont=~m/<ul\s*class\=\"swatches\s*size\">\s*([\w\W]*?)\s*<\/ul>/is)
				{
					my $swacth_size=$1;
					$swacth_size=~s/<li\s*class\=\"[^>]*?\"[^>]*?>\s*<a[^>]*?>\s*Size\s*Chart\s*<\/a>//igs;
					if($swacth_size=~m/<li\s*class\=\"[^>]*?\"[^>]*?>\s*<a[^>]*?>[^>]*?<\/a>/is)
					{
						while($swacth_size=~m/<li\s*class\=\"([^>]*?)\"[^>]*?>\s*<a[^>]*?>\s*([^>]*?)\s*<\/a>/igs)
						{
							my $select=&DBIL::Trim($1);
							my $size=$2;
							if($select=~m/unselectable/is)
							{
								$out_of_stock='y';
							}
							else			
							{
								$out_of_stock='n';
							}	
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=lc($color);
						}
					}
					else
					{
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'',$color,'n',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=lc($color);
					}	
				}
				$count++;
			}
		}
		# No size
		if(int($count)==0)
		{
			my $size='';
			my $color='';
			my $out_of_stock='';
			if(($price eq "")or($price=~m/\s*0\s*$/is))
			{
				$out_of_stock='y';
			}
			else
			{
				$out_of_stock='n';
			}
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=lc($color);
			
		}
		if($no_color_size==1)
		{
			my $count=0;
			while($content2=~m/<li>\s*<a\s*name\=\"product[^>]*?>\s*<img[^>]*?src\=\"([^>]*?)\"/igs)
			{
				my $alt_image=$1;
				$alt_image=~s/amp\;//is;
				my $cont=get_content($alt_image);
				next if($cont eq 1);
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				# if($alt_image=~m/a1/is)
				if($count==0)
				{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='';
						$hash_default_image{$img_object}='y';
						$count++;
						
				}	
				else
				{
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}='';
					$hash_default_image{$img_object}='n';
					
				}
			}
			undef $count;
		}
		
		# Image
		if($content2=~m/<ul\s*class\=\"swatches\s*Color\">\s*([\w\W]*?)\s*<\/ul>/is)
		{
			my $sw_block=$1;
			# while($sw_block=~m/emptyswatch\">\s*<a[^>]*?\"([^>]*?)\"\s*title\=\"([^>]*?)\"[^>]*?style\s*\=\"background\:\s*url\(([^>]*?)\)\;/igs)
			while($sw_block=~m/(?:emptyswatch\">|selected\">)\s*<a[^>]*?\"([^>]*?)\"\s*title\=\"([^>]*?)\"[^>]*?style\s*\=\"background\:\s*url\(([^>]*?)\)\;/igs)
			{
				my $sw_url=$1;
				my $color=$2;
				my $swatch= &DBIL::Trim($3);
				$sw_url=~s/\&amp\;/&/igs;	
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=lc($color);
				$hash_default_image{$img_object}='n';
				
				my $sw_cont=get_content($sw_url);
				# while($sw_cont=~m/<li\s*class\=\"thumb\s*(?:selected)?\">\s*<a\s*href\=([^>]*?)\s*target\=_blank\s*class\=\"thumbnail\-link\">/igs)
				my $count=0;
				while($sw_cont=~m/<li>\s*<a\s*name\=\"product[^>]*?>\s*<img[^>]*?src\=\"([^>]*?)\"/igs)
				{
					$alt_image=$1;
					$alt_image=~s/amp\;//is;
					my $cont=get_content($alt_image);
					next if($cont eq 1);	
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					# if($alt_image=~m/a1/is)
					if($count==0)
					{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							push(@query_string,$query);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=lc($color);
							$hash_default_image{$img_object}='y';
							$count++;
					}	
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=lc($color);
						$hash_default_image{$img_object}='n';
						
					}
				}
				undef $count;
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

		PNF:	
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
sub Trim
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
sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
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
		if ( $rerun_count <= 2 )
		{
			$rerun_count++;
			sleep(1);
			goto Home;
		}
	}
	return $content;
}
