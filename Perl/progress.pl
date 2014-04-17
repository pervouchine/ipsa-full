exit unless(@ARGV>0);

@ARGV = split /\n/, `ls $ARGV[0]*.mk`;

foreach $file(@ARGV) {
  open FILE, $file;
  print "$file:\n";
  %f = %g = ();
  while(<FILE>) {
    chomp;
    @a = split /\s*\:\:\s*/;
    if(@a>1) {
	@b = split /\s+/, $a[1];
	foreach $z(@b) {
	    $f{$a[0]}{$z}=1;
	    $g{$a[0]}{$z}=1 if(-e $z);
	}
    }
  }

  foreach $k(sort keys(%f)) {
    if(keys(%{$f{$k}})>1) {
	print "$k\t",sprintf("%.1lf",100*keys(%{$g{$k}})/keys(%{$f{$k}})), "\n";
    }
  }
}


