use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CUFTS::CRDB4';
use CUFTS::CRDB4::Controller::Resource::Field;

ok( request('/resource/field')->is_success, 'Request should succeed' );
done_testing();
