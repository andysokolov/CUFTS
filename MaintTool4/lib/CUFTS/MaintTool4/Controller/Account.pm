package CUFTS::MaintTool4::Controller::Account;
use Moose;
use namespace::autoclean;

use String::Util qw(hascontent trim);

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::MaintTool::Controller::Account - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('/loggedin') :PathPart('account') :CaptureArgs(0) {}

sub edit :Chained('base') :PathPart('edit') :Args(0) {
    my ( $self, $c ) = @_;

    my $form_validate = {
        required => [ 'name', 'email' ],
        optional => [ 'phone', 'submit' ],
        filters  => [ 'trim' ],
        dependency_groups => { password => [ 'password', 'verify_password' ] },
        constraints       => {
            password => {
                constraint => sub { $_[0] eq $_[1] },
                params     => [ 'password', 'verify_password' ],
            },
        },
        missing_optional_valid => 1,
    };

    $c->stash->{field_messages} = {
        password => $c->loc('Passwords must match.')
    };

    if ( $c->has_param('submit') ) {

        $c->form($form_validate);
        $c->stash_params();

        unless ( $c->form_has_errors ) {

            # Set the 'password' field to the crypted value before saving if it is set
            if ( hascontent( $c->form->valid('password') ) ) {
                $c->form->valid( 'password', crypt($c->form->valid('password'), $c->user->key) );
            }

            eval {
                my $user = $c->user;
                $user->update_from_fv( $c->form );
            };
            if ($@) {
                $c->stash_errors($@);
            }
            else {
                $c->stash_results( $c->loc('Account data updated.') );
                delete $c->stash->{params}; # Use the updated record instead of any saved parameters
            }

        }
    }

    $c->stash->{account}  = $c->user;
    $c->stash->{template} = 'account/edit.tt';
}





=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
