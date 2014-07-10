#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Sussan_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
##require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Sussan_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger;
	
	$dbh->do("set character set utf8"); ### Setting UTF 8 Characters ###
	$dbh->do("set names utf8");  ### Setting UTF 8 Characters ###
	
	####Variable Initialization##############
	$robotname='Sussan-AU--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Sus';
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
	
	my $skuflag = 0;my $imageflag = 0;
	if($product_object_key)
	{
		my $url3=$url;
		my @query_string;
		$url3 =~ s/^\s+|\s+$//g;
		$url3 =~ s/\"$//g;
		my $content2 = get_content($url3);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock);

		#price_text
		if($content2=~m/catalog_link\">([\w\W]*?)<div[^>]*?DescriptionDiv\">/is)
		{
			my $content = $1;
			if($content =~ m/class\=\"price\s*(?:secPrice)?\"[^>]*?>\s*([^>]*?)\s*</is)
			{
				$price = &DBIL::Trim($1);
				$price_text=$price;
				$price=~s/^\$//igs;
				# print "\n$price\n";
			}
			# else
			# {
				# print "price Not matched";
			# }
			
			if($content =~ m/<span\s*class\=\"listPrice\">([^^]*?style\=\"[^^]*?)<\/span>/is)
			{
				$price_text = &DBIL::Trim($1);
			}
			elsif($content =~ m/productPromotions\">([^>]*?)<\/span>/is)
			{
				$price_text="$price_text $1";
				$price_text = &DBIL::Trim($price_text);
			}
		}
		
		if($content2 =~ m/class\=\"font3\"\s*style\=\"font\-size[^>]*?>\s*([^>]*?)\s*</is)
		{
			$product_id = &DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto dup_productid if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		# else
		# {
			# print "product_id Not matched";
		# }


		#product_name
		if($content2 =~ m/breadcrumb_current\">\s*([^>]*?)\s*</is)
		{
			$product_name = &DBIL::Trim($1);
		}
		# else
		# {
			# print "product_name Not matched";
		# }

		
		# description
		if ($content2 =~ m/id\=\"DescriptionDiv\"\s*>\s*(?:<[^>]*?>)?\s*([^>]*?)\s*</is)
		{		
			$description = &DBIL::Trim($1);		
		}
		# else
		# {
			# print "\nDescription not matched\n";
		# }
		
		if ($content2 =~ m/id\=\"DescriptionDiv\"\s*>[\w\W]*?<span>([^>]*?)</is)
		{		
			$prod_detail = &DBIL::Trim($1);
		}
		# else
		# {
			# print "\nProduct details regex not matched\n";
		# }
		
		
		######################size & out_of_stock##########################################
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		while($content2 =~ m/\"catentry_id\"\s*\:([\w\W]*?\"Availability\"\s*:\s*\"[\w]*\")\,/igs )
		{
				my $size_content = $1;
				my ($size,$availabilty,$color);
				if($size_content=~m/\"Colour_([^>]*?)\"\s*\:/is)
				{
					$color=$1;
				}
				if($size_content=~m/\"Size_([^>]*?)\"\s*\:/is)
				{
					$size=$1;
				}
				
				my $out_of_stock;
				if($size_content=~m/\"Availability\"\s*:\s*\"([^>]*?)\"/is)
				{
					$availabilty=$1;
					if($availabilty eq 'Available')
					{
						$out_of_stock = 'n';
					}
					elsif($availabilty eq 'Unavailable')
					{
						$out_of_stock = 'y';
					}
					else
					{
						# $out_of_stock = 'n';
						# print "\nRegex not matched\n";
					}
				}
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
		}
		
		############################## Production Url Block ###############################################
		my $content3=$content2;
		my $k =0;
		while($content3=~m/\"catentry_id\"\s*\:([\w\W]*?\"Availability\"\s*:\s*\"[\w]*\")\,/igs)
		{
			my $alt_image_content = $1;
			my ($color);
			if($alt_image_content=~m/\"Colour_([^>]*?)\"\s*\:/is)
			{
				$color=$1;
			}
			my $image_color=$color if($k eq 0);
			$image_color=$color if($k eq 1);
			if($k > 0)
			{
				if($image_color ne $color)
				{
					$image_color = $color;
				}
				else
				{
					$k++;
					next;
				}
			}
			$k++;
		}
		
		################################ Image Block ##################################################
		my $image_id;
		if($content2=~m/id\=\"productZoomImageMsgValAftTrimID\"\s*value\=\"([\d]+)\"/is)
		{
			$image_id=$1;
		}
		# else
		# {
			# print "\nimage id not matched\n";
		# }
		# print "\n$image_id\n";
		my $res2;
		my $count=0;
		my $content4=$content2;
		while($content4=~m/\"catentry_id\"\s*\:([\w\W]*?\"Availability\"\s*:\s*\"[\w]*\")\,/igs)
		{
			my $alt_image_content = $1;
			my ($main_image,$color,$img_file);
			if($alt_image_content=~m/\"image_m\"\s*\:\s*\"([^>]*?)\"/is)
			{
				my $alt_image=$1;
				if($alt_image=~m/([^>]*?)([_\d_\w_\d\s]*).jpg$/is)
				{
					$main_image='http://'.$1.$image_id.'_'.$2.'.jpg';
					# print "\n$main_image\n";
				}
				# else
				# {
					# print "\nAlternate Image not matched\n";
				# }
			}
			# else
			# {
				# print "\nAlternate Image Content not matched\n";
			# }
			if($alt_image_content=~m/\"Colour_([^>]*?)\"\s*\:/is)
			{
				$color=$1;
			}
			my $image_color=$color if($count eq 0);
			$image_color=$color if($count eq 1);
			$main_image =~ s/\\\//\//g;			
			$img_file = (split('\/',$main_image))[-1];
			if($count > 0)
			{
				if($image_color ne $color)
				{
					$image_color = $color;
				}
				else
				{
					$count++;
					next;
				}
			}
			my ($imgid,$img_file) = &DBIL::ImageDownload($main_image,'Product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
			$image_objectkey{$img_object}=$color;
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);
			for(my $y=2;$y<=4;$y++)
			{
				my $alter_image=$main_image;
				my $alternate_image;
				if($alter_image=~m/([^>]*?)_[\d]\.jpg$/igs)
				{
					$alternate_image=$1.'_'.$y.'.jpg';
				}
				# print "\n$alternate_image\n";
				$alternate_image =~ s/\\\//\//g;			
				my $img_file1 = (split('\/',$alternate_image))[-1];
				my $i_con=&get_content_code($alternate_image);
				###if($i_con!~m{<[^<>]*?>}is)  
				if($i_con=~m/\s*200\s*/is)
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($alternate_image,'Product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alternate_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
					#### last; 
				}
				# my ($imgid,$img_file) = &DBIL::ImageDownload($alternate_image,'Product',$retailer_name);
				# my ($img_object,$flag) = &DBIL::SaveImage($imgid,$alternate_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);			
				# $image_objectkey{$img_object}=$color;
				# $hash_default_image{$img_object}='n';
			}
			$count++;
		}
		my $brand='sussan';
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
			
		###############################
		PNF:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);
		###end:
		$dbh->commit();
		print "end";
		dup_productid:
		$dbh->commit();
	}
}1;

sub get_content
{
	my $url = shift;
	
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	print "URL:: $url \n";
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
	open LL,">>".$retailer_file;
    print LL "$url=>$code\n";
    close LL;
	my $content;
	if($code =~m/20/is)
	{
		$content = $res->content;
	}
	elsif($code =~m/40/is)
	{
		print "\nUrl not found\n";
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


sub get_content_code
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
	# open LL,">>".$retailer_file;
    # print LL "$url=>$code\n";
    # close LL;
	my $content;
	if($code =~m/20/is)
	{
		# $content = $res->content;
		return($code);
	}
	elsif($code =~m/40/is)
	{
		print "\nUrl not found\n";
		return($code);
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			goto Home;
		}
	}
	return $code;
}