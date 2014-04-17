#!/usr/bin/perl
use lib qw(/users/rg/dmitri/software/utils/);
use utils;

if(@ARGV==0) {
    print STDERR "input: STDIN, output: STDOUT\n";
}

parse_command_line(exons => {description=>'exons tsv file (4 columns)'});

if(-r $exons) {
    print STDERR "[<$exons";
    open FILE, $exons;
    while(<FILE>){
    	chomp;
    	($chr, $source, $feature, $beg, $end, $score, $str) = split /\t/;
	next unless($feature eq "exon");
    	$ann{join("\t", $chr, $beg, $str)} = $ann{join("\t", $chr, $end, $str)} = 1;
    }
    close FILE;
    print STDERR "]\n";
}

$line=<STDIN>;
print $line;
while($line=<STDIN>){
    chomp $line;
    @array = split /\t/, $line;
    ($chr, $a, $b, $c, $d, $str) = split /\_/, shift(@array);
    $chr = "chr$chr" unless($chr=~/^chr/);
    next unless((! -r $exons) || $ann{join("\t", $chr, $a, $str)} && $ann{join("\t", $chr, $d, $str)});
    $id = join("_", $chr, $b, $c, $str);
    for($i=0; $i<@array; $i++) {
	$data{$id}[$i]+=$array[$i];
    }
}

foreach $id(sort keys(%data)) {
    print join("\t", $id, @{$data{$id}}), "\n";
}
