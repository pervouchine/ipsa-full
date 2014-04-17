#!/usr/bin/perl
use Perl::utils;

if(@ARGV==0) {
}

parse_command_line(i => {description=>'input gtf file name and label', array=>hash});

%input  = @i;

die unless(keys(%input)>0);

foreach $file(keys(%input)) {
    $name = $input{$file};
    print STDERR "[$file $name";
    open FILE, $file;
    while($line = <FILE>) {
	($chr, $beg, $end, $str, $count) = split /\t/, $line;
        $chr = "chr$chr" unless($chr=~/^chr/);
        $id = "$chr\_$beg\_$end\_$str";
	$data{$name}{$id} += $count;
	$rows{$id}++;
	$cols{$name}++;
    }
    print STDERR "]", ++$n, "\n";
    close FILE;
}

@c = sort keys(%cols);
@r = sort keys(%rows);
print join("\t", @c),"\n";
foreach $id(@r) {
    @arr = ($id);
    foreach $name(@c) {
        push @arr, 0 + $data{$name}{$id};
    }
    print join("\t", @arr), "\n";
}
