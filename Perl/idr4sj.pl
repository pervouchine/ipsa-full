#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "Generic npIDR routine for more than two bioreplicas\n";
}

@input  = @ARGV;

die unless(@input>0);

foreach $file(@input) {
    print STDERR "[$file ",++$n;
    open FILE, $file;
    while($line = <FILE>) {
	chomp $line;
	($chr, $beg, $end, $str, $count, $stagg, $entrp, $annot, $nucl) = split /\t/, $line;
        $chr = "chr$chr" unless($chr=~/^chr/);
        $id = "$chr\_$beg\_$end\_$str";
	push @{$val{$id}}, $count;
	$count{$id} += $count;
	$stagg{$id} += $stagg;
	$entrp{$id} += $entrp;
	$prm{$id}    = [$annot, $nucl];
	$rows{$id}++;
    }
    print STDERR "]\n";
    close FILE;
}

foreach $id(keys(%rows)) {
    @values = @{$val{$id}};
    $nzeroes = 0;                                       # number of zeros in a line
    for($j = $i = 0; $i < @values; $i++) {
        $values[$i] = int($values[$i]);
        if($values[$i] == 0) {
            $nzeroes++;                                 # count number of zeros in the line
        }
        else {
            $j = $i;                                    # memorize non-zero value
        }
        $absolute{$values[$i]}++;                       # absolute counter incremented always
    }
    $conditional{$values[$j]}++ if($nzeroes == @values - 1); # conditional counter incremented if zeroes are in all replicas but one
}
foreach $id(sort keys(%rows)) {
    ($chr, $beg, $end, $str) = split /\_/, $id;
    $idr = sprintf("%.4lf", $absolute{$count{$id}} ? $conditional{$count{$id}}/$absolute{$count{$id}} : 0);
    $idr =~ s/\.*0+$//;
    print join("\t", $chr, $beg, $end, $str, $count{$id}/$n, $stagg{$id}/$n, $entrp{$id}/$n, @{$prm{$id}}, $idr), "\n";
}
