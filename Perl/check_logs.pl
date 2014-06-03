@files = split /\n/, `ls $ARGV[0]*A01.ssj.tsv`;
foreach $file(@files) {
    $file=~s/.ssj.tsv//;
    $z = `cat $file.ssj.log`;
    @l1 = split /\s+/, `ls -l $file.ssj.tsv`;
    @l2 = split /\s+/, `ls -l $file.ssj.tsv`;
    if(index($z, 'ompleted')==0 || $l1[4]==0 || $l2[4]==0) {
	print STDERR "[$file]\n";
	system("rm -f $file.ssj.tsv $file.ssc.tsv $file.ssj.log");
    }
}
