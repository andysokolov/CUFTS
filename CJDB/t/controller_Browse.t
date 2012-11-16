use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::CJDB';
use CUFTS::CJDB::Controller::Browse;

ok( request('/browse')->is_success, 'Request should succeed' );
done_testing();
