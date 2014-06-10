use strict;
use warnings;

use IO::File;

use Test::More tests => 43;

use Test::DBIx::Class {
    schema_class => 'CUFTS::Schema',
    connect_info => [ 'dbi:Pg:dbname=CUFTStesting','CUFTStesting','', { quote_names => 1 } ],
    force_drop_table  => 1,
    fail_on_schema_break => 1,
};

my $job_schema  = Schema;
my $work_schema = $job_schema->clone->connect( 'dbi:Pg:dbname=CUFTStesting','CUFTStesting','', { quote_names => 1 } );

my $timestamp = $job_schema->get_now();
like($timestamp, qr/^[-\d]+\s[-\.:\d]+$/, 'timestamp as extra check that TestDatabase loaded');

my $site = $job_schema->resultset('Sites')->create({
    name   => 'Test University',
    active => 'true',
});

my $account = $job_schema->resultset('Accounts')->create({
    key      => 'test',
    email    => 'test@test.com',
    password => 'password',
    name     => 'Test Account',
    active   => 'true',
});

my $global_resource = $job_schema->resultset('GlobalResources')->create({
    name          => 'Test Global Resource 1',
    key           => 'global_resource_1',
    resource_type => { type => 'Test Type 1' },
    provider      => 'Test Provider',
    module        => 'Wiley',
    active        => 't',
});

my $local_resource = $job_schema->resultset('LocalResources')->create({
    name          => 'Test Local Resource 1',
    site          => $site->id,
    resource_type => { type => 'Test Type 1' },
    provider      => 'Test Provider',
    module        => 'Wiley',
    active        => 't',
});

use_ok( 'CUFTS::JQ::Client' );

my $client = CUFTS::JQ::Client->new(
    job_schema  => $job_schema,
    work_schema => $work_schema,
    log_fh      => IO::File->new('/tmp/job_queue_test', '>'),
    job_log_dir => '/tmp/jobs',
);
isa_ok($client, 'CUFTS::JQ::Client', 'created a JQ client');

# Purposely fail at adding a job due to missing required fields

my $job_fail = $client->add_job({
    class      => 'tests',
    site_id    => $site->id,
    account_id => $account->id,
    data       => { resource => 1234 },
});
ok( !defined $job_fail, 'correctly failed to create a job with missing data');
ok( $client->has_errors, 'client has error flags');
isa_ok( $client->errors, 'ARRAY', 'errors is an ARRAYREF');

# Clear errors

$client->clear_errors();
ok( !$client->has_errors, 'client cleared error flags');

# Add a working job

my $job1 = $client->add_job({
    info               => 'Test job 1 added by job_queue_client.t',
    type               => 'tests',
    class              => 'test',
    site_id            => $site->id,
    account_id         => $account->id,
    global_resource_id => $global_resource->id,
    data               => { note => 'data note' },
});
isa_ok($job1, 'CUFTS::JQ::Job', 'created a new JQ job1');

# And a second

my $job2 = $client->add_job({
    info               => 'Test job 2 added by job_queue_client.t',
    type               => 'tests',
    class              => 'test',
    site_id            => $site->id,
    priority           => 100,
    account_id         => $account->id,
    global_resource_id => $global_resource->id,
});
isa_ok($job2, 'CUFTS::JQ::Job', 'created a new JQ job2');

# And a third with a different type

my $job3 = $client->add_job({
    info              => 'Test job 3 added by job_queue_client.t',
    type              => 'tests2',
    class             => 'test',
    site_id           => $site->id,
    account_id        => $account->id,
    local_resource_id => $local_resource->id,
    data              => { note => 'data note' },
});
isa_ok($job3, 'CUFTS::JQ::Job', 'created a new JQ job2');


# Load jobs by id

my $job1_match = $client->get_job( $job1->id );
is( $job1_match->id, $job1->id, 'loaded job 1 by id');
is( $job1_match->data->{note}, 'data note', 'data stored from passed in hashref');

my $job2_match = $client->get_job( $job2->id );
is( $job2_match->id, $job2->id, 'loaded job 2 by id');

isnt( $job1_match->info, $job2_match->info, 'jobs loaded were different');

# List jobs

my ( $jobs, $pager ) = $client->list_jobs();
is( scalar @$jobs, 3, 'listed three jobs' );
is( $jobs->[0]->id, $job2->id, 'higher priority listed first');
is( $pager->total_entries, 3, 'pager matches results' );

( $jobs, $pager ) = $client->list_jobs({ type => 'tests' });
is( scalar @$jobs, 2, 'filtered jobs by type' );
is( $pager->total_entries, 2, 'pager matches results' );

