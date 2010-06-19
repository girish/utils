#!/usr/bin/perl -w


# For comments, usage, etc., do:
# print_rank.pl -h

use Getopt::Std;
use strict;

my $usage;

{
$usage = <<"_USAGE_";
Usage: 
print_rank.pl [-fN] ordered_list > list_with_explicit_ranks 
print_rank.pl -h

Given a list ranked in order of significance (from the most signifcant
to the least significant item) on the basis of a certain measure, this
script prints the same list with each line prefixed by its rank.

The element with the most significant value for the relevant measure
gets rank 1 , the second highest 2, etc.

In case of ties, the rank assigned is an average of the ranks the
elements would get if they were not tied -- e.g., if the second and
third element in the list have the same value, they will both get rank
2.5 (= (2+3)/2); the fourth element will then get rank 4.

It is assumed that the ordered elements all contain the same number of
tab- or space-delimited fields

The field containing the value of the ordering measure can be specified using
option -f, the default is 1 (i.e., ordering value is in first field)

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}

my %op;
getopts('hf:',\%op);

if ($op{h}) {
    print $usage;
    exit;
} 

my $r_column = 0;
if ($op{"f"}) {
    $r_column = $op{"f"} - 1;
}

my $curr_value;
my $first;
my $last;
my $avg;
my @a = ();
my $i = 0;
my $j = 0;


while (<>) {
    my @fields = split "[\t ]";
    chomp $fields[$#fields];

    my $value = $fields[$r_column];
    $i++;
    
    if ((!($curr_value))||($value != $curr_value)) {
	if ($curr_value) {

	    $avg = ($first+$last)/2;
	    foreach (@a) {
		print "$avg\t";
		print;
	    }
	    @a = ();
	    $j = 0;
	    
	}
	$first = $i;
	$curr_value = $value;
    }

    $j++;
    push @a,$_;
    $last = $i;
}

$avg = ($first+$last)/2;
foreach (@a) {
    print "$avg\t";
    print;
}
