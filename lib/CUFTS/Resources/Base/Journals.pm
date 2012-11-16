## CUFTS::ResourceTypes::Base::Journals
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

package CUFTS::Resources::Base::Journals;

use base qw(CUFTS::Resources);

use strict;
use CUFTS::DB::Journals;
use CUFTS::DB::Resources;
use CUFTS::DB::LocalResources;
use CUFTS::Util::Simple;

use Date::Calc;

use CUFTS::Exceptions;
use SQL::Abstract;

##
## So far these are all class data constants
##

sub global_db_module {
    return 'CUFTS::DB::Journals';
}

sub active_global_db_module {
    return 'CUFTS::DB::JournalsActive';
}

sub local_db_module {
    return 'CUFTS::DB::LocalJournals';
}

sub has_title_list {
    return 1;
}

# Used to help identify a specific journal line in a title list.  EBSCO, for example may
# list the same journal multiple times, however each line has a unique identifier.
sub unique_title_list_identifier {
    return undef;
}

sub global_resource_details {
    return [qw(database_url notes_for_local)];
}

sub local_resource_details {
    return [qw(database_url cjdb_note)];
}

sub overridable_resource_details {
    return [qw(database_url cjdb_note)];
}

sub resource_details_help {
    return {
        %{ $_[0]->SUPER::resource_details_help },
        'database_url' =>
            "URL linking to the resource at a database level.\nOnly necessary when linking to local resource or gateway.",
        'notes_for_local' =>
            "Notes which will be displayed when editing the\nlocal resource.",
    };
}

sub help_template {
    return 'help/journals_common';
}

# Ordered field list for setting up display, editting, and export tables

sub title_list_fields {
    return [
        qw(
            id
            title
            issn
            e_issn
            ft_start_date
            ft_end_date
            embargo_months
            embargo_days
            current_months
            current_years
            coverage
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end

            cit_start_date
            cit_end_date
            vol_cit_start
            vol_cit_end
            iss_cit_start
            iss_cit_end

            db_identifier
            toc_url
            journal_url
            urlbase
            publisher
            abbreviation
            
            journal_auth
            
        )
    ];
}

sub overridable_title_list_fields {
    return [
        qw(
            ft_start_date
            ft_end_date
            vol_ft_start
            vol_ft_end
            iss_ft_start
            iss_ft_end
            embargo_months
            embargo_days
            current_months
            current_years
            coverage
            
            db_identifier   
            toc_url
            journal_url
            urlbase
            publisher
            abbreviation
            

            cit_start_date
            cit_end_date
            vol_cit_start
            iss_cit_start
            vol_cit_end
            iss_cit_end

            cjdb_note
            local_note

            journal_auth
        )
    ];
}

sub title_list_field_map {
    return {
        'title'          => 'title',
        'issn'           => 'issn',
        'e_issn'         => 'e_issn',
        'ft_start_date'  => 'ft_start_date',
        'ft_end_date'    => 'ft_end_date',
        'cit_start_date' => 'cit_start_date',
        'cit_end_date'   => 'cit_end_date',
        'vol_ft_start'   => 'vol_ft_start',
        'vol_ft_end',    => 'vol_ft_end',
        'iss_ft_start'   => 'iss_ft_start',
        'iss_ft_end'     => 'iss_ft_end',
        'db_identifier'  => 'db_identifier',
        'journal_url'    => 'journal_url',
        'embargo_days'   => 'embargo_days',
        'embargo_months' => 'embargo_months',
        'publisher'      => 'publisher',
        'abbreviation'   => 'abbreviation',
        'current_months' => 'current_months',
        'current_years'  => 'current_years',
        'coverage'       => 'coverage',
        'cjdb_note'      => 'cjdb_note',
        'local_note'     => 'local_note',
        'journal_auth'   => 'journal_auth',
    };
}

sub local_matchable_on_columns {
    return [ '', 'issn', 'title', 'issn,title' ];
}

sub local_to_global_field {
    return 'journal';
}

