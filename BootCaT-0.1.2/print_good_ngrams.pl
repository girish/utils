#!/usr/bin/perl  -w

# For comments and usage, type:
# print_good_ngrams.pl -h

use Getopt::Std;

{
$usage = <<"_USAGE_";
Usage:
print_good_ngrams.pl max_gram_size stop_word_list target_word_list corpus
print_good_ngrams.pl -h

This script takes as input a number specifying the largest n requested
(n as in n-gram), a stop word list (in one word per line format), a
list of unigram target words (same format) and a corpus (same format).

As output, it prints out all the n-grams in the corpurs (starting from
bigrams and up to the user-specified n) that contain at least one
target word and no stop word.

Since stop word list is checked before target word list, if a word is
in both lists it will be treated as a stop word.

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

if ((!($real_n = shift))||(!($swords = shift))) {
    print $usage;
    exit;
}
$n = $real_n -1;


if ((!($targets = shift))||(!($corpus = shift))) {
    print $usage;
    exit;
}

open SWORDS, $swords;
while (<SWORDS>) {
    chomp;
    $is_stop{$_} = 1;
}
close SWORDS;

open TARGETS, $targets;
while (<TARGETS>) {
    chomp;
    $is_target{$_} = 1;
}
close TARGETS;

$target_in_window = 0;
$i = $n;

open CORPUS, $corpus;
while (<CORPUS>) {
    chomp;
    if ($is_stop{$_}) {
	@ngram = ();
	$target_in_window = 0;
	$i = $n;
	next;
    }

    shift @ngram;
    $ngram[$n] = $_;

    if ($is_target{$_}) {
	$target_in_window = $real_n;
    }
    
    if ($target_in_window) {
	$c = $n - 1;
	while ($c >= $i) {
	    if ($c < $target_in_window) {
		print join ' ',@ngram[$c...$n];
		print "\n";
	    }
		$c--;
	    	}
	$target_in_window--;
    }
    if ($i > 0) {
	$i--;
    }
}
close CORPUS;
