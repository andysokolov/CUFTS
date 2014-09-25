## CUFTS::DB::ERMCounterSources
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

package CUFTS::DB::ERMCounterSources;

use strict;
use base 'CUFTS::DB::DBI';

__PACKAGE__->table('erm_counter_sources');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    site
    type
    name
    reference
    version
    email
    erm_sushi

    last_run_timestamp
    next_run_date
    run_start_date
    interval_months
));
__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('erm_counter_sources_id_seq');

__PACKAGE__->has_a('erm_sushi' => 'CUFTS::DB::ERMSushi');
__PACKAGE__->has_many('counter_counts' => 'CUFTS::DB::ERMCounterCounts');
__PACKAGE__->has_many('counter_links' => 'CUFTS::DB::ERMCounterLinks');


# Gets database usage from attached JR1 COUNTER reports.  Returns data like:
# [ { start_date => '2009-01-01', count => 1000 }, ... ]

sub database_usage_from_jr1 {
    my ( $self, $start_date, $end_date ) = @_;

    # Do some date checking here!

    my $sth = CUFTS::DB::ERMCounterCounts->sql_sum_counts_by_counter_source();
    $sth->execute($self->id, $start_date, $end_date);
    return $sth->fetchall_arrayref({});
}

1;

__END__

Types:
j - journal data
d - database data
