#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Bealls_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use String::Random;
use URI::Escape;
use DBI;
use DateTime;

# require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Bealls_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	$robotname='Bealls-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Bea';
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
		my $content2 = &getcont($url3);
		my @a=('Zoo York','Zion Rootswear','Zenana','Zak Designs','Zac & Rachel','Youngland','Young Hearts','Ymi','Yankee Candle','Y\'all\'s','Xoxo','Xcell','Wurl','Workman Publishing','Wonderwink','Windham Weavers','Windham Pointe','Windham Lightweights','Wind & Willow','Wilton','Willowbrook','White Sierra','Wembley','Weekender','Wearfirst','Wearabouts','Water Sports, Llc','Warner\'s','Wallflower','Walking Dead','Volcom','Vintage America','Vince Camuto','Vicky Tiel','Versace','Vera','Varsity','Vans','Vanity Fair','Vanilla Star','Van Heusen','Van Cleef','Usher','Us Polo','Unionbay','Under Tech','Ubu','Tyte','Ty','Tsi','True Religion','Tropix Ultra','Tropix','Triple C','Trimshaper','Trifari','Tri-Coastal','Treska','Tresics','Travelers Club','Travalo','Tramp','Totes','Tortuga','Toni Morgan','Tommy Hilfiger','Tommy Bahama','Toast Master','Tiana B','Ti Designs','Thunder Cats','Thrill','Three Hearts','Thomson Pottery','Thomas The Train','Thomas & Friends','Thirstystone','The Touch Of Nina','The Sharper Image','The Sak','The Peanut Shop','The Ny Yankees','The Beatles','The Avengers','Teva','Tervis','Telic','Teez-Her','Team Sports America','Team Beans','Team','Tea Of Life','Tabletops Unlimited Inc.','Table Trends','Swarovski','Suzy Toronto','Surf Up','Supplies By Union Bay','Superman','Superblox','Sunshine Baby','Sunsets','Sunkissed','Sunflower','Sunbeam','Sunbay','Sun N\' Sand','Sun Kidz','Style & Home','Studio West','Studio I','Strivectin','Stone & Co.','Stockdale','Starfrit Gourmet','Star Wars','Stainless Steel','Stagg','Sta','St. Tropez','St. Eve','Springs Home','Spring Step','Spongebob Squarepants','Spoiled','Splash Home','Splash Fun','Spider-Man','Sperry','Spense','Speedo','Speechless','Spanx','Southern Tide','South Point','Sons Of Anarchy','Sola Vive','Sol Republic','Soho','Soffe','Sodastream','Snooki Couture','Snapware','Smart Planet','Skylander','Skyes The Limit','Skinny Mixes','Skechers','Simply Swim','Simple Pleasures','Silver Forest','Signature','Siena Studio','Shift3','Shark','Shannon Miller','Shakira','Shakespeare','Seven 7','Sesame Street','Sellers Publishing','Self Esteem','Sebago','Seaside Treasures','Scrubs','Scott David','Scooby-Doo!','Scene Weaver','Sbicca','Say What?','Savvy','Savane','Sarong Clips','Sara Michelle','Sangria','Sandra Darren','San Pacific','San Miguel','Sam & Libby','Salt Life','Ryka','Rusty','Russell Athletics','Runway Girl','Rude Boyz','Royalty By Ymi','Royalty','Royal Copenhagen','Roxy','Rothschild','Rosetti','Ronni Nicole','Roman','Rockport','Rocket Dog','Rochas','Rival','Ritz','Ripple Junction','Rip Curl','Rio','Rihanna','Rider','Rialto','Rewind','Revlon','Relic','Regular Show','Reeses','Reel Legends','Reebok','Realm','Rare Editions','Rampage','Ralph Lauren','Rafaella','Rachel','Rabbit Rabbit','R & M Richards','R & K','Quiksilver','Pyrex','Pursuit','Pure 100','Puma','Puig','Promise Me','Progressive','Profilo','Prodyne','Proctor Silex','Prinz','Princess Faith','Primitives By Kathy','Presto','Pressbox','Power Rangers','Poof Slinky','Poof','Pomeroy','Polaroid','Plushland','Plush Pals','Playtex','Planet Gold','Pink Platinum','Pink & Pepper','Pictura','Picnic Plus','Pga Tour','Pfaltzgraff','Perry Ellis','Perfumers','Perceptions','Penelope Mack','Pelican Bay Ltd','Pelagic','Peds','Pearls','Peachy','Peaceful Shores','Peaceful Dreams','Paul Sebastian','Patrizia','Park B. Smith','Paris Hilton','Paradise Shores','Paradise Bay','Paper Doll','Panama Jack','Palmland','Palm Island Home','Palm Island','Pacific Beach','Oxo','Ovb','Ovation','Outlooks','Other','Oster','Oshkosh B\'gosh','Oscar De La Renta','Orthaheel','Original Gourmet','Onque','Only Nine','Oneworld','O\'neill','Oneida','One Step Up','On The Verge','Olympia Luggage','Olga','Oleg Cassini','Olde Thompson','Old Guys Rule','Ocean Dream','Ocean Current','Ocean Avenue','Ny Collection','Nunn Bush','Nue Options','Now Designs','Nourison','Notations','Nostalgia Electric','Nosox','None','No Fear','Nintendo','Ninja Turtles','Ninja','Nine West','Nina Ricci','Nicole Polizza','Nickelodeon','Nick Jr','Next','New View','New Balance','Neff','Nautica','Naturalizer','Natasha','Napier','Naomi & Nicole','Nannette','Myrurgia','My U','My Little Pony','Mundi','Multisac','Mr. Saturday Night','Mr. Coffee','Mr. Bbq','Mountain Dew','Moschino','Mootsies Tootsies','Mont Blanc','Monster Jam','Monster High','Mohawk','Modern Living','Moda Design','Moa Moa','Misto','Miss Chievous','Minecraft','Mimosa','Mikasa','Mick Mack','Michael Kors','Michael Jordan','Mia','M-Fasis','Merrell Footwear','Melannco','Mega Bloks','Maytex','Maxine Of Hollywood','Mattel','Marvel','Margaritaville','Marc Ecko Cut & Sew','Marc Ecko','Malibu Dream Girls','Malden','Majestic','Maison Royale','Maidenform','Magnolia Lane','Magic Bullet','Madison Park','Madden Girl','Machine','M. Haskell','Luxology','Luminarc','Ls Arts','Love, Fire','Loungees','Longitude','London Times','London Fog','Lollipop','Lolita Lempicka','Lolita','Logo Chair','Logo Athletic','Liz Claiborne New York','Living Doll L.A.','Little Rebels','Little Lass','Lissome','Linea Donatella','Lindt','Lilyette','Lily White','Lily Of France','Lily Bloom','Lifestyle Studios','Lifestride','Libbey','Levis','Leoma Lovegrove','Lennie','Lego','Legend 67','Lee','Laura Ashley','Larry Levine','Laid Back','Laguna','Lacoste','La Gear','Kyle & Deena','K-Swiss','Kraftware','Koltov','Knock Knock','Klip It','Kitchenaid','Kitchen Selective','Kitchen & Home','Kim Kardashian','Kikkerland','Keurig','Kensie','Kenneth Cole Reaction','Kemp & Beatley','Keds','Kay Dee Designs','Kathy Van Zeeland','Kathryn','Karl Lagerfeld','Karen Neuburger','Kamenstein','Kalorik','Justin Bieber','Justice League','Jou Jou','Joop','Jones New York Sport','Joe Benbasset','Jodhpuri','Jockey For Her','Jockey','Jesus Del Pozo','Jessica Simpson','Jessica Mcclintock','Jem','Jellypop','Jelli Fish Inc.','Jean Paul Gaultier','Jay Imports','Jasmine Rose','Jantzen','Jansport','James Bond','Jake & Neverland Pirates','Jag','Jaclyn Intimates','J. Lo','J. America','Izod','Izaro','Ixtreme','Italian Shoemakers','It Luggage','Issey Miyake','Isotoner','Island Surf','Iron Man','International Silver','Interdesign','Ink Inc','Ink Bone','Ing','Infini','Indigo Rein','Incredible Hulk','In Gear','Impo','Ilive','Ihome','Ihip','Igloo','Hybrid','Hurley','Hunter','Hugo Boss','Hue','Hot Wheels','Hot Water','Hot Kiss','Hot Cotton','Homedics','Home Essentials','Hollywood Fashion Secrets','Hollander Basics','Hercules','Hello Kitty','Hearts Of Palm','Harve Benard','Hanes','Hamilton Beach','Halston','Halo','Halcyon','Haggar','Guy Laroche','Guy Harvey','Gund','Guess','Gucci','Grill Pro','Great American Products','Grasshoppers','Grant Howard','Gold Toe','Godiva','Godinger','Gloria Vanderbilt Sport','Gloria Vanderbilt','Glasslock','Givenchy','Giorgio Of Beverly Hills','Gibson','Gianni Versace','Ghirardelli','George Foreman','George & Martha','Genuine Wrangler','Gemstones','Gator Boys','Ganz','Gameday Boots','Gama Go','Gale Hayman','G3','Funky Socks','Fsu','Fresh Brewed','French Toast','French Shriner','French Laundry','Freestyle','Freeman','Free Society','Free Bird','Fred','Franco Sarto','Fox','Forever Collectibles','Ford','Footnotes','Florsheim','Florida Marketplace','Florida','Flexees','Fisher-Price','First Time','Fire Agate','Fine Silver Plate','Fine Gold Plate','Figueroa And Flower','Fiesta','Ferrari','Fergalicious','Felli','Feathered Friends','Fast & Furious','Farberware','Fancy That','F.S.I','F.A.N.G','Eyeshadow','Eye Candy','Excell Home Fashions','Evergreen','Evan Picone','Esteé Lauder','Escada','Erika','Empower','Emma & Michelle','Emerald','Ellison First Asia','Ellen Tracy','Elizabeth Taylor','Elizabeth Arden','Elf On The Shelf','Elegant Baby','El Paso','Ed Hardy','Ecko','Easy Street','Easy Spirit','Eastland','Earl Jean','Duck Dynasty','Dr. Scholl\'s','Dora The Explorer','Donna Karan','Dolly Mama','Dollie & Me','Dolce & Gabbana','Dockers','D\'margeaux','Dkny Jeans','Distortion','Disorderly Kids','Disney','Discovery Kids','Dickies Girl','Devgiri','Despicable Me 2','Despicable Me','Derek Heart','Dennis East','Democracy','Deer Stags','Dearfoams','Dc Shoes','Davidoff','D. Jeans','Cutie Pie Baby','Currants','Cuisine De France','Cuisinart','Cuddle Sox','Cuddl Duds','Cubavera','Crystal Vogue','Crocs','Crock-Pot','Creative Bath','Cradle Soft','Counterparts','Counter Art','Corrine Mccormick','Corningware','Core Home','Coral Bay Leisure','Coral Bay','Cool Girl','Cool Gear','Converse','Contesa','Connected Apparel','Concepts Nyc','Conair','Columbia Sportswear','Columbia','Colony','Colombino','Collegiate Fashionista','College Concepts Inc','Collection 18','Cole Of California','Coke','Cocomo','Coastal Home','Coastal Cocktails','Club Attivo','Cloud 9','Clinique','Clay Art','Clarks','Claiborne','Cl By Laundry','City Scene','Circulon','Circleware','Cinder Block','Chloe','Chirp','Chicago Cutlery','Chaus','Champion','Cavendish & Harvey','Cathy Daniels','Cathay Home','Casual Living','Casabella','Carters','Carole','Carol Dauplaise','Carlos Santana','Carlos By Carlos Santana','Caribbean Joe','Captain America','Capelli Ny','Capelli','Cape Shore','Candy Coast','Candlesticks','Camp & Campus','Cambridge Silversmiths','Calvin Klein','Call Of Duty','Caesars','By Appointment','Bvlgari','Buxton','Burberry','Bueno','Bronte & Tallulah','Britney Spears','Brisas','Brighten The Season','Brew Pod','Brentwood','Breast Cancer','Breaking Bad','Bravado','Boston Warehouse','Boelter Brands','Body Candy','Boca Clips','Boca Classics','Bobino','Bob Marley','Bob Mackie','Blue Spice','Blue Sol','Blue Mountain Arts','Blue Hat','Blue Crab','Blue 84','Blu Pepper','Black Jack','Black & Decker','Bioworld','Billabong','Bijan','Big Bang Theory','Bia Cordon Bleu, Inc.','Betsey Johnson','Benson Mills','Benetton','Belle Du Jour','Bella','Bebe','Beautees','Beau','Beach Stop','Beach Stakes','Beach Diva','Be Bop','Bcbgeneration','Bay Studio','Batman','Basha','Barely There','Bare Traps','Bardwil Industries','Barbie','Bandolino','Bali','Bailey Blue','Bacova','Backyard Fun','Baccini','Baby Starters','Baby Gear','Baby Fanatic','Baby Essentials','B12','B.O.C.','B.L.E.U.','Azzaro','Avia','Avanti','Aussino','Aurora','Attivo','Asics','As U Wish','As Seen On T.V.','Artland','Armitron','Ariya','Aris By Treska','Aria','Arc','Aqua Couture','Appfinity','Anvil','Anne Klein','Anne Cole Signature','Annalee & Hope','Ann Marino','Angry Birds','Angie','Angel Beach','Anastasia','Amy Byer','American Tourister','American Flyer','American Dream','Almost Famous','Allison Brittney','Allie & Rob','Allergy Relief','Alia','Alfred Dunner','Agb','Aerosoles','Adventure Time','Adolfo','Adidas','A2 By Aerosoles','A. Byer','A Shore Fit','5th Sun','47 Brand','3-D Zone','1st Kiss');
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock,$colour,$item_no);
		# 40/50 Code Page
		if($content2 eq 1)
		{
			goto PNF;
		}
		# Name and Product id
		if ($content2 =~m/<h1[^>]*?>(?:<span[^>]*?>[^>]*?<\/span>)?\s*([^>]*?)<\/h1[^>]*?>(?:(?:\s*<[^>]*?>\s*)+[^>]*?id\:\s*([^>]*?)\s*<)?/is)
		{
			$product_name= &DBIL::Trim($1);
			$item_no=&DBIL::Trim($2);
			$product_id=$item_no;
			$product_name=decode_entities($product_name);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key, $dbh,$robotname, $retailer_id);
			goto end if($ckproduct_id == 1);
			undef ($ckproduct_id);
			
		}
		# Brand
		my $p_name=$product_name;
		chomp($p_name);
		$p_name=~s/^New\!\s*//igs;
		my $brand;
		my $na;
		if($p_name=~m/^([\w\W]*?)\s+[^>]*?$/is)
		{
			 $na=$1;
		}
		my @name=grep(/^\s*$na[^>]*?$/is,@a);
		foreach my $name(@name)
		{
			if($p_name=~m/(^$name)[^>]*?$/is)
			{
				$brand=$1;
			}
		}
		# Price
		if($content2=~m/offer\-price\">\s*(\W*(\d[^>]*?))\s*(?:\s*<[^>]*?>\s*)+(?:(reg\.\s*[^>]*?)\s*<)?/is)
		{
			$price_text= "Now $1"." Was "."$3";
			$price= &DBIL::Trim($2);
			$price_text=~s/\s*Was\s*$//is;
			if($price_text!~m/Was/is)
			{
				$price_text=~s/\s*Now\s*//is;
			}	
			my $c=$price;
			if($c=~m/\W*(\d+\.?\d*)\s*\-\s*\W*(\d+\.?\d*)/is)
			{
				my $v1=$1;
				my $v2=$2;
				if($v1<$v2)
				{
					$price=$v1;
					
				}
				else
				{
					$price=$v2;
				}
			}		
			$price_text=~s/\s*\-\s*$//is;
		}
		# Description
		if ($content2 =~ m/<meta\s*name\=\"description\"\s*content\=\"([^>]*?)\s*\"/is)
		{
			$description = &DBIL::Trim($1);			
		}
		# Product Detail
		if ($content2 =~ m/<div\s*id\=\"detail\"[^>]*?>(?:\s*<[^>]*?>\s*)+([^>]*?)\s*</is)
		{
			$prod_detail = &DBIL::Trim($1);
			
		}
		$price="null" if($price eq '.' or $price eq ' ' or $price eq ',' or $price eq '');
		# size & out_of_stock
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		my $count=1;
		if($content2=~m/Color\"\:\[\"([^>]*?)\"]\,\"Size\"\:\[null\]/is) ### Size Null ######
		{
			my $colour=$1;
			my $out_of_stock='';
			my $size='One Size';
			my $colour1=$colour;
			$colour=&ProperCase($colour);
			$colour=~s/\-(\w)/-\u\L$1/is;
			sub ProperCase {
				join(' ',map{ucfirst(lc("$_"))}split(/\s/,$_[0]));
			}
			if($price eq "")
			{
				$out_of_stock='y';
			}
			else			
			{
				$out_of_stock='n';
			}
			if($content2=~m/add\-area\">\s*This\s*product\s*is\s*not\s*available\s*for\s*purchase/is)  #### Price Null ####
			{
				$price='null';
				$price_text='null';
			}	
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}=$colour1;
			$count++;
			push(@query_string,$query);
		}
		if($count == 1)
		{
			$count=1;
			while($content2=~m/Color\"\:(?:\")?([^>]*?)(?:\")?\,\"Size\"\:\"([^>]*?)\"(?:\,\"[^>]*?price\"\:\"([^>]*?)\")?/igs)  #### Colour & Size available #####
			{
				my $size=$2;
				my $colour1=$1;
				my $pric=$3;
				if($pric ne '')
				{
					$price=$pric;						######## Price varies depends on Size #######
					$price=~s/^\W//is;
				}
				my $out_of_stock='n';
				if($colour1=~m/Color\"\:\"([^>]*?)$/is)
				{
					$colour1=$1;
				}	
				my $color;
				if($colour1 eq 'null')
				{
					$colour='';
				}
				else
				{
					$colour=$colour1;
				}
				$colour=&ProperCase($colour);
				$colour=~s/\-(\w)/-\u\L$1/is;
				sub ProperCase {
					join(' ',map{ucfirst(lc("$_"))}split(/\s/,$_[0]));
				}
				if($content2=~m/add\-area\">\s*This\s*product\s*is\s*not\s*available\s*for\s*purchase/is)	#### Price Null ####
				{
					$price='null';
					$price_text='null';
				}
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}=$colour1;
				$count++;
				push(@query_string,$query);
			}
		}
		if($count == 1) #### Colour & Size Null ####
		{
			my $size='One Size';
			my $colour='No raw color';
			my $out_of_stock='';
			if($content2=~m/add\-area\">\s*This\s*product\s*is\s*not\s*available\s*for\s*purchase/is)
			{
				$price='null';
				$out_of_stock='y';
			}
			else
			{
				$out_of_stock='n';
			}
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$colour,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}='null';
			push(@query_string,$query);
		}
		
		# Image
		my %hash;
		while($content2=~m/ipsId\"\:\"(\d[^>]*?)\"[^<]*?Color\"\s*\:\s*(?:\[)?(?:\")?([^>]*?)(?:\]\,)?\"/igs)
		{
			$hash{$1}=$2;
		}
		foreach (keys %hash)
		{
			my $i=$_;
			my $yn;
			my $main_image="http://s7d5.scene7.com/is/image/Bealls/$i".'-yyy?$';					###### Default Image #####
			my $swatch_image="http://s7d5.scene7.com/is/image/Bealls/$i".'-yyy?$'.'swatch$';		###### Swatch Image #####
			my $alt_image="http://s7d5.scene7.com/is/image/Bealls/$i".'-200?$';						###### Alternate Image #####
			my $alt_image1="http://s7d5.scene7.com/is/image/Bealls/$i".'-500?$';					###### Alternate Image #####
			my ($imgid,$img_file) = &DBIL::ImageDownload($main_image,'product','bealls-us');
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$main_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}="$hash{$i}";
			$hash_default_image{$img_object}='y';
			push(@query_string,$query);
			my ($imgid,$img_file) = &DBIL::ImageDownload($swatch_image,'swatch','bealls-us');
			my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$swatch_image,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			$imageflag = 1 if($flag);
			$image_objectkey{$img_object}="$hash{$i}";
			$hash_default_image{$img_object}='n';
			push(@query_string,$query);
			######## Checking Image file Size to avoid incorrect Image url #############
			my $alt_check = getcont($alt_image);
			open(F, ">/opt/home/merit/Merit_Robots/alt.html");
			print F $alt_check;
			close F;
			my $ch=-s "/opt/home/merit/Merit_Robots/alt.html";   ##### File Size ######
			if($ch>2000)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image,'product','bealls-us');
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}="$hash{$i}";
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
			unlink("/opt/home/merit/Merit_Robots/alt.html");    ####### Removal of image file #######
			
			my $alt_check = getcont($alt_image1);
			open(F, ">/opt/home/merit/Merit_Robots/alt.html");
			print F $alt_check;
			close F;
			my $ch=-s "/opt/home/merit/Merit_Robots/alt.html";
			if($ch>2000)
			{
				my ($imgid,$img_file) = &DBIL::ImageDownload($alt_image1,'product','bealls-us');
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alt_image1,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}="$hash{$i}";
				$hash_default_image{$img_object}='n';
				push(@query_string,$query);
			}
			unlink("/opt/home/merit/Merit_Robots/alt.html");
			###############################################
		}	
		#### Sku_has_Image #########
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
}1;

sub getcont()
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
		$content = $res->content;
		return($content);
	}
	elsif($code =~m/40/is)
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(2);
			goto Home;
		}
		return 1;
	}
	else
	{
		if ( $rerun_count <= 3 )
		{
			$rerun_count++;
			sleep(2);
			goto Home;
		}
		return 1;
	}
}
