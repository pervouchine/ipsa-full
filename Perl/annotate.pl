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
			logfile => {description=>'name of the log file'},
			MAPTOOLSDIR  =>{variable=>T, ifabsent=>'MAPTOOLSDIR not specified'});


read_junctions($in);
read_annotation($annot);
index_ss();

$program = $MAPTOOLSDIR."bin/getsegm2 -limit 4 -margins -1 0 -spacer 0 -inp_type 2 -out_type 1";
%seq = split /[\t\n]/, `cat $in | $program -dbx $dbx -idx $idx`;
print STDERR "[cat $in | $program -dbx $dbx -idx $idx]\n";

open FILE, $in || die;
while($line=<FILE>) {
    chomp $line;
    ($id, $count, $rest) = split /\t/, $line, 3;
    ($chr, $beg, $end, $strand) = split /\_/, $id;
    foreach $str("+", "-") {
	if($strand eq $str || $strand eq '.') {	
	    $status = annot_status($chr, $beg, $end, $str);
	    $id = join("_", $chr, $beg, $end, $str);
	    $nucl   = $seq{$id};
	    $nucl   = "NA" unless($nucl);
	    $nucl =~ tr/[a-z]/[A-Z]/;
	    print join("\t", $id, $count, $rest, $status, $nucl), "\n";
	    $stat1{$status}{$nucl}++;
	    $stat2{$status}{$nucl}+=$count;
	}
    }
}
close FILE;

if($logfile) {
    open FILE, ">$logfile";
    foreach $status(sort keys(%stat1)) {
	foreach $nucl(sort keys(%{$stat1{$status}})) {
	    print FILE join("\t", $logfile, $status, $nucl, $stat1{$status}{$nucl}, $stat2{$status}{$nucl});
	}
    }
    close FILE;
}




