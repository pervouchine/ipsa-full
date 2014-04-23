#!/usr/bin/perl
# Binary relations library
# Binary relation = associative array with two keys; values don't matter

#       Copyright 2011,2012 Dmitri Pervouchine (dp@crg.eu)
#       This file is a part of the IRBIS package.
#       IRBIS package is free software: you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation, either version 3 of the License, or
#       (at your option) any later version.
#       
#       IRBIS package is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#       
#       You should have received a copy of the GNU General Public License
#       along with IRBIS package.  If not, see <http://www.gnu.org/licenses/>.
#

return(1);

##############################################################################################################
# I/O functions
##############################################################################################################

sub print_relation {
    my $x;
    my $y;
    foreach $x (keys(%{@_[0]})) {
	foreach $y (keys(%{${@_[0]}{$x}})) {
	    print "$x\t$y\n";
	}
    }
    print "\n";
}

##############################################################################################################
# Algebraic functions
##############################################################################################################

sub symmetrify {
    # input: pointer to a relation
    foreach my $x (keys(%{@_[0]})) {
	next unless($x);
	foreach my $y (keys(%{${@_[0]}{$x}})) {
	    next unless($y);
	    ${@_[0]}{$y}{$x}=${@_[0]}{$x}{$y};
	}
	${@_[0]}{$x}{$x}=1
    }
}

sub product {
    # input: pointer to the first term, pointer to the second term, pointer to the output
    foreach my $x (keys(%{@_[0]})) {
	next unless($x);
	foreach my $y (keys(%{${@_[0]}{$x}})) {
	    next unless($y);
	    foreach my $z (keys(%{${@_[1]}{$y}})) {
		next unless($z);
		${@_[2]}{$x}{$z}=1;
	    }
	}
    }
}

sub adjoint {
    foreach my $x (keys(%{@_[0]})) {
	foreach my $y (keys(%{${@_[0]}{$x}})) {
	    ${@_[1]}{$x}{$y}=1;
	}
    }
}

##############################################################################################################
# Transitive closure 
##############################################################################################################

sub getall {
    my $x = @_[1];
    my @res = ($x);
    $BINREL_FLAG{$x}=1;
    foreach my $y (keys(%{${@_[0]}{$x}})) {
	next if($y eq undef);
	push @res, getall(@_[0],$y) unless($BINREL_FLAG{$y});
    }
    return(@res);
}

sub transitive_closure {
    %BINREL_FLAG=();
    my $x;
    my %res=();
    foreach $x (keys(%{@_[0]})) {
	next if($x eq undef);
	unless($BINREL_FLAG{$x}) {
	    foreach $y(getall(@_[0],$x)) {
		next if($y eq undef);
		$res{$x}{$y}=1;
	    }
	}
    }
    return(%res);
}

sub cliques {
    %BINREL_FLAG=();
    my @res = ();
    foreach my $x (keys(%{@_[0]})) {
	next if($x eq undef);
	unless($BINREL_FLAG{$x}) {
	    push @res, [getall(@_[0],$x)];
	}
    }
    return(@res);
}
