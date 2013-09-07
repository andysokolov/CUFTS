package CUFTS::CJDB4::Controller::Journal;
use Moose;
use namespace::autoclean;

use CUFTS::CJDB::Util;

use String::Util qw(trim hascontent);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CJDB4::Controller::Journal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('../site') :PathPart('journal') :CaptureArgs(0) {}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->redirect( $c->uri_for_site( $c->controller('Browse')->action_for('browse') ) );
}

sub view :Chained('base') :PathPart('') :Args(1) {
    my ( $self, $c, $journals_auth_id ) = @_;

    my $journal = $c->model('CUFTS::CJDBJournals')->find({ site => $c->site->id, journals_auth => $journals_auth_id });
    defined($journal) or
        die("Unable to retrieve journal auth id $journals_auth_id");

    # Save any tag changes

    $self->_save_tags($c, $journal);

    # Check for attached ERM records

    my $links = $journal->display_links;

    foreach my $link ( @$links ) {
        next if $link->link_type == 0;  # Print, no ERM would be attached

        my $local_resource = $link->local_resource;
        my $local_journal  = $link->local_journal;

        if ( defined($local_resource) && $local_resource->erm_main ) {
            $c->stash->{erm}->{$link->id} = $local_resource->erm_main;
        }
        elsif ( defined($local_journal) && $local_journal->erm_main ) {
            $c->stash->{erm}->{$link->id} = $local_journal->erm_main;
        }
    }

    if ( $c->has_account ) {
        $c->stash->{tags} = $journal->tag_summary( $c->site, undef, $c->account );
        $c->stash->{account_tags} = [ $journal->tags({ account =>  $c->account->id }, { order_by => 'tag' })->all ];
    }
    else {
        $c->stash->{tags} = $journal->tag_summary( $c->site );
    }

    $c->stash->{links} = CUFTS::CJDB::Util::links_rank_name_sort( $links, $c->stash->{resources_display} );
    $c->stash->{staff} = ( $c->account && $c->account->has_role('staff') ) ? 1 : 0;
    $c->stash->{journal} = $journal;
    $c->stash->{template} = 'journal.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Browse')->action_for('browse') ), $c->loc('Journals') ];
    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Journal')->action_for('view'), $journals_auth_id ), $journal->title ];
}


sub _save_tags {
    my ( $self, $c, $journal ) = @_;

    return if !$c->has_account;

    ##
    ## Edit existing tags
    ##

    my $modified_count = 0;
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
        my $tag = $journal->tags->find({ id => $id });
        if ( !defined($tag) ) {
            push @{ $c->stash->{errors} }, "Unable to retrieve tag id $id";
            next PARAM;
        }
        if ( $tag->get_column('account') != $c->account->id ) {
            push @{ $c->stash->{errors} },
                "Tag id $id does not belong to the current account.";
            next PARAM;
        }

        if ( $action eq 'delete' ) {
            $tag->delete();
        }
        elsif ( $action eq 'edit' ) {
            my $viewing = $c->req->params->{"viewing_$id"};
            my $text    = trim($self->_clean_tag_text( $c->req->params->{$param} ));

            if ( !hascontent($text) ) {
                $tag->delete();
                next PARAM;
            }

            $tag->tag($text);
            $tag->viewing($viewing);
            $tag->update;

            $modified_count++;
        }
        else {
            push @{ $c->stash->{errors} }, "Unrecognized action: $action";
        }
    }

    ##
    ## Add new tags
    ##

    my $added_count = 0;
    my $new_tags = trim($c->req->params->{new_tag});
    if ( hascontent($new_tags) ) {
        foreach my $tag (split /\s*,\s*/, $new_tags) {
            $tag = trim($self->_clean_tag_text($tag));
            next if !hascontent($tag);

            my $record = {
                journals_auth => $journal->get_column('journals_auth'),
                site          => $c->site->id,
                account       => $c->account->id,
                tag           => $tag,
            };

            my $count = $c->model('CUFTS::CJDBTags')->search($record)->count;
            next if $count > 0;

            $record->{level} = $c->account->level;
            $record->{viewing} = $c->req->params->{new_viewing};

            my $tag_record = $c->model('CUFTS::CJDBTags')->create($record);
            if ( defined $tag_record ) {
                $added_count++;
            }
            else {
                push @{ $c->stash->{errors} }, "Error creating tag: $tag";
            }


        }
    }

    if ( $modified_count ) {
        push @{ $c->stash->{result} }, "Modified $modified_count tags.";
    }
    if ( $added_count ) {
        push @{ $c->stash->{result} }, "Added $added_count tags.";
    }

}


sub _clean_tag_text {
    return CUFTS::CJDB::Util::strip_tag( $_[1] );
}



=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
