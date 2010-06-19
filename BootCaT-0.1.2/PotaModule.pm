package PotaModule;
use strict;
use vars qw(@ISA @EXPORT);
use Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(&dig_content);


use strict;

# for documentation, type:
# perldoc PotaModule.pm

# this is the only function exported by this module
# it returns an array reference where the first
# element of the array is the string corresponding to the 
# cleaned text from the analyzed doc (possibly, an empty string)
# and the "score" that such cleaned text obtained from
# Finn's BTE heuristic
# $array_ref = dig_content($html_text,\%bad_words,
#                            $max_bad_types, $max_bad_tokens,
#                            \%good_words, $min_good_types,
#                            $min_good_tokens, $min_good_ratio,
#                            $min_size, $max_size);

sub dig_content {
    # a string with the contents of the document
    # could be null string
    my $text = shift;
    # reference to hash of stop words, mapping them to some
    # non 0 value
    # could be empty
    my $badref = shift;
    # max thresholds for stop words
    my $maxbadtypes = shift;
    my $maxbadtokens = shift;
    # reference to hash of common words, mapping them to some
    # non 0 value
    # could be empty
    my $goodref = shift;
    # min thresdholds for common words
    my $mingoodtypes = shift;
    my $mingoodtokens = shift;
    my $mingoodratio = shift;
    # min and max number of bytes, or rather caracters, of doc before
    # processing it
    my $mincharactersize = shift;
    my $maxcharactersize = shift;

    # if empty string, return empty string
    if (!($text)) {
	return ["",0];
    }

    # if too long or too short, return empty string
    if ((length($text)<$mincharactersize)||(length($text)>$maxcharactersize)) {
	return ["",0];
    }

# remove junk, from BTE, plus striping off of whide chars
    $text = remove_crap($text);
# replace tags with XTAGX
    $text = identify_tags($text);
# tokenize
    my $tokensref = tokenize($text);
# look for longest low tag density stretch
    my $maxboundariesref = look_for_text_stretch($tokensref);
# if what is left in doc satisfies min/max good/bad word constraints, return
# string corresponding to max stretch, and info about score of corresponding
# stretch
    my $cleaned_string = join (" ", (grep {$_ ne "XTAGX"} @{$tokensref}[${$maxboundariesref}[0]..${$maxboundariesref}[1]]));

    if (check_page($cleaned_string,$badref,$maxbadtypes,$maxbadtokens,$goodref,$mingoodtypes,$mingoodtokens,$mingoodratio)) {
	return [$cleaned_string,${$maxboundariesref}[2]];
    }
    # else, return an empty string and 0 as the score
    return ["",0];

}

# from BTE
sub remove_crap{
    my $data = shift;

# we are not interested in anything up to <body
    $data =~ s/.*<body/<body/is;

#############################
# get rid of comments       #
#############################
    $data =~ s{ <!                   # comments begin with a `<!'
		    # followed by 0 or more comments;
		    
    (.*?)		# this is actually to eat up comments in non 
			# random places

     (                  # not suppose to have any white space here

                        # just a quick start; 
      --                # each comment starts with a `--'
        .*?             # and includes all text up to and including
      --                # the *next* occurrence of `--'
        \s*             # and may have trailing while space
                        #   (albeit not leading white space XXX)
     )+                 # repetire ad libitum  XXX should be * not +
    (.*?)		# trailing non comment text
   >                    # up to a `>'
}{
    if ($1 || $3) {	# this silliness for embedded comments in tags
	"<!$1 $3>";
    } 
}gesx;                 # mutate into nada, nothing, and niente


# .. and scripts
$data =~ s#<script.*?/script>#<script></script>#gsi;

# converting to latin 1 if utf 8

    $data = utf8_to_latin1($data);

# stripping off wide chars

    return nice_string($data);

}

