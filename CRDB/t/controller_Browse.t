use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'CUFTS::CRDB' }
BEGIN { use_ok 'CUFTS::CRDB::Controller::Browse' }

ok( request('/browse')->is_success, 'Request should succeed' );


