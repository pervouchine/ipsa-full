#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility takes a BED6 ssc file and constraints its content to splice sites which are present in BED6 ssj file\n";
}

parse_command_line(annot => {default=>10, description=>'annotation column'},
		   sites => {default=>11, description=>'splice site column'},
		   ssj   => {description=>'input ssj (bed) file', ifunreadable=>'input not readable'},
                   ssc   => {description=>'input ssc (bed) file', ifunreadable=>'input not readable'});

open FILE, "<$ssj" || die;
while($line=<FILE>) {
    chomp $line;
    ($chr, $beg, $end, $name, $score, $str, $rest) = split /\t/, $line, 7;
    $data{$chr}{$beg}{$str}=1;
    $data{$chr}{$end}{$str}=1;
}
close FILE;

open FILE, "<$ssc" || die;
while($line=<FILE>) {
    chomp $line;
    ($chr, $pos, $pos, $name, $score, $strand, $rest) = split /\t/, $line, 7;
    foreach $str("+", "-") {
        print join("\t", $chr, $pos, $pos, $name, $score, $str, $rest),"\n" if(($strand eq $str || $strand eq '.') && $data{$chr}{$pos}{$str});
    }
}
close FILE;

