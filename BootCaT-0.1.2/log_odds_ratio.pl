#!/usr/bin/perl -w

# For usage and comments, type:
# log_odds_ratio.pl -h

use Getopt::Std;

{
$usage = <<"_USAGE_";
Usage: 
logoddsratio.pl target_corpus_size ref_corpus_size fq_file

This script assumes input in format:

word fq_in_target_corpus fq_in_ref_corpus

with fields delimited by one or more space or tabs.

The other arguments are the size of target corpus (in number words)
and the size of the reference corpus (in number words).

For each line in the input, we calculate the log of the odds ratio
(see section 2.8 of Everitt 1992) by assuming the folowing contingency
table:

                       curr_w=w     curr_w!=w
corpus=target             a            b
corpus!=reference         c            d

where a is the frequency of a word in the target corpus, b is the size
of the target corpus minus a, c is the frequency of the word in the
reference corpus and d is the size of the reference corpus minus c.

The odds ratio is given by ad/cb, and the log odds ratio is:

log_odds_ratio = ln(ad/cb) = ln(a) + ln(d) - ln(c) - ln(b)

The current version of the script assumes that some smoothing or
trimming took place, such that the input to the script does not
contain zeroes.

Because of the logs, if there is a 0 the script dies.

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

if ((!($n_target = shift))||(!($n_ref = shift))||(!($i_file = shift))) {
    print $usage;
    exit;
}
# $n_target is target corpus size
# $n_ref is reference corpus size

open(IFILE,$i_file);
while (<IFILE>) {
    
    ($w,$fq_target,$fq_ref) = split "[ \t]+";
    chomp $fq_target;
    
    $lor = log($fq_target) + log($n_ref - $fq_ref) 
	- log($fq_ref) - log($n_target - $fq_target);

    printf("%s %.10f\n",$w,$lor);
#    print "$w $lor\n";
}
close(IFILE);
