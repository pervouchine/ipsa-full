#!/usr/bin/perl
use Perl::utils;

@suffixes = ('ssj','ssc');

if(@ARGV==0) {
    print STDERR "This utility creates a makefile for the sj pipeline, taking the index file from STDIN and printing the makefile to STDOUT\n";
}

parse_command_line(     dir     => {description=>'the output directory', ifabsent=>'output directory not specified'},
			param   => {description=>'parameters passed to sjcount'},
			group	=> {description=>'the grouping field for IDR', ifabsent=>'grouping field is absent'},
			block	=> {description=>'the blocking field for merge'},
			margin  => {description=>'margin for aggregate', default=>5},
			entropy => {description=>'entropy lower threshold', default=>3},
			mincount=> {description=>'min number of counts for the denominator', default=>20},
			idr     => {description=>'IDR upper threshold', default=>0.1},
                        annot   => {description=>'the annotation (gtf)', ifabsent=>'annotation not specified'},
			genome	=> {description=>'the genome (without .dbx or .idx)', ifabsent=>'genome not specified'},
			merge	=> {description=>'the name of the output to merge in case if blocks are missing'});

@group = split /\,/, $group;
@block = split /\,/, $block;

while($line=<STDIN>) {
    chomp $line;
    ($file, $attr) = split /\t/, $line;
    %attr = get_features($attr);

    $id  = join("_", @attr{@group});	# grouping id for IDR
    $key = join("_", @attr{@block});	# blocking id for merge

    if($attr{'type'} eq "bam" && $attr{'view'}=~/^Alignments/) {

	if($attr{'readType'}=~/\dx(\d+)(D*)/) {
	    $readLength = $1;
	    $stranded   = ($2 eq "D" ? "" : "-unstranded");
	}
	else {
	    die("Read length not specified");
	}

        @a = split /\//, $file;
        $target = pop(@a);
        $target  =~ s/\.bam$//;
        $name = "$dir$target";

	make(script=>"sjcount", input=>{-bam=>$file}, output=>{-ssj=>"$name.A01.ssj.tsv", -ssc=>"$name.A01.ssc.tsv"}, 
	     after=>"-log $name.A01.ssj.log -binsize 1 -nbins $readLength $param $stranded -quiet", endpoint=>'A01',mkdir=>T);

	make(script=>"aggregate.pl", input=>{-tsv=>"$name.A01.ssj.tsv"}, output=>{'>'=>"$name.A02.ssj.bed"}, before=>"-readLength $readLength -margin $margin -minintron 4", endpoint=>'A02');
        make(script=>"aggregate.pl", input=>{-tsv=>"$name.A01.ssc.tsv"}, output=>{'>'=>"$name.A02.ssc.bed"}, before=>"-readLength $readLength -margin $margin -minintron 0", endpoint=>'A02');

	make(script=>"annotate.pl",  input=>{-bed=>"$name.A02.ssj.bed", -annot=>$annot, -dbx=>"$genome.dbx", -idx=>"$genome.idx"}, output=>{'>'=>"$name.B03.ssj.bed"}, endpoint=>'B03');
	make(script=>"choose_strand.pl", input=>{-bed=>"$name.B03.ssj.bed"}, output=>{'>'=>"$name.B04.ssj.bed"}, endpoint=>'B04');
	make(script=>"constrain_ssc.pl", input=>{-ssc=>"$name.A02.ssc.bed",-ssj=>"$name.B04.ssj.bed"}, output=>{'>'=>"$name.B04.ssc.bed"}, endpoint=>'B04');	

	foreach $suff(@suffixes) {
	    push @{$IDR{$id}{$suff}}, "$name.B04.$suff.bed";
	    make(script=>"offset.r", input=>{-t=>"$name.A01.$suff.tsv"}, output=>{-p=>"$name.A01.$suff.pdf"}, endpoint=>'QC1');
	    push @{$sj_merge_cl{$key}}, "-i $dir$id.B07.gff $id ";
	    push @{$sj_merge_mk{$key}}, "$dir$id.B07.gff ";
	}

	make(script=>"disproportion.r", input=>{-b=>"$name.A02.ssj.bed"}, output=>{-p=>"$name.A02.ssj.pdf"}, endpoint=>'QC2');
	make(script=>"sjstat.r", input=>{-b=>"$name.B04.ssj.bed"}, output=>{'>'=>"$name.B04.ssj.log"}, endpoint=>'QC3');
    }

    if($attr{'type'} eq "gff" || $attr{'type'} eq "gtf") { 
        make(script=>"tx.pl", input=>{-quant=>$file, -annot=>$annot}, output=>{'>'=>"$dir$id.C06.gff"}, endpoint=>'C06');
	push @{$tx_merge_cl{$key}}, "-i $dir$id.C06.gff $id ";
        push @{$tx_merge_mk{$key}}, "$dir$id.C06.gff ";
    }

}

foreach $id(keys(%IDR)) {
    $name = "$dir$id";
    foreach $suff(keys(%{$IDR{$id}})) {
        make(script=>"idr4sj.r", input=>{''=>join(" ", @{$IDR{$id}{$suff}})}, output=>{''=>"$name.B05.$suff.bed"}, endpoint=>'B05');
	make(script=>"awk", before=>"'\$\$9>=$entropy && \$\$12<$idr'", input=>{''=>"$name.B05.$suff.bed"}, output=>{'>'=>"$name.B06.$suff.bed"}, endpoint=>'B06');
    }
    make(script=>"zeta.pl", input=>{-ssj=>"$name.B06.ssj.bed", -ssc=>"$name.B06.ssc.bed", -annot=>$annot}, output=>{'>'=>"$name.B07.gff"}, between=>"-mincount $mincount", endpoint=>'B07');
}

foreach $key(keys(%sj_merge_cl)) {
    $name = $key ? $key : $merge;
    next unless($name);
    print "$dir$name.psi.tsv   $dir$name.cosi.tsv  : @{$sj_merge_mk{$key}}\n\tperl Perl/merge_gff.pl @{$sj_merge_cl{$key}} -o psi  $dir$name.psi.tsv  -o cosi $dir$name.cosi.tsv\n";
    print "$dir$name.psi5.tsv  $dir$name.psi3.tsv  : @{$sj_merge_mk{$key}}\n\tperl Perl/merge_gff.pl @{$sj_merge_cl{$key}} -o psi5 $dir$name.psi5.tsv -o psi3 $dir$name.psi3.tsv\n";
    print "$dir$name.cosi5.tsv $dir$name.cosi3.tsv : @{$sj_merge_mk{$key}}\n\tperl Perl/merge_gff.pl @{$sj_merge_cl{$key}} -o cosi5 $dir$name.cosi5.tsv -o cosi3 $dir$name.cosi3.tsv\n";
    print "all :: $dir$name.psi.tsv  $dir$name.cosi.tsv $dir$name.psi5.tsv $dir$name.psi3.tsv $dir$name.cosi5.tsv $dir$name.cosi3.tsv\n";
}

foreach $key(keys(%tx_merge_cl)) {
    $name = $key ? $key : $merge;
    next unless($name);
    print "$dir$name.txpsi.tsv : @{$tx_merge_mk{$key}}\n\tperl Perl/merge_gff.pl @{$tx_merge_cl{$key}} -o psi $dir$name.txpsi.tsv\n";
    print "all :: $dir$name.txpsi.tsv\n";
}

