## CJDB::DB::Journals
##
## Copyright Todd Holbrook, Simon Fraser University (2003)
##
## This file is part of CJDB.
##
## CJDB is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
## 
## CJDB is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CJDB; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

package CJDB::DB::Journals;

use strict;
use base 'CJDB::DB::DBI';
use CJDB::DB::JournalsTitles;
use CJDB::DB::Links;
use CJDB::DB::Subjects;
use CJDB::DB::Relations;
use CJDB::DB::Associations;
use CJDB::DB::ISSNs;
use CUFTS::DB::JournalsAuth;

__PACKAGE__->table('cjdb_journals');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	title
	sort_title
	stripped_sort_title

	call_number

    image
    image_link
    rss
    miscellaneous

	journals_auth

	site

	created
));                                                                                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->columns(TEMP => qw( result_title ) );
__PACKAGE__->sequence('cjdb_journals_id_seq');

__PACKAGE__->has_many('titles', [ 'CJDB::DB::JournalsTitles' => 'title' ]);
__PACKAGE__->has_many('links', 'CJDB::DB::Links' => 'journal');
__PACKAGE__->has_many('subjects', [ 'CJDB::DB::JournalsSubjects' => 'subject' ]);
__PACKAGE__->has_many('associations', [ 'CJDB::DB::JournalsAssociations' => 'association' ]);
__PACKAGE__->has_many('relations', 'CJDB::DB::Relations' => 'journal');
__PACKAGE__->has_many('issns', 'CJDB::DB::ISSNs' => 'journal');
__PACKAGE__->has_a('journals_auth' => 'CUFTS::DB::JournalsAuth');


sub search_distinct_by_exact_subjects {
	my ($class, $site, $search, $offset, $limit) = @_;

	scalar(@$search) == 0 and
		return [];
	
	$limit ||= 'ALL';
	$offset ||= 0;

	my @bind = ($site);	
	my $sql = "SELECT DISTINCT ON (cjdb_journals.stripped_sort_title, cjdb_journals.id) cjdb_journals.* FROM cjdb_journals ";
	my $where = " WHERE cjdb_journals.site = ? ";

	my $count = 0;
	foreach my $search (@$search) {
		$count++;

        # Use LIKE in search because of varchar pattern op indexes

		$sql .= " JOIN cjdb_journals_subjects AS cjdb_journals_subjects${count} ON (cjdb_journals_subjects${count}.journal = cjdb_journals.id) ";
		$sql .= " JOIN cjdb_subjects AS cjdb_subjects${count} ON (cjdb_journals_subjects${count}.subject = cjdb_subjects${count}.id) ";
		$where .= " AND cjdb_subjects${count}.search_subject LIKE ? ";
		$where .= " AND cjdb_journals_subjects${count}.site = ? ";
		
		push @bind, $search;
		push @bind, $site;
	}

	$sql .= $where;
	$sql .= " ORDER BY cjdb_journals.stripped_sort_title, cjdb_journals.id LIMIT $limit OFFSET $offset";

    warn($sql);

	my $dbh = $class->db_Main();
    my $sth = $dbh->prepare($sql, {pg_server_prepare => 0});
	
	$sth->execute(@bind);
	my @results = $class->sth_to_objects($sth);
	return \@results;
}		

sub search_distinct_by_exact_associations {
	my ($class, $site, $search, $offset, $limit) = @_;

	scalar(@$search) == 0 and
		return [];
	
	$limit  ||= 'ALL';
	$offset ||= 0;

	my @bind = ($site);	
	my $sql = "SELECT DISTINCT ON (cjdb_journals.stripped_sort_title, cjdb_journals.id) cjdb_journals.* FROM cjdb_journals ";
	my $where = " WHERE cjdb_journals.site = ? ";

	my $count = 0;
	foreach my $search (@$search) {
		$count++;

        # Use LIKE in search because of varchar pattern op indexes

		$sql .= " JOIN cjdb_journals_associations AS cjdb_journals_associations${count} ON (cjdb_journals_associations${count}.journal = cjdb_journals.id) ";
		$sql .= " JOIN cjdb_associations AS cjdb_associations${count} ON (cjdb_journals_associations${count}.association = cjdb_associations${count}.id) ";
		$where .= " AND cjdb_associations${count}.search_association LIKE ? ";
		$where .= " AND cjdb_journals_associations${count}.site = ? ";
		
		push @bind, $search;
		push @bind, $site;
	}

	$sql .= $where;
	$sql .= " ORDER BY cjdb_journals.stripped_sort_title, cjdb_journals.id LIMIT $limit OFFSET $offset";


    my $sth = $class->db_Main()->prepare($sql, {pg_server_prepare => 0});
	my @results = $class->sth_to_objects($sth, \@bind);
	return \@results;
}


