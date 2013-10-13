use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::CRDB4';
use CUFTS::CRDB4::Controller::Resource;

ok( request('/resource')->is_success, 'Request should succeed' );
done_testing();
