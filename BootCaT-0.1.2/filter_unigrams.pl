#!/usr/bin/perl



use Getopt::Std;

{
$usage = <<"_USAGE_";

Usage: 
filterunigrams.pl [-s] word_list unigram_list > filtered_unigrams
filtered_unigrams.pl -h

- word_list is in one-word per line format;

- unigram_list is a frequency list in word frequency format (space or
 tab delimited).

This is a script to filter out unigrams from a frequency list on the
basis of a list of words.

If option -s (for stopword) is set, then word list is treated as
stopword list, i.e., unigrams that are in list are removed from
unigram list; otherwise, only those unigrams that are in list are kept

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}


%opts = ();
getopts('sh',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}

$stop_op = 0;
if ($opts{s}) {
  $stop_op = 1;
}

if (!(open WLIST, shift)) {
    print $usage;
    exit;
}
while (<WLIST>) {
  $i=$_;
  chomp $i;
  $in{$i} = 1;
}
close WLIST;

if (!(open ULIST, shift)) {
    print $usage;
    exit;
}
while (<ULIST>) {
  $input = $_;
  ($w,$fq) = split "[\t ]",$input;
  if ($stop_op) {
    if ($in{$w}) {
      next;
    }
  }
  else {
    if (!$in{$w}) {
      next;
     }
  }
  print $input;
}
close ULIST;
