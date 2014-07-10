#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Harrods_UK;
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
sub Harrods_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger = shift;
	$robotname='Harrods-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Har';
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
	($cookie_file,$retailer_file)=&DBIL::LogPath($robotname);
	$cookie=HTTP::Cookies->new(file=>$cookie_file,autosave=>1);
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
		my $content2 =&lwp_get($url3);
		# if($content2=~m/<h1>\s*(Whoops\!)\s*<\/h1>/is)
		# {
			# print "\n$1\n";
			# next;
		# }
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my @query_string;
		my ($price,$price_text,$needed_price,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);

		#price_text over
		if( $content2 =~ m/\'was\'>([^^]*?>now[^>]*?<\/span>)/is )
		{
			
			$price_text = &DBIL::Trim($1);
			
			
		}
		elsif ( $content2 =~ m/\"price\">([^^]*?)<\/span>/is )
		{
			$price_text = &DBIL::Trim($1);
			
		}

		#price over
		if ( $content2 =~m/now[^>]*?([\d.,]+)<\/span>/is )
		{
			$price = &DBIL::Trim($1);
			$price=~s/\,//igs;
			decode_entities($price);
		}
		elsif ( $content2 =~m/\"price\">[^>]*?([\d.,]+)<\/span>/is )
		{
			$price = &DBIL::Trim($1);
			$price=~s/\,//igs;
			decode_entities($price);
		}
		
		#product_id over
		if ( $content2 =~ m/Product\s*Code\s*([^>]*?)<\/span>/is )
		{
			$product_id = &DBIL::Trim($1);
			decode_entities($product_id);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto dup_productid if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}

		#product_name over
		if ( $content2 =~ m/productname\">([^^]*?)<\/span>/is )
		{
			$product_name = &DBIL::Trim($1);
			decode_entities($product_name);
		}
		elsif ( $content2 =~ m/class\=\"fn\">([^^]*?)<\/span>/is )
		{
			$product_name = &DBIL::Trim($1);
			decode_entities($product_name);
		}

		#Brand over
		if ( $content2 =~ m/class\=\"brand\">([^^]*?)<\/span>/is )
		{
			$brand = &DBIL::Trim($1);
			decode_entities($brand);
			&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			
		}
		else
		{
			$brand = 'harrods';
			&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			
		}

		#description over
		if ($content2=~m/description\">([^^]*?)<\/p>/is)
		{		
			$description = $1;		
			$description = &DBIL::Trim($description);	
			decode_entities($description);
		}

		#details over
		if ( $content2 =~ m/Details<\/dt>\s*<dd>\s*<ul>([^^]*?)<\/ul>/is )
		{		
			$prod_detail = &DBIL::Trim($1);
			decode_entities($prod_detail);
		}
		
		#colour
		# if ( $content2 =~ m/<label\s*id\=\"colorLabel\">Color\:[^>]*?<\/label>[^^]*?imageMap[^>]*?\=([^^]*?)<\/script>/is )
		# {
			# my $colour_content = $1;
			# if ( $colour_content =~ m/name\"\:\s*\"([^>]*?)\"\s*\}\;/is )
			# {			
				# $color = trim($1);		
			# }
		# }
		
		# size, color & out_of_stock
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my ($size_content,$color_content);
		if($content2 =~ m/(<select\s*name\=\'colour\'\s*id\=\'colour\'[^^]*?<\/select>)[^^]*?(<select\s*id\=\"size\">[^^]*?<\/select>)/is )
		{
			$color_content=$1; $size_content=$2;
			my $inc=2; my %hash_color;
			while( $color_content =~ m/<option\s*value\=\"([^>]*?)\"/igs)
			{
				$color= &DBIL::Trim($1);
				if($hash_color{$color} eq ''){
				$hash_color{$color}=$color;
				}
				else{
				$color=$color.' ('.$inc.')';
				$inc++;
				}
				my $count1=1;
				while ( $size_content =~ m/data\-cprice\=\"[^>]*?([\d.,]+)\"\s*[^>]*?>([^>]*?)<\/option>/igs)
				{		
					my $size = &DBIL::Trim($2);
					$price = &DBIL::Trim($1);
					$price=~s/\,//igs;
					$size ='no size' if($size eq '');
					$out_of_stock = 'n';			
					$out_of_stock = 'y' if($content2=~m/<span>Out\s*of\s*Stock<\/span>/is);
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;
					push(@query_string,$query);
					if($count1==1)
					{
						# $logger->send("$query");
					}
					$count1++;
					
				}
			}
		}
		elsif($content2 =~ m/<select\s*id\=\"size\">([^^]*?)<\/select>/is )
		{
			$size_content=$1;
			my $count2=1;
			while ( $size_content =~ m/data\-cprice\=\"[^>]*?([\d.,]+)\"\s*[^>]*?>([^>]*?)<\/option>/igs)
			{			
				my $size = &DBIL::Trim($2);
				$color ='Not specified';
				$price = &DBIL::Trim($1);
				$price=~s/\,//igs;
				$size ='no size' if($size eq '');
				$out_of_stock = 'n';			
				$out_of_stock = 'y' if($content2=~m/<span>Out\s*of\s*Stock<\/span>/is);
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
				if($count2==1)
				{
					# $logger->send("$query");
				}
				$count2++;
			}
			if( $size_content eq '')
			{
				my $size ='no size';
				$color ='Not specified';
				$out_of_stock = 'n';
				$out_of_stock = 'y' if($content2=~m/<span>Out\s*of\s*Stock<\/span>/is);
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
				# $logger->send("$query");
			}
		}
		elsif($content2 =~ m/data\-cprice\=\"[^>]*?([\d.,]+)\"\s*[^>]*?>([^>]*?)<\/option>/is)
		{
			my $inc=2; my %hash_color;
			my $count3;
			while ( $content2 =~ m/data\-cprice\=\"[^>]*?([\d.,]+)\"\s*[^>]*?>([^>]*?)<\/option>/igs)
			{
				$color = &DBIL::Trim($2);
				my $size ='no size';
				$price = &DBIL::Trim($1);
				$price=~s/\,//igs;
				if($hash_color{$color} eq ''){
				$hash_color{$color}=$color;
				}
				else{
				$color=$color.' ('.$inc.')';
				$inc++;
				}				
				$out_of_stock = 'n';			
				$out_of_stock = 'y' if($content2=~m/<span>Out\s*of\s*Stock<\/span>/is);	
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
				if($count3==1)
				{
					# $logger->send("$query");
				}
				$count3++;
				
			}
		}
		else
		{
			my $size="no size";
			$color='Not specified';
			$out_of_stock = 'n';			
			$out_of_stock = 'y' if($content2=~m/<span>Out\s*of\s*Stock<\/span>/is);
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$color;
			push(@query_string,$query);
			# $logger->send("$query");
		}
		
		
		
		#swatchimage over
		my @colur_t;
		if ( $content2 =~ m/<a\s*class\=\"color_swatch[^>]*?\"\s*href\=\"([^>]*?)\"\s*data\-cname\=\"([^>]*?)\"/is )
		{
			# my $color_main_swat_block=$1;
			my $inc=2; my %hash_color;
			while($content2=~m/<a\s*class\=\"color_swatch[^>]*?\"\s*href\=\"([^>]*?)\"\s*data\-cname\=\"([^>]*?)\"/igs)
			{
				my $swatch = &DBIL::Trim($1);
				my $colour_id=&DBIL::Trim($2);
				
				if($hash_color{$colour_id} eq ''){
				$hash_color{$colour_id}=$colour_id;
				}
				else{
				 $colour_id=$colour_id.' ('.$inc.')';
				 $inc++;
				}
				
				my $img_file = (split('\/',$swatch))[-1];
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'Swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'Swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
				$image_objectkey{$img_object}=$colour_id;
				$hash_default_image{$img_object}='n';
				push(@colur_t,"$colour_id");
				push(@query_string,$query);
			}
		}
		else
		{
			if($content2=~m/src\=\'([^>]*?)\'\s*alt\s*\=\s*\'Thumbnail\'\/>/is)
			{
				while($content2=~m/src\=\'([^>]*?)\'\s*alt\s*\=\s*\'Thumbnail\'\/>/igs)
				{
					push(@colur_t,"Not specified");
				}
			}
			else
			{
				push(@colur_t,"Not specified");
			}
		}
		
		# #Image over
		if ( $content2 =~m/<a\s*class\=\"color_swatch[^>]*?\"\s*href\=\"([^>]*?)\-s\"\s*data\-cname\=\"([^>]*?)\"/is )
		{
			my $inc=2; my %hash_color;
			while( $content2 =~m/<a\s*class\=\"color_swatch[^>]*?\"\s*href\=\"([^>]*?)\-s\"\s*data\-cname\=\"([^>]*?)\"/igs )
			{
				my $alt_image=&DBIL::Trim($1);
				my $color = &DBIL::Trim($2);
				my $count=1;
				my $img_file;
				$alt_image =~ s/\\\//\//g;
				$img_file = (split('\/',$alt_image))[-1];	
				
				if($hash_color{$color} eq ''){
				$hash_color{$color}=$color;
				}
				else{
				 $color=$color.' ('.$inc.')';
				 $inc++;
				}
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'Product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
				
				while($count lt 3)
				{
					my $alt1_image="$alt_image-$count";
					my $check=&lwp_get($alt1_image);
					goto afsdf if($check eq 1);
					my $img1_file;
					$alt1_image =~ s/\\\//\//g;
					$img1_file = (split('\/',$alt1_image))[-1];
					my ($imgid,$img1_file) = &DBIL::ImageDownload($alt1_image,'Product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt1_image,$img1_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
					$count++;
				}
				afsdf:
			}
		}
		elsif ( $content2 =~m/src\=\'([^>]*?)\'\s*alt\s*\=\s*\'Thumbnail\'\/>/is )
		{
			my $count=0;
			my $count_col=0;
			while ( $content2 =~m/src\=\'([^>]*?)\'\s*alt\s*\=\s*\'Thumbnail\'\/>/igs )
			{
				$count++;
				my $alt_image = &DBIL::Trim($1);
				$alt_image=~s/thumbnail/fullScreen/igs;
				$alt_image=~s/_thumb//igs;
				my $img_file;
				$alt_image =~ s/\\\//\//g;
				$img_file = (split('\/',$alt_image))[-1];				
				my $res2;
				
				if ( $count == 1 )
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'Product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
					$image_objectkey{$img_object}=$colur_t[$count_col];
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				else
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'Product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
					$image_objectkey{$img_object}=$colur_t[$count_col];
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				$count_col++;		
			}
		}
		else
		{
			my $count=0;
			my $count_col=0;
			while ( $content2 =~m/<a\s*href\=\"([^>]*?)\"\s*class\=\"product_main_img/igs )
			{
				$count++;
				my $alt_image = &DBIL::Trim($1);
				$alt_image=~s/thumbnail/fullScreen/igs;
				$alt_image=~s/_thumb//igs;
				my $img_file;
				$alt_image =~ s/\\\//\//g;
				$img_file = (split('\/',$alt_image))[-1];				
				my $res2;
				
				if ( $count == 1 )
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'Product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
					$image_objectkey{$img_object}=$colur_t[$count_col];
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				else
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'Product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
					$image_objectkey{$img_object}=$colur_t[$count_col];
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				$count_col++;		
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
