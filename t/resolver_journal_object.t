use strict;

use Test::More tests => 3;

# Test that the ResolverRequest object can be created and spot check a couple of fields.
# The request one is important because it's an object, not a string like the others.

BEGIN {
	use_ok('CUFTS::ResolverJournal');
}

my $r1 = CUFTS::ResolverJournal->new();
isa_ok($r1, 'CUFTS::ResolverJournal');

$r1->title('Test');
is($r1->title, 'Test');

1;