# Returns an array ref for plugging into Abstract::SQL for filtering
# records for display.  Done here so we can optimize ISSN search,
# remove ISSNs from search if they'll never match, etc.

sub filter_on {
    my ( $class, $string ) = @_;

    if ( $string =~ s/^(\d{4})-?(\d{3}[\dxX])$/$1$2/ ) {
        $string = uc($string);
        return [ 'issn' => $string, 'e_issn' => $string ];
    }
    elsif ( $string =~ /[^-0-9xX]/ ) {
        return [ 'title' => { ilike => "\%$string\%" } ];
    }
    else {
        return [
            'title'  => { ilike => "\%$string\%" },
            'issn'   => { ilike => "\%$string\%" },
            'e_issn' => { ilike => "\%$string\%" }
        ];
    }
}

sub clean_data {
    my ( $class, $record ) = @_;

    my @errors;

    # Validate ISSN

    if ( defined( $record->{'issn'} ) ) {
        if ( $record->{'issn'} =~ / (\d{4}) [-\s]? (\d{3}[\dxX]) /xsm ) {
            $record->{'issn'} = uc("$1$2");
        }
        else {
            push @errors, 'ISSN is not valid: ' . $record->{'issn'};
            delete $record->{'issn'};
        }
    }

    # Validate e-ISSN

    if ( defined( $record->{'e_issn'} ) ) {
        if ( $record->{'e_issn'} =~ / (\d{4}) [-\s]? (\d{3}[\dxX]) /xsm ) {
            $record->{'e_issn'} = uc("$1$2");
        }
        else {
            push @errors, 'e-ISSN is not valid: ' . $record->{'e_issn'};
            delete $record->{'e_issn'};
        }
    }

    # Remove extra quotes and spaces from titles
    $record->{'title'} = trim_string($record->{'title'}, '"');
    $record->{'title'} = trim_string($record->{'title'});

    # Check to make sure there's an (e-)ISSN or title

    if (    is_empty_string( $record->{'issn'} )
         && is_empty_string( $record->{'e_issn'} ) 
         && is_empty_string( $record->{'title'} )  )
    {
        push @errors, 'Neither ISSN or title are defined';
    }
    
    # Clean up volume and issue ranges
    
    foreach my $field ( qw( vol_ft_start iss_ft_start vol_cit_start iss_cit_start ) ) {
        if ( not_empty_string($record->{$field}) ) {
            $record->{$field} =~ s/-.*$//;
            # $record->{$field} =~ tr/\d//cd;
        }
    }

    foreach my $field ( qw( vol_ft_end iss_ft_end vol_cit_end iss_cit_end ) ) {
        if ( not_empty_string($record->{$field}) ) {
            $record->{$field} =~ s/^.*-//;
            # $record->{$field} =~ tr/\d//cd;
        }
    }
    
    

    push @errors, @{ $class->clean_data_dates($record) };
    push @errors, @{ $class->SUPER::clean_data($record) };

    return \@errors;
}

sub duplicate_for_loading_fields {
    return [ 'issn', 'e_issn', 'title' ];
}

sub clean_data_dates {
    my ( $class, $record ) = @_;

    my @end = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

    # Set incomplete start date fields to -01 or -01-01

    foreach my $field ( keys %$record ) {
        next unless $field =~ /start_date$/;
        next unless not_empty_string( $record->{$field} );

        if ( $record->{$field} =~ /^(\d{4})-?(\d{2})$/ ) {
            my $year = $1;
            my $month = $2 eq '00' ? '01' : $2;
            $record->{$field} = "${year}-${month}-01";
        }
        elsif ( $record->{$field} =~ /^(\d{4})$/ ) {
            $record->{$field} = "$1-01-01";
        }
    }

    foreach my $field ( keys %$record ) {
        next unless $field =~ /end_date$/;
        next unless not_empty_string( $record->{$field} );

        if ( $record->{$field} =~ /^(\d{4})-?(\d{2})$/ ) {
            my $year = $1;
            my $month = $2 eq '00' ? '01' : $2;
            $record->{$field} = "${year}-${month}-" . $end[ int($month) - 1 ];
        }
        elsif ( $record->{$field} =~ /^(\d{4})$/ ) {
            $record->{$field} = "$1-12-31";
        }
    }

    return [];
}

