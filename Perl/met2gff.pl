use Perl::utils;
$threshold = 10;
$w = 10;


$header=<STDIN>;
while($line=<STDIN>) {
    chomp $line;
    @array = split /\t/, $line;
    $id = shift(@array);
    next unless(avg(@array)>$threshold);
    ($chr, $a, $b, $c, $d, $s) = split /_/, $id;
    gff_exn($chr, $a - $w, $a, $s);
    gff_exn($chr, $b, $c, $s);
    gff_exn($chr, $d, $d + $w, $s);
}


sub gff_exn {
    ($x, $y) = sort {$a<=>$b} (@_[1], @_[2]);
     print join("\t", @_[0], mex, exon, $x, $y, 0, @_[3], '.', set_attributes(transcript_id=>$id)), "\n";
}
