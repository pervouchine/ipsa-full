#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This script checks multiple SJ paths against already annotated SJs\n";
    print STDERR "Input : tsv file on STDIN\n";
}

parse_command_line( ssj => {description=>'the splice junction file', ifunreadable=>'bed not specified'},
		    minstaggered=>{description=>'he minimum umber of staggered reads', default=>2},
		    nucleotides =>{description=>'the splice site nucleotides', default=>GTAG});

open FILE, $ssj || die();
while($line=<FILE>) {
    chomp $line;
    ($chr, $beg, $end, $strand, $total, $staggered, $entropy, $annot, $nuc) = split /\t/, $line;
    $jnc{join("\t", $chr, $beg, $end, $strand)}++ if($nuc eq $nucleotides && $staggered>=$minstaggered);
}
close FILE;

while($line=<STDIN>) {
    ($chr, $strand, $n, $locations) = split /\t/, $line;
    $chr = "chr$chr" unless($chr=~/^chr/);
    $flag = 1;
    @array = split /\,/, $locations;
    for($i=0;$i<@array;$i++) {    
	($beg, $end, $offset) = split /\:/, $array[$i];
	$flag = undef unless($jnc{join("\t", $chr, $beg, $end, $strand)}); 
    }
    print $line if($flag);
}

