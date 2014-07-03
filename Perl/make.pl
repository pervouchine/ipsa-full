#!/usr/bin/perl
use Perl::utils;

@suffixes = ('ssj','ssc');

if(@ARGV==0) {
    print STDERR "This utility creates a makefile for the sj pipeline, taking the index file from STDIN and printing the makefile to STDOUT\n";
}

parse_command_line(     dir     => {description=>'the output directory', ifabsent=>'output directory not specified'},
			repository => {description=>'the repository subdirectory for bam files'},
			param   => {description=>'parameters passed to sjcount'},
			group	=> {description=>'the grouping field for IDR', ifabsent=>'grouping field is absent'},
			block	=> {description=>'the blocking field for mastertable'},
			margin  => {description=>'margin for aggregate', default=>5},
			entropy => {description=>'entropy lower threshold', default=>3},
			status  => {description=>'annotation status lower threshold', default=>0},
			mincount=> {description=>'min number of counts for the denominator', default=>20},
			idr     => {description=>'IDR upper threshold', default=>0.1},
                        annot   => {description=>'the annotation (gtf)', ifabsent=>'annotation not specified'},
			genome	=> {description=>'the genome (without .dbx or .idx)', ifabsent=>'genome not specified'},
			merge	=> {description=>'the name of the output to merge in case if blocks are missing'},
			SJCOUNTDIR =>{variable=>T,ifabsent=>'SJCOUNTDIR not specified'});

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

        if($file=~/^http/ || $file=~/^ftp/) {
            make(script=>"wget", before=>$file, output=>{-O=>"$repository$target"}, mkdir=>T, endpoint=>'download');
            $file = "$repository$target";
        }

        $target  =~ s/\.bam$//;
        $name = "$dir$target";

	make(script=>$SJCOUNTDIR."sjcount_v3", input=>{-bam=>$file}, output=>{-ssj=>"$name.A01.ssj.tsv", -ssc=>"$name.A01.ssc.tsv", -log=>"$name.A01.ssj.log"}, 
	     after=>"-binsize 1 -nbins $readLength $param $stranded -quiet", mkdir=>T, endpoint=>A01);

	make(script=>"aggregate1.pl", input=>{'<'=>"$name.A01.ssj.tsv"}, output=>{'>'=>"$name.A02.ssj.tsv"}, before=>"-readLength $readLength -margin $margin", endpoint=>'A02');
        make(script=>"aggregate2.pl", input=>{'<'=>"$name.A01.ssc.tsv"}, output=>{'>'=>"$name.A02.ssc.tsv"}, before=>"-readLength $readLength -margin $margin", endpoint=>'A02');

	make(script=>"annotate.pl",      input=>{-in=>"$name.A02.ssj.tsv", -annot=>$annot, -dbx=>"$genome.dbx", -idx=>"$genome.idx"}, output=>{'>'=>"$name.A03.ssj.tsv"}, endpoint=>'A03');
	make(script=>"choose_strand.pl", input=>{'<'=>"$name.A03.ssj.tsv"}, output=>{'>'=>"$name.A04.ssj.tsv"}, before=>"-", endpoint=>'A04');
	make(script=>"constrain_ssc.pl", input=>{'<'=>"$name.A02.ssc.tsv",-ssj=>"$name.A04.ssj.tsv"}, output=>{'>'=>"$name.A04.ssc.tsv"}, endpoint=>'A04');	

	foreach $suff(@suffixes) {
	    push @{$IDR{$id}{$suff}}, "$name.A04.$suff.tsv";
	    make(script=>"offset.r", input=>{-t=>"$name.A01.$suff.tsv"}, output=>{-p=>"$name.A01.$suff.pdf"}, endpoint=>'QC1');
	    $ct_merge{$key}{$suff}{"$dir$id.A06.$suff.tsv"}  = $id;
	}

	make(script=>"disproportion.r", input=>{-i=>"$name.A02.ssj.tsv"}, output=>{-o=>"$name.A02.ssj.pdf"}, endpoint=>'QC2');
	make(script=>"sjstat.r", input=>{-i=>"$name.A04.ssj.tsv"}, output=>{'>'=>"$name.A04.ssj.log"}, endpoint=>'QC3');

        make(script=>"aggregate3.pl", input=>{'<'=>"$name.A01.ssj.tsv",-ssj=>"$name.A04.ssj.tsv"}, output=>{'>'=>"$name.D01.tsv"}, endpoint=>'D01', mkdir=>T);

        $sj_merge{$key}{"$dir$id.A07.gff"}      = $id;
	$ce_merge{$key}{"$dir$id.B07.gff"}      = $id;
        $me_merge{$key}{"$name.D01.tsv"}        = $id;
	$mm_merge{$key}{"$dir$id.D07.gff"}        = $id;
    }

    if($attr{'type'} eq "gff" || $attr{'type'} eq "gtf") { 
        make(script=>"tx.pl", input=>{-quant=>$file, -annot=>$annot}, output=>{'>'=>"$dir$id.C07.gff"}, endpoint=>'C07', mkdir=>T);
	$tx_merge{$key}{"$dir$id.C07.gff"} = $id;
    }
}

