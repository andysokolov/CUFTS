#!/usr/local/bin/perl

use MARC::File::USMARC;
use constant MAX => 9999999;
my %counts;
 
 my $filename = shift or die "Must specify filename\n";
 my $file = MARC::File::USMARC->in( $filename );
 
 while ( my $marc = $file->next() ) {
     for my $field ( $marc->field("6..") ) {
         my $heading = $field->subfield('a');
 
         # trailing whitespace / punctuation.
         $heading =~ s/[.,]?\s*$//;
 
         # Now count it.
         ++$counts{$heading};
     }
 }
 $file->close();
 
 # Sort the list of headings based on the count of each.
 my @headings = reverse sort { $counts{$a} <=> $counts{$b} } keys %counts;
 
 # Take the top N hits...
 @headings = @headings[0..MAX-1];
 
 # And print out the results.
 for my $heading ( @headings ) {
     printf( "%5d %s\n", $counts{$heading}, $heading );
 }