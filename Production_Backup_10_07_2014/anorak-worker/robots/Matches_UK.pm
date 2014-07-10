#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Matches_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
use utf8;
##require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Matches_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger;	
	# $dbh->do("set character set utf8"); ### Setting UTF 8 Characters ### I have removed to avoid character trunction in Produt name for some products
	# $dbh->do("set names utf8");  ### Setting UTF 8 Characters ###
	####Variable Initialization##############
	$robotname='Matches-UK--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Mat';
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

	###########################################

	my $select_query = "select ObjectKey from Retailer where name=\'$retailer_name\'";
	my $retailer_id = &DBIL::Objectkey_Checking($select_query, $dbh, $robotname);

	my $hashref = &DBIL::Objectkey_Url($robotname_list, $dbh, $robotname, $retailer_id);
	my %hashUrl = %$hashref;
	my $skuflag = 0;my $imageflag = 0;
	
	if($product_object_key)
	{	
		my $url3=$url;		
		my $multi_product_flag=0;
		my @query_string;
		
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		
		$url3='http://www.matchesfashion.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = get_content($url3);
		
		my ($price,$price_text,$brand,$sub_category,$item_no,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@image_object_key,@sku_object_key,@string);	
			
		#### Content Block ###
		if($content2=~m/<div\s*class\=\"inner\">\s*<div\s*class\=\"details\">\s*<div\s*class\=\"info\">([\w\W]*?)<h4>\s*VIEW\s*MORE\:\s*<\/h4>/is)
		{
			my $Product_info_block=$1;
			
				### Product Title and Item No  ###
				if($Product_info_block=~m/<h3\s*class\=\"description\">([^>]*?)\s*\(([\d]+)\s*\)\s*<\/h3>/is)
				{
					$product_name=&DBIL::Trim(clean($1));
					$item_no=&DBIL::Trim(clean($2));
					
					my $ckproduct_id = &DBIL::UpdateProducthasTag($item_no, $product_object_key, $dbh, $robotname, $retailer_id);
					goto end if($ckproduct_id == 1);
					undef ($ckproduct_id);
					##$dbh->commit;
				}
				#### Brand #### 
				if($Product_info_block=~m/<h2\s*class\=\"designer\"><a\s*href\=[^>]*?>([^>]*?)<\/a>\s*<\/h2>/is)
				{
					$brand=&DBIL::Trim(clean($1));
					# if($brand ne "")
					# {
						# &DBIL::SaveTag('Brand',lc($brand),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
						#$dbh->commit;
					# }

				}
				elsif($Product_info_block=~m/<h4\s*class\=\"designer\">([^>]*?)<\/h4>/is)
				{
					$brand=&DBIL::Trim(clean($1));
					# if($brand ne "")
					# {
						# &DBIL::SaveTag('Brand',lc($brand),$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
						# $dbh->commit;
					# }

				}
				#### Price Text ####

				##### NEW PRICE #####
				if($Product_info_block=~m/<div\s*class\=\"price\">([\w\W]*?)<\/div>/is)
				{
					$price_text=$1;
					
					if($price_text=~m/<span\s*class\=\"sale\"\s*>([^>]*?)<\/span>/is)
					{
						$price=$1;					
						$price=~s/\&nbsp\;/ /igs;					
						$price=&DBIL::Trim(clean($price));
						
						if($price=~m/\s*\£([\d\.\,]+?)\s*$/is)
						{	
							$price=$1;
							$price=~s/\,//igs;
						}
						
					}
					elsif($price_text=~m/^\s*[\W]+?([\d\.\,]+?)\s*$/is) ### Normal Single Pricing
					{
						$price=$1;
						$price=~s/\,//igs;
					}
				}
				
				if($price=~m/^\s*$/is)
				{			
					$price='NULL';
				}

				### Product Description  ###
				if($Product_info_block=~m/<span>\s*Style\s*notes\s*<\/span>[\w\W]*?<p>([^>]*?)<\/p>/is)
				{
					$description=&DBIL::Trim(clean($1));
				}
				elsif($Product_info_block=~m/<span>\s*Style\s*notes\s*<\/span>[\w\W]*?<p>([^>]*?)(?:(Shown|Styled|)\s*here\s*with\s*<[\w\W]*?)?<\/p>/is)
				{
					$description=&DBIL::Trim(clean($1));
				}
				
				### Product Detail  ###
				if($Product_info_block=~m/<span>\s*Details\s*<\/span>\s*<\/h4>\s*<div\s*class\=\"panel\">([\w\W]*?)<\/ul>/is)
				{
					$prod_detail=&DBIL::Trim(clean($1));
					$prod_detail=~s/<[^>]*?>/ /igs;
					
					if($Product_info_block=~m/<span>\s*Size\s*and\s*fit<\/span>\s*<\/h4>([\w\W]*?)<\/ul>/is)
					{
						$prod_detail=$prod_detail.' '.$1;
						$prod_detail=~s/<[^>]*?>/ /igs;
						$prod_detail=&DBIL::Trim(clean($prod_detail));
					}
					
				}
				#### SIZE #####
				my @sizes;
				if($Product_info_block=~m/<div\s*class\=\"sizes\">([\w\W]*?)<a[^>]*?>Size\s*Guide<\/a>/is)
				{
					my $size_block=$1;
					$size_block=~s/<option\s*value\=\"\">SELECT\s*SIZE<\/option>//igs;
					while($size_block=~m/<option\s*value\=[^>]*?>([^>]*?)<\/option>/igs)
					{
						my $size=&DBIL::Trim(clean($1));
						push(@sizes, $size);
						
						if($size=~m/(\s*Sold\s*Out\s*|\s*comming\s*soon\s*|\s*coming\s*soon\s*)/is)
						{
							$size=~s/\s*-\s*Sold\s*Out\s*//igs;
							$size=~s/\s*Sold\s*Out\s*//igs;
							$size=~s/\s*-\s*comming\s*soon\s*//igs;
							$size=~s/\s*comming\s*soon\s*//igs;
							$size=~s/\s*-\s*coming\s*soon\s*//igs;
							$size=~s/\s*coming\s*soon\s*//igs;
							$out_of_stock='y';
						}
						else
						{
							$out_of_stock='n';
						}
						$colour="no raw colour";
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);						
						$sku_objectkey{$sku_object}='No Colour';
						push(@query_string,$query);	
						###$dbh->commit();
					}
						
				}
				else
				{
					my $size='';
					$colour='no raw colour';
					if($Product_info_block=~m/(\s*Sold\s*Out\s*|\s*comming\s*soon\s*|\s*coming\s*soon\s*)/is)
					{					
						$out_of_stock='y';
					}
					else
					{
						$out_of_stock='n';
					}
					if($price eq '')
					{
						print "Null:: $price\n";
					}
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);						
					$sku_objectkey{$sku_object}='No Colour';
					push(@query_string,$query);
					###$dbh->commit();
				}
		}
		  
		####### Image Collection Section #####
		my $default_image;
		if($content2=~m/<div\s*class\=\"images\">\s*<div\s*class\=\"image\-list\">([\w\W]*?)<\/div>\s*<\/div>/is)
		{	
			my $Image_Block=$1;
			
			while($Image_Block=~m/<img\s*alt=[^>]*?class\=\"product\-image\"\s*src\=\"([^>]*?)\"\s*\/>/igs)
			{
				my $image_url=$1;
				
				if($image_url=~m/[^>]*?_1_large\.jpg/is) ### Main Image without color
				{	
					$default_image=$image_url;
					##$main_image =~ s/\$//g;
					
					
						my ($imgid,$img_file) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$default_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No Colour';
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
						###$dbh->commit;
				}
				else ### Alternate Images without color
				{
					
						my ($imgid,$img_file) = &DBIL::ImageDownload($image_url,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$image_url,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='No Colour';
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
						###$dbh->commit;

				}

			}
		}
		
		
		### Sku has Image Inserted here (Function Added)
		
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
					###$dbh->commit;
				}
			}
		}

		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key, $item_no, $product_name, $brand, $description, $prod_detail, $dbh,$robotname, $excuetionid, $skuflag, $imageflag, $url3, $retailer_id, $multi_product_flag);
		$product_name=$description=$prod_detail=$out_of_stock=undef;
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);
		end:
		$dbh->commit();
		print "end";
		################################### OLD SCRIPT NEED TO DELETE AFTER THE BUILD ########################
	}
	# $dbh->disconnect();
}1;

#### &DBIL::SaveDB("Delete from Product where detail_collected='d' and RobotName=\'$robotname_list\'",$dbh,$robotname); 
#####&DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');


sub clean
{
my $value1=shift;
$value1=~s/\&\#8217\;/\'/igs;
$value1=~s/\&\#8217\;/\'/igs;
$value1=~s/\&\#10\;\s*\-/*/igs;
$value1=~s/\&\#13\;\s*\-/*/igs;
$value1=~s/\&quot\;/"/igs;
$value1=~s/\&quot/"/igs;
$value1=~s/\&\#233\;/é/igs;
##$value1=~s/Â¡Â¯/'/igs;
$value1=~s/<[^>]*?>/ /igs;
$value1=~s/\&amp\;/&/igs;
$value1=~s/\Â/ /igs;
###$value1=~s/\&amp/&/igs;
$value1=~s/\&nbsp\;/ /igs;
$value1=~s/\&nbsp/ /igs;
$value1=~s/\s+/ /igs;
$value1=~s/^\s+|\s+$//igs;
# $value1=decode_entities($value1);
# utf8::decode($value1);
return($value1);	
}


sub get_content
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
	open JJ,">>$retailer_file";
	print JJ "$url->$code\n";
	close JJ;
	my $content;
	if($code =~m/20/is)
	{
		##$content = $res->content;
		$content = $res->decoded_content;
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
