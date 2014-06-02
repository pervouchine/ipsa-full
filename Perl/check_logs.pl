@files = split /\n/, `ls $ARGV[0]*A01.ssj.tsv`;
foreach $file(@files) {
    $file=~s/.tsv//;
    $z = `cat $file.log`;
    $k = (index($z, 'ompleted')>=0 ? OK : No);
    unless($k eq OK) {
	print STDERR "[$file]\n";
	system("rm -f $file.tsv $file.log");
 	$file =~ s/ssj/ssc/;
	system("rm -f $file.tsv");
    }
}
