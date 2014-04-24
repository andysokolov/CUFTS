package CUFTS::Schema::JobQueueLog;

use strict;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ TimeStamp /);

__PACKAGE__->table('job_queue_log');

__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    job_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    account_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    site_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    level => {
        data_type => 'integer',
        is_nullable => 0,
    },
    type => {
      data_type => 'varchar',
      is_nullable => 0,
      size => 128,
    },
    client_identifier => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 128,
    },
    message => {
        data_type => 'text',
        is_nullable => 1,
    },
    timestamp => {
        data_type => 'datetime',
        set_on_create => 1,
    }
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( job     => 'CUFTS::Schema::JobQueue',  'job_id' );
__PACKAGE__->belongs_to( site    => 'CUFTS::Schema::Sites',     'site_id',    { join_type => 'left' } );
__PACKAGE__->belongs_to( account => 'CUFTS::Schema::Accounts',  'account_id', { join_type => 'left' } );

1;
