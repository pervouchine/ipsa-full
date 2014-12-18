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
			entropy => {description=>'entropy lower threshold', default=>1.5},
			status  => {description=>'annotation status lower threshold', default=>0},
			mincount=> {description=>'min number of counts for the denominator', default=>10},
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
    $key = $merge if($merge);
    next unless($id && $key);

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
        $name = "$target";

	make(script=>$SJCOUNTDIR."sjcount", input=>{-bam=>$file}, output=>{-ssj=>fn($name,A01,ssj,tsv), -ssc=>fn($name,A01,ssc,tsv), -log=>fn($name,A01,ssj,'log')},
             after=>"-nbins $readLength $param $stranded -quiet", mkdir=>T, endpoint=>A01);

	$prm = "-readLength $readLength -margin $margin -name $name";
	make(script=>"awk '\$\$2==1'",input=>{''=>fn($name,A01,ssj,tsv)}, output=>{'>'=>fn($name,A02,ssj,tsv), -logfile=>fn($name,A02,ssj,'log')}, between=>"|perl Perl/agg.pl $prm", endpoint=>A02);
        make(script=>"awk '\$\$2==0'",input=>{''=>fn($name,A01,ssc,tsv)}, output=>{'>'=>fn($name,A02,ssc,tsv), -logfile=>fn($name,A02,ssc,'log')}, between=>"|perl Perl/agg.pl $prm", endpoint=>A02);

        $merge_tsv{Z}{psc}{$key}{fn($name,A01,ssj,tsv)} = $attr{labExpId};

	make(script=>"annotate.pl",      input=>{-in=>fn($name,A02,ssj,tsv), -annot=>$annot, -dbx=>"$genome.dbx", -idx=>"$genome.idx"}, output=>{'>'=>fn($name,A03,ssj,tsv)}, endpoint=>A03);
	make(script=>"choose_strand.pl", input=>{'<'=>fn($name,A03,ssj,tsv)}, output=>{'>'=>fn($name,A04,ssj,tsv), -logfile=>fn($name,A04,ssj,'log')}, before=>"-", endpoint=>A04);
	make(script=>"constrain_ssc.pl", input=>{'<'=>fn($name,A02,ssc,tsv),-ssj=>fn($name,A04,ssj,tsv)}, output=>{'>'=>fn($name,A04,ssc,tsv)}, endpoint=>A04);	

        make(script=>"awk '\$\$2>=2'", input=>{''=>fn($name,A01,ssj,tsv)}, output=>{'>'=>fn($name,D01,tsv)}, between=>"| perl Perl/agg.pl -", endpoint=>D01);
	make(script=>"constrain_mult.pl", input=>{-ssj=>fn($name,A04,ssj,tsv), '<'=>fn($name,D01,tsv)}, output=>{'>'=>fn($name,D02,tsv)}, endpoint=>D02);
	make(script=>"extract_mex.pl", input=>{'<'=>fn($name,D02,tsv)}, output=>{'>'=>fn($name,D03,tsv)}, endpoint=>D03);

        push @{$IDR{$id}{ssj}}, fn($name,A04,ssj,tsv);
	push @{$IDR{$id}{ssc}}, fn($name,A04,ssc,tsv);
	push @{$IDR{$id}{mex}}, fn($name,D03,tsv);

	$merge_tsv{A}{ssj}{$key}{fn($id,A06,ssj,tsv)} = $id;
	$merge_tsv{A}{ssc}{$key}{fn($id,A06,ssc,tsv)} = $id;
	$merge_tsv{D}{mex}{$key}{fn($id,D06,tsv)}     = $id;

	$mk_stat{A}{ssj}{$key}{fn($id,A06,ssj,tsv)} = $id;

	$merge_gff{A}{'psi,cosi'}{$key}{fn($id,A07,gff)} = $id;
	$merge_gff{A}{'psi5,psi3'}{$key}{fn($id,A07,gff)} = $id;
	$merge_gff{A}{'cosi5,cosi3'}{$key}{fn($id,A07,gff)} = $id;
	$merge_gff{D}{'mpsi,mcosi'}{$key}{fn($id,D07,gff)} = $id;
	$merge_gff{B}{'psicas'}{$key}{fn($id,B07,gff)} = $id;
    }

    if($attr{'type'} eq "gff" || $attr{'type'} eq "gtf") { 
        make(script=>"tx.pl", input=>{-quant=>$file, -annot=>$annot}, output=>{'>'=>fn($id,C07,gff)}, endpoint=>C07);
	$merge_gff{C}{psitx}{fn($id,C07,gff)} = $id;
    }
}

