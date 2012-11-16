## CUFTS::DB::ERMCounterCounts
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

package CUFTS::DB::ERMCounterCounts;

use strict;
use base 'CUFTS::DB::DBI';

use Date::Calc qw(Days_in_Month);

__PACKAGE__->table('erm_counter_counts');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    counter_title
    counter_source
    start_date
    end_date
    type
    count
    timestamp
));                                                                                                        
__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('erm_counter_counts_id_seq');

__PACKAGE__->has_a('counter_title', 'CUFTS::DB::ERMCounterTitles');
__PACKAGE__->has_a('counter_source', 'CUFTS::DB::ERMCounterSources');

__PACKAGE__->set_sql('stats_by_counter_source' => qq{
    SELECT start_date, COUNT(*) AS count FROM erm_counter_counts WHERE counter_source = ? GROUP BY start_date ORDER BY start_date DESC;
});

__PACKAGE__->set_sql('sum_counts_by_counter_source' => qq{
    SELECT start_date, SUM(count) AS count FROM __TABLE__ WHERE counter_source = ? AND start_date >= ? AND start_date <= ? GROUP BY start_date ORDER BY start_date;
});

sub normalize_column_values {
    my ($self, $values) = @_;
    
    # Set the end date if it isn't already set.

    if ( !exists($values->{end_date}) && defined($values->{start_date}) && $values->{start_date} =~ /(\d{4})-(\d{2})-\d{2}/ ) {
        $values->{end_date} = "$1-$2-" . Days_in_Month($1,$2);
    }

    return 1;   # ???
}

1;

