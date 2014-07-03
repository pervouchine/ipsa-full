#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility takes a REFSEQ tsv annotation (STDIN) and reformats it into a more compact, quickly readable file (STDOUT). Only exons are taken into account.\n";
}

parse_command_line(source=>{description=>'the content of the source field', default=>'SJPIPE'}, verbose=>{store=>T});

while($line=<STDIN>) {
    chomp $line;
    ($trash, $tid, $chr, $str, $trash, $trash, $trash, $trash, $trash, $starts, $ends) = split /\t/, $line;
    next if($chr=~/\_/);
    @starts = split /\,/, $starts;
    @ends   = split /\,/, $ends;
    for($i=0;$i<@starts;$i++) {
	$beg = $starts[$i];
	$end = $ends[$i];
	($beg, $end) =  sort {$a<=>$b} ($beg, $end);
	print join("\t", $chr, $source, 'exon', $beg, $end, '.', $str, '.', set_attributes(transcript_id=>$tid)), "\n";
    }
}


