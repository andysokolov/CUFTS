package CUFTS::CRDB4::Controller::Resources;
use Moose;
use namespace::autoclean;

use String::Util qw( trim hascontent );

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CRDB4::Controller::Resources - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub base : Chained('/site') PathPart('resources') CaptureArgs(0) {}

=head2 edit_erm_records

Check roles to make sure user has rights to edit resources.

=cut

sub edit_erm_records : Chained('base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_role_json('edit_erm_records');
}


=head2 rerank

AJAX action for reranking a set of resources using drag and drop sortables.

=cut

sub rerank : Chained('edit_erm_records') PathPart('rerank') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{json}->{success} = 0;
    $c->stash->{current_view} = 'JSON';

    my $subject 	   = $c->request->params->{subject};
    my $resource_order = $c->request->params->{resource_order};
    my $resource_other = $c->request->params->{resource_other};

    if ( !$subject ) {
	    $c->stash->{json}->{message} = $c->loc('Missing subject in rerank');
	    return;
    }

    # Add security join which only brings back subjects for the current site

    my %records = map { $_->get_column('erm_main') => $_ } $c->model('CUFTS::ERMSubjectsMain')->search( { subject => $subject } )->all;

    $resource_order = [ $resource_order ] if !ref($resource_order);
    $resource_other = [ $resource_other ] if !ref($resource_other);

    my $rank = 1;

    my $update_transaction = sub {
        foreach my $resource_id ( @$resource_order ) {
            my $record = $records{$resource_id};
            if ( !defined($record) ) {
                die("Unable to find matching ERM record ($resource_id) in subject ($subject)" );
            }
            $record->rank( $rank );
            $record->update;
            $rank++;
        }

        foreach my $resource_id ( @$resource_other ) {
            my $record = $records{$resource_id};
            if ( !defined($record) ) {
                die("Unable to find matching ERM record ($resource_id) in subject ($subject)" );
            }
            $record->rank( 0 );
            $record->update;
        }

        $c->stash->{json}->{message}  = $c->loc('Successfully reranked resources.');
        $c->stash->{json}->{success} = 1;

        return 1;
    };

    $c->model('CUFTS')->schema->txn_do( $update_transaction );
}


sub subject_description : Chained('base') PathPart('edit_erm_records') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{current_view} = 'JSON';

    my $subject_id  = $c->request->params->{subject_id};
    my $description = $c->request->params->{subject_description} || '';
    my $change      = $c->request->params->{change};

    my $subject  = $c->model('CUFTS::ERMSubjects')->find({ id =>  $subject_id });

    if ( !$subject ) {
        $c->stash->{json}->{success} = 0;
        $c->stash->{json}->{message} = $c->loc('Unable to find subject record.');
        return;
    }

    if ( $change ) {

        $description = trim( $description );
        $description = undef if !hascontent( $description );

        $subject->description( $description );
        $subject->update();

        $c->stash->{json}->{success} = 1;
        $c->stash->{json}->{message} = $c->loc('Updated subject description.');

    }

    $c->stash->{json}->{subject_description} = $subject->description;

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
