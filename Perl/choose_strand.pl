#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility takes a BED6+3+2 file (STDIN) where column #10 is the annotation status and #11 is splice sites, and selects for each pair of beg/end the strand based on these two columns (STDOUT)\n";
}

parse_command_line(annot => {default=>10, description=>'annotation column'},
		   sites => {default=>11, description=>'splice site column'});

while($line=<STDIN>) {
    chomp $line;
    @array = split /\t/, $line;
    push @{$data{$array[0]}{$array[1]}{$array[2]}}, [@array];
}

foreach $chr(sort keys(%data)) {
    foreach $beg(sort {$a<=>$b} keys(%{$data{$chr}})) {
	foreach $end (sort {$a<=>$b} keys(%{$data{$chr}{$beg}})) {
    	    @array = sort my_sort @{$data{$chr}{$beg}{$end}};
	    print join("\t", @{$array[0]}),"\n";
	}
    }
}

sub  my_sort {
    return(-1) if($b->[$annot-1] <  $a->[$annot-1]);
    return(1)  if($b->[$annot-1] >  $a->[$annot-1]);
    return(-1) if($b->[$sites-1] lt $a->[$sites-1]);
    return(1)  if($b->[$sites-1] gt $a->[$sites-1]);
    return(0)
}
