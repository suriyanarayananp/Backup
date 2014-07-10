#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Express_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use URI::Escape;
use DBI;
use DateTime;

# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Express_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Express-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Exp';
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
		$url3='http://www.express.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &getcont($url3);
		##### Multi Item Page #######
		if($content2 =~ m/quantity\"\:\s*\d+\s*\}\,\{\s*\"id\"/is)
		{
			$mflag=1;
			my $product_name;
			if ( $content2 =~ m/>\s*([^>]*?)\s*<\/h1>/is )
			{
					$product_name = &DBIL::Trim($1);
			}
			goto noinfo;
		}	
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		# Product_ID
		if($url3=~m/pro\/(\d[^>]*?)\//is)
		{
			$product_id=$1;
		}
		
		my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
		goto end if($ckproduct_id == 1);
		undef ($ckproduct_id);
		##### Price ########
		my ($price1,$price2,$price3,$pr1,$pr2,$pr3,$price_text,$pr);
		if ( $content2=~m/cat\-glo\-tex\-oldP\">\s*([^>]*?)<\/span>\s*<[^>]*?>\s*<[^>]*?>\s*<[^>]*?\s*content\=\"USD\">\&\#36\;<\/span><[^>]*?\=\"price\">([^>]*?)<\/span>\s*<\/span>\s*-\s*([^>]*?)<\/span>*/is)
		{
			$price1 = &DBIL::Trim($1);
			$price2 = &DBIL::Trim($2);
			$price3 =&DBIL::Trim($3);
			#$pr =~ s/\&\#36\;/\$/igs;
			$price1=~ s/\&\#36\;//igs;
			$price2=~ s/\&\#36\;//igs;
			$price3=~ s/\&\#36\;//igs;
			if($price1 ge $price2 && $price1 ge $price3)
			{
				$pr2=$price1;
			}
			elsif($price2 ge $price1 && $price2 ge $price3)
			{
				$pr2=$price2;
			}
			elsif($price2 ge $price1 && $price2 ge $price3)
			{
				$pr2=$price3;
			}
			
			if($price1 < $price2 && $price1 < $price3)
			{
				$pr1=$price1;
			}
			elsif($price2 < $price1 && $price2 < $price3)
			{
				$pr1=$price2;
			}
			elsif($price3 < $price1 && $price3 < $price2)
			{
				$pr1=$price3;
			}
			$price1=~s/$price1/\$ $price1/igs;
			$price2=~s/$price2/\$ $price2/igs;
			$price3=~s/$price3/\$ $price3/igs;
			$price_text="$price1-$price2-$price3";
			$price=$pr1;
				
		goto neprice;
		}
		if ( $content2=~m/content\=\"USD\">\s*([\w\W]*?\s*<\/span>\s*<\/span>\s*\-\s*[^>]*?)</is)
		{
			$price_text = &DBIL::Trim($1);
			$price='null';
			$price_text =~ s/\&\#36\;/\$/igs;
			# print"price with -";
			if($price_text=~m/(\d+\.\d+)[^>]*?(\d+\.\d+)/is)
			{
				my $v1=$1;
				my $v2=$2;
				if($v1>$v2)
				{
					$price=$v2;
				}
				else
				{
					$price=$v1;
				}
			}
			# $price_text =~ s/\&\#36\;//igs;
			goto neprice;
		}
		elsif ( $content2=~m/content\=\"USD\">\s*([\w\W]*?)\s*<\/span>\s*<\/strong>\s*/is)
		{
			$price_text = &DBIL::Trim($1);
			$price = &DBIL::Trim($1);
			$pr=&DBIL::Trim($1);
			$price_text =~ s/\&\#36\;/\$/igs;
			$pr =~ s/\&\#36\;/\$/igs;
			$price =~ s/\&\#36\;//igs;
			
		}
		#price_text
		if ( $content2 =~ m/<span\s*class\=\"cat\-glo\-tex\-oldP\">\s*([^>]*?)\s*<\/span>/is )
		{
			$price_text = &DBIL::Trim($1);
			$price_text =~ s/\&\#36\;/\$/igs;
			$price_text=$price_text.'-'.$pr;
			$price =~ s/\$//ig;
		}
		elsif($content2=~m/font\-weight\:normal\">([^>]*?)<\/font>/is)
		{
			$price_text = &DBIL::Trim($1);
			$price_text =~ s/\&\#36\;/\$/igs;
			$price_text=$pr.'-'.$price_text;
			$price =~ s/\$//ig;
			$price_text =~ s/^\-/\$/ig;
			$price_text =~ s/\-$//ig;
			
		
		}
		$price =~ s/^\s*|\s*$//ig;
		neprice:
		#product_name
		if ( $content2 =~ m/<meta\s*property\=\"og\:title\"\s*content\=\"([^\"]*)\"\s*\/>/is )
		{
			$product_name = &DBIL::Trim($1);
		}
		
		#brand not available in page;
		my $brand;
		
		if ( $content2 =~m/\"description\">\s*([\w\W]*?)\s*<ul>([\w\W]*?)<\/ul>/is )
		{
				$description=&DBIL::Trim($1);
				$prod_detail = $2;
				$prod_detail=~s/<\/li>\s*<li>/\n* /igs;
				$prod_detail=~s/\&\#39\;/\'/igs;
				$prod_detail=~s/Â//igs;
				$prod_detail=~s/®//igs;
				$description=~s/\&\#39\;/'/igs;
				$description=~s/\&quot\;/\"/igs;
				$prod_detail=&DBIL::Trim($prod_detail);			
		}
	
		#color_size
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		my ($swatch,$colors);
		my @keys;
		if($url3=~m/http\:\/\/www\.express\.com([\w\W]*?\/([^\/]*)\/(cat[\d]*))/is)
		{
			my $ss_url=uri_escape($1);
			my $id_1=$2;
			my $id_2=$3;
			
			my $post_cont='productId='.$id_1.'&url='.$ss_url.'&selectedColor=&categoryId='.$id_2.'&commerceitemId=&selectedFacetColor=';
			my $url_color='http://www.express.com/catalog/gadgets/color_size_gadget.jsp?'."$post_cont";
			
			my $color_cont=&getcont($url_color);
			
			#color
			while($color_cont=~m/<img\s*class\=\"[^\"]*?\"\s*src\=\"([\w\W]*?_s\?\$swatch\$)\"[\w\W]*?alt="([^\"]*)\"\s*\/>/igs)
			{
				$swatch 	= &DBIL::Trim($1);
				$colors=&DBIL::Trim($2);
				unless($swatch=~m/^\s*http\:/is)
				{
					$swatch='http:'.$swatch;
				}
				$color_hash{$colors}=$swatch;
			}
			
			#size_&_outofstock
			
			 @keys = keys %color_hash;
			
			my $size=@keys;
			
			print "Size::$size";
			#single_color
			if($size== 1)
			{
				my $color_1;
				if($color_cont=~m/<span\s*class\=\"selectedColor\">\s*([\w\W]*?)\s*<\/span>/is)
				{
					$color_1=$1;
					#&DBIL::SaveTag('Color',lc($color_1),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
					
				}
				while($color_cont=~m/(?:<option\s*class\=\"availableSize\"\s*value\=\"[^\"]*\">|<option\s*id\=\"selectedSize\"[^>]*?>)\s*([\w\W]*?)\s*<\/option>/igs)
				{
					my $size=&DBIL::Trim($1);
					
					
					if ($size=~m/([^>]+)\s*(\$[^>]*?)(?:\s*\-\s*[^>]*?)?$/is)
						{
						$size=&DBIL::Trim($1);
						$price = &DBIL::Trim($2);
						$price =~ s/\&\#36\;//igs;
						$price =~ s/\$//igs;
						}
						elsif($size=~m/([^>]*?)\s*\-\s*[^>]*?/is)
						{
						$size=&DBIL::Trim($1);
						}
						
						
					my $out_of_stock='n';
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color_1,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color_1;
					push(@query_string,$query);			
				}
						
			}
			elsif($size== 0)
			{
				my $size='';
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
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}="$color";
				push(@query_string,$query);
				if($content2=~m/og\:image\"\s*content\=\"[^>]*?\/expressfashion\/([^>]*?)\?/is)
				 {
					my $id=$1;
					my $img_url='http://images.express.com/is/image/expressfashion/'.$id.'?req=set,json';
					my $img_cont=&getcont($img_url);
					my $count=0;
					while($img_cont=~m/\{\"i\"\:\{\"n\"\:\"([^>]*?)\"\}/igs)
					{
						my $image_url="http://images.express.com/is/image/"."$1";
						$count++;
						my ($imgid,$img_file) = &DBIL::ImageDownload($image_url,'product','express-us');
						if ( $count == 1 )
						{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}="$color";
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						else
						{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}="$color";
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}	
					}
				}	
			
			}
			else
			{
				#mutiple_color
				foreach my $color(keys %color_hash)
				{
					my $post_zize='selectedColor='.$color.'&selectedSize=&productId='.$id_1.'&commerceitemId=&quantity=1';
					my $url_zize='http://www.express.com/catalog/gadgets/color_size_gadget.jsp?'."$post_zize";
					
					my $size_cont=&getcont($url_zize);
					while($size_cont=~m/(?:<option\s*class\=\"availableSize\"\s*value\=\"[^\"]*\">|<option\s*id\=\"selectedSize\"[^>]*?>)\s*([\w\W]*?)\s*<\/option>/igs)
					{
						my $size=&DBIL::Trim($1);
						if ($size=~m/([^>]+)\s*\$([^>]*?)(?:\s*\-\s*[^>]*?)?$/is)
						{
						$size=&DBIL::Trim($1);
						$price = &DBIL::Trim($2);
						$price =~ s/\&\#36\;//igs;
						$price=~s/\$//igs;
						$price =~ s/^\W*//igs;
						}
						elsif($size=~m/([^>]*?)\s*\-\s*[^>]*?/is)
						{
						$size=&DBIL::Trim($1);
						}
						
						my $out_of_stock='n';
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
					#&DBIL::SaveTag('Color',lc($color),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
					
				}
			}
		}
		### No size	 & Colour ########
		else
		{
			my $size='';
			my $color='';
			my $out_of_stock='';
			if($price ne "")
			{
				$out_of_stock='n';
			}
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$color;
			push(@query_string,$query);
		}
		#Swatch Image
		my $i=0;
		foreach my $swatchs(values %color_hash)
		{
			$keys[$i];
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatchs,'swatch','express-us');
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatchs,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$keys[$i];
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
			
			$i++;
		}
		#Imges
		my $imp=0;
		my $i=0;
		foreach my $img_url(values %color_hash)
		{
			my $imp;
			$keys[$i];
			if($img_url=~m/expressfashion\/(\d[^>]*?\d)\ws\?/is)
			{
				my $img_colr_id=$1;
			
				my $img_color_url='http://images.express.com/is/image/expressfashion/'.$img_colr_id.'?req=set,json';
				
				my $img_color_cont=&getcont($img_color_url);
			
				while($img_color_cont=~m/\{\"i\"\:\{\"n\"\:\"([^>]*?)\"\}/igs)
				{
					my $final_img_url="http://images.express.com/is/image/".$1;
				
					$imp++;
				
					my ($imgid,$img_file) = &DBIL::ImageDownload($final_img_url,'product','express-us');
					if ( $imp == 1 )
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$final_img_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$keys[$i];
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$final_img_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$keys[$i];
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}
			}
			$i++;
		}
		### Sku_has_Image #####
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
		noinfo:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
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

sub getcont()
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
			sleep 5;
			goto Home;
		}
	}
	return $content;
}
