#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
    print STDERR "This utility takes a gtf annotation (STDIN) and reformats it into a more compact, quickly readable file (STDOUT). Only exons are taken into account.\n";
}

parse_command_line(source  =>{description=>'the content of the source field', default=>'SJPIPE'},
		   element =>{description=>'element to constrain', default=>'exon'});

while($line=<STDIN>) {
    chomp $line;
    ($chr, $trash, $elm, $beg, $end, $trash, $str, $trash, $attr) = split /\t/, $line;
    $chr = "chr$chr" unless($chr=~/^chr/);
    if($elm eq $element) {
	%attr =  get_attributes($attr);
        $tid = $attr{'transcript_id'};
	push @{$exons{$tid}}, [$beg, $end];
	$CHR{$tid}{$chr} = $STR{$tid}{$str} = 1;
    }
}


foreach $tid(keys(%exons)) {
    if(keys(%{$CHR{$tid}})==1 && keys(%{$STR{$tid}})==1) {
	($chr, $str) = (keys(%{$CHR{$tid}}), keys(%{$STR{$tid}}));
	@array = sort {$a->[0]<=>$b->[0]} @{$exons{$tid}};
	for($i=0; $i<@array; $i++) {
	    $key = join("\t", $chr, $source, 'exon',   $array[$i]->[0],   $array[$i]->[1], '.', $str, '.');
	    push @{$belong{$key}}, $tid;
	    push @{$relpos{$key}}, percent($i, @array-1);
	    if($i>0) {
		$key = join("\t", $chr, $source, 'intron', $array[$i-1]->[1], $array[$i]->[0], '.', $str, '.');
		push @{$belong{$key}}, $tid;
		push @{$relpos{$key}}, percent($i-1, @array-2);
	    }
	}
    }
    else {
	$trans_spliced++;
    }
}

foreach $key(keys(%belong)) {
    print $key, "\t", set_attributes(belongsto=>join(",", @{$belong{$key}}), pos=>avg(@{$relpos{$key}})), "\n";
}

print STDERR "[WARNING: $trans_spliced trans spliced transcripts excluded]" if($trans_spliced);

sub percent {
    return('NA') unless(@_[0]>=0 && @_[1]>0);
    return(strand_c2i($str)<0 ? 1 - @_[0]/@_[1] : @_[0]/@_[1]);
}


