#!/usr/bin/perl -w

# For comments and usage, type:
# connect_bi_connectors.pl -h

use Getopt::Std;

{
$usage = <<"_USAGE_";
Usage:
connect_bi_connectors.pl bigrams corpus

Given a list of bigrams and a corpus, in one word per line format,
this script returns the corpus with all the occurrences of the bigrams
substituted by the bigrams written as single orthographic words with
an underscore connecting the parts.

For example, if *of the* is in list, all occurrences of this sequence
in corpus (on two lines) will be converted into of_the on single
line.

In cases of w1 w2 w3 sequences where both w1 w2 and w2 w3 are in
bigram list, we go left to right (top-down?) and replace w1_w2
with underscore.

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.
_USAGE_
}

%opts = ();
getopts('h',\%opts);


%opts = ();
getopts('th',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
} 

if ((!($conlist = shift))||(!($corpus = shift))) {
    print $usage;
    exit;
}

open CONLIST,$conlist;
while (<CONLIST>) {
    ($f,$s) = split;
    $sec_of{$f} = $s;
}
close CONLIST;

open CORPUS,$corpus;
while(<CORPUS>) {

    chomp;

    if (defined($prev)) {
	if ($_ eq $s) {
	    print "${prev}_$s\n";
	    undef($prev);
	    next;
	}
	print "$prev\n";
    }

    if ($s = $sec_of{$_}) {
	$prev = $_;
	next;
    }

    undef($prev);
    print "$_\n";
}       
close CORPUS;

if (defined($prev)) {
    print "$prev\n";
}
