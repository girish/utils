#!/usr/bin/perl -w

# For comments, usage, etc. do:
# tagwrapper -h

use strict;
use Getopt::Std;
use File::Temp qw / tempfile /;
use Inline::Files;

my $usage;
{
$usage = <<"_USAGE_";

This script performs tagging of English, German, Italian, French and
Spanish by invoking the appropriate taggers and producing output in
the format expected by CWB:

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

where, independently of the tagger output, the positional attributes
are always arranged in the order: word pos lemma (tab delimited).

The text elements are going to be present only if the -d option is
used (see below).

The relevant taggers must be in the path of the user. They are:

tree-tagger-english
tree-tagger-german
ita_tree_tagger_wrapper.pl
analyzer

The tagsets are those used by these taggers, unless replacement tags
are provided in the parameter files bundled in the __DATA__ section of
the script.

Usage:

tagwrapper.pl -l langcode [-d delimiter] inputfile > taggedoutput

tagwrapper.pl -h | more

-l langcode: one of en de it fr es

-d delimiter: if a line begins with delimeter, the first string
 following delimiter is used as an id and a corresponding text element
 is introduced in the output

-h: prints this information and quits

The script is controlled by various parameter files that are bundled
at the bottom of the script in the __DATA__ section.

Copyright 2005, Marco Baroni and Sara Piccioni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}
{
    my $blah = 1;
# this useless block is here because here document confuses
# emacs
}

my %opts = ();
getopts('hl:d:',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}

my $delimiter;
if (!($delimiter = $opts{d})) {
    undef $delimiter; # melius est abundare
}

my $langcode;
# lang code is mandatory and must be one of en de it fr es
# list should not be hard-coded!
if ( !($opts{l}=~/^(en|de|it|fr|es)$/)  || !($langcode=$opts{l})) {
    die "please specify valid language code!";
}

# preprocessing

print STDERR "preprocessing the input\n";

my ($temphandle,$tempfile) = tempfile(UNLINK => 1);

while (<>) {

    # always a good idea to undos
    s/\r//;

    # grabbing the id from lines beginning with delimiter
    if ($delimiter && /^[ \t]*$delimiter[ \t]*([^ \t]*)/) {
	my $id = $1;
	$id =~ s/\n//g;
	print $temphandle "<text_id=\"$id\">\n";
    }
    else {
	# < and > can confuse taggers and (perhaps???) CWB
	s/[<>]/ /g;
	print $temphandle $_;
    }
}

# now we read the parameter files to see what is the sentence marker
# in the language of interest and what is the order of the word, pos
# and lemma fields

my $code;
my $sent;
my @fields;
my %columns;

while (<SENTINFO>) {
    chomp;
    ($code,$sent) = split "[ \t]+",$_;
    if ($code eq $langcode) {
	last;
    }
}
close SENTINFO;

while (<FIELDORDERINFO>) {
    chomp;
    my ($code,$fstring) = split "[ \t]+",$_;
    if ($code eq $langcode) {
	@fields = split "",$fstring;
	
	foreach (0..2){
	    $columns{$fields[$_]} = $_;
	}

	last;
    }
}
close FIELDORDERINFO;

# tagging

print STDERR "now tagging\n";

my ($temphandletgd,$tempfiletgd) = tempfile(UNLINK => 1);

# ENGLISH
if ($langcode eq "en") {
    
    `tree-tagger-english $tempfile > $tempfiletgd`;

}
# GERMAN
elsif($langcode eq "de") {

    `tree-tagger-german $tempfile > $tempfiletgd`;

}
# FRENCH
elsif ($langcode eq "fr") {

    `tree-tagger-french $tempfile > $tempfiletgd`;
}
# ITALIAN
elsif ($langcode eq "it") {
    `ita_tree_tagger_wrapper.pl -x $tempfile > $tempfiletgd`;
}
# SPANISH
elsif ($langcode eq "es") {

    # spanish tagging is kind of hacky... eventually, we should
    # probably write a spanish_tree_tagger_wrapper.pl like
    # we do for italian...

    my ($tokhandle,$tokfile) = tempfile(UNLINK => 1);
    while (<FREELINGFESTOK>) {
	print $tokhandle $_;
    }

    `analyzer -f /usr/local/share/FreeLing/config/es.cfg --lang es --inpf plain --outf tagged --ftok $tokfile --noloc --nodate --noquant --noner --nonec < $tempfile | sed "s/>.*/>/" | grep -v "^\$" > $tempfiletgd`;

    close $tokhandle;
}
close $temphandle;

