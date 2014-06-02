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
	($id, $count, $stag, $entr) = split /\t/, $line;
        $chr = "chr$chr" unless($chr=~/^chr/);
	$data{$name}{$id} += $count;
	$rows{$id} = $cols{$name} = 1;
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
