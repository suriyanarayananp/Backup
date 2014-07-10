#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Davidlawrence_AU;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
use utf8;
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";

###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Davidlawrence_AU_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Davidlawrence-AU--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Dav';
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
		my $content2 = &get_content($url3);
		if($content2=~m/you\s*are\s*looking\s*for\s*cannot\s*be\s*accessed\./is)
		{
			print "\n$1\n";
			goto PNF;
		}
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$color);

		#product_name
		if ( $content2 =~ m/<div[^>]*?id="prod-details">\s*<h1[^>]*?>\s*([\w\W]*?)<\/h1>/is )
		{
			$product_name =&DBIL::Trim($1);
		}
		
		#price & price_text
		if ( $content2 =~ m/<strong[^>]*?price\">([\w\W]*?)<\/strong>/is )
		{
			$price_text =&DBIL::Trim($1);
			$price_text=~s/\s*(?:Usually|now\s*only)\s*//igs;
			# $price =&DBIL::Trim($2);
			if($price_text =~m/(\d[^>]*?)\s*AUD(?:[^>]*?(\d[^>]*?)\s*AUD)?/is)
			{
				my $v1=$1;
				my $v2=$2;
				$v2=0 if($v2 eq "");
				if($v1<$v2)
				{
					$price=$v1;
				}
				elsif($v2!=0)				
				{
					$price=$v2;
				}
				else
				{
					$price=$v1;
				}
			}
		}
		
		#product_id
		if( $content2 =~ m/Style\s*number\:\s*([^<]*?)</is )
		{
			$product_id =&DBIL::Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		
		#description
		if ( $content2 =~ m/Description\s*<\/h2>\s*(?:(?:<[^>]*?>\s*)*)([^<]*?<[\w\W]*?\s*<\W*\/Description[^>]*>)/is )
		{
			$description =&DBIL::Trim($1);
			$description=decode_entities($description);
			utf8::decode($description);
		}
		if ( $content2 =~ m/detail(?:s)?\W*<\/h2>\s*(?:(?:<[^>]*?>\s*)*)([^<]*?<[\w\W]*?\s*<\W*\/Detail[^>]*>)/is )
		{		
			$prod_detail=$1;
			$prod_detail =~ s/\<[^>]*?\>//ig;
			# encode_entities($prod_detail);
			$prod_detail=~s/\&acirc\;/ /igs;
			$prod_detail=~s/\\n/ /igs;
			$prod_detail =&DBIL::Trim($prod_detail);
			$prod_detail=decode_entities($prod_detail);
			utf8::decode($prod_detail);
			
		}
		my (%sku_objectkey,%image_objectkey,%hash_default_image);
		# size & out_of_stock
		if($content2=~m/<select[^>]*?Colour\"[^>]*?>[\w\W]*?<\/select>/is)
		{
			my $color_content=$&;
			while($color_content =~ m/<option[^>]*?value\=\"[^>]*?\"[^>]*?>\s*([^<]*?)\s*</igs)
			{
				my $colors=$1;
				my $newlink=$url3;
				my $color=$colors;
				if($newlink!~m/\&clr\=/is)
				{
					$newlink=$newlink."&clr=".$color;
				}
				else
				{
					$newlink=~s/&clr=[^\&]*&/&clr=$color&/igs;
				}
				my $content3 = get_content($newlink);
				
				if($content3=~m/<select[^>]*?Size\"[^>]*?>[\w\W]*?<\/select>/is)
				{
					my $size_content=$&;
					while($size_content =~ m/<option[^>]*?value\=\"[^>]*?\"[^>]*?>\s*([^<]*?)\s*</igs)
					{
						my $size =&DBIL::Trim($1);
						my $out_of_stock;		
						$out_of_stock = 'n';
						$colors=&ProperCase($colors);
						$colors=~s/\-(\w)/-\u\L$1/is;
						sub ProperCase 
						{
							join(' ',map{ucfirst(lc("$_"))}split(/\s/,$_[0]));
						}
						print "SSSKUUUUU>>size>>>$size>>>$colors\t\t$color\n";
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colors,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						push(@query_string,$query);
					}
				}
				#Image
				# if($content3=~m/<ul[^>]*?items\">[\w\W]*?<\/ul>/is)
				# {
					# my $img_cont=$&;
					# my $image_count=0;
					while($content3=~m/<img\s*src\=\"[^>]*?\"\s*name\=\"([^>]*?)\"[^>]*?>/igs)
					{			
						my $alt_image = $1;
						$alt_image='http://www.davidlawrence.com.au'.$alt_image;
						my $img_file;
						# $alt_image =~ s/\\\//\//g;			
						print "$alt_image\n";
						#my $col=$1 if($alt_image=~m/_([a-z\s]+)_/is);
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'Product',$retailer_name);
						if ($alt_image=~m/_1_/is)
						{
							print "1>>>$alt_image\t\t$color\n";
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);
						}
						else
						{
							print "2>>>$alt_image\t\t\t$color\n";
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'Product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$imageflag = 1 if($flag);
							$image_objectkey{$img_object}=$color;
							$hash_default_image{$img_object}='n';
							push(@query_string,$query);
						}
					}
				# }
			}
		}
		my @image_obj_keys = keys %image_objectkey;
		my @sku_obj_keys = keys %sku_objectkey;
		foreach my $img_obj_key(@image_obj_keys)
		{
			foreach my $sku_obj_key(@sku_obj_keys)
			{
				# print "$image_objectkey{$img_obj_key}       $sku_obj_key{$sku_obj_key}\n";
				# print "$image_objectkey{$img_obj_key}\n";
				print "Image $image_objectkey{$img_obj_key} <<Sku>>>$sku_objectkey{$sku_obj_key}\n";
				if($image_objectkey{$img_obj_key} eq $sku_objectkey{$sku_obj_key})
				{
					
					my $query=&DBIL::SaveSkuhasImage($sku_obj_key,$img_obj_key,$hash_default_image{$img_obj_key},$product_object_key,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					push(@query_string,$query);
				}
			}
		}
		@sku_obj_keys=@image_obj_keys=undef;
		PNF:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		$dbh->commit();
	}
}1;

#&DBIL::SaveDB("Delete from Product where detail_collected='d' and RobotName=\'$robotname_list\'",$dbh,$robotname);
# &DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
# $dbh->commit();
# $dbh->disconnect();

sub get_content
{
	my $url = shift;
	my $rerun_count;
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
		if ( $rerun_count <= 2 )
		{
			$rerun_count++;
			sleep(1);
			goto Home;
		}
	}
	return $content;
}
