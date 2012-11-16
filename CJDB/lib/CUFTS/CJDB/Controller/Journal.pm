package CUFTS::CJDB::Controller::Journal;
use Moose;
use namespace::autoclean;

use CUFTS::Util::Simple;
use XML::RAI;
use LWP::Simple;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CUFTS::CJDB::Controller::Journal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base :Chained('../site') :PathPart('journal') :CaptureArgs(0) {
    
}


sub view :Chained('base') :PathPart('') :Args(1) {
    my ( $self, $c, $journals_auth_id ) = @_;
    
    defined($journals_auth_id) or
        die "journal auth id not defined";
    
    my $site_id = $c->stash->{current_site}->id;

    my $journal = CJDB::DB::Journals->search(site => $site_id, journals_auth => $journals_auth_id)->first;
    defined($journal) or
        die("Unable to retrieve journal auth id $journals_auth_id");

    if ($c->stash->{current_account}) {
        my @my_tags =  CJDB::DB::Tags->search(
            'journals_auth' => $journals_auth_id,
            'account' => $c->stash->{current_account}->id,
            { order_by => 'tag' }
        );
        $c->stash->{my_tags} = \@my_tags;
    }

    if ( not_empty_string($journal->rss) ) {
        my $xml = get($journal->rss);
        
        XML::RSS::Parser->register_ns_prefix( 'prism', 'http://purl.org/rss/1.0/modules/prism/' );
        
        XML::RAI::Channel->add_mapping( 'year',   'year'   );
        XML::RAI::Channel->add_mapping( 'month',  'month'  );
        XML::RAI::Channel->add_mapping( 'day',    'day'    );
        XML::RAI::Channel->add_mapping( 'date',   'prism:coverDisplayDate' );
        
        XML::RAI::Item->add_mapping( 'volume',     'volume',    'prism:volume' );
        XML::RAI::Item->add_mapping( 'issue',      'issue',     'prism:number' );
        XML::RAI::Item->add_mapping( 'startPage',  'startPage', 'prism:startingPage' );
        XML::RAI::Item->add_mapping( 'endPage',    'endPage',   'prism:endingPage' );
        XML::RAI::Item->add_mapping( 'date',       'pubDate',   'prism:publicationDate' );
        XML::RAI::Item->add_mapping( 'authors',    'authors',   'author', 'dc:creator' );
        XML::RAI::Item->add_mapping( 'publisher',   'dc:publisher' );
        
        
        eval {
            $c->stash->{rss} = XML::RAI->parse_string($xml);
        };
        
    }
    
    $c->stash->{rank_name_sort} = sub {
        my ( $links, $displays ) = @_;
        my @new_array = sort { $b->{rank} <=> $a->{rank} or $displays->{ $a->{resource} }->{name} cmp $displays->{ $b->{resource} }->{name} } @$links;
        return \@new_array;
    };

    # Check for attached ERM records
    
    if ( $c->stash->{current_account} ) {
        my $role = CJDB::DB::Roles->search({ role => 'staff' })->first;
        if ( CJDB::DB::AccountsRoles->count_search({ role => $role->id, account => $c->stash->{current_account}->id }) > 0 ) {
            $c->stash->{staff} = 1;
        }
    }

    foreach my $link ( $journal->links ) {
        next if $link->link_type == 0;  # Print, no further links
        my $resource = $link->local_resource;
        my $local_journal = CUFTS::DB::LocalJournals->retrieve($link->local_journal);
        my $erm;
        if ( defined($resource) && $resource->erm_main ) {
            $c->stash->{erm}->{$link->id} = $resource->erm_main;
        }
        elsif ( defined($local_journal) && $local_journal->erm_main ) {
            $c->stash->{erm}->{$link->id} = $local_journal->erm_main;
        }
    }

    $c->stash->{tags} = CJDB::DB::Tags->get_tag_summary($journals_auth_id, $c->stash->{current_site}->id, (defined($c->stash->{current_account}) ? $c->stash->{current_account}->id : undef));
    $c->stash->{journal} = $journal;    
    $c->stash->{template} = 'journal.tt';
}


sub rss_proxy :Chained('base') :PathPart('rss_proxy') :Args(1) {
    my ($self, $c, $journals_auth_id) = @_;

    defined($journals_auth_id) or
        die "journal auth id not defined";
    
    my $site_id = $c->stash->{current_site}->id;

    my $journal = CJDB::DB::Journals->search(site => $site_id, journals_auth => $journals_auth_id)->first;
    defined($journal) or
        die("Unable to retrieve journal auth id $journals_auth_id");

    if ( not_empty_string($journal->rss) ) {
        my $xml = get($journal->rss);

        if ( not_empty_string($xml) ) {

            my $prefix = $c->stash->{current_site}->proxy_prefix;

            if ( not_empty_string($prefix) ) {
                $xml =~ s{ <link> \s* (http:// .+?) </link> }{<link>${prefix}$1</link>}gxsm;
                $xml =~ s{ <link> \s* <!\[CDATA\[ \s* (http:// .+?) \s* \] \s* \] \s* > \s* </link> }{<link><![CDATA[${prefix}$1]]></link>}gxsm;
                $xml =~ s{ <guid> \s* (http:// .+?) </guid> }{<guid>${prefix}$1</guid>}gxsm;
                $xml =~ s{ <guid> \s* <!\[CDATA\[ \s* (http:// .+?) \s* \] \s* \] \s* > \s* </guid> }{<guid><![CDATA[${prefix}$1]]></guid>}gxsm;
                $xml =~ s{ <item \s+ (.+?)(http:// .+?) > }{<item $1${prefix}$2>}gxsm;
                $xml =~ s{ <rdf:li \s+ rdf:resource="(http:// .+?)" \s* /> }{<rdf:li rdf:resource="${prefix}$1" />}gxsm;
            }

            $c->response->content_type('text/xml');
            $c->response->output($xml);

        }
        else {
            $c->res->output('There was an error retrieving the RSS feed for this journal');
            warn("Error retrieving RSS for journal: " . $journal->id . " site: $site_id");
        }
    }
    else {
        $c->res->output('There is no RSS feed enabled for this journal');
    }
}

sub manage_tags :Chained('base') :PathPart('manage_tags') :Args(1) {
    my ($self, $c, $journals_auth_id) = @_;
    
    $c->stash->{'show_manage_tags'} = 1;
    
    $c->forward( $c->controller->action_for('view'), [$journals_auth_id]);
}


=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
