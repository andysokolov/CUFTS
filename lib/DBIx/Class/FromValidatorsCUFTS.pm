package DBIx::Class::FromValidatorsCUFTS;
use strict;
use warnings;
use base 'DBIx::Class';
use Carp::Clan qw/^DBIx::Class/;
use Scalar::Util qw(blessed);

our $VERSION = '0.02';

{
    package DBIx::Class::ResultSet;

    use strict;
    use warnings;
    use Carp::Clan qw/^DBIx::Class/;
    use Scalar::Util qw(blessed);

    sub create_from_fv {
        my ($self, $results, $args) = @_;
        croak "pass me a form results object" unless blessed($results);
        croak "pass me a object which can call 'success' and 'valid'"
            unless $results->can('success') and $results->can('valid');
        croak "has error on form" unless $results->success;
        croak "args must be a hash ref" if defined $args && !ref $args eq 'HASH';
        $args ||= {};

        my $values = $results->valid();

        my %cols = ( %$args,
                   map  { $_ => $values->{$_} }
                   grep { exists $values->{$_} }
                   $self->result_source->columns );

        return $self->create(\%cols);
    }
}

sub update_from_fv {
    my ($self, $results, $args) = @_;
    croak "pass me a form results object" unless blessed($results);
    croak "pass me a object which can call 'success' and 'valid'"
        unless $results->can('success') and $results->can('valid');
    croak "has error on form" unless $results->success;
    croak "args must be a hash ref" if defined $args && !ref $args eq 'HASH';
    $args ||= {};

    my $values = $results->valid();

    my %cols = ( %$args,
           map  { $_ => $values->{$_} }
           grep { exists $values->{$_} }
           $self->result_source->columns );

    return $self->update(\%cols);
}

1;
__END__

=head1 NAME

DBIx::Class::FromValidatorsCUFTS - Update or Insert DBIx::Class data from Validators

=head1 SYNOPSIS

    # in your Schema class

    package
        Test::Schema;
    use base qw( DBIx::Class::Schema::Loader );

    __PACKAGE__->loader_options(
        components    => [ qw( FromValidatorsCUFTS ) ],
    );

    # in your Catalyst controller

    $c->form;
    $c->model('DBIC::Member')->create_from_fv($c->form,
        {
            # extra stuff
            name  => "woremacx",
            email => "woremacx at gmail",
        }
    );

    $c->model('DBIC::Member')->search({ name => "woremacx" })->first->update_from_fv($c->from,
        {
            # extra stuff
            email => 'woremacx plus vagina at gmail',
        }
    );

=head1 DESCRIPTION

DBIx::Class::FromValidatorsCUFTS allows you to Update or Insert DBIx::Class objects
from FormValidator::Simple or Data::FormValidator.

=head1 METHODS

=head2 create_from_fv

call DBIC's create method.

=head2 update_from_fv

call DBIC's update method.

=head1 AUTHOR

woremacx E<lt>woremacx at cpan dot orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBIx::Class::WebForm>, L<DBIx::Class::FromSledge>, L<FormValidator::Simple>, L<Catalyst::Plugin::FormValidator::Simple>

=cut
