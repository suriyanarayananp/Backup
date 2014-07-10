#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Witchery_AU;
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
sub Witchery_AU_DetailProcess()
{	
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;	
	my $retailer_id=shift;
	$robotname='Witchery-AU--Detail';
	####Variable Initialization##############
$robotname =~ s/\.pl//igs;
$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
my $retailer_name=$robotname;
my $robotname_detail=$robotname;
my $robotname_list=$robotname;
$robotname_list =~ s/\-\-Detail/--List/igs;
$retailer_name =~ s/\-\-Detail\s*$//igs;
$retailer_name = lc($retailer_name);
my $Retailer_Random_String='Wit';
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

	my $skuflag = 0;
	my $imageflag = 0;
	my @query_string;

	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;	
		my $content2 = &get_content($url3);		
		goto PNF if($content2=~m/No\s*pricing\s*information\s*available/is);
		goto PNF if($content2==1);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;	
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		my ($price_text,@price_calc,$c_price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);
		#price_text	
		if ( $content2 =~m/<div\s*class=\"price_break\s*default\">\s*([\w\W]*?)\s*<\/div>/is )
		{
			$c_price_text = &DBIL::Trim($1);
			utf8::decode($c_price_text);
			if($c_price_text=~m/From \s*AUD\s*\$[\d\,\.]+/is)
			{
				my $min=0; my $max=0;
				while($content2 =~m/<p\s*class\=\"price\s*(?:now|standard)\">((?!N\/A)[\w\W]*?)<\/p>/igs)
				{
					my $price_amt=&DBIL::Trim($1);
					utf8::decode($price_amt);
					$price_amt=~s/\s*AUD\s*\$\s*//igs;
					push(@price_calc,$price_amt);
				}
				foreach my $price_amt(@price_calc)
				{
					if($max<$price_amt)
					{
						$max=$price_amt;
					}
					if($max>$price_amt)
					{
						$min=$price_amt;
					}
					
				}
				$c_price_text = $c_price_text."to AUD \$ $max";
				
			}
			$c_price_text=~s/Â//igs;
			
		}
		#product_id
		if ($content2=~m/<li>Style\s*Code\:\s*(\d+)<\/li>/is)
		{
			$product_id=&DBIL::Trim($1);
			my $ckproduct_id=&DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto ckp if($ckproduct_id==1);
			undef($ckproduct_id);
		}
		
		#product_name
		if($content2=~m/<h1\s*itemprop=\"name\">([^<]*?)<\/h1>/is)
		{
			$product_name=&DBIL::Trim($1);
		}
		
		#description
		if($content2=~m/<div\s*class\=\"info_content\">\s*<div\s*class\=\"content\">([^>]*?)(?:<\/div>|<br\/><br\/><p>)/is)
		{		
			$description=&DBIL::Trim($1);
		}
		
		#details
		if($content2=~m/<div\s*class\=\"content\"><ul>([\w\W]*?)<\/ul><\/div>/is)
		{	
			$prod_detail=$1;
			$prod_detail=~s/<li>/\* /igs;
			$prod_detail=~s/<\/li>//igs;
			$prod_detail=&DBIL::Trim($prod_detail);
		}
		
		#colour,size,price		
		while($content2=~m/<li\s*class=\"(c_\d+)\">\s*<p\s*class\=\"swatch\"\s*title\=\"([^>]*?)\">([\w\W]*?)<\/ul>\s*<\/li>/igs)
		{
			my $color_code=$1;
			my $color=&DBIL::Trim($2);
			my $colour_block=$3;
			# Size,Availablity,Colour
			while($colour_block=~m/(?:<li\s*class=\"s_\d+\s*([^>]*?)\">\s*<input\s*id[^>]*?>\s*<label\s*for\=\"coloursize[^>]*?>([^>]*?)<\/label>(?:\s*<[^>]*?>\s*)*<p\s*class=\"price\s*standard\">(N\/A)<\/p>)|(?:(?:<li\s*class=\"s_(0)|<li\s*class=\"s_\d+)\s*([^>]*?)\">\s*<input\s*id[^>]*?>\s*<label\s*for\=\"coloursize[^>]*?>([^>]*?)<\/label>(?:\s*<[^>]*?>\s*)*(?:<p\s*class\=\"price\s*was\">\s*[^>]*?<span[^>]*?>[^>]*?<\/span><span[^>]*?>[^>]*?<\/span><\/p>)?\s*(<p\s*class=\"price\s*[^>]*?\">\s*<span[^>]*?>[^<]*?<\/span>\s*<span[^<]*?>(\d+(?:\.\d+)?)<\/span>\s*<\/p>))/igs)
			{	
				my $availablity=$1.$5;
				my $size=$2.$6;
				$size=&DBIL::Trim($size);
				my $one_size=$4;
				my $price=$3.$8;
				$price=&DBIL::Trim($price);		
				if(($one_size=~m/0/is) and ($size=~m/^\s*$/is))
				{
				$size = 'One Size';
				}
				print "$price**\n";
				if(($price=~m/N\/A/is)||($price=~m/^\s*$/is)||($price eq ''))
					{
						$price='null';
						$price_text='';
						print "Inside Loop $price=>$price_text\n";
					}
					else
					{
					$price_text=$c_price_text;
					}
				# $price="null" if($price=~m/^\s*$/is);
				$price_text=~s/Â//igs;
				utf8::decode($price_text);		
				$out_of_stock = 'y';
				$out_of_stock = 'n' if($availablity !~m/unavailable/is);
				print "$out_of_stock";
				my($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				print "$out_of_stock";
				$skuflag=1 if($flag);
				$sku_objectkey{$sku_object}=$color;
			}
			#swatchimage
			if($colour_block=~m/<img\s*src=\"([^>]*?)\"[^>]*?>/is)
			{
				my $swatch=&DBIL::Trim($1);
				my($imgid,$img_file)=&DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag=1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
			}
			
			# Main/Alternate Images
			if ($content2=~m/<ul\s*class\=\"altimages\s*$color_code\s*(?:default)?\">\s*<li>\s*<a\s*data\-mainimage\=\"(?:[^<]*?)\"\s*href\=\"([^>]*?)\">([\w\W]*?)\s*<\/ul>/is)
			{				
				my $main_image=&DBIL::Trim($1);
				my $alt_image_block=$2;
				my($imgid,$img_file)=&DBIL::ImageDownload($main_image,'product',$retailer_name);
				my($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag=1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
				while($alt_image_block=~m/<a\s*data\-mainimage=\"(?:[^<]*?)\"\s*href\=\"([^>]*?)\">/igs)
				{
					my $alt_image = &DBIL::Trim($1);
					my($imgid,$img_file)=&DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$imageflag=1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';			
				}
			}
		}
		#For Products out of stock with price information
		if($content2=~m/We\'re\s*sorry\,\s*this\s*item\s*is\s*no\s*longer\s*available\s*online\.<br>/is)
		{	
			$out_of_stock = 'y';
			$color="";
			#price
			if($content2=~m/<div\s*class\=\"price_break\s*default\">\s*(?:[\w\W]*?)>([\d\,\.]+)<\/span><\/p>\s*(?:<p\s*class\=\"availability\s*unavailable\">We[^>]*?<br>[^<]*?<a[^>]*?>nearest\s*store<\/a>\.<\/p>\s*)?\s*<\/div>/is)
			{
				print "inside out of stock\n ";
				my $price=&DBIL::Trim($1);
				my $price_text='AUD $'.$price;
				my $size='';
				utf8::decode($price_text);	
				my($sku_object,$flag,$query)=&DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag=1 if($flag);
				$sku_objectkey{$sku_object}=$color;
						
			}
			# Main/Alternate Images
			if ($content2=~m/<ul\s*class\=\"altimages\s*c_\d+\s*(?:default)?\">\s*<li>\s*<a\s*data\-mainimage\=\"(?:[^<]*?)\"\s*href\=\"([^>]*?)\">([\w\W]*?)\s*<\/ul>/is)
			{				
				my $main_image=&DBIL::Trim($1);
				my $alt_image_block=$2;
				my($imgid,$img_file)=&DBIL::ImageDownload($main_image,'product',$retailer_name);
				my($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag=1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
				while($alt_image_block=~m/<a\s*data\-mainimage=\"(?:[^<]*?)\"\s*href\=\"([^>]*?)\">/igs)
				{
					my $alt_image = &DBIL::Trim($1);
					my($imgid,$img_file)=&DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my($img_object,$flag,$query)=&DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
					$imageflag=1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';			
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
		PNF:
		my($query1,$query2)= &DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		ckp:
		$dbh->commit();
	}
}1;
# &DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
# $dbh->commit();
# $dbh->disconnect();


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
	my $content;
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