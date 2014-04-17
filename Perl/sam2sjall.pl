#!/usr/bin/perl
use Perl::utils;
use Switch;

if(@ARGV==0) {
    print STDERR "This is a line-based utility for extracting splice junctions from SAM files\n";
    print STDERR "Input is a SAM file (better to contrain to lines with 2 or more Ns)\n";
    print STDERR "Output is tsv: chr/strand/number_of_splits/[beg/end/offset]/[beg/end/offset]/.../count\n";
}

parse_command_line( read1 => {description=>'flip read1 yes/no (1/0)', default=>1},
		    read2 => {description=>'flip read2 yes/no (1/0)', default=>0},
		    maxnh => {description=>'max NH tag value',default=>0},
		    lim   => {description=>'stop after this number of lines (for debug)',default=>0});
 
$BAM_FREAD1 = 0x40;
$BAM_FREAD2 = 0x80;
$BAM_FREVERSE = 0x10;
@STRAND = ("+", "-");

@read = ($read1, $read2);
for($s=0; $s<2; $s++) {
    print STDERR "[Warning: will take reverse complement of read ", $s+1, "]\n" if($read[$s] % 2);
}


while(<STDIN>){
    ($id, $flag, $ref, $pos, $qual, $cigar, $RNEXT, $PNEXT, $TLEN, $SEQ, $QUAL, $rest) = split /\t/, $_, 12;
    $s = (($flag & $BAM_FREVERSE)>0);
    $strand = ($flag & $BAM_FREAD1) ? ($s + $read[0]) & 1 : ($s + $read[1]) & 1;
    $NH = ($rest =~ /NH\:i\:(\d+)/ ? $1 : 0);

    $n++;
    last if($n>$lim && $lim>0);

    next if($NH>$maxnh && $maxnh>0);

    @array = ();
    $offset = 0;
    while($cigar=~/(\d+)(\w)/g) {
        $increment = $1;
        $operation = $2;
        switch($operation) {
	    case 'M' {	$pos += $increment;
			$offset+=$increment; 
		     }
	    case 'I' {  $offset+=$increment; 
		     }
	    case 'D' {  $pos += $increment;  
		     }
	    case 'N' {  push @array, join(":", $pos - 1, $pos + $increment, $offset); 
			$pos += $increment; 
		     }
	    case 'S' { $offset+=$increment;
		     }
	}
    }
    if(@array>0) {
	$count{join("\t", $ref, $STRAND[$strand], 0+@array, join(",",@array))}++;
    }
}

foreach $key(keys(%count)) {
    print "$key\t$count{$key}\n";
}
