#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Boohoo_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBIL_Updated/DBIL.pm"; # UKER DEFINED MODULE DBIL.PM
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);

sub Boohoo_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger = shift;
	$robotname='Boohoo-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Hol';
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

	my $skuflag = 0;
	my $imageflag = 0;
	my $mflag = 0;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url3='http://www.boohoo.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &lwp_get($url3);
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$img_file,$imagei,$imagelist,$imageid,$colorid,$imageurl,$size,$defualtimage,$multicol, $filter,$FCavailable,$swatch_url,$sku_con,$base_url,$price_text1,$sku_url);
		my $mflag;
		my (%colorid_hash,%image_hash,%sku_objectkey,%image_objectkey,%hash_default_image,%swatch_hash);
		my (@colorarry,@sizearry,@imagearry,@swatcharry);
		my @query_string;
		goto MP if($content2 =~ m/(?:We\'re\s*sorry\,\s*this\s*product\s*is\s*out\s*of\s*stock\.|Sorry\,\s*this\s*item\s*is\s*out\s*of\s*stock)/is);
		####product_id
		if($content2=~ m/Product\s*code\s*\:\s*([^>]*?)\s*<\/p>/is)
		{
			$product_id=trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
			# print"product_id::$product_id\n";
		}
		####product_name
		$product_name=trim($1) if($content2=~ m/<h1[^>]*?>\s*([^>]*?)\s*<\/h1>/is);
		# print"product_name::$product_name\n";
		####Brand
		$brand="Boohoo";
		# print"brand::$brand\n";
		########description
		$description=trim($1) if($content2=~ m/<div\s*id\=\"tab1\">([\w\W]*?)\s*<\/div>/is); 
		# print"description::$description\n";
		########prod_detail
		$prod_detail=trim($1) if($content2=~ m/<div\s*id\=\"tab2\">([\w\W]*?)\s*<\/div>/is); 
		# print"prod_detail::$prod_detail\n";
		$price_text1=trim($1) if($content2=~ m/<div\s*id\=\"atrPrice\">([\w\W]*?)<\!\-\-\s*WAS\sprice\s*Label/is); 
		$price_text1=~s/Price//igs;
		$price_text1=~s/\s+/ /igs;
		$price_text1=~s/^\s+|\s+$//igs;
		# print"price_text::$price_text\n";
		####price
		$price=trim($1) if($content2=~ m/as\s*MAX\s*\-\->\s*\£([^>]*?)\s*<\/span>/is); 
		# print"price::$price\n";
		######SKU 
		$sku_con=$1 if($content2=~ m/setChanges([\w\W]*?)setLabels/is);
		#####Size
		if($content2=~m/ajaxFunction\(\'([^>]*?)\&ordercol/is)
		{
			$sku_url=$1;
		}
		my $size_url='http://www.boohoo.com/bin/venda?ex=co_wizr-productgrid&bsref=boohoo&invt='.$product_id.'&layout=noheaders';
		# my $size_url="http://www.boohoo.com/bin/venda?ex=co_wizr-productgrid&invt=".$product_id;
		my $size_con=&lwp_get($size_url);
		my $size_con1=$1 if($size_con=~m/UK\s*SIZE([\w\W]*?)<\/tr>/is);
		while($size_con1=~ m/<span>\s*([^>]*?)\s*<\/span>/igs)
		{
			my $sizevalue=trim($1);
			push(@sizearry,$sizevalue);
		}
		@sizearry=keys %{{ map { $_ => 1 } @sizearry }};
		print"sizearry::::::::@sizearry\n";
		####Color
		while($size_con=~m/Venda\.ProductDetail\.changeSet\(\'\s*([^>]*?)\s*\'\,/igs)
		{
			my $colorvalue=trim($1);
			push(@colorarry,$colorvalue);
		}
		@colorarry=keys %{{ map { $_ => 1 } @colorarry }};
		print"colorarry::@colorarry\n";
		#####outofstock
		my $count1=1;
		foreach(@colorarry)
		{
			$color=$_;
			$price=trim($1) if($sku_con=~m/atr2\"\:\"\Q$color\E\"[^>]*?\"atrsell\"\:\"([^>]*?)\"\,/is);
			if($price_text1=~m/\Q$price\E/is)
			{
				$price_text=$price_text1;
				# print"jeganprice_text::$price_text\n";
				$price_text=~s/\&pound\;/\Â\£/igs;
				$price_text =~ s/\&\#163\;/\Â\£/igs;
				$price_text=~s/\£/\Â\£/igs;
			}
			else
			{
				$price_text="£".$price;
				$price_text=~s/\£/\Â\£/igs;
			}
			foreach(@sizearry)
			{
				$size=$_;
				$out_of_stock="y";
				$out_of_stock="n" if($sku_con=~ m/att1\"\:\"\s*\Q$size\E\s*\"\,\s*\"att3\"\:\"\"\,\"att2\"\:\"\s*\Q$color\E\s*\"\,\"att4\"\:\"\"\}/is);
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
				print"color::$color\n";
				print"size::$size\n";
				print"out_of_stock::$out_of_stock\n\n";
			}
			undef $price_text;
		}
		$base_url=$1 if($content2=~ m/var\s*based_imgURL\s*\=\s*\'([^>]*?)\'/is); 
		####Swatch&Main&Alternate
		foreach(@colorarry)
		{
			$color=$_;
			####Swatch
			$swatch_url="http://www.boohoo.com/content/ebiz/boohoo/resources/images/swatches/".$product_id."_".$color.".jpg";
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_url,'swatch',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_url,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
			$image_objectkey{$img_object}=$color;
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
			####main image
			# print"swatch_url::$swatch_url\n";
			while($content2=~ m/exLargeImg[\d+]\s*\:\s*\{path\:\s*currentColour\s*\+\s*\"\s*([^>]*?)\s*\"/igs)
			{
				my $con_value=$1;
				$imageurl="http://www.boohoo.com".$base_url.$color.$con_value;
				IMAGE:
				my $code=get_image($imageurl);
				if($con_value eq "_xl.jpg")
				{
					if($code != 200)
					{
						$con_value="_l.jpg";
						$imageurl="http://www.boohoo.com".$base_url.$color.$con_value;
						print"con_value::$con_value\n";
						goto IMAGE;
					}
				}
				if($code == 200)
				{
					if($con_value eq "_xl.jpg")
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
						my ($img_object,$flsag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
						# print"ifimageurl::$imageurl\n";
					}
					elsif($con_value eq "_l.jpg")
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
						# print"ifimageurl::$imageurl\n";
					}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
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
		MP:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		$dbh->commit();
	}
}1;

sub lwp_get()
{
	# sleep(rand 3);
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>$url);
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
sub get_image()
{
	my $url=shift;
	my $err_count=0;
	# print "url :: $url\n";
	home:
	# my $cookie = HTTP::Cookies->new(file=>$0."_cookie.txt",autosave=>1);
	# $ua->cookie_jar($cookie);
	my $req = HTTP::Request->new(GET=>"$url");
	my $res = $ua->request($req);
	my $code=$res->code;
	print "\n CODE :: $code\n";
	
	return($code);
}
sub trim($) {
  my $string = shift;
  $string =~ s/<[^>]*?>/ /igs;
  $string =~ s/\"/''/igs;
  $string =~ s/\&nbsp\;/ /g;
  $string =~ s/\|//igs;
  $string =~ s/\s+/ /igs;
  $string =~ s/^\s+//g;
  $string =~ s/^\s+//g;
  $string =~ s/\s+$//g;
  $string =~ s/^\s*n\/a\s*$//g;
  $string =~ s/\&\#039\;/'/g;
  $string =~ s/\&\#43\;/+/g;
  $string =~ s/amp;//g;
  $string =~ s/mydelimiter/|/g;
 
  return $string;
}
