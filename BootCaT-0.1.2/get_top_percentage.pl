#!/usr/bin/perl -w


# For comments, usage, etc., do:
# get_top_percentage.pl -h

use Getopt::Std;

#overkill?
use POSIX qw(ceil);

{
$usage = <<"_USAGE_";
Usage: 
get_top_percentage.pl delimiter percentage input_file 
get_top_percentage -h

This takes two arguments: a number (to be interpreted as a percentage
value) and the name of a file (or - if stdin is being piped).

It assumes that the file contains a list of (n-)grams sorted by a
certain measure. The input must thus be sorted, and each line must be
of the form n-gram value

The important thing is that value must be at the end of line, preceded
by some form of space, and that it contains only digits and
periods. Other things (eg, number of grams and how they are delimited)
do not matter.

Output is a list of the top n n-grams, where n is the number of
n-grams in the top x percent (rounded up to int), plus the tail of
n-grams that have the same value as the last n-gram in the top x
percent.

For example, suppose that the input file has 208007 lines/ngrams, and
the user wants the top 5%. 5% of 208007 is 10400.35. Rounding up, this
becomes 10401. Now, suppose that the ngram at line 10401 in the sorted
file has value 40, and there are 10 more lines below it that have
value 40. Then, these lines will also be printed, and thus the output
will contain 10411 lines.

NB: script creates temporary file tempXXXX; no check is performed to
make sure that this file does not exist, and no error handling is
attempted...

I would really like to solve the piping stdin problem in a less hacky
way...

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}

%opts = ();
getopts('h',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
} 

if ((!($perc = shift))||(!($file = shift))) {
    print $usage;
    exit;
}

`cat $file \> tempXXXX`;

$n = `wc tempXXXX`;
$n =~ s/\s*([0-9]+)\s.*/$1/;
chomp $n;

$top = ceil(($perc/100)*$n);

$i= 0;

open F,"tempXXXX";
while (<F>) {

    # print top words
    if ($i < $top) {
	print;

	$prev = $_;
	$prev =~ s/.*\s([0-9\.]+)$/$1/;
	chomp $prev;

	$i++;

	next;
    }

    # beyond top, keep printing if value is same as that of last word in top
    $line = $_;
    $curr = $line;
    $curr =~ s/.*\s([0-9\.]+)$/$1/;
    chomp $curr;    
    if ($curr == $prev) {
	print $line;
	next;
    }

    # we get here if we are beyond top and value of previous line was below
    # value of last top word
    last;
}
close F;

`rm -f tempXXXX`;
