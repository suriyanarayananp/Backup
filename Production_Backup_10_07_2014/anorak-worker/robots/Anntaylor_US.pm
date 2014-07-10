#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Anntaylor_US;
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

###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Anntaylor_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Anntaylor-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Ann';
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
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.anntaylor.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = get_content($url3);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		#price_text
		if ( $content2 =~ m/class\=\"dollars\">\s*([^>]*?)\s*<\/sup>\s*([^>]*?)\s*(?:<\/span>|<\/div>)[\w\W]*?class\=\"dollars\">\s*([^>]*?)\s*<\/sup>\s*([^>]*?)\s*<sup[^>]*?>(?:([^>]*?))?\s*</is )
		{
			$price_text = "Was ".&DBIL::Trim($1).&DBIL::Trim($2)." Sale ".&DBIL::Trim($3).&DBIL::Trim($4).&DBIL::Trim($5);
		}
		elsif($content2 =~ m/class\=\"dollars\">\s*([^>]*?)\s*<\/sup>\s*([^>]*?)\s*<sup[^>]*?>(?:([^>]*?))?\s*</is)
		{
			$price_text = &DBIL::Trim($1).&DBIL::Trim($2).&DBIL::Trim($3);
		}
		#price
		if ( $content2 =~ m/class\=\"dollars\">\s*([^>]*?)\s*<\/sup>\s*([^>]*?)\s*<sup[^>]*?>(?:([^>]*?))?\s*</is )
		{
			$price = &DBIL::Trim($2).&DBIL::Trim($3);
		}
		elsif ( $content2 =~ m/<p\s*class\=\"product_price\s*\">[\w\W]*?<span\s*class\=\"nowPrice\">[\w\W]*?;([^>]*?)<\/span><\/p>/is )
		{
			$price = &DBIL::Trim($1);
			
		}
		if($price eq "")
		{
			$price='null';
		}
		#product_id
		if ( $content2 =~ m/>\s*style\s*\#*([^<]*?)\s*</is)
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname, $retailer_id);
			goto end if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if ( $content2 =~ m/<h1[^>]*?>([\w\W]*?)<\/h1>/is)
		{
			$product_name = &DBIL::Trim($1);
			$product_name=&clear($product_name);
		}
		#description&details
		if ( $content2 =~ m/class\=\"gu\sdescription\"[\w\W]*?<p>([^>]*?)<\/p>/is )
		{
			$description = &DBIL::Trim($1);
			$description=&clear($description);
		}
		if( $content2 =~ m/class\=\"gu\sgu\-first\sdescription\"[\w\W]*?<p>([^>]*?)<\/p/is )
		{
			$description = &DBIL::Trim($1);
			$description=&clear($description);
		}
		$description=~s/\&quot\;/"/igs;
		my $pdetailcon;
		if($content2 =~ m/class\=\"details\">([\w\W]*?)<a/is)
		{
			$pdetailcon=$1;
		}
		while ($pdetailcon =~ m/<p>([^>]*?)<\/p>/igs )
		{
			$prod_detail .=&DBIL::Trim($1);
			$prod_detail=~s/\&quot\;/"/igs;
		}
		#colour
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key,%imageHash,%swatchHash);
		my $color;
		while($content2 =~ m/<li\sid\=\"color([^>]*?)\"[\w\W]*?id\=\"colorName\"\s*value\=\'([^>]*?)\'/igs)
		{
			my $color_code 	= &DBIL::Trim($1);
			$color 		= &DBIL::Trim($2);
			$color_hash{$color_code} = &DBIL::Trim($color);
		}
		# size & out_of_stock
		my @holesize;
		my $y=0;
		my $tid=0;
		while($content2 =~ m/<li\sid\=\"([\w\W]*?)\"[\w\W]*?class\=\"size[\w\W]*?\"/igs)
		{
			$holesize[$y]=&DBIL::Trim($1);
			$y++;
		}
		if($content2 =~ m/type\=\"radio\"/is)        
		{
			if($content2 =~ m/id\=\"fs\-size\"/is)
			{
				my $protype;
				if($content2 =~ m/\&productPageType\=([^>]*?)\&/is)
				{
					$protype=$1;
				}
				while($content2 =~ m/rel\=\'([\w\W]*?)\'[\w\W]*?type\=\"radio\"[\w\W]*?>\s*([^>]*?)\s*\&/igs)
				{
					my $rel=$1;
					my $type=$2;
					my($id,$cat)=split('\$_\$',$rel);
					my $cul="http://www.anntaylor.com/catalog/skuColor.jsp?prodId=$id&imageId=productImage&skuId=$cat&productPageType=$protype&imageId=&colorExplode=false";
					my $clcontent=get_content($cul);
					while($clcontent =~ m/<li\sid\=\"color([^>]*?)\"[\w\W]*?id\=\"colorName\"\s*value\=\'([^>]*?)\'/igs)
					{
						my $clcode=&DBIL::Trim($1);
						my $col=&DBIL::Trim($2);
						my $url4="http://www.anntaylor.com/catalog/skuSize.jsp?prodId=$id&colorCode=$clcode&sizeCode=&imageId=productImage&skuId=$cat&productPageType=$protype&colorExplode=false";
						my $sizecont=get_content($url4);
						while($sizecont=~ m/class\=\"size([\w\W]*?)\"/igs)
						{
							my $stock_text=&DBIL::Trim($1);
							my $size=$type."-".$stock_text;
							my $out_of_stock = 'n';
							if($1=~ m/^([^>]*?)\sdisable/is)
							{
								$out_of_stock = 'y';
								$size=$type."-".$1;
							}
							$col=&ProperCase($col);
							$col=~s/\-(\w)/-\u\L$1/is;
							sub ProperCase {
							    join(' ',map{ucfirst(lc("$_"))}split(/\s/,$_[0]));
							}
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$col,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$clcode;
							push(@query_string,$query);
						}
						if($col ne '')
						{
							#&DBIL::SaveTag('Color',lc($col),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
						}
					}
				}
			}
		}
		elsif($content2 =~ m/id\=\"fs\-size\"/is)
		{			
			my ($id,$cat,$protype);
			if($content2 =~ m/productId\s\:\s\"([^>]*?)\"/is)
			{
				$id=&DBIL::Trim($1);
			}
			if($content2 =~ m/name\=\"skuId\"[\w\W]*?value\=\"([^>]*?)\"/is)
			{
				$cat=$1;
			}
			if($content2 =~ m/\&productPageType\=([^>]*?)\&/is)
			{
				$protype=$1;
			}
			my @color_code = keys %color_hash;
			foreach my $code (@color_code)
			{	
				my $url4="http://www.anntaylor.com/catalog/skuSize.jsp?prodId=$id&colorCode=$code&sizeCode=&imageId=productImage&skuId=$cat&productPageType=$protype&colorExplode=false";
				my $content4=get_content($url4);
				while($content4=~ m/class\=\"size([\w\W]*?)\"/igs)
				{
					my $stock_text=&DBIL::Trim($1);
					my $size=$stock_text;
					my $out_of_stock = 'n';
					if($1=~ m/^([^>]*?)\sdisable/is)
					{
						$out_of_stock = 'y';
						$size=$1;
					}
					$color_hash{$code}=&ProperCase($color_hash{$code});
					$color_hash{$code}=~s/\-(\w)/-\u\L$1/is;
					sub ProperCase {
					    join(' ',map{ucfirst(lc("$_"))}split(/\s/,$_[0]));
					}
					if($price eq "")
					{
							$price='null';
					}
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_hash{$code},$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$code;
					push(@query_string,$query);
				}
				if($color_hash{$code} ne '')
				{
					#&DBIL::SaveTag('Color',lc($color_hash{$code}),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				}
			}
		}
		else
		{	
			# $tid=0;
			if($content2 =~ m/<p\s*class\=\"msg\-productNotFound\">/is)
			{
				$out_of_stock='y';
			}
			if($price eq "")
			{
					$price='null';
			}
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'',$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$sku_objectkey{$sku_object}='No Color';
			push(@query_string,$query);
			if($color ne '')
			{
				#&DBIL::SaveTag('Color',lc($color),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			}
			$tid++;
		}
		###image
		
		if($content2 =~ m/<img\s*src\=\"([^>]*?)\&recipeName/is)
		{
			
			my $imge=&DBIL::Trim($1);
			my $sid = $1 if($imge=~ m/\&swatchID\=(\d+)$/is);
			my @url;
			if($imge=~ m/itemID\=([^>]*?)\&/is)
			{
				my $itemid=$1;
				my $imageurl="http://richmedia.channeladvisor.com/ViewerDelivery/productXmlService?profileid=52000652&itemid=".$itemid."&viewerid=270&callback=productXmlCallbackImageColorChangeprofileid52000652itemid."."$itemid";
				my $alt_image_page_cont = get_content($imageurl);
				$alt_image_page_cont = decode_entities($alt_image_page_cont);
				while($alt_image_page_cont=~ m/\"\@id\"\:\s*\"\d+\"\,\s*\"\@path\"\:\s*\"([^>]*?)\&recipeId\=114\"\s*\,\s*\"\@internalName\"\:\s*\"(\d+)\"/igs)
				{
					# $swatchHash{$1} = $2;
					$swatchHash{$2} = $1;
				}
				
				while($alt_image_page_cont=~ m/\"\@externalName\"\:\s*\"(\d+)\"\s*[^>]*?\"\@type\"\:\s"[^>]*?\"\,\s*\"\@path\"\:\s*"([^>]*?)\&recipeId/igs)
				{
					push(@url,$2);
					$imageHash{$2} = $1;
					# $imageHash{$1} = $2;
				}
			}
			my @a;
			foreach (keys %swatchHash)
			{
				my $key = $_;
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatchHash{$key},'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatchHash{$key},$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				if($tid==0)
				{
					$image_objectkey{$img_object}=$key;
				}
				else				
				{
					$image_objectkey{$img_object}='No Color';
				}
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
				push(@a,$key);
			}
			my $tot=@a;
			my $count=1;
			my $i=0;
			foreach (keys %imageHash)
			{
				my $key = $url[$i];
				my ($imgid,$img_file) = &DBIL::ImageDownload($key,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$key,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				if($tid==0)
				{
					$image_objectkey{$img_object}=$imageHash{$key};
				}
				else				
				{
					$image_objectkey{$img_object}='No Color';
				}
				if($count<=$tot)
				# if($imageHash{$key} eq $sid)
				{
					$hash_default_image{$img_object}='y';
					$count++;
				}
				else
				{
					$hash_default_image{$img_object}='n';
				}
				push(@query_string,$query);
				$i++;
			}
		}
		# Sku_has_Image
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		end:
			print "";
		$dbh->commit();
	}
}1;

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
		$content = $res->content;
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep 1;
			goto Home;
		}
	}
	return $content;
}
sub clear()
{
 my $text=shift;
 
 $text=~s/<li[^>]*?>/*/igs;
 $text=~s/&quot/"/igs; 
 $text=~s/â€/”/igs;
 $text=~s/\&\#39\;/'/igs;
 # $text=~s/â€“/–/igs;
 # $text=~s/â€˜/‘/igs;
 # $text=~s/â€¦/…/igs;
 $text=decode_entities($text);  
 return $text;
}