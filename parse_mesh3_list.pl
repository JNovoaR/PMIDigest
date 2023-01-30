use strict;

#
#


if ($#ARGV<1) {die "** Usage:  parse_mesh  d2021.bin  list index_idsncolors\n";}

my @dis_mh; my @dis_entry; my @dis_ui; my @dis_mn; my $ndis=0;
my @other_mh; my @other_entry; my @other_ui; my @other_mn; my $nother=0;
my @org_mh; my @org_taxid; my @org_ui; my @org_mn; my @org_entry; my $norg=0;
my $xmh; my $xentry; my $xui; my @xst;
my $xtaxid;
my @comp_nm; my @comp_sy; my @comp_hm; #For info in cxxxxx. Just in case.
my @comp_mh; my @comp_mn; my @comp_rnrr; my @comp_pa; my @comp_pi;  my @comp_ui; my $ncomp=0;
my $xnm; my $xrr; my $xsy; my $xpa; my $xpi; my $xhm; my $xmn;
my $orgf=0;my $disf=0;my $compf=0;my $otherf=0; # Flags to detect interesting concepts.

my @meshlist=();
open my $fp, "<", $ARGV[1] or die "** Can't r-open '$ARGV[1]'\n";
while(<$fp>){chop; push (@meshlist,$_);}
close $fp;

my @meshcolors=();
open my $fp, "<", $ARGV[2] or die "** Can't r-open '$ARGV[1]'\n";
while(<$fp>){chop;if (substr($_, 0, 1) ne "#"){push (@meshcolors,uc($_))}}
close $fp;

foreach my $file (0..1){
open my $fp, "<", $ARGV[$file] or die "** Can't r-open '$ARGV[$file]'. Make sure you properly downloaded, named and placed mesh database, as described in PMIDigest's README.md \n";
while(<$fp>){
	chop;
	if(substr($_,0,10) eq "*NEWRECORD"){
		$xmh=""; $xentry=""; $xui=""; $xtaxid=""; @xst=();
		$xnm=""; $xrr=""; $xsy=""; $xpa=""; $xpi=""; $xhm="";
		$xmn="";
		}
	if($_=~ /^NM\s=\s(.+?)$/){
		#print "$_\n$1\n\n";
		$xnm=$1;
		}
	if($_=~ /^R[RN]\s=\s(.+?)$/){
		my $xs=$1; if ($xs =~ /(.+?)\s/) {$xs=$1;}
		#print "$_\n$xs\n\n";
		$xrr=$xrr.$xs."|";
		}
	if($_=~ /^SY\s=\s(.+?)$/){
		my $xs=$1; if ($xs =~ /(.+?)\|/) {$xs=$1;}
		#print "$_\n$xs\n\n";
		$xsy=$xsy.$xs."|";
		}
	if($_=~ /^HM\s=\s(.+?)$/){
		my $xs=$1; if ($xs =~ /(.+?)\/\*/) {$xs=$1;}
		#print "$_\n$xs\n\n";
		$xhm=$xhm.$xs."|";
		}
	if($_=~ /^PA\s=\s(.+?)$/){
		my $xs=$1; if ($xs =~ /(.+?)\|/) {$xs=$1;}
		#print "$_\n$xs\n\n";
		$xpa=$xpa.$xs."|";
		}
	if($_=~ /^PI\s=\s(.+?)$/){
		my $xs=$1; if ($xs =~ /(.+?)\|/) {$xs=$1;}
		#print "$_\n$xs\n\n";
		$xpi=$xpi.$xs."|";
		}
	
	if($_=~ /^ENTRY\s=\s(.+?)$/ ||  /^PRINT\sENTRY\s=\s(.+?)$/){
		my $xs=$1; if ($xs =~ /(.+?)\|/) {$xs=$1;}
		#print "$_\n$xs\n\n";
		$xentry=$xentry.$xs."|";
		}
	if($_=~ /^MH\s=\s(.+?)$/){
		#print "$_\n$1\n\n";
		$xmh=$1;
		}
	if($_=~ /^UI\s=\s(.+?)$/){
		#print "$_\n$1\n\n";
		$xui=$1;
		}
	if($_=~ /^ST\s=\s(.+?)$/){
		#print "$_\n$1\n\n";
		push(@xst,$1);
		}
	if($_=~ /^MN\s=\s(.+?)$/){
		#print "$_\n$1\n\n";
		$xmn=$xmn.$1."|";
		}
	if($_=~ /^RN\s=\stxid(\d+)$/){
		#print "$_\n$1\n\n";
		$xtaxid=$1;
		}
	if($_ eq ""){
		chop $xentry; chop $xmn; chop $xrr; chop $xsy; chop $xhm; chop $xpa; chop $xpi;
		$orgf=0; $disf=0; $compf=0; $otherf=0;
		my $pst=join(",",@xst);
		my $wordcolor = "#000000";
		my $relevant = 0;
		foreach my $groupncolor (@meshcolors) {
			my @l_groupncolor = split("	", $groupncolor);
			my $group =$l_groupncolor[0];
			my $color = $l_groupncolor[1];
			if(grep(/^$group$/,@xst)) {
				$wordcolor = $color;
				$relevant = 1;		
			}
		}
		# 
		# Just print. I.e. print for an input list of UIDs of interest
		
		my $found=0;
		foreach my $i (@meshlist){
			if($i eq $xui){$found=1; last;}
			}
		
		if($found==1 && $relevant == 1){
			print "$wordcolor\t$xui\t$xmh\t$xentry\t$xtaxid\t$xnm\t$xrr\t$xsy\t$xpa\t$xpi\t$xhm\t$xmn\t$pst\n";
			#print STDERR "$wordcolor\t$xui\t$xmh\t$xentry\t$xtaxid\t$xnm\t$xrr\t$xsy\t$xpa\t$xpi\t$xhm\t$xmn\t$pst\n";
			}
		#
		}
	
	}
close $fp;
}

#
# So far so good. Diseases and microorganisms apparently ok
#


exit;


