#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Charlotterusse_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Charlotterusse_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Charlotterusse-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Cha';
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
	
	my $skuflag = 0;my $imageflag = 0;my $mflag=0;my @query_string;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		print "\nUrl : $url3\n";
		
		my $content2 = &get_content($url3); ### Getting product url content
		goto PNF if($content2==1); ### Check whether the product is 'x' or not
		my %tag_hash;my %color_hash;my %prod_objkey;my %size_hash;
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color,$price_id);
		
		#product_id and checkind duplication
		if ( $content2=~m/Style\:\s*<[^>]*?>([^>]*?)<[^>]*?>/is )
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto dup_productid if($ckproduct_id == 1);
		}
		
		#price_text
		if ( $content2=~m/>Price\:[^<]*?<\/label>\s*<span\s*id\=\"jsonPDP_([\d]+_[\d]+)_PRICE\"\s*class\=\"[^\"]*?\"><\/span>\s*<strike\s*id\=\"jsonPDP_[\d]+_[\d]+_MSRP\"\s*class\=\"[^\"]*?\">\s*([^<]+?)\s*<\/strike>\s*<span\s*id\=\"jsonPDP_[\d]+_[\d]+_DPRICE\"\s*class\=\"[^\"]*?\">\s*([^<]+?)\s*<\/span>\s*<span\s*id\=\"jsonPDP_[\d]+_[\d]+_you\-save\-message\"\s*class\=\"[^\"]*?\"\s*>\s*\(\s*([^<]+?)\s*<[^>]*?>\s*([^<]+?)\s*<\/span>\)<\/span>\s*<\/div>\s*<div\s*id\=\"jsonPDP_[\d]+_[\d]+_MSG\"\s*class\=\"promoMessages\">\s*<div\s*class\=\"promoMsgText\">\s*(NOW\s*\:\s*\$([^<]+?))<span[^>]*?>/is )
		{
			$price_id=$1;
			$price_text = $2." $3 $4 $5 $6";
			# $price=$7;
			# $price=~s/\$//igs;$price=~s/\,//igs;$price=~s/\.00//igs;
		}
		elsif ( $content2=~m/>Price\:[^<]*?<\/label>\s*<span\s*id\=\"jsonPDP_([\d]+_[\d]+)_PRICE\"\s*class\=\"[^\"]*?\">\s*([^<]+?)\s*<\/span>\s*<strike\s*id\=\"jsonPDP_[\d]+_[\d]+_MSRP\"\s*class\=\"[^\"]*?\"><\/strike>\s*<span\s*id\=\"jsonPDP_[\d]+_[\d]+_DPRICE\"\s*class\=\"[^\"]*?\"><\/span>\s*<span\s*id\=\"jsonPDP_[\d]+_[\d]+_you\-save\-message\"\s*class\=\"[^\"]*?\"\s*>\s*<\/span>\s*<\/div>\s*<div\s*id\=\"jsonPDP_[\d]+_[\d]+_MSG\"\s*class\=\"promoMessages\">\s*<div\s*class\=\"promoMsgText\">\s*(NOW\s*\:\s*\$([^<]+?))<span[^>]*?>/is )
		{
			$price_id=$1;
			$price_text = $2." $3";
			# $price=$4;
			# $price=~s/\$//igs;$price=~s/\,//igs;$price=~s/\.00//igs;
		}
		elsif ( $content2=~m/>Price\:[^<]*?<\/label>\s*<span\s*id\=\"jsonPDP_([\d]+_[\d]+)_PRICE\"\s*class\=\"[^\"]*?\">\s*([^<]+?)\s*<\/span>\s*<strike\s*id\=\"jsonPDP_[\d]+_[\d]+_MSRP\"\s*class\=\"[^\"]*?\"><\/strike>\s*<span\s*id\=\"jsonPDP_[\d]+_[\d]+_DPRICE\"\s*class\=\"[^\"]*?\"><\/span>\s*<span\s*id\=\"jsonPDP_[\d]+_[\d]+_you\-save\-message\"\s*class\=\"[^\"]*?\"\s*>\s*<\/span>\s*<\/div>/is )
		{
			$price_id=$1;
			$price_text = &DBIL::Trim($2);
			# $price=$price_text;
			# $price=~s/\$//igs;$price=~s/\,//igs;$price=~s/\.00//igs;
		}
		elsif($content2=~m/>Price\:[^<]*?<\/label>\s*<span\s*id\=\"jsonPDP_([\d]+_[\d]+)_PRICE\"\s*class\=\"[^\"]*?\"><\/span>\s*<strike\s*id\=\"jsonPDP_[\d]+_[\d]+_MSRP\"\s*class\=\"[^\"]*?\">\s*([^<]+?)\s*<\/strike>\s*<span\s*id\=\"jsonPDP_[\d]+_[\d]+_DPRICE\"\s*class\=\"[^\"]*?\">\s*([^<]+?)\s*<\/span>\s*<span\s*id\=\"jsonPDP_[\d]+_[\d]+_you\-save\-message\"\s*class\=\"[^\"]*?\"\s*>\s*([\w\W]+?)\s*<\/span>\s*<\/div>/is )
		{
			$price_id=$1;
			$price_text = $2." $3"." $4";
			# $price=$3;
			&DBIL::Trim($price_text);
			# $price=~s/\$//igs;$price=~s/\,//igs;$price=~s/\.00//igs;
		}
		$price_text=~s/\,//igs;
		#### Price... Price is will be getting from separate URL which is framed using price id.
		my $price_url='http://www.charlotterusse.com/jsonp/ajaxPackager/ajaxPackage.jsp?cb=binder.commonJSON.vars.JSONP[1401520708811]&promoEntityIds='.$price_id.'&formatPromo=2';
		my $price_cont = &get_content($price_url);### Price content
		if($price_cont=~m/\"\s*NOW\s*\:\s*([\$\d\.\,]*?)\s*\"/is)
		{
			$price=$1;
			$price=~s/\$//igs;$price=~s/\,//igs;$price=~s/\.00//igs;
			if($price=~m/[a-z]+/is)
			{
				if($price_cont=~m/\"\s*DPRICE\"\s*\:\s*\"([\$\d\.\,]*?)\s*\"/is)
				{
					$price=$1;
					$price=~s/\$//igs;$price=~s/\,//igs;$price=~s/\.00//igs;
				}
			}
		}
		elsif($price_cont=~m/\"\s*PRICE\"\s*\:\s*\"([\$\d\.\,]*?)\s*\"/is)
		{
			$price=$1;
			$price=~s/\$//igs;$price=~s/\,//igs;$price=~s/\.00//igs;$price=~s/\s+//igs;
		}
		
		#product_name over
		if ( $content2=~m/<div\s*class=\"item\-name\">([^>]*?)<\/div>/is )
		{
			$product_name = &DBIL::Trim($1);
		}

		$brand='Charlotterusse';
		#description over
		if ( $content2=~m/<div\s*class=\"richtext\">([^^]*?)<\/div>/is )
		{		
			$description = &DBIL::Trim($1);			
		}

		#details over
		if ( $content2=~m/<table[^>]*?\"productDetailsTable\"\s*>([^^]*?)<\/table>/is )
		{		
			$prod_detail = &DBIL::Trim($1);
		}
				
		# size & out_of_stock & color over
		if ( $content2=~m/VARIANT_ID[^>]*?\"stock\"\:([^>]*?)\,\"price\"\:\"([^\"]*?)\"\,\"SIZE_NAME\"\:\"([^>]*?)\"\,[^>]*?swatchColorName\"\:\"([^>]*?)\"\,\"isPreorderable/is )
		{
			my %color_hash;
			while ( $content2=~m/VARIANT_ID[^>]*?\"stock\"\:([^>]*?)\,\"price\"\:\"([^\"]*?)\"\,\"SIZE_NAME\"\:\"([^>]*?)\"\,[^>]*?swatchColorName\"\:\"([^>]*?)\"\,\"isPreorderable/igs )
			{
				my $stock_det=$1;
				my $price1=$2;
				my $size = &DBIL::Trim($3);
				$color= &DBIL::Trim($4);
				
				$price1=~s/\$//igs;$price1=~s/\,//igs;$price1=~s/\.00//igs;
				$price=$price1 if($price eq '');
				$price='NULL' if($price eq '');
				my $out_of_stock='y';
				$out_of_stock = 'n' if $stock_det=~m/true/is;			
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				$color_hash{$color}='';
				push(@query_string,$query);
			}
		}
		
		#swatchimage
		my %swatch_hash;
		while ( $content2=~m/\{\"colorName\"\:\"([^>]*?)\"\,\"altImagesSize\"\:[^>]*?\,\"swatchImg\"\:\"([^>]*?)\"\,\"altImages/igs )
		{
			my $colour_id=$1;
			my $swatch ='http://s7d9.scene7.com/is/image/CharlotteRusse/'.&DBIL::Trim($2);		
			if(%swatch_hash~~/$swatch/)
			{
				# print "Already exist\n";
			}
			else
			{
				$swatch_hash{$swatch}='';
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$image_objectkey{$img_object}=$colour_id;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
		}
		
		#Image
		
		my %altimage_hash;
		while ( $content2=~m/\{\"colorName\"\:\"([^>]*?)\"\,\"altImagesSize\"\:[^>]*?\,\"swatchImg\"\:\"[^>]*?\"\,\"altImages\":\[([^>]*?)\]/igs )
		{
			my $col_id=$1;
			my $alt_image_content = $2;		
			my $img_count=0;
			while ( $alt_image_content =~ m/([\w]+)/igs )
			{
				$img_count++;
				my $alt_image ='http://s7d9.scene7.com/is/image/CharlotteRusse/'.&DBIL::Trim($1);
				my $img_file;
				$alt_image =~ s/\\\//\//g;			
				$img_file = (split('\/',$alt_image))[-1];				
				if(%altimage_hash~~/$alt_image/)
				{
					# print "alt image already exist\n";
				}
				else
				{
					$altimage_hash{$alt_image}='';
					if ( $img_count == 1 )
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$col_id;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);					
					}
					else
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$col_id;
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
		PNF:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		dup_productid:
		$dbh->commit();
	}
}1;

sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	Home:
	my $ua=LWP::UserAgent->new;
	$ua->agent("User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (.NET CLR 3.5.30729)");
	my $cookie = HTTP::Cookies->new(file=>$0."_cookie.txt",autosave=>1);
	$ua->cookie_jar($cookie);
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
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
		# print "\n----\n$url-----\n";
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
}