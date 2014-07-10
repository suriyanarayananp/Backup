#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Karenmillen_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use DBI;
use DateTime;
use utf8;
# require "/opt/home/merit/Test_DB/DBIL.pm";
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Karenmillen_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger;

	####Variable Initialization##############
	my $robotname = 'Karenmillen-UK--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Kar';
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

	############Database Initialization########
	my $dbh = &DBIL::DbConnection();
	$dbh->do("set character set utf8"); ### Setting UTF 8 Characters ###
	$dbh->do("set names utf8");  ### Setting UTF 8 Characters ###
	###########################################

	my $select_query = "select ObjectKey from Retailer where name=\'$retailer_name\'";
	my $retailer_id = &DBIL::Objectkey_Checking($select_query, $dbh, $robotname);

	my $hashref = &DBIL::Objectkey_Url($robotname_list, $dbh, $robotname, $retailer_id);
	my %hashUrl = %$hashref;
	

	my $skuflag = 0;
	my $imageflag = 0;
	my $mflag=0;
	
	print "$product_object_key\n";
	
	if($product_object_key)
	{
		my $url3=$url;
		my @query_string;
		my @color_arr;
		
		print"URL:: $url\n";
		my $content2 = &get_content($url3);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my %sku_objectkey;
		my %image_objectkey;
		my %hash_default_image;
		my %hash_default_image;
		
		##my ($price,$brand,$sub_category,$product_name,$productname,$product_id,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$select_var,$i,$size,$price_text,$color,$sku,$j,$pricetext,$unit);
		my ($price,$brand,$sub_category,$product_name,$product_id,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$select_var,$i,$size,$price_text,$color,$sku,$j,$pricetext,$unit);
		
		
		### Product ID and De-duping process ####
		my $productid4ref,$pid;		
		##if($url3=~m/[^>]*\/([^>]*)/is) ### Product ID Collected from the URL. ###
		if($url3=~m/[^>]*\/[^>]*?([\w]{2}[\d]{3})[^>]*?/is) ### Collected from the URL only the item id as visible in info. ###
		{
			$productid4ref=$1;
			my $ckproduct_id = &DBIL::UpdateProducthasTag($productid4ref, $product_object_key, $dbh, $robotname, $retailer_id);
			goto LASTQ if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
	
		######################## START OF PRODUCT SKU FETCH #######################
		
		### Product Name ####
		if($content2=~m/<div\s*id\=\"rc_productTitle\"[^>]*?>\s*([^>]*?)\s*</is)
		{
			$product_name=$1;
			$product_name=&DBIL::Trim($product_name);
		}

		### Price Field ##
		if($content2=~m/<p\s*class\=\"product_price\">\s*([^>]*?)\s*</is)
		{
			$price_text=$1;
			$price_text=~s/<[^>]*?>/ /igs;			
			$price_text=~s/\&pound\;/\£/g;
			$price_text=~s/\s+/ /igs;
			$price_text=~s/^\s+|\s+$//igs;
			$price_text=~s/\Â//igs;
		}
		$price=$price_text;
		print "PRICE BEFORE: $price\n";
		### $price=~s///igs;
		$price=~s/\£//igs;
		##$price=~s/\w//igs;
		
		if($price_text=~m/^\s*$/is)
		{
			if($content2=~m/<p\s*class\=\"product_price\">\s*([\w\W]*?)\s*<\/p>/is)
			{
				$price_text=$1;
				print "Price text from Price Text1:; $price_text\n";
				if($price_text=~m/<span\s*class\=\"now\">([^>]*?)<\/span>/is)
				{	
					$price=$1;
					print "Price from Price Text2:; $price\n";
					if($price=~m/([\d\.\s]+)/is)
					{
						$price=$1;
					}
					print "Price after Price Text:: $price\n";
				}
				$price_text=~s/<[^>]*?>/ /igs;			
				$price_text=~s/\&pound\;/\£/igs;
				$price_text=~s/\s+/ /igs;
				$price_text=~s/^\s+|\s+$//igs;
				$price_text=~s/\Â//igs;
			}
		}
		
		print "PRICE BEFORE: $price\n";
		
		$price=~s/\£//igs;					
		$price=~s/\,//igs;
		#
		if($price=~m/^\s*$/is)
		{
			print "PRICE GOES NULL WHEN PRICE TEXT iS:: $price_text\n";
			$price='NULL';
			####exit;
		}
		
		### Product Color ####
		my $color; 
		my $collect_flag=0;
		##if($content2=~m/<li\s*class\=\"selected\">\s*<[^>]*?>([^>]*?)<[^>]*?>\s*<img\s*class\=\"product_image\"\s*src\=\"([^>]*?)\"/is)
		while($content2=~m/<li\s*class\=\"selected\">\s*<[^>]*?>\s*([^>]*?)\s*<[^>]*?>\s*<img\s*class\=\"product_image\"\s*src\=\"\s*([^>]*?)\s*\"/igs)
		{
			 $color=$1;
			my $swac_img=$2;
			
			if($color=~m/^\s*$/is)
			{
				$color='no raw colour';
				$color_hash{$color}=$swac_img;				
			}
			else
			{	
				push(@color_arr, $color);
				my ($imgid,$img_file) = &DBIL::ImageDownload($swac_img,'swatch',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swac_img,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);	
				print "Out of stock loop external:: $color\n";
				my $content4=$content2;
				
				### OUT OF STOCK ###
				while($content4=~m/<li\s*class\=\"([^>]*?_stock[^>]*?)\s*\">\s*<[^>]*?>\s*(?:<[^>]*?>\s*<[^>]*?>\s*<[^>]*?>)?([^>]*?)</igs)
				{
					my $stoc=$1;
					$size=$2;
					$out_of_stock='n';
					print "Out of stock loop Internal: $color :: Size :: $size\n";
					if($stoc=~m/no_stock/is)
					{
						$out_of_stock='y';
					}
					print "SKU PART 1:: $price\t $price_text\t$size\t$color";
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$color;	
					push(@query_string,$query);	
					$collect_flag=1;
				}
			}
		}	
		
		
		
		#### PRODUCT IMAGES ####
		my $product_image1;

		if($content2=~m/<img\s*class\=\"product_image\"\s*id\=\'enlarged_image\'\s*src\=\"([^>]*?)\"/is)
		{
			$product_image1=$1;
				
			my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
			
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			# my ($img_object,$flag) = &&DBIL::SaveImage($imgid,$swatch_image,$img_file,'swatch',$Retailer_Random_String,$robotname,$excuetionid);
			
			$imageflag = 1 if($flag);
			
			$image_objectkey{$img_object}=$color;
			
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);	

		}
		elsif($content2=~m/<img\s*class\=\"product_image\"\s*id\=\'main_image\'\s*src\=\"([^>]*?)\"/is)
		{
			$product_image1=$1;
			
			my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$color;
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);	
		}	
		
		
		for ($i=1;$i<10;$i++)
		{
			my $product_image12=$product_image1;
			$product_image12=~s/\.jpg/_$i.jpg/igs;
			
			my $content11=&image_validate($product_image12);

			if($content11 eq 1)
			{			
				my ($imgid,$img_file) = &DBIL::ImageDownload($product_image12,'product',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image12,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$color;
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);	
			}
			else
			{
				last;
			}			
		}	
		
		#### PRODUCT DESCRIPTION ###
		my($des3,$Details,$desc3,$final_des);
		if($content2=~m/<meta\s*name\=\"description\"\s*content\=\"([^>]*?)\"/is)
		{
			$des3=$1;
			$des3=~s/\s+/ /igs;
			$des3=~s/<[^>]*?>/ /igs;
			$des3=&DBIL::Trim($des3);
		}
		if($content2=~m/<div\s*id\=\"editor_notes\">\s*<p>([^>]*?)</is)
		{
			$desc3=$1;
			$desc3=~s/\s+/ /igs;
			$desc3=~s/<[^>]*?>/ /igs;
			$desc3=&DBIL::Trim($desc3);
		}
		$final_des=$des3.$desc3;
		if($content2=~m/<dd\s*class\=\"product_specifics\">([\w\W]*?)<\/dd>/is)
		{
			$Details=$1;
			$Details=&DBIL::Trim($Details);
		}
		if(($product_name ne '' or $product_id ne '' ) && ($des3 eq '' and $Details eq ''))
		{
		   $des3='-';
		}
			
		$Details=~s/\s+/ /igs;
		$Details=~s/<li>/\*/igs;
		$Details=~s/<[^>]*?>//igs;
		$Details=&DBIL::Trim($Details);
		# print"des====>>$des3\n\n";
		
		
		##### REMOVED TO AVOID PRODUCT DUPLICATION WHEN IT ARISES  #####
		
		### PRODUCT Duplication ###
		# my @image_obj_keys = keys %image_objectkey;
		# my @sku_obj_keys = keys %sku_objectkey;
		# foreach my $img_obj_key(@image_obj_keys)
		# {
			# foreach my $sku_obj_key(@sku_obj_keys)
			# {
				# if($image_objectkey{$img_obj_key} eq $sku_objectkey{$sku_obj_key})
				# {
					
					# my $query=&DBIL::SaveSkuhasImage($sku_obj_key,$img_obj_key,$hash_default_image{$img_obj_key},$product_object_key,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					# push(@query_string,$query);	
				# }
			# }
		# }	

		##### End of Removal ####
		
		
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		
		######################## END OF PRODUCT SKU FETCH #######################	FOR ADDITIONAL COLOURS
		if($content2=~m/<p>\s*Colour\s*\:\s*<\/p>\s*<ul>([\w\W]*?)<\/ul>/is)
		{
			my $image_product_block=$1;
			print "Inside the if Loop for Color Image\n";
			if($image_product_block=~m/<a\s*href\=\"\s*([^>]*?)\s*\"\s*class\=\"product_link\">/is)
			{
				print "Inside the IF LOOP for Color Image URL Fetching\n";
				while($image_product_block=~m/<a\s*href\=\"\s*([^>]*?)\s*\"\s*class\=\"product_link\">/igs)
				{
					my $next_product_link=$1;
					my $content3 = &get_content($next_product_link);
					print "Inside the IF Loop for Color Image\n";
					
					######################## START OF LOOPING PRODUCT SKU FETCH #######################
					print "Inside the while Loop for Color Image\n";
					
					### Product Color ####
					my $color; 
					##if($content2=~m/<li\s*class\=\"selected\">\s*<[^>]*?>([^>]*?)<[^>]*?>\s*<img\s*class\=\"product_image\"\s*src\=\"([^>]*?)\"/is)
					while($content3=~m/<li\s*class\=\"selected\">\s*<[^>]*?>\s*([^>]*?)\s*<[^>]*?>\s*<img\s*class\=\"product_image\"\s*src\=\"\s*([^>]*?)\s*\"/igs)
					{
						 $color=$1;
						my $swac_img=$2;
						my $color_ck_flag=0;
						foreach my $old_colour (@color_arr)
						{
							if($old_colour=~m/^\s*$color\s*$/is)
							{
								$color_ck_flag=1;
							}
						}
						
						if($color_ck_flag==0)
						{
							if($color=~m/^\s*$/is)
							{
								$color='no raw colour';
								# ####$color_hash{$color}=$swac_img;	
								if($color_hash{$color}==$swac_img)
								{
									my ($imgid,$img_file) = &DBIL::ImageDownload($swac_img,'swatch',$retailer_name);
									my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swac_img,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$imageflag = 1 if($flag);
									$image_objectkey{$img_object}=$color;
									$hash_default_image{$img_object}='n';
									push(@query_string,$query);	
								}
							}
							else
							{	
								push(@color_arr, $color);
								my ($imgid,$img_file) = &DBIL::ImageDownload($swac_img,'swatch',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swac_img,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color;
								$hash_default_image{$img_object}='n';
								push(@query_string,$query);	
								print "Color and outof stock 2 :: $color\n";
								### OUT OF STOCK ###
								my $content5=$content3;
								while($content5=~m/<li\s*class\=\"([^>]*?_stock[^>]*?)\s*\">\s*<[^>]*?>\s*(?:<[^>]*?>\s*<[^>]*?>\s*<[^>]*?>)?([^>]*?)</igs)
								{
									my $stoc=$1;
									$size=$2;
									$out_of_stock='n';
									if($stoc=~m/no_stock/is)
									{
										$out_of_stock='y';
									}
									print "SKU PART 2 ::Color and outof stock inside 2 :: $color ::Size:: $size\n";
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$color;	
									push(@query_string,$query);	
								}
								
							}
						}
					}	
					
					#### PRODUCT IMAGES ####
					my $product_image1;
					if($content3=~m/<img\s*class\=\"product_image\"\s*id\=\'enlarged_image\'\s*src\=\"([^>]*?)\"/is)
					{
						$product_image1=$1;
							
							my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
							
							my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							# my ($img_object,$flag) = &&DBIL::SaveImage($imgid,$swatch_image,$img_file,'swatch',$Retailer_Random_String,$robotname,$excuetionid);
							
							$imageflag = 1 if($flag);
							
							$image_objectkey{$img_object}=$color;
							
							$hash_default_image{$img_object}='y';
							push(@query_string,$query);	

					}
					elsif($content3=~m/<img\s*class\=\"product_image\"\s*id\=\'main_image\'\s*src\=\"([^>]*?)\"/is)
					{
						$product_image1=$1;
						
						my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);	
					}	

					for ($i=1;$i<10;$i++)
					{
						my $product_image12=$product_image1;
						$product_image12=~s/\.jpg/_$i.jpg/igs;
						
						my $content11=&image_validate($product_image12);

						if($content11 eq 1)
						{			
						my ($imgid,$img_file) = &DBIL::ImageDownload($product_image12,'product',$retailer_name);
						
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image12,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$color;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);	
						}
						else
						{
							last;
						}			
					}	
					
					# print"des====>>$des3\n\n";
					#### PRODUCT Duplication ###
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
			
				}
			}
			else ### If the Loop For Second Product
			{
				print "Inside the Else Loop of ordinary no raw color\n";
				if($content2=~m/<p>\s*Colour\:\s*<\/p>\s*<ul>\s*<li\s*class\=\"selected\">\s*<span>([^>]*?)<\/span>/is)
				{
					my $color=$1;
					if($color=~m/^\s*$/is)
					{
						$color='no raw colour';
					}
					my $swac_img=$color_hash{'no raw colour'};
					my ($imgid,$img_file) = &DBIL::ImageDownload($swac_img,'swatch',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swac_img,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);	
					
					my $content4=$content2;
					
					### OUT OF STOCK ###
					while($content4=~m/<li\s*class\=\"([^>]*?_stock[^>]*?)\s*\">\s*<[^>]*?>\s*(?:<[^>]*?>\s*<[^>]*?>\s*<[^>]*?>)?([^>]*?)</igs)
					{
						my $stoc=$1;
						$size=$2;
						$out_of_stock='n';
						
						if($stoc=~m/no_stock/is)
						{
							$out_of_stock='y';
						}
						if($collect_flag!=1)
						{
							print "SKU PART 3 ::Color and out of stock inside 2 :: $color ::Size:: $size\n";
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$color;	
							push(@query_string,$query);	
						}
					}
					
				}
				###elsif($color_hash{$color}=='no raw colour')
				elsif($color=~m/no\s*raw\s*colour/is)
				{
					##my $color='no raw colour';
					print "Entered Inside the IF Loop ::: $color_hash{$color} \n";
					
					my $swac_img=$color_hash{$color};
					my ($imgid,$img_file) = &DBIL::ImageDownload($swac_img,'swatch',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swac_img,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$color;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);	
					my $content4=$content2;
					
					### OUT OF STOCK ###
					while($content4=~m/<li\s*class\=\"([^>]*?_stock[^>]*?)\s*\">\s*<[^>]*?>\s*(?:<[^>]*?>\s*<[^>]*?>\s*<[^>]*?>)?([^>]*?)</igs)
					{
						my $stoc=$1;
						$size=$2;
						$out_of_stock='n';
						
						if($stoc=~m/no_stock/is)
						{
							$out_of_stock='y';
						}
						print "SKU PART 4 ::Color and out of stock inside 2 :: $color ::Size:: $size\n";
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
			}
		}
		
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$productid4ref,$product_name,$brand,$des3,$Details,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3, $retailer_id, $mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		
		### my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		#### push(@query_string,$qry); 				
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);			
		LASTQ:
		$dbh->commit();
		print "Product COMPLETED\n";		
	}
}1;	
# &DBIL::RetailerUpdate($retailer_id,$excuetionid,$dbh,$robotname,'end');
# $dbh->commit();
				
sub get_content
{
	my $url = shift;
	my $rerun_count;
	$url =~ s/^\s+|\s+$//g;
	Home:
	
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/html;charset=UTF-8");
	$req->header("Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
	$req->header("Content-Type"=>"text/html;charset=UTF-8");
		# $req->header("Referer"=> "http://www.neimanmarcus.com/en-us/index.jsp");
		# $req->header("Host"=> "www.neimanmarcus.com");
	my $res = $ua->request($req);
	$cookie->extract_cookies($res);
	$cookie->save;
	$cookie->add_cookie_header($req);
	my $code=$res->code;
	print "\nCODE :: $code";
	my $content;
	if($code =~m/20/is)
	{
		$content = $res->content; ### dont change Decoded content, Some regex functionality like prices are Fail &pound; ||||| ###
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

sub image_validate()
{
    my $url = shift;
	
    $url =~ s/^\s+|\s+$//g;
 
 my $req = HTTP::Request->new(GET=>$url);
 $req->header("Content-Type"=> "text/plain");
 my $res = $ua->request($req);
 # $cookie->extract_cookies($res);
 # $cookie->save;
 # $cookie->add_cookie_header($req);
 my $code=$res->code;
 
    if($code==200)
    {
  return 1;
    }
    else
    {
  return 0;
    }
}