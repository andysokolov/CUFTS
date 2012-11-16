## CJDB::DB::Titles
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

package CJDB::DB::Titles;

use strict;
use base 'CJDB::DB::DBI';
use CJDB::DB::JournalsTitles;

__PACKAGE__->table('cjdb_titles');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    title
    search_title
));                                                                                                    
__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('cjdb_titles_id_seq');
__PACKAGE__->has_many('journals', [ 'CJDB::DB::JournalsTitles' => 'journal' ] );


sub search_titlelist {
    my ($class, $site, $title, $offset, $limit) = @_;

    $limit  ||= 'ALL';
    $offset ||= 0;

    my $sql = "SELECT DISTINCT on (search_title) title FROM cjdb_titles WHERE cjdb_titles.site = ? AND cjdb_titles.search_title LIKE ? ORDER BY search_title LIMIT $limit OFFSET $offset";
    my $dbh = $class->db_Main();
    my $sth = $dbh->prepare($sql, {pg_server_prepare => 0});

    $sth->execute($site, $title);
    my $results = $sth->fetchall_arrayref;
    return $results;
}


sub search_distinct_by_journal_main {
    my ($class, $site, $title, $offset, $limit) = @_;

    $limit ||= 'ALL';
    $offset ||= 0;

    my $sql = "SELECT * FROM (SELECT DISTINCT on (journal) * FROM cjdb_titles WHERE cjdb_titles.site = ? AND cjdb_titles.search_title LIKE ? ORDER BY journal, main DESC) AS titles_sorted ORDER BY titles_sorted.search_title LIMIT $limit OFFSET $offset";
    my $dbh = $class->db_Main();
    my $sth = $dbh->prepare($sql, {pg_server_prepare => 0});

    $sth->execute($site, $title);
    my @results = $class->sth_to_objects($sth);
    return \@results;
}    

sub search_re_distinct_by_journal_main {
    my ($class, $site, $title, $offset, $limit) = @_;

    $limit  ||= 'ALL';
    $offset ||= 0;

    my $sql = "SELECT * FROM (SELECT DISTINCT on (journal) * FROM cjdb_titles WHERE cjdb_titles.site = ? AND cjdb_titles.search_title ~ ? ORDER BY journal, main DESC) AS titles_sorted ORDER BY titles_sorted.search_title LIMIT $limit OFFSET $offset";
    my $dbh = $class->db_Main();
    my $sth = $dbh->prepare($sql, {pg_server_prepare => 0});

    $sth->execute($site, $title);
    my @results = $class->sth_to_objects($sth);
    return \@results;
}    


sub search_distinct_by_journal_main_combined {
    my ($class, $join_type, $site, $search, $offset, $limit) = @_;

    defined($join_type) && ($join_type =~ /^(INTERSECT|UNION|EXCEPT)$/) or
        CJDB::Exception::DB->throw("Bad join type in search_distinct_by_journal_main_combined: $join_type");


    # Return an empty set if there were no search terms

    return [] if scalar(@$search) == 0;

    $limit ||= 'ALL';
    $offset ||= 0;

    foreach my $x (0..$#$search) {
        $search->[$x] = '\m' . $search->[$x] . '\M';
    }

    my $search_string = 'SELECT * FROM cjdb_titles WHERE cjdb_titles.site = ? AND cjdb_titles.search_title ~ ?';

    my $sql = 'SELECT * FROM (SELECT DISTINCT ON (journal) * FROM (';

    $sql .= $search_string;
    foreach my $count (1 .. (scalar(@$search) - 1)) {
        $sql .= " $join_type $search_string";
    }

    $sql .= ") AS combined_journals ORDER BY journal,main DESC) AS titles_sorted ORDER BY titles_sorted.search_title LIMIT $limit OFFSET $offset";

    my @bind;
    foreach my $search_term (@$search) {
        push @bind, ($site, $search_term);
    }

    my $dbh = $class->db_Main();
    my $sth = $dbh->prepare($sql, {pg_server_prepare => 0});
    $sth->execute(@bind);
    my @results = $class->sth_to_objects($sth);

    return \@results;
}

sub search_distinct_by_journal_main_union {
    my ($class, $site, $search, $offset, $limit) = @_;

    return $class->search_distinct_by_journal_main_combined('UNION', $site, $search, $offset, $limit);
}

sub search_distinct_by_journal_main_intersect {
    my ($class, $site, $search, $offset, $limit) = @_;

    return $class->search_distinct_by_journal_main_combined('INTERSECT', $site, $search, $offset, $limit);
}

1;
