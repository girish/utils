#!/usr/bin/perl -w

# For comments, usage, etc., do:
# collect_urls_from_google.pl -h
# perldoc collect_urls_from_google.pl

use strict;
use Getopt::Std;
use Net::Google::Search;

my $usage = <<"_USAGE_";
Usage: 
  $0 options seeds_file
 
  For each query string (word/phrase or combination of words/phrases)
  in input filter, this script returns all the pages that matched the 
  query on Google.

  Script requires a googleapi key: http://www.google.com/apis

  Other search parameters can be specified via the options.
 
  Notice that Google resticts automated searches via google API to 1000
  per day, and that each block of 10 results returned counts as a search.

  For more information, please type:

  perldoc collect_urls_from_google.pl

Options:
  -k google_key
    Mandatory. Your Google API key.
  -l language_name
   Only pages in the requested language are returned. Default is no 
   language restriction.
  -c count
   Maximum number of pages returned per query.
  -n names
   Prints list of names of languages currently supported and quits.
  -h
   Prints this information and quits.
_USAGE_

# languages supported by google as of July 25 2003
my %langs = (
    "" => "",
    "Arabic" => "lang_ar",
    "Chinese_CN" => "lang_zh-CN",
    "Chinese_TW" => "lang_zh-TW",
    "Czech" => "lang_cs",
    "Danish" => "lang_da",
    "Dutch" => "lang_nl",
    "English" => "lang_en",
    "Estonian" => "lang_et",
    "Finnish" => "lang_fi",
    "French" => "lang_fr",
    "German" => "lang_de",
    "Greek" => "lang_el",
    "Hebrew" => "lang_iw",
    "Hungarian" => "lang_hu",
    "Icelandic" => "lang_is",
    "Italian" => "lang_it",
    "Japanese" => "lang_ja",
    "Korean" => "lang_ko",
    "Latvian" => "lang_lv",
    "Lithuanian" => "lang_lt",
    "Norwegian" => "lang_no",
    "Portuguese" => "lang_pt",
    "Polish" => "lang_pl",
    "Romanian" => "lang_ro",
    "Russian" => "lang_ru",
    "Spanish" => "lang_es",
    "Swedish" => "lang_sv",
    "Turkish" => "lang_tr"
);

my %opts = ();
getopts('k:l:c:nh',\%opts);

if ($opts{n}) {
    print "CURRENTLY SUPPORTED LANGUAGE NAMES:\n";
    print join "\n", sort keys(%langs);
    print "\n";
    exit;
}

if ((!($opts{k}))||($opts{h})) {
    print $usage;
    exit;
}

if (!open LIST, shift) {
    print $usage;
    exit;
}

while (<LIST>) {
    print "CURRENT_QUERY $_";
    chomp;

    my $search = Net::Google::Search->new({key=>$opts{k}});

    if ($opts{l}) {
	$search->lr($langs{$opts{l}});
    }
    if ($opts{c}) {
	$search->max_results($opts{c});
    }             

    $search->query($_);

    if (!(map { print $_->URL()."\n"; } @{$search->results()})) {
	print "NO_RESULTS_FOUND\n";
    }
}


=head1 NAME

B<collect_urls_from_google.pl>: searches Google with list of queries from input file and returns list of urls found.

=head1 SYNOPSIS

collect_urls_from_google.pl -k YOUR_GOOGLE_KEY query_list > url_list

collect_urls_from_google.pl -k YOUR_GOOGLE_KEY -c 20 -l Danish query_list > url_list

collect_urls_from_google.pl -h

collect_urls_from_google.pl -n

=head1 DESCRIPTION

This script can be used to build a list of urls from Google on topics of interest. I use it as part of a procedure to build corpora from the web.

The input file must contain a list of Google queries, one query per line.

Syntax of the queries is same as for manual Google queries, e.g.:

old town

''old town''

''the old town''

Please experiment. It is instructive to compare url list found by script with urls found through manual Google searches.

For each query in the input, the output will contain the line ''CURRENT_SEED current_query'' followed by the list of urls that were found, one per line.

If no url was found for a certain query, the line NO_RESULTS_FOUND is printed.

No filtering is performed on output (e.g., I do not remove urls that end in .doc, I do not remove repeated urls, etc.), in the name of modularity (you can easily filter the output on the command line), and so that you can manually inspect the output to look for ''bad'' seeds (e.g., seeds that are too similar to each other, seeds that find a lot of non-html pages, etc.) 

The script uses the Net::Google module, which, in turn, is an interface to the Google Web APIs.

Plese see the Google API documentation and the Net::Google documentation for more information.

Crucially, in order to run the script you have to obtain a Google API key from the Google Web API page: 

http://www.google.com/apis

One key gives you 1000 automated searches per day. However, given that one API search returns a maximum of 10 results, if you ask the script for more results per search you are actually making more than one search, from the point of view of the Google API.

Net::Google is not part of the standard (perl 5.8.0) distribution. Thus, you will have to install it. If you are lucky, the following should be enough:

sudo perl -MCPAN -e shell

cpan> install Net::Google

I tested the script with Net::Google version 0.21.

I tried to use the C<safe> and C<filter> methods of Net::Google::Search to let the user control whether they want to use Google's searchSafe and filter options, but I was not able to switch these options off: this means that in the current version of the script searches are always conducted in safe and filtered mode.

The future of the script depends of course on the future of the Google Web APIs and on the future of Net::Google.

=head1 OPTIONS

B<-k> YOUR_GOOGLE_API_KEY

Mandatory.

B<-l> Language

A language from the list of currently supported languages (default: no language restriction).

B<-c> Count

Maximum number of results per query. Default: 10.

B<-h>

Prints usage and quits.

B<-n>

Prints list of names of currently supported languages and quits.

=head1 AUTHOR

Marco Baroni, baroni AT sslmit.unibo.it

=head1 BUGS

- No control over searchSafe and filter options.

- Probably many other bugs: if you find one, please let me know: baroni AT sslmit unibo it

=head1 COPYRIGHT

Copyright 2003, Marco Baroni

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=head1 SEE ALSO

Net::Google

http://www.google.com/apis

print_pages_from_url_list.pl

=cut
