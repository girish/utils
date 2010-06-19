#!/usr/bin/perl

# to see the documentation, type:
# perldoc retrieve_and_clean_pages_from_url_list.pl

use strict;
use warnings;

# PotaModule must be in path!
use PotaModule;

use Getopt::Std;

use LWP;

my $usage = <<"_USAGE_"; 

This script downloads all the html docs in pages corresponding to an
input url list, and it formats their contents as text, applying
various filters.

To see documentation and usage, type:

perldoc retrieve_and_clean_pages_from_url_list.pl

Copyright 2005, Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_

my %opts = ();
getopts('hg:k:b:f:m:',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}

# read type/token maxima of acceptable bad words
# initialized to default values

my $maxbadtypes = 3;
my $maxbadtokens = 10;

# if user specified type/token maxima but no bad word list,
# something is wrong

if ($opts{f} && !($opts{b})){
    die "if you specify bad word thresholds, you should also have a bad word list";
}

if ($opts{f}) {
    ($maxbadtypes,$maxbadtokens) = split "/",$opts{f};
}

my %bad = ();

if ($opts{b}) {
    open BADWORDS,$opts{b} or die "could not find bad word file $opts{b}";
    while (<BADWORDS>) {
	chomp;
	$bad{$_} = 1;
    }
    close BADWORDS;
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

# maximum/minimum size of doc before processing
# defaults to 5Kb/200Kb
# (or equivalent char numbers in "character semantics")

my $minbytesize = 5119;
my $maxbytesize = 204801;

if ($opts{m}) {
    ($minbytesize,$maxbytesize) = split "/",$opts{m};
}


my $browser;
my $html_text;

while (<>) {

    if ($_ !~/^http/) {
	next;
    }

    my ($url) = $_;
    chomp $url;
    # Tom Emerson's "focusing on HTML" regexp, with small additions
    if ($url !~/\.((a)|(ai)|(aif)|(aifc)|(aiff)|(asc)|(avi)|(bcpio)|(bin)|(bmp)|(bz2)|(c)|(cdf)|(cgi)|(cgm)|(class)|(cpio)|(cpp?)|(cpt)|(csh)|(css)|(cxx)|(dcr)|(dif)|(dir)|(djv)|(djvu)|(dll)|(dmg)|(dms)|(doc)|(dtd)|(dv)|(dvi)|(dxr)|(eps)|(etx)|(exe)|(ez)|(gif)|(gram)|(grxml)|(gtar)|(gz)|(h)|(hdf)|(hqx)|(ice)|(ico)|(ics)|(ief)|(ifb)|(iges)|(igs)|(iso)|(jnlp)|(jp2)|(jpe)|(jpeg)|(jpg)|(js)|(kar)|(latex)|(lha)|(lzh)|(m3u)|(mac)|(man)|(mathml)|(me)|(mesh)|(mid)|(midi)|(mif)|(mov)|(movie)|(mp2)|(mp3)|(mp4)|(mpe)|(mpeg)|(mpg)|(mpga)|(ms)|(msh)|(mxu)|(nc)|(o)|(oda)|(ogg)|(pbm)|(pct)|(pdb)|(pdf)|(pgm)|(pgn)|(pic)|(pict)|(pl)|(png)|(pnm)|(pnt)|(pntg)|(ppm)|(ppt)|(ps)|(py)|(qt)|(qti)|(qtif)|(ra)|(ram)|(ras)|(rdf)|(rgb)|(rm)|(roff)|(rpm)|(rtf)|(rtx)|(s)|(sgm)|(sgml)|(sh)|(shar)|(silo)|(sit)|(skd)|(skm)|(skp)|(skt)|(smi)|(smil)|(snd)|(so)|(spl)|(src)|(srpm)|(sv4cpio)|(sv4crc)|(svg)|(swf)|(t)|(tar)|(tcl)|(tex)|(texi)|(texinfo)|(tgz)|(tif)|(tiff)|(tr)|(tsv)|(txt)|(ustar)|(vcd)|(vrml)|(vxml)|(wav)|(wbmp)|(wbxml)|(wml)|(wmlc)|(wmls)|(wmlsc)|(wrl)|(xbm)|(xht)|(xhtml)|(xls)|(xml)|(xpm)|(xsl)|(xslt)|(xwd)|(xyz)|(z)|(zip))$/i){
   
	if ($html_text = do_GET($url)) {

	    my $potaref = dig_content($html_text,\%bad,
				      $maxbadtypes,$maxbadtokens,
				      \%good,$mingoodtypes,
				      $mingoodtokens,$mingoodratio,
				      $minbytesize,$maxbytesize);

	    
	    # if we did get something back from the cleaning process,
	    # let's print it
	    if (${$potaref}[0]) {
		print "CURRENT URL $url\n";
		print ${$potaref}[0],"\n";
	    }
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

I<retrieve_and_clean_pages_from_url_list.pl>: a simple script that
downloads html pages corresponding to an input list and extracts text
from them, applying various filters.

=head1 SYNOPSIS

retrieve_and_clean_pages_from_url_list.pl url_list > corpus.txt

retrieve_and_clean_pages_from_url_list.pl -b stop_words -g keep_words 
                                          url_list > corpus.txt

retrieve_and_clean_pages_from_url_list.pl -b stop_words -f 3/10 \
                                  -g keep_words -k "10/30/0.25" \
                                                -m  5119/204801 \
                                          url_list > corpus.txt

=head1 DESCRIPTION

This script downloads all the html in the pages corresponding to an
input url list, and it extracts their contents as text, applying a
heuristic method to look for the "content-rich" section of a page, and
removing the rest. Moreover, various filters can be applied, and the
pages that do not satisfy them are not printed to output.

The input list must have one url per line. Lines that do not begin
with http are ignored. Urls with non-html suffixes (doc, jpg, pdf,
etc.) are also ignored (I use a regular expression written by Tom
Emerson for this task).

For the remaining urls, the script downloads the corresponding page
and applies the filters. If the page passes the filters, the script
prints a header line in format:

CURRENT URL current_url_string

and then the contents it extracted from the corresponding page.

The module assumes that the input is in latin1, or utf8 representing
latin1 (that is converted to latin1).

For details about the boilerplate stripping heuristic, take a look at
the documentation of the PotaModule (which you must have installed in
order to use this script):

perldoc PotaModule

=head2 ARGUMENT AND OPTIONS

The only argument to the script is a file with a list of urls, one per line.

The options are:

B<-h>: Prints short info about the script and quits.

B<-b filename>: A list of "bad" words (e.g., pornographic terms). If a
document contains more than a certain number of types or tokens from
this list, it will not be printed (see option B<-f> for default
thresholds and how to change them).

B<-f type_N/token_N>: Two slash-separated values that specify,
respectively, the number of types and tokens from the "bad" word list
sufficient to cause a document to be discarded. Default thresholds are
3 types and 10 tokens. Of course, this option can only be specified if
a bad word list is also passed.

B<-g filename>: A list of "good" words (e.g., function words). A
document is printed only if it contains a certain number of types and
tokens from this list, and if the ratio of tokens from the list to
total tokens is above a certain threshold (see option B<-k> for
default thresholds and how to change them).

B<-k type_N/token_N/ratio>: Three slash-separated values that specify,
respectively, the minimum number of types and tokens from the "good"
word list that a document must contain to be printed, and the minimum
ratio of tokens from the list to total tokens in the document that a
document must have to be printed. Default thresholds are 10 types, 30
tokens and a ratio of 0.25 (or 0, 0 and 0 if no "good" word list is
specified). Of course, the option can only be used if a good word list
is also passed.

B<-m min_size/max_size>: Two slash-separated values specifying the
minimum and maximum allowed sizes (in characters) for documents to be
printed. Default values are 5119 and 204801, respectively, which, in
single-byte encodings, means 5KB and 2000KB, respectively.

=head1 DEPENDENCIES

You need to have the following modules installed:

LWP

PotaModule

=head1 AUTHOR

Marco Baroni, baroni AT sslmit.unibo.it

=head1 ACKNOWLEDGMENTS

Thanks to Eros Zanchetta for help, advice and testing and to Tom
Emerson for the regular expression to filter out non-html.

=head1 BUGS

Probably many: if you find one, please let me know: baroni AT sslmit
unibo it

=head1 COPYRIGHT

Copyright 2005, Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

=head1 SEE ALSO

The PotaModule and other software from the WaCky project:

http://sslmitdev-online.sslmit.unibo.it/wac/wac.php

=cut
