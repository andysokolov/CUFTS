package CUFTS::MaintTool::C::ERM::Provider;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::ERMProviders;

my $form_validate = {
    required => [
        qw(
            key
        )
    ],
    optional => [
        qw(
            submit 
            cancel

            provider_name
            local_provider_name

            admin_user
            admin_password
            admin_url
            support_url

            stats_available
            stats_url
            stats_frequency
            stats_delivery
            stats_counter
            stats_user
            stats_password
            stats_notes

            provider_contact
            provider_notes

            support_email
            support_phone
            knowledgebase
            customer_number
        )
    ],
    filters  => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_new = {
    required => [ qw( key ) ],
    optional => [ qw( save cancel ) ],
    filters  => ['trim'],
    missing_optional_valid => 1,
};

sub default : Private {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{submit} ) {
        my $id = $c->req->params->{provider};
        
        if ( $id eq 'new' ) {
            $c->redirect('/erm/provider/create');
        }
        else {
            $c->redirect("/erm/provider/edit/$id");
        }
    }

    my @records = CUFTS::DB::ERMProviders->search( { site => $c->stash->{current_site}->id }, { order_by => 'LOWER(key)' } );
    $c->stash->{records} = \@records;
    $c->stash->{template} = "erm/provider/find.tt";

    return 1;
}

# find_json - Gets a list of provider keys and ids starting with the passed in key.  This is used for ExtJS
#             combo box lookups, but could be expanded out to cover other uses.

sub find_json : Local {
    my ( $self, $c ) = @_;
    
    my @records;
    my $search = { site => $c->stash->{current_site}->id };

    if ( my $key = $c->req->params->{key} ) {
        $search->{key} = { ilike => "$key\%" };
    }

    @records = CUFTS::DB::ERMProviders->search( $search, { order_by => 'LOWER(key)' } );

    $c->stash->{json}->{rowcount} = scalar(@records);

    # TODO: Move this to the DB module later.
    $c->stash->{json}->{results}  = [ map { { id => $_->id, key => $_->key } } @records ];

    $c->forward('V::JSON');
}


sub create : Local {
    my ( $self, $c ) = @_;

    return $c->redirect('/erm/provider/') if $c->req->params->{cancel};

    if ( $c->req->params->{save} ) {

        $c->form( $form_validate_new );

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            my $erm;
            eval {
                $erm = CUFTS::DB::ERMProviders->create({
                    site => $c->stash->{current_site}->id,
                    key  => $c->form->{valid}->{key},
                });
            };

            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;

            return $c->redirect( "/erm/provider/edit/" . $erm->id );

        }

    }

    $c->stash->{template}  = "erm/provider/create.tt";

    $c->stash->{javascript_validate} = [ $c->convert_form_validate( 'erm-create', $form_validate_new, 'erm-create-' ) ];
}

# .. /erm/edit/main/123         (erm_main)
# .. /erm/edit/provider/423523   (erm_provider)

sub edit : Local {
    my ( $self, $c, $erm_id  ) = @_;

    $c->req->params->{cancel}
        and return $c->redirect('/erm/provider/');


    my $erm = CUFTS::DB::ERMProviders->search({
        id   => $erm_id,
        site => $c->stash->{current_site}->id,
    })->first;

    if ( !defined($erm) ) {
        die("Unable to find ERMProviders record: $erm_id for site " . $c->stash->{current_site}->id);
    }
    
    if ( $c->req->params->{submit} ) {

        $c->form( $form_validate );

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            eval {
                $erm->update_from_form( $c->form );
            };
        
            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;
            push @{ $c->stash->{results} }, 'ERM data updated.';
        }
    }

    $c->stash->{erm}       = $erm;
    $c->stash->{erm_id}    = $erm_id;
    $c->stash->{template}  = 'erm/provider/edit.tt';
    push @{$c->stash->{load_css}}, 'tabs.css';

    $c->stash->{javascript_validate} = [ $c->convert_form_validate( 'provider-form', $form_validate, 'erm-edit-input-' ) ];
}

sub delete : Local {
    my ( $self, $c ) = @_;
    
    $c->form({
        required => [ qw( erm_provider_id ) ],
        optional => [ qw( confirm cancel delete ) ],
    });

    unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

        if ( $c->form->{valid}->{cancel} ) {
            return $c->forward('/erm/provider/edit/' . $c->form->{valid}->{erm_provider_id} );
        }
    
        my $erm_provider = CUFTS::DB::ERMProviders->search({
            site => $c->stash->{current_site}->id,
            id => $c->form->{valid}->{erm_provider_id},
        })->first;

        my @erm_mains = CUFTS::DB::ERMMain->search( { provider => $erm_provider->id, site => $c->stash->{current_site}->id });

        $c->stash->{erm_mains} = \@erm_mains;
        $c->stash->{erm_provider} = $erm_provider;

        if ( defined($erm_provider) ) {

            if ( $c->form->{valid}->{confirm} ) {

                eval {
                
                    foreach my $erm_main ( @erm_mains ) {
                        $erm_main->provider( undef );
                        $erm_main->update();
                    }
                    
                    $erm_provider->delete();
                };

                if ($@) {
                    my $err = $@;
                    CUFTS::DB::DBI->dbi_rollback;
                    die($err);
                }
            
                CUFTS::DB::ERMMain->dbi_commit();
                $c->stash->{result} = "ERM provider record deleted.";
            }
        }
        else {
            $c->stash->{error} = "Unable to locate ERM provider record: " . $c->form->{valid}->{erm_provider_id};
        }

    }

    $c->stash->{template} = 'erm/provider/delete.tt';
}


1;
