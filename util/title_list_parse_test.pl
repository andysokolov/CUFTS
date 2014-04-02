#!/usr/local/bin/perl

##
## NOTE: This must be run from the base CUFTS directory using a relative
## path like: util/title_list_updater.pl or you will get module loading
## errors
##

##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## This file is part of CUFTS.
##
## CUFTS is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
## 
## CUFTS is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CUFTS; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

use lib qw(lib);

use Data::Dumper;

use strict;

if ( scalar(@ARGV) != 2 ) {
    usage();
    exit;
}

my $module = shift @ARGV;
my $file   = shift @ARGV;

$module = "CUFTS::Resources::$module";

my $module_file = "${module}.pm";
$module_file =~ s{::}{/}g;
require $module_file;

open DAT_FILE, $file or
    die("Unable to open file: $!");

$module->title_list_extra_requires();

*DAT_FILE = *{$module->preprocess_file(*DAT_FILE)};

$module->title_list_skip_lines(*DAT_FILE);

# get field headings

my $field_headings = $module->title_list_get_field_headings(*DAT_FILE);
defined($field_headings) && (ref($field_headings) eq 'ARRAY') && (scalar(@$field_headings) > 0) or
    die("title_list_get_field_headings did not return an array ref or did not contain any fields");

print "Field headings\n";
print(Dumper($field_headings));
#print "Field headings: ", join( "\t", @$field_headings ), "\n\n";

my $count = 0;
while ( my $row = $module->title_list_parse_row(*DAT_FILE) ) {
    $count++;
#    print "Line $count\n", join( "\t", @$row ), "\n";
    
    my $record = $module->title_list_build_record($field_headings, $row);            
    unless ( defined($record) && (ref($record) eq 'HASH') ) {
        print("build_record did not return a hash ref\n\n");
        next;
    }

    my $data_errors = $module->clean_data($record);

    if ( $module->skip_record($record) ) {
        print "Skipping record, as per skip_record()\n\n";
        next
    };

    if (defined($data_errors) && ref($data_errors) eq 'ARRAY' && scalar(@$data_errors) > 0) {
        print join(', ', @$data_errors), "\n\n";
        next;
    }

    print Dumper( $record );
    print "\n\n"

}

close DAT_FILE;


sub usage {
    print "util/title_list_parse_test.pl Module title_list\n";
}