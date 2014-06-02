#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility aggregates the output of sjcount (STDIN) by the 5th column (offset) and outputs a TSV (STDOUT) with three extra columns being ";
    print STDERR "(5) total count, (6) staggered read count, (7) entropy\n";
}

parse_command_line( ssj => {description=>'the splice junction file', ifunreadable=>'bed not specified'},
                    minstaggered=>{description=>'he minimum umber of staggered reads', default=>2},
                    nucleotides =>{description=>'the splice site nucleotides', default=>GTAG});

open FILE, $ssj || die();
while($line=<FILE>) {
    chomp $line;
    ($chr, $beg, $end, $strand, $total, $staggered, $entropy, $annot, $nuc) = split /\t/, $line;
    $jnc{join("\t", $chr, $beg, $end, $strand)}++ if($nuc eq $nucleotides && $staggered>=$minstaggered);
}
close FILE;

while($line=<STDIN>) {
    chomp $line;
    ($id, $deg, $offset, $count) = split /\t/, $line;
    next unless($deg==2);
    ($chr, $x, $y, $z, $t, $str) = split /\_/, $id;
    next unless($jnc{join("\t", $chr, $x, $y, $str)} && $jnc{join("\t", $chr, $z, $t, $str)});
    push @{$data{$id}}, $count;
}

foreach $id(sort keys(%data)) {
    print join("\t", $id, aggstat(@{$data{$id}})), "\n";
}
