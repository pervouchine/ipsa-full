#!/usr/bin/perl
use lib qw(/users/rg/dmitri/software/utils/);
use utils;;

if(@ARGV==0) {
}

parse_command_line(i => {description=>'input gtf file name and label', array=>hash});

%input  = @i;

die unless(keys(%input)>0);

foreach $file(keys(%input)) {
    $name = $input{$file};
    print STDERR "[$file $name";
    open FILE, $file;
    while($line = <FILE>) {
	($id, $count, $stag, $entropy, $annot, $nucl) = split /\t/, $line;
	$log2count = int(log($count)/log(2));
	for($i=0; $i<=$log2count; $i++) {
	    $data{$annot}{$id}{$i}++;
	}
	$maxlog2count = $log2count if($maxlog2count < $log2count);
    }
    print STDERR "]", $n++, "\n";
    close FILE;
}

##############################################
# $data{$annot}{$id} : x -> number of samples with log2count >= x
##############################################

foreach $annot(sort keys(%data)) {
    print STDERR join("\t", $annot, 0+keys(%{$data{$annot}})), "\n";
}

##############################################
# freq{annot}{x} : n -> # of SJ that have count>=x in exactly n samples 
##############################################

foreach $annot(keys(%data)) {
    foreach $id(keys(%{$data{$annot}})) {
	foreach $log2count(keys(%{$data{$annot}{$id}})) {
	    $nsp = $data{$annot}{$id}{$log2count};
	    $freq{$annot}{$log2count}{$nsp}++;
	}
    }
}

##############################################
# freq{annot}{x} : n -> # of SJ that have count>=x in exactly n samples  
##############################################

foreach $annot(keys(%freq)) {
    foreach $log2count(keys(%{$freq{$annot}})) {
	foreach $nsp(keys(%{$freq{$annot}{$log2count}})) {
	    for($i=1; $i<=$nsp; $i++) {
		$res{$annot}{$log2count}{$i} += $freq{$annot}{$log2count}{$nsp};
	    }
	}
    }
}

foreach $annot(sort {$a<=>$b} keys(%data)) {
    for($log2count=0; $log2count<=$maxlog2count; $log2count++) {
	for($nsp=1; $nsp<=$n; $nsp++) {
	    $s=$res{$annot}{$log2count}{$nsp}+0;
	    print join("\t", $annot, $log2count, $nsp, $s), "\n";
	}
    }
}
