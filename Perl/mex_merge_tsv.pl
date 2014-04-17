#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
}

parse_command_line(i  => {description=>'input gtf file name and label', array=>hash});

################################################################################################################################

%input  = @i;

die unless(keys(%input)>0);

foreach $file(keys(%input)) {
    $name = $input{$file};
    print STDERR "[$file $name";
    open FILE, $file;
    while($line = <FILE>) {
	chomp $line;
	@a = split /\t/, $line;
	$z = pop(@a);
        ($chr, $str, $deg, $location) = split /\t/, $line;
        $chr = "chr$chr" unless($chr=~/^chr/);
        @segm = ();
	@array = split /\,/, $location;
        for($i=0;$i<@array;$i++) {
            ($beg, $end, $offset) = split /\:/, $array[$i];
            push @segm, ($beg, $end);
        }
	for($i=0; $i<@segm-2; $i+=2) {
	    $id = join("_", $chr, $segm[$i], $segm[$i+1], $segm[$i+2], $segm[$i+3], $str);
	    $data{$name}{$id} += $z;
	    $rows{$id} = 1;
	}
	$cols{$name} = 1;
    }
    print STDERR "]",++$n,"\n";
    close FILE;
}

@c = sort keys(%cols);
@r = sort keys(%rows);

print join("\t", @c),"\n";
foreach $id(@r) {
    print $id;
    foreach $name(@c) {
	$value = $data{$name}{$id};
        print "\t", $value+0;
    }
    print "\n";
}
