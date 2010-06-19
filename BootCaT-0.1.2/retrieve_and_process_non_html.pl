#!/usr/bin/perl

use strict;
use warnings;

use File::Temp qw / tempfile /;
use Getopt::Std;
use LWP;

my $usage = <<"_USAGE_"; 

This script downloads all the pdf (option -p) and/or "doc" (option -d)
docs from pages corresponding to an input url list (one url per line,
urls that do not end in -- case-insensitive -- pdf or doc are ignored)
and it formats their contents as text.

The script is a wrapper around pdftotext and antiword, so those two
programs must be installed, to process pdf and "doc", respectively.

In the output, the textified contents of each document are preceded by the
line:

CURRENT URL url

(where url, of course, is the corresponding url).

Usage:

retrieve_and_process_non_html.pl -h | more

retrieve_and_process_non_html.pl -p url_list > pdf_only.txt

retrieve_and_process_non_html.pl -d url_list > doc_only.txt

retrieve_and_process_non_html.pl -pd url_list > both.txt

retrieve_and_process_non_html.pl -m 20000  -pd url_list > shortened.txt

retrieve_and_process_non_html.pl -m 20000 -g frequent_words 
                                         -p -d url_list > filtered.txt

retrieve_and_process_non_html.pl -m 20000 -g frequent_words -k 10/30/0.25
                                         -pd url_list > filtered.txt

...

Notice that if neither -p nor -d are specified, the default is that
nothing will be printed.

Option -m will keep only the first N characters (e.g., -m 20000 will
keep only the first 20000 characters) of documents longer than N
characters.

Option -g can be used to pass a list of frequent words -- any document
that does not have a minimum number of types and tokens from this
list, and a minimum ratio of tokens from the list to total token
count, will be discarded (useful as a language filter and to avoid
"junk" documents).

By default, the minmum type, token and ratio thresholds are 10, 30 and
0.25 respectively (or 0, 0 and 0 if no word list is passed). The
defaults can be modified by passing three slash-separated values with
the option -k (min type/min tok/min ratio).

Copyright 2005, Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_

my $browser;

my %opts = ();
getopts('hpdm:k:g:',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}

# read type/token minima of required good words
# initialized to default values

my $mingoodtypes = 10;
my $mingoodtokens = 30;
my $mingoodratio = 0.25;

# if user specified type/token minima but no good word list,
# something is wrong

if ($opts{k} && !($opts{g})){
    die "if you specify good word thresholds, you should also have a good word list";
}

if ($opts{k}) {
    ($mingoodtypes,$mingoodtokens,$mingoodratio) = split "/",$opts{k};
}

my %good = ();

if ($opts{g}) {
    open GOODWORDS,$opts{g} or die "could not find good word file $opts{g}";
    while (<GOODWORDS>) {
	chomp;
	$good{$_} = 1;
    }
    close GOODWORDS;
}
else { # required minima should be set to 0;
    $mingoodtypes = 0;
    $mingoodtokens = 0;
    $mingoodratio = 0;
}


while (<>) {

    chomp;

    my $url = $_;

    if (!/^https?:\/\/.*\.(pdf|doc)\/?/i) {
	next;
    }
    my $is_pdf = 0;;
    if ($1 =~ /^[pP]/) {
	$is_pdf = 1; # at this point, 0 means doc
    }
    if ( ( (!$opts{p}) && $is_pdf ) || ( (!$opts{d}) && (!$is_pdf) ) ) {
	next;
    }

    my $contents = "";
    my $parsedcontents = "";

    if ($contents = do_GET($_)) {

	my ($temphandle,$tempfile) = tempfile(UNLINK => 1);
	
	$| = 1;

	print $temphandle $contents;

	if ( ($is_pdf && ($parsedcontents = `pdftotext -nopgbrk $tempfile -`))
	     ||
	     ((!$is_pdf) && ($parsedcontents = `antiword $tempfile`))) {

	    if ($opts{m}) {
		chomp $parsedcontents;
		$parsedcontents = substr($parsedcontents,0,$opts{m});
		$parsedcontents .= "\n";
	    }

	    $parsedcontents = utf8_to_latin1($parsedcontents);
	    $parsedcontents = nice_string($parsedcontents);

	    # replace sequences of any kind of space symbol
	    # with a single space
	    $parsedcontents =~ s/[\r\n \t]+/ /gs;
	    # just in case, this includes also entity #10;
	    $parsedcontents =~ s/\&\#0?10;/ /gs;
    	    # ... and evil mysterious space
	    $parsedcontents =~ s/\xa0/ /g;
	    # substitute evil ms apostrophes
	    $parsedcontents =~ s/\x92/\x27/gs;
	    # add newline at end
	    $parsedcontents =~ s/ ?$/\n/;

	    if (!filter_out($parsedcontents)) {
		print "CURRENT URL $_\n";
		print $parsedcontents;
	    }
	}
	close $temphandle;
    } 
}

