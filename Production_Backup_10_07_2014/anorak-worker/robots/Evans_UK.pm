#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Evans_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
#require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Evans_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;
	$robotname='Evans-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Eva';
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
	my @query_string;
	my $skuflag = 0;my $imageflag = 0;
	if($product_object_key)
	{
		my $url3=$url;
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		$url='http://www.evans.co.uk/'.$url unless($url=~m/^\s*http\:/is);
		
		my $content2 = get_content($url);
		goto PNF if($content2 =~ m/We\s*apologise\s*for\s*any\s*inconvenience/is);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		my $mflag=0;
		if($content2 =~ m/SELECT\s*THE\s*ITEMS\s*YOU\s*WISH\s*TO\s*BUY/is)
		{
			$mflag=1;
			$product_name = &DBIL::Trim($1) if ( $content2 =~ m/<h1>([\w\W]*?)<\/h1>/is );
			if ( $content2 =~ m/<p\s*id\=\"bundle_description\">([\w\W]*?)<\/p>/is )
			{
				my $desc_content = $1;
				$description = &DBIL::Trim($desc_content);
			}
			goto PNF;
		}
			
		#price_text and Price
		if ( $content2 =~ m/<li\s*class\=\"product_price\">([\w\W]*?)<\/li>/is )
		{
			$price_text = &DBIL::Trim($1);
			$price=$price_text;
			$price_text=~s/\&pound\;/\�\�/igs;
			#$price_text=decode_entities($price_text);
		}
		
		my ($temp_price1,$temp_price2);
		if($content2 =~m/<li\s*class\=\"was_price\s*product_price\">([\w\W]*?)<\/li>/is)
		{
			$temp_price1=&DBIL::Trim($1);
		}
		if($content2 =~m/<li\s*class\=\"now_price\s*product_price\">([\w\W]*?)<\/li>/is)
		{
			$temp_price2=&DBIL::Trim($1);
			$price_text=$temp_price1.' '.$temp_price2;
			$price=$temp_price2;
			$price_text=~s/\&pound\;/\�\�/igs;
			#$price_text=decode_entities($price_text);
		}
		$price=~s/[a-zA-Z]+//igs;
		$price=~s/\&//igs;
		$price=~s/\;//igs;
		$price=~s/\://igs;
		$price=&DBIL::Trim($price);
		
		#product_id
		if ( $content2  =~ m/>\s*item\s*code\s*\:*([\w\W]*?)<\/li>/is )
		{
			$product_id = &DBIL::Trim($1);
			$product_id = substr $product_id, 0, -4;			
		}
		
		#product_name
		if ( $content2 =~ m/<h1>([\w\W]*?)<\/h1>/is )
		{
			$product_name = &DBIL::Trim($1);
		}
		
		#description&details
		if ( $content2 =~ m/(<[^<]*?class\=\"product_description\">[\w\W]*?<\/div>)/is )
		{
			my $desc_block = $1;
			if($desc_block=~m/<[^<]*?class\=\"product_description\">\s*([^<]*?)\s*<br>/is)
			{
				$description = &DBIL::Trim($1);
				if($desc_block=~m/<br>([\w\W]*?)<\/div>/is)
				{
					$prod_detail = $1;
				}
			}
			else
			{
				$description = &DBIL::Trim($desc_block);
				$prod_detail=$description;
			}
		}
		
		#colour
		my $color;
		if ( $content2 =~ m/<li\s*class\=\"product_colour\">\s*Colour\:[^<]*?<span>\s*([^<]*?)\s*<\/span>/is )
		{
			$color=$1;			
		}
		
		# size
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		
		my $qcount=0;
		if( $content2 =~ m/<option>\s*Select\s*Size\s*<\/option>([\w\W]*?)<\/select>/is)
		{
			my $size_content1 = $1;
			while ( $size_content1 =~ m/<option[^<]*?title\=\"([^<]*?)\"[^<]*?>\s*([^<]*?)\s*<\/option>/igs )
			{
				my $stock_text = &DBIL::Trim($1);
				my $size = &DBIL::Trim($2);
				my $out_of_stock;
				if ( $stock_text =~ m/Out\s*of\s*stock/is )
				{
					$out_of_stock = 'y';
				}
				else
				{
					$out_of_stock = 'n';
				}
				
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$color;
				push(@query_string,$query);
				
				if($qcount == 0)
				{
					# $logger->send("$robotname SkuQuery :: $query");
					$qcount++;
				}
			}
		}
		if ( $content2 =~ m/<a\s*href\=\"([^<]*?)\"\s*title\=\"Zoom\s*in\"\s*class\=\"product_view\"[^<]*?>/is )
		{
			my $image_link = &DBIL::Trim($1);
			unless($image_link=~m/^\s*http\:/is)
			{
				$image_link='http://media.evans.co.uk/'.$image_link;
			}
			my ($img_file,$img_id);
			if($image_link=~m/\/([\w]+)_large\.jpg$/is)
			{
				$img_id=$1;
			}
			my $count=1;
			foreach (2..7)
			{
				my $res2;
				if ( $count == 1 ) #normal img
				{	
					my ($imgid,$img_file) = &DBIL::ImageDownload($image_link,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image_link,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				else 	#small img
				{
					my $test_img='http://media.evans.co.uk/wcsstore/Evans/images/catalog/'.$img_id.'_'.$count.'_large.jpg';
				
					my $img_status_code=get_content_code($test_img);
					if($img_status_code eq 200)
					{	
						my ($imgid,$img_file) = &DBIL::ImageDownload($test_img,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$test_img,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					elsif($img_status_code eq 404)
					{
						goto ImageCompleted;
					}
				}
				$count++;
			}		
		}
		ImageCompleted:
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
		$dbh->commit;
	}	
}1;

sub get_content()
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	$url =~ s/amp;//igs;
	
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
			sleep 5;
			goto Home;
		}
	}
	return $content;
}	
sub get_content_code
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	$url =~ s/amp;//igs;
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
	return $code;
}
