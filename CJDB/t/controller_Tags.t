use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::CJDB';
use CUFTS::CJDB::Controller::Tags;

ok( request('/tags')->is_success, 'Request should succeed' );
done_testing();