sub search_by_issn {
	my ($class, $site, $issns, $exact, $offset, $limit) = @_;

	scalar(@$issns) == 0 and
		return [];
	
	$limit ||= 'ALL';
	$offset ||= 0;

	my $search_type = $exact ? '=' : 'LIKE';
	
	my $issn = uc($issns->[0]);
	$issn =~ s/[^0-9X]//g;

	my $sql = <<"";
SELECT DISTINCT ON (cjdb_journals.stripped_sort_title, cjdb_journals.id) cjdb_journals.* FROM cjdb_journals
JOIN cjdb_issns ON (cjdb_journals.id = cjdb_issns.journal) 
WHERE cjdb_issns.issn $search_type ? AND cjdb_journals.site = ?
ORDER BY cjdb_journals.stripped_sort_title, cjdb_journals.id
LIMIT $limit OFFSET $offset;

	my $dbh = $class->db_Main();
    my $sth = $dbh->prepare($sql, {pg_server_prepare => 0});
	
	$sth->execute($issn, $site);
	my @results = $class->sth_to_objects($sth);
	return \@results;
}

sub search_distinct_by_tags {
	my ($class, $tags, $offset, $limit, $level, $site, $account, $viewing) = @_;
	
	scalar(@$tags) == 0 and
		return [];

	$limit ||= 'ALL';
	$offset ||= 0;

	my @bind;	
	my $sql = 'SELECT DISTINCT ON (combined_journals.sort_title, combined_journals.id) combined_journals.* FROM (';

	my @search;
	foreach my $tag (@$tags) {

		my $search_sql = '(SELECT cjdb_journals.* FROM cjdb_journals JOIN cjdb_tags ON (cjdb_journals.journals_auth = cjdb_tags.journals_auth) WHERE tag = ? AND cjdb_journals.site = ?';
		push @bind, $tag, $site;

		# Full on public search.
		
		if ($viewing == 0) {
			$search_sql .= ' AND cjdb_tags.viewing = ? ';
			push @bind, 0;
    		if ($account) {
    			$search_sql .= ' AND cjdb_tags.account = ?';
    			push @bind, $account;
    		}
		} elsif ($viewing == 1) {
			$search_sql .= ' AND cjdb_tags.viewing = ? AND cjdb_tags.site = ? ';
			push @bind, 1, $site;
    		if ($account) {
    			$search_sql .= ' AND cjdb_tags.account = ?';
    			push @bind, $account;
    		}
		} elsif ($viewing == 2) {
			$search_sql .= ' AND cjdb_tags.viewing = ? AND cjdb_tags.site = ? ';
			push @bind, 2, $site;
    		if ($account) {
    			$search_sql .= ' AND cjdb_tags.account = ?';
    			push @bind, $account;
    		}
		} elsif ($viewing == 3) {
			$search_sql .= ' AND (cjdb_tags.viewing = ? OR (cjdb_tags.viewing = ? AND cjdb_tags.site = ?) ';
			push @bind, 1, 2, $site;
    		if ($account) {
    			$search_sql .= ' OR (cjdb_tags.account = ? AND cjdb_tags.viewing = 0)';
    			push @bind, $account;
    		}
			
			$search_sql .= ')';
		} elsif ($viewing == 4) {
    		$search_sql .= ' AND (cjdb_tags.viewing = ? OR cjdb_tags.viewing = ?) AND cjdb_tags.site = ? ';
    		push @bind, 1, 2, $site;
    	}

		if ($level) {
			$search_sql .= ' AND cjdb_tags.level >= ?';
			push @bind, $level;
		}


		$search_sql .= ' )';
		push @search, $search_sql;
	}
		
	$sql .= join ' INTERSECT ', @search;
	$sql .= ") AS combined_journals ORDER BY combined_journals.sort_title, combined_journals.id LIMIT $limit OFFSET $offset";

#    warn($sql);
#    warn(join ',', @bind);

	my $dbh = $class->db_Main();
	$dbh->do('set enable_nestloop = off');
	
	my $sth = $dbh->prepare($sql, {pg_server_prepare => 0});
	$sth->execute(@bind);
	my @results = $class->sth_to_objects($sth);	
	$dbh->do('set enable_nestloop = on');
	
	return \@results;
}	




