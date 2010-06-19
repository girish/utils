#!/usr/bin/perl -w

# For comments and usage type:
# collect_mw_terms.pl -h

use strict;
use Getopt::Std;

my $usage;
{
$usage = <<"_USAGE_";
Usage:
collect_mw_terms.pl k connectors ngrams bigrams > output_ngrams
collect_mw_terms.pl -h

- k: a constant btw 0 and 1 (but expected to be towards the upper end
of this continuum);
- connectors: a list of connectors, one per line;
- ngrams: a list of ngrams, in format w1 ... wn fq, with the fields
delimited by a single space (fq can have decimal part, to handle cases
where fqs are smoothed);
- bigrams: same format as above, but only bigrams.

The script returns as output the longest ngrams that do not contain
as substring a shorter ngram with fq larger than that of the longer
ngram divided by the k constant (in other words, fq of longer ngram
must be at least equal to k*substring fq)

Ngrams that have a connector at one edge, or containing a sequence of
adjacent connectors are also filtered out.

_USAGE_
}

my %opts = ();
getopts('h',\%opts);
if ($opts{h}) {
    print $usage;
    exit;
}

my %is_conn = ();
my %max_hash = ();
my %explored = ();

my $k;

if (!($k = shift)) {
    print $usage;
    exit;
}

print STDERR "now processing connector list\n";
if (!(open CONNS, shift)) {
    print $usage;
    exit;
}
while (<CONNS>) {
    chomp;
    $is_conn{$_}++;
}
close CONNS;
print STDERR "connector list processed\n";

print STDERR "now processing ngram list\n";
if (!(open NGRAMS,shift)) {
    print $usage;
    exit;
}
while (<NGRAMS>) {

    chomp;

    my ($l,$center,$r,$fq) = /^([^ ]+) (.+) ([^ ]+) ([0-9\.]+)$/;

    my $conn;
    if ($is_conn{$l}) {
	my $next_l = ($center =~ /^([^ ]+) /);
	if ($is_conn{$next_l}) {
	    next;
	}
	$conn = "l";
    }
    if ($is_conn{$r}) {
	my $next_r = ($center =~ / ([^ ]+)$/);
	if ($is_conn{$next_r}) {
	    next;
	}
	$conn .= "r";
    }
    if (!$conn) {
	$conn = "n";
    }

    possibly_store("$center $r",$l,"l",$conn,$fq);
    possibly_store("$l $center",$r,"r",$conn,$fq);
}
close NGRAMS;
print STDERR "ngram list processed\n";

print STDERR "now processing bigram list and looking for multi-word terms\n";
if (!(open BIGRAMS,shift)) {
    print $usage;
    exit;
}
while (<BIGRAMS>) {
    chomp;
    my ($w1,$w2,$fq) = split;

    my $conn;
    if ($is_conn{$w1}) {
	$conn = "l";
    }
    if ($is_conn{$w2}) {
	$conn .= "r";
    }
    if (!$conn) {
	$conn = "n";
    }
    if ($conn =~ "lr") {
	next;
    }

    print_largest_mw_term("$w1 $w2",$conn,$fq);
}
close BIGRAMS;
print STDERR "finished!\n";

sub possibly_store {
    my ($gram,$curr_word,$side,$conn_flag,$fq) = @_;

    my ($maxstring,$max,$old_side,$conn,$word);

    if ( (!($maxstring = $max_hash{$gram})) ||
	 ((($max,$old_side,$conn,$word)=split(" ",$maxstring)) 
	  && ($max <= $fq)) ) {
	$max_hash{$gram} = "$fq $side $conn_flag $curr_word";
    }
}

sub print_largest_mw_term {
    my ($gram,$conn,$fq) = @_;

      
    my $found = 0;    

    my @unigrams = split " ",$gram;
    my $i = 0;
    my $j = 1;
    while ($j <= $#unigrams) {
	if ($found = $explored{"$unigrams[$i] $unigrams[$j]"}) {
	    return $found;
	}
	$i++;
	$j++;
    }
    
    my $maxstring;
    if ($maxstring = $max_hash{$gram}) {
	my ($nfq,$nside,$nconn,$nw) = split(" ",$maxstring);
	if ($nfq >= $k*$fq) {

	    my $next_gram;
	    if ($nside eq "l") {
		$next_gram = "$nw $gram";
	    }
	    else {
		$next_gram = "$gram $nw";
	    }

	    $found = print_largest_mw_term($next_gram,$nconn,$nfq);
	}
    }
	
    if ((!$found)&&($conn !~/[rl]/)) {
	print "$gram\n";
	$found = 1;
    }

    @unigrams = split " ",$gram;
    $i = 0;
    $j = 1;
    while ($j <= $#unigrams) {
	$explored{"$unigrams[$i] $unigrams[$j]"} = $found;
	$i++;
	$j++;
    }
    
    delete $max_hash{$gram};
	
    return $found; 
}
