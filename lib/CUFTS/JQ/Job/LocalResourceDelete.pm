package CUFTS::JQ::Job::LocalResourceDelete;

use Moose;

extends 'CUFTS::JQ::Job';

sub work {
    my $self = shift;

    $self->terminate_possible();

    my $resource = $self->work_schema->resultset('LocalResources')->find({ id =>  $self->local_resource_id });
    return $self->fail( 'Unable to load local resource id ' . $self->local_resource_id ) if !defined $resource;

    eval {
        $self->start();

        $self->work_schema->txn_do( sub {
            $self->log(0, 'debug', 'Loaded local resource: ' . $resource->name);
            $self->checkpoint( 0, 'Starting to delete title list' );
            $resource->do_module( 'delete_title_list', $self->work_schema, $resource, 1, $self );
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