sub display_links {
    my ($self) = @_;
    my @results = CJDB::DB::Links->search_display($self->id);
    
    return \@results;
}


# Not moved to new database layout, see if it breaks (might not be used anywhere)

__PACKAGE__->set_sql('distinct_by_title' => qq{
	SELECT DISTINCT cjdb_journals.*
	FROM cjdb_journals JOIN cjdb_titles ON (cjdb_journals.id = cjdb_titles.journal)
	WHERE cjdb_journals.site = ? AND cjdb_titles.search_title LIKE ?
	ORDER BY cjdb_journals.sort_title
});



# Do a "LIKE" search on the titles and return in alphabetic order
sub search_distinct_title_by_journal_main {
    my ($class, $site, $title, $offset, $limit) = @_;

    $limit  ||= 'ALL';
    $offset ||= 0;

    my $sql = qq{
        SELECT cjdb_journals.*, titles_sorted.title AS result_title FROM (
            SELECT DISTINCT ON (cjdb_journals_titles.journal) cjdb_titles.title, cjdb_titles.search_title, cjdb_journals_titles.journal AS journal_id 
            FROM cjdb_titles
            JOIN cjdb_journals_titles ON (cjdb_titles.id = cjdb_journals_titles.title)
            WHERE cjdb_journals_titles.site = ?
            AND cjdb_titles.search_title LIKE ?
            ORDER BY cjdb_journals_titles.journal, cjdb_journals_titles.main DESC
        ) AS titles_sorted
        JOIN cjdb_journals ON (cjdb_journals.id = titles_sorted.journal_id)
        ORDER BY titles_sorted.search_title
        LIMIT $limit OFFSET $offset
    };

    my $sth = $class->db_Main()->prepare($sql, {pg_server_prepare => 0});
    my @results = $class->sth_to_objects( $sth, [$site, $title] );
    return \@results;
}

# Use a fulltext search through the titles and return in relevance order
sub search_distinct_title_by_journal_main_ft {
    my ($class, $site, $title, $offset, $limit) = @_;

    $limit  ||= 'ALL';
    $offset ||= 0;

    my $sql = qq{
        SELECT cjdb_journals.*, titles_sorted.title AS result_title,
               ts_rank_cd( to_tsvector('english', search_title), plainto_tsquery('english', 'journal of health service research') ) as rank
        FROM (

            SELECT DISTINCT ON (cjdb_journals_titles.journal) cjdb_titles.title, cjdb_titles.search_title, cjdb_journals_titles.journal AS journal_id,
                    ts_rank_cd( to_tsvector('english', search_title), plainto_tsquery('english', ?), 8 ) as rank
            FROM cjdb_titles
            JOIN cjdb_journals_titles ON (cjdb_titles.id = cjdb_journals_titles.title)
            WHERE cjdb_journals_titles.site = ?
            AND to_tsvector('english', search_title) @@ plainto_tsquery('english', ?)            
            ORDER BY cjdb_journals_titles.journal, rank DESC, cjdb_journals_titles.main DESC

        ) AS titles_sorted
        JOIN cjdb_journals ON (cjdb_journals.id = titles_sorted.journal_id)
        ORDER BY titles_sorted.rank DESC, titles_sorted.search_title
        LIMIT $limit OFFSET $offset
    };

    my $sth = $class->db_Main()->prepare($sql, {pg_server_prepare => 0});
    my @results = $class->sth_to_objects( $sth, [$title, $site, $title] );
    return \@results;
}