# postprocess

print STDERR "now post-processing and printing output\n";

# if available, get list of replacement tags 

my %replacement_tag;

my $uc_l = uc($langcode);
while (<$uc_l>) {
    if (/^\#/) {
	next;
    }
    chomp;
    my ($itag,$otag) = split "[ \t]+",$_;
    $replacement_tag{$itag} = $otag;
}

my $replace_pos = 0;
if (%replacement_tag) {
    $replace_pos = 1;
}

# print output

my $sentopen = 0;
my $textopen = 0;

print "<corpus>\n";

while (<$temphandletgd>) {

    chomp;

    if (/^<text/) {

	if ($sentopen) {
	    print "</s>\n";
	}
	if ($textopen) {
	    print "</text>\n";
	}
	s/text_/text /;
	print;
	print "\n";
	print "<s>\n";
	$sentopen = 1;
	$textopen = 1;
	next;
    }

    if (!$sentopen) {
	print "<s>\n";
	$sentopen = 1;
    }

    @fields = ();

    @fields = split "[\t ]+",$_;
    
    if ($replace_pos) {

	my $replacement;

	if (!($replacement =
	      $replacement_tag{$fields[$columns{p}]})) {
	    print STDERR "NB: tag $fields[$columns{p}] not found in replacement list:\nleaving unchanged\n";
	}
	else {
	    $fields[$columns{p}] = $replacement;
	}
    }

    $fields[$columns{l}] =~s/<unknown>/UNKNOWN/;

    print "$fields[$columns{w}]\t$fields[$columns{p}]\t$fields[$columns{l}]\n";

    if ($fields[$columns{p}] eq $sent) {
	print "</s>\n";
	$sentopen =0;
    }
    
}

if ($sentopen) {
    print "</s>\n";
}
if ($textopen) {
    print "</text>\n";
}

print "</corpus>\n";

