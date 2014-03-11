#!/usr/bin/perl
use Perl::utils;

$program = "\${MAPTOOLSDIR}getsegm -limit 4 -margins -1 0 -spacer 0 -type 1";

if(@ARGV==0) {
    print STDERR "This utility takes an aggregated BED6+3 file, the genomic annotation, and the genome, and outputs BED6+3+2 with two more columns: ";
    print STDERR "(10) annotation status and (11) splice sites\n";
    print STDERR "If BED6+3 was strandless ('.' in column 6) then each line will be reported twice, one for '+' and and for '-' strand\n";
}

parse_command_line(	bed	=> {description=>'the input file', ifunreadable=>'input not specified'},
			annot	=> {description=>'the annotation (gff)', ifunreadable=>'annotation not specified'}, 
			dbx	=> {description=>'the genome (dbx)', ifunreadable=>'dbx not specified'},
                        idx     => {description=>'the genome (idx)', ifunreadable=>'idx not specified'});


open FILE, $annot || die;
while($line=<FILE>) {
    chomp $line;
    ($chr, $source, $feature, $beg, $end, $score, $str) = split /\t/, $line;
    next unless($feature eq "intron");
    $sj{$chr}{$beg}{$end}{$str}++;
    $ss{$chr}{$beg}{$str}++;
    $ss{$chr}{$end}{$str}++;
}
close FILE;

%seq = split /[\t\n]/, `$program -dbx $dbx -idx $idx -in $bed`;

open FILE, $bed || die;
while($line=<FILE>) {
    chomp $line;
    ($chr, $beg, $end, $name, $score, $strand, $rest) = split /\t/, $line, 7;
    foreach $str("+", "-") {
	if($strand eq $str || $strand eq '.') {	
	    $status = $sj{$chr}{$beg}{$end}{$str} ? 3 : ($ss{$chr}{$beg}{$str} && $ss{$chr}{$end}{$str} ? 2 : ($ss{$chr}{$beg}{$str} || $ss{$chr}{$end}{$str} ? 1 : 0));
	    $nucl   = $seq{join("_",$chr, $beg, $end, $str)};
	    $nucl   = "NA" unless($nucl);
	    $nucl =~ tr/[a-z]/[A-Z]/;
	    print join("\t", $chr, $beg, $end, $name, $score, $str, $rest, $status, $nucl), "\n";
	}
    }
}
close FILE;


