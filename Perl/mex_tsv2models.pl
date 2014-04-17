#!/usr/bin/perl
use lib qw(/users/rg/dmitri/software/utils/);
use utils;

if(@ARGV==0) {
}

parse_command_line(bed => {description=>'output (GB track) bed file', ifabsent=>"bed file not specified"},
		   gff => {description=>'output models file', ifabsent=>"gff file not specified"},
		   W   => {description=>'margin width', default=>20},
		   exons => {description=>'exons tsv file (4 columns)'},
		   mincount => {description=>'min read count for the path', default=>5});

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

open BED, ">$bed" || die;
open GFF, ">$gff" || die;

$line=<STDIN>;
chomp $line;
@colnames = split /\t/, $line;
while($line=<STDIN>){
    chomp $line;
    @array = split /\t/, $line;
    ($chr, $a, $b, $c, $d, $str) = split /\_/, shift(@array);
    $chr = "chr$chr" unless($chr=~/^chr/);
    next unless((! -r $exons) || $ann{join("\t", $chr, $a, $str)} && $ann{join("\t", $chr, $d, $str)});
    next unless($a - $W>0);
    next unless(sum(@array)>=$mincount);
    $transcript_id++;
    @segm = ($a - $W, $a, $b, $c, $d, $d + $W);
    @block_len = @block_start = ();
    for($i=0;$i<@segm;$i+=2) {
	print GFF join("\t", $chr, 'mexex', 'exon', $segm[$i], $segm[$i+1], '.', $str, '.', "transcript_id \"mexex$transcript_id\";"), "\n";
	push @block_len,   $segm[$i+1] - $segm[$i] + 1;
	push @block_start, $segm[$i] - $segm[0];
    }
    print BED join("\t", $chr, $segm[0]-1, $segm[-1], 'track', 1000, '.', $segm[1]-1, $segm[-2], 0, 0+@block_len, join(",", @block_len), join(",", @block_start)), "\n";
}
close GFF;
close BED;
