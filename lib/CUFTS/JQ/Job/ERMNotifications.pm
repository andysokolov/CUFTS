package CUFTS::JQ::Job::ERMNotifications;

use Moose;

extends 'CUFTS::JQ::Job';




sub work {
    my $self = shift;


    $self->finish();
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
