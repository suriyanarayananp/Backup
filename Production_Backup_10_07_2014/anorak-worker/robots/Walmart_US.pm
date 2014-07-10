#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Walmart_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
use DateTime;
# require "/opt/home/merit/Merit_Robots/DBIL.pm";
##require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name, $robotname_detail, $robotname_list, $Retailer_Random_String, $pid, $ip, $excuetionid, $country, $ua, $cookie_file, $retailer_file, $cookie);

sub Walmart_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;

	####Variable Initialization##############
	$robotname='Walmart-US--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Wal';
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
	my $skuflag = 0; my $imageflag = 0;		
	
	if($product_object_key) 
	{	
		my $url3=$url;
		my $multi_product_flag=0;
		my @query_string;	
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;		
		$url3='http://www.walmart.com'.$url3 unless($url3=~m/^\s*http\:/is);
		my $content2 = get_content($url3);
		
		my ($price,$price_text,$brand,$sub_category,$item_no,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour);
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@image_object_key,@sku_object_key,@string, @direct_image);

		# ItemNo / Product ID collection
		if($content2=~m/<meta[^>]*?property\s*\=\s*\"og\:url\"\s*content\s*\=\"[^>]*?\/(\d+)\s*\"[^>]*?>/is)
		{
			$item_no=$1;
			# Checking Duplication using item number
			my $ckproduct_id = &DBIL::UpdateProducthasTag($item_no, $product_object_key, $dbh, $robotname, $retailer_id);					
			goto LAST if($ckproduct_id == 1);		
			undef ($ckproduct_id);
		}	
		
		#TO Check whether it is a In store product mark as X.
		if($content2=~m/price\s*\:\s*\'([\w\W]*?)\'\s*\,/is) 
		{
			my $x_prod_con=clean($1);
			if($x_prod_con=~m/\s*In\s*stores\s*only\s*/is) # TO Check whether it is a In store product mark as X.
			{
				goto PNF;
			}
		}
		## Price and Price text information ###
		
		###if ( $content2 =~ m/<div\s*class\s*\=\"PricingInfo\"[^>]*?>([\w\W]*?)<\/div>/is )
		if ( $content2 =~ m/<div\s*class\s*\=\"PricingInfo\s*[^>]*?>([\w\W]*?)<\/div>/is )
		{
			$price_text = &DBIL::Trim(clean($1));
			if ( $price_text =~ m/\s*\$\s*([\d\.\,]+)[\w\W]*?<span\s*class\=\"smallPriceText[\d]*?\">([\d\,\.]+)$/is )
			{
				$price = &DBIL::Trim(clean($1.$2));
				$price =~s/\,//igs;
				$price =~s/\s+//igs;
			}
			elsif ( $price_text =~ m/\s*\$\s*([\d\.\s\,]+)/is )
			{				
				$price = &DBIL::Trim(clean($1));
				$price =~s/\,//igs;
				$price =~s/\s+//igs;
			}
			if($price_text=~m/^\s*From\s*([^<]*?)$/is)
			{
				$price_text=$1;
			}
			if($content2 =~m/<div\s*class\s*\=\s*\"\s*Was\s*Price[^>]*?>\s*([^<]*?)</is)
			{
				my $price_text2 =&DBIL::Trim(clean($1));
				$price_text ="$price_text2"."-"."$price_text";
			}
		}
		elsif($content2 =~ m/price\s*\:\s*\'\s*([\w\W]*?\d+)\s*(?:(?:\s*<[^>]*?>\s*)+\s*)?<\/div>/is)
		{
			$price_text = &DBIL::Trim(clean($1));
			
			if($price_text=~m/^\s*In\s*stores\s*only/is)
			{
				$price_text="";
			}
			elsif ( $price_text =~ m/\s*\$\s*([\d\.\,]+)[\w\W]*?<span\s*class\=\"smallPriceText[\d]*?\">([\d\,\.]+)$/is )
			{
				$price = &DBIL::Trim(clean($1.$2));
				$price =~s/\,//igs;
				$price =~s/\s+//igs;
			}
			elsif ( $price_text =~ m/\s*\$\s*([\d\.\s\,]+)/is )
			{
				$price = &DBIL::Trim(clean($1));
				
				$price =~s/\,//igs;
				$price =~s/\s+//igs;
			}
			
			if($price_text=~m/^\s*From\s*([^<]*?)$/is)
			{
				$price_text=$1;
			}
			if($content2 =~m/<div\s*class\s*\=\s*\"\s*Was\s*Price[^>]*?>\s*([^<]*?)</is)
			{
				my $price_text2 =&DBIL::Trim(clean($1));
				$price_text ="$price_text2"."-"."$price_text";
			}
		}	
		if($price=~m/^\s*$/is)
		{
			$price='NULL';
		}
		
		#### Multi-Product Check
		if(($content2 =~ m/<ul\s*class\=\"BundleComponentsList\">[\w\W]*?<\/ul>/is)||($content2 =~ m/More\s*about\s*this\s*bundle/is))
		{
			$multi_product_flag=1;
		}
		
		##Brand Tag from Product Name##
		if ( $content2 =~ m/<meta[^>]*?prop[^>]*?\=\"brand\"[^>]*?content=\"([^>]*?)\s*\"[^>]*?>/is )
		{
			$brand = &DBIL::Trim(clean($1));
			if($brand=~m/L\.E\.I|Oh\!\s*Mamma|Smart\s*\&\s*Sexy|Brinley\s*Co/is) ### May be this brand can be got in filter itself, it differs in info page, so making Brands duplication### Avoiding here.
			{
				print "Brand exist\n";
			}
			else
			{
				if($brand ne "")
				{
					####&DBIL::SaveTag('Brand',$brand,$product_object_key,$dbh,$robotname,$Retailer_Random_String,$excuetionid);
				}
			}
		}
		# Product_name
		if ( $content2 =~ m/<h1[^>]*?\"productTitle\"[^>]*?>([^<]*?)</is )
		{
			$product_name = &DBIL::Trim(clean($1));
		}
		# Description and detail
		if ( $content2 =~ m/<span[^>]*?\-details\-short\-desc\s*(?:\'|\")[^>]*?>([\w\W]*?)<\/div>([\w\W]*?<\/div>)/is )
		{
			$description = $1;
			$prod_detail = $2;
			
			$description=~s/\<li[^>]*?\>/ -/igs;
			$description=~s/^\s*\-//igs;
			$prod_detail=~s/\<li[^>]*?\>/ -/igs;
			$prod_detail=~s/^\s*\-//igs;
			
			$description = &DBIL::Trim(clean($description));
			$prod_detail = &DBIL::Trim(clean($prod_detail));				
			$description=~s/(?:\s*<[^>]*?>\s*)*\s*\<\/span\s*$//igs;
			$prod_detail=~s/(?:\s*<[^>]*?>\s*)*\s*\<\/span\s*$//igs;
			if($description eq "")
			{
				$description=$prod_detail;
				$prod_detail="";
			}
			if(($content2 =~ m/<h\d*>\s*Item\s*Description\s*(?:\s*<[^>]*?>\s*)+\s*\s*Top\s*of\s*Page\s*</is)&&($content2 =~ m/<div\s*class\s*\=\s*\"Bundles\s*Opt\s*Desc\s*\"\s*>([\w\W]*?)<\/div>\s*<\/div>/is)&&($description ne ""))
			{
				my $description1 = $1;
				
				$description1=~s/\<li[^>]*?\>/ -/igs;
				$description1=~s/^\s*\-//igs;
			
				$description = &DBIL::Trim(clean($description1)).",$description";
			}
			elsif(($content2 =~ m/<h\d*>\s*Item\s*Description\s*(?:\s*<[^>]*?>\s*)+\s*\s*Top\s*of\s*Page\s*</is)&&($content2 =~ m/<div\s*class\s*\=\s*\"Bundles\s*Opt\s*Desc\s*\"\s*>([\w\W]*?)<\/div>\s*<\/div>/is)&&($description eq ""))
			{
				$description = $1;
				
				$description=~s/\<li[^>]*?\>/ -/igs;
				$description=~s/^\s*\-//igs;
			
				$description = &DBIL::Trim(clean($description));
			}
		}
		$description=decode_entities($description);
		$prod_detail=decode_entities($prod_detail);	
		
		if(($product_name ne '' or $item_no ne '' ) && ($description eq '' and $prod_detail eq ''))
		{
			$description='-';
		}
		
		###Out of Stock
		if($content2=~m/Bundle\s*Availability\s*\-\->\s*(?:\s*<[^>]*?>\s*)+\s*([^<]*?)</is)
		{
			$out_of_stock=$1;
		}
		elsif($content2=~m/class\s*\=\s*\"\s*(?:In\s*stock|Online\s*Not\s*Sold)\s*\"\s*>([\w\W]*?)<\/div>/is)
		{
			my $blk1=$1;
			
			if($blk1=~m/>\s*(In\s*stock)\s*(?:\s*<[^>]*?>\s*)+\s*for\s*\:\s*</is)
			{
				$out_of_stock=$1;
			}
		}
		$out_of_stock =~ s/^\s*In\s*Stock\s*$/n/igs;
		$out_of_stock =~ s/^\s*Out\s*of\s*Stock\s*Online\s*$/y/igs;
		$out_of_stock =~ s/^\s*$/y/igs;
		
		###Size,Color,Out_of stock
		my ($size,$Swatch_Color,$Swatch_Color1,$colourj,$colour_code,$select,$sizecolour,$stone,@temp,$default_colour);
		my $count=1;
		
		####To map Sku_has_image code if no swatch image
		if($content2=~m/Select\s*Color|Select\s*Material/is)
		{
			$select="Yes";
			print"\nselect::$select\n";
		}
		elsif($content2=~m/Select\s*size\s*\/\s*Color/is)
		{
			$select="Yes";
			$sizecolour="Yes";
			print"\nselect::$select\n";
		}
		elsif($content2=~m/Select\s*stone|Select\s*Birthstone/is)
		{
			$select="Yes";
			$stone="Yes";
			print"\nstone::$stone\n";
		}
		# elsif($content2=~m/name\=\"selected_Option\"/is)
		# {
			# $select="Yes";
			# print"\nselect Option::$select\n";
		# }
		
		if($content2=~m/<div\s*class\s*\=\s*\"\s*prt\s*Hid\s*\"\s*>\s*<div\s*id\s*\=\s*\"VARIANT\w*SELECTOR\s*\"\s*>/is)
		{
			if($content2=~m/<\s*script\s*type\s*\=\s*\"\s*text\/javascript\s*\"\s*>\s*[^\{]*?var\s*(?:variants|DefaultItem)\s*([\w\W]*?)(?:var\s*variant\s*Widgets|Variant\s*WidgetSelectorManager[^\(]*?\([^\,]*?\,\s*Default\s*Item\))/is)
			{
				my $block=$1;			
				while($block=~m/\{\s*itemId\s*\:\s*([\w\W]*?)\}\s*\]\s*\}/igs)
				{
					my $blck1=$1;
					
					if($blck1=~m/\s*is\s*In\s*Stock\s*\:\s*([^\,]*?)\,/is)
					{
						$out_of_stock=$1;
						
						$out_of_stock =~ s/^\s*false\s*/y/igs;
						$out_of_stock =~ s/\s*true\s*/n/igs;
						$out_of_stock =~ s/^\s*$/y/igs;
					}
					### Price
					if($blck1=~m/<div\s*class\s*\=\s*\"\s*Pricing\s*Info[^>]*?>\s*([\w\W]*?)<\/div>/is)
					{
						$price_text = &DBIL::Trim(clean($1));
						
						if($price_text=~m/^\s*From\s*([^<]*?)$/is)
						{
							$price_text=$1;
						}
						
						if ( $price_text =~ m/\s*\$?([\d\.\,]+)/is )
						{
							$price = &DBIL::Trim(clean($1));
							$price =~s/\,//igs;
							$price =~s/\s+//igs;
						}
					}
					if($blck1=~m/<div\s*class\s*\=\s*\"Was\s*Price[^>]*?>\s*([\w\W]*?)<\/div>/is)
					{
						my $price_text1 =&DBIL::Trim(clean($1));
						$price_text ="$price_text1"."-"."$price_text";
						$price_text=~s/\.\s*/./igs;
					}
					###Size matching by Size|Total\s*Carats
					if($blck1=~m/variantAttrName\s*\:\s*(?:\'|\")\s*[^\'\"]*?(?:Size|Total\s*Carats)[^\'\"]*?\s*(?:\'|\")\,[\w\W]*?variantAttrValue\s*\:\s(?:\'|\")([^\']*?)(?:\'|\")\s*\,/is)
					{
						$size=$1;
						$size=decode_entities($size);
						$size=~s/\'//igs;
						$size=~s/\\//igs;
					}
					####If Width for Sizeis available
					if($blck1=~m/variantAttrName\s*\:\s*(?:\'|\")\s*[^\'\"]*?Width[^\'\"]*?\s*(?:\'|\")\,[\w\W]*?variantAttrValue\s*\:\s(?:\'|\")([^\']*?)(?:\'|\")\s*\,/is)
					{
						my $width=$1;
						$size="$size $width";
					}
					####Colour Matching by Color|Pattern|stone|Birthstone|Material|colour|Finish
					
					if($blck1=~m/variantAttrName\s*\:\s*(?:\'|\")\s*[^\'\"]*?(?:Color|Pattern|stone|Birthstone|Material|colour|Finish|Character)[^\'\"]*?\s*(?:\'|\")\,[\w\W]*?variantAttrValue\s*\:\s(?:\'|\")([^\']*?)(?:\'|\")\s*\,/is)
					{
						$colourj=clean($1);
						print "Color Matching IF LOOP1::  $colourj\n";
						####If both Stone & Colour are avalilable
						if($blck1=~m/variantAttrName\s*\:\s*(?:\'|\")\s*[^\'\"]*?(?:stone|Birthstone|Material)[^\'\"]*?\s*(?:\'|\")\,[\w\W]*?variantAttrValue\s*\:\s(?:\'|\")[^\']*?(?:\'|\")\s*\,/is)
						{
							if($blck1=~m/variantAttrName\s*\:\s*(?:\'|\")\s*[^\'\"]*?Color[^\'\"]*?\s*(?:\'|\")\,[\w\W]*?variantAttrValue\s*\:\s(?:\'|\")([^\']*?)(?:\'|\")\s*\,/is)
							{
								my $col=clean($1);
								$colourj="$colourj $col";
								print "Both Stone & Colour Color Matching IF LOOP1::  $colourj\n";
							}
						}
						push(@temp,$colourj);
					}
					
					###To map Sku_has_image by code
					if($blck1=~m/upc\:\s*\'([^<]*?)\'/is)
					{
						$colour_code=$1;
					}
					
					###If Size & colour are merged in single dropdown(Select Size / Colour)
					if($sizecolour eq "Yes")
					{
						print"\nsizecolour:: $sizecolour\n";
						if($colourj=~m/\//is)
						{
							$size=$colourj;
							$size=~s/\s*\/[^<]*?$//igs;
							$colourj=~s/^[^<]*?\/\s*//igs;
							print"\nSize:: $size\n";
							print"\nColour::$colourj\n";
						}
					}
					###If Size & colour are merged in single dropdown(Select Stone)
					if($stone eq "Yes")
					{
						print"\nstone:: $stone\n";
						if($colourj=~m/\s*Carat\s*|\s*Cut\s*/is)
						{
							$size=$colourj;
							$size=~s/\s*(?:Carat|Cut)[^<]*?$//igs;
							$colourj=~s/^[^<]*?(?:Carat|Cut)\s*//igs;
							print"\nSize:: $size\n";
							print"\nColour:: $colourj\n";
						}
					}
					# Making the price NULL if empty
					$price='null' if($price eq '' or $price eq ' ');
					# Writing the Sku details to DB
					my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colourj,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					push(@query_string,$query);	
					if($select eq 'Yes')
					{
						print "colour_code>>$colour_code\n";
						$sku_objectkey{$sku_object}=$colour_code;
					}
					elsif($colourj ne '')
					{
						print "colourj>>$colourj\n";
						$sku_objectkey{$sku_object}=lc($colourj);
					}
					else
					{
						print "code>>No Colour\n";
						$sku_objectkey{$sku_object}='No Colour';
					}
				}
			}
		}
		elsif($content2=~m/<div\s*class\=\"prtHid\">\s*<div\s*id\=\"VARIANT_SELECTOR\"[^>]*?>([\w\W]*?)<p[^>]*?class\=\"clear\"[^>]*?>/is) ##No JavaScript
		{
			my $block1=$1;
			my (@Swatch,@size,@Swatch_url,@width_size_arr);
			
			if($block1=~m/>\s*(?:Select|Set)\s*Size\s*<([\w\W]*?)<\/select>/is)
			{
				my $block2=$1;
				
				while ( $block2 =~ m/<option[^>]*?>([^<]*?)</igs)
				{
					$size = $1;
					push(@size,$size);
				}
				
				#colour
				if($content2=~m/Color\s*\:s*<([\w\W]*?)<\/div>\s*<p[^>]*?class=[^>]*?>/is)
				{
					my $block3=$1;
					
					while($block3=~m/<div\s*class\=\"BoxSelection\"[^>]*?>\s*<img[^>]*?title\=\"([^>]*?)\"[^>]*?>/igs)
					{
						$Swatch_Color=$1;
						push(@Swatch,$Swatch_Color);
					}
					if($block3=~m/>\s*Select\s*Color\s*<([\w\W]*?)<\/select>/is)
					{
						my $clr=$1;
						
						while($clr=~m/<option\s*id\s*\=\s*\"[^>]*?>\s*([^>]*?)</igs)
						{
							$Swatch_Color=$1;
							push(@Swatch,$Swatch_Color);
						}
					}
				}
				
				####### Width Size #####
				if($content2=~m/<span\s*id\=\"step2\"\s*class\=\"BodyMBold\">[^>]*?Width\:\s*<\/span>([\w\W]*?)<\/select>\s*<\/div>\s*<\/div>/is)
				{
					my $width_block=$1;
					
					while($width_block=~m/<option\s*id\=\"[^>]*?\"\s*style\=\"display\:block\"\s*value\=\"[\d\W]*?\">([^>]*?)<\/option>/igs)
					{
						my $width_size=&DBIL::Trim(clean($1));
						push(@width_size_arr,$width_size);
					}
				}
				
				if(!@width_size_arr) #### Width Size not available ####
				{
					foreach my $colour (@Swatch)
					{					
						foreach my $size1 (@size)
						{						
							my ($sku_object, $flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size1,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=lc($colour);
							push(@query_string,$query);	
						}
					
					}
					if(!@Swatch)
					{
						foreach my $size1(@size)
						{
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size1,"",$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);						
							$sku_objectkey{$sku_object}='No Colour';	
							push(@query_string,$query);	
						}
					}				
					if(!@size)
					{	
						foreach my $colour(@Swatch)
						{					
							my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"",$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=lc($colour);
							push(@query_string,$query);	
						}
					}
					############################ End of the Normal Size and color ###					
				}
				else
				{
					foreach my $colour (@Swatch) # If colour, Size and width available
					{				
						foreach my $size1 (@size)
						{
							foreach my $widt_size (@width_size_arr) ### Added Width Size Array
							{
								$size1=$size1.'; '.$widt_size;
								
								my ($sku_object, $flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size1,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=lc($colour);
								push(@query_string,$query);	
							}
						}
					}
					if(!@Swatch) # If colour not available, but Size and width available
					{
						foreach my $size1(@size)
						{
							foreach my $widt_size (@width_size_arr) ### Added Width Size Array
							{
								$size1=$size1.'; '.$widt_size;
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size1,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);						
								$sku_objectkey{$sku_object}='No Colour';
								push(@query_string,$query);
							}
						}
					}
					if(!@size) # If size not available, but colour and width available 
					{
						foreach my $colour(@Swatch)
						{
							foreach my $widt_size (@width_size_arr) ### Added Width Size Array
							{								
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$widt_size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=lc($colour);
								push(@query_string,$query);
							}
						}
					}
				} ### Else Loop for Width
			}
			else
			{
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"",'no raw colour',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}='No Colour';
				push(@query_string,$query);
			}
		}
		else
		{
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,"",'no raw colour',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}='No Colour';
			push(@query_string,$query);
		}
		
		####Image fetching###
		my @default_images;
		my ($default_colour,$code);
		my $default_count=0;
		if($multi_product_flag ne 1)
		{
			my $swatch_content=$1 if($content2=~m/type\:\'SWATCH\'([\w\W]*?)\]/is);
			
			while($swatch_content=~m/value\:\'([^<]*?)\'[^<]*?colorChipImagePath\:\'([^<]*?)\'[^<]*?posterImagePath\:\s*\'([^<]*?)\'/igs)
			{
				my $swatch_colour=clean($1);
				my $swatch_image=$2;
				my $default_image=$3;
				
				####Swatch Image
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_image,'swatch',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_image,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}=lc($swatch_colour);
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
				if($default_count == 0)
				{
					$default_colour=$swatch_colour;
				}
				$default_count++;
				####Default Image
				
				my ($imgid1,$img_file1) = &DBIL::ImageDownload($default_image,'product',$retailer_name);
				
				my ($img_object1,$flag1,$query) = &DBIL::SaveImage($imgid1,$default_image,$img_file1,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag1);
				$image_objectkey{$img_object1}=lc($swatch_colour);
				$hash_default_image{$img_object1}='y';
				push(@query_string,$query);
				push(@default_images,$default_image);
			}
		}
		#### Single or Multi product page Image#####
		if($multi_product_flag == 1 or !@default_images)
		{
			if($content2=~m/<a\s*href\=\'([^<]*?)\'\s*id\=\"Zoomer/is)
			{
				my $direct_image=$1;
				
				my ($imgid,$img_file) = &DBIL::ImageDownload($direct_image,'product',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$direct_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				push(@query_string,$query);
				if(@temp)
				{
					my $code;
					if($direct_image=~m/\/([a-z\d]*?)_/is)
					{
						$code=$1;
					}
					print "code in Image>>$code\n";
					$image_objectkey{$img_object}=$code;
				}
				else
				{
					print "code in Image No Colour>>No Colour\n";
					$image_objectkey{$img_object}='No Colour';
				}	
				$hash_default_image{$img_object}='y';
			}
		}
		
		#### Alternate Image
		while($content2=~m/posterImages\.push\(\'([^<]*?)\'/igs)
		{
			my $alt_image=$1;
			
			if($alt_image=~m/_AV(?:[\d]*?)?_/is)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product',$retailer_name);
				
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);	
				push(@query_string,$query);
				if($default_colour ne '')
				{
					$image_objectkey{$img_object}=lc($default_colour);
				}
				elsif(@temp)
				{
					my $code;
					if($alt_image=~m/\/([a-z\d]*?)_/is)
					{
						$code=$1;
					}
					print "code in Alt_Image>>$code\n";
					$image_objectkey{$img_object}=$code;
				}
				else
				{
					print "code in Alt_Image No Colour>>No Colour\n";
					$image_objectkey{$img_object}='No Colour';
				}
				$hash_default_image{$img_object}='n';
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
				}
			}
		}	
		
		PNF:				
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key, $item_no, $product_name, $brand, $description, $prod_detail, $dbh, $robotname, $excuetionid, $skuflag, $imageflag, $url3, $retailer_id, $multi_product_flag);		
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);
		#### &DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		$dbh->commit();	
	}
}1;
	
### Local Cleaning Function ####
sub clean
{
	my $value1=shift;
	$value1=~s/\&\#8217\;/\'/igs;
	$value1=~s/\&\#58\;//igs;
	$value1=~s/\&\#10\;\s*\-/*/igs;
	$value1=~s/\&\#13\;\s*\-/*/igs;
	$value1=~s/\&quot\;/"/igs;
	$value1=~s/\&quot/"/igs;
	$value1=~s/\&amp\;/&/igs;
	$value1=~s/Â¡Â¯/'/igs;
	$value1=~s/<[^>]*?>/ /igs;
	$value1=~s/\s+/ /igs;
	$value1=~s/^\s+|\s+$//igs;
	$value1=~s/\.\s+/./igs;	
	$value1=~s/\''/\'\'/igs;
	$value1=~s/''/\'\'/igs;
	return($value1);	
}

### Pinging WebPage URL ###
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