package CUFTS::JQ::Job::Test;

use Moose;

extends 'CUFTS::JQ::Job';


sub work {
    my $self = shift;

    my $checkpoints = 5;

    foreach my $x ( 1 .. $checkpoints ) {
        sleep(10);
        $self->checkpoint( int( 100 / $checkpoints) * $x, "Did some work!" );
        return 0 if $self->check_terminate();
    }

    $self->finish();
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
