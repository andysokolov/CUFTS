package CUFTS::Schema::JobQueue;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ TimeStamp InflateColumn::DateTime InflateColumn::Serializer /);

__PACKAGE__->table('job_queue');

__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    info => {
        data_type => 'text',
        is_nullable => 0,
    },
    type => {
      data_type => 'varchar',
      is_nullable => 0,
      size => 128,
    },
    class => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 128,
    },
    account_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    priority => {
        data_type => 'integer',
        is_nullable => 0,
        default_value => 0,
    },
    site_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    local_resource_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    global_resource_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    status => {
        data_type => 'varchar',
        is_nullable => 1,
    },
    claimed_by => {
        data_type => 'varchar',
        is_nullable => 1,
    },
    completion => {
        data_type => 'integer',
        is_nullable => 1,
        default_value => 0,
    },
    data => {
        data_type => 'text',
        is_nullable => 1,
        serializer_class => 'JSON',
    },
    checkpoint_timestamp => {
        data_type => 'datetime',
        is_nullable => 1,
    },
    run_after => {
        data_type => 'datetime',
        is_nullable => 1,
    },
    reschedule_hours => {
        data_type => 'integer',
        is_nullable => 1,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
    },
    modified => {
        data_type => 'datetime',
        set_on_create => 1,
        set_on_update => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( site            => 'CUFTS::Schema::Sites',     'site_id',                    { join_type => 'left' } );
__PACKAGE__->belongs_to( account         => 'CUFTS::Schema::Accounts',  'account_id',                 { join_type => 'left' } );
__PACKAGE__->belongs_to( global_resource => 'CUFTS::Schema::GlobalResources', 'global_resource_id',   { join_type => 'left' } );
__PACKAGE__->belongs_to( local_resource  => 'CUFTS::Schema::LocalResources',  'local_resource_id',    { join_type => 'left' } );

__PACKAGE__->has_many( logs => 'CUFTS::Schema::JobQueueLog', 'job_id' );

sub update_checkpoint_timestamp {
    my $self = shift;
    $self->checkpoint_timestamp( $self->get_timestamp() );
}

1;
