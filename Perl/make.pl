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
	make(script=>"aggregate.pl", input=>{'<'=>fn($name,A01,ssj,tsv)}, output=>{'>'=>fn($name,A02,ssj,tsv), -logfile=>fn($name,A02,ssj,'log')}, before=>"$prm -deg 1", endpoint=>A02);
        make(script=>"aggregate.pl", input=>{'<'=>fn($name,A01,ssc,tsv)}, output=>{'>'=>fn($name,A02,ssc,tsv), -logfile=>fn($name,A02,ssc,'log')}, before=>"$prm -deg 0", endpoint=>A02);

	make(script=>"annotate.pl",      input=>{-in=>fn($name,A02,ssj,tsv), -annot=>$annot, -dbx=>"$genome.dbx", -idx=>"$genome.idx"}, output=>{'>'=>fn($name,A03,ssj,tsv)}, endpoint=>A03);
	make(script=>"choose_strand.pl", input=>{'<'=>fn($name,A03,ssj,tsv)}, output=>{'>'=>fn($name,A04,ssj,tsv), -logfile=>fn($name,A04,ssj,'log')}, before=>"-", endpoint=>A04);
	make(script=>"constrain_ssc.pl", input=>{'<'=>fn($name,A02,ssc,tsv),-ssj=>fn($name,A04,ssj,tsv)}, output=>{'>'=>fn($name,A04,ssc,tsv)}, endpoint=>A04);	

	foreach $suff(@suffixes) {
	    push @{$IDR{$id}{$suff}}, fn($name,A04,$suff,tsv);
	}

	$merge_tsv{A}{ssj}{$key}{fn($id,A06,ssj,tsv)} = $id;
	$merge_tsv{A}{ssc}{$key}{fn($id,A06,ssc,tsv)} = $id;
	$merge_tsv{D}{mex}{$key}{fn($name,D02,tsv)} = $id;

	$mk_stat{A}{ssj}{$key}{fn($id,A06,ssj,tsv)} = $id;

        make(script=>"aggregate.pl",     input=>{'<'=>fn($name,A01,ssj,tsv)}, output=>{'>'=>fn($name,D01,tsv)},  before=>"$prm -deg 2", endpoint=>D01);
	make(script=>"constrain_mex.pl", input=>{-ssj=>fn($name,A04,ssj,tsv), '<'=>fn($name,D01,tsv)}, output=>{'>'=>fn($name,D02,tsv)}, endpoint=>D02);

	$merge_gff{A}{'psi,cosi'}{$key}{fn($id,A07,gff)} = $id;
	$merge_gff{A}{'psi5,psi3'}{$key}{fn($id,A07,gff)} = $id;
	$merge_gff{A}{'cosi5,cosi3'}{$key}{fn($id,A07,gff)} = $id;
	$merge_gff{B}{'psicas'}{$key}{fn($id,B07,gff)} = $id;
    }

    if($attr{'type'} eq "gff" || $attr{'type'} eq "gtf") { 
        make(script=>"tx.pl", input=>{-quant=>$file, -annot=>$annot}, output=>{'>'=>fn($id,C07,gff)}, endpoint=>C07);
	$merge_gff{C}{psitx}{fn($id,C07,gff)} = $id;
    }
}

