use strict;

use Test::More tests => 4;

# Test that the ResolverRequest object can be created and spot check a couple of fields.
# The request one is important because it's an object, not a string like the others.

BEGIN {
	use_ok('CUFTS::ResolverResource');
}

my $r1 = CUFTS::ResolverResource->new();
isa_ok($r1, 'CUFTS::ResolverResource');

$r1->name('Test');
is($r1->name, 'Test');

$r1->resource( TestObject->new );
isa_ok($r1->resource, 'TestObject');

package TestObject;
sub new {
      return bless {}, shift;
}

1;