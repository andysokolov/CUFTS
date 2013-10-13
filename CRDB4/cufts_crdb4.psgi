use strict;
use warnings;

use CUFTS::CRDB4;

my $app = CUFTS::CRDB4->apply_default_middlewares(CUFTS::CRDB4->psgi_app);
$app;

