#!/usr/bin/perl

sub get_attributes {
    my %res = ();
    while(@_[0]=~/([\w\_\d]+)[\s*=](.*?)\;/g) {
        $res{$1} = $2;
        $res{$1} =~ s/^\"(.*)\"$/$1/;
    }
    return(%res);
}


if(@ARGV==0) {
    print STDERR "This utility takes a DCC index file from STDIN and outputs a TSV table of attribute values. The names of attributes are in ARGV.\n";
    exit;
}

while(<STDIN>) {
    chomp;
    @arr = split /\t/;
    %attr = get_attributes($arr[8]);
    $attr{'INT'} = join("_",@arr[0,3,4,6]);
    print join("\t",@attr{@ARGV}), "\n";
}


