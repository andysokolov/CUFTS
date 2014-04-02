#!/usr/local/bin/perl

use lib qw (lib);

use strict;

use MARC::Batch;
use MARC::Record;

my $FATAL_ERRORS = 1;

$MARC::Record::DEBUG = 1;

my $batch = MARC::Batch->new('USMARC', @ARGV);
$batch->strict_off();

while ( read_record($batch) ) {
warn "----------------------------------------------------\n";

}

sub read_record {
    my ( $batch ) = @_;

    my $record;
    eval {
        $record = $batch->next();
    };
    if ( $@ ) {
        if ( $FATAL_ERRORS ) {
            die($@)
        }
        else {
            warn( $@ );
            warn( 'Fatal errors is off, skipping record.' );
            $record = read_record($batch);
        }
    }
    
    return $record;
}