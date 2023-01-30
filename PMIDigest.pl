use strict;
use File::Path;
#use Lingua::EN::Sentence qw( get_sentences add_acronyms );

#
#


my $string_to_STDERR = "\n\nPMIDigest USAGE: perl PMIDigest.pl you_PMIDs_list your_MESH_colors your\@email.com [-v] [your_additional_XML_files] ... >name_it_as_will.html

Commands between square brackets \"[]\" are optional.
Use -v for a more detailed report of the program progress.
For more information of how to run PMIDigest, go to \"README.md\".\n\n
";

#
# Conf stuff
#
my $auxiliar_files_dir = "./auxiliar_files";
my $tmpdir="./tmp/";
my $procid=$$;
my $pmid_dir="./PMIDs/";
my $bindir="./";

my $layoutCutOff = 500;
my $noNetworkCutOff = 3000;
my $defaultLayout = "cose_then_cola";
my $bigLayout = "breadthfirst";
my @preuterms="";

my $netgradient =
"
#436473
#416a79
#3f6f7f
#3c7584
#397b89
#35818d
#328791
#2e8d94
#2c9397
#2a9999
#2a9f9b
#2ca59b
#30ab9c
#36b19b
#3eb69a
#46bc99
#50c297
#5ac795
#65cc92
#70d18f
#7cd68c
#88db88
#95e084
#a2e481
#b0e97d
#beed79
#ccf076
#dbf473
#eaf770
#fafa6e
";



#
# User highlighted terms
#
#my @userterms=("the", "gut barrier", "microbiome");
#my $utermscolor = "#a600ff"; #set the color for user term. Now purple


my $title="PMIDigest papers";
my @pmids;
my %ref; my %title; my %auth; my %abstract; my %date; my %datep;
my %meshids; my %meshidnames; my %citedby; my %icites; my %databank;
my %ptypes; my %ptypel;
my @allmeshids=();

my $nmesh; my @mclass; my @mui; my @mprint; my %mcount; my @mname; my @meshpmids;
my @mtaxid; my @mrr; my @mhierarch;my @mst;

my %utermspmids; my %source;

###Create tmp and PMIDs dir if not existing
if (!(-d $tmpdir)) {
	mkdir($tmpdir) or die "**Couldn't create $tmpdir directory, $!";
}
if (!(-d $pmid_dir)) {
	mkdir($pmid_dir) or die "**Couldn't create $pmid_dir directory, $!";
}

# Options / Maybe remove for CGI (?)
#fverbose 1 makes the script print process information on the shell

my $fverbose=0;
my @lfiles;
my $arg_counter=0;

if (@ARGV.length() < 3) {
	print STDERR "\n**ERROR: Mandatory arguments are missing.";
	print STDERR $string_to_STDERR;
	die;
}

foreach my $arg (@ARGV) {
	if ($arg_counter > 2) {
		if (index($arg, "-")==0) {
			if($arg=~/\-v/) {$fverbose=1;}
		} else {
			push(@lfiles, $arg);
		}
	}
	$arg_counter+=1;
}


my $PMIDs_file = $ARGV[0];
my $conf_file = $ARGV[1];
my $email = $ARGV[2];

if (!($email =~/^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})$/)) {
	print STDERR "\n**ERROR, invalid email adress: $email\n";
	print STDERR $string_to_STDERR;
	exit;
	}

if($fverbose==1){print STDERR "\n\n";}

open(input_file, "<", $PMIDs_file) or die "**Unable to open \"$PMIDs_file\" file";
# Reads stdin. Makes an array (@pmids) with the stdin pubmed ids
while(<input_file>){
	chop;
	$_ =~ s/\r//ig;
	if(substr($_,0,1) eq "#") {$title=substr($_,1,); next;}
	push(@pmids,$_);
	}
#close $fp;


my $conf_file = $ARGV[1];