# Claim next job, finish it, and check runnable jobs after

my $got_job = $client->claim_next_job();
isa_ok( $got_job, 'CUFTS::JQ::Job', 'claimed next job');
is( $got_job->id, $job2->id, 'claimed high priority job');
is( $got_job->status, 'claimed', 'claiming job sets claimed status');

$got_job->finish();

( $jobs, $pager ) = $client->list_runnable_jobs();
is( scalar @$jobs, 2, 'listed two runnable jobs left' );
is( $pager->total_entries, 2, 'pager matches results' );

# Test that defaults from the client cascade to the created jobs when appropriate

my $client_defaults = CUFTS::JQ::Client->new(
    job_schema  => $job_schema,
    work_schema => $work_schema,
    account_id  => $account->id,
    site_id     => $site->id,
    log_fh      => IO::File->new('/tmp/job_queue_test', '>'),
    job_log_dir => '/tmp/jobs',
);
isa_ok($client_defaults, 'CUFTS::JQ::Client', 'created a JQ client');
is( $client_defaults->account_id,  $account->id, 'default account set' );
is( $client_defaults->site_id,     $site->id,    'default site set' );

my $job4 = $client_defaults->add_job({
    info               => 'Test job 4 added by job_queue_client.t',
    type               => 'tests2',
    class              => 'global resource delete',
    global_resource_id => $global_resource->id,
    data               => { note => 'Here\'s another data note!' },
});
isa_ok($job4, 'CUFTS::JQ::Job', 'created a new JQ job4');

# Test moving through valid statuses

is( $job1->status, 'new', 'new status');
$job1->status('runnable');
is( $job1->status, 'runnable', 'runnable status');
$job1->status('claimed');
is( $job1->status, 'claimed', 'claimed status');
$job1->status('working');
is( $job1->status, 'working', 'working status');
$job1->status('completed');
is( $job1->status, 'completed', 'completed status');
$job1->status('terminate');
is( $job1->status, 'terminate', 'terminate status');
$job1->status('terminated');
is( $job1->status, 'terminated', 'terminated status');
$job1->status('failed');
is( $job1->status, 'failed', 'failed status');

$job1->status('new');
$job1->start();
is( $job1->status, 'working', 'start() moves status to working');

$job1->finish();
is( $job1->status, 'completed', 'finish() moves status to completed');

$job1->fail();
is( $job1->status, 'failed', 'fail() moves status to failed');


$job1->status('working');
$job1->terminate();
is( $job1->status, 'terminate', 'terminate() moves status to terminate');

eval {
    $job1->terminate_possible();
};
is( $job1->status, 'terminated', 'do_terminate() moves status to terminated');

my $job_to_terminate = $client->add_job({
    info               => 'Test job terminate added by job_queue_client.t',
    type               => 'tests',
    class              => 'test',
    site_id            => $site->id,
    priority           => 100,
    account_id         => $account->id,
});
isa_ok($job_to_terminate, 'CUFTS::JQ::Job', 'created a new JQ job2');
$job_to_terminate->terminate();
is( $job_to_terminate->status, 'terminated', 'terminatation before running' );



# Test transaction isolation

##
## !!!! The following type of code works in practice, but is failing here. Maybe this DBIC DBI doesn't give truly separate schemas?
##

# my $job5 = $client_defaults->add_job({
#     info               => 'Test job 5 added by job_queue_client.t',
#     type               => 'test isolation',
#     class              => 'test',
# });
# isa_ok($job5, 'CUFTS::JQ::Job', 'created a new JQ job4');
#
# $job5->start();
# eval {
#     $job5->work_schema->txn_do( sub {
#         $job5->work_schema->resultset('GlobalResources')->delete;
#         $job5->checkpoint( 50, 'In the middle of fake work before dying.');
#         is( $job_schema->resultset('JobQueueLog')->search({ job_id => $job5->id })->count(), 3, 'log entry exists during transaction' );
#         is( $work_schema->resultset('GlobalResources')->count(), 0, 'delete of global resources during transaction' );
#         die('Do not commit!');
#     });
# };
# $job5->fail();
#
# is( $job5->status, 'failed', 'proper fail after transaction isolation test');
# isnt( $work_schema->resultset('GlobalResources')->count(), 0, 'rolled back delete of global resources' );
# is( $job_schema->resultset('JobQueueLog')->search({ job_id => $job5->id })->count(), 4, 'log entry saved through job schema during rollback' );




1;
