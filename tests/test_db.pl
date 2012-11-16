#!/usr/bin/perl

use lib '../lib';

use CUFTS::DB::Sites;
use Data::Dumper;

my $sites = CUFTS::DB::Sites->retrieve_all;
warn(Dumper($sites));