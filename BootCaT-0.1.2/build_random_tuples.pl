#!/usr/bin/perl -w

# For comments, usage, etc. do:
# build_random_tuples -h

use Memoize; 
use Getopt::Std;

memoize('factorial');

getopts('n:l:h');

{
$usage = <<"_USAGE_";
Usage:
build_random_tuples.pl [-nN] [-lL] items
build_random_tuples.pl -h

This script generates a list of L random N-tuples from the items 
in the input list (assumed to be in one-keyword-per-line format).

The items are sampled with replacement. 

The tuples will not be identical (nor will they be permutations of 
each other).

Thus, the maximum number of tuples requested cannot be higher than the 
number of N-sets that can be chosen from the number of items.

N defaults to 3, L defaults to 10.

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.
_USAGE_
}

if ($opt_h) {
    $opt_h = 1;
    # previous is just to avoid warning about $opt_h being used only once
    print $usage;
    exit;
}

if (!$opt_n) {
    $opt_n = 3;
}
if (!$opt_l) {
    $opt_l = 10;
}

while (<>) {
    # undos
    s/\r//g;
    chomp;
    # if item is multi-word expression, remove double quotes
    # and (re-)insert them
    if (/[ ]/) {
	s/^\"*/\"/;
	s/\"*$/\"/;
    }

    push @items,$_;
}

$k = scalar(@items);

$combs = factorial($k)/(factorial($k-$opt_n)*factorial($opt_n));

if ($opt_l > $combs) {
    print "Too many tuples requested for the number of items!\n";
    print $usage;
    exit;
}

srand;

while ($opt_l) {
    $item = $items[rand $k];
    while (defined($picked{$item})) {
	$item = $items[rand $k];
    }
    
    $picked{$item}++;
    push @tuple, $item;

    if (scalar(@tuple) == $opt_n) {
	$ordered = join ' ',(sort @tuple);
	if (!defined($seen{$ordered})) {
	    $seen{$ordered}++;
	    print join ' ',@tuple;
	    print "\n";
	    $opt_l--;
	}
	@tuple = ();
	%picked = ();
    }
}


sub factorial {
    my $n = shift;
    return undef if $n < 0; 
    return 1 if $n == 0; 
    return $n * factorial($n - 1) ; 
}
