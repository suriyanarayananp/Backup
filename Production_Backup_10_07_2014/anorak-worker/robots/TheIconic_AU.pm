#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package TheIconic_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
use Time::HiRes;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";

###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
my $lifetime_timer = [Time::HiRes::gettimeofday()];
sub TheIconic_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger = shift;
	
	$robotname='TheIconic-AU--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='ico';
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
		$url3='http://www.theiconic.com.au'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = get_content($url3);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my $celapsed = Time::HiRes::tv_interval($lifetime_timer);
		my $ctic = [Time::HiRes::gettimeofday()];
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		# Move to end if the product page is invalid
		goto MP if( $content2 =~m/page\s*you\s*searched\s*for\s*can\s*not \s*be\s*found/is);
		
		#product_id Matching - 10 digit no.
		if ( $content2 =~ m/product_id\'>\s*([^>]*?)\s*<\/span>/is )
		{
			$product_id = &DBIL::Trim($1);		
			print "\n****$product_id****\n";
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			# Goto the End if the Product is Duplicate
			goto ENDLOOP if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		
		#price_text Matching
		if($content2=~m/\"price\s*[^>]*?\"\s*>\s*([\w\W]*?)\s*<\/div>/is)
		{
			$price_text=&DBIL::Trim($1);
			$price_text=~s/Â/ /igs;
			$price_text=~s/^Â//igs;
			$price_text=~s/Â/ /igs;
			$price_text=~s/(WAS)/ $1/igs;
			$price_text=~s/Save//igs;
			# print "Price=>$price_text\n";
		}
		else
		{
			# print "Price Text Not Matching\n";
			# $logger->send("Item $product_object_key - Price Text Empty in $retailer_name");
		}
		
		# Price Matching
		if($content2=~m/selectedSkuPrice\"\s*value\=\"([^>]*?)\"\/?>/is)
		{
			$price = &DBIL::Trim($1);
			if($price=~m/([^>]*?)\-[^>]*?$/is)
			{
				$price=$1;
			}
			$price=~s/^Â//igs;
			$price=~s/$//igs;
			$price=~s/\,//igs;
			# print "Price=>$price\n";
		}
		elsif($content2=~m/<span\s*[^>]*?\"price[^>]*?\">(?:\s*<[^>]*?>\s*)*\s*(?:\W)?([\d\.\,]*?)\s*<\/span>/is)
		{
			$price = &DBIL::Trim($1);
			if($price=~m/([^>]*?)\-[^>]*?$/is)
			{
				$price=$1;
			}
			$price=~s/^Â//igs;
			$price=~s/$//igs;
			$price=~s/\,//igs;
			# print "Price=>$price\n";
		}
		else
		{
			# print "Price Not Matching\n";
			# $logger->send("Item $product_object_key - Price Empty in $retailer_name");
		}
		
		#product_name
		if ( $content2 =~ m/class\=\'name\'\s*>\s*([^>]*?)\s*<\/span>/is )
		{
			$product_name = &DBIL::Trim($1);
			$product_name =~s/amp\;//igs;
			$product_name =~s/\&\#39\;/\'/igs;
			# print "Pname=>$product_name\n";
		}
		elsif ( $content2 =~ m/brand\-title\s*[^>]*?>\s*([^>]*?)\s*(?:<[^>]*?>\s*)+\s*([\w\W]*?)\s*<\/h1>/is )
		{
			$product_name = &DBIL::Trim($2);
			$product_name =~s/amp\;//igs;
			$product_name =~s/\&\#39\;/\'/igs;
			# print "Pname=>$product_name\n";
		}
		
		#product_description
		if ( $content2 =~ m/\"Details\">\s*([\w\W]*?)\s*<\/div>\s*<\/dd>/is )
		{
			$description = &DBIL::Trim($1);
			chomp($description);
			# print "Desc=>$description\n";
		}
		else
		{
			print "Desc Not Matching\n";
		}
		
		#product_detail
		if ( $content2 =~ m/size\s*\&\s*fit\">\s*([\w\W]*?)\s*<\/div>\s*<\/dd>/is )
		{
			$prod_detail = &DBIL::Trim($1);
			chomp($prod_detail);
			# print "Detail=>$prod_detail\n";
		}
		else
		{
			print "Detail Not Matching\n";
		}
		
		#Brand		
		if($content2=~m/\"brand\"\:\"([^>]*?)\"\,/is)
		{
			$brand = &DBIL::Trim($1);
			# print "Brand = > $brand\n";
		}
		elsif($content2=~m/brand\-title\s*[^>]*?>\s*([^>]*?)\s*(?:<[^>]*?>\s*)+\s*([\w\W]*?)\s*<\/h1>/is)
		{
			$brand = &DBIL::Trim($1);
			# print "Brand = > $brand\n";
		}
		else
		{
			print "Brand Not Matching\n";
		}
		
		if ( $brand !~ /^\s*$/g )
		{
			&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
		}
		# colour - Matching
		my $color;
		if($content2=~m/\"color-name\"[^>]*?>\s*([^>]*?)\s*<\/span>\s*<i/is)
		{
			$color = &DBIL::Trim($1);
			# print "Color = > $color";
		}
		else{$color='No Raw Colour';}
		
		my $elapsed = Time::HiRes::tv_interval($ctic);
		my $rtic = [Time::HiRes::gettimeofday()];
		# size & out_of_stock - Matching
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		if($content2=~m/\"size\-dropdown\s*\">\s*([\w\W]*?)\s*<\/ul>\s*<\/div>\s*<\/div>/is)
		{
			my $size_content = $1;
			my ($size,$size_value);
			while($size_content=~m/the\-size\'>\s*([^>]*?)\s*<\/span>\s*<\/div>\s*<div\s*[^>]*?>\s*(?:<span\s*[^>]*?>\s*<\/span>\s*<\/div>\s*)?\s*(?:<div\s*[^>]*?>\s*)+\s*([^>]*?)\s*</igs)
			# while($size_content=~m/the\-size\'>\s*([^>]*?)\s*<[^>]*?>\s*(?:<[^>]*?>\s*)+\s*([^>]*?)\s*</igs)
			{
				$size=&DBIL::Trim($1);
				$size_value=&DBIL::Trim($2);
				$size='No Size' if($size eq '');
				
				if($size_value=~m/sold\s*out/is)
				{
					my $out_of_stock='y';
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=lc($color);
					push(@query_string,$query);	
					print "Data Collected=>$price,$price_text,$size,$color,$out_of_stock,$brand\n";
				}
				else
				{
					my $out_of_stock='n';
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=lc($color);
					push(@query_string,$query);	
					print "Data Collected=>$price,$price_text,$size,$color,$out_of_stock,$brand\n";
				}
			}
		}
		elsif($content2=~m/Unfortunately,\s*this\s*item\s*has\s*sold\s*out/is)
		{
			my $out_of_stock='y';
			my $size='';
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=lc($color);
			push(@query_string,$query);
		}
		else
		{
			print "Size Not Matching\n";
		}
		my $relapsed = Time::HiRes::tv_interval($rtic);
		my $itic = [Time::HiRes::gettimeofday()];
		# $logger->send("Item $product_object_key - Pattern Match Completed for $retailer_name");
		
		# Image - Matching
		# while ( $content2 =~ m/<div\s*[^>]*?>\s*<a\s*[^>]*?fullsizable\"[^>]*?\s*href\=\"([^>]*?\-(\d+)\.[^>]*?)\"\s*>\s*</igs )
		my $count=1;
		while ( $content2 =~ m/<div\s*[^>]*?>\s*<a\s*[^>]*?fullsizable\"[^>]*?\s*href\=\"([^>]*?\-(\d+)\.[^>]*?)\"\s*>\s*</igs )
		{
			my $image = &DBIL::Trim($1);
			unless($image=~m/^\s*http\:/is)
			{
				$image='http:'.$image;
			}
			$image =~ s/\$//g;
			# $logger->send("Wrong Image URL- $image") if (length($image) >= 100 );
			my ($imgid,$img_file) = &DBIL::ImageDownload($image,'product',$retailer_name);
			if ( $count == 1 )
			{
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=lc($color);
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
				print "Image => $count => $image ---> Y\n";
			}
			else
			{
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=lc($color);
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
				print "Image => $count => $image ---> N\n";
			}
			$count++;
		}

		my $ielapsed = Time::HiRes::tv_interval($itic);
		my $sitic = [Time::HiRes::gettimeofday()];
		# $logger->send("Item $product_object_key - Image download successful for $retailer_name");
		print "Image Download Completed\n";
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
		print "Sku Mapping Completed\n";
		# $logger->send("Item $product_object_key - Initilizing Bulk query Execution for $retailer_name");
		
		my $sielapsed = Time::HiRes::tv_interval($sitic);
		my $utic = [Time::HiRes::gettimeofday()];
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		my $uelapsed = Time::HiRes::tv_interval($utic);
		my $eqstic = [Time::HiRes::gettimeofday()];
		
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		# $logger->send("Item $product_object_key - Commit and Exit for $retailer_name");
		print "Completed\n";
		ENDLOOP:
		print "End";
		$dbh->commit();
		my $eqselapsed = Time::HiRes::tv_interval($eqstic);
		$logger->send("Item $product_object_key - R->$elapsed Sku->$relapsed I->$ielapsed M->$sielapsed U->$uelapsed B->$eqselapsed by TheIconic-AU");
	}

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
	print "\nCODE :: $code";
	
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
}1;
