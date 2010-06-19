#!/usr/bin/perl -w

# For comments, usage, etc., do:
# doc_delimited_uniq.pl -h

use Getopt::Std;

{
$usage = <<"_USAGE_";
Usage: 
doc_delimited_uniq.pl delimiter corpus > doc_uniqued_corpus 
doc_delimited_uniq -h

Given a corpus with one word per line, and delimiters separating
original documents (no delimiter at the end, delimiter at the
beginning) it leaves only one occurrence of each word in each
document.

After you apply this to the corpus, you can get document frequency by
removing the delimiters and doing a sort | uniq -c.

The delimiting line must be the only line containing the delimiter,
and it can also contain other stuff (e.g., some numbering or naming
scheme).

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

if ((!($delimiter = shift))||(!($corpus = shift))) {
    print $usage;
    exit;
}

open CORPUS, $corpus;
while (<CORPUS>) {
    $curr = $_;
    if ($curr =~ /$delimiter/) {
	if ($prev_del) {  # to skip first delimiter
	    print "$prev_del";
	    foreach $w (keys %encountered) {
		print $w;
	    }
	    %encountered = ();
		       }
	$prev_del = $curr;
    }
    else {
	$encountered{$curr} = 1;
    }
}
close CORPUS;

print "$prev_del";
foreach $w (keys %encountered) {
    print $w;
}
