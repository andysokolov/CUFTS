## CUFTS::Resources::JournalAuth
##
## Copyright Todd Holbrook - Simon Fraser University (2003)
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

package CUFTS::Resources::JournalAuth;

use base qw(CUFTS::Resources::Base::Journals);

use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use CUFTS::DB::JournalsAuth;

use strict;

sub local_resource_details       { return []    }
sub global_resource_details      { return []    }
sub overridable_resource_details { return []    }
sub help_template                { return undef }
sub has_title_list               { return 0     }

sub get_records {
    my ( $class, $resource, $site, $request ) = @_;

    my $issn = not_empty_string( $request->issn ) ? $request->issn : $request->eissn;

    if ( not_empty_string($issn) ) {

        my @ja_match = CUFTS::DB::JournalsAuthISSNs->search( issn => $issn );
        if ( scalar(@ja_match) != 1 ) {
            # No matches, or multiple matches that we can't disambiguate yet.
            return undef;
        }

        my @ja_issns = CUFTS::DB::JournalsAuthISSNs->search( journal_auth => $ja_match[0]->journal_auth, issn => { '!=' => $issn } );
        if ( scalar(@ja_issns) ) {
            my $existing_issns = $request->other_issns;
            if ( !defined($existing_issns) ) {
                $existing_issns = [];
            }
            push @$existing_issns, map { $_->issn } @ja_issns;
            $request->other_issns( $existing_issns );
        }

        # Add the title to the original request if it's missing
        if ( is_empty_string($request->title) ) {
            my $ja = $ja_match[0]->journal_auth;
            if ( defined($ja) && not_empty_string($ja->title) ) {
                $request->title( $ja->title );
            }
        }

    }
    elsif ( not_empty_string($request->title) ) {
        # No ISSN found, try a title lookup to grab some JA records and attach their ids to the request

        my @ja_ids = map { $_->id } CUFTS::DB::JournalsAuth->search_by_title($request->title);

        if ( scalar(@ja_ids) && scalar(@ja_ids) < 10 ) {
            $request->journal_auths( \@ja_ids );
        }
    }


    return undef;
}

sub can_getMetadata {
    my ( $class, $request ) = @_;

    if (    not_empty_string( $request->issn )
         || not_empty_string( $request->eissn )
         || not_empty_string( $request->title )
    ) {
        return 1;
    }

    return 0;
}

1;