sub count_distinct_title_by_journal_main_ft {
    my ($class, $site, $title) = @_;

    my $sql = qq{
        SELECT COUNT(*) FROM (
            SELECT cjdb_journals_titles.journal
            FROM cjdb_titles
            JOIN cjdb_journals_titles ON (cjdb_titles.id = cjdb_journals_titles.title)
            WHERE cjdb_journals_titles.site = ?
            AND to_tsvector('english', search_title) @@ plainto_tsquery('english', ?)            
            GROUP BY cjdb_journals_titles.journal
        ) AS subsel
    };

    my @row = $class->db_Main()->selectrow_array( $sql, {}, $site, $title );
    return $row[0];
}

sub search_re_distinct_title_by_journal_main {
    my ($class, $site, $title, $offset, $limit) = @_;

    $limit  ||= 'ALL';
    $offset ||= 0;

    my $sql = qq{
        SELECT cjdb_journals.*, titles_sorted.title AS result_title FROM (
            SELECT DISTINCT ON (cjdb_journals_titles.journal) cjdb_titles.title, cjdb_titles.search_title, cjdb_journals_titles.journal AS journal_id 
            FROM cjdb_titles
            JOIN cjdb_journals_titles ON (cjdb_titles.id = cjdb_journals_titles.title)
            WHERE cjdb_journals_titles.site = ?
            AND cjdb_titles.search_title ~ ?
            ORDER BY cjdb_journals_titles.journal, cjdb_journals_titles.main DESC
        ) AS titles_sorted
        JOIN cjdb_journals ON (cjdb_journals.id = titles_sorted.journal_id)
        ORDER BY titles_sorted.search_title
        LIMIT $limit OFFSET $offset
    };

    my $sth = $class->db_Main()->prepare($sql, {pg_server_prepare => 0});
    my @results = $class->sth_to_objects( $sth, [$site, $title] );
    return \@results;
}    


sub search_distinct_title_by_journal_main_combined {
    my ($class, $join_type, $site, $search, $offset, $limit) = @_;

    # Return an empty set if there were no search terms

    return [] if scalar(@$search) == 0;

    $limit  ||= 'ALL';
    $offset ||= 0;

    my @search_terms = map { '[[:<:]]' . $_ . '[[:>:]]' } @$search;
    
    my $search_string;

    foreach my $x (0 .. $#search_terms - 1) {
        $search_string .= ' cjdb_titles.search_title ~ ? ' . $join_type;
    }
    $search_string .= ' cjdb_titles.search_title ~ ?';

    my $sql = qq{
        SELECT cjdb_journals.*, titles_sorted.title AS result_title FROM (
            SELECT DISTINCT ON (cjdb_journals_titles.journal) cjdb_titles.title, cjdb_titles.search_title, cjdb_journals_titles.journal AS journal_id 
            FROM cjdb_titles
            JOIN cjdb_journals_titles ON (cjdb_titles.id = cjdb_journals_titles.title)
            WHERE cjdb_journals_titles.site = ?
            AND ( $search_string )
            ORDER BY cjdb_journals_titles.journal, cjdb_journals_titles.main DESC
        ) AS titles_sorted
        JOIN cjdb_journals ON (cjdb_journals.id = titles_sorted.journal_id)
        ORDER BY titles_sorted.search_title
        LIMIT $limit OFFSET $offset
    };

    my @bind = ($site, @search_terms);
    my $sth = $class->db_Main()->prepare($sql, {pg_server_prepare => 0});
    my @results = $class->sth_to_objects($sth, \@bind);

    return \@results;
}

sub search_distinct_title_by_journal_main_any {
    my ($class, $site, $search, $offset, $limit) = @_;

    return $class->search_distinct_title_by_journal_main_combined('OR', $site, $search, $offset, $limit);
}

sub search_distinct_title_by_journal_main_all {
    my ($class, $site, $search, $offset, $limit) = @_;

    return $class->search_distinct_title_by_journal_main_combined('AND', $site, $search, $offset, $limit);
}



1;
