#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Aeropostale_US;
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
sub Aeropostale_US_DetailProcess()
{	
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;	
	my $retailer_id=shift;
	$robotname='Aeropostale-US--Detail';
	####Variable Initialization##############
$robotname =~ s/\.pl//igs;
$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
my $retailer_name=$robotname;
my $robotname_detail=$robotname;
my $robotname_list=$robotname;
$robotname_list =~ s/\-\-Detail/--List/igs;
$retailer_name =~ s/\-\-Detail\s*$//igs;
$retailer_name = lc($retailer_name);
my $Retailer_Random_String='Aer';
my $pid = $$;
my $ip = `/sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`;
$ip = $1 if($ip =~ m/inet\s*addr\:([^>]*?)\s+/is);
my $excuetionid = $ip.'_'.$pid;
###########################################

############Proxy Initialization#########
my $country = $1 if($robotname =~ m/\-([A-Z]{2})\-\-/is);
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
#my $firstping = &get_content('http://www.aeropostale.com/include/intlSetCountryCurrency.jsp?selCountry=United+States&selCurrency=US+Dollar+%28USD%2');
	my $skuflag = 0;
	my $imageflag = 0;
	my $mflag=0;
	my @query_string;

	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		my $content2 = &get_content($url3);
		goto PNF if($content2==1);
		if($content2=~m/(No\s*Results\s*Found)/is)
		{
			print "\n$1\n";
			goto PNF;
		}

		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		
		my ($mflag,$price,$price_text,$size,$type,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);

		#price_text
		if( $content2 =~ m/addItemsToBagTop/is )
		{
			if( $content2 =~ m/childProdImage\">\s*<a\s*href\=\"([^>]*?)\"/is )
			{
				# my $updateQuery = "Delete from Product where retailer_id =\'$retailer_id\' and ObjectKey=\'$product_object_key\'";
				# &DBIL::SaveDB($updateQuery, $dbh, $robotname);
				goto PNF;
				
			}
		
		}# if ( $content2 =~ m/<ul\s*class\=\"price\">([^^]*?)<\/ul>/is)
		elsif ( $content2 =~ m/<ul\s*class\=\"price\">([^^]*?)<\/ul>/is )
		{
			$price_text = $1;
			$price_text=~s/<[^>]>//igs;
			$price_text = &DBIL::Trim($price_text);
		}

		#product_id
		###if ( $content2 =~ m/<div\s*class[^>]*?>Style:\s*([^>]*?)\s*<\/div>/is)
		if ( $url3 =~ m/productId\=([\d]*)\s*$/is)
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto dup_productid if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}

		#product_name
		if ( $content2 =~ m/<h2>([^>]*?)<\/h2>/is )
		{
			$product_name = &DBIL::Trim($1);
			decode_entities($product_name);
		}

		#description
		if ($content2=~m/<div\s*class\=\'product\-description\'>([\w\W]*?)<\/div>/is)
		{		
			$description = $1;		
			$description = &DBIL::Trim($description);			
			decode_entities($description);
		}

		
		#swatchimage
		my @colur_t;
		if ($content2 =~ m/<ul\s*class\=\"swatches\s*clearfix\">\s*([\w\W]*?)<\/ul>/is)
		{
			my $color_main_swat_block=$1;
			while($color_main_swat_block=~m/<img\s*src\=\"([^>]*?)\"\s*alt\=\"([^>]*?)\"/igs)
			{
				my $swatch = &DBIL::Trim($1);
				my $colour_id=&DBIL::Trim($2);
				$colour_id=lc($colour_id);
				$swatch = "http://www.aeropostale.com$swatch";
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
				push(@query_string,$query);
				$image_objectkey{$img_object}=$colour_id;
				$hash_default_image{$img_object}='n';
				push(@colur_t,"$colour_id");
			}
			
		}
		# noswatchimage:
		# if($content2=~m/<label\s*id=\"colorLabel\">Color\:\s*([^<]*?)\s*<\/label>/is)
		# {
		# my $colour_id=&DBIL::Trim($1);
		# push(@colur_t,"$colour_id");
		# print "noswatchimage \n\n";
		# <>;
		# }
		
		
		# size & out_of_stock
		if( $content2 =~ m/itemMap\s*\=\s*new\s*Array\(\)\;([^^]*?)<\/script>/is )
		{
			my $size_content = $1;
			my $color;
			my %color_hash;
			if(@colur_t)
			{
				foreach my $c (@colur_t)
				{
					#$c=~s/ /\\s*/igs;
					while($size_content=~m/sDesc\:\s*\"([^\"]*?)\"[^\{\}]*?cDesc\:\s*\"\s*($c)\s*\"[^\{\}]*?avail\:\s*\"([^\"]*?)\"\,\s*price\:\s*\"[^\"]*?([\d.]+)\"/igs)
					{			
						my $size = &DBIL::Trim($1);
						$color = &DBIL::Trim($2);
						$color = lc($color);
						$price = &DBIL::Trim($4);
						my $availablity = &DBIL::Trim($3);
						my $out_of_stock;		
						$out_of_stock = 'n';			
						$out_of_stock = 'y' if($availablity !~m/IN_STOCK|LOW\s*_?\s*STOCK/is);
						$price ='NULL' if($price=='');
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						$color_hash{$color}='';
					}
				}
			}
			else
			{
				$color ='No raw colour';
				my $out_of_stock='n';
				my $size ='No size';
				$price=$1 if($price_text=~m/<ul\s*class=\"price\"><li>[^<]*?([\d\,\.]+)\s*<\/li>/is);
				$price=$1 if($price_text=~m/<li\s*class="now">now[^<]*?([\d\,\.]+)\s*<\/li>/is);
				$price ='NULL' if($price=='');
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				$color_hash{$color}='';
			}
		}
		
		# #Image
		if ( $content2 =~m/store\.product\.alternateImages\[\d+\]\s*\=\s*\[([\w\W]*?)\]\;/is)
		{
			my $count_col=0;
			while ( $content2 =~m/store\.product\.alternateImages\[\d+\]\s*\=\s*\[([\w\W]*?)\]\;/igs)
			{
				my $block=$1;
				my $count=0;
				while($block =~m/enh\:\s*\"(\/[^>]*?)\"\s*}/igs )
				{
					my $alt_image; $count++;
					
					$alt_image="http://www.aeropostale.com$1" if($1 ne '');
					
					my $img_file;
					$alt_image =~ s/\\\//\//g;
					$img_file = (split('\/',$alt_image))[-1];

					if ( $count == 1 )
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=lc($colur_t[$count_col]);
						$hash_default_image{$img_object}='y';	
					}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=lc($colur_t[$count_col]);
						$hash_default_image{$img_object}='n';						
					}
				}
				$count_col++;
			}
		}
		
		$brand="aeropostale";
		# DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
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
		
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		dup_productid:
		$dbh->commit;
	}
}1;
sub get_content
{
	my $url = shift;
	my $rerun_count;
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
	open fh,">>$retailer_file";
	print fh "$url=>$code\n";
	close fh;
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
		return 1;
	}
	return $content;
}
