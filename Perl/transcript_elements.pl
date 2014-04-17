#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility takes a gtf annotation (STDIN) and reformats it into a more compact, quickly readable file (STDOUT). Only exons are taken into account.\n";
}

parse_command_line(source=>{description=>'the content of the source field', default=>'SJPIPE'});

while($line=<STDIN>) {
    chomp $line;
    ($chr, $trash, $element, $beg, $end, $trash, $str, $trash, $attr) = split /\t/, $line;
    $chr = "chr$chr" unless($chr=~/^chr/);
    if($element eq "exon") {
	%attr =  get_attributes($attr);
        $tid = $attr{'transcript_id'};
	push @{$exons{$tid}}, [$chr, $beg, $end, $str];
    }
}


foreach $tid(keys(%exons)) {
    @array = sort {$a->[1]<=>$b->[1]} @{$exons{$tid}};
    %chr = %str = ();
    foreach $exon(@array) {
	$chr{$exon->[0]}=$str{$exon->[3]}=1;
    }
    if(keys(%chr)==1 && keys(%str)==1) {
	for($i=0; $i<@array; $i++) {
	    push @{$res{join("\t", keys(%chr), $source, 'exon',   $array[$i]->[1],   $array[$i]->[2], '.', keys(%str), '.')}}, $tid;
	    push @{$res{join("\t", keys(%chr), $source, 'intron', $array[$i-1]->[2], $array[$i]->[1], '.', keys(%str), '.')}}, $tid if($i>0);
	    push @{$pos{join("\t", keys(%chr), $source, 'exon',   $array[$i]->[1],   $array[$i]->[2], '.', keys(%str), '.')}}, percent($i, @array-1);
	    push @{$pos{join("\t", keys(%chr), $source, 'intron', $array[$i-1]->[2], $array[$i]->[1], '.', keys(%str), '.')}}, percent($i-1, @array-2)  if($i>0);
	}
    }
    else {
	$trans_spliced++;
    }
}

foreach $key(keys(%res)) {
    print $key, "\t", set_attributes(belongsto=>join(",", @{$res{$key}}), pos=>avg(@{$pos{$key}})), "\n";
}

print STDERR "[WARNING: $trans_spliced trans spliced transcripts excluded]" if($trans_spliced);

sub percent {
    return('NA') unless(@_[0]>=0 && @_[1]>0);
    return(strand_c2i(keys(%str))<0 ? 1 - @_[0]/@_[1] : @_[0]/@_[1]);
}


