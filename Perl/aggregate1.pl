#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility aggregates the output of sjcount (STDIN) by the 5th column (offset) and outputs a TSV (STDOUT) with three extra columns being ";
    print STDERR "(5) total count, (6) staggered read count, (7) entropy\n";
}

parse_command_line(margin	=>{default=>0, 	description=>'the margin for offset'}, 
		   readLength	=>{default=>0, 	description=>'the read length'}, 
		   minintron	=>{default=>4,	description=>'min intron length'},
		   maxintron    =>{default=>0,  description=>'max intron length'}
		  );

while($line=<STDIN>) {
    chomp $line;
    ($id, $deg, $offset, $count) = split /\t/, $line;
    next unless($deg==1);
    ($chr, $beg, $end, $str) = split /\_/, $id;
    $chr ="chr$chr" unless($chr=~/^chr/);
    next if($readLength && $margin && ($offset < $margin || $offset >= $readLength - $margin));
    next if($minintron  && ($end - $beg < $minintron + 2) || $maxintron && ($end - $beg > $maxintron + 2));
    push @{$data{$chr}{$beg}{$end}{$str}}, $count;
}

foreach $chr(sort keys(%data)) {
    foreach $beg(sort {$a<=>$b} keys(%{$data{$chr}})) {
	foreach $end(sort {$a<=>$b} keys(%{$data{$chr}{$beg}})) {
	    foreach $str(keys(%{$data{$chr}{$beg}{$end}})) {
		@stats = aggstat(@{$data{$chr}{$beg}{$end}{$str}});
	    	print join("\t", $chr, $beg, $end, $str, @stats), "\n";
	    }
	}
    }
}
