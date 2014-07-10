#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Neimanmarkus_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;

require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Neimanmarkus_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	my $logger=shift;
	
	####Variable Initialization##############
	$robotname='Neimanmarkus-US--Detail';
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Nei';
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
	my $mflag=0;
	if($product_object_key)
	{	
	
		my $url3=$url;
		my @query_string;
		my $content2 = get_content($url3);
		$content2=~s/\&nbsp\;/ /igs;
		$content2=~s/\&amp\;/\&/igs;
		$content2=~s/\&\#174\;/®/igs;
		$content2=~s/\&\#233\;/e/igs;
		$content2=~s/\&\#151\;/-/igs;	

		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my %sku_objectkey;
		my %image_objectkey;
		my %hash_default_image;
		my %hash_default_image;
		##################product not found####################
		# if($content2=~m/>Product\s*Not\s*Found</is)
		if($content2=~m/>\s*This\s*item\s*is\s*not\s*available\s*\.\s*</is)
		{
		
		goto PNF;
		
		}
		##################################
		
		my (@arey,@areye,@satz);
		my ($price,$brand,$sub_category,$product_name,$productname,$product_id,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$select_var,$i,$size,$price_text,$color,$sku,$j,$pricetext,$unit);
		
		#################product name and brand ##############################
		if($content2=~m/<span\s*itemprop\=\"brand\"\s*class\=\"designer\">\s*([\w\W]*?)\s*<\/span>\s*([\w\W]*?)\s*<\/h1>/is)
		{
			$brand=$1;
			$productname=$2;
			$brand=~s/<[^>]*?>//igs;
			$productname=~s/<[^>]*?>//igs;
			$productname=~s/\,//igs;
			$productname=~s/amp;//igs;
			$productname=~s/\&\#039\;//igs;
			$productname=~s/\&\#233\;/e/igs;
			$productname=~s/\&nbsp\;/ /igs;
			$productname=~s/\&amp\;\#174\;/ /igs;
			$brand=~s/\,//igs;
			$brand=&DBIL::Trim($brand);
			$productname=&DBIL::Trim($productname);

		}
		elsif($content2=~m/<h1\s*itemprop\=\"name\">\s*([^>]*?)\s*<\/h1>/is)
		{
			$productname=$1;
			$productname=~s/<[^>]*?>//igs;
			$productname=~s/\,//igs;
			$productname=~s/\&\#233\;/e/igs;
			$productname=~s/\&\#039\;//igs;
			$productname=~s/\&nbsp\;/ /igs;
			$productname=&DBIL::Trim($productname);
		}
		elsif ($content2=~m/<span\s*class\=\"designer\">\s*([\w\W]*?)\s*<\/span>\s*([\w\W]*?)\s*<\/h1>/is)
		{
			$brand=$1;
			$productname=$2;
			$brand=~s/<[^>]*?>//igs;
			$productname=~s/<[^>]*?>//igs;
			$productname=~s/\,//igs;
			$productname=~s/amp;//igs;
			$productname=~s/\&\#233\;/e/igs;
			$productname=~s/\&\#039\;//igs;
			$productname=~s/\&nbsp\;/ /igs;
			$brand=~s/\,//igs;
			$brand=&DBIL::Trim($brand);
			$productname=&DBIL::Trim($productname);
		}
		elsif ($content2=~m/<h5>\s*<p>\s*([^>]*?)<\/p>\s*([^>]*?)\s*<\/h5>/is)
		{
			$brand=$1;
			$productname=$2;
			$brand=~s/<[^>]*?>//igs;
			$productname=~s/<[^>]*?>//igs;
			$productname=~s/\,//igs;
			$productname=~s/\&\#233\;/e/igs;
			$productname=~s/\&\#039\;//igs;
			$productname=~s/\&nbsp\;/ /igs;
			$productname=~s/amp;//igs;
			$brand=~s/\,//igs;
			$brand=DBIL::Trim($brand);
			$productname=DBIL::Trim($productname);
		}
		#######product reference number ###############
		my $productid4ref;
		if($url3=~m/prod([\d]+)/is)
		{
			$productid4ref=$1;
			chomp($productid4ref);
		}
		
		my $ckproduct_id = &DBIL::UpdateProducthasTag($productid4ref, $product_object_key, $dbh,$robotname,$retailer_id);
		goto LAST if($ckproduct_id == 1);
		undef ($ckproduct_id);
		my $pr_count=0;
		###########Mulitple product#####################
		if($content2=~m/nm\.marketing\.omnitureproperties\[\"products\"\]\s*\=\s*(\"\;[^>]*?\")\;/is)
		{
			my $mblock=$1;
			if($mblock=~m/\;[^>]*?_[^>]*?\;\;\;\;eVar7=nr_/is)
			{
				while($mblock=~m/\;[^>]*?_[^>]*?\;\;\;\;eVar7=nr_/igs)
				{
					$pr_count++;
				
				}
			}
			elsif($mblock=~m/\;[^>]*?_[^>]*?\;\;\;\;eVar7=nr/is)
			{
				while($mblock=~m/\;[^>]*?_[^>]*?\;\;\;\;eVar7=nr/igs)
				{
					$pr_count++;				
				}
			}
			
		}

		if($pr_count > 1)
		{
			$mflag=1;
			goto top;
		}
		my $identificationno;
		##################### SKU  ########################
		if($content2=~m/<div\s*id\=\"productDetails\"([\w\W]*?)on\s*change\s*function\,\s*generic\s*for\s*all\s*products/is)
		{
			my $block=$1;
			my $block1=$block;
			$block=~s/<[^>]*?>//igs;
			if($block=~m/$productid4ref[^>]*?\(\'([^>]*?)\'\,\'([^>]*?)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/is)
			{
				############ SKU with size #################

				
				if($block1=~m/labeltxt\=\"SIZE\"/is)
				{
					# while($block=~m/$productid4ref[^>]*?\(\'([^>]*?)\'\,\'([^>]*?)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/igs)
					if($block=~m/$productid4ref[^>]*?\(\'(\d+)\'\,\'(prod$productid4ref)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/is)
					{
						while($block=~m/$productid4ref[^>]*?\(\'(\d+)\'\,\'(prod$productid4ref)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/igs)
						{
							$identificationno=$1;
							$product_id=$2;
							$sku=$3;
							$size=$4;
							$color=$5;
							$product_name=$6;
							$out_of_stock=$7;
							$product_name=~s/\'\,\'//igs;
							$product_name=~s/^null//igs;
							$product_id=~s/prod//igs;
							$size=~s/null//igs;
							$color=~s/\\\'/'/igs;
							$color=~s/\'\'//igs;
							$color=~s/null//igs;
							$product_name=~s/\\\'/'/igs;
							###### out of stock #####################
							# if($out_of_stock eq 'stock4')
							# {
							# $out_of_stock='y';
							# }
							# elsif($out_of_stock eq 'stock2')
							# {
							# $out_of_stock='y';
							# }
							# else
							# {
							# $out_of_stock='n';
							# }
							$out_of_stock='n';
							if($content2=~m/>\s*This\s*item\s*is\s*not\s*available\s*\.\s*</is)
							{
								$out_of_stock='y';
								$color='no raw colour' if($color eq "");
							
							}
							$product_name=&DBIL::Trim($product_name);
							$unit=1;
							
							##################Price Text ###########################
							if($block1=~m/<div\s*class\=\"adornmentPriceElement\">([\w\W]*?)<p\s*class/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;

							}
							elsif($block1=~m/span\s*itemprop\=\"price\">([^>]*?)<\/span>/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;

							}
							elsif($block1=~m/\-\-\>\s*<span>([^>]*?)<\/span>/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								# $price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;
								
								
							}
							
							####################price ######################
							
							
							if ($price_text=~m/off\:\s*(\$[\d\.\,]*)/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/NOW\s*\:\s*([^>]*?)\s*$/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/Value\:\s*([^>]*?)$/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}	
							elsif ($price_text=~m/^[^>]*?\$([^>]*?\.\d+)(?:[^>]*)/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif($block1=~m/price\:<\/div><[^>]*?>([^>]*?)<\/span>\s*<\/div>\s*<[^>]*?>\s*<div\s*class\=\"adornmentPriceElement\s*percentOff\"\s*>\s*<[^>]*?>([^>]*?)<\/div>\s*<[^>]*?>([^>]*?)</is)
							{
								$price_text= $1." $2"." $3";
								$price=$3;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								# $price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							
							}
							else
							{
								$price=$price_text;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
								
							}
							$price=~s/Extra[^>]*?$//igs;
							$price=~s/\s+/ /igs;
							$price=~s/^\s+//igs;
							$price=~s/\s+$//igs;
							$price=~s/\d+\%[^>]*?$//igs;

							$price=~s/[^>]*?\://igs;
							$price=~s/[a-z]+//igs;
							$size=~s/\'\'//igs;
							$price="Null" if($price eq '');
							$size="no size" if($size eq '');
						
							if($color eq '')
							{
								
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,'no raw color',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$product_id;
							push(@query_string,$query);			
							}
								
							else
							{	
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$product_id;
								push(@query_string,$query);	
							}
					
						}	
					}
					elsif($block=~m/$productid4ref[^>]*?\(\'(\d+)\'\,\'([^>]*?)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/igs)
					{
						while($block=~m/$productid4ref[^>]*?\(\'(\d+)\'\,\'([^>]*?)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/igs)
						{
							$identificationno=$1;
							$product_id=$2;
							$sku=$3;
							$size=$4;
							$color=$5;
							$product_name=$6;
							$out_of_stock=$7;
							$product_name=~s/\'\,\'//igs;
							$product_name=~s/^null//igs;
							$product_id=~s/prod//igs;
							$size=~s/null//igs;
							$color=~s/\\\'/'/igs;
							$color=~s/\'\'//igs;
							$color=~s/null//igs;
							$product_name=~s/\\\'/'/igs;
							###### out of stock #####################
							# if($out_of_stock eq 'stock4')
							# {
							# $out_of_stock='y';
							# }
							# elsif($out_of_stock eq 'stock2')
							# {
							# $out_of_stock='y';
							# }
							# else
							# {
							# $out_of_stock='n';
							# }
							$out_of_stock='n';
							if($content2=~m/>\s*This\s*item\s*is\s*not\s*available\s*\.\s*</is)
							{
								$out_of_stock='y';
								$color='no raw colour' if($color eq "");
							
							}
							$product_name=&DBIL::Trim($product_name);
							$unit=1;
							
							##################Price Text ###########################
							if($block1=~m/<div\s*class\=\"adornmentPriceElement\">([\w\W]*?)<p\s*class/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;

							}
							elsif($block1=~m/span\s*itemprop\=\"price\">([^>]*?)<\/span>/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;

							}
							elsif($block1=~m/\-\-\>\s*<span>([^>]*?)<\/span>/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								# $price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;
								
								
							}
							
							####################price ######################
							if ($price_text=~m/off\:\s*(\$[\d\.\,]*)/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/NOW\s*\:\s*([^>]*?)\s*$/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/Value\:\s*([^>]*?)$/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/^[^>]*?\$([^>]*?\.\d+)(?:[^>]*)/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif($block1=~m/price\:<\/div><[^>]*?>([^>]*?)<\/span>\s*<\/div>\s*<[^>]*?>\s*<div\s*class\=\"adornmentPriceElement\s*percentOff\"\s*>\s*<[^>]*?>([^>]*?)<\/div>\s*<[^>]*?>([^>]*?)</is)
							{
								$price_text= $1." $2"." $3";
								$price=$3;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								# $price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							
							}
							else
							{
								$price=$price_text;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
								
							}
							$price=~s/Extra[^>]*?$//igs;
							$price=~s/\s+/ /igs;
							$price=~s/^\s+//igs;
							$price=~s/\s+$//igs;
							$price=~s/\d+\%[^>]*?$//igs;

							$price=~s/[^>]*?\://igs;
							$price=~s/[a-z]+//igs;
							$size=~s/\'\'//igs;
							$price="Null" if($price eq '');
							$size="no size" if($size eq '');
						
							if($color eq '')
							{
								
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,'no raw color',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$product_id;
							push(@query_string,$query);			
							}
								
							else
							{	
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$product_id;
								push(@query_string,$query);	
							}
					
						}					
					}
				}
				############ SKU without size #################
				else
				{
					# while($block=~m/$productid4ref[^>]*?\(\'([^>]*?)\'\,\'([^>]*?)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/igs)
					if($block=~m/$productid4ref[^>]*?\(\'(\d+)\'\,\'(prod$productid4ref)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/is)
					{
						while($block=~m/$productid4ref[^>]*?\(\'(\d+)\'\,\'(prod$productid4ref)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/igs)
						{
							$identificationno=$1;
							$product_id=$2;
							$sku=$3;
							$color=$4;
							$size=$5;
							$product_name=$6;
							$out_of_stock=$7;
							$product_name=~s/\'\,\'//igs;
							$product_name=~s/^null//igs;
							$product_id=~s/prod//igs;
							
							$color=~s/\\\'/'/igs;
							$color=~s/\'\'//igs;
							$product_name=~s/\\\'/'/igs;
							###### out of stock #####################
							# if($out_of_stock eq 'stock4')
							# {
							# $out_of_stock='y';
							# }
							# elsif($out_of_stock eq 'stock2')
							# {
							# $out_of_stock='y';
							# }
							# else
							# {
							# $out_of_stock='n';
							# }
							$out_of_stock='n';
							if($content2=~m/>\s*This\s*item\s*is\s*not\s*available\s*\.\s*</is)
							{
								$out_of_stock='y';
								$color='no raw colour' if($color eq "");
							
							}
							$product_name=&DBIL::Trim($product_name);
							$unit=1;
							##################Price Text ###########################
							# if($block1=~m/span\s*itemprop\=\"price\">([^>]*?)<\/span>/is)
							if($block1=~m/<div\s*class\=\"adornmentPriceElement\">([\w\W]*?)<p\s*class/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;

							}
							elsif($block1=~m/span\s*itemprop\=\"price\">([^>]*?)<\/span>/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;

							}
							elsif($block1=~m/\-\-\>\s*<span>([^>]*?)<\/span>/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;
							}
							
							##################Price###########################
							if ($price_text=~m/off\:\s*(\$[\d\.\,]*)/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/NOW\s*\:\s*([^>]*?)\s*$/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/Value\:\s*([^>]*?)$/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/^[^>]*?\$([^>]*?\.\d+)(?:[^>]*)/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif($block1=~m/price\:<\/div><[^>]*?>([^>]*?)<\/span>\s*<\/div>\s*<[^>]*?>\s*<div\s*class\=\"adornmentPriceElement\s*percentOff\"\s*>\s*<[^>]*?>([^>]*?)<\/div>\s*<[^>]*?>([^>]*?)</is)
							{
								$price_text=$1." $2"." $3";
								$price=$3;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								# $price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							
							}
							else
							{
								$price=$price_text;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							$price=~s/Extra[^>]*?$//igs;
							$price=~s/\s+/ /igs;
							$price=~s/^\s+//igs;
							$price=~s/\s+$//igs;
							$price=~s/\d+\%[^>]*?$//igs;
							$price=~s/Extra[^>]*?$//igs;

							$price=~s/[^>]*?\://igs;
							$size=~s/\'\'//igs;
							$price=~s/[a-z]+//igs;
							$price="Null" if($price eq '');
							$size="no size" if($size eq '');
							if($color eq '')
							{
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,'no raw color',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$product_id;
							push(@query_string,$query);	
							}
								
							else
							{	
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$product_id;	
								push(@query_string,$query);
							}
						}
					}
					elsif($block=~m/$productid4ref[^>]*?\(\'(\d+)\'\,\'([^>]*?)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/is)					
					{
						while($block=~m/$productid4ref[^>]*?\(\'(\d+)\'\,\'([^>]*?)\'\,\'sku(\w+)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,\'([^>]*?)\'\,false[^>]*?\/category\/images\/prod_([^>]*?).gif/igs)
						{
							$identificationno=$1;
							$product_id=$2;
							$sku=$3;
							$color=$4;
							$size=$5;
							$product_name=$6;
							$out_of_stock=$7;
							$product_name=~s/\'\,\'//igs;
							$product_name=~s/^null//igs;
							$product_id=~s/prod//igs;
							
							$color=~s/\\\'/'/igs;
							$color=~s/\'\'//igs;
							$product_name=~s/\\\'/'/igs;
							###### out of stock #####################
							# if($out_of_stock eq 'stock4')
							# {
							# $out_of_stock='y';
							# }
							# elsif($out_of_stock eq 'stock2')
							# {
							# $out_of_stock='y';
							# }
							# else
							# {
							# $out_of_stock='n';
							# }
							$out_of_stock='n';
							if($content2=~m/>\s*This\s*item\s*is\s*not\s*available\s*\.\s*</is)
							{
								$out_of_stock='y';
								$color='no raw colour' if($color eq "");
							
							}
							$product_name=&DBIL::Trim($product_name);
							$unit=1;
							##################Price Text ###########################
							# if($block1=~m/span\s*itemprop\=\"price\">([^>]*?)<\/span>/is)
							if($block1=~m/<div\s*class\=\"adornmentPriceElement\">([\w\W]*?)<p\s*class/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;

							}
							elsif($block1=~m/span\s*itemprop\=\"price\">([^>]*?)<\/span>/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;

							}
							elsif($block1=~m/\-\-\>\s*<span>([^>]*?)<\/span>/is)
							{
								$price_text=$1;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;
							}
							
							##################Price###########################
							if ($price_text=~m/off\:\s*(\$[\d\.\,]*)/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/NOW\s*\:\s*([^>]*?)\s*$/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/Value\:\s*([^>]*?)$/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif ($price_text=~m/^[^>]*?\$([^>]*?\.\d+)(?:[^>]*)/is)
							{
								$price=$1;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							elsif($block1=~m/price\:<\/div><[^>]*?>([^>]*?)<\/span>\s*<\/div>\s*<[^>]*?>\s*<div\s*class\=\"adornmentPriceElement\s*percentOff\"\s*>\s*<[^>]*?>([^>]*?)<\/div>\s*<[^>]*?>([^>]*?)</is)
							{
								$price_text=$1." $2"." $3";
								$price=$3;
								$price_text=~s/<[^>]*?>//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s+/ /igs;
								$price_text=~s/^\s*//igs;
								$price_text=~s/\-\-\>//igs;
								$price_text=~s/\s*\<p\s*class//igs;
								$price_text=~s/Details//igs;
								$price_text=~s/NM[^>]*?$//igs;
								$price_text=~s/OC[^>]*?$//igs;
								# $price_text=~s/OC[^>]*?$//igs;
								$price_text=~s/\,//igs;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							
							}
							else
							{
								$price=$price_text;
								$price=~s/\$//igs;
								# $price=~s/\.00//igs;
								$price=~s/\,//igs;
								$price=~s/\d+\%[^>]*?$//igs;
								$price=~s/Extra[^>]*?$//igs;
							}
							$price=~s/Extra[^>]*?$//igs;
							$price=~s/\s+/ /igs;
							$price=~s/^\s+//igs;
							$price=~s/\s+$//igs;
							$price=~s/\d+\%[^>]*?$//igs;
							$price=~s/Extra[^>]*?$//igs;

							$price=~s/[^>]*?\://igs;
							$size=~s/\'\'//igs;
							$price=~s/[a-z]+//igs;
							$price="Null" if($price eq '');
							$size="no size" if($size eq '');
							if($color eq '')
							{
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,'no raw color',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
							$skuflag = 1 if($flag);
							$sku_objectkey{$sku_object}=$product_id;
							push(@query_string,$query);	
							}
								
							else
							{	
								my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								$skuflag = 1 if($flag);
								$sku_objectkey{$sku_object}=$product_id;	
								push(@query_string,$query);
							}
						}
					
					
					}
				}
			}
			else
			{
				###### out of stock with price only  #####################
				if($content2=~m/>\s*This\s*item\s*is\s*not\s*available\s*\.\s*</is)
				{
					$out_of_stock='y';
					
					if($content2=~m/<span\s*itemprop\=\"brand\"\s*class\=\"designer\">\s*([\w\W]*?)\s*<\/span>\s*([\w\W]*?)\s*<\/h1>/is)
					{
						$brand=$1;
						$product_name=$2;
						$brand=&DBIL::Trim($brand);
						$product_name=&DBIL::Trim($product_name);
					}
					# if($block1=~m/span\s*itemprop\=\"price\">([^>]*?)<\/span>/is)
					if($block1=~m/<div\s*class\=\"adornmentPriceElement\">([\w\W]*?)<p\s*class/is)
					{
						$price_text=$1;
						$price_text=~s/<[^>]*?>//igs;
						$price_text=~s/\-\-\>//igs;
						$price_text=~s/\s+/ /igs;
						$price_text=~s/^\s*//igs;
						$price_text=~s/\-\-\>//igs;
						$price_text=~s/\s*\<p\s*class//igs;
						$price_text=~s/Details//igs;
						$price_text=~s/NM[^>]*?$//igs;
						$price_text=~s/OC[^>]*?$//igs;
						$price_text=~s/\,//igs;
					}
					elsif($block1=~m/span\s*itemprop\=\"price\">([^>]*?)<\/span>/is)
					{
						$price_text=$1;
						$price_text=~s/<[^>]*?>//igs;
						$price_text=~s/\-\-\>//igs;
						$price_text=~s/\s+/ /igs;
						$price_text=~s/^\s*//igs;
						$price_text=~s/\-\-\>//igs;
						$price_text=~s/\s*\<p\s*class//igs;
						$price_text=~s/Details//igs;
						$price_text=~s/NM[^>]*?$//igs;
						$price_text=~s/OC[^>]*?$//igs;
						$price_text=~s/\,//igs;
					}
					elsif($block1=~m/\-\-\>\s*<span>([^>]*?)<\/span>/is)
					{
						$price_text=$1;
						$price_text=~s/<[^>]*?>//igs;
						$price_text=~s/\-\-\>//igs;
						$price_text=~s/\s+/ /igs;
						$price_text=~s/^\s*//igs;
						$price_text=~s/\-\-\>//igs;
						$price_text=~s/\s*\<p\s*class//igs;
						$price_text=~s/Details//igs;
						$price_text=~s/NM[^>]*?$//igs;
						$price_text=~s/OC[^>]*?$//igs;
						$price_text=~s/\,//igs;
					}
					##################Price###########################
					if ($price_text=~m/off\:\s*(\$[\d\.\,]*)/is)
					{
						$price=$1;
						$price=~s/\$//igs;
						# $price=~s/\.00//igs;
						$price=~s/\,//igs;
						$price=~s/\d+\%[^>]*?$//igs;
						$price=~s/Extra[^>]*?$//igs;
					}
					elsif ($price_text=~m/NOW\s*\:\s*([^>]*?)\s*$/is)
					{
						$price=$1;
						$price=~s/\$//igs;
						# $price=~s/\.00//igs;
						$price=~s/\,//igs;
						$price=~s/Extra[^>]*?$//igs;
						$price=~s/\d+\%[^>]*?$//igs;
					}
					elsif ($price_text=~m/Value\:\s*([^>]*?)$/is)
					{
						$price=$1;
						$price=~s/\$//igs;
						# $price=~s/\.00//igs;
						$price=~s/\,//igs;
						$price=~s/Extra[^>]*?$//igs;
						$price=~s/\d+\%[^>]*?$//igs;
					}
					elsif ($price_text=~m/^[^>]*?\$([^>]*?\.\d+)(?:[^>]*)/is)
					{
						$price=$1;
						$price=~s/\$//igs;
						# $price=~s/\.00//igs;
						$price=~s/\,//igs;
						$price=~s/\d+\%[^>]*?$//igs;
						$price=~s/Extra[^>]*?$//igs;
					}
					else
					{
						$price=$price_text;
						$price=~s/\$//igs;
						# $price=~s/\.00//igs;
						$price=~s/\,//igs;
						$price=~s/Extra[^>]*?$//igs;
						$price=~s/\d+\%[^>]*?$//igs;
					}
					$price=~s/Extra[^>]*?$//igs;
					$price=~s/\s+/ /igs;
					$price=~s/^\s+//igs;
					$price=~s/\s+$//igs;
					$price=~s/\d+\%[^>]*?$//igs;
					$price=~s/[^>]*?\://igs;
					$price=~s/[a-z]+//igs;
					$price="Null" if($price eq '');
					$size="no size" if($size eq '');
					# print"Price==>$price";
					if($color eq '')
					{
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,'no raw color',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$skuflag = 1 if($flag);
					$sku_objectkey{$sku_object}=$product_id;
					push(@query_string,$query);		
					}
					else
					{	
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$product_id;
						push(@query_string,$query);	
					}
				}
			}
		}
		my $count=1;
		################## Image ###########################
		if($content2=~m/g\"\s*data\-zoom\-\s*url\=\"([^>]*?)\"/is)
		{
			while($content2=~m/data\-zoom\-url\=\"([^>]*?)\"/igs)
			{
				my $product_image1=$1;
				if ($count eq 1)
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_id;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				else		
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_id;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				$count++;
			}
		}
		else
		{
			while($content2=~m/data\-zoom\-url\=\"([^>]*?)\"/igs)
			{
				my $product_image1=$1;
				if ($count eq 1)
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_id;
					$hash_default_image{$img_object}='y';
					push(@query_string,$query);
				}
				else		
				{
					my ($imgid,$img_file) = &DBIL::ImageDownload($product_image1,'product',$retailer_name);
					my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$product_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
					$imageflag = 1 if($flag);
					$image_objectkey{$img_object}=$product_id;
					$hash_default_image{$img_object}='n';
					push(@query_string,$query);
				}
				$count++;
			}
		}
		##################Sku Has image###########################
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
		################## Description ###########################
		top:
		my($des3,$Details);
		if($content2=~m/<div\s*class\=\"suiteTop\">([^>]*?)</is)
		{
			$des3=$1;
			$des3=trim($Details);
		}
		elsif($content2=~/<div\s*class\=\"productTop\">([^>]*?)</is)
		{
			$des3=$1;
			$des3=trim($Details);
		}
		elsif($content2=~/<div\s*class\=\"productCutline\">([^>]*?)</is)
		{
			$des3=$1;
			$des3=trim($Details);	
		}
		elsif($content2=~/class\=\"productCutline\"><ul>([^>]*?)</is)
		{
			$des3=$1;
			$des3=trim($Details);	
		}
		################## Details ###########################
		if($content2=~m/ul><li>([\w\W]*?)<\/li><\/ul>/is)
		{
			$Details=$1;
			$Details=trim($Details);	
		}
		elsif($content2=~m/(<strong>[\w\W]*?)<\/li><\/ul>/is)
		{
			$Details=$1;
			$Details=trim($Details);
		}
		elsif($content2=~m/<br><br>(<li>[\w\W]*?)<\/ul>/is)
		{
			$Details=$1;
			$Details=trim($Details);
		}
		if($des3  eq '')
		{
				$des3='  ';
		}
		$des3=~s/\s+/ /igs;
		
		$des3=&DBIL::Trim($des3);
		$Details=~s/\s+/ /igs;
		$Details=~s/<li>/\*/igs;
		$Details=~s/<strong>/\*/igs;
		$Details=~s/<[^>]*?>//igs;
		$Details=&DBIL::Trim($Details);
		if(($product_name ne '' or $product_id ne '' ) && ($des3 eq '' and $Details eq ''))
		{
		   $des3='-';
		}
		PNF:
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$productid4ref,$productname,$brand,$des3,$Details,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# push(@query_string,$query);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry); 
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh,$logger);
		LAST:		
		print " ";

		$dbh->commit();
	}
}1;

sub get_content
{
	my $url = shift;
	my $rerun_count=0;
	$url =~ s/^\s+|\s+$//g;
	$url =~ s/amp\;//g;
	Home:
	my $req = HTTP::Request->new(GET=>"$url");
	$req->header("Content-Type"=> "text/plain");
	$req->header("Referer"=> "http://www.neimanmarcus.com/en-us/index.jsp");
	$req->header("Host"=> "www.neimanmarcus.com");
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
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(30);
			goto Home;
		}
	}
	return $content;
}

sub get_content_status
{
        my $url = shift;
        my $rerun_count=0;
        Home:
        $url =~ s/^\s+|\s+$//g;
        $url =~ s/amp\;//g;
        my $req = HTTP::Request->new(GET=>"$url");
        $req->header("Content-Type"=> "text/plain");
        my $res = $ua->request($req);
        $cookie->extract_cookies($res);
        $cookie->save;
        $cookie->add_cookie_header($req);
        my $code=$res->code;
        if($code =~m/20/is)
        {
         return $code;
        }
        else
        {
            if ( $rerun_count <= 1 )
           {
	 	$rerun_count++;
		goto Home;
	    }
        }
}

sub trim
{
	my $txt = shift;
	
	$txt=~s/\&\#151\;/-/igs;	
	$txt=~s/\&\#8539\;/1\/8/igs;	
	$txt=~s/\&\#153\;/™/igs;	
	$txt=~s/\&\#150\;/-/igs;	
	$txt=~s/\&\#190\;/¾/igs;	
	$txt=~s/\&\#189\;/½/igs;	
	$txt=~s/\&\#176\;/°/igs;	
	$txt=~s/\&\#232\;/è/igs;	
	$txt=~s/\&\#241\;/ñ/igs;
	
	return $txt;
}
