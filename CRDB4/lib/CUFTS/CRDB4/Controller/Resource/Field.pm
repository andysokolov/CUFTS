package CUFTS::CRDB4::Controller::Resource::Field;
use Moose;
use namespace::autoclean;

use CUFTS::Util::Simple;
use JSON::XS qw(encode_json);
use Unicode::String qw(utf8);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CRDB4::Controller::Resource::Field - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut



my %handler_map = (
    consortia           => 'consortia',
    content_types       => 'content_types',
    resource_medium     => 'resource_medium',
    resource_type       => 'resource_type',
    subjects            => 'subjects',
    pricing_model       => 'pricing_model',
);

my %data_type_handler_map = (
    varchar => 'text',
    text    => 'textarea',
    boolean => 'boolean',
    date    => 'date',
    integer => 'integer',
);

sub base :Chained('/resource/load_resource') :PathPart('field') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_role_json('edit_erm_records');

    # Avoid IE caching of AJAX calls

    $c->response->header( 'Cache-Control' => 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0, max-age=0' );
    $c->response->header( 'Pragma' => 'no-cache' );
    $c->response->header( 'Expires' => 'Thu, 01 Jan 1970 00:00:00 GMT' );
}

sub edit :Chained('base') :PathPart('edit') :Args(1) {
    my ( $self, $c, $field ) = @_;

    # Dispatch to appropriate field handler

    my $handler = $self->get_handler( $c, $field );

    die("Unable to find handler for field: $field") if !defined( $handler );

    $c->stash->{no_wrap} = 1;
    $c->forward( $handler, [ $field ] );
}

sub get_handler {
    my ( $self, $c, $field ) = @_;

    $c->stash->{display_field} = $c->model('CUFTS::ERMDisplayFields')->search( { field => $field, site => $c->site->id } )->first();

    my $handler = $handler_map{$field};

    # Try to get a data type from the schema

    if ( !defined($handler) ) {
        my $data_type = $c->model('CUFTS::ERMMain')->result_source->column_info($field)->{data_type};

        warn($data_type);

        # Special cases

        if ( $data_type eq 'varchar' && $field =~ /_url$/ ) {
#            $handler = 'URL';
            $handler = 'text';  # Treat URL fields as text for now
        }
        else {
            $handler = $data_type_handler_map{$data_type};
        }
    }

    if ( defined($handler) ) {
        $handler = "edit_field_${handler}";
    }

    return $handler;
}

sub edit_field_subjects :Private {
    my ( $self, $c, $field ) = @_;

    if ( defined( $c->req->params->{subjects} ) ) {

        my $subjects = $c->req->params->{subjects};
        if ( !ref($subjects) ) {
            $subjects = [ $subjects ];
        }
        my $erm = $c->stash->{erm};

        $c->model('CUFTS')->schema->txn_do( sub {

            $erm->subjects_main->delete_all();

            foreach my $subject_id ( @$subjects ) {

                my $count = $c->model('CUFTS::ERMSubjects')->search({ site => $c->site->id, id => $subject_id })->count();
                if ( $count < 1 ) {
                    die("Attempt to add subject not belonging to this site.");
                }

                $erm->add_to_subjects_main({ subject => $subject_id });
            }

        } );

        # Reload new subjects for display

        $c->stash->{subject_links} = [ map { [ $_->subject, $c->uri_for_site( $c->controller('Browse')->action_for('browse'), { subject => $_->id } ) ] }  
                                       sort { $a->subject cmp $b->subject } $c->stash->{erm}->subjects ];


        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        my @all_subjects = $c->model('CUFTS::ERMSubjects')->search( { site => $c->site->id }, { order_by => 'subject' } )->all;

        $c->stash->{value} = [ map { $_->id } $c->stash->{erm}->subjects( {}, {order_by => 'subject'} )->all() ];
        $c->stash->{options} = \@all_subjects;
        $c->stash->{display_field} = 'subject';

        $c->stash->{field} = $field;
        $c->stash->{template} = 'fields/multiselect.tt'
    }


}