## --RETRIVE AND PARSE XMLs--
my $paper_counter = 0;
my $n_of_papers = scalar @pmids;
foreach my $pmid (@pmids){
	# Check if $pmid.xml and $pmid_cited.xml exist in $pmid_dir/ and retrieve otherwise
	if(!(-e "$pmid_dir/$pmid.xml")){
		my $cmd="wget -O $pmid_dir/$pmid.xml -o $tmpdir/lwget_$procid \"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$pmid&retmode=xml&email='$email'\"\n";
		#if($fverbose==1){print STDERR "Retrieving $pmid.xml: $cmd";}
		sleep (int(rand(2))+0);
		system $cmd;
		}
	if(!(-e "$pmid_dir/$pmid\_cited.xml")){
		my $cmd="wget -O $pmid_dir/$pmid\_cited.xml -o $tmpdir/lwget_$procid \"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&linkname=pubmed_pubmed_citedin&id=$pmid&email='$email'\"\n";
		#if($fverbose==1){print STDERR "Retrieving $pmid\_cited.xml: $cmd";}
		sleep (int(rand(2))+0);
		system $cmd;
		}
	$paper_counter += 1;
	if($fverbose==1){my $prcnt = ($paper_counter/$n_of_papers)*100; printf STDERR "Retrieving papers data: %.f%% completed.\r", $prcnt;}
	#print STDERR "$pmid\n";
	#if(!(-e "$pmid_dir/$pmid.pubmed")){
	#	my $cmd="wget -O $pmid_dir/$pmid.pubmed -o /tmp/lwget_$procid \"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$pmid&retmode=text&rettype=pubmed\"\n";
	#	#print STDERR "Retrieving $pmid.pubmed: $cmd";
	#	sleep (int(rand(2))+0);
	#	system $cmd;
	#	}
	
	### Everything from xml now.
	#open my $fp, "$pmid_dir/$pmid.pubmed" or qerror("** Can't r-open '$pmid_dir/$pmid.pubmed'\n");
	#my $xpubmed= do { local $/; <$fp> };
	#close $fp;
	#my @xpubmedr=split("\n\n",$xpubmed);
	#foreach my $pmid (@xpubmedr) {print ">> $pmid<<\n";} print "\n";
	#$xpubmedr[0]=~s/\n//g; $xpubmedr[0]=~s/^1\.\s//m; 
	#$xpubmedr[0]=~s/\sdoi:.+//m;
	#$ref{$pmid}=$xpubmedr[0];
	#$xpubmedr[1]=~s/\n/ /g; $xpubmedr[1]=~s/\s$//;
	#$title{$pmid}= $xpubmedr[1];
	# Authors better from XML below
	#$xpubmedr[2]=~s/\n/ /g; $xpubmedr[2]=~s/\(\d+\)//g; 
	#$auth{$pmid}= $xpubmedr[2];
	# Abstract better from XML below
	#$xpubmedr[4]=~s/\.\n/\. /g; $xpubmedr[4]=~s/\n//g; 
	#$abstract{$pmid}= $xpubmedr[4];
	
	open my $fp, "$pmid_dir/$pmid.xml" or qerror("** Can't r-open '$pmid_dir/$pmid.xml'\n");
	my $xml= do { local $/; <$fp> };#Note: This takes the content of the file w/o the need of a loop. 
	close $fp;
	
	## -- SOURCE --
	$source{$pmid} = "PM";

	## -- GET DATE --
	$date{$pmid}="--"; $datep{$pmid}="--"; 
	#if($xml=~/<ArticleDate.+<Year>(\d+)<\/Year>.*<Month>(\d+)<\/Month>.*<Day>(\d+)<\/Day>.*<\/ArticleDate>/m){
	if($xml=~/<PubDate.+<MedlineDate>.*(\d{4}).*?<\/MedlineDate>.*?<\/PubDate>/m){
		#$date{$pmid}=$1.".".$2.$3;$datep{$pmid}=$3."/".$2."/".$1;
		$date{$pmid}=$1."00"; $datep{$pmid}="00"."/".$1;
		}	
	if($xml=~/<PubDate.+<Year>(\d+)<\/Year>.*?<\/PubDate>/m){
		#$date{$pmid}=$1.".".$2.$3;$datep{$pmid}=$3."/".$2."/".$1;
		$date{$pmid}=$1."."."00";$datep{$pmid}="00"."/".$1;
		}
	if($xml=~/<PubDate.+<Year>(\d+)<\/Year>.*<Month>(.+)<\/Month>.*?<\/PubDate>/m){
		#$date{$pmid}=$1.".".$2.$3;$datep{$pmid}=$3."/".$2."/".$1;
		$date{$pmid}=$1.".".$2;$datep{$pmid}=$2."/".$1;
		}
	#print "($pmid) ($date{$pmid}) ($datep{$pmid})\n";

	## --GET MESH TERMS --
	my $xmesh="";
	if($xml=~/<MeshHeadingList>(.+?)<\/MeshHeadingList>/m){$xmesh=$1;}
	my @xmesh2=split("<MeshHeading>",$xmesh);
	my @xmesh3=();
	foreach my $i (@xmesh2) {
		#print "$pmid [$i]\n";
		if($i=~/<DescriptorName\sUI=\"(.+?)\"/) {push (@xmesh3,$1);} 
		}
	foreach my $i (@xmesh3){
		my $found=0;
		foreach my $j (@allmeshids){
			if($i eq $j){$found=1; last;}
			}
		if($found==0) {push(@allmeshids,$i);}
		}
	$meshids{$pmid}=join("|",@xmesh3);
	@xmesh3=();
	foreach my $i (@xmesh2) {
		#print "$pmid [$i]\n";
		if($i=~/<DescriptorName\sUI=\".+?\".*?>(.+)?<\/DescriptorName>/) {push (@xmesh3,$1);} 
		}
	$meshidnames{$pmid}=join("|",@xmesh3);
	## --GET ABSTRACT--
	my $xabs="";
	if($xml=~/<Abstract>(.+?)<\/Abstract>/m){$xabs=$1;}
	$xabs=~s/\n//g; $xabs=~s/<AbstractText\sLabel=\"(.+?)\".*?>/ $1: /g; $xabs=~s/<AbstractText>//g;
	$xabs=~s/<\/AbstractText>//g; $xabs=~s/<CopyrightInformation>.+?<\/CopyrightInformation>//g; 
	$abstract{$pmid}=$xabs;
	
	## --GET AUTHORS --
	$auth{$pmid}="";
	my @xauth=(); my @auth1=();
	if($xml=~/<AuthorList.*?>(.+?)<\/AuthorList>/){@auth1=split("<Author",$1);}
	foreach my $i (@auth1) {
		if($i=~/<LastName.*?>(.+)<\/LastName>.*<ForeName.*?>(.+)<\/ForeName/){
			push(@xauth,"$1, $2");
			}
		}
	$auth{$pmid}=join("; ",@xauth);

	## --GET TITLE--
	$title{$pmid}="";
	if($xml=~/<ArticleTitle.*?>(.+?)<\/ArticleTitle>/){$title{$pmid}=$1;}
	
	## --GET REFERENCE--
	my $xref=""; my $xxref="";
	if($xml=~/<Journal.*?>(.+?)<\/Journal>/){$xxref=$1;}
	if($xxref=~/<Title.*?>(.+?)<\/Title>/){$xref=$1;}
	if($xxref=~/<ISOAbbreviation.*?>(.+?)<\/ISOAbbreviation>/){$xref=$1;}
	if($xxref=~/<Year.*?>(.+?)<\/Year>/){$xref=$xref.". ($1)";}
	if($xxref=~/<Volume.*?>(.+?)<\/Volume>/){$xref=$xref.". $1";}
	if($xxref=~/<Issue.*?>(.+?)<\/Issue>/){$xref=$xref."($1)";}
	$xxref="";
	if($xml=~/<Pagination.*?>(.+?)<\/Pagination>/){$xxref=$1;}
	if($xxref=~/<MedlinePgn.*?>(.+?)<\/MedlinePgn>/){$xref=$xref.":$1";}
	#print "$ref{$pmid}\n$xref\n\n";
	$ref{$pmid}=$xref;
	my @xdb=(); my @xdbs=();
	if($xml=~/<DataBankList.*?>(.+?)<\/DataBankList>/){@xdb=split("<DataBank",$1); }
	foreach my $i (@xdb) {
		if($i=~/<AccessionNumber\s{0,3}>(.+?)<\/AccessionNumber>/){
			push(@xdbs,$1);
			}
		}
	$databank{$pmid}=join("|",@xdbs);
	
	## --GET PUBLICATION TYPE --
	# xC=clinicaltrial/Randomized; xR=Review; #Sistematic-review/meta-analisis
	my $xtype=""; my $xC=0; my $xR=0; my $xS=0; 
	if($xml=~/<PublicationTypeList>(.+?)<\/PublicationTypeList>/m){$xtype=$1;}
	my @xtype2=split("<PublicationType",$xtype);
	my @xtype3=();
	foreach my $i (@xtype2) {
		#print "$pmid [$i]\n";
		if($i=~/>(.+?)<\/PublicationType>/) {
			my $xs=$1;
			if($xs=~/(^Randomized.*?)$/){$xs=~s/(^Randomized.*?)$/<b><font color=#c39bd3>$1<\/font><\/b>/g; $xC=1;}
			if($xs=~/(^.*Clinical\sTrial.*?)$/){$xs=~s/(^.*Clinical\sTrial.*?)$/<b><font color=#c39bd3>$1<\/font><\/b>/g; $xC=1;}
			if($xs=~/(^Review)$/){$xs=~s/(^Review)$/<b><font color=#5dade2>$1<\/font><\/b>/g; $xR=1;}
			if($xs=~/(^Systematic\sReview)$/){$xs=~s/(^Systematic\sReview)$/<b><font color=#7dcea0>$1<\/font><\/b>/g; $xS=1;}
			if($xs=~/(^Meta-Analysis)$/){$xs=~s/(^Meta-Analysis)$/<b><font color=#7dcea0>$1<\/font><\/b>/g; $xS=1;}
			push (@xtype3,$xs);
			} 
		}
	$ptypes{$pmid}=join("; ",@xtype3); #$ptypes{$pmid}=$ptypes{$pmid}.";";
	$ptypel{$pmid}="";
	if($xR==1){$ptypel{$pmid}=$ptypel{$pmid}."<b><font color=#5dade2>R</font></b> ";}
	if($xS==1){$ptypel{$pmid}=$ptypel{$pmid}."<b><font color=#7dcea0>S</font></b> ";}
	if($xC==1){$ptypel{$pmid}=$ptypel{$pmid}."<b><font color=#c39bd3>C</font></b> ";}
	
	## --GET 'CITED BY' LIST--
	open my $fp, "$pmid_dir/$pmid\_cited.xml" or qerror("** Can't r-open '$pmid_dir/$pmid\_cited.xml'\n");
	my $xml= do { local $/; <$fp> };
	close $fp;
	$xml=~s/\n//mg;
	my @xlink=split("<Link>",$xml);
	my @xid=();
	foreach my $i (@xlink) {
		if($i=~/<Id>(\d+?)<\/Id>.*<\/Link>/){push (@xid,$1);}
		} 
	$citedby{$pmid}=join(",",@xid);
	#print STDERR "\n\n>$pmid: ($ptypes{$pmid})\n"; 
	#print STDERR "$ptypes{$pmid} ($ptypel{$pmid})<br>\n"; 
	#if($auth{$pmid}=~/Costabile/){
	#	print STDERR "\n\n>$pmid: ($ref{$pmid}) ($title{$pmid})\n($auth{$pmid})\n($abstract{$pmid})\n($date{$pmid}) ($datep{$pmid})\n($meshids{$pmid})\n($meshidnames{$pmid})\n ($citedby{$pmid})\n";
	#	}
	}

#exit;

if (@pmids.length > $layoutCutOff) {
	$defaultLayout = $bigLayout;
}

if($fverbose==1){print STDERR "\nBuilding HTML file. This might take some time...";}


my $xpmid; my $xsource; my $xyear; my $xtitle; my $xabs; my $xref; my $xauthors; my $xptype; my $xmesh; 

my $xjournal; my $xvolume; my $xpages; my $xdoi;

my $xC; my $xR; my $xS;

my %dois;

foreach my $filename (@lfiles){
	open(xml, "<", $filename) or die "Unable to open \"$filename\" file";
	while (<xml>) {
		$_ =~ s/\r//ig;
		if ($_ =~ /<row>/i) {
			$xpmid = ""; 
			$xyear = "";
			$xtitle = "";
			$xabs = "";
			$xref = "";
			$xauthors = "";
			$xptype = "";
			$xmesh = ""; #always empty
			$xjournal = "";
			$xvolume = "";
			$xpages = "";
			$xdoi = "";
			$xC=0; $xR=0; $xS=0;
			} 
		elsif ($_ =~ /<field name="PMID">(.*)<\/field>/i) {$xpmid = $1;}
		elsif ($_ =~ /<field name="OWN">(.*)<\/field>/i) {$xsource = $1;}
		elsif ($_ =~ /<field name="DP">(.*)<\/field>/i) {$xyear = $1;}
		elsif ($_ =~ /<field name="TI">(.*)<\/field>/i) {$xtitle = $1;}
		elsif ($_ =~ /<field name="AB">(.*)<\/field>/i) {$xabs = $1;}
		elsif ($_ =~ /<field name="AU">(.*)<\/field>/i) {$xauthors = $1;}	
		elsif ($_ =~ /<field name="PT">(.*)<\/field>/i) {$xptype = $1;
			if($_=~/(^Randomized.*?)$/){$_=~s/(^Randomized.*?)$/<b><font color=#c39bd3>$1<\/font><\/b>/g; $xC=1;}
			if($_=~/(^.*Clinical\sTrial.*?)$/){$_=~s/(^.*Clinical\sTrial.*?)$/<b><font color=#c39bd3>$1<\/font><\/b>/g; $xC=1;}
			if($_=~/(^Review)$/){$_=~s/(^Review)$/<b><font color=#5dade2>$1<\/font><\/b>/g; $xR=1;}
			if($_=~/(^Systematic\sReview)$/){$_=~s/(^Systematic\sReview)$/<b><font color=#7dcea0>$1<\/font><\/b>/g; $xS=1;}
			if($_=~/(^Meta-Analysis)$/){$_=~s/(^Meta-Analysis)$/<b><font color=#7dcea0>$1<\/font><\/b>/g; $xS=1;}
		}
		elsif ($_ =~ /<field name="JT">(.*)<\/field>/i) {$xjournal = $1; $xjournal =~ s/(\S+)/\u\L$1/g;}
		elsif ($_ =~ /<field name="VI">(.*)<\/field>/i) {$xvolume = $1;}
		elsif ($_ =~ /<field name="PG">(.*)<\/field>/i) {$xpages = $1;}
		elsif ($_ =~ /<field name="SO">.*doi:\s*(.*)<\/field>/i) {$xdoi = $1;}
		elsif ($_ =~ /<\/row>/i) {
			push(@pmids, $xpmid);
			$date{$xpmid} = "$xyear.00"; $datep{$xpmid} = "00/$xyear";
			$title{$xpmid} = $xtitle;
			$abstract{$xpmid} = $xabs;
			$auth{$xpmid} = $xauthors;
			$ptypes{$xpmid} = $xptype;
			$ptypel{$xpmid} = "";
			if($xR==1){$ptypel{$xpmid}=$ptypel{$xpmid}."<b><font color=#5dade2>R</font></b> ";}
			if($xS==1){$ptypel{$xpmid}=$ptypel{$xpmid}."<b><font color=#7dcea0>S</font></b> ";}
			if($xC==1){$ptypel{$xpmid}=$ptypel{$xpmid}."<b><font color=#c39bd3>C</font></b> ";}
			$meshids{$xpmid} = $xmesh;
			$meshidnames{$xpmid} = $xmesh;
			$xref = "<i>$xjournal.</i> ($xyear).\n $xvolume:$xpages";
			$ref{$xpmid} = $xref;
			$dois{$xpmid} = $xdoi;
			$source{$xpmid} = $xsource;
			#print STDERR "\n$pmid\n$year\n$title\n$abs\n$ref\n$authors\n$ptype\n$mesh\n$journal\n$volume\n$pages\n$doi\n\n";
			}	
		}
	}


## --GET MESHES FULL INFORMATION--

# Retrieve info for mesh terms in set (to tmpdir/meshes_data_$procid). And import it.
# Prints temporal file with meshes list (meshes_$procid), use script to read this file and extract 
# from mesh d2021.bin (mesh database) the meshes full information and prints the data of this meshes 
# in meshes_data_$procid. 

open my $fp, ">", "$tmpdir/meshes_$procid" or qerror("** Can't w-open '$tmpdir/meshes_$procid'\n");
foreach my $i (@allmeshids) {print $fp "$i\n"}
close $fp;
system "perl $bindir/parse_mesh3_list.pl $auxiliar_files_dir/mesh.bin $tmpdir/meshes_$procid ./$conf_file >$tmpdir/meshes_data_$procid\n";#argv 1: mesh database; argv 2: mesh list file (just created above)
open my $fp, "<", "$tmpdir/meshes_data_$procid" or qerror("** Can't r-open '$tmpdir/meshes_data_$procid'\n");

$nmesh=0;
while(<$fp>){
	chop; my @l=split("\t",$_);
	$nmesh++;
	#Equaling mesh fields with hash variables.
	$mclass[$nmesh]=$l[0]; $mui[$nmesh]=$l[1];
	$mname[$nmesh]=$l[2];
	#$mprint[$nmesh]=$l[2]."|".$l[3]."|".$l[5]."|".$l[7]."|".$l[8]."|".$l[9]."|".$l[10]; MESH PA and PI removed
	$mprint[$nmesh]=$l[2]."|".$l[3]."|".$l[5]."|".$l[7]."|"."|".$l[10]; # Mesh sinonisms (will be use in coloring subroutine)
	$mprint[$nmesh]=~s/\s\(.+\)//g;
	$mtaxid[$nmesh]=$l[4]; $mrr[$nmesh]=$l[6]; 
	$mhierarch[$nmesh]=$l[11];$mst[$nmesh]=$l[12];
	$mcount{$mui[$nmesh]}=0;
	foreach my $pid (@pmids){
		my @tm=split("\\|",$meshids{$pid});
		if(grep(/^$mui[$nmesh]$/,@tm)) {$mcount{$mui[$nmesh]}++;} 
		}
	#print STDERR "$mclass[$nmesh]\t$mui[$nmesh]\t$mprint[$nmesh]\t$mtaxid[$nmesh]\t$mrr[$nmesh]\t$mhierarch[$nmesh]\t($mst[$nmesh])\n\n";	
	#print STDERR "$mui[$nmesh]\t$mclass[$nmesh]\t$mtaxid[$nmesh]\t($mrr[$nmesh])\t$mname[$nmesh]\n";
	}
close $fp;
#print STDERR "";


## --CREATES MESH -> PAPERS ASSOCIATION--

foreach my $i (1..$nmesh){
	$meshpmids[$i]="";
	foreach my $pid (@pmids){
		my @xmids=split("\\|",$meshids{$pid}); 
		if(grep(/^$mui[$i]$/,@xmids)) {$meshpmids[$i]=$meshpmids[$i].$pid."|";}
		}
	chop $meshpmids[$i];
	}

## --CREATES IDs FOR USER TERMS-- (used later on for mesh table). ### DEPRECATED
#my $utermscounter = 1;
#my %utermsids;
#foreach my $term (@userterms) {
#	$utermsids{"user_term_".$utermscounter} = $term;
#	$utermscounter++
#	}

#foreach my $id (%utermsids) {print STDERR "$id $utermsids{$id}\n"}

## --CREATES USER IDS -> PAPER ASSOCIATION-- ###DEPRECATED


#my %utermspmcount;

#foreach my $termid (keys %utermsids) {
#	$utermspmids{$termid} = "";
#	foreach my $pmid (@pmids) {
#		my $term = $utermsids{$termid};
#		my $text = $title{$pmid}."\n".$abstract{$pmid};
#		if ($text =~ /(\w*$term\w*)/) {$utermspmids{$termid} = $utermspmids{$termid}." ".$pmid}
#		}
#	$utermspmcount{$termid} = scalar(split(" ", $utermspmids{$termid}));
#	}

#foreach my $id (keys %utermspmids) {print STDERR "$id $utermspmids{$id}\n"}
#foreach my $id (keys %utermspmcount) {print STDERR "$id $utermspmcount{$id}\n"}

#print STDERR join("\n", @meshpmids);  

# --CALCULATE INTERNAL CITATIONS (citations from papers included in list)--
# And graph for dot
my @tograph=();
open my $fp, ">", "$tmpdir/g_$procid.dot" or qerror("** Can't w-open '$tmpdir/g_$procid.dot'\n");
print $fp "digraph citations{\tsize=\"75\";\n";
foreach my $pid (@pmids){
	$icites{$pid}=0;
	my @cit=split(",",$citedby{$pid});
	foreach my $i (@cit){
		foreach my $j (@pmids){
			if($i eq $j) {
				print $fp "\t$j -> $pid [];\n"; 
				push(@tograph,$pid); push(@tograph,$j); 
				$icites{$pid}++;
				}
			}
		}
	}

html_head();

print "<script>\n";
print "
function filldetails(id, cycenter = true) {
    isThisNode(id);
    var divtofill = document.getElementById('details');
    divtofill.innerHTML = document.getElementById(\"data\"+id).value;
    isthisrow(\"tr\"+id);
    if (cycenter) {
      var node = cy.\$('#'+id);
      cy.animate({center: { eles: node }, easing: \"ease-in-out\"}).delay(50);
    }
};\n";

## --PRINTS HTML <script>--
my %detailstodata;
foreach my $pid (@pmids){
	my @l=split(",",$auth{$pid}); my @ll=split("/",$datep{$pid});
	my $xauth=$l[0]." (".$ll[1].")";
	#This creates the content of the deatils div (title, abstract, etc). hmesh subroutine 
	# colour the mesh terms inside the title and abstract.
	my $xabs;
	if ($source{$pid} eq "PM") {
		$xabs= hmesh("<p><i>$xauth.</i> <a href=https://pubmed.ncbi.nlm.nih.gov/$pid target=new>$pid</a><br>$ptypes{$pid}</p><hr><h2>$title{$pid}</h2><p>".$abstract{$pid})."</p>";
	} else {
		my $doi = $dois{$pid};
		if ($doi ne "") {
			$xabs= hmesh("<p><i>$xauth.</i> <a href=https://www.doi.org/$doi target=new>$pid</a><br>$ptypes{$pid}</p><hr><h2>$title{$pid}</h2><p>".$abstract{$pid})."</p>";
		} else {
			$xabs= hmesh("<p><i>$xauth.</i> <a class=\"empty-link\" target=new>$pid</a><br>$ptypes{$pid}</p><hr><h2>$title{$pid}</h2><p>".$abstract{$pid})."</p>";
			}
		}
	#print STDERR "-----------------\n($abstract{$pid})\n\n($xabs)\n"; #exit;
	$xabs=~s/\(/&lpar;/g;$xabs=~s/\)/&rpar;/g;
	$xabs=~s/'/\\'/g;$xabs=~s/\"/\\'/g;
	my @xdb=split("\\|",$databank{$pid});
	if(@xdb>0){
		$xabs=$xabs."<p><i>Clin. trials: ";
		foreach my $i(@xdb){
			if($i=~/^IRCT/) {$xabs=$xabs."<a href=https://www.irct.ir/search/result?query=$i target=new>$i</a> ";}
			elsif($i=~/^NCT/) {$xabs=$xabs."<a href=https://clinicaltrials.gov/ct2/show/$i target=new>$i</a> ";}
			elsif($i=~/^ACTRN/) {$xabs=$xabs."<a href=https://www.anzctr.org.au/TrialSearch.aspx#&&searchTxt=$i target=new>$i</a> ";}
			elsif($i=~/^ISRCT/) {$xabs=$xabs."<a http://www.controlled-trials.com/$i target=new>$i</a> ";}
			elsif($i=~/^ChiCTR/) {$xabs=$xabs."<a https://www.chictr.org.cn/historyversionpuben.aspx?regno=$i target=new>$i</a> ";}
			else {$xabs=$xabs.$i." ";}
			}
		$xabs=$xabs."</p>";
		}
	
	# Exploring sentence highlighting...
	#my $sentences=get_sentences($xabs);     ## Get the sentences.
        #foreach my $i (@$sentences) {
        #	print STDERR "> $i\n";
        #	}
        #exit;
	#print "    if(arguments[0] == \"$pid\") {divtofill.innerHTML = \"$xabs\";}  \n"; #Old line, to print full text in if js statement
	#print "    if(arguments[0] == \"$pid\") {divtofill.innerHTML = document.getElementById(\"data$pid\").value;}  \n";
	$detailstodata{"data$pid"} = $xabs;
	}

##js function to display (and undisplay) pmids list of mesh term in mesh table.
print "\nfunction  fillmeshpmids(id,func) {\n";
print "    var htmlc=\"\";\n";
foreach my $i (1..$nmesh){
	my $xmp="<a onclick=fillmeshpmids('$mui[$i]',0)><i>[-pmids]</i></a><br> ";
	my @xpmids=split("\\|",$meshpmids[$i]);
	foreach my $i (@xpmids){
		$xmp=$xmp."<a onclick=filldetailsANDmovetorow($i)>$i</a> ";
		}
	print "   if(arguments[0] == \"$mui[$i]\") {if(arguments[1]==1) {htmlc=\"$xmp\";} else {htmlc=\"<a onclick=fillmeshpmids('$mui[$i]',1)><i>[+PMIDs]</i></a>\";} }\n";
	}

print "    document.getElementById(arguments[0]).innerHTML=htmlc;\n";	
print "  }\n";


##js function to delete repeted or empty element of and array-
print "
function uniq(array) {
  var uniqArray = [];
  for (let i in array) {
    if (array[i] != \"\") {
      if (!uniqArray.includes(array[i])) {
        uniqArray.push(array[i]);
        }
      }
    }
 return uniqArray;
}

\n";

##js function to display and undisplay specified hidden element
print "
function displayBlock(id_block) {
  var value = document.getElementById(id_block).style.visibility;
  if(value == \"visible\") {
    document.getElementById(id_block).style.visibility = \"hidden\";
  } else {
    document.getElementById(id_block).style.visibility = \"visible\";
  }
}
\n";

##js to add term to "Added" list
print "
function addTerm(input) {
  var text = document.getElementById(\"Added\").innerHTML;
  var linput = input.split(\";\");
  for (let i in linput) {
    linput[i] = linput[i].trim();
    if (linput[i].length > 2) {
      if (!\"<b><font color=\\\"#e67e22\\\">  <\\/font><\\/b>  <b><font color=\\\"#00bb00\\\">  <\\/font><\\/b> <b><font color=\\\"#0000ff\\\">  <\\/font><\\/b> <b><font color=\\\"#ff0000\\\">  <\\/font><\\/b><b> <font color=\\\"#a600ff\\\">  <\\/font><\\/b>\".includes(linput[i])) {
      text = text + linput[i] + \"<br>\";
      }
    }
  document.getElementById(\"Added\").innerHTML = text;
  document.getElementById(\"uterm-text-input\").value = \"\";
  }
}
\n";

##js to add new user terms. Coloured and introduced in mesh table.
print "
function runTerms() {
  var Added = document.getElementById(\"Added\").innerHTML;
  var uterms = document.getElementById(\"Added\").innerHTML;
  lAdded = Added.split(\"<br>\");
  luterms = uterms.split(\"<br>\");
  lAdded.pop();
  lAdded.shift();
  luterms.pop();
  luterms.shift();
  lAdded = uniq(lAdded);
  luterms = uniq(luterms);
  var filtered = [];
  var luterms_pmids = {};
  for (let i in lAdded) {
    if (/<b><font color=\\\"#a600ff\\\">.*<\\\/font><\\\/b>/.test(luterms[i])) {
      luterms[i] = luterms[i].replace(/<b><font color=\\\"#a600ff\\\">(.+)<\\\/font><\\\/b>/, function (\$0, \$1) {return \$1;});
    } else {
      lAdded[i] = \"<b><font color=#a600ff>\"+lAdded[i]+\"<\/font><\/b>\";
    }
    luterms_pmids[luterms[i]] = [];
  }
  if (lAdded.length != 0) {document.getElementById(\"Added\").innerHTML =  \"Added:<br>\"+lAdded.join(\"<br>\")+\"<br>\"};
  var pmidstags = document.getElementsByClassName(\"pmids-data\");
  for (let i = 0; i < pmidstags.length; i++) {
    var text = pmidstags[i].getAttribute(\"value\");
    coloredWords = text.match(/<b><font color=#a600ff>[A-Za-z1-9|s]+<\\\/font><\\\/b>/g);
    if (coloredWords) {
      for (let i = 0; i < coloredWords.length; i++) {
        var re = /<b><font color=#a600ff>([A-Za-z1-9|s]+)<\\\/font><\\\/b>/;
        word = re.exec(coloredWords[i])[1];
        retoreplace = new RegExp(\"<b><font color=#a600ff>\"+word+\"</font></b>\", \"g\");
        text = text.replace(retoreplace, word);
      }   
    }
    for (let k = 0; k < luterms.length; k++) {
      var utermToRe =\"\"
      for (let i in luterms[k]) {
        var character = luterms[k][i];
        if (/[a-z]/.test(character)) {
          character = \"[\"+character.toUpperCase()+character+\"]\";
          }
        utermToRe = utermToRe + character;
        }
      var re2 = new RegExp(\"([^A-Za-z0-9]){0,1}([A-Za-z0-9]*\"+utermToRe+\"[A-Za-z0-9]*)([^A-Za-z0-9]){0,1}\", \"g\");
      var splitText = text.split(\"<hr>\");
      if (splitText[1].match(re2)) {
        pmid = pmidstags[i].getAttribute(\"id\").slice(4,);
        luterms_pmids[luterms[k]].push(pmid);
        splitText[1] = splitText[1].replace(re2, function (\$0, \$1, \$2, \$3) {var x = \$1+\"<b><font color=#a600ff>\"+\$2+\"</font></b>\"+\$3; return x.replace(\"undefined\", \"\");});
        }
      text = splitText.join(\"<hr>\");
      }
    pmidstags[i].setAttribute(\"value\", text);
  }
  let table = document.getElementById(\"mesh_table\").rows;
  var index_todelete = [];
  for (let i = 0; i < table.length; i++) {
    var row = table[i];
    var row_cells = row.cells;
    var type = row_cells[0].innerHTML;
    var term = row_cells[1].innerHTML;
    if (type.match(\"user_term\")) {
      index_todelete.push(i);
    }
  }
  var n = 0;
  for (let i in index_todelete) {
    document.getElementById(\"mesh_table\").deleteRow(index_todelete[i]-n);
    n++;
  }
  var ldata= [];
  for (let i in Object.keys(luterms_pmids)) {
    var key= Object.keys(luterms_pmids)[i];
    var key_pmids= luterms_pmids[key];
    var to_list = key + \":\" + key_pmids.join(\";\");
    ldata.push(to_list);
  }
  to_data = ldata.join(\"|\");
  var data_tag = document.getElementById(\"data_uterms_pmids\");
  data_tag.setAttribute(\"value\", to_data);;
  for (let i in luterms) {
    var row = document.getElementById(\"mesh_table\").insertRow(0);
    var term_number = parseInt(i) + 1;
    var id = \"user_term_\"+term_number.toString();
    var ratio = luterms_pmids[luterms[i]].length.toString()+\"/\"+pmidstags.length.toString();
    var cell1 = row.insertCell(0);
    cell1.innerHTML = \"<a>\"+id+\"</a>\";
    var cell2 = row.insertCell(1);
    cell2.innerHTML = \"<font color=#a600ff>\"+luterms[i]+\"</font>\";
    var cell3 = row.insertCell(2);
    var cell4 = row.insertCell(3);
    cell4.innerHTML = ratio
    var termMod = luterms[i].replace(\" \", \"|\");
    var cell5 = row.insertCell(4);
    cell5.innerHTML = \"<td id=\"+luterms[i]+\" style=\\\"cursor:pointer;\\\"><a onclick=\\\"fillnewtermspmids('\"+id+\"','\"+termMod+\"',1)\\\"><i>[+PMIDs]</i></a>\";
    cell5.setAttribute(\"id\", id);
    cell5.setAttribute(\"style\", \"cursor:pointer;\");
  }      
}



\n";


##js similar to fillmeshpmids and fillutermspmids but with new uterms (inputed by html menu)
print "
function fillnewtermspmids (id, term, option) {
  term = term.replace(\"|\", \" \");
  var from_data = document.getElementById(\"data_uterms_pmids\").getAttribute(\"value\");
  var ldata = from_data.split(\"|\");
  for (let i in ldata) {
    if (term == ldata[i].split(\":\")[0]) {
      var lpmids = ldata[i].split(\":\")[1].split(\";\");
    }
  }
  term = term.replace(\" \", \"|\");
  if (option==1) {
    htmlc = \"<a onclick=fillnewtermspmids('\"+id+\"','\"+term+\"',0)><i>[-pmids]</i></a><br>\"
    for (let i in lpmids) {
    	htmlc += \"<a onclick=filldetailsANDmovetorow('\"+lpmids[i]+\"')>\"+lpmids[i]+\"</a> \";
    }
  } else {
    htmlc = \"<a onclick=fillnewtermspmids('\"+id+\"','\"+term+\"',1)><i>[+PMIDs]</i></a>\"
  }
  document.getElementById(id).innerHTML=htmlc;
}
\n";

##js clear input
print "
function cleartoAdd () {
  document.getElementById(\"toAdd\").innerHTML = \"Terms to add:<br>\";
}

function clearAdded () {
  document.getElementById(\"Added\").innerHTML = \"Already added:<br>\";
}

function clearCreatedTags () {
  document.getElementById(\"createdtags\").innerHTML = \"\";
}

function clearHTMLTags (string) {
	//removes all html tags of a text
	var regexp = /<[^>]*>/gi;
	return string.replaceAll(regexp, '');	
}\n";

##js to move rows (delete and recover)
print "
function moveRows (from_table_id, to_table_id) {
  var from_rows = document.getElementById(from_table_id).rows;
  for (let i = 0; i<from_rows.length; i++) {
    var row = from_rows[i];
    var sel_cell = row.cells[9];
    var check_box = sel_cell.childNodes[0];
    if (check_box.checked) {
      check_box.checked = false;
      var new_row = row;
      new_row.setAttribute(\"class\", \"deleted\");
      document.getElementById(to_table_id).getElementsByTagName(\"tbody\")[0].append(new_row);
      //row.remove();
      i=-1;
    }
  }
}
\n";


print "
function tagSelection(tag, table_id = \"pm_papers_table\") {
  var cleartag = clearHTMLTags(tag);
  var from_rows = document.getElementById(table_id).rows;
  for (let i = 0; i<from_rows.length; i++) {
    var row = from_rows[i];
    var tag_cell = row.cells[8];
    var sel_cell = row.cells[9];
    var check_box = sel_cell.childNodes[0];
    var attribute = cleartag + \"-row\";
    if (check_box.checked) {
      if (cleartag == 'Imp.') {tag = '<p style=\"font-size:0px\">!!!</p>' + tag;}
      tag_cell.innerHTML = tag;
      row.setAttribute(\"class\", attribute);
      check_box.checked = false;
    }
  }
}
\n";

print"
function newTag(tagName) {
  tagName = tagName.trim();
  if (tagName == \"\") {return}
  var newTag = '<input type=\"radio\" name=\"createdTags\" value=\"'+tagName+'\">'+tagName+'<br>';
  var createdTags = document.getElementById(\"createdtags\").innerHTML;
  var radios = document.getElementsByName(\"createdTags\");
  var add = true;
  for (let i = 0; i < radios.length; i++) {
    if (radios[i].getAttribute(\"value\") == tagName) {
      add = false;
    }
  }
  if (add) {
    createdTags = createdTags + newTag;
    document.getElementById(\"createdtags\").innerHTML = createdTags;
  }
  tagSelection(tagName);
}
\n";

print"
function getRadioVal (name) {
  var form = document.getElementsByName(name);
  var value = \"\";
  for (let i in form) {
    if (form[i].checked) {
      value =form[i].value;
    }
  }
  return value;
}
\n";

print "
function displayLayouts (open=false) {
  if (open) {
    document.getElementById(\"chooseLayout\").innerHTML = \"<b><a onclick=displayLayouts()>[+]</a></b>\";
  } else {
    document.getElementById(\"chooseLayout\").innerHTML = \"Choose layout: <input id=\\\"radiobreadthfirst\\\" type=\\\"radio\\\" name=\\\"layouts\\\" value=\\\"breadthfirst\\\" onclick=changeLayout('breadthfirst')>breadthfirst <input id=\\\"radiocose\\\" type=\\\"radio\\\" name=\\\"layouts\\\" value=\\\"cose\\\" onclick=changeLayout('cose')>cose <input id=\\\"radiocola\\\" type=\\\"radio\\\" name=\\\"layouts\\\" value=\\\"cola\\\" onclick=changeLayout('cola')>cola <input id=\\\"radioklay\\\" type=\\\"radio\\\" name=\\\"layouts\\\" value=\\\"klay\\\" onclick=changeLayout('klay')>klay <input id=\\\"radiodagre\\\" type=\\\"radio\\\" name=\\\"layouts\\\" value=\\\"dagre\\\" onclick=changeLayout('dagre')>dagre <b><a onclick=displayLayouts(true)>[-]</a></b>\";
    document.getElementById(\"radio\" + current_layout).checked = true;
  }
}
\n";

print "
function movetorow (rowid) {
  var scrollpos = document.getElementById(rowid).offsetTop;
  document.getElementById(\"pm_papers_list\").scrollTo(0, scrollpos);
};\n";

print"
var shownrowid = \"null\";

function isthisrow (rowid) {
  var shownrow = document.getElementById(shownrowid);
  if (shownrow) {
    shownrow.setAttribute(\"style\", \"color:black\");
  }
  shownrowid = rowid;
  var shownrow = document.getElementById(shownrowid);
  if (shownrow) {
    shownrow.setAttribute(\"style\", \"background-color: #ddfdff\");
  }
};\n";


print"
function filldetailsANDmovetorow (pmid) {
  movetorow ('tr'+pmid);
  filldetails(pmid);
};\n";

print"
document.addEventListener('mouseup', function(e) {
    var div1 = document.getElementById('othertagsmenu');
    var button1 = document.getElementsByClassName('othertagsbutton')[0];
    var div2 = document.getElementById('newtermsmenu');
    var button2 = document.getElementsByClassName('enterterms')[0];
    if (!div1.contains(e.target) && !button1.contains(e.target)) {
    	if (div1.style.visibility == 'visible') {
        displayBlock('othertagsmenu');
      }
    }
    if (!div2.contains(e.target) && !button2.contains(e.target)) {
    	if (div2.style.visibility == 'visible') {
        displayBlock('newtermsmenu');
      }
    }
});\n";

print "</script>\n";
print "</head>\n";


print "\n<body>\n";

## --PRINTS HTML DATA--

print "<data id =\"data_uterms_pmids\" value =\"\"></data>";

foreach my $dataid (keys %detailstodata) {
  print "<data id=\"$dataid\" class=\"pmids-data\" value=\"$detailstodata{$dataid}\"></data>\n";
}


my $added = join("<br>", @preuterms)."<br>";


## --PRINTS HTML PAPERS TABLE, BUTTONS, ETC.--
#my $utermstext = join("<br>", @userterms); (deprecated).
print "
<div id=\"deleted_papers_div\" class=\"list\">
  <div class=\"buttons-box\">
     <button class=\"papers_buttons\" onclick='displayBlock(\"deleted_papers_div\")'>&lt;-Return</button>&nbsp;&nbsp;&nbsp;&nbsp;<button class=\"papers_buttons\" onclick='moveRows(\"deleted_papers_table\",\"pm_papers_table\")'>Undelete selection</button>
  </div>
  <h3>&nbsp;Deleted papers</h3>
  <table id=\"deleted_papers_table\" rules=\"rows\" style=\"width:100%;\" class=\"sortable\" cellpadding=\"8\" border=\"1\">
    <tr><th>Ref.<br>PMID</th><th>Source</th><th>Type</th><th>Date</th><th width=30%>Title</th><th>#cit<br>TOT</th><th>cit/<br>year</th><th>#cit<br>INT</th><th>Tag</th><th>Sel.</th></tr>
  </table>
</div>



<div id=\"pm_papers_list\" class=\"list\">
  <div class=\"buttons-box\">
    <div  id= \"tagbuttons\" style=\"align-self:center; border:none; display: inline-block\">&nbsp;<a href=\"http://csbg.cnb.csic.es/RIMICIA/pdigest_help.html\" target=\"_blank\">[HELP]</a><b> &nbsp;Tag: </b> <button class=\"papers_buttons\" onclick='tagSelection(\"<u>Imp.</u>\")'>Tag as Imp.</button>&nbsp;&nbsp;<button class=\"papers_buttons othertagsbutton\" onclick='displayBlock(\"othertagsmenu\")'>Other tags</button>&nbsp;&nbsp;<button class=\"papers_buttons\" onclick='tagSelection(\"<p style=\\\"font-size:0px\\\">~~~</p>---\")'>Untag</button>&nbsp;&nbsp;</div><div id= \"delbuttons\" style=\"align-self:center; border:none; display: inline-block\"><b>Delete: </b><button class=\"papers_buttons\" onclick='moveRows(\"pm_papers_table\",\"deleted_papers_table\")'>Del. selection</button>  <button class=\"papers_buttons\" onclick='displayBlock(\"deleted_papers_div\")'>Trash-></button></div><div id= \"highlightbuttons\" style=\"align-self:center; border:none; display: inline-block\"><b>Highlight terms: </b>  <button class=\"enterterms\" onclick='displayBlock(\"newtermsmenu\")'>Enter new terms </button></div>

      <div id=\"newtermsmenu\" style=\"display: block; visibility: hidden;\">
      <p>To hightlight new terms, enter them in the <br>text box (one by one or separated by \";\") <br>and press \"Add\". <b> Don't forget to press <br>\"Save changes\" when you are done</b>.<br><br> Enter term:</p><input id=\"uterm-text-input\" type=\"text\"><br><br><input type=\"submit\" value=\"Add\" onclick='addTerm(document.getElementById(\"uterm-text-input\").value)'><br><p id=\"Added\"> Added:<br>$added</p>
      <button class=\"clear\" onclick=\"clearAdded()\">Clear</button><button class=\"run\" onclick='runTerms()'>Save changes</button>
      </div>

    
    <div id=\"othertagsmenu\">
      <p><b>Use new tag.</b><br><br>Tag name:</p><input id=\"newtag-text-input\" type=\"text\"><input type=\"submit\" value=\"Tag selection\" onclick='newTag(document.getElementById(\"newtag-text-input\").value)'><br><br><hr><p><b>Use previously created tags.</b><br></p><p id=\"createdtags\"></p><div align=\"right\" style=\"border:none\"><button class=\"clear\" style=\"position: absolute; left: 10px\" onclick=\"clearCreatedTags()\">Clear</button><input type=\"submit\" value=\"Tag selection\" onclick='tagSelection(getRadioVal(\"createdTags\"))'></div>
    </div>

    
  </div>


<h3>&nbsp;$title</h3>
<table id=\"pm_papers_table\" cellpadding=8 border=1 rules=\"rows\" style=\"width:100%;\" class=\"sortable\"><tr><th>Ref.<br>PMID</th><th>Source</th><th>Type</th><th>Date</th><th width=30%>Title</th><th>#cit<br>TOT</th><th>cit/<br>year</th><th>#cit<br>INT</th><th>Tag</th><th>Sel.</th></tr>\n";

#foreach (%source) {print STDERR "$_\n"}

my $nlist=0;
foreach my $pid (@pmids){
	$nlist++;
	my $ncites=split(",",$citedby{$pid});
	my $xauth; my @auth_list=split("; ",$auth{$pid}); 
	my $xref=$ref{$pid}; $xref=~s/(.+?)(\(\d+\)[\.*])(.+)/<i>$1<\/i>$2<br>$3/;
	if(@auth_list>=3) {$xauth=$auth_list[0]." <i>et al.</i>";} else {$xauth=$auth{$pid};}
	my @xd=split("/",$datep{$pid}); my $xdate=$xd[1].".".monthnr($xd[0]);
	my $tyearp=$xd[1]+(monthnr($xd[0])-1)/12;
	my @xdt=localtime(); my $tyearn=$xdt[5]+1900+($xdt[4]-1+1)/12;
	my $cityear; if(($tyearn-$tyearp)>0) {$cityear=sprintf("%.1f",$ncites/($tyearn-$tyearp));} else {$cityear="0.0";}
	my $xpid;
	if ($source{$pid} eq "PM") {
		$xpid="<a href=\"https://pubmed.ncbi.nlm.nih.gov/$pid\" target=new>$pid</a>";
	} else {
		my $doi = $dois{$pid};
		if ($doi ne "") {
			$xpid="<a href=\"https://www.doi.org/$doi\" target=new>$pid</a>";
		} else {
			$xpid="<a class=\"empty-link\"\>$pid</a>";
			}
		}
	print "<tr id= \"tr$pid\" onclick=\"filldetails('$pid')\" style=\"cursor:copy;\"><td>$xauth<br>$xref<br>$xpid</td><td align=center style=\"font-size: 0.5vw\">$source{$pid}</td><td>$ptypel{$pid}</td><td>$xdate</td><td>$title{$pid}</td>";
	print "<td align=right>$ncites</td><td align=right>$cityear</td><td align=right>$icites{$pid}</td><td align=center style=\"font-size: 0.7vw\"><p style='font-size:0px'>~~~</p>---</td><td><input type=\"checkbox\" id=\"select_pmid\" value=\"checked\"></input></td>";
	#print "<td align=right onclick=\"filldetails('$pid')\">&gt</td>\n";
	print "</tr>\n";
	}

print "</table>\n</div>\n\n";

## --PRINTS HTML MESH TERMS LIST--
# Color priority: 1-red-disease; 2-blue-comp; 3-green-morg; 4-orange-other

#print STDERR "$nlist\n";
print "\n<div class=\"mesh\" id=\"mesh\">\n";
print "<table id= \"mesh_table\" cellpadding=8 border=1 rules=\"rows\" style=\"width:100%;\">\n";

#%mcount = (%mcount, %utermspmcount); #Merge mesh and user terms papers count hashes

foreach my $mi (sort { $mcount{$b} <=> $mcount{$a} } keys %mcount) {
	#if($mcount{$mi}<$nlist/30) {last;}
	###DEPRECATED
	#if ($mi=~/user_term_/) {
	#	my $xmp="<a onclick=\"fillutermspmids('$mi',1)\"><i>[+PMIDs]</i></a> ";
	#	print "<tr valign=top><td><a>$mi</a></td>";
	#	print "<td><font color=$utermscolor>$utermsids{$mi}</font></td><td></td><td>$utermspmcount{$mi}/$nlist</td>";
	#	print "<td id=$mi style=\"cursor:pointer;\">$xmp</td></tr>\n";
	###------
	#} else {
		my $i=0; foreach my $j (1..$nmesh){if($mui[$j] eq $mi) {$i=$j; last;}}
		my $color="#000000";
		$color= $mclass[$i];
		my $xlink="";
		my @tmpsempantictypes = split(",", $mst[$i]);
		if ($mrr[$i] != "0") {
			if (grep( /^T109$/, @tmpsempantictypes) || grep( /^T116$/, @tmpsempantictypes) || grep( /^T121$/, @tmpsempantictypes) || grep( /^T123$/, @tmpsempantictypes) || grep( /^T114$/, @tmpsempantictypes) || grep(/^T130$/, @tmpsempantictypes)){
				my @l_rrchem = split(/\|/, $mrr[$i]);
				foreach my $rrchem (@l_rrchem) {
					if($rrchem=~/\d+\-\d+/) {
							$xlink=$xlink."<a href=https://www.lookchem.com/casno$rrchem.html target=new>$rrchem</a> ";
					} else {
						my $tmp=lc($rrchem); $xlink=$xlink."<a href=https://fdasis.nlm.nih.gov/srs/unii/$tmp target=new>$tmp</a> ";
					}
				}
			}
		}	
		if (grep( /^T007$/, @tmpsempantictypes)) {
			$xlink="<a href=https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$mtaxid[$i] target=new>taxid:$mtaxid[$i]</a>";
		}				
		my $xmp="<a onclick=\"fillmeshpmids('$mi',1)\"><i>[+PMIDs]</i></a> ";
		print "<tr valign=top><td><a href=https://id.nlm.nih.gov/mesh/$mi.html target=new>$mi</a></td>";
		print "<td><font color='$color'>$mname[$i]</font></td><td>$xlink</td><td>$mcount{$mi}/$nlist</td>";
		#print STDERR "<td><font color='$color'>$mname[$i]</font></td><td>$xlink</td><td>$mcount{$mi}/$nlist</td>\n";
		print "<td id=$mi style=\"cursor:pointer;\">$xmp</td></tr>\n";
	}
print "</table>\n";	
print "</div>\n";

## --PRINT DETAILS <div> --
print "\n<div class=\"details\" id=\"details\">\n";
print "Details\n";
print "</div>\n";


## --PRINT GRAPH --
print "\n<div id=\"pmnetwork\" class=\"network\">\n";

### only print graph if not too much nodes.
if (@pmids.length > $noNetworkCutOff) {
	print "<p class='noNetworkMessage'> Too many nodes to display this network</p>";
	print "<script>function isThisNode(id) {};var cy = cytoscape();</script>";
} else {
	print "<div id=\"chooseLayout\"><b><a onclick=displayLayouts()>[+]</a></b></div>\n";
print "<script>\n";
#print "function loadNetwork () {\n";
print "var cy = cytoscape({
  container: document.getElementById('pmnetwork'),
  elements: [";


$netgradient=~ s/^\s+|\s+$//g;
my @lnetgradient = split("\n", $netgradient);
use List::Util qw(max);
use List::Util qw(min);
my $highest = max values %icites;
my $lowest = min values %icites;
my $chunk = ($highest - $lowest + 1) / @lnetgradient.length;


my %citeto;

for my $pid (keys %citedby) {
	my @xvalues = split(",", $citedby{$pid});
	for my $value (@xvalues) {
		if ($citeto{$value}) {
			$citeto{$value} = "$citeto{$value},$pid";
		} else {
			$citeto{$value} = $pid;
		}
	}
}

use POSIX;
my @edges;
foreach my $pid (@pmids) {
	if ($source{$pid} == "pm") {
		if ($icites{$pid} != 0 || $citeto{$pid} != "") {
			my @l=split(",",$auth{$pid}); my @ll=split("/",$datep{$pid});
			my $xauth=$l[0]." (".$ll[1].")";
			my $nodecolor = $lnetgradient[floor($icites{$pid}/$chunk)];
			print "{data: { id: '$pid', label:\"$xauth\\n$pid\", grade: '$icites{$pid}', color: '$nodecolor'}},\n";
			my @sours = split(",", $citedby{$pid});
			foreach my $sour (@sours) {
				if ( grep( /^$sour$/, @pmids ) ) {
					my $edge = "{data: { id: '$sour-$pid', source: '$sour', target: '$pid' }},\n";
					push(@edges, $edge);
					}
		  		}
			}
		}
	}
foreach my $edge (@edges) {
	print $edge;
}


print"
  ],
  style: [
    {
      selector: 'node',
      style: {
        'shape': 'ellipse',
        'width': 65,
        'background-color': function (ele){return ele.data('color')},
        'text-wrap': 'wrap',
        'content': 'data(label)',
        'text-valign': 'center',
        'font-size': 8,
      }
    },

    {
      selector: 'edge',
      style: {
        'width': 3,
        'line-color': '#ccc',
        'target-arrow-color': '#ccc',
        'target-arrow-shape': 'triangle',
        'curve-style': 'bezier'
      }
    },
    {
      selector: 'node.highlight',
      style: {
        'border-color': '#ff00fb',
        'border-width': '3px'
      }
    },
    {
      selector: 'node.income',
      style: {
        'border-color': '#00ffc5',
        'border-width': '2px'
      }
    },
    {
      selector: 'node.outgo',
      style: {
        'border-color': '#ff3030',
        'border-width': '2px'
    }
    },
    {
      selector: 'node.semitransp',
      style:{ 'opacity': '0.5' }
    },
    {
      selector: 'edge.income',
      style: { 'line-color': '#00ffc5', 'target-arrow-color': '#00ffc5'  }
    },
    {
      selector: 'edge.outgo',
      style: { 'line-color': '#ff3030', 'target-arrow-color': '#ff3030'  }
    },
    {
      selector: 'edge.semitransp',
      style:{ 'opacity': '0.2' }
    }
  ],

  layout: {
    name: 'random',
  }

});

cy.on('tap', 'node', function (evt) {
         var node = evt.target;
         filldetails(node.id(), cycenter = false)
         movetorow(\"tr\"+node.id())
    })
    
cy.on('cxttapstart', 'node', function(evt){
	cy.elements().removeClass('semitransp');
	cy.elements().removeClass('income');
	cy.elements().removeClass('outgo');
	var sel = evt.target;
	cy.elements().difference(sel.neighborhood()).not(sel).addClass('semitransp');
	sel.addClass('outgo');
	sel.incomers().addClass('income');
	sel.outgoers().addClass('outgo');
})

document.getElementById(\"pmnetwork\").onclick = function(evt){
	cy.elements().removeClass('semitransp');
	cy.elements().removeClass('income');
	cy.elements().removeClass('outgo');   
};


function isThisNode(id) {
  cy.elements().removeClass('highlight');
  var node = cy.getElementById(id);
  node.addClass('highlight');
}

var current_layout;

function changeLayout (layoutName) {
  if (layoutName == 'cose') {
    var layout = cy.layout({
        name: layoutName,
        refresh: 1000,
        nodeRepulsion: node => 4500
      });
    layout.run();
  } else if (layoutName == 'klay') {
    var layout = cy.layout({
        name: layoutName,
        klay: {
          spacing: 10,
        }
      });
    layout.run();
  } else if (layoutName == 'cose_then_cola') {
    var layout = cy.layout({
        name: 'cose',
        refresh: 100,
        nodeRepulsion: node => 4500,
        stop: function () {
        	changeLayout ('cola');
        	}
        });
     layout.run();
  } else {
    var layout = cy.layout({
        name: layoutName
      });
    layout.run();
  }
 current_layout = layoutName;
}

changeLayout ('$defaultLayout');


\n";

print "</script>";
}###here ends the else 

print "</div>\n";

print "<script>\n";
print "runTerms()\n"; #To automatically run the perl uterms
print "</script>\n";


print "\n</body>\n</html>\n";


###REMOVE tmp directory


rmtree( $tmpdir ) or die "Couldn't remove $tmpdir directory, $!";

if($fverbose==1){print STDERR "\n\n";}

exit 0;


## --SUBROUTINES--


# Coloring mesh terms.

my $borrarA = 0;
my $borrarB = 0;

sub hmesh {
my ($text) = @_;
#my $textA = $text;
#my $textB = $text;
my $color;
#my $xmatchesA = 0;
#my $xmatchesB = 0;
foreach my $i (1..$nmesh){
	my $color="#000000";
	my @xl = split("\t", $mclass[$i]);
	$color= $xl[0];
	#print STDERR "> $mui[$i] $mclass[$i] ($mprint[$i])\n";
	#print STDERR "   >>> $mprint[$i]:\n";
	my @printed=split("\\|",$mprint[$i]);
	foreach my $j (@printed) {
		#print STDERR "($j)\n"
		if($j eq "") {next;}
		$j=~s/\(/\\(/g;$j=~s/\)/\\)/g;$j=~s/\[/\\[/g;$j=~s/\]/\\]/g;  # To avoid simbols of regexp
		if($text=~/[^a-z]($j)[^a-z]/i){
		#if($text=~/($j)/i){
			#print STDERR "\n\n>>>> $j ($color):\n";
			# Check if match already within a color tag.
			my $match=$1; my $doit=1;
			#if($text=~/<font\scolor=([^<]+?$match[^>]+?)<\/font>/i){
			#	print STDERR "* $match already in font ($1)\n";
			#	$doit=0;
			#	}
			#else {$doit=1;}

			if($doit==1){
				#if($j=~/child/i) {print STDERR "($j) ($mprint[$i]) ($mclass[$i]) $mui[$i]\n";}
				#print STDERR "($match) [$text]\n\n";
				$text =~ s/(\w*$j\w*)/<b><font color=$color>$1<\/font><\/b>/ig;
				## --Matches methods--:
				#$xmatchesA += $textA =~ s/(\w*$j\w*)/<b><font color=$color>$1<\/font><\/b>/ig; ## HERE ????
				#$xmatchesB += $textB =~ s/([^a-z0-9])($j)([^a-z0-9])/$1<b><font color=$color>$2<\/font><\/b>$3/ig;
				## --Matches methods comparation--:
				#my $eqmatches = '!!!!!=matches';
				#if ($xborrarA eq $xborrarB) {$eqmatches = '======matches'}
				#if ($textA eq $textB) {
				#  $text = $textA;
				#} else {
				#  $text = $textA."<br><br>$xborrarA<br>$eqmatches<br>$xborrarB<br><br>".$textB;
				#}
				#$borrarA = $borrarA + $xborrarA;
				#$borrarB = $borrarB + $xborrarB;
				#print STDERR "[$text]\n\n\n";
				}
			}
		}
	}
return $text;
}

## Coloring user terms. NOT USED.

#sub coluserterms{
#my ($text) = @_;
#foreach my $term (@userterms) {
#  if($text=~/[^a-z]($term)[^a-z]/i) {
#    $text =~ s/(\w*$term\w*)/<b><font color=$utermscolor>$1<\/font><\/b>/ig;
#    }
#  }
#return $text;
#}



# Error messages for when files cannot be opened
sub qerror {   ### Later adapt to web
my ($msg) = @_;
print STDERR "$msg";
exit 0;
}

# Change month number for month name
sub monthn{
my ($m) = @_;
my $ret=$m;
if($m == 1) {$ret="Jan";}
if($m == 2) {$ret="Feb";}
if($m == 3) {$ret="Mar";}
if($m == 4) {$ret="Apr";}
if($m == 5) {$ret="May";}
if($m == 6) {$ret="Jun";}
if($m == 7) {$ret="Jul";}
if($m == 8) {$ret="Aug";}
if($m == 9) {$ret="Sep";}
if($m == 10) {$ret="Oct";}
if($m == 11) {$ret="Nov";}
if($m == 12) {$ret="Dec";}
return $ret;
}


# monthn reverse
sub monthnr{
my ($m) = @_;
my $ret=$m;
if($m eq "Jan" ) {$ret="01";}
if($m eq "Feb" ) {$ret="02";}
if($m eq "Mar" ) {$ret="03";}
if($m eq "Apr" ) {$ret="04";}
if($m eq "May" ) {$ret="05";}
if($m eq "Jun" ) {$ret="06";}
if($m eq "Jul" ) {$ret="07";}
if($m eq "Aug" ) {$ret="08";}
if($m eq "Sep" ) {$ret="09";}
if($m eq "Oct" ) {$ret="10";}
if($m eq "Nov" ) {$ret="11";}
if($m eq "Dec" ) {$ret="12";}
return $ret;
}

# print html header
sub html_head {
print "<!DOCTYPE html>\n";
print "<html>\n";
print "<head>\n";
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n";
print "<title>PMID list digest: $title</title>\n";
#print "<link rel=\"stylesheet\" type=\"text/css\" href=\"./digest.css\" media=\"screen\">\n";
#print "<script src=\"./sorttable.js\"></script>\n";
#print "<script src=\"cytoscape.min.js\"></script>\n";
print "<script src=\"$auxiliar_files_dir/cytoscape.min.js\"></script>\n";
print "<link rel=\"stylesheet\" type=\"text/css\" href=\"$auxiliar_files_dir/styles.css\" media=\"screen\">\n";
print "<script src=\"$auxiliar_files_dir/sorttable.js\"></script>\n";
print "<script src=\"$auxiliar_files_dir/klay.js\"></script>\n";
print "<script src=\"$auxiliar_files_dir/cytoscape-klay.js\"></script>\n";
print "<script src=\"$auxiliar_files_dir/dagre.js\"></script>\n";
print "<script src=\"$auxiliar_files_dir/cytoscape-dagre.js\"></script>\n";
print "<script src=\"$auxiliar_files_dir/cola.min.js\"></script>\n";
print "<script src=\"$auxiliar_files_dir/cytoscape-cola.js\"></script>\n";

}





