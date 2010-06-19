#!/usr/bin/perl -w

# For comments, usage, etc., do:
# add1_smoothing.pl -h

use Getopt::Std;

{
$usage = <<"_USAGE_";
 Usage: 
  $0 [-t] general_corpus_fq_list specialized_corpus_fq_list
  $0 -h

  The general_corpus_fq_list is a whitespace-delimited list of words
  with their frequencies in a reference corpus. The
  specialized_corpus_fq_list is a whitespace-delimited list of words
  with their frequencies in a specialized corpus (but the frequencies
  in this case do not really matter).

  The output will be a list that contains all and only the words in
  the specialized list with their frequency in the general corpus + 1,
  i.e. if a word had a frequency of 3 in the general corpus, its
  output frequency will be 4, if a word did not appear in the general
  corpus list (i.e., it had a frequency of 0 there), its output
  frequency will be 1.

  The list is printed to an output file that is named as the input
  general list, but with .add1 suffix added.

  If option -t is passed, the script also prints to STDERR an estimate
  of the number of words in the *smoothed* corpus, given by the sum of
  all the frequencies in the general frequency list + 1 per word + the
  number of words that are in the specialized list but not in the
  general list.

  If option -h is passed, the script prints this message and quits.

  NB: The script expects the other BootCaT tools to be in the path.

  NB2: Any pre-existing file matching XXXTEMP*XXX pattern is silently
  removed by the script.

 This program is free software. You may copy or redistribute it under
 the same terms as Perl itself.

_USAGE_

}

%opts = ();
getopts('th',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
} 

if ((!($gen = shift))||(!($spec = shift))) {
    print $usage;
    exit;
}

die "Ooops, file $gen.add1 already exists: $!"
    if -e "$gen.add1";


`rm -f TEMPXXX*XXX`;

print STDERR "getting the types in general corpus\n";

`gawk '{print \$1}' $gen | sort > TEMPXXXwords_in_genXXX`;

print STDERR "adding one\n";

`gawk '{print \$1}' $spec | simple_filter.pl -s TEMPXXXwords_in_genXXX - | gawk '{print \$1,"0"}' | gawk '{i=\$2+1;print \$1,i}' $gen - | sort - > TEMPXXXgen_unifqs_add1XXX`;

if ($opts{t}) {
    print STDERR "estimate of size of smoothed corpus:\n";
    $tot = `gawk 'BEGIN{i=0}{i+=\$2}END{print i}' TEMPXXXgen_unifqs_add1XXX`;
    print STDERR "$tot";
}

print STDERR "creating smoothed general corpus fq list for words in specialized corpus\n";

`gawk '{print \$1}' $spec | filter_unigrams.pl - TEMPXXXgen_unifqs_add1XXX | sort > $gen.add1`;

`rm -f TEMPXXX*XXX`;
