#!/usr/bin/env perl

# Author: Siva Reddy
# Purpose: Developed for detecting near duplicate documents. 
# Date of Creation: Jan 31 2009 3:15 am
# Email: gvsreddy@students.iiit.ac.in
# Dependency: Text::DeDuper Module


use Text::DeDuper;

#Creating instance of DeDuper
$deduper = new Text::DeDuper(
	ngram_size => 5,
	encoding => 'utf8'
);


@no_near_duplicates=();	#List of no duplicates
%duplicates= ();	# { document : its_duplicates_seperated_by_space }


# $ARGV[0] is a file containing all the file 
# paths of the files to be checked for Duplication.
# I recommend to sort the file names list according
# to the size of files so that the non duplicate file 
# with larger size is present in your final list of
# non-duplicate files.


# Check each file for its duplicates
open LIST_OF_FILES, "<", $ARGV[0];

while (<LIST_OF_FILES>){
	chomp($_);
	$file= $_;	#Current file to be checked
	print "Checking duplicates for $file\n";

	#Read the entire file at once
	sysopen DOCFILE, $file, 0;
	sysread (DOCFILE, $doctext, -s DOCFILE);
	close DOCFILE;
	
	#Does it have duplicate
	@similar_docs= $deduper->find_similar($doctext);

	#Yes it has. Add it to duplicates hash table
	if (@similar_docs){	
		$duplicate_files= "";
		foreach $doc (@similar_docs){
			$duplicate_files .= $doc."\t";
		}
		$duplicates{$file}= $duplicate_files; 
		print "\tFound Duplicate $duplicate_files\n";
		#print $duplicates{$file};
		#print @similar_docs;
	}

	#Not a duplicate. Add it to non duplicate documents
	else{
		$deduper->add_doc($file, $doctext);
		push @no_near_duplicates, $file;
	}
}

#Print Non Duplicate file names to a file
open NON_DUPLICATES, ">", $ARGV[1];
foreach my $doc (@no_near_duplicates){
	print NON_DUPLICATES "$doc\n";
}
close NON_DUPLICATES;

#Print Duplcate file names to a file
open DUPLICATES, ">", $ARGV[2];
while ( my ($key, $value) = each(%duplicates) ) {
	print DUPLICATES "$key\t$value\n";
}


