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

$max_buffer_size= 250;

@no_near_duplicates=() ;
%duplicates= () ;

$counter= 250;

open LIST_OF_FILES, "<", $ARGV[0];

@to_be_validated= <LIST_OF_FILES> ;

close LIST_OF_FILES;

$count_of_non_duplicates= 0;

@next_to_be_validated= ();
$iteration= 0;

$skipper= 0;

while ( $#to_be_validated >= 0 && $counter <= 7500)
{
    print "Iteration number = $iteration\n";
    $skipper= 7250- $counter + 250;
    foreach (@to_be_validated) {
        chomp($_);
        $file= $_;  #Current file to be checked
        print "Checking duplicates for $file\n";
    
        #Read the entire file at once
        sysopen DOCFILE, $file, 0;
        sysread (DOCFILE, $doctext, -s DOCFILE);
        close DOCFILE;

        if ($skipper > 0 && $count_of_non_duplicates < $max_buffer_size){
            print "In Skipper part1 skipper= $skipper\n";
            $count_of_non_duplicates += 1;
            $deduper->add_doc($file, $doctext);
            push @no_near_duplicates, $file;
            $skipper = $skipper -1;
            next;
        }
        elsif ($skipper > 0){
            print "In Skipper part2 skipper= $skipper\n";
            push @next_to_be_validated, $file;
            $skipper = $skipper -1;
            next;
        }
	
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
            if ($count_of_non_duplicates >= $max_buffer_size ){
                push @next_to_be_validated, $file;
            }
            else{
                $count_of_non_duplicates += 1 ;
                $deduper->add_doc($file, $doctext);
                push @no_near_duplicates, $file;
            }
        }
    }
    @to_be_validated= @next_to_be_validated;
    @next_to_be_validated= ();
    $count_of_non_duplicates= 0;
    $deduper->clean();
    $iteration += 1;
    
    open NON_DUPLICATES, ">>", $ARGV[1];
    #Print Non Duplicate file names to a file
    foreach my $doc (@no_near_duplicates){
        print NON_DUPLICATES "$doc\n";
    }
    @no_near_duplicates = ();
    close NON_DUPLICATES;
    
    open DUPLICATES, ">>", $ARGV[2];
    #Print Duplcate file names to a file
    while ( my ($key, $value) = each(%duplicates) ) {
        print DUPLICATES "$key\t$value\n";
    }
    %duplicates= () ;
    close DUPLICATES;
    $counter += 250;
}

