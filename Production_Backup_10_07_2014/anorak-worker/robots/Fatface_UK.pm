#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Fatface_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
use List::MoreUtils qw/ uniq /;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBIL_Updated/DBIL.pm"; # UKER DEFINED MODULE DBIL.PM
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Fatface_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger = shift;
	$robotname='Fatface-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Fat';
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
		$product_object_key =~ s/^\s+|\s+$//g;
		my $content2 = &lwp_get($url3);
		goto PNF if($content2==1);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my @query_string;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);
		$content2=~s/<\!\-\-[\w\W]*?\-\->//igs;
		#product_id
		if( $content2 =~ m/Product\s*code\s*\:\s*([\d]+)<\/span>/is)
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id,$product_object_key,$dbh,$robotname,$retailer_id);
			goto dup_productid if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#price_text & #price
		my ($temp_price1,$temp_price2);
		if($content2=~m/<span\s*class\=\"price\">\s*([^<]*?)\s*<\/span>/is)
		{
			$price_text=$1;
			$price=$1 if($price_text=~m/£\s*([^<]*?)\s*$/is);
		}
		elsif($content2=~m/<span\s*class\=\"prod-price-was\">[\w\W]*?<\/span>\s*<\/span>/is)
		{
			if($content2=~m/<span\s*class\=\"prod-price-now\">([\w\W]*?<\/span>)\s*<\/span>/is)
			{
				my $block1=$1;
				$temp_price1=$1 if($block1=~m/<span\s*class\=[^<]*?>\s*([^<]*?)\s*<\/span>/is);
				$price=$1 if($temp_price1=~m/£\s*([^<]*?)\s*$/is);
			}
			if($content2=~m/<span\s*class\=\"prod-price-was\">([\w\W]*?<\/span>)\s*<\/span>/is)
			{
				my $block1=$1;
				$temp_price2=$1 if($block1=~m/<span\s*class\=[^<]*?>\s*([^<]*?)\s*<\/span>/is);
			}
			$price_text=$temp_price2.' '.$temp_price1;
		}	
		#product_name
		if ( $content2 =~ m/<h1\s*itemprop\=\"name\"[^>]*?>([^>]*?)<\/h1>/is )
		{
			$product_name = &DBIL::Trim($1);
		}
		#description&details
		if ( $content2 =~ m/<div\s*class\=\"tab-invtdesc1[^>]*?>([\w\W]*?)<\/div>/is )
		{
			$description = &DBIL::Trim($1);
		}
		if ( $content2 =~ m/<div\s*class\=\"tab-invtdesc2[^>]*?>([\w\W]*?)<\/div>/is )
		{
			$prod_detail=$1;
			$prod_detail=~s/<\/li>/\,/igs;
			$prod_detail = &DBIL::Trim($prod_detail);
			$prod_detail=~s/\s*\,/\,/igs;
			}
		
		#size
		my  @sizes;
		if( $content2 =~ m/Please\s*Select\s*Size([\w\W]*?)<\/div>/is )
		{
			my $sizeblock=$1;
			while ($sizeblock=~m/<option\s*value\=[^>]*?>([^>]*?)<\/option>/igs)
			{
				my $size=$1;
				push (@sizes, $size);
			}
		}
		
		#color
		my @colors;
		if( $content2 =~ m/Please\s*Select\s*Colour([\w\W]*?)<\/div>/is )
		{
			my $colorblock=$1;
			while ($colorblock=~m/<option\s*value\=[^>]*?>([^>]*?)<\/option>/igs)
			{
				my $color=$1;
				push (@colors, $color);
			}
		}
		
		#total color and sizes
		my @total_value;
		foreach my $temp(@colors)
		{
			foreach my $temp1(@sizes)
			{
				my $compare_value=$temp."-".$temp1;
				push(@total_value,$compare_value);
			}
		}
		
		#Avilable sizes with color
		my (@avilable_sizes_colors);
		while ( $content2 =~ m/Venda\.Attributes\.StoreJSON\(\{\"att1\"\:\"([^>]*?)\"\,\"att3\"\:\"\"\,\"att2\"\:\"([^>]*?)\"\,\"att4/igs )
		{
			my $avilablecolor=$1;
			my $avilablesize=$2;
			my $avilable_size_color=$avilablecolor."-".$avilablesize;
			push(@avilable_sizes_colors,$avilable_size_color);
		}
		my $color;
		my $size;
		$price_text=~s/\£/\Â\£/igs;
		for (my $i=0; $i<=$#total_value; $i++)
		{
			my $flag1;
			if($total_value[$i]=~m/^([^>]*?)\-([^>]*?)$/is)
			{
				$color=$1;
				$size=$2;
			}
			my $flag;
			for (my $j=0; $j<=$#avilable_sizes_colors;$j++)
			{
				
				if ($total_value[$i] eq $avilable_sizes_colors[$j])
				{
					 $flag=1;
					last;
				}
				else
				{
					 $flag=0;
				}
			}
			if($flag eq '1')
			{
				$out_of_stock='n';
			}
			else
			{
				$out_of_stock='y';
			}
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=lc($color);
			$color_hash{$color}='';	
			push(@query_string,$query);
		}
		undef $color;
		undef $size;
		undef @avilable_sizes_colors;
		undef @total_value;
		
		#Swatch_image
		while ($content2=~m/SwatchURL\[\"([^>]*?)\"\]\s*\=\s*\"([^>]*?)\"/igs)
		{
			my $swatch_colour=&DBIL::Trim($1);	
			my $swatch = &DBIL::Trim($2);
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$image_objectkey{$img_object}=lc($swatch_colour);
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
		}
		
		#product_image
		my (@main_image,@alt_image,@imagecolor);
		while ($content2=~m/Venda.Attributes.fatFaceImageGallery[^>]*?\"param\"\s*\:\s*\"([^>]*?)\"[\w\W]*?imgL([\w\W]*?)\]/igs)
		{
			my $image_color=$1;
			my $imageblock=$2;
			push (@imagecolor,$image_color);
			
			my $count=1;
			my %hash_image;
			while($imageblock=~m/(http[^>]*?)\"/igs)
			{
				my $product_image1=$1;
				if($count ==1)
				{
					if($hash_image{$product_image1} eq '')
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=lc($image_color);
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}
					$count++;
				}
				else
				{
					push(@alt_image,$product_image1);
					# if($hash_image{$product_image1} eq '')
					# {
						# my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
						# my ($img_object,$flag) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						# $imageflag = 1 if($flag);
						# $image_objectkey{$img_object}=$image_color;
						# $hash_default_image{$img_object}='n';
						# $hash_image{$product_image1} = $image_color;
					# }
				}
			}
			@alt_image=uniq(@alt_image);
		}
		# print "MainImages=>>>@main_image\n";
		# print "AlternateImages=>>>@alt_image\n";
		# my $m=0;
		# foreach my $mainimage(@main_image)
		# {
			# my $colorssss=$imagecolor[$m];
			# my $main_image =&DBIL::Trim($mainimage);
			# my ($imgid,$img_file) = &DBIL::ImageDownload($main_image,'product',$retailer_name);
			# my ($img_object,$flag) = &DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			# $imageflag = 1 if($flag);
			# $image_objectkey{$img_object}=$colorssss;
			# $hash_default_image{$img_object}='y';	
			# $m++;
		# }
		my $altimage;
		foreach $altimage(@alt_image)
		{
			my $colorsss=$imagecolor[0];
			my $alt_image =&DBIL::Trim($altimage);
			my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=lc($colorsss);
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
		}
		# undef @main_image;
		undef @alt_image;
		# undef @imagecolor;
		undef $altimage;
		# undef $mainimage;
		
		
		$brand='Fatface';
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		dup_productid:
		print "";
		$dbh->commit();
	}
}1;
sub lwp_get() 
{ 
    REPEAT: 
    my $url = $_[0];
    my $req = HTTP::Request->new(GET=>$url);
    $req->header("Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"); 
    $req->header("Content-Type"=>"application/x-www-form-urlencoded"); 
    my $res = $ua->request($req); 
    $cookie->extract_cookies($res); 
    $cookie->save; 
    $cookie->add_cookie_header($req); 
    my $code = $res->code(); 
    print $code,"\n"; 
    open LL,">>".$retailer_file;
    print LL "$url=>$code\n";
    close LL;
    if($code =~ m/50/is) 
    {        
        goto REPEAT; 
    } 
    return($res->content()); 
}
