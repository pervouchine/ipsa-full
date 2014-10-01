#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
}

#parse_command_line(i => {description=>'input gtf file name and label', array=>hash});

#%input  = @i;

#die unless(keys(%input)>0);

@annot = (0,1,2,3);

foreach $file(@ARGV) {
    $name = $input{$file};
    print STDERR "[$file $name";
    open FILE, $file;
    while($line = <FILE>) {
	($chr, $beg, $end, $str, $count, $stag, $entropy, $annot, $nucl) = split /\t/, $line;
        $chr = "chr$chr" unless($chr=~/^chr/);
        $id = "$chr\_$beg\_$end\_$str";
	$sum_count{$id}+=$count;
	$sum_stagg{$id}+=$stag;
	@{$status{$id}} = ($annot, $nucl);
    }
    print STDERR "]", $n++, "\n";
    close FILE;
}

foreach $id(sort keys(%status)) {
    print join("\t", $id, $sum_count{$id}, $sum_stagg{$id}, @{$status{$id}}),"\n";
}

