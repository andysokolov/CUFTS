package CUFTS::MaintTool::C::ERM::SUSHI;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::ERMSushi;

my $form_validate = {
    required => [
        qw(
            name
        )
    ],
    optional => [
        qw(
            submit
            cancel

            requestor
            service_url
            interval_months
        )
    ],
    constraints => {
        interval_months => qr/^\d{1,2}$/,
    },
    filters  => ['trim'],
    missing_optional_valid => 1,
};

sub default : Private {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{submit} ) {
        my $id = $c->req->params->{source_id};

        if ( $id eq 'new' ) {
            $c->redirect('/erm/sushi/edit/new');
        }
        else {
            $c->redirect("/erm/sushi/edit/$id");
        }
    }

    my @records = CUFTS::DB::ERMSushi->search( site => $c->stash->{current_site}->id, { order_by => 'LOWER(name)' } );
    $c->stash->{records} = \@records;
    $c->stash->{template} = "erm/sushi/find.tt";

    return 1;
}

# find_json - Gets a list of source keys and ids starting with the passed in key.  This is used for ExtJS
#             combo box lookups, but could be expanded out to cover other uses.

sub find_json : Local {
    my ( $self, $c ) = @_;

    my @records;
    my $search = { site => $c->stash->{current_site}->id };

    if ( my $key = $c->req->params->{key} ) {
        $search->{key} = { ilike => "$key\%" };
    }

    @records = CUFTS::DB::ERMSushi->search( $search, { order_by => 'LOWER(key)' } );

    $c->stash->{json}->{rowcount} = scalar(@records);

    # TODO: Move this to the DB module later.
    $c->stash->{json}->{results}  = [ map { { id => $_->id, key => $_->key } } @records ];

    $c->forward('V::JSON');
}


sub edit : Local {
    my ( $self, $c, $sushi_id  ) = @_;

    $c->req->params->{cancel}
        and return $c->redirect('/erm/sushi/');

    my $sushi;
    if ( $sushi_id ne 'new' && int($sushi_id) > 0 ) {
        $sushi = CUFTS::DB::ERMSushi->search({
            id   => int($sushi_id),
            site => $c->stash->{current_site}->id,
        })->first;

        if ( !defined($sushi) ) {
            die("Unable to find SUSHI Sources record: $sushi_id for site " . $c->stash->{current_site}->id);
        }
    }

    if ( $c->req->params->{submit} ) {

        $c->form( $form_validate );

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            eval {
                if ( $sushi ) {
                    $sushi->update_from_form( $c->form );
                }
                else {
                    $c->form->valid->{site} = $c->stash->{current_site}->id;
                    $sushi = CUFTS::DB::ERMSushi->create_from_form( $c->form );
                    $sushi_id = $sushi->id;
                }
            };

            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;
            push @{ $c->stash->{results} }, 'ERM SUSHI Source updated.';
        }
    }

    $c->stash->{sushi}     = $sushi;
    $c->stash->{sushi_id}  = $sushi_id;
    $c->stash->{template}   = 'erm/sushi/edit.tt';
}

sub delete : Local {
    my ( $self, $c ) = @_;

    $c->form({
        required => [ qw( sushi_id ) ],
        optional => [ qw( confirm cancel delete ) ],
    });

    unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

        if ( $c->form->valid->{cancel} ) {
            return $c->redirect('/erm/sushi/edit/' . $c->form->valid->{sushi_id} );
        }

        my $sushi = CUFTS::DB::ERMSushi->search({
            site => $c->stash->{current_site}->id,
            id   => $c->form->valid->{sushi_id},
        })->first;

        my @counter_sources = CUFTS::DB::ERMCounterSources->search( { erm_sushi => $sushi->id, site => $c->stash->{current_site}->id });

        $c->stash->{counter_sources} = \@counter_sources;
        $c->stash->{sushi}           = $sushi;

        if ( defined($sushi) ) {

            if ( $c->form->valid->{confirm} ) {

                eval {

                    foreach my $source ( @counter_sources ) {
                        $source->erm_sushi( undef );
                        $source->update();
                    }

                    $sushi->delete();
                };

                if ($@) {
                    my $err = $@;
                    CUFTS::DB::DBI->dbi_rollback;
                    die($err);
                }

                CUFTS::DB::ERMMain->dbi_commit();
                $c->stash->{result} = "ERM SUSHI record deleted.";
            }
        }
        else {
            $c->stash->{error} = "Unable to locate ERM record: " . $c->form->valid->{sushi_id};
        }

    }

    $c->stash->{template} = 'erm/sushi/delete.tt';
}

1;
