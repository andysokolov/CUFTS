use strict;

use Test::More tests => 3;

BEGIN {
	use_ok('CUFTS::Config');
}

my $schema = CUFTS::Config->get_schema();
isa_ok($schema, 'CUFTS::Schema');

my $timestamp = $schema->get_now();

like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp from database');
