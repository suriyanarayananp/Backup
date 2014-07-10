#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Countryroad_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
use utf8;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";

###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Countryroad_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Countryroad-AU--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Cou';
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
		$url3='http://www.countryroad.com.au'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content = &lwp_get($url3);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my (%sku_objectkey,%image_objectkey,%hash_default_image,%color_code);
		my @color_arr;
		my ($price,$price_text,$brand,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		#Price & Price_text
		if ( $content =~ m/<div[^>]*?class="price\wbreak\s*default[^>]*?>([\w\W]*?)<\/div>/is )
		{
			$price_text = $1;
			if ($price_text =~ m/<span[^>]*?itemprop\=\"price[^>]*?>([\w\W]*?)<\/span>/is )
			{
				$price = $1;
			}
			$price_text =~ s/<[^>]*?>/ /igs;
			# $price_text =~ s/\Â/ /igs;
			$price_text =~ s/\s+/ /igs;
			$price_text=~s/\$\s+/\$/igs;
			$price_text =~ s/^\s+//is;
			$price_text =~ s/\s+$//is;
			
			# $price_text=decode_entities($price_text);
			utf8::decode($price_text);
			
			$price=~s/<[^>]*?>/ /igs;
			$price=~s/\s+/ /igs;
			$price=~s/^\s+/ /is;
			$price=~s/\s+$/ /is;
		}
		#Product_id
		if ( $content =~ m/<li[^>]*?>\s*style\s*code\s*\:\s*([\w\W]*?)<\/li>/is )
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#Product_name
		if ( $content =~ m/<h1[^>]*?itemprop\=\"name[^>]*?>([\w\W]*?)<\/h1>/is )
		{
			$product_name = &DBIL::Trim($1);
			$product_name=decode_entities($product_name);
			utf8::decode($product_name);
		}

		$brand = "Country Road";

		#Description
		if( $content =~ m/<div[^>]*?class="content\s*long_description[^>]*?>\s*([\w\W]*?)\s*<\/div>/is )
		{
			$description = &DBIL::Trim($1);
			$description=decode_entities($description);
			utf8::decode($description);
		}
		#Prod_details
		if( $content =~ m/Product\s*details[\w\W]*?<div[^>]*?>\s*([\w\W]*?)<\/div>/is )
		{
			$prod_detail = &DBIL::Trim($1);
			$prod_detail=decode_entities($prod_detail);
			utf8::decode($prod_detail);
		}
		#Colour & Swatch
		
		if ( $content =~ m/Select\s*Colour\s*([\w\W]*?)\s*<\/fieldset>/is )
		{
			my $colour_content = $1;
			#while( $colour_content =~ m/<li\s*class\=\"([^>]*?)\s*[on]*?\s*\">\s*(?:<[^>]*?>)\s*<label\s*for\=\"colour[^>]*?\s*title\=\"([^<]*?)\"[^>]*?><img\s*src\=\"([^<]*?)\"[^>]*?>\s*<\/label>\s*<\/li>/igs)
			while( $colour_content =~ m/<li\s*class\=\"([^>]*?)\s*[on]*?\s*\">\s*(?:<[^>]*?>)\s*<label\s*for\=\"colour[^>]*?\s*title\=\"([^<]*?)\"[^>]*?>([\w\W]*?)\s*<\/label>\s*<\/li>/igs )
			{
				my $color_codes 	= &DBIL::Trim($1);
				my $color 		= &DBIL::Trim($2);
				my $swatch_content 	= $3;
				
				push(@color_arr,$color);
				$color_code{$color} = $color_codes;
				
				if ( $swatch_content =~ m/<img[^>]*?src\=\"([^<]*?)\"[^>]*?>/is )
				{
					my $swatch = &DBIL::Trim($1);	
					my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
					$image_objectkey{$img_object}=lc($color);
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
			}
		}
		
		# size & out_of_stock
		if ( $content =~ m/<fieldset[^>]*?>\s*<legend[^>]*?>\s*Size\s*<\/legend>\s*([\w\W]*?)\s*<\/fieldset>/is )
		{
			my $size_content = $1;
			foreach my $color ( @color_arr )
			{
				# $color_code{$color};
				if( $size_content =~ m/<li[^>]*?class\=\"$color_code{$color}\"[^>]*?>\s*([\w\W]*?)\s*<\/li>/is )
				{
					my $outstock_content = $1;
					while($outstock_content=~m/<option[^>]*?value\=\"[\d]+\"[^>]*?>\s*([^>]*?)\s*<\/option>/igs)
					{
						my $size_det = &DBIL::Trim($1);
						my $out_of_stock;
						my $size;
						if($size_det=~m/([^>]*?)\s*-\s*Not\s*Available/is)	
						{
							$size = &DBIL::Trim($1);
							$out_of_stock = 'y';
						}
						else
						{
							$size = $size_det;
							$out_of_stock = 'n';
						}
												
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=lc($color);
						push(@query_string,$query);
					}
				}
			}
		}
		else
		{
			foreach my $color ( @color_arr )
                        {
				my $size = "One Size";
				my $out_of_stock = 'n';
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=lc($color);
				push(@query_string,$query);
			}
		}
		
		# Image
		if ( $content =~ m/<figure\s*class\=\"product_image\"[^>]*?>([\w\W]*?)<\/figure>/is )
		{
			my $img_content = $1;
			foreach my $color ( @color_arr )
			{
				my $flag1 = 0;
				if( $img_content =~ m/<ul[^>]*?class\=\"altimages\s*$color_code{$color}\s*[^>]*?>\s*([\w\W]*?)\s*<\/ul>/is )
				{
					my $image_content1 = $1;
					while($image_content1=~m/<li[^>]*?>\s*<a[^>]*?data-mainimage\=\"[^>]*\s*href\=\"*([^<]*?.jpg)\"[^>]*?>\s*(?:<[^>]*?>)?<\/a>\s*<\/li>/igs)
					{
						my $img_url = &DBIL::Trim($1);
						my ($imgid,$img_file) = &DBIL::ImageDownload($img_url,'product',$retailer_name);
						if($flag1 == 0)
						{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$img_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=lc($color);
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
							$flag1++;
						}
						else
						{
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$img_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=lc($color);
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
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
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:	
		$dbh->commit();
	}
}1;
# &DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
# $dbh->commit();
# $dbh->disconnect();
#&DBIL::SaveDB("Delete from Product where detail_collected='d' and RobotName=\'$robotname_list\'",$dbh,$robotname);

sub lwp_get()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $req = HTTP::Request->new(GET=>$url);
	$req->header("Content-Type"=> "text/plain");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
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
			goto Home;
		}
	}
	return $content;
}
