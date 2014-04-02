use strict;

# Test some of the internals of the title list loading system

use Data::Dumper;

use Test::More tests => 7;

use Test::DBIx::Class {
    schema_class => 'CUFTS::Schema',
    connect_info => [ 'dbi:Pg:dbname=CUFTStesting','CUFTStesting','', { quote_names => 1 } ],
    force_drop_table  => 1,
    fail_on_schema_break => 1,
};

BEGIN {
    use_ok('CUFTS::Config');
    use_ok('CUFTS::Resources');
    use_ok('CUFTS::Resources::Wiley');
}

use FindBin;
my $test_file_dir = "$FindBin::Bin/data";

my $schema = Schema;
my $timestamp = $schema->get_now();
like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp as extra check that TestDatabase loaded');

# Support records for the next set of created records

my $site = $schema->resultset('Sites')->create({
    name => 'Test University',
    active => 'true',
});

my $resource1 = $schema->resultset('GlobalResources')->create({
    name          => 'Test Global Resource 1',
    key           => 'global_resource_1',
    resource_type => { type => 'Test Type 1' },
    provider      => 'Test Provider',
    module        => 'Wiley',
    active        => 't',
});

my $resource2 = $schema->resultset('GlobalResources')->create({
    name          => 'Test Global Resource 2',
    key           => 'global_resource_2',
    resource_type => { type => 'Test Type 2' },
    provider      => 'Test Provider',
    module        => 'Wiley',
    active        => 't',
});

$resource1->add_to_global_journals({
    title         => 'Aging cell',
    issn          => '14749718',
    e_issn        => '14749726',
    ft_start_date => '2002-10-01',
    ft_end_date   => '2010-10-02',
    journal_url   => 'http://onlinelibrary.wiley.com/journal/10.1111/(ISSN)1474-9726',
    vol_ft_start  => 1,
    iss_ft_start  => 1,
});

$resource1->add_to_global_journals({
    title         => 'Annals of Clinical and Translational Neurology',
    e_issn        => '23289503',
    ft_start_date => '2013-12-01',
    journal_url   => 'http://onlinelibrary.wiley.com/journal/10.1002/(ISSN)2328-9503',
    vol_ft_start  => 1,
});

$resource1->add_to_global_journals({
	title         => 'To Be Deleted',
	e_issn        => '12341234',
	ft_start_date => '2013-12-01',
	journal_url   => 'http://onlinelibrary.wiley.com/journal/10.1002/(ISSN)1234-1234',
});


is( $schema->resultset('GlobalJournals')->count, 3, 'created journal');

# This is very hackish.. Replace all the custom load methods with the ones from CUFTS::Resources

my $module = $resource1->module;
$module = CUFTS::Resources::__module_name($module);

is( $module, 'CUFTS::Resources::Wiley', 'got correct module name');

no strict 'refs';
*{"${module}::title_list_column_delimiter"}   = *CUFTS::Resources::title_list_column_delimiter;
*{"${module}::title_list_field_map"}          = *CUFTS::Resources::title_list_field_map;
*{"${module}::title_list_skip_lines_count"}   = *CUFTS::Resources::title_list_skip_lines_count;
*{"${module}::title_list_skip_blank_lines"}   = *CUFTS::Resources::title_list_skip_blank_lines;
*{"${module}::title_list_extra_requires"}     = *CUFTS::Resources::title_list_extra_requires;

*{"${module}::preprocess_file"}               = *CUFTS::Resources::preprocess_file;
*{"${module}::title_list_get_field_headings"} = *CUFTS::Resources::title_list_get_field_headings;
*{"${module}::skip_record"}                   = *CUFTS::Resources::skip_record;
*{"${module}::title_list_skip_lines"}         = *CUFTS::Resources::title_list_skip_lines;
*{"${module}::title_list_read_row"}           = *CUFTS::Resources::title_list_read_row;
*{"${module}::title_list_parse_row"}          = *CUFTS::Resources::title_list_parse_row;
*{"${module}::title_list_split_row"}          = *CUFTS::Resources::title_list_split_row;
*{"${module}::title_list_skip_comment_line"}  = *CUFTS::Resources::title_list_skip_comment_line;
*{"${module}::clean_data"}                    = *CUFTS::Resources::clean_data;

my $results = $module->load_global_title_list($schema, $resource1, "${test_file_dir}/title_list_test1.txt");

delete $results->{timestamp};
is_deeply( $results,
    {
        'error_count'                    => 0,
        'processed_count'                => 9,
        'errors'                         => undef,
        'deleted_count'                  => 1,
        'new_count'                      => 7,
        'modified_count'                 => 1,
        'local_resources_auto_activated' => 0
    }, 'results summary is as expected'
);
