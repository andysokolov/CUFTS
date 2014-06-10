use strict;

use Test::More tests => 20;

# use Test::DBIx::Class {
# 	schema_class => 'CUFTS::Schema',
# 	connect_info => ['dbi:Pg:dbname=CUFTStesting','CUFTStesting','', { quote_names => 1 }],
# 	force_drop_table  => 1,
# 	fail_on_schema_break => 1,
# };

# my $schema = Schema;
# my $timestamp = $schema->get_now();
# like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp as extra check that TestDatabase loaded');

use CUFTS::Config;
my $schema = CUFTS::Config::get_schema();


BEGIN {
	use_ok('MARC::Record');
	use_ok('CUFTS::CJDB::Util');
}

my $marc_record = new MARC::Record();
isa_ok($marc_record, 'MARC::Record');

$marc_record->leader('00000nas  22001577a 4500');
$marc_record->append_fields(
    MARC::Field->new( '005', '20140604001146.0' ),
    MARC::Field->new( '022', '', '', 'a', '2105-2581' ),
    MARC::Field->new( '022', '', '', 'a', '0013-0559' ),
    MARC::Field->new( '035', '', '', 's', 'CJDB411617' ),
    MARC::Field->new( '245', '', '', 'a', 'Economie Rurale' ),
    MARC::Field->new( '246', '', '', 'a', 'Économie rurale' ),
    MARC::Field->new( '229', '', '', 'a', 'Économie rurale' ),
    MARC::Field->new( '590', '', '', 'a', 'Available full text from CAIRN - Bouquet General - CAIRN: 2007-01-01 (i.297) to current' ),
);

is( $marc_record->title, 'Economie Rurale', 'new marc record title checked' );
is( $marc_record->subfield('246','a'), 'Économie rurale', 'new marc record title with diacritics' );

my $marc_binary = $marc_record->as_usmarc;
my $marc_record2 = MARC::Record->new_from_usmarc( $marc_binary );

isa_ok( $marc_record2, 'MARC::Record' );
is( $marc_record2->title, 'Economie Rurale', 'read marc record title checked' );
is( $marc_record2->subfield('246','a'), 'Économie rurale', 'read marc record title with diacritics' );

warn $marc_record->as_formatted();

my $marc_encoded = new MARC::Record();
isa_ok($marc_encoded, 'MARC::Record');

$marc_encoded->leader('00000nas  22001577a 4500');
$marc_encoded->append_fields(
	MARC::Field->new( '005', '20140604001146.0' ),
	MARC::Field->new( '022', '', '', 'a', '2105-2581' ),
	MARC::Field->new( '022', '', '', 'a', '0013-0559' ),
	MARC::Field->new( '035', '', '', 's', 'CJDB411617' ),
	MARC::Field->new( '245', '', '', 'a', CUFTS::CJDB::Util::latin1_to_marc8('Economie Rurale') ),
	MARC::Field->new( '246', '', '', 'a', CUFTS::CJDB::Util::latin1_to_marc8('Économie rurale') ),
	MARC::Field->new( '229', '', '', 'a', CUFTS::CJDB::Util::latin1_to_marc8('Économie rurale') ),
	MARC::Field->new( '590', '', '', 'a', CUFTS::CJDB::Util::latin1_to_marc8('Available full text from CAIRN - Bouquet General - CAIRN: 2007-01-01 (i.297) to current') ),
);

is( CUFTS::CJDB::Util::marc8_to_latin1($marc_encoded->title),               'Economie Rurale', 'new marc record title checked' );
is( CUFTS::CJDB::Util::marc8_to_latin1($marc_encoded->subfield('246','a')), 'Économie rurale', 'new marc record title with diacritics' );

my $marc_encoded_binary = $marc_encoded->as_usmarc;
my $marc_encoded2 = MARC::Record->new_from_usmarc( $marc_binary );

isa_ok( $marc_encoded2, 'MARC::Record' );
is( CUFTS::CJDB::Util::marc8_to_latin1($marc_encoded2->title),               'Economie Rurale', 'read marc record title checked' );
is( CUFTS::CJDB::Util::marc8_to_latin1($marc_encoded2->subfield('246','a')), 'Économie rurale', 'read marc record title with diacritics' );

warn $marc_encoded2->as_formatted();


my $marc_database = new MARC::Record();
isa_ok($marc_database, 'MARC::Record');

my $db_string = $schema->resultset('JournalsAuthTitles')->find(660944)->title;

$marc_database->leader('00000nas  22001577a 4500');
$marc_database->append_fields(
	MARC::Field->new( '005', '20140604001146.0' ),
	MARC::Field->new( '022', '', '', 'a', '2105-2581' ),
	MARC::Field->new( '022', '', '', 'a', '0013-0559' ),
	MARC::Field->new( '035', '', '', 's', 'CJDB411617' ),
	MARC::Field->new( '245', '', '', 'a', CUFTS::CJDB::Util::latin1_to_marc8('Economie Rurale') ),
	MARC::Field->new( '246', '', '', 'a', CUFTS::CJDB::Util::latin1_to_marc8($db_string) ),
	MARC::Field->new( '229', '', '', 'a', CUFTS::CJDB::Util::latin1_to_marc8($db_string) ),
	MARC::Field->new( '590', '', '', 'a', CUFTS::CJDB::Util::latin1_to_marc8('Available full text from CAIRN - Bouquet General - CAIRN: 2007-01-01 (i.297) to current') ),
);

is( CUFTS::CJDB::Util::marc8_to_latin1($marc_database->title),               'Economie Rurale', 'new marc record title checked' );
is( CUFTS::CJDB::Util::marc8_to_latin1($marc_database->subfield('246','a')), 'Économie rurale', 'new marc record title with diacritics' );

my $marc_database_binary = $marc_database->as_usmarc;
my $marc_database2 = MARC::Record->new_from_usmarc( $marc_binary );

isa_ok( $marc_database2, 'MARC::Record' );
is( CUFTS::CJDB::Util::marc8_to_latin1($marc_database2->title),               'Economie Rurale', 'read marc record title checked' );
is( CUFTS::CJDB::Util::marc8_to_latin1($marc_database2->subfield('246','a')), 'Économie rurale', 'read marc record title with diacritics' );

warn $marc_database2->as_formatted();



1;
