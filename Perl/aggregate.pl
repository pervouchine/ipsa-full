#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility aggregates tsv output of sjcount (STDIN) by the 5th column (offset) and outputs BED6+3 (STDOUT) with three extra columns being ";
    print STDERR "(7) total count, (8) staggered read count, (9) entropy\n";
}

parse_command_line(margin	=>{default=>0, 	description=>'the margin for offset'}, 
		   readLength	=>{default=>0, 	description=>'the read length'}, 
		   minintron	=>{default=>0,	description=>'min intron length'},
		   maxintron    =>{default=>0,  description=>'max intron length'}
		  );

while($line=<STDIN>) {
    chomp $line;
    ($chr, $beg, $end, $str, $offset, $count) = split /\t/, $line;
    $chr ="chr$chr" unless($chr=~/^chr/);
    next if($readLength && $margin && ($offset < $margin || $offset >= $readLength - $margin));
    next if($minintron  && ($end - $beg < $minintron + 2) || $maxintron && ($end - $beg > $maxintron + 2));
    push @{$data{$chr}{$beg}{$end}{$str}}, $count;
}

foreach $chr(sort keys(%data)) {
    foreach $beg(sort {$a<=>$b} keys(%{$data{$chr}})) {
	foreach $end(sort {$a<=>$b} keys(%{$data{$chr}{$beg}})) {
	    foreach $str(keys(%{$data{$chr}{$beg}{$end}})) {
		@stats = sum(@{$data{$chr}{$beg}{$end}{$str}});
		$score = sprintf("%.0f", 100*log($stats[0])/log(2));
		$score = 1000 if($score > 1000);
	    	print join("\t", $chr, $beg, $end, '.', $score, $str, @stats), "\n";
	    }
	}
    }
}
		
sub sum {
    my $s = 0;
    my $c = 0;
    my $l = 0;
    foreach $val(@_) {
	$s+=$val;
	$c+=1;
	$l+=$val*log($val);
    }
    my $h = sprintf("%.2f", (log($s) - $l/$s)/log(2));
    return($s, $c, $h>0 ? $h : 0);
}
