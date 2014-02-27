#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility computes exon inclusion rates based on the quantifiaction data\n"; 
}

parse_command_line(annot=>{description=>'the genomic annotation', ifunreadable=>'the genomic annotation is missing'},
		   quant=>{description=>'the transcript quantification file (gtf/gff)', ifunreadable=>'the quantification file missing'},
		   minc =>{description=>'the minimum sum of rpkms to consider the inclusion ratio as reliable', default=>0});
		
#######################################################################################################################

print STDERR "[<$annot";
open FILE, $annot || die();
while($line=<FILE>) {
    chomp $line;
    ($chr, $trash, $element, $beg, $end, $trash, $str, $attr) = split /\t/, $line;
    next unless($element eq "exon");
    $chr = "chr$chr" unless($chr=~/^chr/);
    $eid = join("_", $chr, $beg, $end, $str);
    %attr = get_attributes($attr);
    foreach $tid(split /\,/, $attr{'belongsto'}) {
	$TE{$tid}{$eid}++;
    }
    $exon{$chr}{$str}{$beg}{$end}++;
}
close FILE;
print STDERR ", indexing";

foreach $chr(keys(%exon)) {
    foreach $str(keys(%{$exon{$chr}})) {
    	foreach $beg(sort {$a<=>$b} keys(%{$exon{$chr}{$str}})) {
	    foreach $end(sort {$a<=>$b} keys(%{$exon{$chr}{$str}{$beg}})) {
	    	push @{$loe{$chr}{$str}}, [$beg, $end];
	    }
	}
    }
}
print STDERR "]\n";

print STDERR "[<$quant";
open FILE, $quant || die();
while($line=<FILE>) {
    chomp $line;
    ($chr, $source, $element, $beg, $end, $name, $str, $trash, $attr) = split /\t/, $line;
    $chr = "chr$chr" unless($chr=~/^chr/);
    %attr = get_attributes($attr);

    $tid = $attr{'transcript_id'};
    $abundance = $attr{'RPKM'} ? $attr{'RPKM'} : 0.5*($attr{'RPKM1'} + $attr{'RPKM2'});

    while($curr{$chr}{$str} < @{$loe{$chr}{$str}} && $loe{$chr}{$str}->[$curr{$chr}{$str}]->[0]<$beg) {$curr{$chr}{$str}++;}
    for($i=$curr{$chr}{$str}; $i<@{$loe{$chr}{$str}} && $loe{$chr}{$str}->[$i]->[0]<=$end; $i++) {
	next unless($loe{$chr}{$str}->[$i]->[1]<=$end);
	$eid = join("_", $chr, @{$loe{$chr}{$str}->[$i]}, $str);
	$tot{$eid}+=$abundance;
    }
    foreach $eid(keys(%{$TE{$tid}})) {
	$inc{$eid} += $abundance;
    }
}
close FILE;
print STDERR "]\n";


print STDERR "[>stdout";
foreach $chr(keys(%exon)) {
    foreach $str(keys(%{$exon{$chr}})) {
	for($i=0; $i<@{$loe{$chr}{$str}}; $i++) {
	    $eid = join("_", $chr, @{$loe{$chr}{$str}->[$i]}, $str);
	    $psi  = frac($inc{$eid}, $tot{$eid} - $inc{$eid});
	    print join("\t", $chr, 'TXPIPE', 'exon', @{$loe{$chr}{$str}->[$i]}, int(1000*$psi), $str, '.', set_attributes(psi=>$psi, inc=>$inc{$eid}, tot=>$tot{$eid})), "\n";
	}	
    }
}
print STDERR "]\n";

