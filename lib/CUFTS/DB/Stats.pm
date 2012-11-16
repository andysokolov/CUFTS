## CUFTS::DB::Stats
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

package CUFTS::DB::Stats;

use strict;
use base 'CUFTS::DB::DBI';


__PACKAGE__->table('stats');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id

    request_date
    request_time

    site

    issn
    isbn
    title
    volume
    issue
    date
    doi
    results
));                                                                                                        

__PACKAGE__->sequence('stats_id_seq');

sub normalize_column_values {
    my ($self, $values) = @_;
    
    # Check ISSNs for dashes and strip them out

    if ( exists($values->{title}) && defined($values->{title}) ) {
        $values->{title} = substr( $values->{title}, 0, 512 );
    }
    
    if (exists($values->{issn}) && defined($values->{issn}) && $values->{issn} ne '') {
        $values->{issn} = uc($values->{issn});
        if ( $values->{issn} !~ s/(\d{4})\-?(\d{3}[\dxX])/$1$2/ ) {
            warn("Invalid ISSN skipped in statistics.")
        }
    }
    
    return 1;   # ???
}


__PACKAGE__->set_sql('top50journals' => qq{
    SELECT issn, title, COUNT(*) as requests FROM
    __TABLE__
    WHERE request_date > (current_date - interval '%s')
    AND site = ?
    AND results = ?
    AND ( ( title IS NOT NULL AND title != '' ) OR ( issn IS NOT NULL AND issn != '' ) )
    GROUP BY issn, title 
    ORDER BY COUNT(*) DESC
    LIMIT 50
});

__PACKAGE__->set_sql('requests_count' => qq{
    SELECT COUNT(*) FROM
    __TABLE__
    WHERE request_date > (current_date - interval '%s')
    AND site = ?
});

__PACKAGE__->set_sql('requests_count_fulltext' => qq{
    SELECT COUNT(*) FROM
    __TABLE__
    WHERE request_date > (current_date - interval '%s')
    AND site = ?
    AND results = 't'
});




sub top50journals {
    my ($class, $site, $time, $results) = @_;
    
    my $sth = $class->sql_top50journals(_internal_time($time));
    $sth->execute($site, $results);
    my $records = $sth->fetchall_arrayref;

    return $records;
}

sub requests_count {
    my ($class, $site, $time) = @_;
    
    my %results;

    my $sth = $class->sql_requests_count(_internal_time($time));
    $sth->execute($site);
    my @row = $sth->fetchrow_array;
    $results{'total_requests'} = $row[0];

    $sth = $class->sql_requests_count_fulltext(_internal_time($time));
    $sth->execute($site);
    @row = $sth->fetchrow_array;
    $results{'requests_with_fulltext'} = $row[0];

    return \%results;
}


sub _internal_time {
    $_[0] eq 'last_week' and
        return '1 week';
    $_[0] eq 'last_month' and
        return '1 month';
    $_[0] eq 'last_year' and
        return '1 year';

    CUFTS::Exception->throw("Unrecognized time period: $_[0]");
}


1;

