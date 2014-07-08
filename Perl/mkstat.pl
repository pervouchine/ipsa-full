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
	$log2count = int(log($count)/log(2));
	for($i=0; $i<=$log2count; $i++) {
	    $data{$annot}{$id}{$i}++;
	}
	$maxlog2count = $log2count if($maxlog2count < $log2count);
    }
    print STDERR "]", $n++, "\n";
    close FILE;
}
## $data{$annot}{$id} : x |-> number of samples with count at least x

##############################################

foreach $annot(keys(%data)) {
    print STDERR join("\t", $annot, 0+keys(%{$data{$annot}})), "\n";
}

foreach $annot(keys(%data)) {
    foreach $id(keys(%{$data{$annot}})) {
	foreach $log2count(keys(%{$data{$annot}{$id}})) {
	    $nsp = $data{$annot}{$id}{$log2count};
	    $freq{$annot}{$log2count}{$nsp}++;
	}
    }
}

for($annot=0; $annot<=3; $annot++) {
    for($log2count=0; $log2count<=$maxlog2count; $log2count++) {
	$s=0;
	for($nsp=1; $nsp<=$n; $nsp++) {
	    $s+=$freq{$annot}{$log2count}{$nsp};
	    print join("\t", $annot, $log2count, $nsp, $s), "\n";
	}
    }
}

#foreach $annot(keys(%data)) {
#    foreach $log2count(keys(%{$freq{$annot}})) {
#	foreach $nsp(keys(%{$freq{$annot}{$log2count}})) {
#	    print join("\t", $annot, $log2count, $nsp, $freq{$annot}{$log2count}{$nsp}), "\n";
#	}
#    }
#}
