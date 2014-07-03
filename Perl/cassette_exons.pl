#!/usr/bin/perl
use Perl::utils;

#if(@ARGV==0) {
#    print STDERR "This utility extracts cassette exons from gff file\n";
#}

while($line=<STDIN>) {
    chomp $line;
    ($chr, $trash, $element, $beg, $end, $trash, $str, $frame, $attr) = split /\t/, $line;
    $data{$element}{$chr}{$str}{$beg}{$end}++;
    $atad{$element}{$chr}{$str}{$end}{$beg}++;
}

print STDERR "]";

foreach $chr(keys(%{$data{exon}})) {
    foreach $str(keys(%{$data{exon}{$chr}})) {
	foreach $x(keys(%{$data{exon}{$chr}{$str}})) {
	    foreach $y(keys(%{$data{exon}{$chr}{$str}{$x}})) {
		foreach $a(keys(%{$atad{intron}{$chr}{$str}{$x}})) {
		    foreach $b(keys(%{$data{intron}{$chr}{$str}{$y}})) {
			next unless($data{intron}{$chr}{$str}{$a}{$b});
			print join("\t", $chr, $str, $a, $x, $y, $b), "\n";
		    }
		}
	    }
	}
    }

}