foreach $id(keys(%IDR)) {
    $name = "$dir$id";
    foreach $suff(keys(%{$IDR{$id}})) {
        make(script=>"idr4sj.r", input=>{''=>join(" ", @{$IDR{$id}{$suff}})}, output=>{''=>"$name.A05.$suff.tsv"}, endpoint=>'A05');
	make(script=>"awk", before=>"'\$\$7>=$entropy && \$\$8>=$status && \$\$10<$idr'", input=>{''=>"$name.A05.$suff.tsv"}, output=>{'>'=>"$name.A06.$suff.tsv"}, endpoint=>'A06');
    }
    make(script=>"zeta.pl", input=>{-ssj=>"$name.A06.ssj.tsv", -ssc=>"$name.A06.ssc.tsv", -annot=>$annot}, output=>{'>'=>"$name.A07.gff"}, between=>"-mincount $mincount", endpoint=>'A07');
    make(script=>"zeta.pl", input=>{-ssj=>"$name.A06.ssj.tsv", -ssc=>"$name.A06.ssc.tsv", -annot=>"$dir$merge.mex.mixed_models.gff"}, output=>{'>'=>"$name.D07.gff"}, between=>"-mincount $mincount", endpoint=>'D07');
    make(script=>"psicas.pl", input=>{-ssj=>"$name.A06.ssj.tsv", -annot=>$annot}, output=>{'>'=>"$name.B07.gff"}, endpoint=>'B07');
}

#######################################################################################################################################################################

foreach $key(keys(%sj_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    make2(script=>"merge_gff.pl", inputs=>{-i=>\%{$sj_merge{$key}}}, outputs=>{-o=>{psi=>  "$dir$name.psi.tsv",   cosi=> "$dir$name.cosi.tsv"}},  endpoint=>"psi");
    make2(script=>"merge_gff.pl", inputs=>{-i=>\%{$sj_merge{$key}}}, outputs=>{-o=>{psi5=> "$dir$name.psi5.tsv",  psi3=> "$dir$name.psi3.tsv"}},  endpoint=>"psi");
    make2(script=>"merge_gff.pl", inputs=>{-i=>\%{$sj_merge{$key}}}, outputs=>{-o=>{cosi5=>"$dir$name.cosi5.tsv", cosi3=>"$dir$name.cosi3.tsv"}}, endpoint=>"cosi");
}

foreach $key(keys(%mm_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    make2(script=>"merge_gff.pl", inputs=>{-i=>\%{$mm_merge{$key}}}, outputs=>{-o=>{psi=>  "$dir$name.mpsi.tsv",   cosi=> "$dir$name.mcosi.tsv"}},  endpoint=>"mex");
}

foreach $key(keys(%tx_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    make2(script=>"merge_gff.pl", inputs=>{-i=>\%{$tx_merge{$key}}}, outputs=>{-o=>{psi=>"$dir$name.psitx.tsv"}},endpoint=>"psitx");
}

#######################################################################################################################################################################

foreach $key(keys(%ce_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    make2(script=>"merge_gff.pl", inputs=>{-i=>\%{$ce_merge{$key}}}, outputs=>{-o=>{psi=> "$dir$name.psicas.tsv"}},  endpoint=>"psicas");
}

foreach $key(keys(%ct_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    foreach $suff(keys(%{$ct_merge{$key}})) {
    	make2(script=>"merge_tsv.pl", inputs=>{-i=>\%{$ct_merge{$key}{$suff}}}, outputs=>{''=>{'>'=>"$dir$name.counts.$suff.tsv"}}, endpoint=>"counts");
    }
}

#######################################################################################################################################################################

foreach $key(keys(%me_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    make2(script=>"mex_merge_tsv.pl", inputs=>{-i=>\%{$me_merge{$key}}}, outputs=>{''=>{'>'=>"$dir$name.mex.tsv"}});
    make(script=>"mex_tsv2exons.pl",  input=>{-exons=>$annot, '<'=>"$dir$name.mex.tsv"}, output=>{'>'=>"$dir$name.mex.exons.tsv"});
    make(script=>"mex_tsv2models.pl", input=>{-exons=>$annot, '<'=>"$dir$name.mex.tsv"}, output=>{-gff=>"$dir$name.mex.models.gtf", -bed=>"$dir$name.mex.models.bed"});
    make(script=>"mex_stats.r", input=>{-i=>"$dir$name.mex.exons.tsv", -e=>$annot}, output=>{-o=>"$dir$name.mex.exons.pdf"}, endpoint=>'mex');
}

if($merge) {
    make(script=>"cat", input=>{''=>"$dir$merge.mex.models.gtf $annot"}, output=>{'>'=>"$dir$merge.mex.mixed_models.gff"}, between=>" | perl Perl/transcript_elements.pl -", endpoint=>'mex');
}

print "all :: psi cosi counts\n";






