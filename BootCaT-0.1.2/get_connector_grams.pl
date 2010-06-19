#!/usr/bin/perl  -w

# For comments, usage, etc., do:
# get_connector_grams.pl -h

use Getopt::Std;

{
$usage = <<"_USAGE_";
Usage:
get_connector_grams.pl n term_list corpus 
get_connector_grams.pl -h

Given a list of unigram terms (one term per line) and a corpus in
one-word-per line format, this script prints all the n-grams that have
terms as first and last grams.

This is useful to find words that often occur between two terms
(likely connectors).

The n in n-grams must be passed by user as argument.

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

if ((!($n = shift))||(!($termlist = shift))||(!($corpus = shift))) {
    print $usage;
    exit;
}

$n--;

open TERMLIST, $termlist;
while (<TERMLIST>) {
    $t=$_;
    chomp $t;
    $is_term{$t} = 1;
}
close TERMLIST;

# initializing arrays

$i = 0;

while ($i <= $n) {
    $ngrams[$i] = "";
    $termtracker[$i] = 0;
    $i++;
}

open CORPUS, $corpus;
while (<CORPUS>) {
  $w = $_;
  chomp $w;
  shift @ngrams;
  shift @termtracker;
  $ngrams[$n] = $w;

  if ($is_term{$w}) {
      $termtracker[$n] = 1;
      if ($termtracker[0]) {
	  $contains_term = 0;
	  foreach $termindex (@termtracker[1...($n-1)]) {
	      if ($termindex) {
		  $contains_term = 1;
		  last;
	      }
	  }
	  if (!$contains_term) {
	      print join " ",@ngrams[0...$n];
	      print "\n";
	  }
      }
  }
  else {
      $termtracker[$n] = 0;
  }
}
close CORPUS;
