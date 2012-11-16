#!/usr/local/bin/perl
# 
use lib qw(lib);

##
## This script changes all HTML entities like &egrave; into their
## ASCII equivalent.
##

use HTML::Entities;

while (<>) {
	print decode_entities($_);
}