foreach $id(keys(%IDR)) {
    $name = "$id";
    foreach $suff(keys(%{$IDR{$id}})) {
        make(script=>"idr4sj.pl", input=>{''=>join(" ", @{$IDR{$id}{$suff}})}, output=>{'>'=>fn($name,A05,$suff,tsv)}, endpoint=>A05);
	make(script=>"awk", before=>"'\$\$4>=$entropy && \$\$5>=$status && \$\$7<$idr'", input=>{''=>fn($name,A05,$suff,tsv)}, output=>{'>'=>fn($name,A06,$suff,tsv)}, endpoint=>A06);
    }
    make(script=>'tsv2bed.pl', input=>{'<'=>fn($name,A06,ssj,tsv)}, output=>{'>'=>fn($name,E06,ssj,bed)}, between=>"-extra 2,3,4,5,6,7", endpoint=>E06);
    make(script=>'tsv2gff.pl', input=>{'<'=>fn($name,A06,ssj,tsv)}, output=>{'>'=>fn($name,E06,ssj,gff)}, between=>"-o count 2 -o stagg 3 -o entr 4 -o annot 5 -o nucl 6 -o IDR 7", endpoint=>E06);

    $Annot = fn($merge,mex,mixed_models,gff);
    make(script=>"zeta.pl", input=>{-ssj=>fn($name,A06,ssj,tsv), -ssc=>fn($name,A06,ssc,tsv), -annot=>$annot}, output=>{'>'=>fn($name,A07,gff)}, between=>"-mincount $mincount", endpoint=>A07);
    make(script=>"zeta.pl", input=>{-ssj=>fn($name,A06,ssj,tsv), -ssc=>fn($name,A06,ssc,tsv), -annot=>$Annot}, output=>{'>'=>fn($name,D07,gff)}, between=>"-mincount $mincount", endpoint=>D07);
    make(script=>"psicas.pl", input=>{-ssj=>fn($name,A06,ssj,tsv), -annot=>$annot}, output=>{'>'=>fn($name,B07,gff)}, endpoint=>B07);
}

#######################################################################################################################################################################


foreach $endpoint(keys(%merge_tsv)) {
    foreach $arm(keys(%{$merge_tsv{$endpoint}})) {
    	foreach $key(keys(%{$merge_tsv{$endpoint}{$arm}})) {
	    make2(script=>"merge_tsv.pl", inputs=>{-i=>\%{$merge_tsv{$endpoint}{$arm}{$key}}}, outputs=>{''=>{'>'=>fn($key,counts,$arm,tsv)}}, endpoint=>$endpoint);
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

print "all :: A D\n";

#######################################################################################################################################################################
exit;

foreach $key(keys(%mm_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    make2(script=>"merge_gff.pl", inputs=>{-i=>\%{$mm_merge{$key}}}, outputs=>{-o=>{psi=>  fn($name,mpsi,tsv),   cosi=> fn($name,mcosi,tsv)}},  endpoint=>"mex");
}

foreach $key(keys(%ct_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    make2(script=>"mkstat.pl", inputs=>{-i=>\%{$ct_merge{$key}{'ssj'}}}, outputs=>{''=>{'>'=>fn($name,'stat',tsv)}});
    make(script=>"mkstat_list.pl", input=>{''=>join(" ", keys(%{$ct_merge{$key}{'ssj'}}))}, output=>{'>'=>fn($name,'list',tsv)}, endpoint=>"stat");
    make(script=>"statcount.r", input=>{-i=>fn($name,'stat',tsv)}, output=>{-o=>fn($name,'stat',pdf)}, endpoint=>"stat");
}

foreach $key(keys(%me_merge)) {
    $name = $key ? $key : $merge;
    next unless($name);
    make(script=>"mex_tsv2exons.pl",  input=>{-exons=>$annot, '<'=>fn($name,mex,tsv)}, output=>{'>'=>fn($name,mex.exons,tsv)});
    make(script=>"mex_tsv2models.pl", input=>{-exons=>$annot, '<'=>fn($name,mex,tsv)}, output=>{-gff=>fn($name,mex.models,gtf), -bed=>fn($name,mex.models,bed)});
    make(script=>"mex_stats.r", input=>{-i=>fn($name,mex.exons,tsv), -e=>$annot}, output=>{-o=>fn($name,mex.exons,pdf)}, endpoint=>'mex');
}

if($merge) {
    make(script=>"cat", input=>{''=>fn($merge,mex.models,gtf)." $annot"}, output=>{'>'=>fn($merge,mex,mixed_models,gff)}, between=>" | perl Perl/transcript_elements.pl -", endpoint=>'mex');
}

print "all :: psi cosi stat counts\n";

sub fn {
    return(@_[1]=~/^[A-Z]\d+$/ ? join(undef, $dir, @_[1], "/", join('.', @_)) : join(undef, $dir, join('.', @_)));
    
}


