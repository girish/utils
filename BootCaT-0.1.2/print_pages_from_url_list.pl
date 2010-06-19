#!/usr/bin/perl

# to see the documentation, type:
# perldoc print_pages_from_url_list.pl

use strict;
use warnings;

use Getopt::Std;

use LWP;
use HTML::TreeBuilder;
use HTML::FormatText;


my $usage = <<"_USAGE_";
Usage: 
 print_pages_from_url_list.pl url_list > pages_in_text_format
 
 This script downloads all the html in the pages corresponding to an
 input url list, and it formats their contents as text.
 
 The input list must have one url per line. Lines that do not begin
 with http are ignored.

 Urls with obviously non-html suffixes (doc, jpg, pdf, etc.)
 are also ignored.

 For the remaining urls, the script prints a header line in format:

 CURRENT_URL current_url_string

 and then the contents of the corresponding page as parsed by
 HTML::FormatText, plus some further reg-exp-based cleaning.

 This program is free software. You may copy or redistribute it under
 the same terms as Perl itself.

 For more information, please type:

 perldoc print_pages_from_url_list.pl
_USAGE_

my %opts = ();
getopts('h',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}

my $formatter = HTML::FormatText->new();
my $browser;
my $html_text;

while (<>) {

    if ($_ !~/^http/) {
	next;
    }

    my ($url) = $_;
    chomp $url;
    if ($url !~/\.(ps)|(gz)|(pdf)|(gif)|(jpg)|(jpeg)|(doc)|(xls)|(ppt)|(rtf)$/i) {
	if ($html_text = do_GET($url)) {
	    my $tree = HTML::TreeBuilder->new_from_content($html_text);
	    my $text = $formatter->format($tree);
	    if ($text =~/[a-zA-Z]/) {
		print "CURRENT URL $url\n";
		# the following is a little bit radical, but overall 
		# it should help getting rid of a lot of junk
		$text =~ s/\[[^\[]*\]//g;
		$text =~ s/\s*[\n\r]/\n/g;
		$text =~ s/[ \t\r]+/ /g;
		$text =~ s/\n /\n/g;
		print "$text\n";
	    }
	    $tree = $tree->delete;
	}
    }
}

sub do_GET {
    # this is taken from the perl & lwp book (but I changed it a bit)

    $browser = LWP::UserAgent->new() unless $browser;
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

=head1 NAME

B<print_pages_from_url_list.pl>: for each url in input list, print corresponding page in text format.

=head1 SYNOPSIS

print_pages_from_url_list.pl url_list > pages_in_text_format

=head1 DESCRIPTION

This script downloads all the html in the pages corresponding to an
input url list, and it formats their contents as text.

It is meant to be used in conjunction with
collect_urls_from_google.pl: you can use the output of that script as
input to this one, in a procedure to create a web-based corpus.

The input list must have one url per line. Lines that do not begin
with http are ignored.

Urls with obviously non-html suffixes (doc, jpg, pdf, etc.)
are also ignored.

For the remaining urls, the script prints a header line in format:

CURRENT_URL current_url_string

and then the contents of the corresponding page as parsed by
HTML::FormatText, plus some further reg-exp-based cleaning.

The script does not skip repeated urls. Thus, to avoid doubles, you
should do a sort-uniq on the output of collect_urls_from_google.pl.

=head1 DEPENDENCIES

You need to have the following modules installed:

LWP

HTML::TreeBuilder

HTML::FormatText

If you get an error message about the script not finding one of these
in @INC, you or your administrator should install the missing module(s).

If you are lucky, the following will be enough:

sudo perl -MCPAN -e shell

cpan> install NAME_OF_MISSING_MODULE

=head1 AUTHOR

Marco Baroni, baroni AT sslmit.unibo.it

=head1 BUGS

Probably many: if you find one, please let me know: baroni
AT sslmit unibo it

=head1 COPYRIGHT

Copyright 2003, Marco Baroni

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=head1 SEE ALSO

LWP

HTML::TreeBuilder

HTML::FormatText

collect_urls_from_google.pl

=cut
