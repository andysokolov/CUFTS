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
use CUFTS::Config;
use String::Util qw(trim hascontent);

sub services {
    return [ qw( metadata ) ];
}

use strict;

sub local_resource_details       { return []    }
sub global_resource_details      { return []    }
sub overridable_resource_details { return []    }
sub help_template                { return undef }
sub has_title_list               { return 0     }

sub get_records {
    my ( $class, $schema, $resource, $site, $request ) = @_;

    $schema ||= CUFTS::Config::get_schema();

    my $issn = hascontent( $request->issn ) ? $request->issn : $request->eissn;

    if ( hascontent($issn) ) {

        my @ja_match = $schema->resultset('JournalsAuthISSNs')->search({ issn => $issn })->all;
        if ( scalar @ja_match != 1 ) {
            # No matches, or multiple matches that we can't disambiguate yet.
            return undef;
        }

        my @ja_issns = $ja_match[0]->journal_auth->issns({ issn => { '!=' => $issn } })->all;
        if ( scalar @ja_issns ) {
            my $existing_issns = $request->other_issns;
            if ( !defined $existing_issns ) {
                $existing_issns = [];
            }
            push @$existing_issns, map { $_->issn } @ja_issns;
            $request->other_issns( $existing_issns );
        }

        # Add the title to the original request if it's missing
        if ( !hascontent($request->title) ) {
            my $ja = $ja_match[0]->journal_auth;
            if ( defined($ja) && hascontent($ja->title) ) {
                $request->title( $ja->title );
            }
        }

        # Include that first match as journal_auths match, it will likely come up from the augmentations above, but there are a few rare cases where this works better.
        $request->journal_auths( [ $ja_match[0]->get_column('journal_auth') ] );

    }
    elsif ( hascontent($request->title) ) {
        # No ISSN found, try a title lookup to grab some JA records and attach their ids to the request

        my @ja_ids = map { $_->id } $schema->resultset('JournalsAuth')->search_by_title($request->title);

        if ( scalar(@ja_ids) && scalar(@ja_ids) < 10 ) {
            $request->journal_auths( \@ja_ids );
        }
    }


    return undef;
}

sub can_getMetadata {
    my ( $class, $request ) = @_;

    if (    hascontent( $request->issn )
         || hascontent( $request->eissn )
         || hascontent( $request->title )
    ) {
        return 1;
    }

    return 0;
}

1;
