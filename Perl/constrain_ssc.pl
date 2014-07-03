#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility takes a BED6 ssc file (STDIN) and constraints its content to splice sites which are present in BED6 ssj file (STDOUT)\n";
}

parse_command_line(ssj => {description=>'input ssj with constraints', ifunreadable=>'input not readable'});

open FILE, "<$ssj" || die;
while($line=<FILE>) {
    chomp $line;
    ($chr, $beg, $end, $str, $rest) = split /\t/, $line, 5;
    $data{$chr}{$beg}{$str}=1;
    $data{$chr}{$end}{$str}=1;
}
close FILE;

while($line=<STDIN>) {
    chomp $line;
    ($chr, $pos, $trash, $strand, $rest) = split /\t/, $line, 5;
    foreach $str("+", "-") {
        print join("\t", $chr, $pos, $pos, $str, $rest),"\n" if(($strand eq $str || $strand eq '.') && $data{$chr}{$pos}{$str});
    }
}


