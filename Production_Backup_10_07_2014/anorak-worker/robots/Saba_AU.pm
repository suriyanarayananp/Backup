#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Saba_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
# use DBI;
use DateTime;
use utf8;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name, $robotname_detail, $robotname_list, $Retailer_Random_String, $pid, $ip, $excuetionid, $country, $ua, $cookie_file, $retailer_file, $cookie);

sub Saba_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $multiproduct_flag=0;
	my $logger;
	
	$dbh->do("set character set utf8"); ### Setting UTF 8 Characters ###
	$dbh->do("set names utf8");  ### Setting UTF 8 Characters ###
	
	####Variable Initialization##############
	##my $robotname = $0;
	$robotname='Saba-AU--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Sab';
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
	#########################################

	############Cookie File Creation###########
	($cookie_file,$retailer_file) = &DBIL::LogPath($robotname);
	$cookie = HTTP::Cookies->new(file=>$cookie_file,autosave=>1); 
	$ua->cookie_jar($cookie);
	###########################################


	my $select_query = "select ObjectKey from Retailer where name=\'$retailer_name\'";
	my $retailer_id = &DBIL::Objectkey_Checking($select_query, $dbh, $robotname);
	my $hashref = &DBIL::Objectkey_Url($robotname_list, $dbh, $robotname,$retailer_id);
	my %hashUrl = %$hashref;
	
	my $skuflag = 0; my $imageflag = 0;		
	
	if($product_object_key)
	{
		my $url = $hashUrl{$product_object_key};
		my $url3=$url;	
		my $multi_product_flag=0;		
		my @query_string;
		
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		my $content2 = get_content($url3);
		
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my ($price,$price_text,$size,$type,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);
		###goto PNF if($content2=~m/unable\s*to\s*locate\s*any\s*merchandise/is);  ### X products
		if($content2=~m/unable\s*to\s*locate\s*any\s*merchandise/is)
		{
			goto PNF; 
		}		
		#####################Product_Id#####################
		 if ( $content2 =~ m/<span\s*itemprop\=\"productID\">\s*([^>]*?)\s*<\/span>/is )
		 {
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto dup_productid if($ckproduct_id == 1); ### Duplicate Products
			undef ($ckproduct_id);
		 }
		 else
		 {
			$multiproduct_flag=1;
			goto endm;  ### Multi Products
		 }
		####################Product_Name ####################
		if ($content2=~m/<h1\s*class\=\"product\-name\"[^>]*?>\s*([^>]*?)\s*<\/h1>/is)
		{
			$product_name = &DBIL::Trim($1);
		}
		##################### Description #######################
		if ($content2=~m/<div\s*id\=\"tab1\"[^>]*?>\s*([\w\W]*?)\s*<\/div>/is)
		{
			$description =&DBIL::Trim($1);
		}
		
		####################### Colour ########################
		my $content=$content2;
		while ( $content2 =~ m/<a[^>]*?class\=\"swatchanchor\"[^>]*?title\=\"([^>]*?)\"[^>]*?href\=\"([^>]*?)\"[^>]*?>\s*<img[^>]*?src\=\"([^>]*?)\"[^>]*?>/igs )
		{
			$color =&DBIL::Trim($1);
			my $next_colour_url=$2;
			my $swatch= $3;
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
			$image_objectkey{$img_object}=$color;
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
			################ loop match content problem #################
			my $next_colour_content=$content;
			################## loop for Multiple Swatch ##################
			if($next_colour_url ne '' )
			{
				undef $next_colour_content;
				$next_colour_content = get_content($next_colour_url);
				my $alt_image;
				############## loop for Multiple Alternate Images ##############
				while( $next_colour_content =~m/<li\s*class\=\"thumb\s*([^>]*?)\">\s*<a[^>]*?href\=\"([^>]*?.jpg)[^>]*?\"[^>]*?>/igs)
				{
					my $ref=$1;
					$alt_image = $2;
					my $image_status='n';
					$image_status='y' if ( $ref ne '' );
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}=$image_status;
					push(@query_string,$query);
				}
				################### Single Images only ###################
				if($alt_image eq '')
				{
					if($next_colour_content=~m/<img[^>]*?class\=\"primary\-image\"\s*src\=\"([^>]*?)\?[^>]*?>/is)
					{
						$alt_image = &DBIL::Trim($1);
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}="y";
						push(@query_string,$query);
					}
				}
			}
			else
			{
				my $alt_image;
				############### loop for Multiple Alternate Images ##############
				while( $next_colour_content =~m/<li\s*class\=\"thumb\s*([^>]*?)\">\s*<a[^>]*?href\=\"([^>]*?.jpg)[^>]*?\"[^>]*?>/igs)
				{
					my $ref=$1;
					$alt_image = $2;
					my $image_status='n';
					$image_status='y' if ( $ref ne '' );
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}=$image_status;
					push(@query_string,$query);
				}
				#################### Single Images only ####################
				if($alt_image eq '')
				{
					if($next_colour_content=~m/<img[^>]*?class\=\"primary\-image\"\s*src\=\"([^>]*?)\?[^>]*?>/is)
					{
						$alt_image = &DBIL::Trim($1);
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}="y";
						push(@query_string,$query);
					}
				}
			}
			####################### Price Infromation###################
			if ( $next_colour_content =~ m/<div\s*class\=\"product\-price\">\s*([\w\W]*?)\s*<\/div>/is )
			{
				my $temp=$1;
				$price_text = &DBIL::Trim($temp);
				$price =&DBIL::Trim($1) if($price_text=~m/\$([\d\,\.]+)\s*/is);
			}
			my $block=$1 if($next_colour_content=~m/<ul\s*class\=\"swatches\s*size\">([\w\W]*?)<\/ul>/is);
			################ Size and Stock Infromation collection #############
			while ($block=~m/<a[^>]*?class\=\"swatchanchor\"\s*(?:href\=\"([^>]*?)\")?\s*[^>]*?>\s*([^>]*?)\s*<\/a>/igs)
			{
				my $ref=&DBIL::Trim($1);
				my $size=&DBIL::Trim($2);
				my $out_of_stock='n';
				$out_of_stock='y' if ( $ref eq "" );
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
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
		
		
		PNF: ### X products
		print " ";
		endm:  ### M Products
		print " ";
		##end:
		##&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,"saba",$description,$description,$dbh,$robotname,$excuetionid,$skuflag,$imageflag);
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,"saba",$description,$description,$dbh,$robotname,$excuetionid,$skuflag,$imageflag, $url3, $retailer_id, $multiproduct_flag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);
		dup_productid: ### duplicate Products
		print " ";
		
		$dbh->commit();
		print " ";
	}
# ###&DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
}1;

sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	$url =~ s/amp\;//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	open fh,">>$retailer_file";
	print fh " $url=>$code \n";
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
			sleep(30);
			goto Home;
		}
	}
	return $content;
}