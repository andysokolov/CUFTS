package CUFTS::MaintTool::C::Account;

use strict;
use base 'Catalyst::Base';

my $form_validate = {
    required => ['name'],
    optional => [ 'email', 'phone', 'submit', 'cancel' ],
    filters  => ['trim'],
    dependency_groups => { password => [ 'password', 'verify_password' ] },
    constraints       => {
        password => {
            constraint => sub { $_[0] eq $_[1] },
            params => [ 'password', 'verify_password' ],
        },
    },
    missing_optional_valid => 1,
};

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->stash->{header_section} = 'Account Settings';

    return 1;
}

sub edit : Local {
    my ( $self, $c, $account_id ) = @_;

    $c->req->params->{cancel}
        and return $c->redirect('/main');

    if ( $c->req->params->{submit} ) {

        $c->form($form_validate);

        if ( defined( $c->form->{valid}->{password} ) ) {
            $c->form->{valid}->{password} = crypt $c->form->{valid}->{password}, $c->stash->{current_account}->{key};
        }
            
        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
            $c->stash->{current_account}->update_from_form( $c->form );
            CUFTS::DB::DBI->dbi_commit;
            return $c->redirect('/main');
        }
    }

    $c->stash->{template} = 'account/edit.tt';
}

1;
