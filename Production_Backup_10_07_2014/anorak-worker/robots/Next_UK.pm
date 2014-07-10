#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Next_UK;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use WWW::Mechanize;
use DBI;
use DateTime;

# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Next_UK_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Next-UK--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Nex';
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
		$url=$url3;
		my @query_string;
		my %prod_objkey;
		my $content2 = get_content($url3);
		#### 40/50 code Page #####
		if($content2 eq 1)
		{
			goto PNF;
		}
		my ($pid,$bran,$col);
		if($url3=~m/\#(\w{3})(\w{3})/is)
		{
			$pid=$1.'-'.$2;
		}
		print "Start\n";
		my $x=$pid;
		$x=~s/\-//is;
		my $br_col_url="http://next.ugc.bazaarvoice.com/data/products.json?apiversion=5.3&passkey=2l72hgc4hdkhcc1bqwyj1dt6d&Filter=Id:"."$x";  ##### Brand Url #####
		my $cont = get_content($br_col_url);
		if($cont=~m/Brand\W*Name\"\:\"([^>]*?)\"[^>]*?colour\W*Values\W*Value\"\:\"([^>]*?)\"/is)
		{
			$bran=$1;
			$col=$2;
		}
		my $tid=0;
		my $content223=$content2;
		while($content2=~m/<article[\w\W]*?>([\w\W]*?)<\/article>/igs)
		{
			my $block=$1;
			if($block=~m/$pid/is)											########## Matches Retailer_Product_Reference from url and product ########
			{
				my %tag_hash;
				my %size_hash;
				my ($price,$price_text,$brand,$sub_category,$item_no,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour, $v1, $v2,$product_id);
				# price
				if ($block =~ m/Price\">([^>]*?(\d+(?:\.\d+)?))(?:\s*<[^>]*?>\s*)+([^>]*?)\s*</is)
				{
					$price_text= $1;
					$price= &DBIL::Trim($2);
					$product_name= &DBIL::Trim($3);
					$product_name=~s/\&\#174\;/®/igs;
					$product_name =~ s/<[^>]*?>|\Â//igs;
					$product_name =~ s/\([^>]*?\)//igs;
					$price_text =~ s/<[^>]*?>|\Â/ /igs;
					$price_text=~s/\s+/ /igs;
					$price_text=~s/^\s*|\s*$//igs;
					$price_text=~s/\&pound\;/\Â\£/igs;
					$price_text =~ s/\&\#163\;/\Â\£/igs;
					$price_text=~s/\£/\Â\£/igs;
					$price_text=~s/Was[^>]*?\£/Was \Â\£/igs;
					$price_text=~s/Now\s*\£/Now \Â\£/igs;
					$price_text=decode_entities($price_text);
					$product_name=decode_entities($product_name);
					
					if($price_text=~m/\W*(\d[^>]*?)\s*\-\W*(\d[^>]*?)$/is)
					{
						$v1=&DBIL::Trim($1);
						$v2=&DBIL::Trim($2);
						if($v1<$v2)
						{
							$price= $v1;
						}
						else
						{
							$price= $v2;
						}
					}	
				}
				# Retailer_Product_Reference
				if ( $block =~ m/ItemNumber\">\s*([^>]*?)\s*</is )
				{
					$item_no = &DBIL::Trim($1);
					$product_id=$item_no;
					$product_id=~s/\-//is;
				}
				if($product_id ne $x)
				{
					$product_id=$x;
				}
				$product_id=lcfirst($product_id);
				my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
				goto end if($ckproduct_id == 1);
				undef ($ckproduct_id);
				# Description
				if ( $block =~ m/<div\s*class\=\"StyleContent\">\s*<div>([\w\W]*?)<div/is )
				{
					$description = &DBIL::Trim($1);
					$description =~ s/<[^>]*?>|\Â//igs;
					$description=decode_entities($description);
				}
				my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
				# Product Detail
				# if ( $block =~ m/compositionPop\"[^>]*?\=\"([^>]*?)\"/is )
				if ( $block =~ m/<div>\s*([^>]*?)\s*<\/div>/is )
				{
					$prod_detail = &DBIL::Trim($1);
					
				}
				if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
				{
				   $description='-';
				}
				# Image
				while($content223 =~ m/<li[^>]*?(selected)?\">\s*<a[^>]*?href\=\"([^>]*?)\">\s*<img/igs)
				{
					my $select=$1;
					my $alt_image = &DBIL::Trim($2);
					$alt_image =~ s/\$//g;
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product','next-uk');
					if($select eq "")
					{
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$product_id;
						$hash_default_image{$img_object}='n';
						push(@query_string,$query);
					}
					# else
					# {
						# my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						# $imageflag = 1 if($flag);
						# $image_objectkey{$img_object}=$product_id;
						# $hash_default_image{$img_object}='y';
						# push(@query_string,$query);
					# }
				}
				my $main_image="http://cdn2.next.co.uk/Common/Items/Default/Default/ItemImages/AltItemShot/"."$product_id".'.jpg';
				my ($imgid,$img_file) = &DBIL::ImageDownload($main_image,'product','next-uk');
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=$product_id;
				$hash_default_image{$img_object}='y';
				push(@query_string,$query);
				
				# Size & Out_of_stock
				my @img;
				if($block=~m/\-(\w+)\">(?:Size|Colour)<\/label>/is)
				{
					my $style_id=$1;
					if($content223=~m/StyleID\:$style_id([\w\W]*?)(?:\{Style|<\/script>)/is)
					{
						my $style_block=$1;
						while($style_block=~m/\{Name\:\"([^>]*?)\"\,([\w\W]*?)\}\]\}/igs)
						{
							my $fit=$1;
							my $fit_block=$2;
							while($fit_block=~m/\{ItemNumber\:\"(([^>]*?)\-\s*\w{3})\"\,Colour\:\"([^>]*?)\"\,/igs)
							{
								my $size_id=$1;
								my $sid=$2;
								my $colour=$3;
								if($colour=~m/\w+(?:\s+|\/)\w+/is)
								{
									if($price_text=~m/\W*(\d[^>]*?)\s*\-\W*(\d[^>]*?)$/is)
									{
										$v1=&DBIL::Trim($1);
										$v2=&DBIL::Trim($2);
										if($v1>$v2)
										{
											$price= $v1;
										}
										else
										{
											$price= $v2;
										}
									}
								}	
								push (@img,$sid);
								$sid=~s/\-//is;
								$sid=lcfirst($sid);
								my $size_link="http://www.next.co.uk/item/$size_id"."?CTRL=select";   ###### Size Url  formation #######
								my $size_cont=get_content($size_link);
								if($size_cont ne 1)													  ###### Checking Correct Size Url ####
								{
									if($size_cont=~m/>\s*Choose\s*Size<([\w\W]*?)<\/select>/is)
									{
										my $b=$1;
										my @size;
										while($b=~m/tion>\s*<option\s*value[^>]*?>([^>]*?)</igs)
										{
											my $val=$1;
											push (@size, $val);
										}
										foreach (@size)
										{
											my $ind_size=$_;
											my $total_size="$ind_size";
											$total_size=~s/\s*\W*\-\W*\s*sold\s*out//igs;
											$total_size=&DBIL::Trim($total_size);
											if($total_size=~m/([^>]*?)\s*\-\s*\W*(\d+\.[^>]*?)$/is)
											{
												$total_size=$1;
												$price=&DBIL::Trim($2);
											}
												
											if($ind_size=~m/sold\s*out/is)
											{
												$out_of_stock='y';
											}
											else
											{
												$out_of_stock='n';
											}
											if($colour eq "")
											{
												$colour="$col";
											}
											if($colour eq "")
											{
												$colour="No raw color";
											}
											$total_size="$fit, $total_size";
											$total_size=~s/^\,\s*//is;
											my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$total_size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
											$skuflag = 1 if($flag);
											$sku_objectkey{$sku_object}=$sid;
											push(@query_string,$query);
										}
									}
								}
								else
								{
									my $total_size='';
									my $out_of_stock='n';
									if($colour eq "")
									{
										$colour="$col";
									}
									if($colour eq "")
									{
										$colour="No raw color";
									}
									my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$total_size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
									$skuflag = 1 if($flag);
									$sku_objectkey{$sku_object}=$sid;
									push(@query_string,$query);
								}
							}
						}
					}
				}		
				else      ######### No Size & No Colour ######
				{
					my $total_size='One Size';
					my $colour='';
					my $out_of_stock='';
					if($price eq "")
					{
						$out_of_stock='y';
					}
					else
					{
						$out_of_stock='n';
					}
					if($colour eq "")
					{
							$colour="$col";
					}
					if($colour=~m/\w+(?:\s+|\/)\w+/is)
					{
						if($price_text=~m/\W*(\d[^>]*?)\s*\-\W*(\d[^>]*?)$/is)
						{
							$v1=&DBIL::Trim($1);
							$v2=&DBIL::Trim($2);
							if($v1>$v2)
							{
								$price= $v1;
							}
							else
							{
								$price= $v2;
							}
						}
					}
					if($colour eq "")
					{
							$colour="No raw color";
					}
					
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$total_size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$product_id;
					push(@query_string,$query);
				}
				
				######### Default Image for Each Colour #######
				foreach my $img_id(@img)
				{
					$img_id=~s/\-//is;
					$img_id=lcfirst($img_id);
					if($img_id != $product_id)
					{
						my $image2="http://cdn2.next.co.uk/Common/Items/Default/Default/ItemImages/AltItemShot/"."$img_id".'.jpg';
						my $alt_image2 = &DBIL::Trim($image2);
						$alt_image2 =~ s/\$//g;
						my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image2,'product','next-uk');
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image2,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}=$img_id;
						$hash_default_image{$img_object}='y';
						push(@query_string,$query);
					}	
				}
				##### Sku_has_Image #########
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
				
				print "\nUpdate Product:$product_object_key url:$url3\n";
				$brand=$bran;
				my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
				push(@query_string,$query1);
				push(@query_string,$query2);
				# push(@query_string,$query);
				# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
				# push(@query_string,$qry);
				&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
				$dbh->commit();
				$tid++;
			}	
		}
		if($tid==0)    ######### if Retailer_Product_Reference does not match in Url and Product ############
		{
			my ($price,$price_text,$brand,$sub_category,$item_no,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour, $v1, $v2,$product_id);
			##### Price & Product Name #########
			if ($content223 =~ m/Price\">([^>]*?(\d+(?:\.\d+)?))(?:\s*<[^>]*?>\s*)+([^>]*?)\s*</is)
			{
				$price_text= $1;
				$price= &DBIL::Trim($2);
				$product_name= &DBIL::Trim($3);
				$product_name=~s/\&\#174\;/®/igs;
				$product_name =~ s/<[^>]*?>|\Â//igs;
				$product_name =~ s/\([^>]*?\)//igs;
				$price_text =~ s/<[^>]*?>|\Â/ /igs;
				$price_text=~s/\s+/ /igs;
				$price_text=~s/^\s*|\s*$//igs;
				$price_text=~s/\&pound\;/\Â\£/igs;
				$price_text =~ s/\&\#163\;/\Â\£/igs;
				$price_text=~s/\£/\Â\£/igs;
				$price_text=~s/Was[^>]*?\£/Was \Â\£/igs;
				$price_text=~s/Now\s*\£/Now \Â\£/igs;
				$price_text=decode_entities($price_text);
				$product_name=decode_entities($product_name);
				
				if($price_text=~m/\W*(\d[^>]*?)\s*\-\W*(\d[^>]*?)$/is)
				{
					$v1=&DBIL::Trim($1);
					$v2=&DBIL::Trim($2);
					if($v1<$v2)
					{
						$price= $v1;
					}
					else
					{
						$price= $v2;
					}
				}	
			}
			###### Retailer_Product_Reference #############
			if ( $content223 =~ m/ItemNumber\">\s*([^>]*?)\s*</is )
			{
				$item_no = &DBIL::Trim($1);
				$product_id=$item_no;
				$product_id=~s/\-//is;
			}
			$product_id=lcfirst($product_id);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname,$retailer_id);
			goto end if($ckproduct_id == 1);
			undef ($ckproduct_id);
			if ( $content223 =~ m/<div\s*class\=\"StyleContent\">\s*<div>([\w\W]*?)<div/is )
			{
				$description = &DBIL::Trim($1);
				$description =~ s/<[^>]*?>|\Â//igs;
				$description=decode_entities($description);
			}
			######### Product Detail & Description ###########
			my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
			if ( $content223 =~ m/<div>\s*([^>]*?)\s*<\/div>/is )
			{
				$prod_detail = &DBIL::Trim($1);
				
			}
			if(($product_name ne '' or $product_id ne '' ) && ($description eq '' and $prod_detail eq ''))
			{
			   $description='-';
			}
			###### Image ##########
			while ( $content223 =~ m/<li[^>]*?(selected)?\">\s*<a[^>]*?href\=\"([^>]*?)\">\s*<img/igs )
			{
				my $select=$1;
				my $alt_image = &DBIL::Trim($2);
				$alt_image =~ s/\$//g;
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product','next-uk');
				if($select eq "")
				{
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_id;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				# else
				# {
					# my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					# $imageflag = 1 if($flag);
					# $image_objectkey{$img_object}=$product_id;
					# $hash_default_image{$img_object}='y';
					# push(@query_string,$query);
				# }
			}
			
			my $main_image="http://cdn2.next.co.uk/Common/Items/Default/Default/ItemImages/AltItemShot/"."$product_id".'.jpg';
			my ($imgid,$img_file) = &DBIL::ImageDownload($main_image,'product','next-uk');
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}=$product_id;
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);
				
			my @img;
			if($content223=~m/\-(\w+)\">(?:Size|Colour)<\/label>/is)
			{
				my $style_id=$1;
				if($content223=~m/StyleID\:$style_id([\w\W]*?)(?:\{Style|<\/script>)/is)
				{
					my $style_block=$1;
					while($style_block=~m/\{Name\:\"([^>]*?)\"\,([\w\W]*?)\}\]\}/igs)
					{
						my $fit=$1;
						my $fit_block=$2;
						while($fit_block=~m/\{ItemNumber\:\"(([^>]*?)\-\s*\w{3})\"\,Colour\:\"([^>]*?)\"\,/igs)
						{
							my $size_id=$1;
							my $sid=$2;
							my $colour=$3;
							if($colour=~m/\w+(?:\s+|\/)\w+/is)
							{
								if($price_text=~m/\W*(\d[^>]*?)\s*\-\W*(\d[^>]*?)$/is)
								{
									$v1=&DBIL::Trim($1);
									$v2=&DBIL::Trim($2);
									if($v1>$v2)
									{
										$price= $v1;
									}
									else
									{
										$price= $v2;
									}
								}
							}
							push (@img,$sid);
							$sid=~s/\-//is;
							$sid=lcfirst($sid);
							my $size_link="http://www.next.co.uk/item/$size_id"."?CTRL=select";   ###### Size Url  formation #######
							my $size_cont=get_content($size_link);
							if($size_cont ne 1)													  ###### Checking Correct Size Url ####
							{
								if($size_cont=~m/>\s*Choose\s*Size<([\w\W]*?)<\/select>/is)
								{
									my $b=$1;
									my @size;
									while($b=~m/tion>\s*<option\s*value[^>]*?>([^>]*?)</igs)
									{
										my $val=$1;
										push (@size, $val);
									}
									foreach (@size)
									{
										my $ind_size=$_;
										my $total_size="$ind_size";
										$total_size=~s/\s*\W*\-\W*\s*sold\s*out//igs;
										$total_size=&DBIL::Trim($total_size);
										if($total_size=~m/([^>]*?)\s*\-\s*\W*(\d+\.[^>]*?)$/is)
										{
											$total_size=$1;
											$price=&DBIL::Trim($2);
										}
											
										if($ind_size=~m/sold\s*out/is)
										{
											$out_of_stock='y';
										}
										else
										{
											$out_of_stock='n';
										}
										if($colour eq "")
										{
											$colour="$col";
										}
										if($colour eq "")
										{
											$colour="No raw color";
										}
										$total_size="$fit, $total_size";
										$total_size=~s/^\,\s*//is;
										my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$total_size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
										$skuflag = 1 if($flag);
										$sku_objectkey{$sku_object}=$sid;
										push(@query_string,$query);
									}
								}
							}
							else
							{
								my $total_size='';
								my $out_of_stock='n';
								if($colour eq "")
								{
									$colour="$col";
								}
								if($colour=~m/\w+(?:\s+|\/)\w+/is)
								{
									if($price_text=~m/\W*(\d[^>]*?)\s*\-\W*(\d[^>]*?)$/is)
									{
										$v1=&DBIL::Trim($1);
										$v2=&DBIL::Trim($2);
										if($v1>$v2)
										{
											$price= $v1;
										}
										else
										{
											$price= $v2;
										}
									}
								}
								if($colour eq "")
								{
									$colour="No raw color";
								}
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$total_size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$sid;
								push(@query_string,$query);
							}
						}
					}
				}
			}		
			else      ######### No Size & No Colour ######
			{
				my $total_size='One Size';
				my $colour='';
				my $out_of_stock='';
				if($price eq "")
				{
					$out_of_stock='y';
				}
				else
				{
					$out_of_stock='n';
				}
				if($colour eq "")
				{
						$colour="$col";
				}
				if($colour=~m/\w+(?:\s+|\/)\w+/is)
				{
					if($price_text=~m/\W*(\d[^>]*?)\s*\-\W*(\d[^>]*?)$/is)
					{
						$v1=&DBIL::Trim($1);
						$v2=&DBIL::Trim($2);
						if($v1>$v2)
						{
							$price= $v1;
						}
						else
						{
							$price= $v2;
						}
					}
				}
				if($colour eq "")
				{
						$colour="No raw color";
				}
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$total_size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$product_id;
				push(@query_string,$query);
			}
			###### Default Image for Each Colour #########
			foreach my $img_id(@img)
			{
				$img_id=~s/\-//is;
				$img_id=lcfirst($img_id);
				if($img_id != $product_id)
				{
					my $image2="http://cdn2.next.co.uk/Common/Items/Default/Default/ItemImages/AltItemShot/"."$img_id".'.jpg';
					my $alt_image2 = &DBIL::Trim($image2);
					$alt_image2 =~ s/\$//g;
					my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image2,'product','next-uk');
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image2,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$img_id;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}	
			}
			##### Sku_has_Image ##########
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
			$brand=$bran;
			print "\nUpdate Product:$product_object_key url:$url3\n";
			PNF:
			my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id);
			push(@query_string,$query1);
			push(@query_string,$query2);
			# push(@query_string,$query);
			# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
			# push(@query_string,$qry);
			&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
			end:
				print "";
				$dbh->commit();
		}
	}
}1;

sub get_content
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	home:
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
		return($content);
	}
	elsif($code =~m/404/is)
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(5);
			goto home;
		}
		return 1;
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(5);
			goto home;
		}
		return 1;
	}
}
sub post_content()
{
	my $size_value=shift;
	my $color_id=shift;
	my $rerun_count=1;
	home:
	my $req1 = HTTP::Request->new(POST=>"http://www.next.co.uk/bag/add");
	$req1->header("Content-Type"=>"application/x-www-form-urlencoded; charset=UTF-8");
	$req1->content("id=$color_id&option=$size_value&quantity=1");
	my $res1 = $ua->request($req1);
	$cookie->extract_cookies($res1);
	$cookie->save;
	$cookie->add_cookie_header($req1);
	my $code1=$res1->code();
	print "$code1";
	my $content;
	if($code1 =~m/20/is)
	{
		$content = $res1->content;
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(5);
			goto home;
		}
		$cookie->clear_temporary_cookies;
		return 1;
	}
	$cookie->clear_temporary_cookies;
	return($content);
}
