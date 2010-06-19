#!/usr/bin/perl -w
#
# for documentation and usage try
# discard_duplicates.pl -h | more

use strict;
use Getopt::Std;
use Digest::MD5 qw(md5);

# DOC HERE

my $usage;
{
$usage = <<"_USAGE_";

This is a very basic script to spot and remove perfect duplicates in a
collection of documents stored in a single file, separated by a
delimiter line beginning with a fixed string.

For each set of duplicate documents, only the first is preserved.

All space is removed from documents before checking if they are
identical (so that, e.g., docs that were formatted with different
criteria and differ only in terms of line breaks will be considered
identical).

Each document in the collection must be prefixed by a line that begins
with a non-ambiguous string. For example, the delimiter could be
"CURRENT URL", in which case the delimiting lines could look like:

CURRENT URL http://www.blahblahblah.org

The delimiter can be specified with the option -d; default is "CURRENT
URL".

The script requires the following perl module to be installed (should
be part of default installation):

Digest::MD5

Usage:

$0 doc_collection_with_default_delimiter 
                   > doc_collection.nodup

$0 -d "delimiter string" doc_collection 
                   > doc_collection.nodup

$0 -h | more

Options:

-d delimiter: the string marking lines delimiting documents
   (default: "CURRENT URL")

-h: print this information and quit

Copyright 2005 Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}

my %opts = ();
getopts('d:h',\%opts);


if ($opts{h}) {
	print $usage;
	exit;
}

my $delimiter;
if (!($delimiter = $opts{d})) {
    $delimiter = "^CURRENT URL";
}

my $to_be_digested = "";
my $digest = "";
my $perfect_copy = "";
my $curr_line = ();
my %seen = ();


while (<>) {
    if (/^$delimiter/) {
	if ($to_be_digested) {
	    $digest = md5($to_be_digested);
	    if (!$seen{$digest}) {
		print "$perfect_copy";
		$seen{$digest}++;
	    }
	}
	$perfect_copy = $_;
	$to_be_digested = "";
	next;
    }
		
	$curr_line = $_;
	$perfect_copy .= $curr_line;
	chomp $curr_line;
	$curr_line =~ s/[\t \r\n]+//g;
	$to_be_digested .= $curr_line;
}

# dont' forget last doc!
if ($to_be_digested) {
    $digest = qw($to_be_digested);
    if (!$seen{$digest}) {
	print "$perfect_copy";
    }
}
