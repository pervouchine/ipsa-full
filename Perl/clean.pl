@files = split /\n/, `ls $ARGV[0]`;
foreach $file(@files) {
    @l = split /\s+/, `ls -l $ARGV[0]$file`;
    if($l[4]==0) {
	print STDERR "[$file]\n";
	system("rm -f $ARGV[0]$file");
    }
}


