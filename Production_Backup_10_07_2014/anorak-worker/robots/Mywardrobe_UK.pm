package Mywardrobe_UK;
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
sub Mywardrobe_UK_DetailProcess()
{	
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;	
	my $retailer_id=shift;
	$robotname='Mywardrobe-UK--Detail';
	####Variable Initialization##############
$robotname =~ s/\.pl//igs;
$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
my $retailer_name=$robotname;
my $robotname_detail=$robotname;
my $robotname_list=$robotname;
$robotname_list =~ s/\-\-Detail/--List/igs;
$retailer_name =~ s/\-\-Detail\s*$//igs;
$retailer_name = lc($retailer_name);
my $Retailer_Random_String='Myw';
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
###################GBP CHANGE########################
my $url1 = 'http://www.my-wardrobe.com/';
my $content = lwp_get($url1);
my $url1 = 'http://www.my-wardrobe.com/core/call_backs/set_user_currency.php?c=GBP&rdt=aHR0cDovL3d3dy5teS13YXJkcm9iZS5jb20v';
my $content = lwp_get($url1);
my $url1 = 'http://www.my-wardrobe.com/';
my $content = lwp_get($url1);
###########################################

	my $skuflag = 0;
	my $imageflag = 0;
	my @query_string;

	if($product_object_key)
	{
		my $url3=$url;
		print "url = $url3\n\n";
		$url3 =~s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;	
		my $content2 = lwp_get($url3);		
		open fh1, ">mywar.html";
		print fh1 "$content2";
		close fh1;
		#goto PNF if($content2=~m/No\s*pricing\s*information\s*available/is);
		goto PNF if($content2==1);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;	
		my ($price,$price_text,$brand,$product_id,$color,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$size);
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
	#price_text
	if($content2=~m/<div\s*class\=\"prices\">\s*([^>]*?\s*(?:<span[^>]*?>[^>]*?<\/span>\s*)*)<\/div>/is)
	{
		$price_text=$1;
		print "$price_text ******";
		$price_text = DBIL::Trim($price_text);	
		decode_entities($price_text);
		utf8::decode($price_text);
		print "$price_text";
	}
	#price
	if($content2=~m/<div\s*class\=\"prices\">\s*\$?(?:\&pound\;)?\s*([^>]*?)\s*</is)
	{
		$price=&DBIL::Trim($1);	
		$price=~s/[^\d\.]//gs;
		$price=~s/\,//igs;
	}
	#product_name
	if($content2=~m/<h1[^>]*?>\s*([^>]*?)\s*<\/h1>/is )
	{
		$product_name=&DBIL::Trim($1);
		decode_entities($product_name);
		utf8::decode($product_name);
	}
	#Brand
	if($content2=~m/>\s*([^>]*?)\s*<\/a>\s*<\/h2>/is)
	{
		$brand=&DBIL::Trim($1);
		decode_entities($brand);
		utf8::decode($brand);
	}
	#product_id
	if($content2=~m/Product\s*Code\:\s*(\d+)</is)
	{
		$product_id = DBIL::Trim($1);
		my $ckproduct_id=&DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
		goto ckp if($ckproduct_id==1);
		undef($ckproduct_id);
		
	}
	#description
	if($content2=~m/<ul\s*class\=\"pages\">\s*<li>([^>]*?)</is)
	{		
		$description = $1;	
		decode_entities($description);
		utf8::decode($description);
	}
	# color
	# if($content2=~m/sku_colour\">([^>]*?)<\/span>/is)
	# {		
		# $color = trim($1);	
	# }
	#details
	if($content2=~m/<\/span>\s*<\/li>\s*<li>\s*([\w\W]*?)\s*<\/li>\s*<li>\s*UK\s*SHIPPING/is)
	{
		$prod_detail = $1;		
		decode_entities($prod_detail);
		utf8::decode($prod_detail);
	}
	#Null size
	if($content2!~m/>What\s*size\s*am\s*I/is)
	{
		print "\ninside Null Size\n";
		$size = 'Null';
		$out_of_stock = 'n';
		$color='no raw color';
		my($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
		push(@query_string,$query);
		$skuflag=1 if($flag);
		$sku_objectkey{$sku_object}=$color;
	}
	#size,outofstock
	while($content2=~m/<option\s*value\=\"\d+\"[^>]*?>([^>]*?)(?:\s*\(([^>]*?)\)\s*)?<\/option>/igs )
	{		
		$size = $1;
		my $availablity = $2;
		$size = DBIL::Trim($size);
		$out_of_stock = 'y';
		$out_of_stock = 'n' if($availablity !~m/sold\s*out/is);			
		$color='no raw color';
		my($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
		push(@query_string,$query);
		$skuflag=1 if($flag);
		$sku_objectkey{$sku_object}=$color;

	}
	#Mainimage
	if($content2=~m/imgs\[0\]\s*\=\s*\'([^>]*?)\'/is )
	{
		my $main_image=$1;
		$main_image = DBIL::Trim($main_image);
		my($imgid,$img_file)=&DBIL::ImageDownload($main_image,'product',$retailer_name);
		my($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
		push(@query_string,$query);
		$imageflag=1 if($flag);
		$image_objectkey{$img_object}=$color;
		$hash_default_image{$img_object}='y';
	}
	#Altimage
	while($content2=~m/imgs\[(?!0)\d+\]\s*\=\s*\'([^>]*?)\'/igs)
		{
			my $alt_image =$1;
			$alt_image = DBIL::Trim($alt_image);
			my $img_file = (split('\/',$alt_image))[-1];
			my($imgid,$img_file)=&DBIL::ImageDownload($alt_image,'product',$retailer_name);
			my($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$imageflag=1 if($flag);
			$image_objectkey{$img_object}=$color;
			$hash_default_image{$img_object}='n';	
			
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);
		
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		ckp:
		$dbh->commit();
	}	
	
}1;
# DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
# $dbh->commit();
# $dbh->disconnect();
sub lwp_get()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
	$req->header("Content-Type"=>"application/x-www-form-urlencoded");
	$req->header("Referer"=>"http://www.my-wardrobe.com/");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;	
	my $content;
	if($code =~m/302/is)
	{
		my $loc = $res->header('Location');
		print "Location => $loc";
		$url=$loc;
		goto Home;
	}
	if($code =~m/20/is)
	{
		$content = $res->content;
		return $content;
	}
	
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep 1;
			goto Home;
		}
		return 1;
	}	
}
	
		