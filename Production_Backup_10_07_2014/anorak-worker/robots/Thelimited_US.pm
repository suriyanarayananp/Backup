#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Thelimited_US;
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
sub Thelimited_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Thelimited-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='The';
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
		my $prod_links=$url;
		my @query_string;
		####################################################################################################################################
		my (@prod_name,@prod_desc,@retailer_prod_ref,@prod_detail,@check_outofstock,@price,@price_text,@colors,@sizes);
		my ($prod_name,$prod_desc,$product_id,$brand,$color,$price,$price_text,$size,$out_of_stock,$img_file,$swatch,$retailer_prod_ref,$prod_detail1,$prod_detail2);
		###----------------------------------------------------------------------------------------------------------------------------------####
		
		# print "\nPRODUCT LINKS::$prod_links\n";
		chomp $prod_links;
		my $content_prod=&get_content($prod_links);
		
		if($content_prod=~m/outofstock\">/is)
		{
			goto PNF;
		}
		
		########## Multi Item Product ###############
		if($content_prod=~m/Item\(s\)\s*Selected</is)
		{
			$mflag=1;
			if($prod_links=~m/[^>]*\/([^>]*?)\.html/is)
			{
				$product_id=$1;
			}
			if($content_prod=~m/\"name\"\W*\"([^>]*?)\"\W*ID\W*\"\d+\"/is)
			{
				$prod_name=&DBIL::Trim($1);		
				
			}
			goto PNF;
		}
		
		######### Product Name ##############	
		if($content_prod=~m/<h1\s*class\=\"productname\"[^>]*?>([\w\W]*?)<\/h1>/is)
		{
			$prod_name=&DBIL::Trim($1);		
			
		}
		$prod_name=~s/\&reg\;//igs;
		############ Retailer_Product_Reference ###########
		if($content_prod=~m/class\=\"item\-number\">\s*Item\s*#\s*[^>]*?>\s*([^<]*?)\s*</is)
		{
			$retailer_prod_ref=&DBIL::Trim($1);
			$product_id=$retailer_prod_ref;
			
		}
		my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
		goto end if($ckproduct_id == 1);
		undef ($ckproduct_id);
		######### Product Description & Product Details #############
		my $prod_detail;
		if($content_prod=~m/<div\s*class\=\"sales\-description\">\s*([^>]*?)\s*<\/div>/is)
		{
			$prod_desc=&DBIL::Trim($1);
		}
		if($content_prod=~m/<div\s*class\=\"long\-description\">([\w\W]*?)<\/div>/is)
		{
			$prod_detail=&DBIL::Trim($1);
		}
		
		########### Price ################################
		
		if($content_prod=~m/priceGroup\">([\w\W]*?)<\/div/is)
		{
			$price_text=&DBIL::Trim($1);
			$price_text=~s/colo(?:u)r//is;
			$price_text=~s/\://is;
			$price_text=~s/\$/\-\$/is;
			$price_text=~s/^\-//is;
			$price=$price_text;
			my ($v1,$v2);
			if($price_text=~m/(\d+\.\d+)\W*(\d+\.\d+)/is)
			{
				$v1=&DBIL::Trim($1);
				$v2=&DBIL::Trim($2);
				if($v1<$v2)
				{
					$price= $v1;
				}
				else
				{
					$price= $v2;
				}
			}	
			$price=~s/\$//igs;
		}
		
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		my $block1;
		if($content_prod=~m/<div\s*class\=\"label\">\s*Size\:[\w\W]*?<ul[^>]*?>([\w\W]*?)<\/ul>/is)
		{
			$block1=$1;
			my @sizes;
			while($block1=~m/<a[^>]*?>\s*([^>]*?)\s*<\/a>/igs)
			{
				push(@sizes,$1);
			}
		}
		
		while($content_prod=~m/\"\s*title\=\"([^>]*?)\"[^>]*?swatchanchor/igs)
		{
			my $color=&DBIL::Trim($1);
			$color=~s/amp;//igs;
			push(@colors,$color);
		}
		############ Sku ############
		my $json_url="http://www.thelimited.com/on/demandware.store/Sites-ltd-Site/default/Product-GetVariants?pid=$retailer_prod_ref&format=json";  ####### Url formation for Sku Details ########
		my $json_cont=&get_content($json_url);
		while($json_cont=~m/\{\s*(?:\"sizeType\"\s*\:\s*\"([^>]*?)\"\s*\,)?\s*\"colorCode\"\s*\:\s*\"([^>]*?)\"\s*\,\s*\"size\"\s*\:\s*\"([^>]*?)\"\s*(?:\,\s*\"pantLength\"\s*\:\s*\"([^>]*?)\"\s*)?\}\,\s*[^>]*?\"avStatus\"\s*\:\s*\"([^>]*?)\"[^>]*?pricing\"\s*\:\s*\{\"standard\"\s*\:\s*\"([^>]*?)\"\,\s*\"sale\"\s*:\s*\"([^>]*?)\"/igs)
		{
			my $type=$1;
			my $color=$2;
			my $size=$3;
			my $length=$4;
			my $stock=$5;
			my $st_p=$6;
			my $sa_p=$7;
			my $avi_status;
			$price_text='Was'.'$'.$st_p.'Now'.'$'.$sa_p;
			if($st_p eq $sa_p)
			{
				$price_text='$'.$st_p;
			}	
			if($st_p < $sa_p)
			{
				$price=$st_p;
			}
			else	
			{
				$price=$sa_p;
			}
			if($length ne "")
			{
				$size=$size.' Pant Length:'."$length";
			}
			if($type ne "")
			{
				$size="$type:".$size;
			}
			if($stock=~m/NOT/is)
			{
				$avi_status='y';
			}
			else
			{
				$avi_status='n';
			}	
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$prod_links,$prod_name,$price,$price_text,$size,$color,$avi_status,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$color;
			push(@query_string,$query);
		}	
		
		###################### Image ###################################
		for (my $k=0; $k<=$#colors; $k++)
		{
			if($content_prod=~m/val\"\s*\:\"$colors[$k]\"([\w\W]*?)\]/is)
			{
				my $swatch_block=$1;
				if($swatch_block=~m/\"swatch\"\W*url\"\s*\:\s*\"([^>]*?)\"/igs)
				{
					my $swatch=$1;
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch','thelimited-us');
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}="$colors[$k]";
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				my $count=0;
				while($swatch_block=~m/(?:\,|\[)\s*\{\W*url\"\s*\:\s*\"([^>]*?)\"/igs)
				{
					my $image=$1;
					my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product','thelimited-us');
					if($count == 0)
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}="$colors[$k]";
						$hash_default_image{$img_object}='y';
						$count++;
						push(@query_string,$query);
					}
					else
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}="$colors[$k]";
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
				}
			}		
		}
		
		#################### Sku_has_Image ###################################
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$prod_name,$brand,$prod_desc,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
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

sub get_content
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $ua=LWP::UserAgent->new;
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
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep 1;
			goto Home;
		}
	}
	return $content;
}
