package CUFTS::MaintTool::C::ERM::Provider;

use strict;
use base 'Catalyst::Base';

use CUFTS::DB::ERMProviders;
use CUFTS::Util::Simple;

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

# find_json - Gets a list of license keys and ids starting with the passed in key.  This is used for ExtJS
#             combo box lookups, but could be expanded out to cover other uses.

sub find_json : Local {
    my ( $self, $c )  = @_;

    my $query = $c->req->parameters;
    foreach my $key ( keys( %$query ) ) {
        my $value = $query->{$key};
        if ( is_empty_string($value) ) {
            delete $query->{$key};
        }
    }

    $query->{site} = $c->stash->{current_site}->id;

    my $URI = URI->new();
    $URI->query_form( $query );
    $c->session->{last_erm_provider_find_query} = $URI->query;

    $self->_find($c);

    $c->forward('V::JSON');
}


sub _find : Local {
    my ( $self, $c ) = @_;

    my @valid_bool_params = qw(
        stats_available
    );

    my $params = $c->req->params;
    my $options = {
        order_by => 'LOWER(key)',
    };
    my ( $offset, $rows );


    if ( defined($params->{start}) || defined($params->{limit}) ) {
        $options->{offset} = $params->{start} || 0;
        $options->{rows}   = $params->{limit} || 25;
    }

    my $search = { site => $c->stash->{current_site}->id };

    if ( my $key = $c->req->params->{key} ) {
        $key =~ s/(%_\?)/\\$1/gsx;
        $search->{key} = { ilike => "\%$key\%" };
    }
    elsif ( my $key_start = $c->req->params->{key_start} ) {
        $key_start =~ s/(%_\?)/\\$1/gsx;
        $search->{key} = { ilike => "$key_start\%" };
    }

    if ( my $filter = $c->req->params->{filter} ) {
        $filter =~ s/(%_\?)/\\$1/gsx;
        $search->{'-or'} = {
            'key'                   => { ilike => "\%$filter\%" },
            'provider_name'         => { ilike => "\%$filter\%" },
            'local_provider_name'   => { ilike => "\%$filter\%" },
            'provider_notes'        => { ilike => "\%$filter\%" },
            'customer_number'       => { ilike => "\%$filter\%" },
        }
    }

    foreach my $param ( keys %$params ) {
        next if !grep { $param eq $_ } @valid_bool_params;
        my $value = $params->{$param};
        next if is_empty_string($value);
        $search->{$param} = $value;
    }

    my @records = CUFTS::DB::ERMProviders->search( $search, $options );
    $c->stash->{json}->{rowcount} = CUFTS::DB::ERMProviders->count( $search );

    # TODO: Move this to the DB module later.
    $c->stash->{json}->{results}  = [ map { { id => $_->id, key => $_->key } } @records ];
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

sub clone : Local {
    my ( $self, $c ) = @_;

    $c->form({
        required => [ qw( erm_provider_id ) ],
        optional => [ qw( confirm cancel delete clone ) ],
    });

    unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

        if ( $c->form->{valid}->{cancel} ) {
            return $c->redirect('/erm/provider/edit/' . $c->form->{valid}->{erm_provider_id} );
        }

        my $erm_provider = CUFTS::DB::ERMProviders->search({
            site => $c->stash->{current_site}->id,
            id   => $c->form->{valid}->{erm_provider_id},
        })->first;

        if ( defined($erm_provider) ) {

            $c->stash->{erm_provider} = $erm_provider;
            if ( $c->form->{valid}->{confirm} ) {

                my $clone;
                eval {
                    $clone = $erm_provider->clone();
                };

                if ($@) {
                    my $err = $@;
                    CUFTS::DB::DBI->dbi_rollback;
                    die($err);
                }

                CUFTS::DB::ERMProviders->dbi_commit();
                return $c->redirect('/erm/provider/edit/' . $clone->id );
            }
        }
        else {
            $c->stash->{error} = "Unable to locate ERM record: " . $c->form->{valid}->{erm_provider_id};
        }

    }

    $c->stash->{template} = 'erm/provider/clone.tt';
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

# Handle selected records for the ExtJS search interface

sub selected_json : Local {
    my ( $self, $c ) = @_;

    my @json_resources;
    my $current_site_id = $c->stash->{current_site}->id;

    if ( $c->session->{selected_erm_provider} && scalar( @{$c->session->{selected_erm_provider}} ) ) {
        my @resources = CUFTS::DB::ERMProviders->search(
            {
                id => { '-in' => $c->session->{selected_erm_provider} },
                site => $current_site_id,
            },
            {
                order_by => 'LOWER(key)'
            }
        );

        foreach my $resource ( @resources ) {
            if ( defined($resource) ) {
                push @json_resources, {
                    id                => $resource->id,
                    key               => $resource->key,
                };
            }
        }
    }

    $c->stash->{json}->{rowcount} = scalar(@json_resources);
    $c->stash->{json}->{results}  = \@json_resources;

    $c->forward('V::JSON');
}


sub selected_add : Local {
    my ( $self, $c ) = @_;

    if ( !$c->session->{selected_erm_provider} ) {
        $c->session->{selected_erm_provider} = [];
    }
    my $new = $c->req->params->{ids};
    if ( ref($new) ne 'ARRAY' ) {
        $new = [$new];
    }
    @{$c->session->{selected_erm_provider}} = List::MoreUtils::uniq( ( @{$c->session->{selected_erm_provider}}, @$new ) );

    $c->forward('selected_json');
}

sub selected_add_all : Local {
    my ( $self, $c ) = @_;

    $self->_find($c);
    $c->session->{selected_erm_provider} = [ List::MoreUtils::uniq( ( @{$c->session->{selected_erm_provider}}, map { $_->{id} } @{$c->stash->{json}->{results}} ) ) ];

    $c->forward('selected_json');
}

sub selected_remove : Local {
    my ( $self, $c ) = @_;

    if ( !$c->session->{selected_erm_provider} ) {
        $c->session->{selected_erm_provider} = [];
    }
    my $delete = $c->req->params->{ids};
    if ( ref($delete) ne 'ARRAY' ) {
        $delete = [$delete];
    }
    my %to_delete = map { $_ => 1 } @$delete;
    @{$c->session->{selected_erm_provider}} = grep { not exists( $to_delete{$_} ) } @{$c->session->{selected_erm_provider}};

    $c->forward('selected_json');
}

sub selected_clear : Local {
    my ( $self, $c ) = @_;
    $c->session->{selected_erm_provider} = [];
    $c->forward('selected_json');
}


sub selected_export : Local {
    my ( $self, $c ) = @_;

    $c->form({ optional => [ qw( format do_export columns ) ] });

    if ( !$c->request->params->{do_export} || !$c->request->params->{columns} || !$c->request->params->{format} ) {
        $c->stash->{template} = 'erm/license/export_columns.tt';
        return;
    }

    if ( !$c->session->{selected_erm_provider} ) {
        $c->session->{selected_erm_provider} = [];
    }

    my $format = $c->stash->{format} = $c->request->params->{format};

    my @erm_records = CUFTS::DB::ERMProviders->search( { site => $c->stash->{current_site}->id, id => { '-in' => $c->session->{selected_erm_provider} } }, { order_by => 'LOWER(key)' } );
    my @flattened_records = map { $_->to_hash } @erm_records;

    my @columns = qw(
        id
        key
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
    );

    my $submitted_columns = $c->request->params->{columns};
    if ( !ref($submitted_columns) eq 'ARRAY' ) {
        $submitted_columns = [$submitted_columns];
    }
    my %submitted_columns;
    foreach my $sc (@$submitted_columns) {
        $submitted_columns{$sc} = 1;
    }

    @columns = grep { $submitted_columns{$_} } @columns;

    if ( $format eq 'json' ) {

        my @cleaned_records;
        foreach my $record (@flattened_records) {
            push @cleaned_records, {  map { ($_, $record->{$_}) } @columns };
        }

        $c->stash->{json} = \@cleaned_records;
        $c->forward('V::JSON');
    }
    elsif ( $format eq 'csv' ) {
        $c->stash->{csv}->{data} = [ \@columns ];
        foreach my $record ( @flattened_records ) {
            push @{$c->stash->{csv}->{data}}, [ map { $record->{$_} } @columns ];
        }
        $c->forward('V::CSV');
    }
    else {
        $c->stash->{columns}  = \@columns;
        $c->stash->{records}  = \@flattened_records;
        $c->stash->{template} = 'erm/license/export_html.tt';
    }
}


1;
