#!/usr/bin/perl -w
use CWB::Encoder;

# For comments, usage, etc. do:
# tagwrapper -h

use Getopt::Std;

my $usage;
{
$usage = <<"_USAGE_";

This script uses Stefan Evert's CWB::Encoder module to CWB-index
corpora in the following simple CWB-compatible format:

<corpus>
<text id="...">
<s>
The DET the
dogs N dog
...
</s>
...
</text>
...
</corpus>

where the positional attributes are always arranged in the order: word
pos lemma (tab delimited).

Of course, the script requires CWB and the CWB::Encoder module to be
properly installed.

Usage:

cwbify_standard_corpus.pl -l langcode -d dir -c cwbname -n descname corpus
cwbify_standard_corpus.pl -h | more

-h: prints this information and quits

-l langcode: an ISO-style language code, such as en, de, it, etc.

-d dir: a directory where the indexed data will be stored -- the
    directory cannot exist already and it will be created by the
    script ; for the corpus to be available to others, you should
    specify an absolute path

-c cwbname: the CWB name for the corpus, short and upper-case

-n descname: a descriptive name made of a few words, in double quotes

corpus: the input corpus

Copyright 2005, Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}
{
    my $blah = 1;
# this useless block is here because here document confuses
# emacs
}

getopts('hl:d:c:n:',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}

if (!($langcode = $opts{l})) {
    die "specify language code!";
}
if (!($datadir = $opts{d})) {
    die "specify data directory!";
}
if (!($corpusname = $opts{c})) {
    die "specify CWB corpus name!";
}
if (!($longname = $opts{n})) {
    die "specify descriptive name!";
}

if (!($ifile = shift)) {
    die "specify input corpus!";
}

$corpus = new CWB::Encoder $corpusname;
$corpus->dir($datadir); # directory for corpus data files
$corpus->overwrite(0);         # may NOT overwrite existing files / directories
                               # this was changed from 1 to 0 after a few
                               # users overwrote their home directories...

$corpus->longname($longname);
$corpus->language($langcode);

$corpus->p_attributes("word"); # declare postional atts (no default!)
$corpus->p_attributes("pos"); # declare postional atts (no default!)
$corpus->p_attributes("lem"); # declare postional atts (no default!)

$corpus->s_attributes("corpus");
$corpus->s_attributes("s");
$corpus->s_attributes("text:0+id");

$corpus->memory(400);          # use up to 400 MB of RAM (default: 75)
$corpus->validate(0);          # disable validation for faster indexing
$corpus->verbose(1);           # print some progress information
$corpus->debug(1);             # enable debugging output
$corpus->encode($ifile);       # encoding, indexing, and compression
