#!/usr/bin/perl

use lib 'lib';

use CUFTS::CJDB::ILSAccount::III;

my $ils_account = CUFTS::CJDB::ILSAccount::III->new();
$ils_account->init('troy.lib.sfu.ca', 4500, '29345000771441');

warn(Dumper($ils_account));
