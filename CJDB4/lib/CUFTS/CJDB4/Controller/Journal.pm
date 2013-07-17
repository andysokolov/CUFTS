package CUFTS::CJDB4::Controller::Journal;
use Moose;
use namespace::autoclean;

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

    # if ( $c->account ) {
    #     my @my_tags =  CJDB::DB::Tags->search(
    #         'journals_auth' => $journals_auth_id,
    #         'account' => $c->stash->{current_account}->id,
    #         { order_by => 'tag' }
    #     );
    #     $c->stash->{my_tags} = \@my_tags;
    # }

    # Check for attached ERM records

    foreach my $link ( $journal->links ) {
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

    $c->stash->{staff} = ( $c->account && $c->account->has_role('staff') ) ? 1 : 0;
    # $c->stash->{tags} = CJDB::DB::Tags->get_tag_summary($journals_auth_id, $c->site->id, (defined($c->account) ? $c->account->id : undef));
    $c->stash->{journal} = $journal;
    $c->stash->{template} = 'journal.tt';

    push @{$c->stash->{breadcrumbs}}, [ $c->uri_for_site( $c->controller('Journal')->action_for('view') ), 'Journal' ];
}



=head1 AUTHOR

Todd Holbrook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