sub _find_existing_title {
    my ( $class, $resource_id, $record, $local ) = @_;

    $^W    = 0;
    $local = ( $local == 1 || $local eq 'local' ) ? 'local' : 'global';
    $^W    = 1;

    no strict 'refs';

    my $method = "${local}_db_module";
    my $module = $class->$method
        or CUFTS::Exception::App->throw("resource does not have an associated database module for loading title lists");

    my $search = { 'resource' => $resource_id };
    
    if ( not_empty_string($record->{issn}) ) {
        $search->{issn} = $record->{issn};
    }
    if ( not_empty_string($search->{eissn}) ) {
        $search->{eissn} = $record->{eissn};
    }
    if ( !exists($search->{issn}) && !exists($search->{eissn}) ) {
        $search->{title} = $record->{title};
    }

    my @titles = $module->search($search);

#	warn('No matched titles on issn/title search: ' . $record->{'issn'} . ' - ' . $record->{'title'}) unless scalar(@titles) > 0;

    my @matched_titles;

    # Run through all the columns because there may be a column removed from the new
    # record which would cause it to match otherwise


TITLE:
    foreach my $title (@titles) {

        # Check normal columns, skip date/id ones, and resource id

COLUMN:
        foreach my $column ( $title->columns ) {
            next COLUMN
                if grep { $column eq $_ } qw( id created modified scanned resource active journal_auth );

            next COLUMN
                if is_empty_string($record->{$column}) && is_empty_string($title->$column);

            next TITLE
                if is_empty_string($record->{$column}) || is_empty_string($title->$column);

            next TITLE
                if $title->$column ne $record->{$column};
        }

        push @matched_titles, $title;
    }

    scalar(@matched_titles) > 1
        and CUFTS::Exception::App->throw('Multiple matching title rows found while updating.');

    return scalar(@matched_titles) == 1 
           ? $matched_titles[0] 
           : undef;
}

sub _find_partial_match {
    my ( $class, $resource_id, $record, $local ) = @_;

    $^W    = 0;
    $local = ( $local == 1 || $local eq 'local' ) ? 'local' : 'global';
    $^W    = 1;

    no strict 'refs';

    my $method = "${local}_db_module";
    my $module = $class->$method
        or CUFTS::Exception::App->throw("resource does not have an associated database module for loading title lists");

    my $search = { resource => $resource_id };

    $search->{issn} = not_empty_string($record->{issn})
                        ? $record->{issn}
                        : undef;

    $search->{e_issn} = not_empty_string($record->{e_issn})
                        ? $record->{e_issn}
                        : undef;

    $search->{title} = $record->{title};
    
    my $unique_field = $class->unique_title_list_identifier;
    if ( defined($unique_field) && not_empty_string($record->{$unique_field}) ) {
        $search->{$unique_field} = $record->{$unique_field};
    }
 
    my @titles = $module->search($search);

    return scalar(@titles) == 1 ? $titles[0] : undef;
}

sub _modify_record {
    my ( $class, $resource, $new_record, $old_record, $timestamp, $local ) = @_;

    $class->log_modified_title( $resource, $old_record, $new_record, $timestamp, $local );

    $^W = 0; # Turn off warnings because of the large number of eq matches against undef fields below.

    foreach my $column ( $old_record->columns ) {
        next
            if grep { $column eq $_ } qw( id created modified scanned resource active journal_auth );

        if ( $old_record->$column ne $new_record->{$column} ) {
            if ( not_empty_string( $new_record->{$column} ) ) {
                $old_record->$column( $new_record->{$column} );
            }
            else {
                $old_record->$column( undef );
            }
        }
    }

    $^W = 1;

    if ( $local eq 'local' ) {
        $old_record->active('t');
    }

    $old_record->modified($timestamp);
    $old_record->scanned($timestamp);
    $old_record->update;

    return;
}

