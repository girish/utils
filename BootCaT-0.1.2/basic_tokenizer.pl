#!/usr/bin/perl

# THIS IS AN OLD TOKENIZER WE WROTE IN A HURRY!
# WE HOPE TO PROVIDE A BETTER ONE IN THE NEXT VERSION OF THE BOOTCAT
# TOOLKIT
# IN THE MEANTIME, YOU ARE PROBABLY BETTER OFF WRITING YOUR OWN!

# This primitive tokenizer returns the words in the input file one per
# line.

# The tokenizer accepts an article/text delimiter, if the corpus
# derives from the combination of various distinct articles. Lines
# containing the article delimiter will be printed out *as is* (no
# attempt at processing them -- for example, even if -i option is set,
# case of line containing article delimiter will not be affected).

# The -a option gets rid of all non-alphabetic characters (standard
# ascii set, plus Italian accented and German umlaut-ed vowels, and
# scharfes S), except in the delimiters.

# The -i option turns all letters to lower case (including
# Italian/German accented/umlaut-ed vowels), except any upper case
# letter in the delimiters.

# The -t (for iTalian) option treats an apostrophe btw. two adjacent
# alphabetic characters as part of the word that that preceding letter
# belongs to.

# The -e (for English) option treats an apostrophe btw. two adjacent
# alphabetic characters as part of a single word with those
# characters.

# Both -t and -e will override the -a option for apostrophes only
# (i.e., apostrophes in the specific contexts targeted by these
# options are kept).

# We need better latin1 handling and dash handling for cases like
# CD-ROM.

$usage = q!
------------------------------------------------------------------------
usage:
basic_tokenizer.pl [switches] input_corpus

switches -h: display this information and quit
         -i: turn all letters to lower case
         -a: discard non-alphabetic characters
         -t: handle apostrophes the Italian way
         -e: handle apostrophes the English way
         -s: input article delimiter
        
For more information, see header of basic_tokenizer.pl script.

NB:

THIS IS AN OLD TOKENIZER

WE HOPE TO PROVIDE A BETTER ONE IN THE NEXT VERSION OF THE BOOTCAT
TOOLKIT

IN THE MEANTIME, YOU ARE PROBABLY BETTER OFF WRITING YOUR OWN

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.
------------------------------------------------------------------------
!;

use Getopt::Std;
getopts('hiates:');

die "$usage" if $opt_h;

$case_insensitive = $opt_i;
$alpha_only = $opt_a;
$ital_apostrophe = $opt_t;
$eng_apostrophe = $opt_e;
$artbound = $opt_s;  # s for separator

die $usage if ($ital_apostrophe && $eng_apostrophe);

open CORPUS, shift @ARGV or die $usage;

while (<CORPUS>) {

  if ($artbound && (/$artbound/)) {
      print;
      next;
  }

  $currline = $_;
      
  # replace evil Italian apostrophe with '
  $currline =~ s/\x92/'/g;
  # chomp $currline;

  # remove all the mysterious stuff
  $currline =~ s/[^\!-\~àèéìòùÀÈÉÌÒÙäöüÄÖÜß\s\!-@]//g;
    
  # if option -i was set, set all chars to lower case

  if ($case_insensitive) {
      $currline = change_to_lower($currline);
  }

  # if option -a was passed, get rid of everything that is not
  # alphabetic

  if ($alpha_only) {
      if (!($ital_apostrophe) && !($eng_apostrophe)) {
	  $currline =~ s/[^a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß\s]//g;
      }
      else {
	  # we have to be more careful...
	  $currline =~ s/[^\'a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß\s]//g;
	  $currline =~ s/([^a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])\'/$1/g;
	  $currline =~ s/\'([^a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])/$1/g;
	  # being identical to treatment below, following could actually
	  # be merged in a single statement after -a-dependent if/else
	  if ($ital_apostrophe) {
	      $currline =~ s/\'([a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])/\' $1/g;
	  }
      }
  }
  # otherwise, simply separate alphabetic
  # characters from any non-alphabetic stuff they are attached to
  # but treat apostrophes specially, if either -t or -e are set
  if (!($ital_apostrophe) && !($eng_apostrophe)) {
      $currline =~ s/([^a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß\s])([a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])/$1 $2/g;
      $currline =~ s/([a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])([^a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß\s])/$1 $2/g;
  }
  else {
      $currline =~ s/([^\'a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß\s])([a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])/$1 $2/g;
      $currline =~ s/([a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])([^\'a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß\s])/$1 $2/g;
      $currline =~ s/([^a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])\'/$1 \'/g;
      $currline =~ s/\'([^a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])/\' $1/g;
      if ($ital_apostrophe) {
	  $currline =~ s/\'([a-zA-ZàèéìòùÀÈÉÌÒÙäöüÄÖÜß])/\' $1/g;
      }
  }
  
  # if line is empty move on
  if ($currline =~ /^\s*$/) {
      next;
  }
  
      
  # remove space at the beginning of line:
  $currline =~ s/^\s+//g;
      
  # now, translate all white space to \n
  $currline =~ s/\s+/\n/g;
  print "$currline";
}
close CORPUS;

sub change_to_lower {
    # perhaps, I should use codes instead...
    
    my $l = shift;
    
    $l =~ s/À/à/g;
    $l =~ s/È/è/g;
    $l =~ s/É/é/g;
    $l =~ s/Ì/ì/g;
    $l =~ s/Ò/ò/g;
    $l =~ s/Ù/ù/g;
    $l =~ s/Ä/ä/g;
    $l =~ s/Ö/ö/g;
    $l =~ s/Ü/ü/;
    
    $l = lc($l);
    
    return $l;
}
