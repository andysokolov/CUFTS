package CUFTS::MaintTool::C::ERM::Main;

use strict;
use base 'Catalyst::Base';

use JSON::XS qw( encode_json );

use CUFTS::Util::Simple;
use DateTime;

use CUFTS::DB::ERMMain;
use CUFTS::DB::ERMMainLink;
use CUFTS::DB::ERMSubjectsMain;

use MARC::Record;
use List::MoreUtils;

my $form_validate = {
    required => [
        qw(
            key
            main_name
        )
    ],
    optional => [
        qw(
            submit
            cancel

            license
            provider
            vendor
            internal_name
            publisher
            url
            access
            resource_type
            resource_medium
            file_type
            description_brief
            description_full
            update_frequency
            coverage
            embargo_period
            pick_and_choose
            public
            public_list
            public_message
            proxy
            group_records
            subscription_status
            print_included
            active_alert
            print_equivalents
            marc_available
            marc_history
            marc_alert
            requirements
            maintenance
            title_list_url
            help_url
            status_url
            resolver_enabled
            refworks_compatible
            refworks_info_url
            user_documentation
            simultaneous_users
            subscription_type
            print_required
            subscription_notes
            subscription_ownership
            subscription_ownership_notes
            misc_notes
            issn
            isbn
            cancellation_cap
            cancellation_cap_notes

            cost
            invoice_amount
            currency
            pricing_model
            pricing_model_notes
            gst
            pst
            gst_amount
            pst_amount
            payment_status
            order_date
            contract_start
            contract_end
            original_term
            auto_renew
            renewal_notification
            notification_email
            notice_to_cancel
            requires_review
            review_by
            review_notes
            local_bib
            local_customer
            local_vendor
            local_vendor_code
            local_acquisitions
            local_fund
            journal_auth
            consortia
            consortia_notes
            date_cost_notes
            subscription
            price_cap
            license_start_date

            stats_available
            stats_url
            stats_frequency
            stats_delivery
            stats_counter
            stats_user
            stats_password
            stats_notes
            counter_stats

            open_access
            admin_subscription_no
            admin_user
            admin_password
            admin_url
            admin_notes
            support_url
            access_url
            public_account_needed
            public_user
            public_password
            training_user
            training_password
            marc_url
            ip_authentication
            referrer_authentication
            referrer_url
            openurl_compliant
            access_notes
            breaches
            alert
            alert_expiry
            
            provider_name
            local_provider_name
            provider_contact
            provider_notes
            support_email
            support_phone
            knowledgebase
            customer_number
            
            erm-edit-input-content_types
        )
    ],
    optional_regexp => qr/^erm-edit-input-/,
    constraints            => {
        contract_end       => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        contract_start     => qr/^\d{4}-\d{1,2}-\d{1,2}/,
        license_start_date => qr/^\d{4}-\d{1,2}-\d{1,2}/,
    },
    js_constraints => {
        contract_end       => { dateISO => 'true' },
        contract_start     => { dateISO => 'true' },
        license_start_date => { dateISO => 'true' },
    },
    filters                => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_new = {
    required => [ qw( key name ) ],
    optional => [ qw( cancel save ) ],
    filters  => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_new_file = {
    required => [
        qw(
            upload
            file_description
            file
        )
    ],
    optional => [],
    filters => ['trim'],
    missing_optional_valid => 1,
};


sub auto : Private {
    my ( $self, $c ) = @_;

    my @load_options = (
        [ 'resource_types',   'resource_type',   'CUFTS::DB::ERMResourceTypes' ],
        [ 'resource_mediums', 'resource_medium', 'CUFTS::DB::ERMResourceMediums' ],
        [ 'subjects',         'subject',         'CUFTS::DB::ERMSubjects' ],
        [ 'content_types',    'content_type',    'CUFTS::DB::ERMContentTypes' ],
        [ 'consortias',       'consortia',       'CUFTS::DB::ERMConsortia' ],
        [ 'pricing_models',   'pricing_model',   'CUFTS::DB::ERMPricingModels' ],
    );
    
    foreach my $load_option ( @load_options ) {

        my ( $type, $field, $model ) = @$load_option;
        my @records = $model->search( { site => $c->stash->{current_site}->id }, { order_by => $field } );

        $c->stash->{"${field}_options"} = \@records;

        $c->stash->{$type}           = { map { $_->id => $_->$field } @records };
        $c->stash->{"${type}_order"} = [ map { $_->id } @records ];

        $c->stash->{"${type}_ext"}   = encode_json( [ [undef, '&nbsp;' ], map { [$_->id, $_->$field ] } @records ] );
        $c->stash->{"${type}_json"}  = encode_json( $c->stash->{$type} );
        $c->stash->{"${field}_lookup"} = $c->stash->{$type};  # Alias for looking up when we have the "field" name rather than the type name.

    }

    return 1;
}



sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = "erm/main/find.tt";
}

sub selected_json : Local {
    my ( $self, $c ) = @_;
    
    my @json_resources;
    my $current_site_id = $c->stash->{current_site}->id;

    if ( $c->session->{selected_erm_main} && scalar( @{$c->session->{selected_erm_main}} ) ) {
        my @resources = CUFTS::DB::ERMMain->search(
            {
                id => { '-in' => $c->session->{selected_erm_main} },
                site => $current_site_id,
            },
            {
                sql_method => 'with_name',
                order_by => 'result_name'
            }
        );
        
        foreach my $resource ( @resources ) {
            if ( defined($resource) ) {
                push @json_resources, {
                    id                => $resource->id,
                    result_name       => $resource->name,
                    vendor            => $resource->vendor,
                    description_brief => $resource->description_brief,
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

    if ( !$c->session->{selected_erm_main} ) {
        $c->session->{selected_erm_main} = [];
    }
    my $new = $c->req->params->{ids};
    if ( ref($new) ne 'ARRAY' ) {
        $new = [$new];
    }
    @{$c->session->{selected_erm_main}} = List::MoreUtils::uniq( ( @{$c->session->{selected_erm_main}}, @$new ) );

    $c->forward('selected_json');
}

sub selected_add_all : Local {
    my ( $self, $c ) = @_;
    
    $self->_find($c);
    $c->session->{selected_erm_main} = [ List::MoreUtils::uniq( ( @{$c->session->{selected_erm_main}}, map { $_->{id} } @{$c->stash->{json}->{results}} ) ) ];

    $c->forward('selected_json');
}

sub selected_remove : Local {
    my ( $self, $c ) = @_;

    if ( !$c->session->{selected_erm_main} ) {
        $c->session->{selected_erm_main} = [];
    }
    my $delete = $c->req->params->{ids};
    if ( ref($delete) ne 'ARRAY' ) {
        $delete = [$delete];
    }
    my %to_delete = map { $_ => 1 } @$delete;
    @{$c->session->{selected_erm_main}} = grep { not exists( $to_delete{$_} ) } @{$c->session->{selected_erm_main}};
    
    $c->forward('selected_json');
}

sub selected_clear : Local {
    my ( $self, $c ) = @_;
    $c->session->{selected_erm_main} = [];
    $c->forward('selected_json');
}

sub selected_marc : Local {
    my ( $self, $c ) = @_;
    
    if ( !$c->session->{selected_erm_main} ) {
        $c->session->{selected_erm_main} = [];
    }
    
    my $MARC_dump;
    
    my @erm_records = CUFTS::DB::ERMMain->search( { site => $c->stash->{current_site}->id, id => { '-in' => $c->session->{selected_erm_main} } } );
    
    my $url_base = $CUFTS::Config::CRDB_URL . $c->stash->{current_site}->key . '/resource/';
    foreach my $erm_record ( @erm_records ) {
        if ( $c->req->params->{file} ) {
            $MARC_dump .= $erm_record->as_marc( $url_base )->as_usmarc();
        }
        else {
            $MARC_dump .= $erm_record->as_marc( $url_base )->as_formatted();
            $MARC_dump .= "\n----------------------------------------------\n";
        }

        # Update records from "on order" to "ordered" and add an order date if there isn't one.
        if ( $c->req->params->{update} ) {
            if ( $erm_record->subscription_status eq $c->stash->{subscription_statuses}->[3] ) {
                $erm_record->subscription_status( $c->stash->{subscription_statuses}->[4] );
            }
            if ( is_empty_string($erm_record->order_date ) ) {
                $erm_record->order_date( DateTime->now()->ymd );
            }
            $erm_record->update;
        }

    }

    CUFTS::DB::DBI->dbi_commit();  # Should be fine, even without any real updates

    if ( $c->req->params->{file} ) {
        $c->res->content_type( 'application/marc' );
        $c->res->headers->push_header( 'Content-Disposition' => 'attachment; filename="marc_records.mrc"' );
        $c->res->body( $MARC_dump );
    }
    else {
        $c->stash->{marc_dump_text} = $MARC_dump;
        $c->stash->{template} = 'erm/main/selected_marc.tt';
    }
}


sub selected_export : Local {
    my ( $self, $c, $format ) = @_;
    
    if ( !$c->session->{selected_erm_main} ) {
        $c->session->{selected_erm_main} = [];
    }
    
    my @erm_records = CUFTS::DB::ERMMain->search( { site => $c->stash->{current_site}->id, id => { '-in' => $c->session->{selected_erm_main} } }, { order_by => 'id' } );
    my @flattened_records = map { $_->to_hash } @erm_records;
    my @columns = sort ( CUFTS::DB::ERMMain->columns, qw( subjects content_types names ) );
    
    if ( $format eq 'json' ) {
        $c->stash->{json} = \@flattened_records;
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
        $c->stash->{template} = 'erm/main/export_html.tt';
    }
}



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
    $c->session->{last_erm_main_find_query} = $URI->query;

    $self->_find($c);

    $c->forward('V::JSON');
}

sub _find {
    my ( $self, $c )  = @_;
    
    my @valid_params = ( qw(
        consortia
        content_medium
        content_type
        keyword
        license
        name
        open_access
        provider
        public
        public_list
        publisher
        print_included
        resource_type
        subject
        subscription_status
        vendor
        ),
        'license.allows_ill',
        'license.allows_ereserves',
        'license.allows_coursepacks',
        'license.allows_walkins',
        'license.allows_distance_ed',
        'license.allows_archiving',
        'license.perpetual_access',
    );

    my $params = $c->req->params;
    my ( $offset, $rows );

    if ( defined($params->{start}) || defined($params->{limit}) ) {
        $offset = $params->{start} || 0;
        $rows   = $params->{limit} || 25;
    }
    
    my $search = {};
    foreach my $param ( keys %$params ) {
        next if !grep { $param eq $_ } @valid_params;
        my $value = $params->{$param};
        next if is_empty_string($value);
        $search->{$param} = $value;
    }
    
    my $count   = CUFTS::DB::ERMMain->facet_count(  $c->stash->{current_site}->id, $search );
    my $results = CUFTS::DB::ERMMain->facet_search( $c->stash->{current_site}->id, $search, 1, $offset, $rows );

    $c->stash->{json}->{rowcount} = $count;
    $c->stash->{json}->{results}  = $results;
    
    return;
}

sub ajax_details : Local {
    my ( $self, $c, $id ) = @_;

    my $erm_obj = CUFTS::DB::ERMMain->search( { id => $id, site => $c->stash->{current_site}->id } )->first;
    my $erm_hash = {
        subjects => [],
        content_types => [],
    };

    foreach my $column ( $erm_obj->columns() ) {
        next if grep { $_ eq $column } qw( license );
        $erm_hash->{$column} = $erm_obj->$column();
    }
    foreach my $column ( qw( consortia pricing_model resource_medium resource_type ) ) {
        if ( defined( $erm_hash->{$column} ) ) {
            $erm_hash->{$column} = $erm_obj->$column()->$column();
        }
    }

    my @subjects = $erm_obj->subjects();
    @{ $erm_hash->{subjects} } = map { $_->subject } sort { $a->subject cmp $b->subject } @subjects;

    my @content_types = $erm_obj->content_types;
    @{ $erm_hash->{content_types} } = map { $_->content_type } sort { $a->content_type cmp $b->content_type } @content_types;

    $c->stash->{json} = $erm_hash;
    $c->forward('V::JSON');
}


sub count_facets : Local {
    my ( $self, $c, @facets ) = @_;

    my $facets = {};
    while ( my ( $type, $data ) = splice( @facets, 0, 2 ) ) {
        $facets->{$type} = $data;
    }

    my $count = CUFTS::DB::ERMMain->facet_count( $c->stash->{current_site}->id, $facets );
    $c->res->body( '<span class="resources-facet-count">' . $count . '</span>' );
}



sub create : Local {
    my ( $self, $c ) = @_;

    return $c->redirect('/erm/main/') if $c->req->params->{cancel};
        
    if ( $c->req->params->{save} ) {

        $c->form( $form_validate_new );

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {

            my $erm;
            eval {
                $erm = CUFTS::DB::ERMMain->create({
                    site => $c->stash->{current_site}->id,
                    key  => $c->form->{valid}->{key},
                });
                
                $erm->main_name( $c->form->{valid}->{name} );

            };

            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;

            return $c->redirect( "/erm/main/edit/" . $erm->id );

        }

    }

    $c->stash->{template}  = "erm/main/create.tt";

    $c->stash->{javascript_validate} = [ $c->convert_form_validate( 'erm-create', $form_validate_new, 'erm-create-' ) ];
}



sub edit : Local {
    my ( $self, $c, $erm_id  ) = @_;

    $c->req->params->{cancel}
        and return $c->redirect('/erm/main/');

    # Get the ERM Main record for editing

    my $erm = CUFTS::DB::ERMMain->search({
        id   => $erm_id,
        site => $c->stash->{current_site}->id,
    })->first;

    if ( !defined($erm) ) {
        die("Unable to find ERMMain record: $erm_id for site " . $c->stash->{current_site}->id);
    }
    my %active_content_types = ( map { $_->id, 1 } $erm->content_types() );
    
    # Get ERM License records for linking
    
    my @erm_licenses = CUFTS::DB::ERMLicense->search( { site => $c->stash->{current_site}->id }, { order_by => 'LOWER(key)' } );
    $c->stash->{erm_licenses} = \@erm_licenses;

    # Get ERM Provider records for linking

    my @erm_providers = CUFTS::DB::ERMProviders->search( { site => $c->stash->{current_site}->id }, { order_by => 'LOWER(key)' } );
    $c->stash->{erm_providers} = \@erm_providers;
    
    if ( $c->req->params->{submit} ) {

        $c->form( $form_validate );

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
            eval {
                $erm->update_from_form( $c->form );

                $erm->main_name( $c->form->{valid}->{main_name} );

                # Handle content type changes

                my $content_types_values = $c->form->{valid}->{'erm-edit-input-content_types'};
                if ( !defined($content_types_values) ) {
                    $content_types_values = [];
                }
                elsif ( !ref($content_types_values) ) {
                    $content_types_values = [ $content_types_values ];
                }

                foreach my $content_type_id ( @{$content_types_values} ) {
                    if ( $active_content_types{$content_type_id} ) {
                        delete $active_content_types{$content_type_id};
                    }
                    else {
                        $erm->add_to_content_types( { content_type => $content_type_id } );
                    }
                }
                foreach my $content_type_id ( keys %active_content_types ) {
                    CUFTS::DB::ERMContentTypesMain->search( { erm_main => $erm_id, content_type => $content_type_id } )->delete_all;
                }

                # Handle subject changes
                
                foreach my $param ( keys %{ $c->form->{valid} } ) {

                    # Edit an existing subject

                    if ( $param =~ /^erm-edit-input-subject-(\d+)-subject$/ ) {
                        my $erm_main_subject_id    = $1;
                        my $erm_main_subject_value = $c->form->{valid}->{$param};

                        my $erm_subjects_main = CUFTS::DB::ERMSubjectsMain->search({
                            erm_main => $erm_id,   # include for security - don't grab other sites' subjects
                            id => $erm_main_subject_id,
                        })->first();
                    
                        if ( $erm_main_subject_value eq 'delete' ) {
                            $erm_subjects_main->delete();
                        }
                        else {
                            $erm_subjects_main->subject( $erm_main_subject_value );
                            $erm_subjects_main->rank( $c->form->{valid}->{"erm-edit-input-subject-${erm_main_subject_id}-rank"} );
                            $erm_subjects_main->description( $c->form->{valid}->{"erm-edit-input-subject-${erm_main_subject_id}-description"} );
                            $erm_subjects_main->update;
                        }

                    }
                    elsif ( $param =~ /^erm-edit-input-subject-add-subject-(\d+)$/ ) {
                        
                        # Add a new subject
                        
                        my $erm_add_id = $1;
                        my $subject_value = $c->form->{valid}->{$param};

                        if ( $subject_value ne 'delete' ) {

                            CUFTS::DB::ERMSubjectsMain->create({
                                erm_main    => $erm_id,
                                subject     => $subject_value,
                                rank        => $c->form->{valid}->{"erm-edit-input-subject-add-rank-${erm_add_id}"},
                                description => $c->form->{valid}->{"erm-edit-input-subject-add-description-${erm_add_id}"},
                            });

                        }

                    }
                    elsif ( $param =~ /^erm-edit-input-names-(\d+)$/ ) {

                        # Modify or delete an alternate name

                        my $erm_names_id    = $1;
                        my $erm_names_value = $c->form->{valid}->{$param};
                        
                        my $erm_name = CUFTS::DB::ERMNames->search({
                            erm_main => $erm_id,
                            id       => $erm_names_id,
                        })->first();
                        
                        if ( not_empty_string( $erm_names_value ) ) {
                            $erm_name->name( $erm_names_value );
                            $erm_name->update();
                        }
                        else {
                            $erm_name->delete();
                        }
                        
                    }
                    elsif ( $param =~ /^erm-edit-input-names-add-name-\d+$/ ) {

                        # Add a new alternate name
                        
                        my $name_value = $c->form->{valid}->{$param};
                        if ( not_empty_string($name_value) ) {

                            CUFTS::DB::ERMNames->create({
                                name     => $name_value,
                                erm_main => $erm_id,
                            });

                        }

                    }
                    elsif ( $param =~ /^erm-edit-input-keywords-(\d+)$/ ) {

                        # Modify or delete an alternate name

                        my $erm_keywords_id    = $1;
                        my $erm_keywords_value = $c->form->{valid}->{$param};
                        
                        my $erm_keyword = CUFTS::DB::ERMKeywords->search({
                            erm_main => $erm_id,
                            id       => $erm_keywords_id,
                        })->first();
                        
                        if ( not_empty_string( $erm_keywords_value ) ) {
                            $erm_keyword->keyword( $erm_keywords_value );
                            $erm_keyword->update();
                        }
                        else {
                            $erm_keyword->delete();
                        }
                        
                    }
                    elsif ( $param =~ /^erm-edit-input-keywords-add-keyword-\d+$/ ) {

                        # Add a new alternate name
                        
                        my $keyword_value = $c->form->{valid}->{$param};
                        if ( not_empty_string($keyword_value) ) {

                            CUFTS::DB::ERMKeywords->create({
                                keyword     => $keyword_value,
                                erm_main 	=> $erm_id,
                            });

                        }

                    }                
				}
            };
            
            if ($@) {
                my $err = $@;
                CUFTS::DB::DBI->dbi_rollback;
                die($err);
            }

            CUFTS::DB::DBI->dbi_commit;
            return $c->redirect( '/erm/main#?' . $c->session->{last_erm_main_find_query} );
            # push @{ $c->stash->{results} }, 'ERM data updated.';
        }
    }
    elsif ( $c->req->params->{upload} ) {
        
        $c->form( $form_validate_new_file );

        unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        
            my $upload = $c->req->upload('file');
            if ( $upload->filename !~ /\.([A-Za-z0-9]+)$/ ) {
                die("Could not determine file name extension.  Please upload files with a proper extension such as .jpg, .pdf, etc.");
            };
            my $ext = $1;

            my $file_rec = CUFTS::DB::ERMFiles->create({
                linked_id   => $erm_id,
                link_type   => 'm',
                description => $c->form->{valid}->{file_description},
                ext         => $ext,
            });

            my $filename = $c->path_to( 'root', 'static', 'erm_files', 'm', $file_rec->UUID . '.' . $ext );

            if ( defined($filename) ) {
                $upload->copy_to( $filename ) or
                    die("Error copying file: $!");
            }

            CUFTS::DB::DBI->commit();
            
        }
    }

    $c->stash->{license_record} = $erm->license;
    $c->stash->{provider_record} = $erm->provider;
    $c->stash->{main_files} = [ CUFTS::DB::ERMFiles->search({ linked_id => $erm_id, link_type => 'm' }) ];

    $c->stash->{active_content_types} = { map { $_->id, 1 } $erm->content_types() };
    $c->stash->{erm}       = $erm;
    $c->stash->{erm_id}    = $erm_id;
    $c->stash->{template}  = "erm/main/edit.tt";
    $c->stash->{javascript_validate} = [ $c->convert_form_validate( "main-form", $form_validate, 'erm-edit-input-' ) ];
    push( @{ $c->stash->{load_css} }, "tabs.css" );

    return 1;
}

sub delete : Local {
    my ( $self, $c ) = @_;
    
    $c->form({
        required => [ qw( erm_main_id ) ],
        optional => [ qw( confirm cancel delete ) ],
    });
    
    unless ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
    
        if ( $c->form->{valid}->{cancel} ) {
            return $c->forward('/erm/main/edit/' . $c->form->{valid}->{erm_main_id} );
        }
    
        my $erm_main = CUFTS::DB::ERMMain->search({
            site => $c->stash->{current_site}->id,
            id => $c->form->{valid}->{erm_main_id},
        })->first;
        
        my @erm_links = CUFTS::DB::ERMMainLink->search({
            erm_main => $erm_main->id
        });

        my ( @erm_links_resources, @erm_links_journals );
        
        foreach my $link ( @erm_links ) {
            if ( $link->link_type eq 'r' ) {
                push @erm_links_resources, $link;
            }
            elsif ( $link->link_type eq 'j' ) {
                push @erm_links_journals, $link;
            }
        }

        $c->stash->{erm_main} = $erm_main;
        $c->stash->{erm_links} = \@erm_links;
        $c->stash->{erm_links_journals} = \@erm_links_journals;
        $c->stash->{erm_links_resources} = \@erm_links_resources;

        if ( defined($erm_main) ) {

            if ( $c->form->{valid}->{confirm} ) {

                eval {
                    foreach my $erm_link ( @erm_links ) {
                        $erm_link->delete();
                    }
                    $erm_main->delete();
                };
                
                # TODO: Delete linked files

                if ($@) {
                    my $err = $@;
                    CUFTS::DB::DBI->dbi_rollback;
                    die($err);
                }
            
                CUFTS::DB::ERMMain->dbi_commit();
                $c->stash->{result} = "ERM Main record deleted.";
            }
        }
        else {
            $c->stash->{error} = "Unable to locate ERM record: " . $c->form->{valid}->{erm_main_id};
        }

    }

    $c->stash->{template} = 'erm/main/delete.tt';
}

sub link : Local {
    my ( $self, $c, $erm_main_id ) = @_;
    
    my $erm_main = CUFTS::DB::ERMMain->search( { id => $erm_main_id, site => $c->stash->{current_site}->id } )->first;
    
    if ( !defined($erm_main) ) {
        die("Could not find ERM Main record for this site: $erm_main_id");
    }
    
    $c->stash->{erm_main} = $erm_main;
    $c->stash->{template} = 'erm/main/link.tt';
}

sub link_ajax : Local {
    my ( $self, $c, $erm_main_id, $link_type, $action ) = @_;

    my $current_site_id = $c->stash->{current_site}->id;

    

    my $erm_main = CUFTS::DB::ERMMain->search( { id => $erm_main_id, site => $current_site_id } )->first;
    if ( !defined($erm_main) ) {
        $c->stash->{json} = {
            success => 'false',
            errorMessage => 'Could not find ERM Main record for this site: $erm_main_id',
        };
        return $c->forward('V::JSON');
    }

    my $ids = $c->req->params->{ids};
    if ( ref($ids) ne 'ARRAY' ) {
        $ids = [$ids];
    }

    if ( $link_type eq 'counter') {
        if ( $action eq 'clear' ) {
            foreach my $record ( CUFTS::DB::ERMCounterLinks->search({ erm_main => $erm_main_id }) ) {
                $record->delete();
            }
        }
        elsif ( $action eq 'remove' ) {
            foreach my $record ( CUFTS::DB::ERMCounterLinks->search({ erm_main => $erm_main_id, counter_source => { '-in' => $ids } }) ) {
                $record->delete();
            }
        }
        elsif ( $action eq 'add' ) {
            foreach my $id ( @$ids ) {
                my $record = CUFTS::DB::ERMCounterLinks->find_or_create({ erm_main => $erm_main_id, counter_source => $id });
#                $record->identifier();
#               $record->update();
            }
        }
        
    }
    else {
        my @records;
        if ( $link_type eq 'resource' ) {
            @records = $action eq 'clear'
                       ? CUFTS::DB::LocalResources->search( { erm_main => $erm_main_id, site => $current_site_id } )
                       : CUFTS::DB::LocalResources->search( { id => { '-in' => $ids }, site => $current_site_id } );
        }
        elsif ( $link_type eq 'journal' ) {
            @records = $action eq 'clear'
                       ? CUFTS::DB::LocalJournals->search( { erm_main => $erm_main_id, 'resource.site' => $current_site_id }, { 'join' => 'resource' } )
                       : CUFTS::DB::LocalJournals->search( { id => { '-in' => $ids }, 'resource.site' => $current_site_id }, { 'join' => 'resource' } );
        }
        foreach my $record ( @records ) {
            $record->erm_main( $action eq 'add' ? $erm_main_id : undef );
            $record->update();
        }
    }
    

    CUFTS::DB::DBI->dbi_commit();
    
    delete($c->req->params->{ids});
    $c->req->params->{erm_main} = $erm_main_id;
    if ( $link_type eq 'resource' ) {
        $c->forward( '/local/find_json' );
    }
    elsif ( $link_type eq 'journal' ) {
        $c->forward( '/local/titles/find_json' );
    }
    elsif ( $link_type eq 'counter') {
        $c->forward( '/erm/counter/find_json' );
    }
}

sub link_clear_ajax : Local {
    my ( $self, $c, $erm_main_id, $link_type ) = @_;

    my $current_site_id = $c->stash->{current_site}->id;

    my $erm_main = CUFTS::DB::ERMMain->search( { id => $erm_main_id, site => $current_site_id } )->first;
    if ( !defined($erm_main) ) {
        $c->stash->{json} = {
            success => 'false',
            errorMessage => 'Could not find ERM Main record for this site: $erm_main_id',
        };
        return $c->forward('V::JSON');
    }
    
    my $ids = $c->req->params->{ids};
    if ( ref($ids) ne 'ARRAY' ) {
        $ids = [$ids];
    }
    
    
    if ( $link_type eq 'resource' ) {
        
        foreach my $id ( @$ids ) {
            my $resource = CUFTS::DB::LocalResources->search( { id => $id, site => $current_site_id } )->first;
            if ( !defined($resource) ) {
                $c->stash->{json} = {
                    success => 'false',
                    errorMessage => 'Could not find resource record for this site: $id',
                };
                return $c->forward('V::JSON');
            }
            $resource->erm_main( $erm_main_id );
            $resource->update();
        }
    }

    CUFTS::DB::DBI->dbi_commit();
    
    delete($c->req->params->{ids});
    $c->req->params->{erm_main} = $erm_main_id;
    $c->forward( '/local/find_json' );
}


sub show_links_json : Local {
    my ( $self, $c ) = @_;
    
    my $erm_main_id = $c->req->params->{erm_main};
    my $link_type   = $c->req->params->{link_type};
    
    if ( $link_type eq 'resource') {
        my $resources = CUFTS::DB::LocalResources->search( { erm_main => $erm_main_id, site => $c->stash->{current_site}->id } );
        $c->stash->{json}->{rowcount} = scalar(@$resources);
        $c->stash->{json}->{results}  = $resources;
    }
    
}

sub unlink_json : Local {
    my ( $self, $c ) = @_;
    
    $c->form({
        required => [ qw( link_id link_type ) ],
    });

    if ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        $c->stash->{'json'}->{error} = 'Failed to validate request parameters';
        return $c->forward('V::JSON');
    }

    my $link_type = $c->form->{valid}->{link_type};
    my $link_id = $c->form->{valid}->{link_id};

    if ( $self->_verify_linking( $c, $link_type, $link_id ) ) {

        # Remove any existing links

        CUFTS::DB::ERMMainLink->search( { link_id => $link_id, link_type => $link_type } )->delete_all;
        CUFTS::DB::ERMMainLink->dbi_commit;
        
        $c->stash->{json} = { result => 'unlinked' };

    }
    
    $c->forward('V::JSON');
}

