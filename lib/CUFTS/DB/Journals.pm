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

package CUFTS::DB::Journals;

use CUFTS::DB::LocalJournals;
use CUFTS::DB::Resources;

use strict;
use base 'CUFTS::DB::DBI';
use SQL::Abstract;

use CUFTS::Util::Simple;

__PACKAGE__->table('journals');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id

    title
    issn
    e_issn
    resource
    vol_cit_start
    vol_cit_end
    vol_ft_start
    vol_ft_end
    iss_cit_start
    iss_cit_end
    iss_ft_start
    iss_ft_end
    cit_start_date
    cit_end_date
    ft_start_date
    ft_end_date
    embargo_months
    embargo_days

    db_identifier   
    toc_url
    journal_url
    urlbase
    publisher
    abbreviation
    current_months
    current_years
    coverage
    cjdb_note
    local_note

    journal_auth

    created
    scanned
    modified
));                                                                                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('journals_id_seq');


__PACKAGE__->has_many('localjournals', 'CUFTS::DB::LocalJournals' => 'journal');

__PACKAGE__->has_a('resource', 'CUFTS::DB::Resources');
__PACKAGE__->has_a('journal_auth', 'CUFTS::DB::JournalsAuth');


sub normalize_column_values {
    my ($self, $values) = @_;
    
    # Check ISSNs for dashes and strip them out

    if (exists($values->{'issn'}) && defined($values->{'issn'}) && $values->{'issn'} ne '') {
        $values->{'issn'} = uc($values->{'issn'});
        $values->{'issn'} =~ s/(\d{4})\-?(\d{3}[\dxX])/$1$2/ or
            $self->_croak('issn is not valid: ' . $values->{'issn'});
    }

    if (exists($values->{'e_issn'}) && defined($values->{'e_issn'}) && $values->{'e_issn'} ne '') {
        $values->{'e_issn'} = uc($values->{'e_issn'});
        $values->{'e_issn'} =~ s/(\d{4})\-?(\d{3}[\dxX])/$1$2/ or
            $self->_croak('e_issn is not valid: ' . $values->{'e_issn'});
    }

    # Set default dates if they're just years or years/months
    
    $values->{ft_start_date}  = set_default_dates($values->{ft_start_date}, 'start')  if exists($values->{ft_start_date});
    $values->{cit_start_date} = set_default_dates($values->{cit_start_date}, 'start') if exists($values->{cit_start_date});

    $values->{ft_end_date}  = set_default_dates($values->{ft_end_date}, 'end')  if exists($values->{ft_end_date});
    $values->{cit_end_date} = set_default_dates($values->{cit_end_date}, 'end') if exists($values->{cit_end_date});

    return 1;   # ???
}

__PACKAGE__->set_sql('by_title' => qq{
SELECT __ESSENTIAL__ FROM __TABLE__ WHERE LOWER(title) LIKE ?
}); 

__PACKAGE__->set_sql('distinct_journal_issn_by_title' => qq{
SELECT DISTINCT ON (title, issn) __ESSENTIAL__
FROM __TABLE__
WHERE LOWER(title) LIKE ?
ORDER BY title
});

__PACKAGE__->set_sql('distinct_journal_issn_by_issn' => qq{
SELECT DISTINCT ON (title, issn) __ESSENTIAL__
FROM __TABLE__
WHERE issn = ?
ORDER BY title
});

__PACKAGE__->set_sql('all_journals_distinct_title_issn' => qq{
SELECT DISTINCT ON (title, issn) __ESSENTIAL__
FROM __TABLE__
});



##
## Switch tables to use a view which returns the same columns as the journals table, but
## preselects active journals.
##
## *** MUST PASS IN local_resource_id AS THE FIRST TERM
##
sub search_active {
    my $class = shift;
    my $local_resource_id = shift;

    defined($local_resource_id) && !($local_resource_id =~ /\D/) && int($local_resource_id) > 0 or
        $class->_croak('local_resource_id passed to search_active is not a number');

    $class->table('journals_active');
    my @result = $class->search_where('local_resource', $local_resource_id, @_);
    $class->table('journals');
    return \@result;
}


1;
