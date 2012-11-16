package CUFTS::CJDB::Controller::Tags;
use Moose;
use namespace::autoclean;

use CUFTS::Util::Simple;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CJDB::Controller::Tags - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('../site') :PathPart('tags') :CaptureArgs(0) {}

sub save :Chained('base') :PathPart('save') :Args(1) {
    my ( $self, $c, $journal_id ) = @_;
    defined($journal_id)
        or die "journal id not defined.";

    my $journal = CJDB::DB::Journals->retrieve($journal_id);
    defined($journal)
        or die("Unable to retrieve journal id $journal_id");

    my $journals_auth_id = $journal->journals_auth->id;

    # Exit out now if the cancel button was pushed (no javascript)

    if ( $c->req->params->{cancel} ) {
        return $c->redirect( $c->uri_for_site( $c->controller('Journal')->action_for('view'), $journals_auth_id ) );
    }

    $self->_do_add_tags(  $c, $journal );
    $self->_do_save_tags( $c, $journal );

    CJDB::DB::Tags->dbi_commit;

    return $c->redirect( $c->uri_for_site( $c->controller('Journal')->action_for('view'), $journals_auth_id ) );
}

sub _do_save_tags {
    my ( $self, $c, $journal ) = @_;

PARAM:
    foreach my $param ( keys %{ $c->req->params } ) {
        my ( $action, $id );
        if ( $param =~ /^(edit|delete)_(\d+)$/ ) {
            ( $action, $id ) = ( $1, $2 );
        }
        else {
            next PARAM;
        }

        # Get tag record and make sure it belongs to the current user
        my $tag = CJDB::DB::Tags->retrieve($id);
        if ( !defined($tag) ) {
            push @{ $c->stash->{errors} }, "Unable to retrieve tag id $id";
            next PARAM;
        }
        if ( $tag->account->id != $c->stash->{current_account}->id ) {
            push @{ $c->stash->{errors} },
                "Tag id $id does not belong to the current account.";
            next PARAM;
        }

        if ( $action eq 'delete' ) {
            $tag->delete();
        }
        elsif ( $action eq 'edit' ) {
            my $viewing = $c->req->params->{"viewing_$id"};
            my $text    = $self->_clean_tag_text( $c->req->params->{$param} );

            if ( is_empty_string($text) ) {
                $tag->delete();
                next PARAM;
            }

            $tag->tag($text);
            $tag->viewing($viewing);
            $tag->update;
        }
        else {
            push @{ $c->stash->{errors} }, "Unrecognized action: $action";
        }
    }
}

sub _do_add_tags {
    my ( $self, $c, $journal ) = @_;

    my $count = 0;
    foreach my $tag_group ( 0 .. 2 ) {
        my $field = "new_tags_${tag_group}";
        my @tags  = split ',', $c->req->params->{$field};

        foreach my $tag (@tags) {
            $tag = $self->_clean_tag_text($tag);

            my $record = {
                'journals_auth' => $journal->journals_auth->id,
                'site'          => $c->stash->{current_site}->id,
                'account'       => $c->stash->{current_account}->id,
                'tag'           => $tag,
            };

            my @existing = CJDB::DB::Tags->search($record);
            next if scalar(@existing);

            $record->{level}   = $c->stash->{current_account}->level;
            $record->{viewing} = $tag_group;

            my $tag_record = CJDB::DB::Tags->create($record);
            defined($tag_record)
                or die("Error creating tag record.");

            $count++;
        }
    }

    return $count;
}

sub _clean_tag_text {
    return CUFTS::CJDB::Util::strip_tag( $_[1] );
}


=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
