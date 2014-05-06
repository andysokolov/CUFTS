## CUFTS::DB::Journals
##
## Copyright Todd Holbrook, Simon Fraser University (2003)
##
## This file is part of CUFTS.
##
## CUFTS is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
##
## CUFTS is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CUFTS; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

package CUFTS::DB::JournalsAuth;

use strict;
use base 'CUFTS::DB::DBI';

use CUFTS::DB::JournalsAuthTitles;
use CUFTS::DB::JournalsAuthISSNs;
use CUFTS::DB::Journals;
use CUFTS::DB::LocalJournals;
use MARC::Record;
use MARC::File::USMARC;

__PACKAGE__->table('journals_auth');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	title
	MARC
	RSS

	created
	modified
));
__PACKAGE__->columns(Essential => qw(
	id
	title
	MARC
	RSS
));

__PACKAGE__->sequence('journals_auth_id_seq');

__PACKAGE__->has_many('titles', 'CUFTS::DB::JournalsAuthTitles' => 'journal_auth');
__PACKAGE__->has_many('issns',  'CUFTS::DB::JournalsAuthISSNs'  => 'journal_auth');

__PACKAGE__->has_many('local_journals',  'CUFTS::DB::LocalJournals' => 'journal_auth', { cascade => 'None'} );
__PACKAGE__->has_many('global_journals' => 'CUFTS::DB::Journals', { cascade => 'None'} );

sub search_by_issns {
	my ($class, @issns) = @_;

	scalar(@issns) == 0 and
		return ();

	my @bind;
	my $sql = 'SELECT DISTINCT ON (journals_auth.id) journals_auth.* FROM journals_auth JOIN journals_auth_issns ON (journals_auth.id = journals_auth_issns.journal_auth) WHERE journals_auth_issns.issn IN (';

	my $count = 0;
	foreach my $issn (@issns) {
		$issn = uc($issn);
		$issn =~ tr/0-9X//cd;
		$issn =~ /^\d{7}[\dX]$/ or
			next;

		$count++;
		$sql .= '?';
		$count == scalar(@issns) or
			$sql .= ',';

		push @bind, $issn;
	}

	$sql .= ')';

	my $dbh = $class->db_Main();
	my $sth = $dbh->prepare_cached($sql);
	$sth->execute(@bind);

	my @results = $class->sth_to_objects($sth);

	return @results;
}

sub search_by_exact_title_with_no_issns {
	my ($class, $title) = @_;

	my $sql = 'SELECT journals_auth.* FROM journals_auth LEFT OUTER JOIN journals_auth_issns ON (journals_auth.id = journals_auth_issns.journal_auth) WHERE journals_auth_issns.issn IS NULL AND journals_auth.title ilike ?';

	my $dbh = $class->db_Main();
	my $sth = $dbh->prepare_cached($sql);
	$sth->execute($title);

	my @results = $class->sth_to_objects($sth);

	return @results;
}


sub search_by_title_with_no_issns {
	my ( $class, $title ) = @_;

	my $sql = 'SELECT DISTINCT ON (journals_auth.id) journals_auth.* FROM journals_auth JOIN journals_auth_titles ON (journals_auth_titles.journal_auth = journals_auth.id) LEFT OUTER JOIN journals_auth_issns ON (journals_auth.id = journals_auth_issns.journal_auth) WHERE journals_auth_issns.issn IS NULL AND journals_auth.title ILIKE ?';

	my $dbh = $class->db_Main();
	my $sth = $dbh->prepare_cached($sql);
	$sth->execute($title);

	my @results = $class->sth_to_objects($sth);

	return @results;
}

sub has_fulltext {
    my ( $self, $journal_auth_id ) = @_;

    if ( !ref($self) && !defined($journal_auth_id) ) {
        die("Error: has_fulltext called on class, but no journal auth id was passed in.");
    }

    $journal_auth_id = $self->id;  # $self

    my $sql = "SELECT COUNT(*) FROM journals WHERE journal_auth = ? AND (";
    $sql .= join ' OR ', map { "$_ IS NOT NULL" } @CUFTS::Config::CUFTS_JOURNAL_FT_FIELDS;
    $sql .= ')';

    my $dbh = $self->db_Main();
	my $sth = $dbh->prepare_cached($sql);
	$sth->execute($journal_auth_id);
	my @result = $sth->fetchrow_array;
    $sth->finish;

    return $result[0];
}

sub search_by_title {
    my ( $class, $title ) = @_;

	my $sql = 'SELECT DISTINCT ON (journals_auth.id) journals_auth.* FROM journals_auth JOIN journals_auth_titles ON (journals_auth_titles.journal_auth = journals_auth.id) WHERE journals_auth_titles.title ILIKE ?';

	my $dbh = $class->db_Main();
	my $sth = $dbh->prepare_cached($sql);
	$sth->execute($title);

	my @results = $class->sth_to_objects($sth);

	return @results;
}

# __PACKAGE__->set_sql('by_title' => qq{
#   SELECT DISTINCT ON (journals_auth.id) journals_auth.* FROM journals_auth JOIN journals_auth_titles ON (journals_auth_titles.journal_auth = journals_auth.id) WHERE journals_auth_titles.title ILIKE ?
# });

sub marc_object {
	my ($self) = @_;

	defined($self->MARC) or
		return undef;

	my $obj = MARC::File::USMARC->decode($self->marc);
	return $obj;
}

1;

__END__
