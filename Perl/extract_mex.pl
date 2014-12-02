#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
}

parse_command_line( ssj => {description=>'the splice junction file', ifunreadable=>'bed not specified'},
		    annot => {description=>'annotation file', ifunreadable=>'annotation not provided'},
                    minstaggered=>{description=>'he minimum umber of staggered reads', default=>2},
                    nucleotides =>{description=>'the splice site nucleotides', default=>GTAG});


open FILE, $annot || die ('Cannot read annotation');
    while($line=<FILE>) {
    chomp $line;
    ($chr, $source, $feature, $beg, $end, $score, $str, $frame, $group) = split /\t/, $line;
    if($feature eq "exon") {
        $EX{$chr}{$beg}{$end}{$str}++;
    }
}
close FILE;


open FILE, $ssj || die();
while($line=<FILE>) {
    chomp $line;
    ($id, $total, $staggered, $entropy, $annot, $nuc) = split /\t/, $line;
    $jnc{$id}++ if($nuc eq $nucleotides && $staggered>=$minstaggered);
}
close FILE;

while($line=<STDIN>) {
    chomp $line;
    ($id, $deg, $offset, $count) = split /\t/, $line;
    $id ="chr$id" unless($id=~/^chr/);
    ($chr, $x, $y, $z, $t, $strand) = split /\_/, $id;
    foreach $str("+", "-") {
        if($strand eq $str || $strand eq '.') {
    	    print join("\t", join("_", $chr, $y, $z, $str), $deg, $offset, $count), "\n" if($jnc{join("_", $chr, $x, $y, $str)} && $jnc{join("_", $chr, $z, $t, $str)} && !$EX{$chr}{$y}{$z}{$str});
	}
    }
}
