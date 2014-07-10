#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Landsend_US;
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
sub Landsend_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Landsend-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Lan';
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
		$url3='http://www.landsend.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &lwp_get($url3);
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$img_file);	
		my($style,$priceRange,$swatcharry,$sizesaarry,$stylename,$namelist,$swatchno,$swatchcolor,$swatchcolcode,$sizeno,$size,$imagetype,$pricemin,$tempx,$mainimage);
		my ($imgid,$stylenum);
		my(@arry_swatcharry,@arry_sizesaarry,@imagearry);
		my(%style_hash,%swatcharry_hash,%sizesaarry_hash,%priceRange_hash,%namelist_hash,%swatchcolor_hash,%swatchcolcode_hash,%size_hash,%swatchcolco_hash,%price_text_hash,%pricemin_hash,%url_hash);
		my (%sku_objectkey,%image_objectkey,%hash_default_image,%sku_imge_hash,%sku_style_hash,%has_image,%imagetype_hash,%imagecol_hash);
		
		### Mulitiple Product#####
		my $mflag;
		if($content2=~m/More\s*details/s)
		{
			$mflag = 1;
			goto MP;
		}
		# Retailer_Product_Reference
		if ( $content2 =~ m/productId\:\s*([^>]*?)\s*\}/is )
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname, $retailer_id);
			goto end if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		# Description & Details
		if ( $content2 =~ m/description\">([\w\W]*?)<p>([\w\W]*?)<\/p>/is )
		{
			$description = &DBIL::Trim($1);
			$prod_detail = &DBIL::Trim($2);
			$description="$description"."$prod_detail";
			$prod_detail="";
		}
		# Main Image
		if ( $content2 =~ m/property\=\"og\:image\"\s*content\=\"([^>]*?)\"/is )
		{
			$alt_image=$1;
			$mainimage=$alt_image;
		}
		# Alternate Image & Swatch Image
		while($content2 =~ m/ProductImage[\d+]*?\s*\.name\s*\=\s*\"([^>]*?)\"[^>]*?ProductImage[\d+]*?\.altText\s*\=\s*\"([^>]*?)\"\;\s*ProductImage[\d+]*?\.url\s*\=\s*\"([^>]*?)\"/igs)
		{
			my $tempname=&DBIL::Trim($1);
			my $tecolor=&DBIL::Trim($2);
			$alt_image=$3;
			$alt_image=~s/\\//igs;
			$alt_image='http://s7.landsend.com'.$alt_image;
			push(@imagearry, $alt_image);
			$imagetype_hash{$alt_image}=$tempname;
			$imagecol_hash{$alt_image}=$tecolor;
		}
		my @imagearry1=keys %{{ map { $_ => 1 } @imagearry }};
		foreach(@imagearry1)
		{
			$alt_image=$_;
			my $tempcol=$imagecol_hash{$alt_image};
			my $tempno=$imagetype_hash{$alt_image};
			if($tempno=~ m/Fabric_Swatch/is)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
				$image_objectkey{$img_object}=lc($tempcol);
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
			unless($tempno=~ m/Fabric_Swatch/is)
			{
				if($tempno=~ m/(?:_FF|_LF|_M1_)/is)
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=lc($tempcol);
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				else
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=lc($tempcol);
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
			}
		}
		# Value Collection
		# Color
		while($content2 =~ m/SwatchImage([\d+]*?)\.altText\s*\=\s*\"([^>]*?)\"[^>]*?SwatchImage[^>]*?\.color\s*\=\s*([^>]*?)\;/igs)
		{
			$swatchno="SwatchImage".&DBIL::Trim($1);
			$swatchcolor=&DBIL::Trim($2);
			$swatchcolcode=&DBIL::Trim($3);
			$swatchcolor_hash{$swatchcolcode}=$swatchcolor;
			$swatchcolcode_hash{$swatchno}=$swatchcolcode;
			$swatchcolco_hash{$swatchno}=$swatchcolor;
			# &DBIL::SaveTag('Color',lc($swatchcolor),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			
		}
		### Size Value Collection ######
		while($content2 =~ m/Size([\d+]*?)\.displayName\s*\=\s*\"([^>]*?)\"/igs)
		{
			$sizeno="Size".&DBIL::Trim($1);
			$size=&DBIL::Trim($2);
			$size_hash{$sizeno}=$size;
		
		}
		my %type;
		while($content2 =~ m/featureNumber\s*\=\s*(\d+)\;[^>]*?displayText\s*\=\s*\"([^>]*?)\"/igs)
		{
			$type{$1}=$2;
		}
		
		my %phash;
		my $pr_text;
		while($content2=~ m/assignedStyle\s*\=\s*(Sty[^>]*?)\;[^>]*?priceRange\s*\=\s*([^>]*?)\;[^>]*?swatchList\s*\=\s*([^>]*?)\;[^>]*?sizes\s*\=\s*([^>]*?)\;[^>]*?displayText\s*=\s*\"([^>]*?)\"\;[^>]*?URL\s*\=\s*\"([^>]*?)\"\;/igs)
		{
			$style=&DBIL::Trim($1);
			$priceRange=&DBIL::Trim($2);
			$swatcharry=&DBIL::Trim($3);
			$sizesaarry=&DBIL::Trim($4);
			$stylename=&DBIL::Trim($5);
			my $ur=$6;
			$ur=~s/\\//igs;
			$url_hash{$style}='http://www.landsend.com'.$ur;
			my $pric_con=&lwp_get($url_hash{$style});
			if($pric_con=~m/class\=\"pp-summary-price\"\s*>([\w\W]*?)\<\/p>/is)
			{
				$pr_text=&DBIL::Trim($1);
				$phash{$style}=$pr_text;
			}
			$price_text=~s/\'//igs;
			$style_hash{$style}=$stylename;
			$swatcharry_hash{$stylename}=$swatcharry;
			$sizesaarry_hash{$stylename}=$sizesaarry;
			$priceRange_hash{$stylename}=$priceRange;
			if($content2 =~ m/$style\.longName\s*\=\s*\"([^>]*?)\"\;/is)
			{
				$namelist=$1;
				$namelist =~ s/\&\#174\;\-/ /igs;
				$namelist=~s/\\//igs;
				$namelist=&DBIL::Trim($namelist);
				$namelist_hash{$stylename}=$namelist;
			}
			#pricetext
			if($content2 =~ m/$priceRange\.minPrice\s*\=\s*([^>]*?)\;[^>]*?$priceRange\.maxPrice\s*\=\s*([^>]*?)\;/is)
			{
				$price_text="\$".&DBIL::Trim($1)."-"."\$".&DBIL::Trim($2);
				$pricemin=&DBIL::Trim($1);
				$price_text_hash{$style}=$price_text;
				$pricemin_hash{$style}=$pricemin;
			}
			my (@arry_swatcharry,@arry_sizesaarry);
			if($content2 =~ m/$swatcharry\.push\(([^>]*?)\)/is)
			{
				my $temp=$1;
				@arry_swatcharry = split(/\,/, $temp);
			}
			if($content2 =~ m/$sizesaarry\.push\(([^>]*?)\)/is)
			{
				my $temp=$1;
				@arry_sizesaarry = split(/\,/, $temp);
			}
			
			############# Sku for Out of Stock Products #################
			foreach my $arry_swatcharry(@arry_swatcharry)
			{
				my $col=$swatchcolcode_hash{$arry_swatcharry};
				foreach my $arry_sizesaarry(@arry_sizesaarry)
				{
					
					if($content2!~m/Sku\d+\.style\s*\=\s*$style\;\s*Sku\d+\.defaultMonoThreadColor\s*\=\s*\w+\;\s*Sku\d+\.color\s*\=\s*$col\;\s*Sku\d+\.size\s*\=\s*$arry_sizesaarry\;/is)
					{
						my $tempstyle=$style;
						my $tempcol=$col;
						my $tempsize=$arry_sizesaarry;
						my $size=$style_hash{$tempstyle}." ".$size_hash{$tempsize};
						my $link=$url_hash{$tempstyle};
						$price_text=$phash{$style};
						$price=$pricemin_hash{$tempstyle};
						$out_of_stock="y";
						if($link ne "")
						{
							$url3=$link;
						}
						my $name=$style_hash{$tempstyle};
						my $product_name=$namelist_hash{$name};
						my $color=$swatchcolor_hash{$tempcol};
						$color=&ProperCase($color);
						$color=~s/\-(\w)/-\u\L$1/is;
						sub ProperCase {
							join(' ',map{ucfirst(lc("$_"))}split(/\s/,$_[0]));
						}
						$size=~s/Root\s*Product\s*Feature//igs;
						if($link=~m/_(\d+)\:/is)
						{
							my $c=$1;
							my $new=$type{$c};
							$size="$new,"."$size";
						}
						$price_text=~s/\$null\s*(?:\-\s*)?//igs;
						$price_text=~s/\{//igs;
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=lc($color);
						push(@query_string,$query);
					}
				}
			}
		}
		########### Sku for In Stock Product ############
		while($content2 =~ m/Sku[\d+]*?\.price\s*\=\s*([^>]*?)\;[^>]*?Sku[\d+]*?\.inventoryStatusCode\s*\=\s*\"([^>]*?)\"\;\s*Sku[\d+]*?\.style\s*\=\s*([^>]*?)\;[^>]*?Sku[\d+]*?\.color\s*\=\s*([^>]*?)\;\s*Sku[\d+]*?\.size\s*\=\s*([^>]*?)\;[^>]*?Sku[\d+]*?\.originalPrice\s*\=\s*([^>]*?)\;/igs)
		{
			my $temprize=&DBIL::Trim($1);
			my $tempstock=&DBIL::Trim($2);
			my $tempstyle=&DBIL::Trim($3);
			my $tempcol=&DBIL::Trim($4);
			my $tempsize=&DBIL::Trim($5);
			my $temporgprize=&DBIL::Trim($6);
			my $name=$style_hash{$tempstyle};
			my $link=$url_hash{$tempstyle};
			$out_of_stock="n";
			if($tempsize eq "null")
			{
				$size_hash{$tempsize}='';
			}	
			$product_name=$namelist_hash{$name};
			$price=$temprize;
			$price_text="\$".$temprize;
			$size=$style_hash{$tempstyle}." ".$size_hash{$tempsize};
			$color=$swatchcolor_hash{$tempcol};
			unless($temprize eq $temporgprize)
			{
				if($content2 =~ m/class\=\"pp-summary-price\"\s*>([\w\W]*?)\<\/p>/is)
				{
					my $pricecon=&DBIL::Trim($1);
					$pricecon=~ s/\{//igs;
					if($pricecon=~m /^(?:([^>]*?))?\$[\d+\.\s]*\s*([^>]*?)\$[\d\.\s]*?/is)
					{
						$price_text=$1."\$".$temporgprize." ".$2."\$".$temprize;
					}
				}
			}
			unless($tempstock eq "A")
			{
				$out_of_stock="y";
			}
			unless($content2 =~ m/class\=\"pp\-available\s*pp\-selected\"/is)
			{
				if($content2 =~ m/class\=\"pp\-product\-name\">\s*([^>]*?)\s*<\/h1>/is)	
				{
					$product_name=$1;
					$product_name =~ s/\&\#174\;\-/ /igs;
					$product_name = &DBIL::Trim($product_name);
					$product_name=~s/\\//igs;
				}
		
			}
			if($link ne "")
			{
				$url3=$link;
			}
			$color=&ProperCase($color);
			$color=~s/\-(\w)/-\u\L$1/is;
			sub ProperCase {
				join(' ',map{ucfirst(lc("$_"))}split(/\s/,$_[0]));
			}
			$size=~s/Root\s*Product\s*Feature//igs;
			$price_text=~s/\$null\s*(?:\-\s*)?//igs;
			 if($link=~m/_(\d+)\:/is)   						######## Size Type #########
			{
				my $c=$1;
				my $new=$type{$c};
				$size="$new,"."$size";
			}
			$price_text=~s/\{//igs;
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=lc($color);
			push(@query_string,$query);
		}
		### Sku_has_Image #######
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
		##### Product_Name ######
		if($content2 =~ m/Product4\.longName\s*\=\s*\"([^>]*?)\"\;/is)
		{
			$product_name=$1;
			$product_name=~s/\\//igs;
		}
		MP:
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

sub lwp_get() 
{ 
    my $url = shift;
	my $rerun_count=0;
    Home: 
    my $req = HTTP::Request->new(GET=>$url);
    $req->header("Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"); 
    $req->header("Content-Type"=>"application/x-www-form-urlencoded"); 
    my $res = $ua->request($req); 
    $cookie->extract_cookies($res); 
    $cookie->save; 
    $cookie->add_cookie_header($req); 
    my $code = $res->code(); 
    print $code,"\n"; 
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
			sleep 2;
			goto Home;
		}
	}
	return $content; 
}