sub link_json : Local {
    my ( $self, $c ) = @_;
    $c->form({
        required => [ qw( erm_main link_id link_type ) ],
    });

    if ( $c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown ) {
        $c->stash->{'json'}->{error} = 'Failed to validate request parameters';
        return $c->forward('V::JSON');
    }

    my $erm_main_id = $c->form->{valid}->{erm_main};
    my $link_type = $c->form->{valid}->{link_type};
    my $link_id = $c->form->{valid}->{link_id};

    if ( $self->_verify_linking( $c, $link_type, $link_id, $erm_main_id ) ) {

        # Remove any existing links

        CUFTS::DB::ERMMainLink->search( { link_id => $link_id, link_type => $link_type } )->delete_all;
        my $new_link = CUFTS::DB::ERMMainLink->create( { link_id => $link_id, link_type => $link_type, erm_main => $erm_main_id } );
        CUFTS::DB::ERMMainLink->dbi_commit;
        
        $c->stash->{json} = { result => 'linked', erm_main => $new_link->erm_main, link_type => $new_link->link_type, link_id => $new_link->link_id };

    }
    
    $c->forward('V::JSON');
}


sub _verify_linking {
    my ( $self, $c, $link_type, $link_id, $erm_main_id ) = @_;

    # Check to make sure it's for our current site

    if ( defined( $erm_main_id ) ) {
        my $erm_main = CUFTS::DB::ERMMain->search( { site => $c->stash->{current_site}->id, id => $erm_main_id } )->first;
        if ( !defined($erm_main) ) {
            $c->stash->{json}->{error} = { error => "No matching ERM Main record for current site" };
            return 0;
        }
    }

    if ( $link_type eq 'r' ) {
        my $journal = CUFTS::DB::LocalResources->search( { site => $c->stash->{current_site}->id, id => $link_id } )->first;
        if ( !defined($journal) ) {
            $c->stash->{json}->{error} = { error => "No matching journal record for current site" };
            return 0;
        }
    }
    elsif ( $link_type eq 'j' ) {
        my $resource = CUFTS::DB::LocalJournals->search( { site => $c->stash->{current_site}->id, id => $link_id } )->first;
        if ( !defined($resource) ) {
            $c->stash->{json}->{error} = { error => "No matching resource record for current site" };
            return 0;
        }
    }

    return 1;
}

sub delete_file : Local {
    my ( $self, $c, $erm_id, $file_id  ) = @_;

    my $erm = CUFTS::DB::ERMMain->search({
        id   => $erm_id,
        site => $c->stash->{current_site}->id,
    })->first;

    if ( !defined($erm) ) {
        die("Unable to find ERMMain record: $erm_id for site " . $c->stash->{current_site}->id);
    }

    my $file = CUFTS::DB::ERMFiles->search({
        linked_id   => $erm_id,
        id          => $file_id,
        link_type   => 'm'
    })->first;

    if ( !defined($file) ) {
        die("Unable to find ERMFile record: $file_id for site " . $c->stash->{current_site}->id);
    }
    
    my $filename = $c->path_to( 'root', 'static', 'erm_files', 'm', $file->UUID . '.' . $file->ext );
    unlink($filename) or
        die("Error removing file: $!");
    
    $file->delete();
    CUFTS::DB::ERMMain->dbi_commit();
    
    $c->redirect("/erm/main/edit/$erm_id");
}


1;
