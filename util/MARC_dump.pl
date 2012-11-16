#!/usr/local/bin/perl

use lib qw (lib);

use strict;

use MARC::Batch;
use MARC::Record;

$MARC::Record::DEBUG = 1;

my $batch = MARC::Batch->new('USMARC', @ARGV);
$batch->strict_off();

while (my $record = $batch->next()) {
warn "----------------------------------------------------\n";

}