foreach $id(keys(%IDR)) {
    make(script=>"idr4sj.pl", input=>{''=>join(" ", @{$IDR{$id}{ssj}})}, output=>{'>'=>fn($id,A05,ssj,tsv)}, endpoint=>A05);
    make(script=>"idr4sj.pl", input=>{''=>join(" ", @{$IDR{$id}{ssc}})}, output=>{'>'=>fn($id,A05,ssc,tsv)}, endpoint=>A05);
    make(script=>"idr4sj.pl", input=>{''=>join(" ", @{$IDR{$id}{mex}})}, output=>{'>'=>fn($id,D06,tsv)}, endpoint=>D06);

    make(script=>"awk", before=>"'\$\$4>=$entropy && \$\$5>=$status && \$\$7<$idr'", input=>{''=>fn($id,A05,ssj,tsv)}, output=>{'>'=>fn($id,A06,ssj,tsv)}, endpoint=>A06);
    make(script=>"awk", before=>"'\$\$4>=$entropy && \$\$7<$idr'", input=>{''=>fn($id,A05,ssc,tsv)}, output=>{'>'=>fn($id,A06,ssc,tsv)}, endpoint=>A06);

    make(script=>'tsv2bed.pl', input=>{'<'=>fn($id,A06,ssj,tsv)}, output=>{'>'=>fn($id,E06,ssj,bed)}, between=>"-extra 2,3,4,5,6,7", endpoint=>E06);
    make(script=>'tsv2gff.pl', input=>{'<'=>fn($id,A06,ssj,tsv)}, output=>{'>'=>fn($id,E06,ssj,gff)}, between=>"-o count 2 -o stagg 3 -o entr 4 -o annot 5 -o nucl 6 -o IDR 7", endpoint=>E06);

    $prm = "-mincount $mincount";
    make(script=>"zeta.pl", input=>{-ssj=>fn($id,A06,ssj,tsv), -ssc=>fn($id,A06,ssc,tsv), -annot=>$annot}, output=>{'>'=>fn($id,A07,gff)}, between=>$prm, endpoint=>A07);
    make(script=>"zeta.pl", input=>{-ssj=>fn($id,A06,ssj,tsv), -ssc=>fn($id,A06,ssc,tsv), -exons=>fn($id,D06,tsv)}, output=>{'>'=>fn($id,D07,gff)}, between=>$prm, endpoint=>D07);
    make(script=>"psicas.pl", input=>{-ssj=>fn($id,A06,ssj,tsv), -annot=>$annot}, output=>{'>'=>fn($id,B07,gff)}, endpoint=>B07);
}

#######################################################################################################################################################################


foreach $endpoint(keys(%merge_tsv)) {
    foreach $arm(keys(%{$merge_tsv{$endpoint}})) {
	$prm = ($arm eq "psc") ? "-by 1,2" : undef;
    	foreach $key(keys(%{$merge_tsv{$endpoint}{$arm}})) {
	    make2(script=>"merge_tsv.pl", inputs=>{-i=>\%{$merge_tsv{$endpoint}{$arm}{$key}}}, outputs=>{''=>{'>'=>fn($key,counts,$arm,tsv)}}, before=>$prm, endpoint=>$endpoint);
	}
    }
}

foreach $endpoint(keys(%mk_stat)) { 
    foreach $arm(keys(%{$mk_stat{$endpoint}})) { 
        foreach $key(keys(%{$mk_stat{$endpoint}{$arm}})) { 
            make2(script=>"mk_stat.pl", inputs=>{-i=>\%{$mk_stat{$endpoint}{$arm}{$key}}}, outputs=>{''=>{'>'=>fn($key,stats,$arm,tsv)}}, endpoint=>$endpoint);
	    make(script=>"mk_stat.r", input=>{-i=>fn($key,stats,$arm,tsv)}, output=>{-o=>fn($key,stats,$arm,pdf)}, endpoint=>stats);
        }
    }
}

foreach $endpoint(keys(%merge_gff)) {
    foreach $arms(keys(%{$merge_gff{$endpoint}})) {
    	foreach $key(keys(%{$merge_gff{$endpoint}{$arms}})) {
	    %outputs=();
	    foreach $arm(split /\,/, $arms) {
	    	$outputs{$arm} = fn($key,$arm,tsv);
	    }
            make2(script=>"merge_gff.pl", inputs=>{-i=>\%{$merge_gff{$endpoint}{$arms}{$key}}}, outputs=>{-o=>\%outputs}, endpoint=>$endpoint);
	}
    }
}

#######################################################################################################################################################################

print "all :: A D stats\n";

sub fn {
    return(@_[1]=~/^[A-Z]\d+$/ ? join(undef, $dir, @_[1], "/", join('.', @_)) : join(undef, $dir, join('.', @_)));
    
}


