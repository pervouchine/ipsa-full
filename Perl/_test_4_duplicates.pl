@a = split /\n/, `ls $ARGV[0]*A01.ssj.tsv`;
foreach $file(@a) {
    print STDERR "$file";
    $n = `cut -f1-5 $file | wc -l`;
    $m = `cut -f1-5 $file | sort -u | wc -l`;
    print STDERR " diplicate" if($m<$n);
    print "\n";
}
