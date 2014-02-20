use strict;

use Test::More tests => 8;

BEGIN {
	use_ok('CUFTS::Result');
}

# Internal cleanup testing.

my $r1 = CUFTS::Result->new();
isa_ok($r1, 'CUFTS::Result');

$r1->atitle('Test Title');
is($r1->atitle, 'Test Title');

$r1->url('http://www.test.com/');
is($r1->url, 'http://www.test.com/');

$r1->record(new TestObject);
isa_ok($r1->record, 'TestObject');

$r1->site(new TestObject);
isa_ok($r1->site, 'TestObject');

my $r2 = CUFTS::Result->new('http://www.newurl.com/');
isa_ok($r2, 'CUFTS::Result');
is($r2->url, 'http://www.newurl.com/');


package TestObject;
sub new {
      return bless {}, shift;
}

1;