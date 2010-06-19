#!/usr/bin/perl -w

# For comments, usage, etc., do:
# collect_urls_from_yahoo.pl -h
# perldoc collect_urls_from_yahoo.pl
# 
# Yahoo Search API feature contributed by Cyrus Shaoul, Feb 6th, 2007

use strict;
use Getopt::Std;
use Yahoo::Search;

my $usage = <<"_USAGE_";
Usage: 
  $0 options seeds_file
 
  For each query string (word/phrase or combination of words/phrases)
  in input filter, this script returns all the pages that matched the 
  query on Yahoo.

  This script can use a Yahoo API key, available from: http://developer.yahoo.com/, 
  and requires that the Yahoo::Search Perl module be installed.

  Other search parameters can be specified via the options.
 
  Notice that Yahoo resticts automated searches via yahoo API to thousands
  per day, and that each block of 10 results returned counts as a search.

  For more information, please type:

  perldoc collect_urls_from_yahoo.pl

Options:
  -k yahoo_key
    Optional. Your Yahoo API key.
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

# languages supported by yahoo as of Feb 2007
my %langs = (
    "" => "",
    "Arabic" => "ar",
    "Chinese_CN" => "szh",
    "Chinese_TW" => "tzh",
    "Croatian" => "hr",
    "Czech" => "cs",
    "Danish" => "da",
    "Dutch" => "nl",
    "English" => "en",
    "Estonian" => "et",
    "Finnish" => "fi",
    "French" => "fr",
    "German" => "de",
    "Greek" => "el",
    "Hebrew" => "iw",
    "Hungarian" => "hu",
    "Icelandic" => "is",
    "Indonesian" => "id",
    "Italian" => "it",
    "Japanese" => "ja",
    "Korean" => "ko",
    "Latvian" => "lv",
    "Lithuanian" => "lt",
    "Norwegian" => "no",
    "Persian" => "fa",
    "Polish" => "pl",
    "Portuguese" => "pt",
    "Romanian" => "ro",
    "Russian" => "ru",
    "Serbian" => "sr",
    "Slovak" => "sk",
    "Slovenian" => "sl",
    "Spanish" => "es",
    "Swedish" => "sv",
    "Thai" => "th",
    "Turkish" => "tr"
);

my %opts = ();
getopts('k:l:c:nh',\%opts);

if ($opts{n}) {
    print "CURRENTLY SUPPORTED LANGUAGE NAMES:\n";
    print join "\n", sort keys(%langs);
    print "\n";
    exit;
}

if ($opts{h}) {
    print $usage;
    exit;
}

if (!open LIST, shift) {
    print $usage;
    exit;
}

my $language = undef;
my $maxresults = 10;	
my $key = rand(1000000);	
while (<LIST>) {
    print "CURRENT_QUERY $_";
    chomp;

    if ($opts{l}) {
	$language = $langs{$opts{l}};
    } 
    if ($opts{c}) {
	$maxresults = $opts{c};
    }             
    if ($opts{k}) {
	$key = $opts{k};
    } 

    if (length($_)>1) {
	my @Results = Yahoo::Search->Results(Doc => $_,
					     AppId => $key,
					     Mode         => 'all', # all words
					     Start        => 0,
					     Count        => $maxresults,
					     AllowAdult   => 0, # no porn, please
					     AllowSimilar => 0, # no dups, please
					     Language     => $language,
					     Type         => 'html'
					     );
	warn $@ if $@; # report any errors
	
	for my $Result (@Results)
	{
	    printf "%s\n",       $Result->Url;
	}
    }
}


=head1 NAME

B<collect_urls_from_yahoo.pl>: searches Yahoo with list of queries from input file and returns list of urls found.

=head1 SYNOPSIS

collect_urls_from_yahoo.pl -k YOUR_YAHOO_KEY query_list > url_list

collect_urls_from_yahoo.pl -k YOUR_YAHOO_KEY -c 20 -l Danish query_list > url_list

collect_urls_from_yahoo.pl -h

collect_urls_from_yahoo.pl -n

=head1 DESCRIPTION

This script can be used to build a list of urls from Yahoo on topics of interest. I use it as part of a procedure to build corpora from the web.

The input file must contain a list of Yahoo queries, one query per line.

Syntax of the queries is same as for manual Yahoo queries, e.g.:

old town

''old town''

''the old town''

Please experiment. It is instructive to compare url list found by script with urls found through manual Yahoo searches.

For each query in the input, the output will contain the line ''CURRENT_QUERY current_query'' followed by the list of urls that were found, one per line.

All text in the query list must be in ASCII or UTF-8 encodings.

No filtering is performed on output (e.g., I do not remove urls that end in .doc, I do not remove repeated urls, etc.), in the name of modularity (you can easily filter the output on the command line), and so that you can manually inspect the output to look for ''bad'' seeds (e.g., seeds that are too similar to each other, seeds that find a lot of non-html pages, etc.) 

The script uses the Yahoo::Search module, which, in turn, is an interface to the Yahoo Web APIs.

Plese see the Yahoo API documentation and the Yahoo::Search documentation for more information.

Crucially, in order to run the script you have to obtain a Yahoo API key from the Yahoo Web API page: 

http://developer.yahoo.com/

One key gives you thousands of automated searches per day. However, given that one API search returns a maximum of 10 results, if you ask the script for more results per search you are actually making more than one search, from the point of view of the Yahoo API.

Yahoo::Search is not part of the standard (perl 5.8.0) distribution. Thus, you will have to install it. If you are lucky, the following should be enough:

sudo perl -MCPAN -e shell

cpan> install Yahoo::Search

I tested the script with Yahoo::Search version 1.7.10

I tried to use the C<safe> and C<filter> methods of Net::Yahoo::Search to let the user control whether they want to use Yahoo's searchSafe and filter options, but I was not able to switch these options off: this means that in the current version of the script searches are always conducted in safe and filtered mode.

The future of the script depends of course on the future of the Yahoo Web APIs and on the future of Net::Yahoo.

=head1 OPTIONS

B<-k> YOUR_YAHOO_API_KEY

Optional.

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
Yahoo Feature added by Cyrus Shaoul, cyrus.shaoul AT ualberta.ca

=head1 BUGS

-None known. Please report any!

=head1 COPYRIGHT

Copyright 2003, Marco Baroni
Copyright 2007, Cyrus Shaoul

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=head1 SEE ALSO

Yahoo::Search

http://developer.yahoo.com/

print_pages_from_url_list.pl

=cut