# from BTE
sub identify_tags{
###############################
# identify the remaining tags #
###############################
    my $data = shift;


# we brutally add period before unambiguous block elements
#    $data =~ s/([^\!\_\-\:\;\,\.\?])\s*<(ADDRESS|BLOCKQUOTE|BR|CENTER|DIR|DIV|DL|FIELDSET|FORM|H1|H2|H3|H4|H5|H6|HR|ISINDEX|MENU|NOFRAMES|NOSCRIPT|OL|P|PRE|TABLE|UL|DD|DT|FRAMESET|LI|TBODY|TD|TFOOT|TH|THEAD|TR)( |>)/$1. <$2$3/gis;
    

    # following expression is greatly simplified and it will probably
    # miss something, but hopefully it will
    # protect us from the segmentation faults caused by original expression

    $data =~ s/<[^>]+>/ XTAGX /gs;

#    $data =~ s{ <                 # opening angle bracket
#
#		    (?:           # Non-backreffing grouping paren
#		     [^>\'\"] *   # 0 or more things that are neither
#		                  # > nor ' nor "
#		     |            #    or else
#		     \".*?\"      # a section between double quotes
#		                  # (stingy match)
#		     |            #    or else
#		     \'.*?\'      # a section between single quotes 
#		                  # (stingy match)
#		     ) +          # repetire ad libitum
#		                  #  hm.... are null tags <> legal? XXX
#		     >            # closing angle bracket
#		 }{ XTAGX }gsx;     # mutate into nada, nothing, and niente

    return $data;

}

sub tokenize{

    my $data = shift;

    chomp $data;
    	
    # replace sequences of any kind of space symbol
    # with a single space
    $data =~ s/[\r\n \t]+/ /gs;
    # just in case, this includes also entity #10;
    $data =~ s/\&\#0?10;/ /gs;

    # substitute evil ms apostrophes
    $data =~ s/\x92/\x27/gs;
    
    # ... and evil mysterious space
    $data =~ s/\xa0/ /g;

    # resolve entities
    $data = translate_html_entities($data);

    # sequences of punctuation marks immediately preceding spaces
    # (or end of line) are likely to be true punctuation marks, split them
    # from token that precedes
    # XXX [this should actually be language specific!] XXX
 #   $data =~ s/([\.\,\!\)\]\}\:\;\?\>\'\"]+)($|[\s]+)/ $1 /gs;
    
    # and the same goes for some word-initial non-alphanumeric symbols
 #   $data =~ s/(^|[\s]+)([\[\(\<\{\'\"\xbf\xa1]+)/ $1 /g;
    
    # also, if there is more than one - it's probably some kind of
    # boundary marker
 #   $data =~ s/\-\-+/ - /g;
    
    # ok, now besides dashes, apostrophes and slashes we should
    # have only internal non-alhpanumericals left 
    # let's tokenize

    my @tokens = grep {/[\S]/} (split "[ ]+",$data);
    return \@tokens;

}

sub look_for_text_stretch{

    my $tokensref =shift;

    my $tok_count = scalar(@{$tokensref});

    my $i = 0;
    my $prev_t = 0;
    my $tag;
    my @chunk_values = ();
    my @chunk_indices = ();
    my $prev_i;
    my $curr_value;

    while ($i < $tok_count) {
	if (${$tokensref}[$i] eq "XTAGX") {
	    $tag = 1-2;
	}
	else {
	    $tag = 1;
	}

	if ($tag != $prev_t) {
	    
	    if ($prev_t) {
		push @chunk_values,$curr_value;
		push @chunk_indices,$prev_i;
	    }
	    $prev_i = $i;
	    $curr_value = 0;
	    $prev_t = $tag;
	}

	$curr_value += $tag;

	$i++;
    }

    push @chunk_values,$curr_value;
    push @chunk_indices,$prev_i;
    
    my $chunk_count = scalar(@chunk_indices);

    my $max_score = 0;
    my $max_begin = 0;
    my $max_end = 0;


    $i = 0;
    my $score;
    while ($i<($chunk_count-1)) {
	
	$score = $chunk_values[$i];
	# if score negative, there is no point in beginning from here
	if ($score < 0) {
	    $i++;
	    next;
	}

	# else, check that this is not already a maximum 
	if ($score>$max_score){
	    $max_score = $score;
	    $max_begin = $i;
	    $max_end = $i;
	}


	my $j= $i+1;
	while ($j<$chunk_count) {
	    
	    $score += $chunk_values[$j];

	    if ($score>$max_score){

#		# debug
#		print STDERR "this was a maximum\n";

		$max_score = $score;
		$max_begin = $i;
		$max_end = $j;
	    }

	    $j++;
	}

	$i++;
    }

    my $begin = $chunk_indices[$max_begin];
    # notice: final chunk _must_ be positive
    my $end = $chunk_indices[$max_end] + $chunk_values[$max_end] - 1;

    return [$begin,$end,$max_score];
}

# check that a page has the required min/max numbers of good/bad
# tokens

