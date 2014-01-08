package CUFTS::Result;

use strict;

use Moose;

has 'url' => (
    isa => 'Str',
    is  => 'rw',
);

has 'atitle' => (
    isa => 'Str',
    is  => 'rw',
);

has 'record' => (
    isa => 'Object',
    is  => 'rw',
);

has 'site' => (
    isa => 'Object',
    is  => 'rw',
);


##
## If there's only a scalar passed in, then treat it as the url field.
##

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( url => $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
};

1;
