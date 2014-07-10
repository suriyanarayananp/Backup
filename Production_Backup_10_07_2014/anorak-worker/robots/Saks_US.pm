#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Saks_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use URI::Escape;
use DateTime;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBIL_Updated/DBIL.pm"; # USER DEFINED MODULE DBIL.PM
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Saks_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Saks-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Sak';
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
		$url3='http://www.saksfifthavenue.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = &lwp_get($url3);
		my $cont1=$content2;
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$img_file,$imagei,$imagelist,$imageid,$colorid,$imageurl,$image1,$size,$defualtimage,$multicol);
		my(@imagearry,@imageconarry,@swatcharry);
		my @query_string;
		my (%size_hash,%swatch_hash,%sku_objectkey,%image_objectkey,%hash_default_image,%swat_hash);
		if($content2=~m/<div\s*class\=\"pdp\-reskin\-right\-container\s*\">([\w\W]*?)end\s*productCopy\-container/is)
		{
			$content2=$1;
		}
		my $mflag;
		if($content2=~ m/<title>\s*Product_Not_Available\s*<\/title>/is)
		{
			goto MP;
		}
		if($content2=~m/Collection\s*Details/s)
		{
			$mflag = 1;
			goto MP;
		}
		#product_id
		if ( $content2 =~ m/Eprd_id\=\s*([^>]*?)\&/is )
		{
			$product_id = trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#Brand_name 
		if ( $content2 =~ m/<h1\s*class\=\"brand\">\s*([^>]*?)\s*<\/h1>/is )
		{
			$brand=trim($1);
			&DBIL::SaveTag('Designer',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
			
		}
		#Product_name
		if ($content2 =~m/<h2\s*class\=\"description\">\s*([^>]*?)(?:<br>|<\/h2>)/is)
		{
			$product_name=trim($1);
			
		}
		#image Reference id
		if ( $content2 =~ m/<h3\s*class\=\"product\-code\-reskin\">\s*([^>]*?)\s*<\/h3>/is )
		{
			$imageid=trim($1);
		
		}
		#price_text
		if ( $content2 =~ m/class\=\"reskin\-price\-container\">([\w\W]*?)<\/td>/is )
		{
			$price_text=trim($1);
			
		}
		#price
		if($price_text=~ m/Now\s*\$([\d+\.]*?)\s*$/is)
		{
			$price=trim($1);
			
		}
		else
		{
			if($price_text=~ m/\$([\d+\.]*?)\s*$/is)
			{
				$price=trim($1);

			}
		}
		#price
		if($content2 =~ m/<div\s*class\=\"soldout\-message\">/is)
		{
			$price='NULL' if($price eq '');
			
		}
		if($content2 =~ m/class\=\"pdp\-reskin\-detail\-content\"[^^]*?<p>([^>]*?)\./is)
		{
			$description=trim($1);
			
		}
		#prod_detail
		if($content2 =~ m/class\=\"pdp\-reskin\-detail\-content\"[^^]*?<ul>([\w\W]*?)(?:<\/ul>|<\/span>)/is)
		{
			$prod_detail=trim($1);
			
		}
		#image
		my $imageconurl="http://image.s5a.com/is/image/saks/$imageid\_IS?req=imageset&locale=en";
		
		my $imagecont=&getcont_image($imageconurl);
		
		if($imagecont=~ m/^([^>]*?)\s*$/is)
		{
			$imagelist=$1;
		}
		if($imagecont=~ m/^([^>]*?)\;/is)
		{
			my $testid=$1;
			$defualtimage="http://image.s5a.com/is/image/".$testid."?scl=1";
			
		}
		@imageconarry=split(/;|,/,$imagelist);
		foreach(@imageconarry)
		{
			my $image="http://image.s5a.com/is/image/".$_."?scl=1";
			push(@imagearry,$image);
		}
		if($content2 =~ m/data\-url\=\"saks\/$imageid/is)
		{
			$colorid=$1;
			my $image=$2;
			while($content2=~m/data\-color\=\"([^>]*?)\"[^>]*?data\-url\=\"([^>]*?)\"/igs)
			{
				$colorid=$1;
				my $image=$2;
				$image1="http://image.s5a.com/is/image/".$image."?scl=1";
				
				push(@imagearry,$image1);
				push(@swatcharry,$image1);
				$swat_hash{$image1}=$colorid;
			}
			if($content2=~m/data\-color\=\"([^>]*?)\"[^>]*?data\-url\=\"([^>]*?)\"/is)
			{
				$multicol=$1;
			}
		}
		my @imagearry1=keys %{{ map { $_ => 1 } @imagearry }};
		foreach(@imagearry1)
		{
			$imageurl=$_;
			my $sku_has_color;
			$sku_has_color=$imageid;
		
			
			my $swatchsize=@swatcharry;
			$sku_has_color=$multicol if($swatchsize > 1);
			
			foreach(@swatcharry)
			{
				my $testurl=$_;
				if($imageurl eq $testurl)
				{
				
					my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$swat_hash{$testurl};
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
					goto NP;
					
				}
			}
			unless($content2 =~ m/id\=\"colorSizeBR0\">[\w\W]*?Choose\s*Color\s*and\/or\s*Size([\w\W]*?)<\/select> /is)
			{
				$imageid="NO COLOR";
				$sku_has_color="NO COLOR";
			}
			if($imageurl eq $defualtimage )
			{
			
				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$imageid;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
				goto NP;
			}
			
			my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$sku_has_color;
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
			NP:
			print"";
			
		}
		#Sku
		if($content2 =~ m/id\=\"colorSizeBR0\">[\w\W]*?Choose\s*Color\s*and\/or\s*Size([\w\W]*?)<\/select>/is)
		{
			my $skucon=$1;
			while($skucon=~ m/data\-product\-size\=\"\s*([^>]*?)\s*\"\s+[^>]*?data\-colorname\=\"\s*([^>]*?)\s*\"[^>]*?>\s*([\w\W]*?)\s*<\/option>/igs)
			{
				$size=trim($1);
				$color=trim($2);
				my $out_stock_con=trim($3);
				$size="NO SIZE" if($size=~m/^\.$/is);
				# goto SN  unless($out_stock_con=~m/\Q$size\E|\Q$color\E/is);
				$out_of_stock='n';
				if($out_stock_con=~m/\$([\d+\.]*?)$/is)
				{
					$price=trim($1);

				}
				if($out_stock_con=~m/Sold\s*Out|PRE\-ORDER/is)
				{
					$out_of_stock='y';
				}
				foreach(@swatcharry)
				{
					my $tempsku=$_;
					my $tempswatch=$swat_hash{$tempsku};
					if($tempswatch eq $color)
					{
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
						goto SN;
					}
				}
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$imageid;
				push(@query_string,$query);
				SN:
				print"";
			}
		}
		else
		{
			$size="NO SIZE";
			$color="NO COLOR";
			$out_of_stock="n";
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$color;
			push(@query_string,$query);
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
		# my $query=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		print"";
		$dbh->commit();
	}	
}1;
sub lwp_get() 
{ 
    # REPEAT: 
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
    # if($code =~ m/50/is) 
    # {        
        # goto REPEAT; 
    # } 
    return($res->content()); 
}

sub trim
{
	my $txt = shift;
	
	$txt =~ s/\<[^>]*?\>//ig;
	$txt =~ s/\n+/ /ig;
	$txt =~ s/\"/\'\'/g;
	$txt =~ s/^\s+|\s+$//ig;
	$txt =~ s/\s+/ /ig;
	$txt =~ s/\&nbsp\;//ig;
	$txt =~ s/\&amp\;/\&/ig;
	$txt =~ s/\&bull\;/•/ig;
	$txt =~ s/[^[:print:]]+//igs;
	$txt =~ s/&pound;/£/ig;
	$txt =~ s/Item\s*number//ig;
	$txt =~ s/\{//igs;
	$txt =~ s/\&\#174\;\-/ /igs;
	$txt =decode_entities($txt);
	
	return $txt;
}
sub getcont_image()
{
 my $url = shift;
 my $ref = shift;
 my $rerun_count=0;
 $url =~ s/amp\;//igs; $ref =~ s/amp\;//igs;
 $url =~ s/^\s+|\s+$//igs; $ref =~ s/^\s+|\s+$//igs;
 Home:
 my $req = HTTP::Request->new(GET=>"$url");
 $req->header("Content-Type"=> "text/plain");
 $req->header("Referer"=>"$ref") if($ref ne ''); 
 my $res = $ua->request($req);
 $cookie->extract_cookies($res);
 $cookie->save;
 $cookie->add_cookie_header($req);
 my $code=$res->code;
 open JJ,">>$retailer_file";
 print JJ "$url->$code\n";
 close JJ;
 my $content;
 
  $content = $res->content;
 
 return $content;
}