sub can_getFulltext {
    my ( $class, $request ) = @_;

    if (   defined( $request->genre )
        && ( $request->genre eq 'article' || $request->genre eq 'journal' )
        && ( not_empty_string( $request->issn ) || not_empty_string( $request->title ) )
        || not_empty_string( $request->eissn ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

sub can_getTOC {
    my ( $class, $request ) = @_;

    if (   defined( $request->genre )
        && ( $request->genre eq 'article' || $request->genre eq 'journal' )
        && ( not_empty_string( $request->issn ) || not_empty_string( $request->title ) )
        || not_empty_string( $request->eissn ) )
    {
        return 1;
    }
    else {
        return 0;
    }

}

sub can_getJournal {
    my ( $class, $request ) = @_;

    if (   defined( $request->genre )
        && ( $request->genre eq 'article' || $request->genre eq 'journal' )
        && ( not_empty_string( $request->issn ) || not_empty_string( $request->title ) )
        || not_empty_string( $request->eissn ) )
    {
        return 1;
    }
    else {
        return 0;
    }
}

sub can_getDatabase {
    my ( $class, $request ) = @_;

    return 1;
}

sub get_records {
    my ( $class, $resource, $site, $request ) = @_;

    my $active = $class->_search_active( $resource, $site, $request );

    # Do date range check, embargo, etc...

    $active = $class->filter_fulltext( $active, $resource, $site, $request );

    return $active;
}

sub search_getFulltext {
    my ( $class, $resource, $site, $request ) = @_;

    my $active = $class->_search_active( $resource, $site, $request );

    # Do date range check, embargo, etc...

    $active = $class->filter_fulltext( $active, $resource, $site, $request );

    $class->can('build_linkFulltext')
        or CUFTS::Exception::App->throw("No build_linkFulltext method defined for class: $class");

    if ( defined($active) && scalar(@$active) > 0 ) {
        return $class->build_linkFulltext( $active, $resource, $site, $request );
    }
    else {
        return undef;
    }
}

sub search_getJournal {
    my ( $class, $resource, $site, $request ) = @_;

    my $active = $class->_search_active( $resource, $site, $request );

    # Do date range check, embargo, etc...

    $active = $class->filter_fulltext( $active, $resource, $site, $request );

    $class->can('build_linkJournal')
        or CUFTS::Exception::App->throw("No build_linkJournal method defined for class: $class");

    if ( defined($active) && scalar(@$active) > 0 ) {
        return $class->build_linkJournal( $active, $resource, $site, $request );
    }
    else {
        return undef;
    }
}

sub search_getTOC {
    my ( $class, $resource, $site, $request ) = @_;

    my $active = $class->_search_active( $resource, $site, $request );

    # Do date range check, embargo, etc...

    $active = $class->filter_fulltext( $active, $resource, $site, $request );

    $class->can('build_linkTOC')
        or CUFTS::Exception::App->throw("No build_linkTOC method defined for class: $class");

    if ( defined($active) && scalar(@$active) > 0 ) {
        return $class->build_linkTOC( $active, $resource, $site, $request );
    }
    else {
        return undef;
    }
}

sub search_getDatabase {
    my ( $class, $resource, $site, $request ) = @_;

    my $active = $class->_search_active( $resource, $site, $request );

    # Do date range check, embargo, etc...

    $active = $class->filter_fulltext( $active, $resource, $site, $request );

    $class->can('build_linkDatabase')
        or CUFTS::Exception::App->throw("No build_linkDatabase method defined for class: $class");

    if ( defined($active) && scalar(@$active) > 0 ) {
        return $class->build_linkDatabase( $active, $resource, $site, $request );
    }
    else {
        return undef;
    }
}

sub build_linkDatabase {
    my ( $class, $records, $resource, $site, $request ) = @_;
    return [] if is_empty_string( $resource->database_url );

    my @results;
    foreach my $record (@$records) {
        my $result = new CUFTS::Result($resource->database_url);
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}

sub build_linkJournal {
    my ( $class, $records, $resource, $site, $request ) = @_;

    defined($records) && scalar(@$records) > 0
        or return [];
    defined($resource)
        or CUFTS::Exception::App->throw('No resource defined in build_linkJournal');
    defined($site)
        or CUFTS::Exception::App->throw('No site defined in build_linkJournal');
    defined($request)
        or CUFTS::Exception::App->throw('No request defined in build_linkJournal');

    my @results;

    foreach my $record (@$records) {
        next if is_empty_string( $record->journal_url );

        my $result = new CUFTS::Result( $record->journal_url );
        $result->record($record);

        push @results, $result;
    }

    return \@results;
}


sub _search_active {
    my ( $class, $resource, $site, $request ) = @_;

    my $global_module = $class->global_db_module
        if defined( $class->global_db_module );
    my $local_module = $class->local_db_module
        if defined( $class->local_db_module );

    my $global = defined( $resource->resource ) ? 1 : 0;
    my $search_module = $global ? $global_module : $local_module;

    my %search_terms = ( 'resource' => $global ? $resource->resource->id : $resource->id );
    my @issns = $request->issns;
    if ( scalar( @issns ) ) {
        my @issn_search = ('-or');
        push @issn_search, { issn  => { '-in' => \@issns } };
        push @issn_search, { e_issn => { '-in' => \@issns } };
        if ( scalar($request->journal_auths) ) {
            push @issn_search, { 'journal_auth' => { '-in' => $request->journal_auths } };
        }
        $search_terms{'-nest'} = \@issn_search;
    }
    elsif ( not_empty_string( $request->title ) ) {
        if ( scalar($request->journal_auths) ) {
            $search_terms{'-nest'} = [ '-or', 
                { 'title' => { 'ilike' => $request->title } },
                { 'journal_auth' => { '-in' => $request->journal_auths } }
            ];
        }
        else {
            $search_terms{'title'} = { 'ilike', $request->title };
        }
    }
    else {
        return [];
    }

    my @matches = $search_module->search_where( \%search_terms );

    # Check for active flag

    my @active;
    foreach my $match (@matches) {

        if ($global) {
            my @local = $local_module->search(
                'journal'  => $match->id,
                'resource' => $resource->id
            );
            
            if ( scalar(@local) > 0 ) {
                if ( $local[0]->active ) {
                    my $local_journal = $local[0];
                    $class->overlay_global_title_data( $local_journal, $match );
                    push @active, $local_journal;
                }
            }
        }
        else {
            push @active, $match if $match->active;
        }
    }

    return \@active;
}

# Filters out records which should be excluded due to things like
# date ranges, embargo, etc.
sub filter_fulltext {
    my ( $class, $records, $resource, $site, $request ) = @_;

    my @valid;
    foreach my $record (@$records) {
        $class->has_fulltext( $record, $resource, $site, $request )
            or next;
        $class->check_fulltext_dates( $record, $resource, $site, $request )
            or next;
        $class->check_fulltext_embargo( $record, $resource, $site, $request )
            or next;
        $class->check_fulltext_current_months( $record, $resource, $site, $request )
            or next;
        $class->check_fulltext_current_years( $record, $resource, $site, $request )
            or next;
        $class->check_fulltext_vol_iss( $record, $resource, $site, $request )
            or next;

        push @valid, $record;
    }

    return \@valid;
}

# Returns 1 if the title has any fulltext at all.  This should be overridden
# to return 1 all the time if all titles in a list are fulltext and there's
# no coverage information

sub has_fulltext {
    my ( $class, $record, $resource, $site, $request ) = @_;

       not_empty_string( $record->ft_start_date )
    or not_empty_string( $record->ft_end_date )
    or not_empty_string( $record->vol_ft_start )
    or not_empty_string( $record->vol_ft_end )
    or not_empty_string( $record->iss_ft_start )
    or not_empty_string( $record->iss_ft_end )
    or not_empty_string( $record->coverage )
    or return 0;

    return 1;
}

sub check_fulltext_vol_iss {
    my ( $class, $record, $resource, $site, $request ) = @_;

    return 1 if is_empty_string( $request->volume ) || $request->volume !~ /^\s*\d+\s*$/;
    my $volume = int($request->volume);

    # requested volume is after end volume

    return 0
        if not_empty_string( $record->vol_ft_end )
        && $volume > int( $record->vol_ft_end );

    # requested volume is before start volume

    return 0
        if not_empty_string( $record->vol_ft_start )
        && $volume < int( $record->vol_ft_start );

    # requested issue matches start volume and is before start issue

    return 1 if is_empty_string( $request->issue ) || $request->issue !~ /^\s*\d+\s*$/;
    my $issue = int($request->issue);

    return 0
        if not_empty_string( $record->vol_ft_start )
        && not_empty_string( $record->iss_ft_start )
        && $volume == int( $record->vol_ft_start )
        && $issue < int( $record->iss_ft_start );

    # requested issue matches end volume and is after end issue

    return 0
        if not_empty_string( $record->vol_ft_end )
        && not_empty_string( $record->iss_ft_end )
        && $volume == int( $record->vol_ft_end )
        && $issue > int( $record->iss_ft_end );

    return 1;
}

# Check a record against a request for fulltext date range
sub check_fulltext_dates {
    my ( $class, $record, $resource, $site, $request ) = @_;

    my ( $year, $month, $day ) = ( $request->year, $request->month, $request->day );

    return 0
        unless $class->_check_date_range( $year, $month, $day, $record->ft_start_date, $record->ft_end_date );

    return 1;
}

# Check a record against a request for embargo period
sub check_fulltext_embargo {
    my ( $class, $record, $resource, $site, $request ) = @_;

    my ( $year, $month, $day )
        = ( $request->year, $request->month, $request->day );
    return $class->_check_embargo( $year, $month, $day,
        $record->embargo_months, $record->embargo_days );
}

# Check a record against a request for a moving wall
sub check_fulltext_current_months {
    my ( $class, $record, $resource, $site, $request ) = @_;

    my ( $year, $month, $day ) = ( $request->year, $request->month, $request->day );
    return $class->_check_current_months( $year, $month, $day,
        $record->current_months );
}

# Check a record against a request for a moving wall
sub check_fulltext_current_years {
    my ( $class, $record, $resource, $site, $request ) = @_;

    my ( $year, $month, $day ) = ( $request->year, $request->month, $request->day );
    return $class->_check_current_years( $year, $month, $day, $record->current_years );
}


# $start and $end must be in YYYY-MM-DD format
sub _check_date_range {
    my ( $class, $year, $month, $day, $start, $end ) = @_;

    my $start_check = $class->_check_start_date( $year, $month, $day, $start );
    my $end_check = $class->_check_end_date( $year, $month, $day, $end );

    return $start_check && $end_check;
}

# $start must be in YYYY-MM-DD format
sub _check_start_date {
    my ( $class, $year, $month, $day, $start ) = @_;
    return 1 unless not_empty_string($start);
    return 1 unless not_empty_string($year);

    if ( $start =~ /^(\d{4})-(\d{2})-(\d{2})/ ) {
        my $start_stamp = int( $1 . $2 . $3 );

        my $wanted_stamp;
        if ( $year =~ /(\d{4})/ ) {
            $wanted_stamp .= $1;
        }

        if ( not_empty_string($month) && $month =~ /(\d{2})/ ) {
            $wanted_stamp .= sprintf( "%02i", int($1) );
        }
        else {
            $wanted_stamp .= '13';    # above 12
        }

        if ( not_empty_string($day) && $day =~ /(\d{2})/ ) {
            $wanted_stamp .= sprintf( "%02i", int($1) );
        }
        else {
            $wanted_stamp .= '32';    # above 31
        }

        if ( int($wanted_stamp) < int($start_stamp) ) {
            return 0;
        }
    }
    else {
        warn("Invalid start date: $start");
    }

    return 1;
}

# $end must be in YYYY-MM-DD format
sub _check_end_date {
    my ( $class, $year, $month, $day, $end ) = @_;
    return 1 unless not_empty_string($end);
    return 1 unless not_empty_string($year);

    if ( $end =~ /^(\d{4})-(\d{2})-(\d{2})/ ) {
        my $end_stamp = int( $1 . $2 . $3 );

        my $wanted_stamp;
        if ( $year =~ /(\d{4})/ ) {
            $wanted_stamp .= $1;
        }

        if ( not_empty_string($month) && $month =~ /(\d{2})/ ) {
            $wanted_stamp .= sprintf( "%02i", int($1) );
        }
        else {
            $wanted_stamp .= '00';    # below 01
        }

        if ( not_empty_string($day) && $day =~ /(\d{2})/ ) {
            $wanted_stamp .= sprintf( "%02i", int($1) );
        }
        else {
            $wanted_stamp .= '00';    # below 01
        }

        if ( int($wanted_stamp) > int($end_stamp) ) {
            return 0;
        }
    }
    else {
        warn("Invalid end date: $end");
    }

    return 1;
}

sub _check_embargo {
    my ( $class, $year, $month, $day, $embargo_months, $embargo_days ) = @_;

    if (   ( defined($month) || defined($year) )
        && ( defined($embargo_months) && int($embargo_months) > 0 )
        || ( defined($embargo_days) && int($embargo_days) > 0 ) )
    {

        $embargo_months
            = defined($embargo_months) ? ( 0 - int($embargo_months) ) : 0;
        $embargo_days
            = defined($embargo_days) ? ( 0 - int($embargo_days) ) : 0;

        if ( not_empty_string($embargo_months) ) {
            my ( $e_year, $e_month, $e_day )
                = Date::Calc::Add_Delta_YMD( Date::Calc::Today, 0, $embargo_months, $embargo_days );

            return $class->_check_end_date( $year, $month, $day,
                sprintf( "%04d-%02d-%02d", $e_year, $e_month, $e_day ) );
        }
    }

    return 1;
}

sub _check_current_months {
    my ( $class, $year, $month, $day, $current_months ) = @_;

    if (   ( defined($month) || defined($year) )
        && ( defined($current_months) && int($current_months) > 0 ) )
    {

        $current_months = 0 - int($current_months);

        if ( not_empty_string($current_months) ) {
            my ( $e_year, $e_month, $e_day )
                = Date::Calc::Add_Delta_YMD( Date::Calc::Today, 0, $current_months, 0 );

            return $class->_check_start_date( $year, $month, $day,
                sprintf( "%04d-%02d-%02d", $e_year, $e_month, $e_day ) );
        }
    }

    return 1;
}

sub _check_current_years {
    my ( $class, $year, $month, $day, $current_years ) = @_;

    if (   ( defined($month) || defined($year) )
        && ( defined($current_years) && int($current_years) > 0 ) )
    {

        $current_years = 0 - int($current_years);

        if ( not_empty_string($current_years) ) {
            my ( $e_year, $e_month, $e_day )
                = Date::Calc::Add_Delta_YMD( Date::Calc::Today, $current_years, 0, 0 );

            return $class->_check_start_date( $year, $month, $day,
                 sprintf( "%04d-%02d-%02d", $e_year, $e_month, $e_day ) );
        }
    }

    return 1;
}

sub activate_all {
    my ( $class, $global_resource, $commit ) = @_;

    defined($global_resource)
        or CUFTS::Exception::App::CGI->throw(
        "No global_resource found in activate_all");

    unless ( ref($global_resource) ) {
        my $global_resource = CUFTS::DB::Resources->retrieve($global_resource)
            or CUFTS::Exception::App::CGI->throw(
            "Unable to load global resource id: $global_resource in activate_all"
            );
    }

    my $resource_id = $global_resource->id;

    my @local_resources = CUFTS::DB::LocalResources->search(
        'resource'      => $resource_id,
        'auto_activate' => 'true'
    );

    foreach my $local_resource (@local_resources) {

        my $global_titles_module = $class->global_db_module
            or CUFTS::Exception::App::CGI->throw("Attempt to view local title list for resource type without global list module.  Resource id: $resource_id");

        my $local_titles_module = $class->local_db_module
            or CUFTS::Exception::App::CGI->throw("Attempt to view local title list for resource type without local list module.  Resource id: $resource_id");

        my $global_titles = $global_titles_module->search( 'resource' => $resource_id );
        my $local_to_global_field = $class->local_to_global_field;

        local $local_titles_module->db_Main->{AutoCommit};

        eval {
            while ( my $global_title = $global_titles->next ) {

      # Check for existing local title record, create it if it does not exist.

                my @local_titles = $local_titles_module->search(
                    'resource'             => $local_resource->id,
                    $local_to_global_field => $global_title->id
                );
                if ( scalar(@local_titles) == 0 ) {
                    my $record = {
                        'active'               => 'true',
                        'resource'             => $local_resource->id,
                        $local_to_global_field => $global_title->id,
                    };
                    $local_titles_module->create($record);
                }
                elsif ( scalar(@local_titles) == 1 ) {
                    $local_titles[0]->active('true');
                    $local_titles[0]->update;
                }
                else {
                    CUFTS::Exception::App::CGI->throw(
                        "Multiple local title matches for global resource $resource_id, title "
                            . $global_title->id );
                }
            }
        };
        if ($@) {
            $local_titles_module->dbi_rollback;
            if ( ref($@) && $@->can('rethrow') ) {
                $@->rethrow;
            }
            else {
                die($@);
            }
        }
        
        if ($commit) {
            $local_titles_module->dbi_commit;
        }
    }

    return scalar(@local_resources);
}

# -------------------------

##
## MODIFIES $local
##

sub overlay_global_title_data {
    my ( $class, $local, $global ) = @_;

    defined($local)
        or return undef;

    defined($global)
        or $global = $local->journal;

    defined($global)
        or return $local;

    foreach my $column (
        qw(title issn e_issn vol_cit_start vol_cit_end iss_cit_start iss_cit_end vol_ft_start vol_ft_end iss_ft_start iss_ft_end cit_start_date cit_end_date ft_start_date ft_end_date embargo_months embargo_days urlbase db_identifier journal_url toc_url publisher abbreviation current_months coverage journal_auth)
    )
    {
        $local->$column( $global->$column ) unless defined( $local->$column );
    }

    $local->ignore_changes;
    return $local;
}


# FAST BUT DANGEROUS. This messes with the internals of a Class::DBI object.  It cuts a big chunk of CJDB rebuild time, but is
# a bad hack thing to do.  Local/Global overlays should be converted into materialized views for the next version of CUFTS.  There's
# a few rarely used columns left out here, just to help speed things up.
sub fast_overlay_global_title_data {
    my ( $class, $local, $global ) = @_;

    return undef if !defined($local);

    if ( !defined($global) ) {
        $global = $local->journal
    }
    
    return $local if !defined($global);

    # Force a load of "global" by accessing a column since it may just be cached as a blessed id
    $global->title;
    
    foreach my $column (
        qw(title issn e_issn vol_cit_start vol_cit_end iss_cit_start iss_cit_end vol_ft_start vol_ft_end iss_ft_start iss_ft_end cit_start_date cit_end_date ft_start_date ft_end_date embargo_months embargo_days urlbase db_identifier journal_url current_months coverage journal_auth)
    )
    {
        if ( !defined($local->{$column}) && defined($global->{$column}) ) {
            $local->{$column} = $global->{$column};
        }
    }

    $local->ignore_changes;
    return $local;
}



##
## CJDB specific code
##

sub modify_cjdb_link_hash {
    my ( $self, $type, $hash ) = @_;

    # $hash the link hash from the CJDB loader:
    # {
    #    URL => '',
    #    link_type => 1,  # 0 - print, 1 - fulltext, 2 - database
    #    fulltext_coverage => '',
    #    citation_coverage => '',
    #    embargo => '',  # moving wall
    #    current => '',  # moving wall
    # }
    
    # Hash should be directly modified here, if necessary.
    
    return 1;
}


1;
