#!/opt/home/merit/perl5/perlbrew/perls/perl-5.14.4/bin/perl
###### Module Initialization ##############
package Target_US;
use strict;
use LWP::UserAgent;
use HTML::Entities;
use URI::URL;
use HTTP::Cookies;
use DBI;
# use utf8;
#require "/opt/home/merit/Merit_Robots/DBILv2/DBIL.pm";
require "/opt/home/merit/Merit_Robots/DBILv3/DBIL.pm";
###########################################
my ($retailer_name,$robotname_detail,$robotname_list,$Retailer_Random_String,$pid,$ip,$excuetionid,$country,$ua,$cookie_file,$retailer_file,$cookie);
sub Target_US_DetailProcess()
{
	my $product_object_key=shift;
	my $url=shift;
	my $dbh=shift;
	my $robotname=shift;
	my $retailer_id=shift;
	# $dbh->do("set character set utf8");
	# $dbh->do("set names utf8");
	my @query_string;
	$robotname='Target-US--Detail';
	####Variable Initialization##############
	$robotname =~ s/\.pl//igs;
	$robotname =$1 if($robotname =~ m/[^>]*?\/*([^\/]+?)\s*$/is);
	$retailer_name=$robotname;
	$robotname_detail=$robotname;
	$robotname_list=$robotname;
	$robotname_list =~ s/\-\-Detail/--List/igs;
	$retailer_name =~ s/\-\-Detail\s*$//igs;
	$retailer_name = lc($retailer_name);
	$Retailer_Random_String='Tar';
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
	if($product_object_key)
	{
		my $skuflag = 0;
		my $imageflag = 0;
		my $mflag=0;	
		my $url3=$url;		
		$url3 =~ s/^\s+|\s+$//g;
		$product_object_key =~ s/^\s+|\s+$//g;
		my $content2 = &GetContent($url3);
		# $content2=decode_entities($content2);
		my %tag_hash;
		my %color_hash;
		my %prod_objkey;
		my %size_hash;
		my ($price,$price_text,$brand,$sub_category,$product_id,$product_name,$description,$main_image,$prod_detail,$alt_image,$out_of_stock);
		my (%sku_objectkey,%image_objectkey,%hash_default_image,@colorsid,@image_object_key,@sku_object_key);
		my @brands=("ZZZquil","ZYRTEC","ZYMOL","Zyliss","Zydus Rx","Zutano Blue","Zulka","ZOSTRIX","Zoomerang","Zoob","Zoo Games","ZONE PERFECT","ZOJIRUSHI","Zoic","ZOBMONDO","Z-LINE","Zirh Int'l","Zirh","Zirconite","ZIPLOC","Zino Davidoff","Zing","Zillionz","ZEVRO","ZESTRA","ZEST","Zero Water","Zero Odor","Zenzation Athletics","ZENO","Zenga","ZEIGLER'S","ZEGERID","Zebra","ZATARAIN'S","Zarbee's","ZANTREX","ZANTAC","ZAK","ZAGG","Zadro","ZADITOR","Y-Volution","Yves Saint Laurent","Yurbuds","YUCATECO","Yu Shan","YouCopia","York","Yoplait","Yonanas","Yogitoes","YOGI","Yoga Sprout","YOCRUNCH","Yo Gabba Gabba","Yes To","YES","YELLOW TAIL","YBIKE","YARD-MAN","Yard Machines","YANKEE CANDLE","YAMAHA","YAKULT","Yakima","YAHTZEE","Xyron","XTRA","Xtend & Climb","Xscape","Xploderz","Xolo","XL-3","Xhilaration","Xerox","XENEDRINE","X-Doria","XBox 360","XBOX","X GAMES","X Factor Sports","Wylers","WWE","Write Dudes","Wrigley 5","WRIGLEY","Wrap-It","WRANGLER","WOW WEE ROBOTICS","WOW","WORX","WORTH","World's Best","World Tour","World Factory","WORKMAN","Wordlock","WOOLITE","WOODWARD'S","Woodstream Corporati","Woodstock Percussion","Woodstock","WOODS","WOODFORD RESERVE","WOODCHUCK","WOODBRIDGE","WONKA","Wonderworld","Wonderful","Wonder Forge","Wonder Bumpers","WONDER","WOLFGANG PUCK","WOLF","Wisk","WISH-BONE","Wipe New","WINX","Winsome","WINNING MOVES","Winix","WINGS","Winfun","WINE CUBE","WINDEX","WILTON","Wilson Sporting Good","WILSON JONES","WILSON","Wildlife Creations","WildKin","WILD PLANET","Wild","Wii","WIDMER","Whynter","WHOPPERS","Whoomp!","Wholly Guacamole","WHOLESOME","WHITMOR","Whitewood Industries","Whitehall Products","WHITE CASTLE","WHIRLPOOL","Wheres Waldo","WHEAT THINS","WHAM-O","Whalen","We-Vibe","WET ONES","WET N WILD","Wet","Westwood Design","Weston","WESTINGHOUSE","WESTERN DIGITAL","WESTERN","WESTCOTT","WESTBRAE","WEST BEND","WESSON","WERTHER'S ORIGINAL","Werner","Wenzel","Wendys","Wendy Bellissimo","Wellhaven","WELLESSE","WELEDA","Welcome Home Brands","WELCH'S","WEIMAN","Weight Watchers","WEIDER","WeeRide","Wee Squeak","Webkinz","WEBER'S","WEBER","WEAREVER","We R Memory Keepers","WBM","Way Basics","Wavenforcer","WAUSAU PAPER","WATKINS","WaterWipes","Waterpik","Water Warriors","Warners","Warner Music Group","Warner Home Video","Warner Brothers","Warner Bros.","WARNER","WARHEADS","Warehouse Of Tiffany","WALLIES","Wallcandy","Wall Friends","Walking Wings","WALKERS","WALKER EDISON FURNIT","WALK FIT","Wahl","WAGNER","WAGAN","WACA","WABASH VALLEY FARMS","VuPoint Solutions","Vulli","V-TECH","VTech","VPX","Vornado","Voots","VOIT","VM DNU","VM","VLASIC","Vizio","VIVITAR","Viviscal","Viva Media","VIVA","Vitol","VitaRocks","Vitamix","Vitaminpaste","VITAMIN WATER","VITAMIN","VITAFUSION","Vitacoco Kids","Vitaclay","Visual Land","Visconti Di Modrone","ViscoFresh","VIRGIN MOBILE","Viper","Violent Lips","Violent Eyes","Vinturi","Vintage","Vinci","Vince Camuto","Village Naturals","VILLAGE","VILEDA","VIGO","Vifah","VIDAL SASSOON","Victory Int'l Group","Victorinox","VICTOR","Vicky Tiel","VICKS NYQUIL/DYQUIL","VICKS","Vickerman","Vichy","VIBE","Versace","VERIZON","Veridian Healthcare","Verde","VeraTemp","Vera Wang","Vera","Venus Embrace","Venus & Olay","VENUS","Venturer","VENOM","VENDANGE","VELVEETA","VEET","Vaultz","VASSARETTE","VASELINE","VARIFLEX","Variety Pet Foods","Vapur","VANS","VANITY FAIR","Vanicream","VANGUARD","Vanderbilt","VAN DE KAMPS","Van Cleef & Arpels","Van Cleef","VAN CAMP'S","VALUSOFT","VALLEY FRESH","Valentino","VAGISIL","Vacmaster","V8","UTZ","UTILITY","Usher","USAopoly","USADawgs","USA Network","Urinozinc","Urbanears","Urban Shop","Urban Republic","Urban Hydration","Urban","Upspring Baby","Upsher Smith RX","UPPER DECK","up&up","up & up","Unvrsl Remote Contrl","UnReal Brands","UNO","UNIVERSITY GAMES","UNIVERSAL Studios","Universal Studio","Universal Music","Universal Home Video","UNISOM","Unique Industries","Union","Uniek","UNIDEN","UNIBALL","UNGER","Ungaro","Underground Toys","Uncommon","Uncle Milton","UNCLE BEN'S","UMVD","UMEYA","Umbra Loft","UMBRA","Umberto","Ulubulu","Ultra Hardware","ULTRA BRITE","Ultimate Nutrition","Ultima II","ULTIMA","UFO","Uchida","UBISOFT","U.S. Brown Bear","U.S Traveler","Tyson","TYLENOL","Twooth","TWIX","TWISTER","Twisted Sista","TWINLAB","TWININGS","Twelve Timbers","TWEEZERMAN","TV GAMES","TURTLES","TURTLE WAX","Turtle Beach","TURKEY HILL","TUMS","TULLAMORE DEW","Tudor Games","T-Tech by Tumi","TT Toys Toys","Tsukineko","TRY ME","TRUVIA","TruMoo","TruEnergy","True White","True Religion","True Fidelity","TRUDEAU","Tropicana","TROJAN","TRIX","TRIVIAL PURSUIT","Triumph Sports","Triton","TRISTAR","TRISCUIT","TRIPLE PASTE","Trion Worlds","Trimmer","TRIM","Trillium","Trikke","Trident","TRIAMINIC","TRESEMME","Trend Lab","TREND","TreeKeeper","Tree Hut","Trax","TravelOn","TRAVELERS CLUB","Traveler's Choice","Travel Time","Travel Smart","Travel Chair","TRAVALO","TRASH PACK","TRANSFORMERS","TransDermal","TRAMONTINA","TRALY","Trailmaker","Traditional Medicina","Trademark Poker","Trademark Global","Trade Winds Tea","TRACKPACK","TRACFONE","Toysmith","TOY STORY","Tovolo","Totino's","Totes","Totally Bamboo","Total Gym","Total Chef","TOTAL","Tot Tutors","TOSTITOS","TOSHIBA","Tortle","Torre & Tagus","TORO","TOPS","Topricin","TOPO CHICO","Top Secret Nutrition","Top Innovations","TOP FLITE","TOP FLIGHT","TOOTSIE ROLL","Tootsie Pop","TOOTSIE","Tool Logic","TOO by Blu Dot","TONY'S","Tony Hawk","TONKA","TONI&GUY","TONE","TOMY","TOMTOM","TOM'S OF MAINE","TOMMY HILFIGER","TOMMY","Tommee Tippee","TOMCAT","TOMBSTONE","Tombow","Tolly Tots","Toilet Duck","Toddy","TOCA","TOBLERONE","Toastess Internation","TOASTED HEAD","TNT","T-MOBILE","TL CareDNU","TL Care","Titos","TITLEIST","Titan","Tio Nacho","TINY LOVE","TIMEX","TIME TO PLAY","Tim McGraw","Tim Holtz","TILLAMOOK","TILEX","Tike Tech","TIGI Bed Head","TIGI","TIGER'S MILK","Tiger Balm","TIGER","TIDY CATS","TIDE","TIDDLIWINKS","Ticonderoga","TIC TAC","Thundershirt","ThunderCats","Thrustmaster","Threshold","Three Lollies","Three Hands","THREE DOG BAKERY","Three Bridges","THREE","THQ","THOMASVILLE","THOMAS TANK ENGINE","THOMAS O'BRIEN","Thomas & Friends","THOMAS","Thirstystone","Thirsties","thinkThin","Thinksport","ThinkFun","Thinkbaby","THIERRY MUGLER","THERMOS","THERMIPAQ","THERMA CARE","Therasteps","Therapure","TheraPearl","THERABREATH","Theo Klein","Thentix","The Wine Enthusiast","The Webster Miami","The Weather Channel","The Ultimate Rose","The Ugglys","The Singing Machine","The Shed","THE OUTDOOR RECREATI","The Neat Company","THE MEMORY COMPANY","The Happys","The Gerson Company","THE GAME OF LIFE","THE FIRST YEARS","The Firm","The Doors","The Doctor's","THE Collection","The Bumble Collectio","The Bug Patch","THE BOSS","The Bathery","THAMES & KOSMOS","THAI KITCHEN","T-FAL","TexStyle/Whisper Sof","TEXAS TOAST","Texas Roadhouse","TEXAS INSTRUMENTS","Tevolio","TETRA","TETLEY","Tervis","TERRO","Terra Decor","TERRA by Battat","Tend Skin","Ten Strawberry Stree","Telesteps","Telebrands","TEK NEK","Tegu","Teeter Hang Ups","Teenage Mutant Ninja Turtles","Teeboo USA","TEDDY GRAHAMS","Ted Lapidus","Technocel","TECH GROUP","TECH DECK","TECATE","TEARS NATURALE","Teamson","TAZO","TAYLORMADE","Taylor Swift","TAYLOR FARMS","Taylor","Tatco","TASTE OF THAI","TASSIMO","TARN X","TarHong","TARGUS","Target Brand","Tango Home","Tangle Teezer","Tanda","TAMPAX","Takeya","Takealongs","TAKE TWO INTERACTIVE","TAKARA","Taggies","TAGAMET HB","Tag Along Teddy","Tadpoles","Tablet Pals","Tab","T.G.I. FRIDAY'S","SYSTANE","Symantec","Sylvia Alexander","SYLVANIA","Swissmar","SWISS MISS","SWISS GEAR","Swiss Army","SWISS","Swing-N-Slide","SWINGLINE","SWIMWAYS","SWIFFER","SWHEAT SCOOP","SweeTARTS","Sweet Slippers","SWEET N LOW","SWEET LEAF","Sweet JoJo Designs","Sweet Earth","Swedish Fish","Sweaty Bands","SwaddleDesigns","SVENHARDS","SVEDKA","Suzano Report","SUTTER HOME","Survivor","Surf","Sure Fit","SURE","Supreme Protein","SUPRA","SuperSoaker","SUPERPRETZEL","SuperMat","SUPERMAN","SUPERIOR","SUPER C","Super Bright","SUNSWEET","Sunshine Loom","Sunpentown","Sunology","SUN-MAID","SUNKIST","Sunjoy","Sungale","Sunergy","SUNDOWN","Sundial","SUNCHIPS","SUNCAST","SUNBIRD","SUNBEAM","Sun Zero","Sun","Sumner Street","Summit Products","Summit Entertainment","SUMMIT","Summer's Eve","SUMMERS EVE","SUMMER INFANT","Summer Escapes","SUMMER","Sumersault","Sumdex","Suisse Sport","SUGAR IN THE RAW","SUDAFED","SUCCESS","Succes De Paris","SUAVITEL","SUAVE","Styles","Stuhrling Original","Stuffies","Studio Basics","Studio Arts","STUDIO","STUBB'S","STROEHMANN","Striiv","Strider","Stride","Street Surfing","STRAWBERRY SHORTCAKE","STP","STOVE TOP","Stouffers","Stott Pilates","StorkCraft","StoreBound","Storck USA","STONYFIELD FARM","Stonegate","Stokke LLC","Stok","Stiles","Stiga","Stick-N-Find","STEWARTS","Stevens Baby BoomDNU","Steven Raichlen","Steve Jackson Games","STETSON","STERLING VINTNERS","STERLING","Steripod","STERILITE","Steren","Stephan Baby","STEP2","Step 2","Step","Stella Artois","STELLA","SteelMaster","STEARNS","SteamFast","STEAK-UMM","STAYFREE","STATIC GUARD","State Fair","STARLITE CREATIONS","STARKIST","Starburst","Starbucks GC","Starbucks","STAR WARS","Star Trek","STAR","STANSPORT","Stanley Bostitch","STANLEY","Stamina","Staedtler","Stadler Form","Stacys","St. Ives","ST PAULI GIRL","SSS TONIC","Srixon","Squish","SQUIRT","Square Enix","Square","SpyNet","Spy Gear","SPY","Spritz","Sprint","SPRI","Spraywhite 90","SPRAYWAY","Spotty","Spotify","SPOT SHOT","Sporting Dog Solutio","SPORTIN WAVES","SPORT SUPPLY GROUP,","SPORT PET","Spongex","SPONGE BOB","SPLENDA","Splat","SPLASH","SPIROGRAPH","SPINMASTER","Spinbrush","SPIDERMAN","SPICE WORLD","SpermCheck","Spellbinders","SPEEDSTICK","SPEEDO","SPECTRUM","SPECTRA","Speck Products","Speck","Specific Beauty","Special K","SPARKLE","Spangler","SPAM","SPALDING","SPACE BAG","Spa Sonic","Spa Master","SOY JOY","Southworth","Southwest Airlines","Southern Enterprises","SOUTHERN COMFORT","SOUTH SHORE","SOUR PATCH","Soundfreq","SOUNDFREAQ","Sound Oasis","Sorrento","Sorelle","SootheTime","Sony Pictures Home E","Sony Pictures","Sony Music","SONY","Sonos","SONOMA CUTRER","SONOMA","Sonix City","SONICARE","Sonic","Sonia Kashuk Luxe","Sonia Kashuk Limited Edition","Sonia Kashuk","Someecards","Solutions 2 Go","Solofill","SOLO","SOLARCAINE","Sol Republic","SOL","Soiree","SOHO","SOG","SOFTSOAP","SoftOnes","SOFTLIPS","SoftHeat","SOFT SCRUB","Soft & Beautiful","Sodastream","Social Gallery Roman","Social Gallery by Roman","SNYDERS","Snuggle Buds","Snuggle","SNOW'S","Snow River","SNICKERS","Sneaky Chef","Snark","SNAPWARE","SNAPPLE","Snap It","Snap Circuits","SNAP","SNACKWELLS","SNACK PACK","Smurfs","Smucker's","Smooth Shine Polish","SMOKING LOON","Smithsonian","Smith's","Smith & Hawken","Smith & Forge","SMIRNOFF","Smile Squared","Smead","SMARTYKAT","SmartTemp","SmartMax","SMARTIES","Smart Trike","Smart Toys","SMART SOLAR","Smart Shave","Smart Ones","Smart Lab Toys","Smart Gear","Smart for life","Smart Choice","SMART BALANCE","SMART","SMALL WORLD","SMACKERS","SlumberCare","Slinky","SLIM-FAST","Slime","SLIM JIM","SlickSugar","Slendertone","Sleepright","Sleeping Partners","Sleep Right","SLEEP MD","Sleep Innovations","SLEEK LOOK","Sleek","Slavia Zaitsev","SKYY","Skywalker Trampoline","Skype","SKYLINE IMPORTS","Skyline Furniture","Skyline","Skullduggery","SKULLCANDY","SKLZ","Skittles","SKIP HOP","Skinnygirl","SKINNY COW","SKINNER","Skin Wear","Skidders","Skechers","Sizzix","Sixtrees","SIRANCHA","Sinupulse","SinuCleanse","SINGING MACHINE","SINGER","SIMPSONS","Simply Shabby Chic","Simply Put","Simply Perfect by Warner's","SIMPLY ORGANIC","Simply Balanced","SIMPLY ASIA","Simply","SIMPLEHUMAN","Simple Wishes","Simple","Simoniz","Simmons Kids","SIMMONS","SIMILAC","Simbi","Silvertone","Silver Hills Bakery","Silpat","Silly String","Silk'n SensEpil","Silk'n","SILK","Silipos","Silent Snooz","SIERRA NEVADA","Sierra Mist","Sienna International","SIDRAL","Sia Botanics","Shrunks","SHOUT","SHOP VAC","Shock Top","SHINER BOCK","Shin Crest","SHERPA PET","Shermag","ShelterLogic","ShedRain","SHEBA","SheaMoisture","Shea Radiance","SHEA MOISTURE","She","SHAUN WHITE SHOES","SHAUN WHITE","SHARPS","SHARPIE","SHARP","Sharkskinzz","SHARK","Shakespeare","SHAKE N BAKE","Shades of Glass","Sexy Hair","SEXY","Sevylor","Seville Classics","SEVENTH GENERATION","Seventeen","Seven Spoons","SESAME STREET","Serta","SERGEANT'S","Serec Entertainment","Sephra","SentrySafe","SENTRY","SENSOR","SENSODYNE","SENSITIVE EYES","SENSIO","Sensible Portions","Sensible Lines","SensatioNail","Sensa","SENORIAL","SENNHEISER","Selsun Blue","Self-Esteem","Self Expressions by Maidenform","Self Expressions","SELF EXPRESSION","Selena Gomez","SELECTS","SelectOHits","Select Brands","SEI","SEGA","SECRET","SEBASTIAN","SebaMed","Seattles Best Coffee","Seasonal Specialties","Seasonal","SEASON","Sealy","Sealed Air","SEAGRAM'S","SEAGATE","SEA PAK","SEA CHOICE","SCUNCI","SCRUBBING BUBBLES","SCRIPTO","SCRABBLE","SCOTTS","Scott David","SCOTT","SCOTCHGARD","SCOTCH-BRITE","SCOTCH","SCOSCHE","SCOPE","SCOOP AWAY","SCOOBY DOO","SCIENTIFIC EXPLORER","SCHYLLING","SCHWINN","SCHWEPPES","SCHOLASTIC","Schoenhut","SCHIFF","Schick Hydro","Schick","Sceptre","Scent Portfolio","SCATTEGORIES","ScarAway","Scan 2 Go","Savinio Designs","Saunders","Sauder","SATIN CARE","Satellite","SASSY","SAS","Sartori","SARGENTO","SARAH JESSICA PARKER","SARA LEE","Sara Bear","SAPUTO","SAPPORO","SANUS","SANTA MARGHERITA","SANRIO","Sango","SANFORD","Sandpiper of Calif","Sandlock","SANDISK","Sanar","SAN J","SAN","SAMY","SAMUEL SMITH","SAMUEL ADAMS","SAMSUNG","Samson","Samick","SAMBAZON","Sam & Libby","Salvatore Ferragamo","Salvador Dali","SALTON","Salter Housewares","SALT SENSE","SALON GRAFIX","SALLY HANSEN","SAKAR","SAILOR JERRY","Sage Spoonfuls","Sagaform","SAGA","SAFETY 1ST","SafeToSleep","Safer Brand","SAFAVIEH","SAECO","SACO","Sachi","SABRA","Sabare","S. ROSEN'S","S&W","S SPORT BY SKECHERS","S CURL","Rx for Brown Skin","R-Way by ZeroXposur","RUSSELL STOVER","Russell Hobbs","RUSK","RuMe","Rum Chata","Rug Doctor","RUFFLES","RUFFIES","RUDI'S","Rubie's","Rubbermaid","RST Outdoor","RRG","ROYCE LIGHTING","Royall Fragrances","Royall","Royal Sovereign","Royal Heritage","Royal Doulton","Royal Copenhagen","Royal Brush","ROYAL","Roxio","ROWENTA","Rover","Round World Products","ROTHSCHILD","ROTEL","Rosetta Stone","ROSE'S","Rosenau","ROSE ART","ROSARITA","ROOMMATES","Roominate","Room Essentials","Room 365DNU","Room 365","Ronin Syndicate","Ronin","RONDELE","RONCO","Rompe Pecho","ROMAN","Rolodex","Rolo","Roller Derby","Rolf Glass","ROLD GOLD","Roku","Roger & Gallet","Rogar","ROGAINE","RODELLE","Rode","Rockstar Games","ROCKSTAR","Rockland","rockflowerpaper","ROCKABYE","Rochas","ROCAWEAR EVOLUTION","Rocawear","RoC Retinol Correxion","RoC","Roblox","ROBITUSSIN","ROBINSON","ROBERTS","Roberto Cavalli","Robert Piquet","ROBERT MONDAVI","Robert Allen H&G","Roaring Spring","ROAD RIPPERS","RMPS","Rivers Edge","RiverRidge","RIVAL","RIUNITE","RITZ","RITTER","Ritmo Pregnancy","RiteLite","RISK","Rising Moon Organics","RIO BRAND","RING POP","RIMMEL","Rihanna","Rightline Gear","RIGHT GUARD","RIEDEL","RID-X","Riddell","RID X","RID","RICOLA","Ricoh","RICHELL","RICHELIEU","Richards Homewares","RICE-A-RONI","RICE SELECT","RICE KRISPIES","Rhythm Band","Rhoost","RHODES","Rhino","REYNOLDS","REYNALDO'S","Reyka","Reyane","Revlon Top Speed","Revlon Photoready","Revlon Colorstay","Revlon Colorsilk Luminista","Revlon Colorsilk","Revlon Colorburst","REVLON","RevitaLens","REVERE","Reston Lloyd","RESOLVE","RESER'S","REPLENISH","REPHRESH","REPEL","RENUZIT","Renú","RENU","Remy Latour","Remo","REMINGTON","Rembrant","REMBRANDT","Reliance","Rejuvenation","REGINA","REGALO","Regal Lager","Regal Entertainment","Regal Elite","REFRESH","REEVES","Reese's","Reese Puffs","REESE","Reed and Barton","Reed","REEBOK","Redmon","Reddi-Wip","Redakai","RED VINES","RED STRIPE","Red Pack","Red Music","Red Lobster","RED HOOK","Red Carpet Manicure","RED BULL","RED BARON","RED","Rechargers","Recent Toys","Recaro","Rebelle","RealTree","Realtone","Realm","Real Techniques","Real Medleys","Ready America","REACH","RCA","RC COLA","RBX","RAZOR","Razbaby","RAYOVAC","RAWLINGS","Ravensburger","Ravel","Rasta Imposta","Raskullz","RAPALA","RAOS","RANIR","Ranger","Range Kleen Mfg","RANGE KLEEN","RANDOM HOUSE","RALPH LAUREN","RAISINETS","RAIN-X","Raintree","Rainbow Light","RAID","RAGU","RADIO FLYER","RADICA","Radiance","RACHELS","Rachel Shoes","RACHAEL RAY","R&R Games","QUNOL","Quirky","Quinn Popcorn","Quilted Northern","Quik Shade","Quik Lok","QUICKIE","Quick Clot","Quest","Queen Latifah","Que Bella","Quartet","Quarrow","Quark","Quality Park","QUAKER","Q-TIPS","Q-See","Qrunch","Qosmio","QCA Spas","Q.Steps","PYREX","PYRAMID","Pursonic","PURPOSE","PURPLE COWBOY","PURINA","PUREX","PUREOLOGY","PureMoist","purely elizabeth.","PURELL","pureguardian","PureGear","PureFit","PURE PROTEIN","Pure Green","Pure Fun","Pure Fitness","Pure Energy OB","Pure Energy","Pure Comfort","Pure and Natural","PURE","PUR","PUP-PERONI","Punisher Skateboards","Pulse","Puj","PUFFS","Puddle Jump","PUCCI PUPS","Publisher Services","Publications Interna","PTS America","PSST","PSORIASIN","Psi Brands DNU","Psi Bands","PS3","PROVENT","Proteque","PROSPIRIT","Prospera","Proscan","Prosacea","ProRack","PROPET","PROPEL","PROMISQOUS","Pro-Medic","Proliss","Project Basics","PROGRESSO","PROGRESSIVE INT'L","ProGear","Pro-Form","ProForm","Profloss","Prodyne","PROCTOR-SILEX","ProActive","Pro Tour Memorabilia","Pro Player Merch","Pro Merch","PRO LINE","Pro Cat","Pro Beauty Tools","Privilege","Prinz","Printworks","PRINGLES","PRINCESS","Prince Lionheart","PRINCE","Primo","PRIME TIME","PRILOSEC","PRICE'S","Prevacid","Pretika","PRESTO","PRESSMAN","PRESERVE","PreSeed","Preparation H","Prepara","Prenatal Cradle","PREMIUM","PREMIERE","Preggie","Preferred MFD","Preferred","Precious Firsts","PRECEPT","PRAIRIE FARMS","Pragotrade","Prada","Prabal Gurung","POWERBAR","POWERADE","PowerA","Power Trains","POWER RANGERS","Power A","POVIDONE","PostMaster","POST-IT","Post Raisin Bran","POST","Positec","Portrait of a Flower","PortablePET","Porsche Design","Pop-Tarts","Popsicle","POPCHIPS","PopCap","POP SECRET","Poolmaster","Poof-Slinky","POND'S","Ponds","POMPEIAN","POM WONDERFUL","Polywood","POLYSPORIN","Polti","POLLY POCKET","POLIGRIP","POLDER","POLAROID","POLARIS","POLAR","POLANER","POLAND SPRING","POISE","PLUM ORGANICS","PLEDGE","PLAYTEX","PlayStation","PLAYSKOOL","PlayMG","PLAYMATES","PLAYHUT","Play-doh","Playboy","Play Visions","Play Circle","Plastec","PlaSmart","Plantronics","PLANTERS","PLANO","Plan B One Step","Plackers","PJ's Organics","PJ Couture","Pizzacraft","Pixi","Pistachio","Pirate's Booty","Pipila","PiperGear","Pipeline","PIONEER","Pino Silvestre","PINNACLE","Pink Platinum","PINK","PINE-SOL","PINALEN","PILSNER URQUELL","PILOT","Pillsbury","Pillow Perfect","PIERRE CARDIN","Pierre Balmain","PICNIC TIME","Pibb","Physio Logic","PHYSICIAN'S FORMULA","Physicians Formula","Photo","PHILLIPS","Philips Sonicare","Philips Norelco","PHILIPS","PHILADELPHIA","Phil and Teds","Peugeot Watches","Peugeot","PETSTAGES","Petspaces","Petit Tresor","Petit Nest","Peter Rabbit Organic","Peter Pilotto for Target","PETER PAN","PET GEAR","PET","PERRY ELLIS","PERONI NASTRO AZZURR","Pero Family Farms","Perler","PERKY PET","Perfumers Workshop","Perfect Timing Inc.","Perfect Portions","Perfect","PEPTO BISMOL","Pepsi MAX","Pepsi","PEPPERIDGE FARM","PEPCID AC","PENTEL","PENTAX","Penn","PENGUIN","PENDAFLEX","Pelican","PEG PEREGO","PEEPS","Pedrini","PEDIASURE","PediaPals","PEDIALYTE","PEDIA-LAX","Pebble","Peavey","PEARLS","Pearl","Pearhead","Peanut Shell","PEANUT BUTTER CO","PEAK","PDP","PC Treasures","pBone","pb Travel","Pawley's Island","Pavlov'z Toyz","Paul Smith","PAUL SEBASTIAN","PAUL MITCHELL","Paul Frank","PATTON","PATTI LABELLE","Pathlighter","Pathika","PATCH PRODUCTS","PATCH","PASTORELLI","PASTA RONI","Parker Brothers","PARK & SUN","Parissa","PARIS PRESENTS","PARIS HILTON","Parfums Rivera","PARFUMS DE COEUR","PARAMOUNT PICTURES","PARAMOUNT","PaperPro","PAPERMATE","PAPER MAGIC","Paper House","PANTENE","Pantech","PANERA","PANASONIC","PAMPERS","PAMELAS","Pam Grace","PAM","Palram Home&Garden P","Paloma Picasso","PALMOLIVE","PALMERS","Paisley Sky","Pair of Thieves","PACON","Paco Rabanne","Packit","Packaged Produce","PACIFICO","Pacifica","Pacific Playtents","Pacific Market Intl","Pacific Cycle","PACIFIC","P.F. CHANGS","OZARKA","Oxygen Plus","OXY","OXO","OXI CLEAN","OXFORD","Own","OvenStuff","OVEN FRY","OVALTINE","Ouya","Outdoor Products","Outdoor Decor","Outback GC","OUT!","Out of the Woods","Out of the Box","OUR GENERATION","Ott-Lite","OttLite","Otterbox","OSTER","OSTEO BIFLEX","Oscar Mayer","Oscar De La Renta","ORTHO OPTION","ORTHO","ORTEGA","ORRINGTON FARMS","OROWEAT","Orlane","Orla Kiely","ORKA","ORIGINS","Original Power","Original Penguin","ORIGIN","Origami","Organizher","ORGANIZE-IT","ORGANIX","ORGANICS","organicKidz","ORGANIC ROOT","OREO","Ore-Ida","OREGON SCIENTIFIC","OREGON CHAI","ORE INTERNATIONAL","Orbit Baby","ORBIT","Orbeez","ORANGE GLO","Oral-B","ORAL B","ORAJEL","Orabrush","Optimum Fulfillment","OPTIMUM CARE","OPTIMUM","Optimal Solutions","OPTI-FREE","OPI","OPEN PIT","OPCON A","Oopsy Daisy too","Oopsy Daisy","Ooma","ONTEL","OnGuard","OneTouch","ONEIDA","ONE STAR","One Rewards","One Direction","ONE A DAY","ONE","Ondago","ON THE BORDER","On stage","OMRON","Omojo","Omega","OLYMPUS","Olloclip","Oliver B","Olive Kids","Olive Garden","Oliso","OLDE THOMPSON","Old Spice","OLD ORCHARD","OLD LONDON","OLD HOME","OLD ENGLISH","Old El Paso","Olay Total Effects","Olay Regenerist","Olay Pro-X","Olay Fresh Effects","Olay Age Defying","OLAY","OKO","Okespor","OILS OF ALOHA","OHM","Oh Joy!","OGX","OGIO","OGGI","Officemate","OFF","Of The Moment","Oenophilia","Oeko","OCUVITE","Ocean's Halo","Ocean Spray","Ocean Potion","OCEAN BEAUTY","Oball","OB","Oatmeal Squares","Oatmeal Crisp","Oakland Living","o.b.","O' CEDAR","NYX","NYLABONE","Nyko","NYC COLOR COSMETICS","NV","NUTTER BUTTER","Nutrisse Foam","NUTRI-GRAIN","NUTELLA","Nurturme","Nurtured by Nature","Nurseryworks","NURSERY WATER","Nuo Tech","NUK","NUBY","NuBrilliance","Nubian HeritageDNU","NUANCES","NSI International","NSI","NP Set","NOXZEMA","NOVA","Nostalgia","Nosefrida","Nos","NORTHWOODS ICE","Northern Response","NORTHERN LIGHTS","Northern Light","NORTHERN","North States","North Star Games","NORTH SHORE","North American Healt","NORSK","Norpro, Inc","NORELCO","NORDIC WARE","Nook","Noodle","Nokia","NOJO","Nogii","NOBILO","Noah's Golf Kingdom","NO YOLKS","No Brand","NNE Root Touch-Up","NNE PERFECT 10","Nivea for Men","NIVEA","Nitro Golf","Nit Free","NISHIKI","Nip + Fab","NIOXIN","NINTENDO","Nino Cerruti","NINJA TURTLES","Ninja","Nine Stars","Nina Ricci","NILLA","NIKON","NIKE","Nifty","NICORETTE","Nicole Miller","Nicole By OPI","Nicole","NICODERM","NICKELODEON","NICK & NORA","Nice 'N Easy Root Touch-Up","Nice 'N Easy Perfect 10","Nice N Easy","NHL","NFL","NEXXUS","Nexxt","Nexium 24HR","NEWTONS","NEWMAN'S OWN","Newco","NEWCASTLE","NEW YORK","New Wave","NEW SKIN","NEW ENGLAND","New Creative","NEW BRIGHT","New Balance","New Arrivals, Inc.","New Age Pets","NEW AGE","NEVERKINK","NEUTROGENA","Neu Home","Net-Jack","Netgear","NET 10","NESTLE CRUNCH","NESTLE","Nest","Nesquik","NESCO","NESCAFE","NERF","Nerds","NEOSPORIN","NeoGeo","Nekoosa","NEGRA MODELO","NECA","Neat-Oh!","NEAT-OH","Neato Robotics","neatHOME","Neatfreak","NEAT SOLUTIONS","Nearly Natural","NEAR EAST","NCIRCLE","NCAA","NC Soft","NBA","Navigator","NAVARRE","NAUTICA","Nature's Wick","NATURES PILLOWS","NATURE'S PATH","NATURES OWN","Nature's Baby Organics","Natures Baby Organic","Naturepedic","NatureBright","NATURE VALLEY","Nature Raised","Nature Nate's","NATURE MADE","Nature Bright","NATURE BABY CARE","NATURALLY","Natural Stone","NATURAL STEPS","NATURAL LIGHT","Natural Instincts","NATURAL ICE","Natural Home","Natural fitness","NATURAL","Natsume","NATROL","National Tree Compan","National Products LT","NATIONAL EXPRESS","National Brand","NATIONAL","NATHAN'S","Nathan","Nate BerkusDNU","Nate Berkus","NASCAR","Narita Trading Co.","Narciso Rodriguez","NAPOLEON PERDIS","NAPHCON","Nanospeed","Namco","NALGENE","NAKED","NAKANO","NAIR","Nady","Nads","NABISCO","Nabi","Myrurgia","MYOJO","MYMO","Mylec","My Pillow Pets","My Minds Eye","My Look","MY LITTLE PONY","My girl's DOLLHOUSE","My Brest Friend","MY BABY SAM","Musti","Mustela","Muskoka","MURRAYS","MURRAY","MURPHY'S","Munchkin","Mumbo Jumbo","Multipet","Multi-Betic","Muk Luks","MUIR GLEN","MUG","MUELLER","Muelhens","Mudhut","MUCINEX","MU Kitchen","MTD","MRS. T'S","MRS. RENFRO'S","MRS. PAUL'S","Mrs. Meyer's","MRS. DASH","MRS. CUBBISON'S","MRS MEYERS","MRS CUBBISONS","MRS BUTTERWORTH","MRS BAIRDS","MR. COFFEE","MR. CLEAN","Mr. Beer","MR. BAR-B-Q","MR & MRS T'S","Moxie Girlz","MOVE FREE","Mountain Sole","MOUNTAIN RIDGE","Mountain King","MOUNTAIN HIGH","Mountain Dew","Mountain Buggy","MOUNT OLIVE","MOTT'S","MOTRIN","MOTOROLA","MOTIONS","Mother's Cookies","Mother's Cereal","MOTHER'S","Mossy Oak","MOSSIMO SUPPLY CO.","Mossimo Supply Co","Mossimo Black","Mossimo","Moshi","Moschino","MORTON","MORNINGSTAR FARMS","MORINAGA","More-C","Mophie","Mop & Glo","Mootsies Tootsies","MOOSE MOUNTAIN","MOORES","Moon Products","MONTEREY","MONTBLANC","Monsuno","Monster High","Monster Cable","Monster Brew","MONSTER","MONOPOLY","Monkey Bars","MONISTAT","MONGOOSE","MONARI FEDERZONI","Mommy's Helper","mOmma","Molyneux","MOLSON","MOLLY MCBUTTER","Molinard De Molinard","Molinard","Moleskine","Mohawk Home","MOHAWK","Moen","MODELO ESPECIAL","Moda Luxe","Moda Casi","Moby","Mobo","Mobiliving","Mobilexpressions","MobiGo","Mobi","MLB","MIZUNO","Mizerak","MIZANI","Mix-Ups","Mixed Chicks","Mix","MiTutto","MITCHUM","Mitchell","Mistymate, Inc","Mission","Miss Oops","Miss Jessie's","Misfit Shine","Misco","Mirror Image","MIRASSOU","MIRALAX","Mirage","MIRACLE WHIP","Miracle Bubbles","Miracle Blanket","Miracelle","MIQUEL-RIUS","MIO","MINUTE RICE","Minute Maid","Mint","Ministar","Mini Babybel","Mineral Fusion","Mindware","Mind Reader","Million Dollar Baby","Miller Lite","MILLER CHILL","MILLER","Millennium Media","MILKY WAY","Milk Splash","MIKE'S HARD LEMONADE","MIKEN","MIGI","MIDWEST GLOVE","Midway Games","MIDWAY","MidNite","Midland","MIDDLE SISTERS","MICROSOFT","Microplane","MICKEY MOUSE","MICKEY","MICHELOB","Michel Germain","MICHAEL KORS","MICHAEL JORDAN","MICHAEL GRAVES","Micargi","MIA 2","MGM","MGA ENTERTAINMENT","MEZZETTA","MEYER'S","MET-RX","METROKANE","Metro Vacuum","METRO","METHOD","METAMUCIL","Metal Earth","MERRICK","MERONA collection","Merona","Merkury","MEOW MIX","MENTOS","MENAGE A TROIS","MEMORY","MEMOREX","Members Only","Melt","Melokia","MELNOR","Mello Yello","MELITTA","Melissa & Doug","Melie","Meguiars","Megared","Mega Brands","MEGA BLOKS","MEGA","MEEP","MedPro","MEDLINE","MEDIBAG","M-Edge","MEDERMA","Medelco","MEDELA","MedCenter","MEDAGLIA","Meccano","MEAD","ME4KIDZ","MD Beauty","MD","MCS Industries","McKlein","MCILHENNY","McCulloch","MCCORMICK","MCCAIN","Mcafee","MBI","MAYTAG","Maylong","Mayfair Games","MAYFAIR","Maybelline Volum'Express","Maybelline Dream","Maybelline Color Sensational","Maybelline Clean Express","Maybelline Baby Lips","Maybelline","MAYA GROUP","MAXWELL HOUSE","Maxius","Maximum Family Games","Maxi-Matic","MAXIM","Maxi","Maxar","Max Steel","MAVERICK RANCH","Maverick","Maurer & Wirtz","Maui Babe","MAUI","MATTEL","MATCHBOX","Mata Piojos","Mastrad","Masterpieces","Mastercraft","MASTERBUILT","MASTER OF MIXES","Master Massage","MASTER LOCK","MASTER","MARZETTI","Mary J Blige","Marvel Classic","MARVEL","MARUCHAN","MARTIN'S","MARTINI & ROSSI","Martian","Martha Stewart","Marshmallow Fun","MARS","Marpac","Marmol & Son","Market Pantry","MARK WEST","Mark of Fitness","Mario Kart","MARIO","Marina de Bourbon","MARIE'S","Marie Callender's","Mariah Carey","MARGARITAVILLE","Marcy","Marcella Borghese","Marc Jacobs","Marc Ecko","MARANDA ENTERPRISES","MaraNatha","Mara Mi","Maples","Maple Skateboards","MAPLE GROVE FARMS","Maple","MANZANITA SOL","Manzanilla Grisi","Manual","Mantis","Mann's Sunny Shores","MANLEY","Manhattan Toy","MANHATTAN BEACHWEAR","MANHATTAN","Manhasset","MANGROOMER","Manfrotto","Man on the Go","Mambo Liz","MAM","MALT-O-MEAL","MALIBU","Malden","MAKOTO","MAKER'S MARK","Majestic pet","Majestic","MAJESCO","MAISTO","Mainstreet Classics","MAIDENFORM","Magnum","MAGNAVOX","Magna-Tiles","MAGNA","MAGLITE","Magical Harmony Kids","MAGIC SLIDERS","Magic Bullet","Magic Bag","MAGIC","Maggie Bags","Magefesa","Mag Instruments","Maestro","Madonna","Madd Gear","Mad Love","Mad Catz","MACK","MACH3","Macally","Macadamia","Mac Sports","Mabu","MABIS","M&M'S","Lytro","LYSOL","LYNK, INC","Lyfe Kitchen","LUXE","LUVS","Luvena","Luvable Friends","LUSTER","Lunchskins","LUNA","LumiSource","Lumiscope","Luminess Tan","Luminess Air","Lumex","Lumabase","Lulyboo","LUIGI'S","LUIGI BROMIOLI","LUDENS","LUCKY YOU","Lucky Star","Lucky Dog","LUCKY CHARMS","Lucky Buddha","LUCKY","LUCINI","LUCAS ARTS","Lucas","LUBRIDERM","LowePro","Loving Family","Love Beets","Love & Toast","Louisiana","LOUIS JADOT","Lotus & Tersano","Lot 26","LORNA DOONE","Lorex","L'Oreal Voluminous","L'Oreal Visible Lift","L'Oreal True Match","L'Oreal Sublime","L'Oreal Studio Secrets","L'Oreal Revitalift","L'Oreal Preference","L'Oreal Mousse Absolute","L'Oreal Healthy Look","L'Oreal Feria Ombre","L'Oreal Feria","L'Oreal Excellence","L'Oreal Colour Riche","L'Oreal Advanced Haircare","L'Oreal","Look Beauty","Loog","Lomani","Lolly & Me","Lolli Living","Lolita Lempicka","LOGITECH","LogicMark","LOG HOUSE","LOG CABIN","Lodge","LOCTITE","LOADED QUESTIONS","Liz Lange Maternity","Liz Lange for Target","LIZ LANGE","LIZ CLAIBORNE","Living Textiles Baby","LITTLEST PET SHOP","Little Tree","LITTLE TIKES","Little Remedies","Little People","Little Partners","LITTLE MOMMY","Little Live Pets","LITTLE KIDS","Little Diva","LITTLE DEBBIE","Little Castle","Little Adventures","Litter Genie","LITEHOUSE","Lite Source","Lite Brix","LISTERINE","LIQUID PLUMR","Lipton RTD","LIPTON","Lipper International","Lip Smackers","Lip Smacker","Lionsgate","Lionel Trains","LIONEL","Linsay","Linon Home Decor","LINKSYS","LINEA","LINDT","LINCOLN LOGS","LIMEAWAY","Lilyette","Lily Star","Lily Nily","Lillian Rose","Li'l Woodzeez","Lil' Rider","LIL CRITTERS","Light Air","Lifty","LIFOAM","Lifetime Brands","LIFETIME","LIFESTYLES","LifeSmart","LifeProof","LifelineUSA","LIFE SAVERS","Life Juice","Life Gear","LIFE","LICENSE","LIBERTY HARDWARE","LIBERTY","Liberte","Libby's PUMPKIN","LIBBEY","LG","LEXMARK","LEXAR","Lewis and Clark","LEVY","LEVI'S","Lever 2000","LEVER","Levels of Discovery","Level Mount","LEVEL","Le'Var","Levana","LETS JAM","L'Equip","Lenmar","LENDER'S","LEMI SHINE","LEINENKUGEL'S","LEINENKUGELS","LEGO","L'eggs","LEGGS","Lee Stafford","LEE KUM KEE","Lee","LECTRIC SHAVE","LEATHERMAN","Leatherbay","LEARNING RESOURCES","Learning Curve","LEAPFROG","LEAN POCKETS","LEAN CUISINE","Leachco","LEA & PERRINS","Le Sueur Brands","LAY'S","Lay-n-Go","LAWRY'S","LawnMaster","Lavera","Lavazza","Lavanila","Lava Lite","Laurent Doll","LAURA'S LEAN BEEF","LAURA SCUDDER","Laura Biagiotti","LAUGHING COW","Laugh & Learn","Latte Communications","LASKO","LashPRO","Laser Pegs","Lascal","LAS PALMAS","Lanvin","Lansinoh","Lang","Laneige","LANDSHARK","LANDMANN","LAND O'FROST PREM","LAND O' LAKES","LAND O LAKES","LANCOME","LANCE","Lamisil","Lambs and Ivy","Lambs & Ivy","LAMAZE","Lalique","Lalaloopsy","Lake Placid","L'AIR DU TEMPS","LAGUNITAS","Lagerfeld","Laffy Taffy","LADYGROOMER","Lactalis","LACROIX","LACOSTE","labworks for Target","Labworks","LABATT BLUE","LA VICTORIA","LA Underground","La Rochere","La Roche Posay","LA PREFERIDA","La Perla","LA LOOKS","La Dee Da","LA CROSSE TECHNOLOGY","LA CREMA","LA CHOY","LA BELLA","LA BANDERITA","LA BABY","Kyocera","KY","KWIK TEK","Kurio","KT Tape","KRYPTONICS","KRUSTEAZ","Krizia","Kristel Saint Martin","Kretschmar","Krave Jerky","Krave","Krash!","KRAFT","KRACO","KOTEX","KORBEL","KOR","Koolatron","KOOL-AID","KONG","KONAMI","Kona Guitars","KONA","KOLCRAFT","Kolbs","KOEI","KODAK","KNUDSEN","KNORR","K'Nex","KNEX","KLONDIKE","KLIPSCH","Kleen-Free","KLEENEX","KIX","KIWI","KITTRICH","KITCHENAID","Kitchen Supply Compa","Kitchen Selectives","KITCHEN BOUQUET","KITCHEN BASICS","Kitchen Art","Kit Kat","KISSES","Kiss Nail","KISS MY FACE","KISS","KIRIN ICHIBAN","Kinky Curly","Kinky","Kingston","KINGSFORD","KING OSCAR","King of Shave","KING KOOKER","King Canopy","KING","Kinfine","Kinetic Sand","KINDERMAT","KIND","KIMBLE","Kimberly Grant","KIMBERLY CLARK","Kim Kardashian","KIM CRAWFORD","KILLIAN'S","KIKKOMAN","Kik Step","Kiinde","Kidz Gear","KIDZ DELIGHT","Kidsline","KIDS ONLY","Kids Made Modern","Kids Line","KIDS II","Kids 0-9","Kid-O","KIDKUSION","KIDKRAFT","KIDDE","Kidco","Kid O","Kid Motorz","KID GALAXY","Kid Cuisine","Kid Basix","Kicking Horse Coffee","KIBBLES 'n BITS","Khataland","KEYSTONE LIGHT","KEYSTONE","KEY WEST","KEURIG","KETTLER","KETTLE","Ketonerx","KERRY GOLD","KERR","KERNEL SEASON'S","Kernel Seasons","Keratin","Kenzo","Kenu","KENTUCKY LEGEND","Kent","KENSINGTON","Kenroy Home","Kennex","KENNETH COLE","KENDALL JACKSON VR","KEN DAVIS","Kem-Tek","KELSYUS","Kelo-cote","KELLOGG'S","Keilen","Keekaroo","Keebler Grahams","KEEBLER","KDon Technology","KC MASTERPIECE","KBL","KAZ","KAYTEE","KAWASAKI","Kawaii Crush","KAUKAUNA","Katy Perry","Kate Aspen","Katadyn","Kaskey Kids","Kashi","Karma Baby","KARMA","Karl Lagerfeld","Karin Maki","Karen Foster","Karcher","Karastan","Kappa Map","Kapoosh","KAOS","KAOPECTATE","Kanon","Kangol","Kamprite","Kalypso Media","Kalorik","Kalencom Corp","Kaisercraft","Kaiser","KABOOM","Kaboo","KABACLIP","K&Company","J-World","JWorld","JVC","JUSTIN'S","Justin Bieber","JUSTICE LEAGUE","JUST WIRELESS","Just Play","Just One You by Carter's","Just One You","JUST FOR MEN","JUST FOR ME","Just Born","Just Bare","Just 1 Pet","JUNIOR MINTS","June Bug","JUICY JUICE","JUICY FRUIT","JUICY COUTURE","JUICEMAN","Judith Jackson","JUANITA'S","JR Watkins","JP Lizzy","JP JESUS DEL POZO","JP GAULTIER DNU","Joy Mangano","JOY","JOVAN","Journee Collection","Joseph Enterprises","JOSE OLE","JOSE CUERVO","Jordan","Joop!","JOOP","Joola","JONES","Jonathan Product","JoJo Designs","JOINT JUICE","Johnson's Natural","Johnson's Baby","Johnson & Johnson","JOHNSON","John Varvatos","John Paul Pet","John N. Hansen","John Louis Home","JOHN FRIEDA","John Bunn","JOCKEY","Joby","Jobar Int'l","jLab","JL Childress","JKY by Jockey","JJ COLE","Jivago","Jimmy Dean","Jimmy Choo","JIM BEAM","Jillian Michaels","Jill-e","Jil Sander","JIFFY","JIF","Jibbitz by Crocs","Jesus Del Pozo","Jessica Simpson","Jessica McClintock","JERZEES","JERGENS","JENSEN","Jennifer Lopez","Jennifer Aniston","Jennie-O","JENGA","Jemma Kidd","JELLY BELLY","JELL-O","JEEP","JeanCharles Brosseau","Jean Paul Gaultier","Jean Patou","Jean Couturier","JBL","Jay Import","Jay Franco","JAX","Jawbone","Java Slim","JASON","JARRITOS","JARLSBERG","JARDEN","JANSPORT","Janome","Jane Carter","Jamie Oliver","James Bond","JAMBA JUICE","JAKKS","Jaguar","Jacques Evard","Jacques Bogart","Jacomo","JACK'S","JACK LINKS","JACK LALANNE","JACK DANIEL'S","Jack and Lily","Jaccard","JABRA","J.A. Henckels","J R WATKINS","IZZO GOLF","IZZE","iXtreme","IVORY","Itzy Ritzy","Itzbeen","Itza","ITUNES","itso","It's So Me","IT'S A 10","iTouchless","Ita-Med","Italtrike","Issey Miyake","ISOTONER","ISO Beauty","ISO","ISI","ISANI for Target","isABelt","IRONMAN","IRONKIDS","IRISH SPRING","IRIS","iRelax","Iplay","iOptron","Ionic Pro","ION Audio","ION","Intramedic","INTL PLAYTHINGS","Intl Caravan","INTEX","INTERPLAK","International Playth","INTERNATIONAL DELIGH","Interdesign","Intelligender","InStyler","Inspire","innovative technolog","InnovAsian","InnoTab","Inkoos","Inkadinkado","Inglow","Inglesina","INGLEHOFFER","Ingenuity","Infinity","Infiniti Pro by Conair","INFANTINO","Indus Tool","INCOMM","Incharacter","INCASE","In Step","In Control","IMUSA","Imprint","IMPERIAL TOYS","IMPERIAL","IMAN","IMAGINATION","IMAGE Entertainment","iLuv","Illume","iLive","IHOME","iHealth","IGNITE","IGLOO","iFusion","iFrogz","Ideaworks","IDEALS","Idea Village","ICY HOT","ICU Eyewear","Icon","iCLEBO","Iceberg","ICE MOUNTAIN","iCat","ICAPS","iBuypower","IBERIA","IAMS","I.B.C. ROOT BEER","I sound","I M HEALTHY","I Health","I CAN'T BELIEVE IT'S","HyperChargers","Hyper","HYLANDS","HYDROXYCUT","HUY FONG FOODS INC.","Huxtable's","Hurom","HUNT'S","Hunter Fan","HUNTER","HUNGRY-MAN","HUNGRY JACK","HUMMER","Hulu","HULK","HUGO BOSS","HUGO","Huggies Natural Care","HUGGIES","HUGGABLE HANGERS","HUFFY","Hudson Baby","HUBBA BUBBA","Huawei","HTC","HOUSEHOLD ESSENTIALS","HOUSE OF TSANG","House of Doolittle","House and Hound","House & Hound","Houdini","HOT WHEELS","Hot Tamales","HOT POCKETS","Hot Off the Press","HOSTESS","Hortense B. Hewitt","Hormel","HORIZON","Hope Paige","HOOVER","Hongo Killer","HONEYWELL","Honey-Can-Do","HONEST TEA","HONEST KIDS","HOMESTYLE","Homespun TM MFD","Homespun TM","HOMEDICS","HOME STYLES","Home Source","HOME PRODUCTS INTERN","Home Essentials","HOME","HOLMES","Hollywood Beauty","HOLLYWOOD","HOLLAND HOUSE","HOLIDAY TIMES","HMDX","HiTech Rx","HitchMate","Hit Entertainment","HIT","Hisense","Hillshire Farm","Hillsdale Furniture","HI-LITER","HighRoad","Highland","High Five","HIDDEN VALLEY","Hibiclens","Hexbugs","Hewlett-Packard","Hewlett Packard","HERSHEY'S","Hers","HERPICIN","Hero Arts","HERO","Hermes","Heritage Pools","HERITAGE","HERDEZ","Herbal Essences","HERBAL ESSENCE","Herbacil","HER Interactive","HENNESSY","HENKEL","HENCKELS","Help Remedies","Hello Kitty","Hello","Hellmann's","HEINZ","HEINEKEN","Heidi Klum","HEFTY","Hedbanz","HEBREW NATIONAL","HeatMax","Heart 4 Hearts","Healthy Choice","HEALTH-O-METER","Health Mark","HEAD N SHOULDERS","HEAD","HCG","HBO","Haws","HAWAIIAN TROPIC","Hawaiian Style","HAWAIIAN PUNCH","Hawaiian","Haute Polish","HAUTE","Hauck","HASBRO","HARVEYS","Harve Benard","Harvard","HARTZ","Harry Koenig","Harper and Zoe","HARP","Harold Import Co","Harmony Juvenile","HARMONY","HARIBO","Hard Candy","Harbortown","Harajuku Mini","HAPPYBABY","Happy Trails","HAPPY KIDS","Happy","HAPI","Hanover","Hanes Red Label","HANES PREMIUM","Hanes","Handstands","Handcandy","Hanae Mori","Hampton Forge","Hampton Direct","Hammermill","HAMILTON BEACH","HAMCO","HALSTON","HALSA","Halo","HALLS","Hallmark","Halle Berry","Hal Leonard","Hailey Jeans","HAIER","Haggar","HACHETTE","Haagen-Dazs","H2O","H.I.M-istry","H.I.M.-istry","Gym Dandy","Gwen Stefani","Guy Laroche","Guy De On","Gun Oil","GUM","GULDEN'S","GUINNESS","Guidecraft","Guess","Guerlain","Gucci","Guardian","GT's","Grow'n Up","Group Sales","GRNDMA EMILI","Grisi","Grip by High Sierra","Grindz","GRIFFIN TECHNOLOGY","Griffin","GREY POUPON","GREY GOOSE","Gres","Greenway","Greenroom","GreenPan","GREEN WORKS","Green Toys","GREEN TEA","GREEN PEARLS","Green Inspired","Green Giant","GreatLite","GREATLAND","Great North Popcorn","Great Neck","GREAT AMERICAN","Granite Ware","GRAND MARNIER","Grand Epicure","Graham Field","Graham & Brown","Grafix","GRACO","GRABBER","GPX","G-Project","GP Percussion","GOURMET SETTINGS","GOURMET GARDEN","Got2B","GORTON'S","Gorilla Playsets","GORILLA","GoPro","GoPicnic","GOOSE ISLAND","Google","Goody Styling Therapy","Goody Simple Styles","Goody QuickStyle","Goody Ouchless","Goody Heritage Collection","Goody Doublewear","GOODY","GOOD SEASONS","Good Humor","GOOD COOK","GOO GONE","GOLLA","Goliath","Goldtoe","Gold'N Plump","GoldieBlox","GOLDFISH","Golden Grahams","GOLDEN GRAHAM","GOLD PEAK","GOLD MEDAL","GOLD BOND","Goicoechea","GoGo SqueeZ","GoGirl","GOFIT","GODIVA","Go Tubb","Go Toob","Go Mama Go Designs","Go Go Babyz","GMI","GLORY","GLORIA VANDERBILT","Global Girlfriend","Global Design Concep","GLIDE","Glenlivet","Gleener","GLD Products","Glaxo Smith Kline","GLADE","GLAD","GLACEAU","Givenchy","GIRARD'S","GIOVANNI","Gioteck","Giorgio Valenti","Giorgio Red","Giorgio Blue","Giorgio Beverly Hill","Giorgio Armani","GIORGIO","Giordano","GINSU","GINSEY","Gimme Couture","Gimme Clips","Gilligan by GOM","GILLIGAN & O'MALLEY","Gillette Series","Gillette Fusion","Gillette","Gildan","GILCO","Gift Mark","GIBSON","Gibraltar","Gianfranco Ferre","Giada De Laurentiis","GI JOE","GHIRARDELLI","Germ Guardian","GERBER ORGANIC","GERBER","Georgetown","GEORGE FOREMAN","Geoffrey Beene","GENUINE KIDS-SHOES","GENUINE KIDS","GENUINE BABY","GENTEAL","GENIUS","Geneva Platinum","GENEVA CLOCK COMPANY","GENERAL FOAM","GENERAL ELECTRIC","Gendarme","Gemmy","GelPro","Gelarti","GE","gDiapers","Gazillion Bubbles","Gazelle","GAVISCON","Gatorade RTD","GATORADE","GATEWAY","GAS X","Garven","GARTNER","Garnier Nutrisse","Garnier Fructis Style","Garnier Fructis","Garnier","GARMIN","GARDETTO'S","GARDEN SAFE","GARDEN PLACE","GarageMate","GarageMaid","GameMill","Game Development Gro","Galtech","GALLO","Gallet","Gale Pacific USA","Gale Hayman","GAIN","GAIAM","GAGGIA","Gadget Gourmet","Gabrialla","G. Pacific","G & S Metal","FUZE","Futuro","Fusion Watches","Fusion ProGlide","Fusion","FurReal Friends","Furby","FUR REAL","FUNYUNS","Funworld","Fungi Nail","Fundix by Castey","FUNDEX","FUL","FUJIFILM","Fuel","Fudge Urban","FUDGE SHOPPE","FRUTTARE","FRUIT ROLL-UPS","FRUIT OF THE LOOM","Fruit Gushers","FRUIT BY THE FOOT","FROSTED FLAKES","FRONTERA","FRONT PORCH CLASSICS","FRITOS","FRITO-LAY","FRIGO","Frigidaire","FRIENDLY TOYS","FRESHLINE","FRESH STEP","Fresh Keeper","FRESH EXPRESS","Fresh Baby","FRESCHETTA","FRESCA","Frends","FRENCH'S","FRENCH TOAST","French Connection UK","French Connection","French Bull","Freestyle By Danskin","FreeStyle","Free by Gottex","FREDERICK FEKKAI","Fred Hayman","Fred & Friends","FRANZ","FRANK'S","FRANKLIN SPORTS","Franklin Electronic","FRANKLIN COVEY","FRANKLIN","FRANCIS COPPOLA","Frances Denney","Fox Searchlight","Fox Run","Fox","Foundations","FOSTER'S","FOSTER GRANT","FOSTER FARMS","Foscam","Forum Novelties","Forge","Forever Collectibles","Forever","FOREMOST","For Dummies","FOODSAVER","FOOD SHOULD TASTE GD","FOLGERS","Focus Products Group","Focus Home Interacti","FOCUS FACTOR","FOAMY","FLYBAR","Fly Wheels","Flutterbye","FLORIDA'S NATURAL","Flip","FLINTSTONE","Flexible Flyer","FLEXI","FLEET","FIXODENT","Five Star Fragrance","FIVE STAR","Fitbit","FIT & FRESH","FISKARS","FISHER-PRICE","Fisher PriceClassDNU","FISHER","FISH FRY","FIRST YEARS","FIRST RESPONSE","FIRST CHECK","FIRST ALERT","FIRST AID ONLY","FIRST ACT","Firefly","Finish","FINESSE","Find It","FIJI","Fifth Sun","Fifth Avenue","Fieldcrest Luxury","Fiber Plus","FIBER ONE","FIBER CHOICE","FHI Heat","FHI","FETZER","Fertile Mind","Ferrero","Ferre","Ferrari","FEOSOL","FENG SHUI","FELLOWES","Felli","FELINE PINE","Fekkai","FEBREZE","Feber","FAULTLESS","FATHEAD","FAT TIRE","FAT CAT","FASHION FORMS","Fashion Angels","FARLEY'S","FARBERWARE","FANTASY","FANTASTIK","FANTASIA","Fanta","Fanmats","FAMOUS DAVE'S","FAMILY FEUD","Faith Hill","Fairy Tales","Fairy Tale High","FAHRENHEIT","Fagor","Fage Total","Factor X","Faconnable","Face A Face","FABULOSO","Faberge","Faber-Castell","FAB FEET","FAB","ezip","E-Z Up","EZ Smart","Eye Majic","Exxel Outdoors","Extra","Extenze","Expressions","EXPO","Ex-Lax","Exhart","Exerpeutic","Exergen","Exederm","EXCEL","EX LAX","EvoraPlus","EVOLVE BY 2(X)IST","EVOLVE","Evian","EVERY MAN JACK","Everstyle","Eversleek","EVERLAST","Evergreen","Everest & Jennings","EVEREADY","Evercreme","EVERCARE","EVENFLO","Eve Alexander","Eva-Dry","EV VALENTINE","EV SUMMER","EV HOLIDAY","EV HALLOWEEN","EV EASTER","EV CHRISTMAS","Europa Baby","Euro Cuisine","EUREKA","EUPHORIA","EUCERIN","Eton","ETCH A SKETCH","ET2 Lighting","ESTROVEN","ESTER C","Estee Lauder","ESTANCIA","essie nail color","essie nail care","Essie","Essential","ESSELTE","Espressione","Escentials Aromather","ESCAPE","Escali","ESCADA","Erox","ERGObaby","ERATH","Eradicator","ERA","EQUAL","EPSON","Epiphone","Epilady","EPIC","EOS","Enviro-Mental Toy","Envion","ENTENMANN'S","ENSURE","ENFAMIL","ENERGIZER","ENDUST","ENDLESS GAMES","Encore","Enclume","EMSON","EMSCO","Empower","Emoji Icons","EMJOI","EMI Music","EMETROL","EMERSON","Emeril","EMERALD","EMBASA","EMBARK","Ematic","Emanuel Ungaro","Elsa L. Inc.","Elsa","ELMER'S","Ello","ELLIS","Ellen Tracy","Ellas Kitchen","Elizabeth Taylor","Elizabeth Arden","Elite Home Fashions","ELITE","Elf","Elenco","Elements","Element Electronics","Element","Elegant Home Fashion","ELECTRONIC ARTS","ELECTROLUX","El Paso","EL MONTEREY","EK Success","Eight O'Clock","EIGHT OCLOCK","Eidos Interactive","Eggo","Egg Beaters","EEBOO","EDY'S","Edushape","Educational Insights","Edifier","EDGECRAFT","EDGE","EDEN","EDDIE BAUER","Ed Hardy","ECR4Kids","EcoTools","EcoSphere","EcoSmart","ECOS","EcoQue","Econofit","Ecolution","Eco Tools","Eclos","Eclipse","Echo Valley","Echo Park Paper","ECHO","Easy-Off","EASY-BAKE","Easy Riser","Easy Outdoor","Easy Care","Easy Bake","Easy","Eastpoint","Easton","EAS","Earthwise","Earth's Best","EARTHBOUND FARMS","EARTHBOUND FARM","Earth Therapeutics","Earth Pan","Earth Mama Angel Baby","Earth Mama Angel Bab","EARPLANES","EarOil","Earnest Eats","EARLY CHILDHOOD RESO","EARLY CALIFORNIA","EAGLE BRAND","EA","e.l.f.","E.l.f","E One Entertainment","DYSON","DYNASTY","DYMO","DUTAILIER","DUREX","Duralex","DURAFLAME","DURACELL","DURABUILT","Dunkin' donuts","Dunhill","DUNCAN HINES","Duncan","DULCOLAX","DUKES","Duff","Duck Dynasty","DUCK","Dualit","D-Signed for Target","DS","DRYEL","DROPPS","Driven","Drive Medical","Drive","DREFT","Dreamworks","Dreamgear","DREAMFIELDS","Dreambaby","DRANO","DRAKKAR NOIR","DragonFly Yoga","Dr. Teal's","Dr. Praeger's","Dr. Laura Berman","DR. Ho's","DR. FRESH","Dr. Bronner's","DR SCHOLLS","DR PEPPER","DR MIRACLE'S","DR BROWNS","DR BRONNERS","Downy Unstopables","DOWNY","Dove Men+Care Expert Shave","Dove Men+Care","Dove Men","DOVE CHOCOLATE","DOVE BEAUTY","Dove","Doulton","Double Dutch Club","DOTS","DOS EQUIS","DORITOS","Dorel Home Products","Dorel Home Product","Dorel Altra","Dora the Explorer","Dora","DOODLE PRO","Doodle","DOO GRO","Donna Karan","DONA MARIA","DON FRANCISCO","Domtar","DominosDNU","Dominos","DOMINO","Dolle Shelving","Dole Juice","DOLE","DOLCE & GABBANA","DOGSWELL","Dog for Dog","DOG CHOW","DocuGard","Doc McStuffins","Do Not Disturb","DMI SPORTS","DMC Products","Dluxe","DKNY","Dixon","DIXIE","DIUREX","Disney Princess","Disney Interactive","Disney Fairies","DISNEY","Disguise","DISENO","Discovery Bay Games","Discovery","Discoveroo","DISARONNO","DIRT DEVIL","Diono","DINTY MOORE","Dinosaur Train","DINGO","DIMETAPP","Dimensions","DigiPower","DIGIORNO","Diggin Active","DIGGIN","Digestive Advantage","Diet Squirt","Diet Sierra Mist","DIET RITE","Diet Pepsi","Diet Mountain Dew","Diet Coke","Diet Canada Dry","Diet A&W","Diet 7-up","Diesel","Die Cuts With A View","DICKINSON'S","DICKIES","Diary Of A Wimpy Kid","Diaper Genie","Diaper Dude","Diaper Dekor","Diaper Buds","Diane Von Furstenbrg","DIAMOND","DIAL","DEXAS","Dex Products Inc","Dex Products","DEX","DEWAR'S","Deva Curl","DESTINEER","DESITIN","DESIGNER WHEY","DESIGNER IMPOSTERS","Designco","Design House LA","DESIGN","DESERT PEPPER","Dermorganic","Dermisa","Dermatouch","DermaLight","Dermabrush","DERMA","DEPEND","Dentyne","DENTEK","DENNISON'S","DENMARK'S FINEST","Denizen from Levi's","Denizen","Demets","Delta Childrens Prod","Delta Children","DELTA","DELSYM","DELONGHI","Dell","DELIZZA","Delimex","Delights","DEL MONTE","DEJA BLUE","DEGREE","Deflecto","DEER PARK","DEBROX","DEAN'S","Dead Sea Essentials","De Wafelbakkers","De La Cruz","DE CECCO","De Blossom","DCWV","DC Comics","Dayspring","Daxx","DAWN","Dawgs","DAVINCI","Davidoff","DAVID BECKHAM","DAVID","Datel","DASANI","Das Keyboard","Darrell Lea","Dark and Lovely","Dark & Lovely","Darden","Danze, Inc","Danya B.","Danshuz","DANNON","Daniel Tiger","Danesco","Danelectro","DANE-ELEC","DANBY","DANA","DAMP RID","Dallas Mfg. Co.","Dali","Dakota","Daisy Rock","DAISY","DAIRY BRAND","Daily Necessities","DAEWOO","Daelia's","DadGear","D3 Publisher","D234 Only","D&W Silks","D CON","Cygnett","CYCLE FORCE","Cybex","CUTIES","Cutie Pops","Curver","CURVE","Curts Salsa","Currie Technologies","Curls Unleashed","Curls","CUREL","CUPCAKE","Culturelle","CULLIGAN","Cuddle Soft","Cuba","CTECH","CTA","CRYSTAL LIGHT","Crystal Farms","Cryptozoic","Cryo-MAX","CRUSH","Crunchy Corn Bran","CRUNCH PAK","CRUNCH 'N MUNCH","Crunch N Munch","Crunch","Crumbs Bake Shop","Crown Crafts Inc.","Cross","CROSLEY","CROCS","CROCODILE CREEK","Crock-Pot","Crock Pot","CRISCO","Cricket","CREST","CRESCENT VALLEY","CRESCENT","Crescendo Fitness","CREME OF NATURE","Creed","CREATIVITY FOR KIDS","CreativeWareDNU","Creative Options","Creative Motions","Creative Motion IND","Creative Converting","Creative Bioscience","CREATIVE BATH","CREATIVE","Creation","Create a Meal","Crckt","Crazy Creek Products","Cra-Z-Loom","Cra-Z-Art","CRAYOLA","Crave","CRANIUM","CRANE","Craftabelle","CRACKER BARREL","Covermate","COVERGIRL Queen","COVERGIRL Perfect","COVERGIRL Lip Perfection","COVERGIRL LashBlast","COVERGIRL","COVER GIRL","Couture","COUNTRY TIME","COUNTRY CROCK","Country Cabin","Coty","COTTONELLE","Cotton Tale","COTTON BUDS","Costume National","COSMI","COSCO","CORTIZONE-10","CORONA","CORNINGWARE","CORN FLAKES","CORELLE","Core Distribution","Core","Coppola","COPPERTONE","COPCO","Copag","Coors Light","COORS","Cooper Classics","Cool Whip","Cool Water","Cooks Sparkling","COOK'S","Cooking Light","COOKIE CRISP","Converse One Star","Converse","CONVENIENCE","Control Brand","Contour","Continental Metallic","Continental Candle","Contigo","Contents","CONTADINA","Constellation Brands","Connoisseurs","Connect 2 Play","Concord Foods","CONCORD","CONCHA Y TORO FRNTRA","Concha Nacar","Concepts","Concept One","Conazol","Conair YOU","Conair True Glow","Conair Hype","CONAIR","CONAGRA","COMSTOCK","COMPOUND W","Completely Bare","Complete","Competitor","CompendiumDNU","Compendium","COMPASS","Comotomo","CommuteMate","COMMUNITY","COMFORT PRODUCTS","Comfort & Harmony","COMET","COMBI","COMBAT","COLUMBUS","Columbian","Coloud","Colorbok","Color Oops","Color Case","COLLEGE INN","Collection","COLGIN","Colgate Kids","COLGATE","COLEMAN","COLAVITA","COKEM","Coke Zero","COINTREAU","Coffique","Coffee-Mate","Coffee Shop","Cocoon","COCOA PUFFS","COCO REAL","CoCaLo","Coca-Cola","Coby","CobraCo","Cobblestone Bread","Coach","Cluedo","CLUE","Club","CLR","Cloud B","Cloud 9","CLOSE-UP","CLOSETMAID","CLOS DU BOIS","Clorox 2","CLOROX","Clinique","CLINERE","C-Line","CLIFFORD","Clif Zbar","Clif Shot","Clif Bar","CLIF","CLICK CLACK","Clever Birds","Clek","CLEARBLUE","CLEARASIL","CLEAR EYES","CLEAR CARE","Clear","Clean WaterDNU","Clean Water","CLEAN & CLEAR","Clean","CLAUSSEN","CLASSY KID","Classroom","CLASSICO","CLASSIC ACCESSORIES","Classic","Clarity","Claritin","CLARINS","Clairol Nice 'N Easy","CLAIROL","Claim Jumper","City of London","City Interactive","CITRUS MAGIC","CITRUCEL","CITRACAL","CIROC","Circulon","CIRCO","Circle Glass","CINNABON","CINN TOAST CRUNCH","Cicatricure","Ciao! Baby","CHUPA CHUPS","CHUNG'S","Chuggington","CHUCK IT TOYS","CHROME","Christine Darvin","Christian Dior","CHRISTIAN AUDIGIER","Chopard","CHOLULA","ChoiceMMEd","CHOBANI","CHLORTRIMETON","Chloe Dao","CHLOE","CHIPS AHOY!","Chipotle","CHINET","CHINA BOY","Child to Cherish","Child Craft","Chikara","CHICKEN OF THE SEA","CHICKEN IN A BISCUT","CHI-CHI'S","CHICCO","ChicBuds","Chicago Skates","Chicago Metallic","CHICAGO CUTLERY","Chicago","CHIC","CHI","CHEX MIX","CHEX","CHESTER'S","Chesapeake Bay","CHERRYBROOK KITCHEN","CHEROKEE UNIFORMS","CHEROKEE","Cherish","CHEF'S PLANET","CHEF'S CHOICE","CHEFS","CHEF'N","CHEFMATE","CHEF SPECIALTIES","CHEF BOYARDEE","CHEETOS","CHEERIOS","CHEER","Chateau Ste Michelle","CHATEAU ST JEAN","CHARMS","CHARMIN","Charlie Banana","CHARLIE","Charcoal Companion","Char-broil","CHAPSTICK","Chantal Thomass","Chantal","Chamberlain Group","CF","CETAPHIL","CERTIFIED INTERNATIO","CeraVe","CEPACOL","Century","CENTRUM","CENTRAL SOUTH DIST.","CELINE DION","Celestron","CELESTIAL SEASONINGS","CELESTIAL","CELESTE","Celebrate Express","CCA and B","CAZADORES","CAVIT","Cavalli","Catskill Craftsmen I","Cathy's Concepts","Caterpillar","Cat Cora","CAT CHOW","Castle Hill","CASIO","Case Scenario","CASE LOGIC","CASE IT","Casdon Toys","CASCADIAN FARM","CASCADIAN","CASCADE","Casabella","CARY'S","Carven","Cartier","Carters","CARROM","Carrera","Caron","CAROLINA PAD","Carolina Herrera DNU","Carolina Herrera","CAROLINA","Carnation","CARMEX","CARLTON","CARLSON","Carlos Santana","Carlo Corinto","Caribou","CARGILL","Carex","CARESS","Careplay","Caremail","CAREFREE","CARE BEAR","CardioChek","CARDINI","Cardinal Industries","CARDINAL","Caravan Global","CARAPELLI","Cara B Naturally","Cara","CAPTAIN MORGAN","Capsule by Cara","Caprice","CAPRI SUN","Cap'n Crunch","Capello","Capelli","CAPE COD","Capcom","CANTU","CANON","CANDYRIFIC","CANDIES","Canadian Mist","CANADA DRY","Can Can","Campho-Phenique","Campbell's","Camp Chef","Camille Rose Natural","CAMERONS","Camelbak","Camden Market","Cambridge Silversmit","Cambridge Limited","CAMBRIDGE","Calvin Klein","CALTRATE","Calphalon","Callaway Golf","CALIFORNIA SCENTS","CALIFORNIA PIZZA KIT","CALIFORNIA BABY","CALIFORNIA","Calico Critters","Calego","CALDREA","Calbee","Cal Pizza GC","Cafejo","Caesar's World","Caesars","Cadie","CADBURY","Cacharel","CABOT","Caboodles","Cabbage Patch Kids","C9 Non-Royalty","C9 By Champion","C.R. Gibson","C&H","C Line","Byblos","Bvlgari","Buzz Bee","Buyseasons","BuyCostumes","Butterfinger","BUTTERBALL","Butt Naked Baby","BUSTELO","BUSH'S","BUSHNELL","BUSCH LIGHT","BUSCH","Burt's Bees Baby","BURT'S BEES","Burnes","BURBERRY","Bunn","Bumkins","BumGenius","Bumbo","BUMBLE BEE","BUMBLE AND BUMBLE","Bum Genius","BULLSEYE","Bulk produce","Buitoni","Built NY","BUILT","Buffalo Wild Wings","Buffalo Puzzles","BUFFALO","BUENO","Budweiser","Buddy Biscuits","Buddy Beds LLC","Bud Light","Bucilla","BubbleBum","Bubble Yum","BUBBLE SHACK","Bubble Guppies","BUBBA","Brushpoint","Brush Buddies","BRUMMEL & BROWN","Brumby","BRUCE'S","BROWNBERRY","BROTHER","Brookstone","Broncolin","Broil King","BROADWAY NAILS","BRITNEY SPEARS","Britestar","Brite Brush","BRITAX","BRITA","BRINKMANN","Brinker Services Cor","BRILLO","Brik-A-Blok","BRIGHT STARTS","Bridgestone Golf","BRIDGESTONE","Brica","BRIARPATCH","BRIANNAS","Breyer's Ice Cream","Brewster","Brenthaven","BREEZE","BREATHE RIGHT","BreathableBaby","BREAKWATER","BREADMAN","BRAWNY","Bravo Sports","BRAVO","Braven","BRAVADO","BRAUN","Bratzillaz","BRATZ","BRASWELL'S","Brand 44","Brainerd","Braava","BOUNTY","Bounceland","BOUNCE","BOULEVARD","BOUDREAUX","Boucheron","Bouche Baby","Botanics","BOSTON WAREHOUSE","Boston Traveler","BOSTON MARKET","BOSTON","Bostitch","BOSSA NOVA","Boss","Bosmere","BOSE","BORN FREE","BORMIOLI ROCCO","Borghese","Borax","Boppy","Boots No7","Boots Extracts","Boots Expert","Boots Champneys","Boots Botanics","BOOTS & BARKLEY","Boots","BOOST MOBILE","BOOST","BOON","Boomwhacker","Boombotix","Boogie Wipes","BONNE MAMAN","Bonjour","BOND","Bonavita","Bona","BOMBAY","Bolthouse Farms","Bojeux","Boise","Boho Boutique","BOGLE VINEYARDS","BogeyPro","Bogart","BodyMedia","Bodycology","Body Solid","Body Innovations","Body Flex","Body Essentials","Body Champ","BODUM","BODDINGTONS","Bocasa","BOB'S REDMILL","Bobs Big Boy","BOBOLI","Bobble","Boba","Bob Mackie","BOB","BOARD DUDES","Bo Bunny","Blueprint","Blueflex","BlueFlame","BlueAir","BLUE SKY","BLUE MOON","BLUE MAGIC","Blue Hills Studio","Blue Handworks","BLUE DIAMOND","Blue Crane","Blue Bonnet","Blue Bell","Blue","BluDot","Blu","BLOW POPS","Blossom Concepts","Blooming Bath","Bloem","Block Financial","Blizzard Entertainme","BLISTEX","BLINK","Blingles","BlendTec","Bleacher CreaturesMF","Blast Zone","Blanqi","Blake's","Blackberry","Black Pearls","BLACK PEARL","Black n' Red","Black Earth","Black & Decker Home","BLACK & DECKER","BIZ","BISSELL","BISQUICK","Birdscapes","BIRDS EYE","BirdieBall","Biotene","Biosilk","Biore","Bio-Oil","BIOLAGE","Biofresh","Bio Oil","Binatone","BIMBO","Billy Boy","Bill Blass","Bill Bailey","Bikini Zone","Bijan","BigTime Muscle","BIGELOW","Big TIme Splash","Big Slice","Big Sexy","Big Mouth Toys","Biddeford Blankets","BICYCLE","Bic","BIALETTI","BIA Cordon Bleu","BEYOND OPTICS","Beyond Bare by Barely There","Beyond Bare","Beyonce","BEYBLADE","Bey Blade","BETTY CROCKER","BETTERN PB","Better Than!","BETTER THAN BUILLION","Better Oats","Betsey Johnson","Bethesda","Bethany Housewares","Bethany House","Best-Lock","BEST FOODS","BERTOLLI","Berndes","BERINGER","Berghoff","Bergers","BENGAY","Benetton","BENEFUL","BENEFIBER","BENADRYL","BEN10","BEN & JERRYS","Bem Wireless","BellyBra","Belly Bandit","Belly Armor","Belloccio","Belle Hop","BELLE CHEVRE","Bella Sun Luci","BELLA SERA","BELLA DNU","Bella","BELL HOWELL","BELL","Belkin","Believe","Belgioioso","Bel Air Lighting","BeKoool","Behringer","Bedtime Originals","Bedoyecta","BED HEAD","Bed Buddy","BECK'S","bebe-jou","Bebe au Lait","BEBE","BEAVER","Beautyko","Beauty Chic","Beauty by Bali","Beautiful","Beats Music","Beats by Dre","BEATS by Dr. Dre","BeaterBlade","BEAR NAKED","BEAR CREEK","Bear Archery","BeanSafe","BEANO","Beaba","Be Maternity","BE","Bazzill","BAYS","Bayou Classic","Bayou","BAYER","BAUSCH & LOMB","Baum Bros.","Bauducco","BattroBorg","BATTLESHIP","Battle Machines","BATMAN","BATCH 19","Bass Pro","BASS","Basics","BASIC 4","Bar-S","Barqs","Barnes & Noble","BARKEEPERS FRIEND","Bark Thins","BARILLA","BARGOOSE","BAREFOOT","BARBIE","Barbara's Bakery","Barbar","Banzai","Banquet","Bankers Box","Bango","Bandana Bowl","Band-Aid","Bandai","Bananagrams","Bananafish","Banana Boat","BAN","Bamboo by Journee","Bamboo","Bambino Mio","Balta Rugs","Balneol","Balmain","BALLATORE","Ball Park","BALL","Bali Essentials","Bali","Balboa Baby","BALANCE BAR","Baker's Secret","BAKER'S","BakerEze","Bagel Bites","BAG TO NATURE","Badia","Badger Basket","BADEN","Bactrack","Backyard Safari","BACK TO BASICS","Back Booster","Bachmann Industries","Bacati","BACARDI","BabyPlus","Babyliss","Babyletto","BABYGANICS","Babybonkie","BABYBJORN","Baby Vision","BABY TREND","Baby Orajel","Baby Mum-Mum","Baby Magic","Baby Ktan","Baby Jogger","Baby Genius","Baby Essentials","BABY EINSTEIN","Baby Delight","Baby Chef","Baby Cargo","Baby Brezza","Baby Bottle Pop","BABY BJORN","Baby Aspen","BABY ALIVE","B.toys","B.","Azzaro","AZO","AXIUS","Axis International","AXE","AVOMEX","AVERY","Avent","Avengers","Avena","Aveeno","AVANTI","AVALON","AutoChron","Auto Expressions","Authentique Paper","AUSTRALIAN GOLD","Aussie","AU'SOME CANDIES","AURORA","AURO by Goldtoe","Auro","Audiovox","Attends","Atopalm","Atlus","Atlantic","ATKINS","ATI","ATHome","ATHENOS","ATARI","AT&T","Asus","ASTV","ASTROGLIDE","Assurant Solutions","Assets-Sara Blakely","ASSETS by Sara Blakely","Assets","ASPEN Pet","Ashtel","AS SEEN ON TV","As I Am","Artskills","Artscape","Artland","Artistic","ARTISANDNU","Artisan Bistro","Artisan","Art.com","Art Bin","Arrowhead","Arrow","Arrogant Bastard","ARRID","Aroma","ARNOLD","Arm's Reach Co-Sleep","ARM'S REACH CONCEPTS","Armour Star","ARMOUR","Armor All","ARMITRON","ARMANI","Armand Basi","ARM & HAMMER","ARLEE HOME FASHIONS","ARIZONA","ARIEL","ARDELL","Arctic Zone","ARCTIC","ARCHWAY","ARCHOS","ARCHITECTURAL MAILBO","Architec","ARCHER FARMS","Archer","Arcade Alley","Aramis","Arachnid","Aquolina","Aquatopia","AquaSense","Aquaphor","AQUANET","AQUAFRESH","Aquafina","Aquadoodle","Aptations","Apptivity","Applied Nutrition","APPLEGATE FARMS","Applebees GC","APPLE JACKS","APPLE & EVE","Apple","Appalachian","Apotheke:M","Apotheke M","Apotheke","Apothecary","Apollo Tools","APOLLO","Apex","Antonio Puig","Antonio Banderas","Anova Medical","Anorak","Annoying Orange","ANNIN","ANNIE'S","Annies","Annie Chuns","Annick Goutal","Anne Michelle","Anna Grifin","ANNA GRIFFIN","Animale","ANIMAL PLANET","Angry Birds","ANGIE'S KETTLE CORN","Angies","AngelCare","Angel Soft","Angel Schlesser","Angel","Anfora","Android","ANDIS","ANDES","Anchor Bay","ANCHOR","Anais Anais","Amys","Amstel Light","AMPRO","AMPLIFY","Ampad","AmLactin","Amisco","Amie et Moi","AMG Medical","AMES","Amerock","American Weigh Scale","AMERICAN TOURISTER","AMERICAN RED CROSS","American Plastic Toy","AMERICAN LICORICE","American Lawn Mower","AMERICAN GREETINGS","American Crew","American Crafts","American Athletic, I","American Atelier","AMERICAN","Ameda","Amco","AMBI","Ambar","Amazonia","ALWAYS","Aluratek","ALTOIDS","Alps International","ALPO","ALPINE","ALPENROSE","Alouette","ALOHA","Almond Joy","Almay Smart Shade","Almay Oil Free","ALMAY","Allstar","Allsop","Alliance","Allerease","Allegro","Allegra","AllClear","ALL THINGS EQUAL","All Pro","All is Bright","All for Paws","All","Alka Seltzer","Alive","Align","Alfred Sung","Alfred Dunhill","Alexia","Alexandra De Markoff","Alex Toys","Alex","ALEVE","ALESSI","Alen","Alder Creek Gifts","Alcohawk","ALBA","ALAVERT","AlaskanNits","Alaskan nits","ALASKAN","ALADDIN","Aksys","AKC","AJIMIRAN","AJAX","Airzone","Airwick","Airwalk","Air-O-Swiss","AIRHEADS","Airhead","AIRBORNE","AIRBAKE","Air Storm","Air Hogs","AIM","Aidells","Ahava","AGENT 18","Agadir","AFRICAS BEST","African Royale","AFG","Affresh","Aerosoles","Aerobed","Aero Minerale","AERO","AEG","Advocate","ADVIL","Adventure Playsets","Adventure Medic Kit","ADVANTUS","Advantage SportsRack","ADVANTAGE","Advanced Pure Air","ADORA","Adonit","ADOLPHS","ADMIRAL NELSONS","Adidas","Adi Designs","Adesso","Aden + Anais","Aden & Anais","ADCOR","Activision","Actiontec","Action Wobble","Action Top","Action Shot","Action Electronics","ACT","ACNE FREE","ACME","Aceto","Acer","Ace Bayou","Accudart","ACCU-CHEK","Accoutrements","Acco","Accent Trends","ACCENT","ABREVA","Able Planet","AAXA Technologies","AAA","A2 by Aerosoles","A.1.","A&W","A&D","3D White");
		if($content2=~m/<h[^>]*?>\s*Sorry[^>]*?find[^>]*?</is)
		{
			goto MP;
		}
		#product_id
		# if ($content2=~m/"partNumber"\s*:\s*"([^>"]*?)"/is)
		if ($url3=~m/\/\-\/A-([^>]*?)\s*$/is)
		{
			$product_id = &Trim($1);
			my $ckproduct_id = &DBIL::UpdateProducthasTag($product_id, $product_object_key,$dbh,$robotname,$retailer_id);
			goto LAST if($ckproduct_id == 1);
			undef ($ckproduct_id);
		}
		#product_name
		if ( $content2 =~ m/<h2[^>]*?class="product-name[^>]*?"[^>]*?>\s*([\w\W]*?)\s*<\/h2>/is)
		{
			$product_name = $1;
			$product_name=~s/<[^>]*?>/ /igs;
			$product_name=~s/\s+/ /igs;
			$product_name=~s/^\s+//is;
			$product_name=~s/\s+$//is;
			$product_name=~s/\&reg\;//is;
			$description=' ';
			$prod_detail=' ';
		}
		$product_name=decode_entities($product_name);
		# utf8::decode($product_name);
		$product_name=~s/Â//gs;
		$product_name=~s/\Â//gs;
		$product_name=~s/\¨//gs;
		$product_name=~s/(?:\n|\r|\t|\h|\v)+/ /gs;
		$product_name=~s/\s+/ /igs;
		$product_name=~s/^\s+//is;
		$product_name=~s/\s+$//is;
		#Description
		if ( $content2 =~ m/<span[^>]*?itemprop="description"[^>]*?>\s*([\w\W]*?)\s*<\/span>\s*<\/p>/is )
		{
			$description = &Trim($1);
		}
		#Product_Detail
		if ( $content2 =~ m/<ul[^>]*?class="[^>]*?innerlistings"[^>]*?>\s*([\w\W]*?)\s*<\/ul>/is )
		{
			$prod_detail = $1;
			$prod_detail =~s/<li[^>]*?>/ * /igs;
			$prod_detail=&Trim($prod_detail);
		}
		$description=decode_entities($description);
		#utf8::decode($description);
		$description=~s/Â//gs;
		$description=~s/\Â//gs;
		$prod_detail=decode_entities($prod_detail);
		#utf8::decode($prod_detail);
		$prod_detail=~s/Â//gs;
		$prod_detail=~s/\Â//gs;
		#Brand
		if ($content2 =~ m/<input[^>]*?id="omni_brand_name"[^>]*?value="\s*([^>]*?)\s*"[^>]*?>/is)
		{
			$brand = $1;
			$brand=~s/^\s+//is;
			$brand=~s/\s+$//is;
		}
		$brand=decode_entities($brand);
		# utf8::decode($brand);
		$brand=~s/Â//gs;
		$brand=~s/\Â//gs;
		if($brand=~m/^\s*$/is)
		{
			foreach my $brand_val(@brands)
			{
				if($product_name=~m/^\s*(\Q$brand_val\E)\s+/is)
				{
					$brand = $1;
					last;
				}
				elsif($product_name=~m/\s+(\Q$brand_val\E)\s+/is)
				{
					$brand = $1;
					last;
				}
				elsif($product_name=~m/\s+(\Q$brand_val\E)\s*$/is)
				{
					$brand = $1;
					last;
				}
			}
		}
		$brand=~s/^\s+//is;
		$brand=~s/\s+$//is;
		if($content2=~m/<div[^>]*?class="viewFullDetails"[^>]*?>\s*<a[^>]*?href=["'][^>]*?["'][^>]*?>\s*view\s*full\s*item\s*detail/is)
		{
			$mflag = 1;
			goto MP;
		}
		if ($content2=~m/itemprop="(?:low)?price"[^>]*?>\s*(?!\{)(?:\$)?([^>]*?)\s*</is)
		{
			$price=$1;
			$price=~s/[^\d\.]//gs;
		}
		#Price & Price Text
		if ($content2 =~m/<div[^>]*?id="price_main"[^>]*?>\s*([\w\W]*?)\s*<\/div>\s*<div[^>]*?id="outOfStock/is)
		{
			$price_text=$1;
			$price_text=~s/<span[^>]*?class="screen-reader-only"[^>]*?>[^>]*?<\/span>/ /igs;
			$price_text=~s/<span[^>]*?>\s*(?:Store|Online)\s*Price\s*<\/span>//igs;
			# $price_text =~ s/\&euro\;/€/ig;
			$price_text = &Trim($price_text);
			$price_text=~s/\s*(?:Online|Store)\s*Price//igs;
			$price_text=~s/\s+/ /igs;
			$price_text=~s/^\s+//is;
			$price_text=~s/\s+$//is;
		}
		$price_text=decode_entities($price_text);
		#utf8::decode($price_text);
		$price_text=~s/Â//gs;
		$price_text=~s/\Â//gs;
		$price_text =~s/á//igs;
		$price_text=~s/^\s*(?:\n|\r|\t|\h|\v)//s;
		$price="NULL" if($price=~m/^\s*$/is);
		
		
		# size & out_of_stock
		my $color_count=0;
		my (@colorpartnum_arr);
		my $swatch_color=1;
		if($content2=~m/<li[^>]*?class="swatchtool"[^>]*?>\s*<input[^>]*?(?:src="[^>"]*?\/[^"\/]*?"[^>]*?)?value="\s*[^>"]*?\s*"[^>]*?>\s*<img[^>]*?src="[^>"]*?"/is)
		{
			while($content2=~m/<li[^>]*?class="swatchtool"[^>]*?>\s*<input[^>]*?(?:src="[^>"]*?\/([^"\/]*?)"[^>]*?)?value="\s*([^>"]*?)\s*"[^>]*?>\s*<img[^>]*?src="[^>"]*?"/igs)
			{
				my $color_partnum=$1;
				my $color_name=$2;			
				$color_partnum=~s/^\s*(\d+)(?:_[^>]*?|\.[^>]*?)$/$1/is;
				++$color_count;
				my $colorpart_plus_name=$color_partnum.'<br>'.$color_name;
				push(@colorpartnum_arr,$colorpart_plus_name);
			}
		}	
		elsif($content2=~m/<option[^>]*?id="COLOR"[^>]*?selected[^>]*?>[^>]*?<\/option>/is)
		{
			$swatch_color=0;
		}	
		my $itemblock;
		if($content2=~m/<script[^>]*?>\s*Target\.globals\.refreshItems\s*=\s*([\w\W]*?)<\/script>/is)
		{
			$itemblock=$1;
		}
		$itemblock=~s/("Attributes"\s*\:\s*{)/\^$1/igs;
		$itemblock=~s/(\,\s*"productId"\s*:\s*"[^"]*?")/$1\^/igs;
		if($content2 =~m/<div[^>]*?id="entitledItem"[^>]*?>([\w\W]*?)<\/div>/is)
		{
			my $size_content = $1;
			if($size_content=~m/"catentry_id"\s*:\s*"[^\}"]*?"\s*\,\s*"Attribute[^"]*?"\s*\:\s*\{[^\}]*?\}/is)
			{
				while($size_content=~m/"catentry_id"\s*:\s*"([^\}"]*?)"\s*\,\s*"Attribute[^"]*?"\s*\:\s*(\{[^\}]*?\})/igs)
				{
					my $catentry_id=$1;
					my $atrribut_blk=$2;
					my ($color,$size);
					my $out_of_stock='n';
					if($atrribut_blk=~m/"color\s*:\s*([^\}]*?)"\s*\:\s*"[^>"]*?"\s*,\s*"size\s*:\s*([^\}]*?)"\s*:\s*"[^>"]*?"/is)
					{
						$color=&Trim($1);
						$size=&Trim($2);	
						if($swatch_color==0)
						{
							if($content2=~m/\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"[^\{\}]*?"Attributes"\s*\:\s*\{\s*[^\{\}]*?"partNumber"\s*\:\s*"([^>"]*?)"/is)
							{
								my $colorpart_plus_name=$1.'<br>'.$color;
								push(@colorpartnum_arr,$colorpart_plus_name);
								++$color_count;
							}
						}												
						# if($content2=~m/"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"Channel"\s*:\s*"([^>"]*?)"/is)
						# {
							# my $channel_code=$1;
							# if($channel_code=~m/\s*Not\s*sold[^>]*?online/is)
							# {
								# $out_of_stock='y';
							# }
							# elsif($content2=~m/(\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"productId[\w\W]*?"\s*\}\s*\})/is)
							# {
								# my $channel_blk=$1;
								# my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
								# if($stat=~m/on\s*backorder/is)
								# {
									# $out_of_stock='y';
								# }
								# elsif($stat eq '')
								# {
									# $out_of_stock='y';
								# }
							# }
						# }	
						if($content2=~m/(\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"productId[\w\W]*?"\s*\}\s*\})/is)
						{
							my $channel_blk=$1;
							my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
							if($stat=~m/on\s*backorder/is)
							{
								$out_of_stock='y';
							}
							elsif($stat=~m/^\s*$/is)
							{
								$out_of_stock='y';
							}
							if(($channel_blk=~m/"price_vary_store"\s*:\s*"true"/is) && ($channel_blk=~m/"offer"\s*:\s*"true"/is) && ($channel_blk=~m/"list"\s*:\s*"true"/is) && ($channel_blk=~m/"eyebrow"\s*:\s*"true"/is) && ($channel_blk=~m/"savestory"\s*:\s*"true"/is))
							{
								my ($current_price,$regular_price);
								if($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>]*?)"\s*\,\s*"list"\s*:\s*"([^>]*?)"/is)
								{
									$current_price=$1; 
									$regular_price='reg: '.$2;
								}
								my $eyebrow_val=$1 if($channel_blk=~m/"eyebrowVal"\s*:\s*"([^>"]*?)"/is);
								my $savetext_val=$1 if($channel_blk=~m/"save_text"\s*:\s*"([^>"]*?)"/is);
								my $newprice_text=$current_price.' '.$eyebrow_val.' '.$regular_price.' '.$savetext_val;	
								$newprice_text=&Trim($newprice_text);
								my $new_price=$current_price;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
								#$price_text=$newprice_text;
							}
							elsif($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>"]+?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
							elsif($channel_blk=~m/"formattedOfferPrice"\s*:\s*"\$?([^>"]*?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
						}
						elsif($itemblock=~m/\^\s*"Attributes"([^\^]*?)"catentry_id"\s*:\s*"\Q$catentry_id\E"/is)
						{
							my $channel_blk=$1;
							my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
							if($stat=~m/on\s*backorder/is)
							{
								$out_of_stock='y';
							}
							elsif($stat=~m/^\s*$/is)
							{
								$out_of_stock='y';
							}
							if(($channel_blk=~m/"price_vary_store"\s*:\s*"true"/is) && ($channel_blk=~m/"offer"\s*:\s*"true"/is) && ($channel_blk=~m/"list"\s*:\s*"true"/is) && ($channel_blk=~m/"eyebrow"\s*:\s*"true"/is) && ($channel_blk=~m/"savestory"\s*:\s*"true"/is))
							{
								my ($current_price,$regular_price);
								if($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>]*?)"\s*\,\s*"list"\s*:\s*"([^>]*?)"/is)
								{
									$current_price=$1; 
									$regular_price='reg: '.$2;
								}
								my $eyebrow_val=$1 if($channel_blk=~m/"eyebrowVal"\s*:\s*"([^>"]*?)"/is);
								my $savetext_val=$1 if($channel_blk=~m/"save_text"\s*:\s*"([^>"]*?)"/is);
								my $newprice_text=$current_price.' '.$eyebrow_val.' '.$regular_price.' '.$savetext_val;	
								$newprice_text=&Trim($newprice_text);
								my $new_price=$current_price;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
								#$price_text=$newprice_text;
							}
							elsif($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>"]+?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
							elsif($channel_blk=~m/"formattedOfferPrice"\s*:\s*"\$?([^>"]*?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
						}
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
						#print "\n------------c: $color";
					}
					elsif($atrribut_blk=~m/"color\s*:\s*([^\}]*?)"\s*\:\s*"\d+"\s*/is)
					{
						$color=&Trim($1);
						if($swatch_color==0)
						{
							if($content2=~m/\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"[^\{\}]*?"Attributes"\s*\:\s*\{\s*[^\{\}]*?"partNumber"\s*\:\s*"([^>"]*?)"/is)
							{
								my $colorpart_plus_name=$1.'<br>'.$color;
								push(@colorpartnum_arr,$colorpart_plus_name);
								++$color_count;
							}
						}
						# if($content2=~m/"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"Channel"\s*:\s*"([^>"]*?)"/is)
						# {
							# my $channel_code=$1;
							# if($channel_code=~m/\s*Not\s*sold[^>]*?online/is)
							# {
								# $out_of_stock='y';
							# }
							# elsif($content2=~m/(\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"productId[\w\W]*?"\s*\}\s*\})/is)
							# {
								# my $channel_blk=$1;
								# my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
								# if($stat=~m/on\s*backorder/is)
								# {
									# $out_of_stock='y';
								# }
								# elsif($stat eq '')
								# {
									# $out_of_stock='y';
								# }
							# }
						# }
						if($content2=~m/(\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"productId[\w\W]*?"\s*\}\s*\})/is)
						{
							my $channel_blk=$1;
							my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
							if($stat=~m/on\s*backorder/is)
							{
								$out_of_stock='y';
							}
							elsif($stat=~m/^\s*$/is)
							{
								$out_of_stock='y';
							}
							if(($channel_blk=~m/"price_vary_store"\s*:\s*"true"/is) && ($channel_blk=~m/"offer"\s*:\s*"true"/is) && ($channel_blk=~m/"list"\s*:\s*"true"/is) && ($channel_blk=~m/"eyebrow"\s*:\s*"true"/is) && ($channel_blk=~m/"savestory"\s*:\s*"true"/is))
							{
								my ($current_price,$regular_price);
								if($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>]*?)"\s*\,\s*"list"\s*:\s*"([^>]*?)"/is)
								{
									$current_price=$1; 
									$regular_price='reg: '.$2;
								}
								my $eyebrow_val=$1 if($channel_blk=~m/"eyebrowVal"\s*:\s*"([^>"]*?)"/is);
								my $savetext_val=$1 if($channel_blk=~m/"save_text"\s*:\s*"([^>"]*?)"/is);
								my $newprice_text=$current_price.' '.$eyebrow_val.' '.$regular_price.' '.$savetext_val;	
								$newprice_text=&Trim($newprice_text);
								my $new_price=$current_price;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
								#$price_text=$newprice_text;
							}
							elsif($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>"]+?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
							elsif($channel_blk=~m/"formattedOfferPrice"\s*:\s*"\$?([^>"]*?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
						}
						elsif($itemblock=~m/\^\s*"Attributes"([^\^]*?)"catentry_id"\s*:\s*"\Q$catentry_id\E"/is)
						{
							my $channel_blk=$1;
							my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
							if($stat=~m/on\s*backorder/is)
							{
								$out_of_stock='y';
							}
							elsif($stat=~m/^\s*$/is)
							{
								$out_of_stock='y';
							}
							if(($channel_blk=~m/"price_vary_store"\s*:\s*"true"/is) && ($channel_blk=~m/"offer"\s*:\s*"true"/is) && ($channel_blk=~m/"list"\s*:\s*"true"/is) && ($channel_blk=~m/"eyebrow"\s*:\s*"true"/is) && ($channel_blk=~m/"savestory"\s*:\s*"true"/is))
							{
								my ($current_price,$regular_price);
								if($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>]*?)"\s*\,\s*"list"\s*:\s*"([^>]*?)"/is)
								{
									$current_price=$1; 
									$regular_price='reg: '.$2;
								}
								my $eyebrow_val=$1 if($channel_blk=~m/"eyebrowVal"\s*:\s*"([^>"]*?)"/is);
								my $savetext_val=$1 if($channel_blk=~m/"save_text"\s*:\s*"([^>"]*?)"/is);
								my $newprice_text=$current_price.' '.$eyebrow_val.' '.$regular_price.' '.$savetext_val;	
								$newprice_text=&Trim($newprice_text);
								my $new_price=$current_price;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
								#$price_text=$newprice_text;
							}
							elsif($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>"]+?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
							elsif($channel_blk=~m/"formattedOfferPrice"\s*:\s*"\$?([^>"]*?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
						}
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,$color,$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}=$color;
					}
					elsif($atrribut_blk=~m/"size\s*:\s*([^\}]*?)"\s*:\s*"\d+"/is)
					{
						$size=&Trim($1);
						# if($content2=~m/"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"Channel"\s*:\s*"([^>"]*?)"/is)
						# {
							# my $channel_code=$1;
							# if($channel_code=~m/\s*Not\s*sold[^>]*?online/is)
							# {
								# $out_of_stock='y';
							# }
							# elsif($content2=~m/(\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"productId[\w\W]*?"\s*\}\s*\})/is)
							# {
								# my $channel_blk=$1;
								# my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
								# if($stat=~m/on\s*backorder/is)
								# {
									# $out_of_stock='y';
								# }
								# elsif($stat eq '')
								# {
									# $out_of_stock='y';
								# }
							# }
						# }
						if($content2=~m/(\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"productId[\w\W]*?"\s*\}\s*\})/is)
						{
							my $channel_blk=$1;
							my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
							if($stat=~m/on\s*backorder/is)
							{
								$out_of_stock='y';
							}
							elsif($stat=~m/^\s*$/is)
							{
								$out_of_stock='y';
							}
							if(($channel_blk=~m/"price_vary_store"\s*:\s*"true"/is) && ($channel_blk=~m/"offer"\s*:\s*"true"/is) && ($channel_blk=~m/"list"\s*:\s*"true"/is) && ($channel_blk=~m/"eyebrow"\s*:\s*"true"/is) && ($channel_blk=~m/"savestory"\s*:\s*"true"/is))
							{
								my ($current_price,$regular_price);
								if($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>]*?)"\s*\,\s*"list"\s*:\s*"([^>]*?)"/is)
								{
									$current_price=$1; 
									$regular_price='reg: '.$2;
								}
								my $eyebrow_val=$1 if($channel_blk=~m/"eyebrowVal"\s*:\s*"([^>"]*?)"/is);
								my $savetext_val=$1 if($channel_blk=~m/"save_text"\s*:\s*"([^>"]*?)"/is);
								my $newprice_text=$current_price.' '.$eyebrow_val.' '.$regular_price.' '.$savetext_val;	
								$newprice_text=&Trim($newprice_text);
								my $new_price=$current_price;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
								#$price_text=$newprice_text;
							}
							elsif($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>"]+?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
							elsif($channel_blk=~m/"formattedOfferPrice"\s*:\s*"\$?([^>"]*?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
						}
						elsif($itemblock=~m/\^\s*"Attributes"([^\^]*?)"catentry_id"\s*:\s*"\Q$catentry_id\E"/is)
						{
							my $channel_blk=$1;
							my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
							if($stat=~m/on\s*backorder/is)
							{
								$out_of_stock='y';
							}
							elsif($stat=~m/^\s*$/is)
							{
								$out_of_stock='y';
							}
							if(($channel_blk=~m/"price_vary_store"\s*:\s*"true"/is) && ($channel_blk=~m/"offer"\s*:\s*"true"/is) && ($channel_blk=~m/"list"\s*:\s*"true"/is) && ($channel_blk=~m/"eyebrow"\s*:\s*"true"/is) && ($channel_blk=~m/"savestory"\s*:\s*"true"/is))
							{
								my ($current_price,$regular_price);
								if($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>]*?)"\s*\,\s*"list"\s*:\s*"([^>]*?)"/is)
								{
									$current_price=$1; 
									$regular_price='reg: '.$2;
								}
								my $eyebrow_val=$1 if($channel_blk=~m/"eyebrowVal"\s*:\s*"([^>"]*?)"/is);
								my $savetext_val=$1 if($channel_blk=~m/"save_text"\s*:\s*"([^>"]*?)"/is);
								my $newprice_text=$current_price.' '.$eyebrow_val.' '.$regular_price.' '.$savetext_val;	
								$newprice_text=&Trim($newprice_text);
								my $new_price=$current_price;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
								#$price_text=$newprice_text;
							}
							elsif($channel_blk=~m/"display_type"\s*:\s*"[^>"]*?"\s*\,\s*"offer"\s*:\s*"([^>"]+?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
							elsif($channel_blk=~m/"formattedOfferPrice"\s*:\s*"\$?([^>"]*?)"/is)
							{
								my $new_price=$1;
								$new_price=~s/[^\d\.]//gs;
								$new_price="NULL" if($new_price=~m/^\s*$/is);
								$price=$new_price;
							}
						}
						my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,$size,'no raw colour',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$skuflag = 1 if($flag);
						$sku_objectkey{$sku_object}='no raw colour';
					}
				}
			}
			else
			{
				my $catentry_id=$1 if($content2=~m/<input[^>]*?name="catEntryId"[^>]*?value="\s*([^>"]+?)\s*"[^>]*?>/is);
				my $out_of_stock='n';
				if($content2=~m/(\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"productId[\w\W]*?"\s*\}\s*\})/is)
				{
					my $channel_blk=$1;
					my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
					if($stat=~m/on\s*backorder/is)
					{
						$out_of_stock='y';
					}
					elsif($stat eq '')
					{
						$out_of_stock='y';
					}
				}
				my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'','no raw colour',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$skuflag = 1 if($flag);
				$sku_objectkey{$sku_object}='no raw colour';
			}		
		}	
		else
		{
			my $catentry_id=$1 if($content2=~m/<input[^>]*?name="catEntryId"[^>]*?value="\s*([^>"]+?)\s*"[^>]*?>/is);
			my $out_of_stock='no';
			if($content2=~m/(\{\s*"catentry_id"\s*:\s*"\Q$catentry_id\E"\s*\,\s*"productId[\w\W]*?"\s*\}\s*\})/is)
			{
				my $channel_blk=$1;
				my $stat=$1 if($channel_blk=~m/"status"\s*\:\s*"\s*([^>"]*?)\s*"/is);
				if($stat=~m/on\s*backorder/is)
				{
					$out_of_stock='y';
				}
				elsif($stat eq '')
				{
					$out_of_stock='y';
				}
			}
			my ($sku_object,$flag,$query) = &DBIL::SaveSku($product_object_key,$url3,$product_name,$price,$price_text,'','no raw colour',$out_of_stock,$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			push(@query_string,$query);
			$skuflag = 1 if($flag);
			$sku_objectkey{$sku_object}='no raw colour';
		}
		if($color_count>=1)
		{
			foreach my $color_catid(@colorpartnum_arr)
			{
				if($color_catid=~m/^\s*([^>]*?)\s*<br>\s*([^>]*?)\s*$/is)
				{
					my $color_part_num=$1;
					my $color_name=$2;
					my $image_block;
					if($content2=~m/"\Q$color_part_num\E"\s*:\s*\{\s*[^\}\]]*?"items"\s*:\s*\[\s*(\{[^\]]*?\})\s*\]/is)
					{
						$image_block=$1;
					}
					while($image_block=~m/"Alt(\d\d)"\s*:\s*\{\s*[^\}]*?"altImage"\s*:\s*"([^>\}"]*?)"[^\}]*?\}/igs)
					{
						my $alter_image_val=$1;
						my $alter_image=$2;
						#next if($alter_image_val=~m/^\s*00\s*$/is);
						$alter_image=~s/^[^>]*?\.com\/wcsstore\/TargetSAS\/\s*$//is;
						$alter_image=~s/^\s*http[^>]*?NoImageIcon[^>]*?\.jpg$//is;
						if($alter_image=~m/^\s*http/is)
						{
							if($alter_image_val=~m/^\s*00\s*$/is) #Main Image Extraction
							{
								my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color_name;
								$hash_default_image{$img_object}='y';
							}
							else #Alternate Image Extraction
							{
								my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
								my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
								push(@query_string,$query);
								$imageflag = 1 if($flag);
								$image_objectkey{$img_object}=$color_name;
								$hash_default_image{$img_object}='n';
								#print "\n-------------cn: $color_name";
							}	
						}
					}
				}	
			}	
		}
		else
		{
			#MainImage
			my $main_image;
			if ($content2=~m/<img[^>]*?itemprop="image"[^>]*?src="\/*([^>"]+?)"/is)
			{
				my $imageurl = &Trim($1);
				if($imageurl!~m/^\s*http/is)
				{
					$imageurl='http://Img2.targetimg2.com/'.$imageurl;
				}
				$main_image=$imageurl;

				my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'product',$retailer_name);
				my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
				push(@query_string,$query);
				$imageflag = 1 if($flag);
				$image_objectkey{$img_object}='no raw colour';
				$hash_default_image{$img_object}='y';
			}
			#AltImage
			if($main_image ne '')
			{
				my $image_block;
				if($content2=~m/"\Q$product_id\E"\s*:\s*\{\s*[^\}\]]*?"items"\s*:\s*\[\s*(\{[^\]]*?\})\s*\]/is)
				{
					$image_block=$1;
				}
				elsif($content2=~m/"[^>"]*?"\s*:\s*\{\s*[^\}\]]*?"items"\s*:\s*\[\s*(\{[^\]]*?\})\s*\]/is)
				{
					$image_block=$1;
				}
				while($image_block=~m/"Alt(\d\d)"\s*:\s*\{\s*[^\}]*?"altImage"\s*:\s*"([^>\}"]*?)"[^\}]*?\}/igs)
				{
					my $alter_image_val=$1;
					my $alter_image=$2;
					next if($alter_image_val=~m/^\s*00\s*$/is);
					$alter_image=~s/^[^>]*?\.com\/wcsstore\/TargetSAS\/\s*$//is;
					if($alter_image=~m/^\s*http/is)
					{
						my ($imgid,$img_file) = &DBIL::ImageDownload($alter_image,'product',$retailer_name);
						my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$alter_image,$img_file,'product',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
						push(@query_string,$query);
						$imageflag = 1 if($flag);
						$image_objectkey{$img_object}='no raw colour';
						$hash_default_image{$img_object}='n';
					}
				}
			}
		}		
		#swatch
		# while ($content2=~m/<li[^>]*?class="swatchtool"[^>]*?>\s*<input[^>]*?value="([^>]*?)"[^>]*?>\s*<img[^>]*?src="([^>"]*?)"/igs)
		# {
			# my $image_val=$1;
			# my $imageurl=$2;
			# my ($imgid,$img_file) = &DBIL::ImageDownload($imageurl,'swatch',$retailer_name);
			# my ($img_object,$flag,$query) = &DBIL::SaveImage($imgid,$imageurl,$img_file,'swatch',$dbh,$Retailer_Random_String,$robotname,$excuetionid);
			#push(@query_string,$query);
			# $imageflag = 1 if($flag);
			# $image_objectkey{$img_object}=$image_val;
			# $hash_default_image{$img_object}='n';
		# }
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
		# my $query=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		# push(@query_string,$query); 
		my ($query1,$query2)=&DBIL::UpdateProductDetail($product_object_key,$product_id,$product_name,$brand,$description,$prod_detail,$dbh,$robotname,$excuetionid,$skuflag,$imageflag,$url3,$retailer_id,$mflag);
		push(@query_string,$query1);
		push(@query_string,$query2);
		# my $qry=&DBIL::SaveProductCompleted($product_object_key,$retailer_id);
		# push(@query_string,$qry);
		&DBIL::ExecuteQueryString(\@query_string,$robotname,$dbh);
		LAST:
		print "";
	}
}1;
sub Trim
{
	my $string=shift;
	$string=~s/<[^>]*?>/ /igs;
	$string =~ s/\&nbsp\;/ /gs;
	$string =~ s/^\s*n\/a\s*$//igs;
	$string =~ s/\&\#039\;/'/gs;
	$string =~ s/\&\#43\;/+/gs;
	$string =~ s/amp;//gs;
	$string=~s/\s+/ /igs;
	$string=~s/^\s+//is;
	$string=~s/\s+$//is;
	return($string);
}
sub GetContent($$$$)
{
    my $mainurl=shift;
    my $method=shift;
    my $parameter=shift;
    my $referer=shift;
    my $err_count=0;
    home:
	my $req;
    if($method eq 'POST')
    {     
        $req=HTTP::Request->new($method=>"$mainurl");
		$req->content("$parameter");
    }
	else
	{
		$req=HTTP::Request->new('GET'=>"$mainurl");
	}	
    $req->header("Content-Type"=> "application/x-www-form-urlencoded");
    $req->header("Referer"=> "$referer");

    my $res=$ua->request($req);
    
    $cookie->extract_cookies($res);
    $cookie->save;
    $cookie->add_cookie_header($req);
    
    my $code=$res->code;    
    print "\nCODE :: $code\n";    
    open JJ,">>$retailer_file";
	print JJ "$mainurl->$code\n";
	close JJ;
    if($code=~m/^\s*(?:5|4)/is)
    {
        print "\nNET FAILURE\n";
        print "\nCHECK :: $mainurl\n";
		$err_count++;
		if($err_count<=3)
		{
			sleep(1);
			goto home;	
		}
    }
    elsif($code=~m/20/is)
    {
        my $con=$res->content;   
		if ($con=~ m/<h2[^>]*?class="product-name[^>]*?"[^>]*?>/is)
		{	
			return $con;
		}
        else
		{
			my $req1=HTTP::Request->new('GET'=>"$mainurl");
			$req1->header("Content-Type"=> "application/x-www-form-urlencoded");
			my $res1=$ua->request($req1);
			$cookie->extract_cookies($res1);
			$cookie->save;
			$cookie->add_cookie_header($req1);
			my $con1=$res1->content;
			return $con1;
        } 		
    }
    elsif($code=~m/30/is)
    {
        my $loc=$res->header('location');                
        $loc=decode_entities($loc);    
        my $loc_url=url($loc,$mainurl)->abs;
        print "\nLocation url : $loc_url\n";
        $mainurl=$loc_url;
        goto home;
    }
}