#!/usr/bin/perl -w

# For usage and comments, type:
# simplefilter.pl -h

use Getopt::Std;
getopts('hsd:');

{
$usage = <<"_USAGE_";
Usage:
simple_filter.pl [-s | -d delimiter] list data > filtered_data
simple_filter.pl -h

This simple filter reads a list of lines and then:

1) If option -s (for stop list) is passed, it removes all the
corresponding lines from the input corpus (or another list);

2) Otherwise, it keeps only the lines that are identical to those in
the list.

Option -d can be used to specify a delimiter that should be kept even if
it is not in list (this cannot be used in conjunction with stop list).

Notice that it is sufficient for a line to contain the delimiter in order
to be kept (to deal with numbering and such things).

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.
_USAGE_
}

if ($opt_h) {
    $opt_h = 1;
    # previous is just to avoid warning about $opt_h being used only once
    print $usage;
    exit;
}


$stop_op = 0;
if ($opt_s) {
    $stop_op = 1;
    if (($opt_s)&&($opt_d)) {
	die "No delimiter in stop list mode!";
    }
}
if ($opt_d) {
    $delimiter = $opt_d;
}

if ((!($listfile = shift))||(!($inputfile = shift))) {
    print $usage;
    exit;
}


open LIST, $listfile;
while (<LIST>) {
  $i=$_;
  $in{$i} = 1;
}
close LIST;

open INPUT, $inputfile;
while (<INPUT>) {
  $input = $_;
  if ($stop_op) {
    if ($in{$input}) {
      next;
    }
  }
  else {
    if (!$in{$input}) {
	if (($delimiter)&&($input !~ /.*$delimiter.*/)) {
		next;
	}
	else {
	    next;
	}
     }
  }
  print $input;
}
close INPUT;

