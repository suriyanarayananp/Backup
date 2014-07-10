#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Delias_US;
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
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Delias_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Delias-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Del';
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
		my $content2 = &get_content($url3);
		if($content2=~m/you\s*are\s*looking\s*for\s*cannot\s*be\s*accessed/is)
		{
			print "\n$1\n";
			goto PNF;
		}
		if($content2=~m/Matching\s*(?:Bottom|tops)/is)
		{
			$mflag=1;
			# goto PNF;
		}
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);
		#product_name
		
		if ( $content2 =~ m/ProductName\"[^>]*?>\s*([^<]*?)\s*</is )
		{
			$product_name = &DBIL::Trim($1);
			$product_name=~s/\'|\'//igs;
		}
		elsif ( $content2 =~ m/detailheader\">\s*(?:<[^>]*?>\s*)?\s*([^<]*?)\s*</is )
		{
			$product_name = &DBIL::Trim($1);			
			$product_name=~s/\'|\'//igs;
		}
		
		#price & price_text
		if ( $content2 =~ m/productPricing\"[^>]*?>\s*([\w\W]*?)<\/tr>/is )
		{
			$price_text = &DBIL::Trim($1);
			$price = &DBIL::Trim($1) if($price_text=~m/pricesale\s*>\s*([^>]*?)\s*</is);
		}
		elsif( $content2 =~ m/detailPrice\"[^>]*?\s*>\s*(?:(?:<[^>]*?>\s*)*)(Was\:\s*(?:(?:<[^>]*?>\s*)*)\W*[^<]*?(?:(?:<[^>]*?>\s*)*)Now\:\s*(?:(?:<[^>]*?>\s*)*)\W*([^<]*?))</is )
		{
			$price_text = &DBIL::Trim($1);
			$price = &DBIL::Trim($2);
		}
		$price ='null' if($price eq "");
		
		#product_id
		if( $content2 =~ m/ProductCode\">\s*([^<]*?)\s*</is )
		{
			$product_id =&DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST  if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#description
		if ( $content2 =~ m/ProductLong\">\s*<div[^>]*?>\s*(?:<[^>]*?>\s*)?\s*([^<]*?)\s*</is )
		{		
			$description =&DBIL::Trim($1);		
			$description=~s/\'|\'//igs;			
		}

		#details
		if ( $content2 =~ m/dhtmlFlyopen1\(event\,\s*\'([\w\W]*?)\'\,[^>]*?\)\">\s*More\s*</is )
		{		
			$prod_detail=$1;
			$brand=$1 if($prod_detail=~m/<li>\s*(?:<[^>]*?>\s*)*by\s*([^>]*?)\s*</is);
			$prod_detail=~s/\\n/ /igs;
			$prod_detail =&DBIL::Trim($prod_detail);
			$prod_detail=~s/\'|\'//igs;
			$brand=~s/\'|\'//igs;			
		}		
		
		# size & out_of_stock
		my (@color_id,@sid);
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		if($content2=~m/<div[^>]*?SwatchContainer[^>]*?>[\w\W]*?<\/div>/is)
		{
			my $swatch_content=$&;
			while($swatch_content =~ m/optionswatch_(\w+)_[^>]*?\"\s*title\=\"([^>]*?)\"\s*src\=\"([^>]*?)\"[^<]*?SwatchClick\(event,\s*\'[^>]*?\,\s*([^>]*?)\,[^>]*?>/igs)
			{
				my $img_id=$1;
				my $color_name=$2;
				my $swatch_url=$3;
				my $colorid=$4;
				my $imgurl_code=&image_code($swatch_url);
				if($imgurl_code=~m/200/is)
				{
					push(@sid,$img_id);
					push(@color_id,"$colorid,$color_name");
				}
			}
		}
		else
		{
			my $size2='';
			$color='';
			my $out_of_stock;		
			if($price eq '')
			{
				$out_of_stock = 'y';	
			}
			elsif($content2=~m/<div\s*class\=\"NoActiveSku/is)
			{
				$out_of_stock = 'y';
			}
			else
			{
				$out_of_stock = 'n';	
			}
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size2,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}='';
			push(@query_string,$query);	
		}
		
		my $i=0;
		for my $color_id(@color_id)
		{
			$color=$color_id;
			$color=~s/(.*)\,\s*(.*)/$2/igs;
			$color_id=~s/(.*),\s*(.*)/$1/igs;
			my $block;
			if($content2 =~m/<\/script>\s*<script\s*type\=\'text\/javascript\'>\s*(MarketLive\.P2P\.buildDependent[\w\W]*?)\s*<\/script>/is)
			{
				$block=$1;
				my $price_text1;
				while($block=~ m/\{\"0\"\:\{\"iOptionPk\"\:\"$color_id\"\}\,\"1\"\:\{\"iOptionPk\"\:\"(\d+)\"\}(?:\,\"2\"\:\{\"iOptionPk\"\:\"(\d+)\"\})?\}[^>]*?skuPrice\"\:\"([^>]*?)\"/igs)
				{			
					my $size_id=$1;
					my $inch_id=$2;
					$price=$3;
					$price_text1=$price;
					$price=~s/\s*\$\s*//igs;
					$price_text1="$price_text" if($price_text1 eq "");
					if($content2=~m/OptionPk\"\:\"$size_id\"\,\"sOptionName\"\:\"([^>]*?)\"\}/is)
					{
						my $size =&DBIL::Trim($1);
						$size=~s/\\//is;
						my $out_of_stock;		
						$out_of_stock = 'n';			
						if($content2=~m/OptionPk\"\:\"$inch_id\"\,\"sOptionName\"\:\"([^>]*?)\"\}/is)
						{
							my $inch =&DBIL::Trim($1);
							$inch=~s/\\//is;
							my $size2="size ".$size."-".$inch;
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size2,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$sid[$i];
							push(@query_string,$query);			
						}
						if($inch_id== '')
						{
							my $out_of_stock;		
							$out_of_stock = 'n';
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$sid[$i];
							push(@query_string,$query);
						}		
					}
				}
			}
			$i++;
		}
		
		# swatchimage
		my $swatch_image_count=0;
		if($content2=~m/<div[^>]*?SwatchContainer[^>]*?>\s*([\w\W]*?)\s*<\/div>/is)
		{
			my $swatch_content=$1;
			while ( $swatch_content =~ m/optionswatch[^>]*?\"\s*title\=\"[^>]*?\"\s*src\=\"([^>]*?)\"[^<]*?SwatchClick\(event,\s*\'([^>]*?)\'\,\s*[^>]*?\,[^>]*?>/igs )
			{
				my $swatch = &DBIL::Trim($1);	
				my $id=$2;
				my $image_code=&image_code($swatch);
				if($image_code=~m/200/is)
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$id;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}	
			}
		}

		#Image
		my @image_id;
		if($content2=~m/<div[^>]*?SwatchContainer[^>]*?>[\w\W]*?<\/div>/is)
		{
			push(@image_id,@sid);
			# my $swatch_content=$&;
			# while ( $swatch_content =~ m/optionswatch[^>]*?\"\s*title\=\"[^>]*?\"\s*src\=\"[^>]*?\"[^<]*?SwatchClick\(event,\s*\'([^>]*?)\'\,\s*[^>]*?\,[^>]*?>/igs )
			# {
				# my $im_id=$1;
				# push(@image_id,$im_id);
			# }
		}
		else
		{
			if($content2=~m/>\s*(var\s*detailImgMapJson_[\w\W]*?)\}\;/is)
			{
				my $block=$1;
				my $id=1;
				while($block=~m/(http[^>]*?wid=415&cvt=jpeg)/igs)
				{
					my $alt_image =&DBIL::Trim($1);
					my $img_file;
					$alt_image =~ s/\\\//\//g;
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}='';
					push(@query_string,$query);
					if($id eq 1)
					{
						$hash_default_image{$img_object}='y';
					}
					else
					{
						$hash_default_image{$img_object}='n';
					}
					$id++;
				}
			}
			goto skipimage;
		}
		
		foreach my $img_id(@image_id)
		{
			my $image_count=0;
			while($content2=~m/<a\s*id\=\"altview_([A-z]+)\"\s*href(?:x)?\=\'([^\']*?)\'[^>]*?smallImage\:\s*\'([^>]*?)\'\"\s*>/igs)
			{
				my $image_alt_id=$1;
				if ( $content2 =~ m/detailImgMapJson_\d+\s*\=\s*\{([^<]*?)\}/is )
				{
					my $detailed_image_content=$1;
					while ($detailed_image_content=~ m/\"($img_id\:$image_alt_id)\"\:\"([^<]*?)\"/igs )
					{
					
						my $image_type = $1;		
						my $alt_image =&DBIL::Trim($2);
						my $img_file;
						$alt_image =~ s/\\\//\//g;		
						my $id;
						if($alt_image=~m/\/\d+_(\w+)_/is)
						{
							$id=$1;
						}					
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						if($image_alt_id eq 'std')
						{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$id;
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
						else
						{
							$image_count++;
							if ($image_count eq 1 )
							{
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$id;
								$hash_default_image{$img_object}='y';
								push(@query_string,$query);
							}
							elsif($image_count gt 1)
							{
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$id;
								$hash_default_image{$img_object}='n';
								push(@query_string,$query);
							}
						}
					}
				}
			}
		}

		#----------------------------------	
		if ( $content2 =~ m/detailImgMapJson_\d+\s*\=\s*\{([^<]*?)\}/is )
		{
			my $detailed_image_content=$1;
			if ($detailed_image_content=~ m/(?:default)\"\:\"([^<]*?)\"/is )
			{
				my $alt_image =&DBIL::Trim($1);
				my $img_file;
				$alt_image =~ s/\\\//\//g;
				my $id;
				if($alt_image=~m/\/\d+_(\w+)_/is)
				{
					$id=$1;
				}
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$id;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}		
		}	
		skipimage:
		if($content2!~m/<a\s*id\=\"altview_([A-z]+)\"\s*href(?:x)?\=\'([^\']*?)\'[^\>]*?smallImage\:\s*\'([^\>]*?)\'\"\s*>/is)
		{
			if ( $content2 =~ m/detailImgMapJson_\d+\s*\=\s*\{([^<]*?)\}/is )
			{
				my $detailed_image_content=$1;
				while ($detailed_image_content=~ m/\"\w+\:\w+\"\:\"([^<]*?)\"/igs )
				{
					my $alt_image =&DBIL::Trim($1);
					my $img_file;
					$alt_image =~ s/\\\//\//g;
					my $id;
					if($alt_image=~m/\/\d+_(\w+)_/is)
					{
						$id=$1;
					}	
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$id;
					$hash_default_image{$img_object}='y';
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
				}
			}
		}
		if(($description eq '') or ($prod_detail eq ' '))
		{
			$description=' ';
		}
		PNF:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		$dbh->commit();
	}
}1;
# &DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
# $dbh->commit();
# $dbh->disconnect();

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
sub image_code
{
	my $url = shift;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
	my $code=$res->code;
	return $code;
}
