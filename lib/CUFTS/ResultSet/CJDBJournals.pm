package CUFTS::ResultSet::CJDBJournals;

use strict;
use base 'DBIx::Class::ResultSet';

 __PACKAGE__->load_components( qw(Helper::ResultSet::SetOperations) );

# Use a fulltext search through the titles and return in relevance order. Note that the ResultSet returned here is a little
# fragile due to the weirdo subquery.

sub search_distinct_title_by_journal_main_ft {
    my ( $self, $site, $title, $page, $limit ) = @_;

    $page ||= 0;

    # Titles subquery

    my $titles_rs = $self->result_source->schema->resultset('CJDBTitles')->search({},
        {
            select   => \"DISTINCT ON (journals_titles.journal) me.title, me.search_title, journals_titles.journal AS journal_id, ts_rank( to_tsvector('english', search_title), plainto_tsquery('english', ?), 8 ) AS rank",
            bind     => [ $title, $title, $site ],
            join     => 'journals_titles',
            where    => \"to_tsvector('english', search_title) @@ plainto_tsquery('english', ?) AND site = ?",
            order_by => [ 'journals_titles.journal', 'journals_titles.main DESC', 'rank DESC',  ],
        }
    );

    # Need to add the join and "AS" clause for the subquery here since DBIC doesn't do it quite right. Could this all
    # be done better as a view or something?
    my $sub = $titles_rs->as_query;
    ${$sub}->[0] .= ' AS titles_subquery JOIN cjdb_journals AS me ON ( titles_subquery.journal_id = me.id )';

    return $self->search( {},
        {
            '+select' => [ 'titles_subquery.title' ],
            '+as'     => [ 'result_title' ],
            from => $sub,
            rows => $limit,
            page => $page,
            order_by => [ 'titles_subquery.rank DESC', 'titles_subquery.search_title' ],
        }
    );
}

sub search_distinct_title_by_journal_main {
    my ( $self, $site, $title, $page, $limit ) = @_;

    $page ||= 0;

    my $titles_rs = $self->result_source->schema->resultset('CJDBTitles')->search(
        {
            site => $site,
            search_title => { '~' => $title },
        },
        {
            select   => "DISTINCT ON (journals_titles.journal) me.title, me.search_title, journals_titles.journal AS journal_id",
            join     => 'journals_titles',
            order_by => [ 'journals_titles.journal', 'journals_titles.main DESC' ],
        }
    );

    # Need to add the join and "AS" clause for the subquery here since DBIC doesn't do it quite right. Could this all
    # be done better as a view or something?
    my $sub = $titles_rs->as_query;
    ${$sub}->[0] .= ' AS titles_subquery JOIN cjdb_journals AS me ON ( titles_subquery.journal_id = me.id )';

    return $self->search( {},
        {
            '+select' => [ 'titles_subquery.title' ],
            '+as'     => [ 'result_title' ],
            from => $sub,
            rows => $limit,
            page => $page,
            order_by => [ 'titles_subquery.search_title' ],
        }
    );
}


sub search_distinct_by_tags {
    my ($self, $tags, $level, $site, $account, $viewing) = @_;

    scalar(@$tags) == 0 and
        return $self;

    if ( ref($site) ne 'SCALAR' && $site->can('id') ) {
        $site = $site->id;
    }

    if ( defined($account) && ref($account) ne 'SCALAR' && $account->can('id') ) {
        $account = $account->id;
    }

    my @rs_list;
    foreach my $tag (@$tags) {
        my %search;

        if ( $viewing == 0 ) {
            %search = ( 'tags.viewing' => 0 );
            $search{'tags.account'} = $account if $account;
        }
        elsif ( $viewing == 1 ) {
            %search = ( 'tags.viewing' => 1, 'tags.site' => $site );
            $search{'tags.account'} = $account if $account;
        }
        elsif ( $viewing == 2 ) {
            %search = ( 'tags.viewing' => 2, 'tags.site' => $site );
            $search{'tags.account'} = $account if $account;
        }
        elsif ( $viewing == 3 ) {
            %search = (
                '-or' => [
                    'tags.viewing' => 1,
                    { 'tags.viewing' => 2, 'tags.site' => $site },
                ]
            );
            if ( $account ) {
                push @{$search{'-or'}}, { 'tags.viewing' => 0, 'tags.account' => $account };
            }
        }
        elsif ( $viewing == 4 ) {
            %search = (
                'tags.site' => $site,
                '-or' => [
                    'tags.viewing' => 1,
                    'tags.viewing' => 2,
                ]
            );
        }

        if ( $level ) {
            $search{'tags.level'} = { '>=' => $level };
        }

        $search{'tags.tag'} = $tag;
        $search{'me.site'}  = $site;

        my $rs = $self->search( \%search, { join => 'tags' } );
        push @rs_list, $rs;
    }

    my $final_rs = pop @rs_list;
    foreach my $rs ( @rs_list ) {
        $final_rs = $final_rs->intersect( $rs );
    }

    return $final_rs;
}



1;