# from here, parameter files
__SENTINFO__
en SENT
it SENT
fr SENT
de $.
es FRASE
__FIELDORDERINFO__
en wpl
it wpl
fr wpl
de wpl
es wlp
__EN__
# these comment lines shut up Inline::File warnings
__DE__
# these comment lines shut up Inline::File warnings
__FR__
# these comment lines shut up Inline::File warnings
__IT__
# these comment lines shut up Inline::File warnings
__ES__
# Freeling/Eagles replacement patterns provided by Sara P
AOFS0	ADJ:f+s
AOFP0	ADJ:f+p
AOMS0	ADJ:m+s
AOMP0	ADJ:m+p
AQ00000	ADJ
AQ0FS0	ADJ:f+s
AQ0FSP	ADJ:f+s
AQ0FP0	ADJ:f+p
AQ0FPP	ADJ:f+p
AQ0MSP	ADJ:m+s
AQ0MP0	ADJ:m+p
AQ0MPP	ADJ:m+p
AQ0CS0	ADJ:c+s
AQ0CP0	ADJ:c+p
CC	CONJCOORD
CS	CONJSUB
DA0FS0	ART-F:s
DA0FP0	ART-F:p
DA0MS0	ART-M:s
DA0MP0	ART-M:p
DA0NS0	ART-N
DD0FS0	DET-DEMO:f+s
DD0FP0	DET-DEMO:f+p
DD0MS0	DET-DEMO:m+s
DD0MP0	DET-DEMO:m+p
DE0FS0	DET-INT:f+s		
DE0FP0	DET-INT:f+p			
DE0MS0	DET-INT:m+s
DE0MP0	DET-INT:m+p
DE0CN0	DET-INT:c+n	
DI0FS0	DET-INDEF:f+s
DI0FP0	DET-INDEF:f+p	
DI0MS0	DET-INDEF:m+s
DI0MP0	DET-INDEF:m+p
DI0CS0	DET-INDEF:c+s	
DI0CP0	DET-INDEF:c+p
DN0FS0	DET-NUM-CARD:f+s
DN0FP0	DET-NUM-CARD:f+p
DN0MSO	DET-NUM-CARD:m+s
DN0MPO	DET-NUM-CARD:m+p
DN0CP0	DET-NUM-CARD:c+s
DP1CSS	DET-POS-1s:c+s
DP1CPS	DET-POS-1s:c+p
DP1FSS	DET-POS-1s:f+s
DP1FPS	DET-POS-1s:f+p
DP1MSS	DET-POS-1s:m+s
DP1MPS	DET-POS-1s:m+p
DP2CSS	DET-POS-2s:c+s
DP2CPS	DET-POS-2s:c+p
DP2FSS	DET-POS-2s:f+s
DP2FPS	DET-POS-2s:f+p
DP2MSS	DET-POS-2s:m+s
DP2MPS	DET-POS-2s:m+p
DP3CS0	DET-POS-3:c+s
DP3CP0	DET-POS-3:c+p
DP3FS0	DET-POS-3:f+s
DP3FP0	DET-POS-3:f+p
DP3MS0	DET-POS-3:m+s
DP3MP0	DET-POS-3:m+p
DP1FSP	DET-POS-1p:f+s
DP1FPP	DET-POS-1p:f+p
DP1MSP	DET-POS-1p:m+s
DP1MPP	DET-POS-1p:m+p
DP2FSP	DET-POS-2p:f+s
DP2FPP	DET-POS-2p:f+p
DP2MSP	DET-POS-2p:m+s
DP2MPP	DET-POS-2p:m+p
Faa	FRASE
Fat	FRASE 
Fc	PUN-COMA 	
Fca	PUN-CORC-IZ 
Fct	PUN-CORC-DE
Fd	PUN-DOS-PUNTOS 
Fe	PUN-COM 
Fg	PUN-GUI 
Fh	PUN-BAR 
Fia	FRASE
Fit	FRASE
Fla	PUN-LLAVE-IZ
Flt	PUN-LLAVE-DE
Fp	FRASE 
Fpa	PUN-PAR-IZ
Fpt	PUN-PAR-DE
Fra	PUN-COM-ANG-IZ	 
Frc	PUN-COM-ANG-DE	  
Fs	FRASE 
Ft	PUN-PORCEN 
Fx	PUN-PUNTOCOMA 
Fz	PUN-UNDER 
Fz	PUN-MAS 
Fz	PUN-IGUAL 
I	INT
NCFS000	NOMBRE-C-F:s
NCFS00A	NOMBRE-C-F:s		
NCFP000	NOMBRE-C-F:p	
NCFP00A	NOMBRE-C-F:p
NCFN000	NOMBRE-C-F:inv
NCMS000	NOMBRE-C-M:s
NCMS00A	NOMBRE-C-M:s
NCMP000	NOMBRE-C-M:p
NCMP00A	NOMBRE-C-M:p
NCMN000	NOMBRE-C-M:inv
NCCS000 NOMBRE-C-C:s	
NCCP000	NOMBRE-C-C:p
NCCN000	NOMBRE-C-C:inv	
NC00000	NOMBRE-C
P0000000	PRO-CLI
P010S000	PRO-CLI-1-C-S
P020S000	PRO-CLI-2-C-S
P020P000	PRO-CLI-2-C-P		
P0300000	PRO-CLI-3
PD0FS000	PRO-DEM-F-S
PD0FP000	PRO-DEM-F-P	
PD0MS000	PRO-DEM-M-S
PD0MP000	PRO-DEM-M-P
PD0NS000	PRO-DEM-N-S
PI0FS000	PRO-INDEF-F-S
PI0FP000	PRO-INDEF-F-P
PI0MS000	PRO-INDEF-M-S
PI0MP000	PRO-INDEF-M-P
PI0CS000	PRO-INDEF-C-S
PI0CP000	PRO-INDEF-C-P
PN0FS000	PRO-NUM:f+s
PN0FP000	PRO-NUM:f+p	
PN0MS000	PRO-NUM:m+s
PN0MP000	PRO-NUM:m+p
PN0CS000	PRO-NUM:c+s
PN0CP000	PRO-NUM:c+p
PN000000	PRO-NUM:0+0
PP1CSN00	PRO-PERS-1-C-S:n		
PP1CSO00	PRO-PERS-1-C-S:obl	
PP1FP000	PRO-PERS-1-F-P
PP1MP000	PRO-PERS-1-M-P
PP2CSN00	PRO-PERS-2-C-S:n
PP2CS000	PRO-PERS-2-C-S	
PP2CSO00	PRO-PERS-2-C-S:obl	
PP2CS00P	PRO-PERS-2-C-S-P
PP2FP000	PRO-PERS-2-F-P	
PP2MP000	PRO-PERS-2-M-P	
PP3FS000	PRO-PERS-3-F-S	
PP3FP000	PRO-PERS-3-F-P		
PP3MS000	PRO-PERS-3-M-S	
PP3MP000	PRO-PERS-3-M-P	
PP1CS000	PRO-PERS-1-C-S	
PP1CP000	PRO-PERS-1-C-P		
PP2CS000	PRO-PERS-2-C-S
PP2CP000	PRO-PERS-2-C-P	
PP3FSA00	PRO-PERS-3-F-S:ac	
PP3FSD00	PRO-PERS-3-F-S:dat	
PP3FPA00	PRO-PERS-3-F-P:ac		 
PP3MSA00	PRO-PERS-3-M-S:ac		
PP3MPA00	PRO-PERS-3-M-P:ac		
PP3CSD00	PRO-PERS-3-C-S:dat	
PP3CN000	PRO-PERS-3-C-N	
PP3CPD00	PRO-PERS-3-C-P:dat	
PX1FS0S0	PRO-POS-F-S-1s
PX1FP0S0	PRO-POS-F-P-1s
PX1MS0S0	PRO-POS-M-S-1s
PX1MP0S0	PRO-POS-M-P-1s
PX2FS0S0	PRO-POS-F-S-2s
PX2FP0S0	PRO-POS-F-P-2s
PX2MS0S0	PRO-POS-M-S-2s
PX2MP0S0	PRO-POS-M-P-2s
PX3FS000	PRO-POS-F-S-3
PX3FP000	PRO-POS-F-P-3
PX3MS000	PRO-POS-M-S-3
PX3MP000	PRO-POS-M-P-3
PX1FS0P0	PRO-POS-F-S-1p
PX1FP0P0	PRO-POS-F-P-1p
PX1MS0P0	PRO-POS-M-S-1p
PX1MP0P0	PRO-POS-M-P-1p
PX2FS0P0	PRO-POS-F-S-2p
PX2FP0P0	PRO-POS-F-P-2p
PX2MS0P0	PRO-POS-M-S-2p
PX2MP0P0	PRO-POS-M-P-2p	
PR000000	PRO-REL
PR0CN000	PRO-REL-C-N
PR0CP000	PRO-REL-C-P
PR0CS000	PRO-REL-C-S
PT000000	PRO-INT
PT0CS000	PRO-INT-C-S
PT0CP000	PRO-INT-C-P
PT0FS000	PRO-INT-F-S
PT0FP000	PRO-INT-F-P
PT0MS000	PRO-INT-M-S
PT0MP000	PRO-INT-M-P
RN	ADV
RG	ADV
SPS00	PRE
SPCMS	PREART-M:s
VMIP1S0	VER:ind+pre+1+s
VMIP2S0	VER:ind+pre+2+s
VMIP3S0	VER:ind+pre+3+s
VMIP1P0	VER:ind+pre+1+p
VMIP2P0	VER:ind+pre+2+p
VMIP3P0	VER:ind+pre+3+p
VMIS1S0	VER:ind+pas+1+s
VMIS2S0	VER:ind+pas+2+s
VMIS3S0	VER:ind+pas+3+s
VMIS1P0	VER:ind+pas+1+p
VMIS2P0	VER:ind+pas+2+p
VMIS3P0	VER:ind+pas+3+p
VMII1S0	VER:ind+imp+1+s	
VMII2S0	VER:ind+imp+2+s	
VMII3S0	VER:ind+imp+3+s	
VMII1P0	VER:ind+imp+1+p	
VMII2P0	VER:ind+imp+2+p	
VMII3P0	VER:ind+imp+3+p
VMIF1S0	VER:ind+fut+1+s
VMIF2S0	VER:ind+fut+2+s
VMIF3S0	VER:ind+fut+3+s
VMIF1P0	VER:ind+fut+1+p
VMIF2P0	VER:ind+fut+2+p
VMIF3P0	VER:ind+fut+3+p
VMSP1S0	VER:sub+pre+1+s
VMSP2S0	VER:sub+pre+2+s
VMSP3S0	VER:sub+pre+3+s
VMSP1P0	VER:sub+pre+1+p
VMSP2P0	VER:sub+pre+2+p
VMSP3P0	VER:sub+pre+3+p
VMSI1S0	VER:sub+imp+1+s	
VMSI2S0	VER:sub+imp+2+s	
VMSI3S0	VER:sub+imp+3+s		
VMSI1P0	VER:sub+imp+1+p	
VMSI2P0	VER:sub+imp+2+p	
VMSI3P0	VER:sub+imp+3+p	
VMIC1S0	VER:cond+pre+1+s
VMIC2S0	VER:cond+pre+2+s
VMIC3S0	VER:cond+pre+3+s
VMIC1P0	VER:cond+pre+1+p
VMIC2P0	VER:cond+pre+2+p
VMIC3P0	VER:cond+pre+3+p
VMM02S0	VER:imper+2+s
VMM03S0	VER:imper+3+s	
VMM02P0	VER:imper+2+p	
VMM03P0	VER:imper+3+p
VMP00SF	VER:part+s+f
VMP00SM	VER:part+s+m
VMP00PF VER:part+p+f
VMP00PM	VER:part+p+m
VMG0000	VER:ger
VMN0000	VER:inf
VSIP1S0	SER:ind+pre+1+s
VSIP2S0	SER:ind+pre+2+s
VSIP3S0	SER:ind+pre+3+s
VSIP1P0	SER:ind+pre+1+p
VSIP2P0	SER:ind+pre+2+p
VSIP3P0	SER:ind+pre+3+p
VSIS1S0	SER:ind+pas+1+s
VSIS2S0	SER:ind+pas+2+s
VSIS3S0	SER:ind+pas+3+s
VSIS1P0	SER:ind+pas+1+p
VSIS2P0	SER:ind+pas+2+p
VSIS3P0	SER:ind+pas+3+p
VSII1S0	SER:ind+imp+1+s	
VSII2S0	SER:ind+imp+2+s	
VSII3S0	SER:ind+imp+3+s	
VSII1P0	SER:ind+imp+1+p	
VSII2P0	SER:ind+imp+2+p	
VSII3P0	SER:ind+imp+3+p
VSIF1S0	SER:ind+fut+1+s
VSIF2S0	SER:ind+fut+2+s
VSIF3S0	SER:ind+fut+3+s
VSIF1P0	SER:ind+fut+1+p
VSIF2P0	SER:ind+fut+2+p
VSIF3P0	SER:ind+fut+3+p
VSSP1S0	SER:sub+pre+1+s
VSSP2S0	SER:sub+pre+2+s
VSSP3S0	SER:sub+pre+3+s
VSSP1P0	SER:sub+pre+1+p
VSSP2P0	SER:sub+pre+2+p
VSSP3P0	SER:sub+pre+3+p
VSSI1S0	SER:sub+imp+1+s	
VSSI2S0	SER:sub+imp+2+s	
VSSI3S0	SER:sub+imp+3+s		
VSSI1P0	SER:sub+imp+1+p	
VSSI2P0	SER:sub+imp+2+p	
VSSI3P0	SER:sub+imp+3+p	
VSIC1S0	SER:cond+pre+1+s
VSIC2S0	SER:cond+pre+2+s
VSIC3S0	SER:cond+pre+3+s
VSIC1P0	SER:cond+pre+1+p
VSIC2P0	SER:cond+pre+2+p
VSIC3P0	SER:cond+pre+3+p
VSM02S0	SER:imper+2+s
VSM03S0	SER:imper+3+s	
VSM02P0	SER:imper+2+p	
VSM03P0	SER:imper+3+p
VSP00SF	SER:part+s+f
VSP00SM	SER:part+s+m
VSP00PF SER:part+p+f
VSP00PM	SER:part+p+m
VSG0000	SER:ger
VSN0000	SER:inf
VAIP1S0	AUX:ind+pre+1+s
VAIP2S0	AUX:ind+pre+2+s
VAIP3S0	AUX:ind+pre+3+s
VAIP1P0	AUX:ind+pre+1+p
VAIP2P0	AUX:ind+pre+2+p
VAIP3P0	AUX:ind+pre+3+p
VAIS1S0	AUX:ind+pas+1+s
VAIS2S0	AUX:ind+pas+2+s
VAIS3S0	AUX:ind+pas+3+s
VAIS1P0	AUX:ind+pas+1+p
VAIS2P0	AUX:ind+pas+2+p
VAIS3P0	AUX:ind+pas+3+p
VAII1S0	AUX:ind+imp+1+s	
VAII2S0	AUX:ind+imp+2+s	
VAII3S0	AUX:ind+imp+3+s	
VAII1P0	AUX:ind+imp+1+p	
VAII2P0	AUX:ind+imp+2+p	
VAII3P0	AUX:ind+imp+3+p
VAIF1S0	AUX:ind+fut+1+s
VAIF2S0	AUX:ind+fut+2+s
VAIF3S0	AUX:ind+fut+3+s
VAIF1P0	AUX:ind+fut+1+p
VAIF2P0	AUX:ind+fut+2+p
VAIF3P0	AUX:ind+fut+3+p
VASP1S0	AUX:sub+pre+1+s
VASP2S0	AUX:sub+pre+2+s
VASP3S0	AUX:sub+pre+3+s
VASP1P0	AUX:sub+pre+1+p
VASP2P0	AUX:sub+pre+2+p
VASP3P0	AUX:sub+pre+3+p
VASI1S0	AUX:sub+imp+1+s	
VASI2S0	AUX:sub+imp+2+s	
VASI3S0	AUX:sub+imp+3+s		
VASI1P0	AUX:sub+imp+1+p	
VASI2P0	AUX:sub+imp+2+p	
VASI3P0	AUX:sub+imp+3+p	
VAIC1S0	AUX:cond+pre+1+s
VAIC2S0	AUX:cond+pre+2+s
VAIC3S0	AUX:cond+pre+3+s
VAIC1P0	AUX:cond+pre+1+p
VAIC2P0	AUX:cond+pre+2+p
VAIC3P0	AUX:cond+pre+3+p
VAM02S0	AUX:imper+2+s
VAM03S0	AUX:imper+3+s	
VAM02P0	AUX:imper+2+p	
VAM03P0	AUX:imper+3+p
VAP00SF	AUX:part+s+f
VAP00SM	AUX:part+s+m
VAP00PF AUX:part+p+f
VAP00PM	AUX:part+p+m
VAG0000	AUX:ger
VAN0000	AUX:inf
Z	NUM
AO0FP0	ADJ:f+p
AO0FS0	ADJ:f+s
AO0MP0	ADJ:m+p
AO0MS0	ADJ:m+s
AQ0CN0	ADJ:c+n
AQ0MS0	ADJ:m+s
DD0CP0	DET-DEMO:c+p	
DD0CS0	DET-DEMO:c+s
DN0CS0	DET-NUM-CARD:c+s
DN0MP0	DET-NUM-CARD:m+p
DN0MS0	DET-NUM-CARD:m+s
DT0CN0	DET-INT:c+n
DT0MS0	DET-INT:m+s
PD0CS000	PRO-DEM-C-S
PP3CNO00	PRO-PERS-3-C-N:obl
PP3NS000	PRO-PERS-3-N-S
PR0FP000	PRO-REL-F-P
PR0FS000	PRO-REL-F-S
PR0MP000	PRO-REL-M-P
PR0MS000	PRO-REL-M-S
VMI0000	VER:ind
VMM0000	VER:imper
VMM01P0	VER:imper+1+p
VMP0000	VER:part
VMSF2S0	VER:sub+fut+2+s
Y	ABR
__FREELINGFESTOK__

