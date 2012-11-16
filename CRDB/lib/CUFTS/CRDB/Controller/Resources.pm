package CUFTS::CRDB::Controller::Resources;

use strict;
use warnings;
use base 'Catalyst::Controller';

use CUFTS::Util::Simple;

=head1 NAME

CUFTS::CRDB::Controller::Resources - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for actions against sets of resources.  These generally tend to be AJAX.

=head1 METHODS

=cut


sub base : Chained('/site') PathPart('resources') CaptureArgs(0) {}

=head2 edit_erm_records

Check roles to make sure user has rights to edit resources.

=cut

sub edit_erm_records : Chained('base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    
    $c->assert_user_roles('edit_erm_records');
}


=head2 rerank 

AJAX action for reranking a set of resources using drag and drop sortables.

=cut

sub rerank : Chained('edit_erm_records') PathPart('rerank') Args(0) {
    my ( $self, $c ) = @_;

    $c->form({
        required => [ qw( subject  ) ], 
        optional => [ qw( resource_order resource_other ) ] 
    });
    
    unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {
        my $subject = $c->form->{valid}->{subject};
        
        # Add security join which only brings back subjects for the current site
        
        my %records = map { $_->get_column('erm_main') => $_ } $c->model('CUFTS::ERMSubjectsMain')->search( { subject => $subject } )->all;

        my $resource_order = $c->form->{valid}->{resource_order} || [];
        $resource_order = [ $resource_order ] if !ref($resource_order);

        my $resource_other = $c->form->{valid}->{resource_other} || [];
        $resource_other = [ $resource_other ] if !ref($resource_other);

        my $rank = 1;

        my $update_transaction = sub {
            foreach my $resource_id ( @{ $resource_order} ) {
                my $record = $records{$resource_id};
                if ( !defined($record) ) {
                    die("Unable to find matching ERM record ($resource_id) in subject ($subject)" );
                }
                $record->rank( $rank );
                $record->update;
                $rank++;
            }

            foreach my $resource_id ( @{ $resource_other } ) {
                my $record = $records{$resource_id};
                if ( !defined($record) ) {
                    die("Unable to find matching ERM record ($resource_id) in subject ($subject)" );
                }
                $record->rank( 0 );
                $record->update;
            }

            $c->stash->{json}->{update} = 'success';

            return 1;
        };

        $c->model('CUFTS')->schema->txn_do( $update_transaction );
    }

    
    $c->stash->{current_view} = 'JSON';
}

=head2 rerank 

AJAX action for changing the subject specific description for a resource from the browse display

=cut


sub subject_description : Chained('edit_erm_records') PathPart('subject_description') Args(0) {
    my ( $self, $c ) = @_;

    $c->form({
        required => [ qw( subject_id erm_main_id  ) ], 
        optional => [ qw( change description ) ] 
    });
    
    unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

        my $erm_main_id = $c->form->{valid}->{erm_main_id};
        my $subject_id  = $c->form->{valid}->{subject_id };

        my $subject  = $c->model('CUFTS::ERMSubjectsMain')->search( { subject => $subject_id, erm_main => $erm_main_id } )->first()
            or die("Unable to find subject record.");

        my $erm_main = $c->model('CUFTS::ERMMain')->search( id => $erm_main_id, site => $c->site->id )->first()
            or die("Unable to find erm_main record");

        if ( $c->form->{valid}->{change} ) {

            # Try to change the description
            
            my $description = $c->form->{valid}->{description};
            $description = trim_string( $description );
            $description = undef if is_empty_string( $description );

            $c->model('CUFTS')->schema->txn_do( sub {
                $subject->description( $description );
                $subject->update();
            } );

        }

        $c->stash->{json}->{description}         = $erm_main->description_brief;
        $c->stash->{json}->{subject_description} = $subject->description;

    }

    
    $c->stash->{current_view} = 'JSON';
}

=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