sub edit_field_consortia :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{$field} ) {

        # Add in validation here

        my $value = $c->req->params->{$field};
        if ( not_empty_string( $value) ) {
            my $count = $c->model('CUFTS::ERMConsortia')->search({ site => $c->site->id, id => $value })->count();
            if ( $count < 1 ) {
                die("Attempt to update consortia to a value not appropriate for this site: $value");
            }
        }
        else {
            $value = undef;
        }

        $c->model('CUFTS')->schema->txn_do( sub {
            $c->stash->{erm}->set_column('consortia', $value );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->get_column('consortia');
        $c->stash->{options} = [ $c->model('CUFTS::ERMConsortia')->search({ site => $c->site->id })->all ];
        $c->stash->{display_field} = 'consortia';
        $c->stash->{template} = 'fields/select.tt'
    }
}

sub edit_field_content_types :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {

        my $value = $c->req->params->{$field};
        if ( !ref($value) ) {
            $value = [ $value ];
        }

        $c->model('CUFTS')->schema->txn_do( sub {
            $c->stash->{erm}->content_types_main->delete_all();

            foreach my $content_type_id ( @$value ) {
                my $count = $c->model('CUFTS::ERMContentTypes')->search( site => $c->site->id, id => $content_type_id )->count();
                if ( $count < 1 ) {
                    die("Attempt to update content_type to a value not appropriate for this site: $content_type_id");
                }
                $c->stash->{erm}->add_to_content_types_main({
                    content_type => $content_type_id
                });
            }

        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = [ map { $_->id } $c->stash->{erm}->content_types ];
        $c->stash->{options} = [ $c->model('CUFTS::ERMContentTypes')->search({ site => $c->site->id })->all ];
        $c->stash->{display_field} = 'content_type';
        $c->stash->{template} = 'fields/multiselect.tt'
    }
}


sub edit_field_resource_medium :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {

        # Add in validation here

        my $value = $c->req->params->{$field};
        if ( not_empty_string( $value ) ) {
            my $count = $c->model('CUFTS::ERMResourceMediums')->search({ site => $c->site->id, id => $value })->count();
            if ( $count < 1 ) {
                die("Attempt to update resource_medium to a value not appropriate for this site: $value");
            }
        }
        else {
            $value = undef;
        }

        $c->model('CUFTS')->schema->txn_do( sub {
            $c->stash->{erm}->resource_medium( $value );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->get_column('resource_medium');
        $c->stash->{options} = [ $c->model('CUFTS::ERMResourceMediums')->search({ site => $c->site->id })->all ];
        $c->stash->{display_field} = 'resource_medium';
        $c->stash->{template} = 'fields/select.tt'
    }
}

sub edit_field_pricing_model :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {

        # Add in validation here

        my $value = $c->req->params->{$field};
        if ( not_empty_string( $value ) ) {
            my $count = $c->model('CUFTS::ERMPricingModels')->search({ site => $c->site->id, id => $value })->count();
            if ( $count < 1 ) {
                die("Attempt to update pricing_model to a value not appropriate for this site: $value");
            }
        }
        else {
            $value = undef;
        }

        $c->model('CUFTS')->schema->txn_do( sub {
            $c->stash->{erm}->pricing_model( $value );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->get_column('pricing_model');
        $c->stash->{options} = [ $c->model('CUFTS::ERMPricingModels')->search({ site => $c->site->id })->all ];
        $c->stash->{display_field} = 'pricing_model';
        $c->stash->{template} = 'fields/select.tt'
    }
}


sub edit_field_resource_type :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {

        # Add in validation here

        my $value = $c->req->params->{$field};
        if ( not_empty_string( $value) ) {
            my $count = $c->model('CUFTS::ERMResourceTypes')->search({ site => $c->site->id, id => $value })->count();
            if ( $count < 1 ) {
                die("Attempt to update resource_type to a value not appropriate for this site: $value");
            }
        }
        else {
            $value = undef;
        }

        $c->model('CUFTS')->schema->txn_do( sub {
            $c->stash->{erm}->resource_type( $value );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->get_column('resource_type');
        $c->stash->{options} = [ $c->model('CUFTS::ERMResourceTypes')->search({ site => $c->site->id })->all ];
        $c->stash->{display_field} = 'resource_type';
        $c->stash->{template} = 'fields/select.tt'
    }
}


sub edit_field_text :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {


        # Convert from UTF8 to latin-1, jQuery AJAX only ever seems to send UTF8
        # Add in validation here


        $c->model('CUFTS')->schema->txn_do( sub {
            $c->stash->{erm}->$field( utf8($c->req->params->{$field})->latin1 );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->$field();
        $c->stash->{template} = 'fields/text.tt'
    }
}

sub edit_field_textarea :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {

        # Add in validation here

        $c->model('CUFTS')->schema->txn_do( sub {
            $c->stash->{erm}->$field( utf8($c->req->params->{$field})->latin1 );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->$field();
        $c->stash->{template} = 'fields/textarea.tt'
    }
}


sub edit_field_boolean :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {

        # Add in validation here

        if ( $c->req->params->{$field} eq '' ) {
            $c->req->params->{$field} = undef;
        }

        $c->model('CUFTS')->schema->txn_do( sub {
            $c->stash->{erm}->$field( $c->req->params->{$field} );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->$field();
        $c->stash->{template} = 'fields/boolean.tt'
    }
}


sub edit_field_date :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {

        # Add in validation here

        $c->model('CUFTS')->schema->txn_do( sub {
            my $val = $c->req->params->{$field};
            $val ||= undef;
            $c->stash->{erm}->$field( $val );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->$field();
        $c->stash->{template} = 'fields/date.tt'
    }
}

sub edit_field_integer :Private {
    my ( $self, $c, $field ) = @_;

    if ( $c->req->params->{update_value} ) {

        # Add in validation here

        $c->model('CUFTS')->schema->txn_do( sub {
            my $val = $c->req->params->{$field};
            $val = not_empty_string($val) ? int($val) : undef;
            $c->stash->{erm}->$field( $val );
            $c->stash->{erm}->update();
        } );

        $c->stash->{display_field_name} = $field;
        $c->stash->{template} = 'display_field.tt'
    }
    else {
        $c->stash->{field} = $field;
        $c->stash->{value} = $c->stash->{erm}->$field();
        $c->stash->{template} = 'fields/integer.tt'
    }
}


sub edit_field_text_field :Private {
    my ( $self, $c, $field ) = @_;
}



=encoding utf8

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