sub do_GET {
    # this is taken from the perl & lwp book (but I changed it a bit)

    my $browser = LWP::UserAgent->new() unless $browser;
    $browser->timeout(10);
    $browser->env_proxy();
    
    my $response;

    # I've put the following in an eval block to try to survive
    # failed ntlm authentications... let's hope it doesn't
    # cause other kinds of trouble...

    eval {$response = $browser->get(@_);};

    if ($@) {
	print STDERR "something went wrong: $@\n";
	return;
    }
    
    return unless $response->is_success;

    return $response->content;
}

# this function to convert from utf8 to latin1
# was written by John Matiasek of OeFAI
sub utf8_to_latin1 { 
  my $data = shift;
  return ''  if ref($data);
  $data = pack("a*",$data);	# utf-8 characters -> bytes
  $data =~ s/([\xC0-\xDF])([\x80-\xBF])/chr(ord($1)<<6&0xC0|ord($2)&0x3F)/egx;
  return $data;
}

# strip off wide chars
# from the perl unicode documentation
sub nice_string {
    join("",
         map { $_ > 255 ?                  # if wide character...
		   sprintf("\\x{%04X}", $_) :  # \x{...}
		   chr($_) =~ /[[:cntrl:]]/ ?  # else if control character ...
		   sprintf("\n",$_) :
#		   sprintf("\\x%02X", $_) :    # \x..
		   chr($_)                     # else as themselves
	       } unpack("U*", $_[0]));           # unpack Unicode characters
}


# check that a page has the required min number of good
# tokens

sub filter_out {
    my $page = shift;
    chomp $page;
    my @tokens = split "[ \t_]+",$page;
    my @goodtypes = ();
    my $goodtokens = 0;
    my %seentypes = ();

    # if the page has 5 tokens or less, there is no point in keeping it
    if (scalar(@tokens) <= 5) {
	return 1;
    }

    foreach my $token (@tokens) {
	$token =~ s/[\.\,\!\)\]\}\:\;\?\>\'\"]+$//;
	$token =~ s/^[\[\(\<\{\'\"\xbf\xa1]+//;
	
	if($good{latin1_lc($token)}) {
	    $goodtokens++;
	    push @goodtypes,$token
		unless $seentypes{$token}++;
	}
    }
    
    if (($goodtokens >= $mingoodtokens)&&(scalar(@goodtypes) >= $mingoodtypes) && (($goodtokens/scalar(@tokens))>=$mingoodratio)) {
	return 0;
    }

    return 1;

    return \@tokens;

}


sub latin1_lc {
    
    return join '', map {
        if ( ( (ord($_) > 64) && (ord($_) < 91) ) ||
             ( (ord($_) > 192) && (ord($_) < 215) ) ||                         
	     ( (ord($_) > 215) && (ord($_) < 223) ) ) {
            sprintf "%c",(ord($_)+32);                                         
	}                                                                   
        else {                                                                 
	    sprintf "%s",$_;                                                   
	}
    }	    
    split '',shift;                                                       
}

