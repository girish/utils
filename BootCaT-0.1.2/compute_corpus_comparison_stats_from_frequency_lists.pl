#!/usr/bin/perl -w

use lib "/home/baroni/sw/UCS/System/Perl/lib";
use UCS;
use UCS::AM;
use Getopt::Std;

{
$usage = <<"_USAGE_";

This script takes two frequency lists as input, one with words from a
specialized corpus, the other with words from a reference corpus.

It produces as output a list of all the words in the specialized
corpus with various counts and statistics.

Input lists must be in format:

word fq

(tab-delimited).

Output list is in format:

word Fq-Spec Fq-Tot MI Log-Likelihood

(tab-delimited), where Fq-Spec is the frequency of the word in the
specialized corpus; Fq-Tot is the sum of the frequencies of the word
in the specialized and general corpus; MI and Log-Likelihood are
association measures representing how "typical" the word is of the
specialized corpus.

Script requires UCS modules to be present, and in path specified by
use lib directive.

Usage:

compute_corpus_comparison_stats_from_frequency_lists.pl spec_corpus.fq
    ref_corpus.fq > output

compute_corpus_comparison_stats_from_frequency_lists.pl -h | more

Copyright 2005, Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}

getopts('h');

if ($opt_h) {
    $opt_h = "blah";
    print $usage;
    exit;
}

$spec = shift or die "could not find specialized corpus frequency list";
$gen = shift or die "could not find general corpus frequency list";

print STDERR "now processing general corpus frequencies\n";

open GEN, $gen or die "could not open general frequency list";
while (<GEN>) {
    chomp;
    ($w,$f) = split "[ \t]+",$_; 
    $fq_gen{$w} = $f;
    $gen_N += $f;
}
close GEN;

print STDERR "$gen_N tokens seen in general corpus frequency list\n";

print STDERR "now processing specialized corpus frequencies\n";

open SPEC, $spec or die "could not open general frequency list";
while (<SPEC>) {
    chomp;
    ($w,$f) = split "[ \t]+",$_; 
    push @spec_words,$w;
    push @spec_fqs,$f;
    if (!($fq_gen = $fq_gen{$w})) {
	$fq_gen = 0;
    }
    push @tot_fqs,$f+$fq_gen;
    $spec_N += $f;
}
close SPEC;


print STDERR "$spec_N tokens seen in general corpus frequency list\n";

# cleaning up...
%fq_gen = ();

print STDERR "finished processing frequency data\n";

print STDERR "now computing MI and log likelihood\n";

$k = @spec_fqs;

$mi_exp = UCS::AM_Expression("MI");
$ll_exp = UCS::AM_Expression("log.likelihood");

$mi_array_ref = $mi_exp->evalloop($k, {f=>\@spec_fqs, f1=>\@tot_fqs, f2 => [ ($spec_N) x $k ], N => [ ($spec_N+$gen_N) x $k]});

$ll_array_ref = $ll_exp->evalloop($k, {f=>\@spec_fqs, f1=>\@tot_fqs, f2 => [ ($spec_N) x $k ], N => [ ($spec_N+$gen_N) x $k]});

print STDERR "now printing results\n";

while (defined($word = shift @spec_words)) {
    print "$word\t";
    print shift @spec_fqs;
    print "\t";
    print shift @tot_fqs;
    print "\t";
    print shift @$mi_array_ref;
    print "\t";
    print shift @$ll_array_ref;
    print "\n";

}

print STDERR "done\n";