## following is a bit of a hack by Marco and Sara P
## perhaps, we should eventually move to have a separate
## wrapper for Freeling/Spanish as we do for Treetagger/It 
## macros to be used in RegExps rules
<Macros>
ALPHA      [^\]<>[(\.,";:?!¿¡«»'`´)^@~|}{_/\\+=&$#*+%\s\d\-]     
ALPHANUM   [^\]<>[(\.,";:?!¿¡«»'`´)^@~|}{_/\\+=&$#*+%\s\-]
NOALPHANUM [\]<>[(\.,";:?!¿¡«»'`´)^@~|}{_/\\+=&$#*+%\s\-]
PARTNUM    [^\]<>[(";:?!¿¡«»'`´)^@~|}{\s]
OTHERS     [\]<>[(\.,";:?!¿¡«»'`´)^@~|}{_/\\+=&$#*+%\-]
</Macros>

## Tokenization rules. They are applied in the order of definition.
## The first matching the *beginning* of the line is applied
## and a token built. The process is repeated until the line 
## has been completely processed.
##    -The first field in the rule is the rule name. If it starts
##     with a "*", the RegExp will only produce a token if the 
##     match is found in abbreviation list <Abbreviations> below.
##    -The second field in the rule is the substring to form the token/s with
##     It may be 0 (the match of the whole expression) or any number
##     from 1 to the number of substrings (up to 9). A token will be
##     created for each substring from 1 to the specified value.
##    -The third field is the regexp to match against the line
## 
<RegExps>
DELIMITERS	0  (<[^>]*>)
INDEX_SEQUENCE  0  (\.{4,}|-{2,}|\*{2,}|_{2,}|/{2,})
INITIALS1       1  ([A-Z](\.[A-Z])+)(\.\.\.)
INITIALS2 	0  ([A-Z]\.)+
NAMES_CODES	0  ({PARTNUM}*[0-9]{PARTNUM}*{ALPHANUM})
THREE_DOTS 	0  (\.\.\.)
QUOTES	        0  (``|´´|<<|>>|'')
MAILS 	        0  {ALPHANUM}+([\._]{ALPHANUM}+)*@{ALPHANUM}+([\._]{ALPHANUM}+)*
URLS 	        0  ((mailto:|(news|http|https|ftp|ftps)://)\S+|^(www(\.\S+)+))
KEEP_COMPOUNDS  0  {ALPHA}+(['_\-]{ALPHA}+)+
*ABREVIATIONS1  0  (({ALPHA}+\.)+)(?!\.\.)
*ABREVIATIONS2  0  ({ALPHA}+\.)(?!\.\.)
WORD            0  {ALPHANUM}+
OTHERS_C        0  {OTHERS}
</RegExps>

## Abbreviations.  The dot is not tokenized separately
## in the cases listed below.
<Abbreviations>
a.c.
aa.rr.
abrev.
adj.
adm.
admón.
afma.
afmas.
afmo.
afmos.
ag.
am.
ap.
apdo.
art.
arts.
arz.
arzbpo.
assn.
atte.
av.
avda.
bros.
bv.
cap.
caps.
cg.
cgo.
cia.
cit.
cl.
cm.
co.
col.
corp.
cos.
cta.
cte.
ctra.
cts.
cía.
d.c.
dcha.
dept.
depto.
dg.
dl.
dm.
doc.
docs.
dpt.
dpto.
dr.
dra.
dras.
dres.
dto.
dupdo.
ed.
ee.uu.
ej.
emma.
emmas.
emmo.
emmos.
entlo.
entpo.
esp.
etc.
ex.
excm.
excma.
excmas.
excmo.
excmos.
fasc.
fdo.
fig.
figs.
fol.
fra.
gral.
ha.
hnos.
hros.
hz.
ib.
ibid.
ibíd.
id.
ilm.
ilma.
ilmas.
ilmo.
ilmos.
iltre.
inc.
intr.
izq.
izqda.
izqdo.
jr.
kc.
kcal.
kg.
khz.
kl.
km.
kw.
lda.
ldo.
lib.
lim.
loc.
ltd.
ltda.
lám.
ma.
mg.
mhz.
min.
mons.
mr.
mrs.
ms.
mss.
mtro.
máx.
mín.
ntra.
ntro.
núm.
ob.
obpo.
op.
pd.
ph.
pje.
pl.
plc.
pm.
pp.
ppal.
pral.
prof.
prov.
pról.
ps.
pta.
ptas.
pte.
pts.
pza.
pág.
págs.
párr.
rda.
rdo.
ref.
reg.
rel.
rev.
revda.
revdo.
rma.
rmo.
rte.
s.
sdad.
sec.
secret.
seg.
sg.
sig.
smo.
sr.
sra.
sras.
sres.
srs.
srta.
ss.mm.
sta.
sto.
sust.
tech.
tel.
telf.
teléf.
ten.
tfono.
tlf.
tít.
ud.
uds.
vda.
vdo.
vid.
vol.
vols.
vra.
vro.
vta.
íd.
ít.
</Abbreviations>