sub check_page {
    my $page = shift;
    # hash with bad words
    my $badref = shift;
    # max thresholds for bad words
    my $maxbadtypes = shift;
    my $maxbadtokens = shift;
    # reference to hash of common words
    my $goodref = shift;
    # min thresdholds for common words
    my $mingoodtypes = shift;
    my $mingoodtokens = shift;
    my $mingoodratio = shift;

    chomp $page;
    my @tokens = split "[ \t_]+",$page;
    my @badtypes = ();
    my $badtokens = 0;
    my @goodtypes = ();
    my $goodtokens = 0;
    my %seentypes = ();

    # if the page has 5 tokens or less, there is no point in keeping it
    if (scalar(@tokens) <= 5) {
#	if ($opts{v}) {
#	    print STDERR "page: $prev_url\n";
#	    print STDERR "page is way too short\n";
#	}
	return 0;
    }

    foreach my $token (@tokens) {
	$token =~ s/[\.\,\!\)\]\}\:\;\?\>\'\"]+$//;
	$token =~ s/^[\[\(\<\{\'\"\xbf\xa1]+//;
	if(${$badref}{latin1_lc($token)}) {
	    $badtokens++;
	    push @badtypes,$token
		unless $seentypes{$token}++;

	    if (($badtokens >= $maxbadtokens)&&(scalar(@badtypes) >= $maxbadtypes)) {
	#	if ($opts{v}) {
	#	    print STDERR "page: $prev_url\n";
	#	    print STDERR "page has too many bad words\n";
#		    print STDERR join " ",@badtypes;
#		    print STDERR "\n";
	#    }
		return 0;
	    }
	}
	
	elsif(${$goodref}{latin1_lc($token)}) {
	    $goodtokens++;
	    push @goodtypes,$token
		unless $seentypes{$token}++;
	}
    }

    if (($goodtokens >= $mingoodtokens)&&(scalar(@goodtypes) >= $mingoodtypes) && (($goodtokens/scalar(@tokens))>=$mingoodratio)) {
	return 1;
    }
#    if ($opts{v}) {
#	print STDERR "page: $prev_url\n";
#	print STDERR "page has not enough good words\n";
#	print STDERR "good tokens: $goodtokens; good types: ",scalar(@goodtypes)," good-to-token ratio: ",$goodtokens/scalar(@tokens),"\n";
#    }
    return 0;
}


sub latin1_lc {
    
    return join '', map {
        if ( ( (ord($_) > 64) && (ord($_) < 91) ) ||
             ( (ord($_) > 191) && (ord($_) < 215) ) ||                         
	     ( (ord($_) > 215) && (ord($_) < 223) ) ) {
            sprintf "%c",(ord($_)+32);                                         
	}                                                                   
        else {                                                                 
	    sprintf "%s",$_;                                                   
	}
    }	    
    split '',shift;                                                       
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


# from bte
sub translate_html_entities{
######################################
# translate html entities to text   #
#####################################
    my $data = shift;

    my %entity = (

        lt     => '<',     #a less-than
        gt     => '>',     #a greater-than
        amp    => '&',     #a nampersand
        quot   => '"',     #a (verticle) double-quote

#        nbsp   => chr 160, #no-break space
	nbsp   => ' ',
        \#x25BC => ' ', # mysterious thing that looks like spacing thingie
	\#x2019 => chr 39 # more weirdness from itWaC

	rsquo  => chr 39,  #replace with '
	lsquo  => chr 39,  #replace with '
	rdquo  => chr 34,  #replace with "
	ldquo  => chr 34,  #replace with "

        iexcl  => chr 161, #inverted exclamation mark
        cent   => chr 162, #cent sign
        pound  => chr 163, #pound sterling sign CURRENCY NOT WEIGHT
        curren => chr 164, #general currency sign
        yen    => chr 165, #yen sign
	euro   => 'E',     # euro->E, obviously a hack
	bull   => '-',     # bullet->-, obviously another hack
	ndash  => '--',    # and the hack keep coming...
	mdash  => '--',    # idem
        hellip => '...',   # hellipsis
        brvbar => chr 166, #broken (vertical) bar
        sect   => chr 167, #section sign
        uml    => chr 168, #umlaut (dieresis)
        copy   => chr 169, #copyright sign
        ordf   => chr 170, #ordinal indicator, feminine
        laquo  => chr 171, #angle quotation mark, left
        not    => chr 172, #not sign
        shy    => chr 173, #soft hyphen
        reg    => chr 174, #registered sign
        macr   => chr 175, #macron
        deg    => chr 176, #degree sign
        plusmn => chr 177, #plus-or-minus sign
        sup2   => chr 178, #superscript two
        sup3   => chr 179, #superscript three
        acute  => chr 180, #acute accent
        micro  => chr 181, #micro sign
        para   => chr 182, #pilcrow (paragraph sign)
        middot => chr 183, #middle dot
        cedil  => chr 184, #cedilla
        sup1   => chr 185, #superscript one
        ordm   => chr 186, #ordinal indicator, masculine
        raquo  => chr 187, #angle quotation mark, right
        frac14 => chr 188, #fraction one-quarter
        frac12 => chr 189, #fraction one-half
        frac34 => chr 190, #fraction three-quarters
        iquest => chr 191, #inverted question mark
        Agrave => chr 192, #capital A, grave accent
        Aacute => chr 193, #capital A, acute accent
        Acirc  => chr 194, #capital A, circumflex accent
        Atilde => chr 195, #capital A, tilde
        Auml   => chr 196, #capital A, dieresis or umlaut mark
        Aring  => chr 197, #capital A, ring
        AElig  => chr 198, #capital AE diphthong (ligature)
        Ccedil => chr 199, #capital C, cedilla
        Egrave => chr 200, #capital E, grave accent
        Eacute => chr 201, #capital E, acute accent
        Ecirc  => chr 202, #capital E, circumflex accent
        Euml   => chr 203, #capital E, dieresis or umlaut mark
        Igrave => chr 204, #capital I, grave accent
        Iacute => chr 205, #capital I, acute accent
        Icirc  => chr 206, #capital I, circumflex accent
        Iuml   => chr 207, #capital I, dieresis or umlaut mark
        ETH    => chr 208, #capital Eth, Icelandic
        Ntilde => chr 209, #capital N, tilde
        Ograve => chr 210, #capital O, grave accent
        Oacute => chr 211, #capital O, acute accent
        Ocirc  => chr 212, #capital O, circumflex accent
        Otilde => chr 213, #capital O, tilde
        Ouml   => chr 214, #capital O, dieresis or umlaut mark
        times  => chr 215, #multiply sign
        Oslash => chr 216, #capital O, slash
        Ugrave => chr 217, #capital U, grave accent
        Uacute => chr 218, #capital U, acute accent
        Ucirc  => chr 219, #capital U, circumflex accent
        Uuml   => chr 220, #capital U, dieresis or umlaut mark
        Yacute => chr 221, #capital Y, acute accent
        THORN  => chr 222, #capital THORN, Icelandic
        szlig  => chr 223, #small sharp s, German (sz ligature)
        agrave => chr 224, #small a, grave accent
	\#xE0  => chr 224, # itWaC weirdness
        aacute => chr 225, #small a, acute accent
        acirc  => chr 226, #small a, circumflex accent
        atilde => chr 227, #small a, tilde
        auml   => chr 228, #small a, dieresis or umlaut mark
        aring  => chr 229, #small a, ring
        aelig  => chr 230, #small ae diphthong (ligature)
        ccedil => chr 231, #small c, cedilla
        egrave => chr 232, #small e, grave accent
        eacute => chr 233, #small e, acute accent
        ecirc  => chr 234, #small e, circumflex accent
        euml   => chr 235, #small e, dieresis or umlaut mark
        igrave => chr 236, #small i, grave accent
        iacute => chr 237, #small i, acute accent
        icirc  => chr 238, #small i, circumflex accent
        iuml   => chr 239, #small i, dieresis or umlaut mark
        eth    => chr 240, #small eth, Icelandic
        ntilde => chr 241, #small n, tilde
        ograve => chr 242, #small o, grave accent
        oacute => chr 243, #small o, acute accent
        ocirc  => chr 244, #small o, circumflex accent
        otilde => chr 245, #small o, tilde
        ouml   => chr 246, #small o, dieresis or umlaut mark
        divide => chr 247, #divide sign
        oslash => chr 248, #small o, slash
        ugrave => chr 249, #small u, grave accent
        uacute => chr 250, #small u, acute accent
        ucirc  => chr 251, #small u, circumflex accent
        uuml   => chr 252, #small u, dieresis or umlaut mark
        yacute => chr 253, #small y, acute accent
        thorn  => chr 254, #small thorn, Icelandic
        yuml   => chr 255, #small y, dieresis or umlaut mark

    );
    ####################################################
    # now fill in all the numbers to match themselves
    ####################################################
    my $chr;
    for $chr ( 0 .. 255 ) { 
        $entity{ '#' . $chr } = chr $chr;
    }

    # but not #039;, which stands for the accent in some pages!
    $entity{'#039'} = "'";
    # other number based entities that we recognize and convert to some
    # latin1 characters (sometimes, losing information, e.g., from
    # left double quotes to straight double quotes)
    $entity{'#8220'} = "\"";	#	left double quot mark
    $entity{'#8211'} = "-";	#	en dash
    $entity{'#8221'} = "\"";	#	right double quot mark
    $entity{'#8230'} = "...";	#	ellipsis
    $entity{'#8222'} = ",,";	#	double low-9 quot mark
                                #       (,, not a good idea for standard
                                #       tokenizers)
    $entity{'#8364'} = "E";	#	euro sign
    $entity{'#8217'} = "'";	#	right single quot mark
    $entity{'#8212'} = "--";	#	em dash
    $entity{'#036'} = "\$";	#	dollar sign (???)
    $entity{'#8226'} = "-";	# bullet
    $entity{'#064'} = "\@";	#	at sign
    $entity{'#092'} = "\\";	#	\
#    $entity{'#9604'} = "";	#	??
    $entity{'#945'} = "alpha";	#	greek alpha
#    $entity{'#8209'} = "";	#	??
    $entity{'#8216'} = "'";	#	left single quotation mark
#    $entity{'#9472'} = "";	#	??
#    $entity{'#65533'} = "";	#	??
    $entity{'#034'} = "\"";	#	quotation mark
    $entity{'#949'} = "epsilon";	#	epsilon
#    $entity{'#383'} = "";	#	??
    $entity{'#953'} = "iota";	#	iota
#    $entity{'#269'} = "";	#	??
    $entity{'#959'} = "omicron";	#	omicron
    $entity{'#957'} = "nu";	#	nu
    $entity{'#956'} = "mu";	#	mu
    $entity{'#060'} = "<";	#	less than
    $entity{'#091'} = "[";	#	[
    $entity{'#093'} = "]";	#	]
    $entity{'#960'} = "pi";	#	pi
    $entity{'#961'} = "rho";	#	rho
    $entity{'#8218'} = "\'";	#	single low-9 quotation mark
                                #       (comma not a good idea for tokenizers)
    $entity{'#964'} = "tau";	#	tau
#    $entity{'#9679'} = "";	#	??
    $entity{'#955'} = "lambda";	#	lambda
    $entity{'#954'} = "kappa";	#	kappa
#    $entity{'#305'} = "";	#	??
    $entity{'#963'} = "sigma";	#	sigma
    $entity{'#8594'} = "->";	#	rightwards arrow
    $entity{'#062'} = ">";	#	greater than
    $entity{'#8243'} = "\"";	#	double prima (use double quotes?)
#    $entity{'#943'} = "";	#	??
    $entity{'#962'} = "sigma";	#	sigmaf (sigma?)
#    $entity{'#351'} = "";	#	??
    $entity{'#038'} = "\&";	#	ampersand
#    $entity{'#940'} = "";	#	??
    $entity{'#937'} = "Omega";	#	Omega
    $entity{'#8722'} = "-";	#	minus
    $entity{'#0124'} = "\|";	#	|
    $entity{'#353'} = "s";	#	s with caron
#    $entity{'#333'} = "";	#	??
#    $entity{'#941'} = "";	#	??
    $entity{'#946'} = "beta";	#	beta
    $entity{'#969'} = "omega";	#	omega
    $entity{'#8249'} = "<";	#	single left pointing angle quot mark (less than?)
    $entity{'#8250'} = ">";	#	single right pointing angle quot mark (more than?)
    $entity{'#916'} = "Delta";	#	Delta



$data =~ s{ (
        &              # an entity starts with a semicolon
        ( 
	    \x23\d+    # and is either a pound (#) and numbers
	     |	       #   or else
	    \w+        # has alphanumunders up to a semi
	)         
        ;?             # a semi terminates AS DOES ANYTHING ELSE (XXX)
    )
} {

    $entity{$2}        # if it's a known entity use that
        ||             #   but otherwise
        $1             # leave what we'd found; NO WARNINGS (XXX)

}gex;                  # execute replacement -- that's code not a string

    return $data;
}


1;

=head1 NAME

I<PotaModule.pm>: module to perform various forms of cleaning and
filtering on an HTML file in order to use it as corpus fodder.

=head1 SYNOPSIS

$array_ref = dig_content($html_text, \%bad_words, $max_bad_types, $max_bad_tokens, \%good_words, $min_good_types, $min_good_tokens, $min_good_ratio, $min_size, $max_size);

=head1 DESCRIPTION

This module exports only one function, I<dig_content>, that is meant
to extract the fragment that contains the most connected text and the
least "boilerplate" from an html document. Moreover, the module
applies various filters to the document, and if the document violates
any of them (in particular, it is too large or too small, contains too
many words from a stop word list, or not enough from a list of words
that should cue connected text), the function filters out the document
(in the sense that it returns an empty string).

The function takes as its input an html document, and possibly empty
stop and keep lists and various parameters, and it returns an array
reference, where the first element of the array is a string containing
the cleaned text extracted from the analyzed document (possibly, an
empty string), and the second element is the score of the returned
fragment for the measure of tag density described below. This score
can be useful for debugging purposes, but it can typically be ignored.

=head2 ARGUMENTS

The function takes the following arguments, in the specified order:

B<$html_text>: The contents of an html document. If empty, an empty
string will be returned.

B<%bad_words>: Reference to a hash containing a list of stop words
(e.g., pornographic terms) as keys, associated with non-zero values
(so that it's easy to check if a word is in list). Passed hash can be
empty.

B<$max_bad_types>: Documents with at least as many types in stop word
list are filtered out (i.e., null string is returned). This should
always be higher than 0.

B<$max_bad_tokens>: Documents with at least as many tokens in stop
word list are filtered out (i.e., null string is returned). This
should always be higher than 0.

B<%good_words>: Reference to a hash containing a list of words (e.g.,
function words) that are expected to occur with a certain frequency in
all pages containing connected text in the target language. All words
should be associated to non-zero values (so that it's easy to check if
a word is in list). Passed hash can be empty.

B<$min_good_types>: Documents that do not contain at least as many
types from "good word" list are filtered out (i.e., null string is
returned). If list of good words is empty, this should be set to 0.

B<$min_good_tokens>: Documents that do not contain at least as many
tokens from "good word" list are filtered out (i.e., null string is
returned). If list of good words is empty, this should be set to 0.

B<$min_good_ratio>: At least this ratio of the tokens in a document
should come from good word list -- because of the Zipfian properties
of language, connected texts are expected to have a rather high
proportion of tokens from a small set of function words (empirically,
I found 0.25 to be a reasonable threshold). If list of good words is
empty, this should be set to 0.

B<$min_size>: Documents that have less than this number of characters
(as assessed by Perl length function) will be filtered out.

B<$max_size>: Documents that have more than this number of characters
(as assessed by perl length function) will be filtered out.

=head2 PROCEDURE AND NOTES

First, the function exported by this model filters out documents that
are below/above the maximum/minimum size thresholds.

Then it strips off javascript and comments, and it performs a rough
tokenization of the text and the html tags (that are mapped to "tag"
tokens). It then looks for the stretch of text that maximizes the
quantity:

N(textual tokens) - N(tag tokens)

This "low tag density" fragment is likely to contain the (or at least
"a") content rich section of the document. High tag density sections
of a page are more likely to contain boilerplate (navigation
information, links, etc.)

If the low tag density fragment satisfies the constraints on
minimum/maximum quantity of "good"/"bad" words, it is returned
(without the tags, of course) as the output string.

The module, for now, assumes that the input is in either latin1 or
utf8 encoding a latin1 language (utf8 is converted to latin1), and
that the language of the document is one where a simple, white-space
tokenization scheme will do the trick.

The method to find the content-rich section of a page is taken from
Aidan Finn's BTE module (a part of the Hyppia project: see URL below),
and the module contains generous portions of code from BTE.

However, this module, in my experiments, is a lot more efficient than
the original BTE module, probably because, instead of computing the
quantity above for each possible stretch, it avoids doing so for
stretches that could not possibly have the highest score (such as
sequences beginning with textual tokens preceded by other textual
tokens, or ending with textual tokens followed by other textual
tokens, or beginning or ending with tag tokens).

=head1 DEPENDENCIES

None I'm aware of.

=head1 AUTHOR

Marco Baroni, baroni AT sslmit.unibo.it

=head1 ACKNOWLEDGMENTS

Thanks to Aidan Finn for the BTE module and to Eros Zanchetta for
help, advice and testing.

=head1 BUGS

Probably many: if you find one, please let me know: baroni AT sslmit
unibo it


=head1 COPYRIGHT

Copyright 2005, Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

=head1 SEE ALSO

The BTE module of the Hyppia project:

http://www.smi.ucd.ie/hyppia/

=cut
