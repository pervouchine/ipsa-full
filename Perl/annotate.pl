#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility takes an aggregated TSV file, the genomic annotation, and the genome, and outputs a TSV with two more columns: ";
    print STDERR "(8) annotation status and (9) splice sites\n";
    print STDERR "If the input was strandless ('.' in column 4) then each line will be reported twice, one for '+' and and for '-' strand\n";
}

parse_command_line(	in	=> {description=>'the input tsv file', ifunreadable=>'input not specified'},
			annot	=> {description=>'the annotation (gtf)', ifunreadable=>'annotation not specified'}, 
			dbx	=> {description=>'the genome (dbx)', ifunreadable=>'dbx not specified'},
                        idx     => {description=>'the genome (idx)', ifunreadable=>'idx not specified'},
			MAPTOOLSDIR  =>{variable=>T, ifabsent=>'MAPTOOLSDIR not specified'});



open FILE, $annot || die;
while($line=<FILE>) {
    chomp $line;
    ($chr, $source, $feature, $beg, $end, $score, $str, $frame, $group) = split /\t/, $line;
    next unless($feature eq "intron");
    $sj{$chr}{$beg}{$end}{$str}++;
    $ss{$chr}{$beg}{$str}++;
    $ss{$chr}{$end}{$str}++;
}
close FILE;

$program = $MAPTOOLSDIR."bin/getsegm -limit 4 -margins -1 0 -spacer 0 -inp_type 1 -out_type 1";
%seq = split /[\t\n]/, `$program -dbx $dbx -idx $idx -in $in`;

open FILE, $in || die;
while($line=<FILE>) {
    chomp $line;
    ($chr, $beg, $end, $strand, $rest) = split /\t/, $line, 5;
    foreach $str("+", "-") {
	if($strand eq $str || $strand eq '.') {	
	    $status = $sj{$chr}{$beg}{$end}{$str} ? 3 : ($ss{$chr}{$beg}{$str} && $ss{$chr}{$end}{$str} ? 2 : ($ss{$chr}{$beg}{$str} || $ss{$chr}{$end}{$str} ? 1 : 0));
	    $nucl   = $seq{join("_",$chr, $beg, $end, $str)};
	    $nucl   = "NA" unless($nucl);
	    $nucl =~ tr/[a-z]/[A-Z]/;
	    print join("\t", $chr, $beg, $end, $str, $rest, $status, $nucl), "\n";
	}
    }
}
close FILE;


