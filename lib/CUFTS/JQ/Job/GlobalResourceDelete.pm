package CUFTS::JQ::Job::GlobalResourceDelete;

use Moose;

extends 'CUFTS::JQ::Job';

sub work {
    my $self = shift;

    $self->terminate_possible();

    my $resource = $self->work_schema->resultset('GlobalResources')->find( $self->global_resource_id );
    return $self->fail( 'Unable to load global resource id ' . $self->global_resource_id ) if !defined $resource;

    eval {
        $self->start();

        $self->work_schema->txn_do( sub {
            $self->log(0, 'debug', 'Loaded global resource: ' . $resource->name);
            $self->checkpoint( 0, 'Starting to delete title lists' );
            $resource->do_module( 'delete_title_list', $self->work_schema, $resource, 0, $self );
            $self->checkpoint( 99, 'Deleting local resources' );
            $resource->local_resources->delete();
            $self->checkpoint( 100, 'Deleting resource' );
            $resource->delete();
            $self->finish('Completed deleting resource and attached records');
        });
    };
    if ( $@ ) {
        if ( !$self->has_status('terminated') ) {
            $self->fail('Delete operation died: ' . $@);
        }
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
