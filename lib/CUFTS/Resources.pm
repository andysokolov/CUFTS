## CUFTS::Resources
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


package CUFTS::Resources;

use CUFTS::Result;
use CUFTS::Exceptions;
use CUFTS::Util::Simple;
use MIME::Lite;
use String::Util qw(trim hascontent);
use strict;

##
## Constants implemented as subs for now... change this later?  We want
## objects inhereting this module to be able to change the values, but not
## objects using this (or an inherited module).
##

sub global_db_module { return undef }
sub local_db_module  { return undef }

sub global_rs {
    CUFTS::Exception::App->throw("resource does not have an associated database module for loading global title lists");
}
sub local_rs {
    CUFTS::Exception::App->throw("resource does not have an associated database module for loading local title lists");
}


sub has_title_list { return 0 }  # default to no
sub title_list_fields { return undef }
sub overridable_title_list_fields { return undef }

sub global_resource_details      { return undef }
sub local_resource_details       { return undef }
sub overridable_resource_details { return [] }

sub can_override_resource_detail {
    my ($class, $field) = @_;
    my $fields = $class->overridable_resource_details or
        return 0;

    return (grep {$_ eq $field} @$fields) ? 1 : 0;
}

sub local_to_global_field { return undef }

sub local_matchable_on_columns { return undef }

sub help_template { return undef };
sub get_resource_details_help {
    my ($class, $field) = @_;

    my $help = $class->resource_details_help;
    if (exists($help->{$field})) {
        return $help->{$field};
    } else {
        return "Unable to find detailed help for resource detail '$field'";
    }
}
sub get_resource_help {
    my ($class, $field) = @_;

    my $help = $class->resource_help;
    if (exists($help->{$field})) {
        return $help->{$field};
    } else {
        return "Unable to find detailed help for resource field '$field'";
    }
}



sub resource_help {
    return {
        'proxy' => "Determines whether the proxy setting from your site configuration is prepended to URLs generated for this resource.",
        'dedupe' => "Determines whether results are deduped at the provider level.\nWith deduping on, only the highest ranked link to a resource at each service level will be generated.",
        'auto_activate' => "Automatically activates all titles for this resource, including new titles added after a title list update.",
        'rank' => "Controls the order in which results are returned to the user.\nThe numbers are relative and sorted in descending order.\nUnranked resources default to 0 and appear at the end of the results list.",
        'active' => "Determines whether the resource is used when resolving requests.",
    };
}

sub resource_details_help {
    return {};
}

sub filter_on {
    return [];
}



# ----------------------------------------------------------------------------

##
## Title list loading routines.  Most of this should be fairly generic
## (parsing column headers, etc.) I will try to make calls back to $self
## wherever possible to make it easier to override individual parts.  Some
## of these routines should not be called (resources without title lists), but
## I thought it would be easier to stick them here rather than subclassing again
## and making something like CUFTS::Resources::withTitleList, etc.
##

sub title_list_column_delimiter { return "\t" }
sub title_list_field_map        { return undef }
sub title_list_skip_lines_count { return 0 }
sub title_list_skip_blank_lines { return 1 }
sub title_list_extra_requires   {};

sub load_local_title_list  { return load_title_list(@_, 1) }
sub load_global_title_list { return load_title_list(@_, 0) }

# preprocess_file - placeholder for a routine which could preprocess the input file
#                   and then re-open *IN to point to the newly generated file

sub preprocess_file {
    my ($class, $IN) = @_;

    return $IN;
}


# load_title_list - reads in a title list, parses, and updates the database
#
# in: $resource   - resource being loaded
#     $title_list - file path to the title list
#     $local      - boolean flag (or 'local' string) for whether this title list should be loaded in the local tables
#

sub load_title_list {
    my ($class, $schema, $resource, $title_list, $local, $job) = @_;
    my $errors;

    $local = (defined $local && ($local eq 'local' || $local == 1)) ? 'local' : 'global';

    my $rs = $local eq 'local' ? $class->local_rs($schema) : $class->global_rs($schema);
    defined $rs or
        CUFTS::Exception::App->throw("resource does not have an associated database module for loading title lists");

    hascontent($title_list) or
        CUFTS::Exception::App->throw("No title list passed into load_title_list");

    defined($resource) or
        CUFTS::Exception::App->throw("No resource passed into load_title_list");

#    open(IN, "<:utf8", $title_list) or
    open(IN, $title_list) or
        CUFTS::Exception::App->throw("Unable to open title list for reading: $!");

    no strict 'refs';

    $class->title_list_extra_requires();

    $job->terminate_possible() if defined $job;

    *IN = *{$class->preprocess_file(*IN)};

    $class->title_list_skip_lines(*IN);

    # get field headings

    my $field_headings = $class->title_list_get_field_headings(*IN);
    defined($field_headings) && (ref($field_headings) eq 'ARRAY') && (scalar(@$field_headings) > 0) or
        CUFTS::Exception::App->throw("title_list_get_field_headings did not return an array ref or did not contain any fields");

    my $duplicate_records = $class->find_duplicates_for_loading(*IN, $field_headings);

    $job->terminate_possible() if defined $job;

    my $timestamp = $schema->get_now();

    my $count = 0;
    my $error_count = 0;
    my $processed_count = 0;
    my $new_count = 0;
    my $modified_count = 0;

    $schema->txn_begin();

    while ( my $row = $class->title_list_parse_row(*IN) ) {

        $job->terminate_possible() if defined $job;

        $count++;

        next if $row =~ /^#/;       # Skip comment lines
        next unless $row =~ /\S/;   # Skip blank lines

        my $record = $class->title_list_build_record($field_headings, $row);

        defined($record) && (ref($record) eq 'HASH') or
            CUFTS::Exception::App->throw("build_record did not return a hash ref");

        my $data_errors = $class->clean_data($record);
        next if $class->skip_record($record);
        if (defined($data_errors) && ref($data_errors) eq 'ARRAY' && scalar(@$data_errors) > 0) {
            push @$errors, map {"line $count: $_"} @$data_errors;
            $error_count++;
        }
        else {
            $processed_count++;

            # Wrap all the updating code in eval so that we can catch any database update
            # errors and roll back the update.

            eval {
                if ( my $existing_title = $class->_find_existing_title($schema, $resource->id, $record, $local) ) {
                    $class->_update_record($resource->id, $record, $existing_title, $timestamp, $local);
                }
                else {
                    ##
                    ## Try for a modify
                    ##
                    my $partial_match = $class->_find_partial_match($schema, $resource->id, $record, $local);
                    if ($partial_match && !$class->is_duplicate($record, $duplicate_records)) {
                        $class->_modify_record($schema, $resource, $record, $partial_match, $timestamp, $local);
                        $modified_count++;
                    }
                    else {
                        $class->_load_record($schema, $resource, $record, $timestamp, $local);
                        $new_count++;
                    }
                }
            };
            if ($@) {
                $schema->txn_rollback();
                if (ref($@) && $@->can('error')) {
                    CUFTS::Exception::App->throw("Database error while loading title list, row " . ($count - 1) . "\n" . $@->error);
                } else {
                    die("Database error while loading title list, row " . ($count - 1) . "\n" . $@);
                }
            }
        }
    }
    close(IN);

    my $deleted_count = $class->_delete_old_records($schema, $resource, $timestamp, $local);

    my $title_count = $rs->search({ resource => $resource->id })->count;
    if ( $title_count == 0 ) {
        $schema->txn_rollback();
        die("All titles will be deleted by this load. Rolling back changes. There is probably an error in the resource module or the title list format has changed.  Resource ID: " . $resource->id);
    }

    my $local_resouces_auto_activated = $class->check_is_global($local) ? $class->activate_all($schema, $resource, 0) : '';

    my $results = {
        errors                         => $errors,
        error_count                    => $error_count,
        processed_count                => $processed_count,
        new_count                      => $new_count,
        modified_count                 => $modified_count,
        deleted_count                  => $deleted_count,
        local_resources_auto_activated => $local_resouces_auto_activated,
        timestamp                      => $timestamp,
    };

    $resource->title_count($title_count) if $class->check_is_global($local);
    $resource->title_list_scanned($timestamp);
    $resource->update;

    $schema->txn_commit();

    return $results;
}

sub _update_record {
    my ($class, $resource_id, $record, $existing_title, $timestamp) = @_;
    $existing_title->update({ scanned => $timestamp });
    return;
}


sub _delete_old_records {
    my ($class, $schema, $resource, $timestamp, $local) = @_;

    my $resource_id = $resource->id;

    my $rs = $class->check_is_local($local) ? $class->local_rs($schema) : $class->global_rs($schema);

    $rs = $rs->search({ resource => $resource_id , scanned => [ { '<' => $timestamp }, undef ] });

    my $deleted_count = 0;
    while ( my $title = $rs->next ) {
        $class->log_deleted_title($schema, $resource, $title, $timestamp, $local);
        $title->delete;
        $deleted_count++;
    }

    return $deleted_count;
}

sub _deactivate_old_records {
    my ($class, $schema, $resource_id, $timestamp, $local) = @_;

    $local = (defined $local && ($local eq 'local' || $local == 1)) ? 'local' : 'global';

    my $rs = $local eq 'local' ? $class->local_rs($schema) : $class->global_rs($schema);
    defined $rs or
        CUFTS::Exception::App->throw("resource does not have an associated database module for loading title lists");

    $rs = $rs->search({ resource => $resource_id, active => 't', scanned => [ undef, { '<' => $timestamp} ] });

    my $deactivated_count = 0;
    while ( my $title = $rs->next ) {
        $title->active('false');
        $title->update;
        $deactivated_count++;
    }

    return $deactivated_count;
}


sub title_list_get_field_headings {
    my ($class, $IN, $no_map) = @_;
    my @headings;

    my $heading_map = $class->title_list_field_map;

    my $headings_array = $class->title_list_parse_row($IN);
    defined($headings_array) && ref($headings_array) eq 'ARRAY' or
        return undef;

    my @real_headings;
    foreach my $heading (@$headings_array) {

        $heading = trim_string($heading);

        if ( defined($heading_map) && !$no_map ) {

            if ( exists($heading_map->{$heading}) ) {
                $heading = $heading_map->{$heading};
            }
            else {
                $heading = "___$heading";
            }
        }

        push @real_headings, $heading;
    }

    return \@real_headings;
}

sub skip_record {
    my ($class, $record) = @_;
    return 0;
}

sub title_list_skip_lines {
    my ($class, $IN, $lines) = @_;

    defined($lines) or
        $lines = $class->title_list_skip_lines_count;

    $lines = int($lines);
    if ($lines > 0) {
        foreach my $x (1..$lines) {
            $class->title_list_read_row($IN);
        }
    }

    return $lines;
}

sub title_list_read_row {
    my ($class, $IN) = @_;

    return <$IN>;
}

sub title_list_parse_row {
    my ($class, $IN) = @_;

    my $row;
    while ($row = $class->title_list_read_row($IN)) {
        return undef unless defined($row);

        next if $row !~ /\S/ && $class->title_list_skip_blank_lines;
        next if $class->title_list_skip_comment_line($row);

        last;
    }

    return undef unless defined($row);
    $row =~ s/[\r\n]//g;   # Strip annoying returns/line feeds

    return $class->title_list_split_row($row);
}

sub title_list_split_row {
    my ($class, $row) = @_;

    my $delimiter = $class->title_list_column_delimiter;
    my @row = split /$delimiter/, $row;
    @row = map { trim_string($_) } @row;    # Strip leading/trailing spaces
    return \@row;
}


sub title_list_skip_comment_line {
    my ($class, $row) = @_;

    return $row =~ /^#/;
}

sub title_list_build_record {
    my ($class, $headings, $row) = @_;
    my %record;

    my $count = 0;
    foreach my $value (@$row) {
        my $field = $headings->[$count++];
        next unless defined($field);
        next unless defined($value);

        $value = trim_string($value);
        $field = trim_string($field);

        next if $value eq '';
        next if $field eq '';

        $record{$field} = $value;
    }

    return \%record;
}

sub clean_data {
    my ($class, $record) = @_;

    return [];
}

sub _load_record {
    my ($class, $schema, $resource, $record, $timestamp, $local) = @_;

    my $rs = $class->check_is_local($local) ? $class->local_rs($schema) : $class->global_rs($schema);
    defined $rs or
        CUFTS::Exception::App->throw("resource does not have an associated database module for loading title lists");

    $rs->can('create') or
        CUFTS::Exception::App->throw("resource's database module does not support create()");

    foreach my $field (keys %$record) {
        delete $record->{$field} if $field =~ /^___/;
    }

    $record->{active}   = 't' if $class->check_is_local($local);
    $record->{scanned}  = $timestamp;
    $record->{resource} = $resource->id;
    my $db_record = $rs->create($record);
    defined($db_record) or
        CUFTS::Exception::App->throw("unable to create database record");

    $class->log_new_title($resource, $db_record, $timestamp);

    return;
}

sub check_is_local {
    my ( $class, $value ) = @_;

    return 0 if !defined($value);
    return 1 if $value eq 'local' || $value eq '1';
    return 0;
}

sub check_is_global {
    return !shift->check_is_local(@_);
}

sub find_duplicates_for_loading {
    my ($class, $IN, $field_headings) = @_;

    my $start_pos = tell $IN;
    my $duplicates = {};
    my $duplicate_for_loading_fields = $class->duplicate_for_loading_fields();

ROW:
    while (my $row = $class->title_list_parse_row($IN)) {
        my $record = $class->title_list_build_record($field_headings, $row);
        my $data_errors = $class->clean_data($record);
        next if defined($data_errors) &&
                ref($data_errors) eq 'ARRAY' &&
                scalar(@$data_errors) > 0;

        my $identifier;
FIELD:
        foreach my $field (@$duplicate_for_loading_fields) {
            if (defined($record->{$field})) {
                $identifier = $record->{$field};
                last FIELD;
            }
        }

        if ( !defined($identifier) ) {
            warn('NO IDENTIFIER');
            next ROW;
        }

        $duplicates->{$identifier}++;
    }

    seek $IN, $start_pos, 0;

    return $duplicates;
}


sub is_duplicate {
    my ($class, $record, $duplicates) = @_;

    my $duplicate_for_loading_fields = $class->duplicate_for_loading_fields();
    my $identifier;

    foreach my $field (@$duplicate_for_loading_fields) {
        if (defined($record->{$field})) {
            $identifier = $record->{$field};
            last;
        }
    }

    return 0 if !defined($identifier);

    return $duplicates->{$identifier} > 1 ? 1 : 0;
}

# Deletes all titles attached to a resource, manually cascading to delete from local resource title lists as well.
# Manually doing the cascade means we skip any triggers at the row level, but iterating through every title takes too much work.
# Now that this has been decoupled to a batch job, that may not be as big an issue, in which case the "delete" calls could be changed to "delete_all"

sub delete_title_list {
    my ($class, $schema, $resource, $local, $job) = @_;

    return unless $class->has_title_list;

    if ( !ref $resource && int($resource) ) {
        $resource = $schema->resultset('GlobalResources')->find(int($resource));
    }
    defined $resource or
        return CUFTS::Exception::App->throw('Unable to find resource.');

    if ( !$class->check_is_local($local) ) {
        my $local_resources_rs = $resource->local_resources;
        my $total_local_count  = $local_resources_rs->count * 2;
        my $count = 0;
        while ( my $local_resource = $local_resources_rs->next ) {
            my $titles_rs = $class->local_rs($schema)->search({ resource => $local_resource->id });
            my $cjdb_rs   = $schema->resultset('CJDBLinks')->search({ resource => $local_resource->id });

            $job->terminate_possible() if defined $job;

            $count++;
            $job->checkpoint( (($count/$total_local_count)*95), 'Deleting ' . $cjdb_rs->count . ' CJDB links for local resource id  ' . $local_resource->id ) if defined $job;
            $cjdb_rs->delete;

            $job->terminate_possible() if defined $job;

            $count++;
            $job->checkpoint( (($count/$total_local_count)*95), 'Deleting ' . $titles_rs->count . ' titles from local resource id  ' . $local_resource->id ) if defined $job;
            $titles_rs->delete;
        }

        $job->terminate_possible() if defined $job;
        my $global_titles_rs = $class->global_rs($schema)->search({ resource => $resource->id });
        $job->checkpoint( 99, 'Deleting ' . $global_titles_rs->count . ' global resource titles' ) if defined $job;
        $global_titles_rs->delete;
    }
    else {
        my $titles_rs = $class->local_rs($schema)->search({ resource => $resource->id });
        my $cjdb_rs   = $schema->resultset('CJDBLinks')->search({ resource => $resource->id });

        $job->terminate_possible() if defined $job;

        $job->checkpoint( 33, 'Deleting ' . $cjdb_rs->count . ' CJDB links.' ) if defined $job;
        $cjdb_rs->delete;

        $job->terminate_possible() if defined $job;

        $job->checkpoint( 66, 'Deleting ' . $titles_rs->count . ' titles.' ) if defined $job;
        $titles_rs->delete;
    }

    # TODO:  Sweep CJDB journals for orphaned CJDB journals after links were deleted?

    return 1;
}


sub activation_title_list {
    my ($class, $schema, $local_resource, $title_list, $match_on, $deactivate) = @_;

    hascontent($title_list) or
        CUFTS::Exception::App->throw('No title list passed into activation_title_list');

    hascontent($match_on) or
        CUFTS::Exception::App->throw('No fields to match for activation passed into activation_title_list');

    defined($local_resource) or
        CUFTS::Exception::App->throw("No resource passed into activation_title_list");

    open(IN, $title_list) or
        CUFTS::Exception::App->throw("Unable to open title list for reading: $!");

    no strict 'refs';

    my $local_rs        = $class->local_rs($schema);
    my $global_rs       = $class->global_rs($schema);
    my $global_resource = $local_resource->resource;

    my $field_headings = CUFTS::Resources->title_list_get_field_headings(*IN);   # Force to Resources object to avoid resource overrides
    defined($field_headings) && (ref($field_headings) eq 'ARRAY') && (scalar(@$field_headings) > 0) or
        CUFTS::Exception::App->throw("title_list_get_field_headings did not return an array ref or did not contain any fields");


    my @match_on = split /,/, $match_on;
    my $map_field = $class->local_to_global_field;

    $schema->txn_begin();

    my $timestamp = $schema->get_now();

    my $errors;
    my $count = 0;
    my $error_count = 0;
    my $processed_count = 0;
    my $new_count = 0;
    while (my $row = CUFTS::Resources->title_list_parse_row(*IN)) {
        $count++;
        my $record = CUFTS::Resources->title_list_build_record($field_headings, $row);
        defined($record) && (ref($record) eq 'HASH') or
            CUFTS::Exception::App->throw("title_list_build_record did not return a hash ref");

        $processed_count++;

        my @global_records = $class->_match_on_rs($global_resource->id, $global_rs, \@match_on, $record)->all;

        foreach my $global_record (@global_records) {

            # Find or create local records

            my $record = {
                resource   => $local_resource->id,
                $map_field => $global_record->id,
            };

            if ( my $existing_record = $local_rs->find($record) ) {
                $existing_record->update({ active => 'true', scanned => $timestamp });
            }
            else {
                $record->{active} = 'true';
                $record->{scanned} = $timestamp;
                $local_rs->create($record);
                $new_count++;
            }

        }

    }
    close(IN);

    my $deactivated_count = 0;
    if ( $deactivate ) {
        $deactivated_count = $class->_deactivate_old_records($schema, $local_resource->id, $timestamp, 1);
    }

    $schema->txn_commit();

    return {
        errors            => $errors,
        error_count       => $error_count,
        processed_count   => $processed_count,
        new_count         => $new_count,
        deactivated_count => $deactivated_count,
    };
}


sub overlay_title_list {
    my ($class, $schema, $local_resource, $title_list, $match_on, $deactivate) = @_;

    hascontent($title_list) or
        CUFTS::Exception::App->throw('No title list passed into overlay_title_list');

    hascontent($match_on) or
        CUFTS::Exception::App->throw('No fields to match for overlay passed into overlay_title_list');

    defined($local_resource) or
        CUFTS::Exception::App->throw("No resource passed into overlay_title_list");

    open(IN, $title_list) or
        CUFTS::Exception::App->throw("Unable to open title list ($title_list) for reading: $!");

    no strict 'refs';

    my $local_rs        = $class->local_rs($schema);
    my $global_rs       = $class->global_rs($schema);
    my $global_resource = $local_resource->resource;

    my $field_headings = CUFTS::Resources->title_list_get_field_headings(*IN);   # Force to Resources object to avoid resource overrides
    defined($field_headings) && (ref($field_headings) eq 'ARRAY') && (scalar(@$field_headings) > 0) or
        CUFTS::Exception::App->throw("title_list_get_field_headings did not return an array ref or did not contain any fields");

    my @match_on = split /,/, $match_on;

    $schema->txn_begin();

    my $timestamp = $schema->get_now();

    my $errors;
    my $count = 0;
    my $error_count = 0;
    my $processed_count = 0;
    my $new_count = 0;

    # Create a map of all the existing local records instead of searching them each time. Memory vs. Speed

    my @local_records = $local_rs->search({ resource => $local_resource->id })->all;
    my $map_field = $class->local_to_global_field;
    my %lmap = map { $_->$map_field => $_ } @local_records;

    # Go through each row and update or create a matching record

    while ( my $row = CUFTS::Resources->title_list_parse_row(*IN) ) {
        $count++;
        my $record = CUFTS::Resources->title_list_build_record($field_headings, $row);
        if ( !defined $record || ref $record ne 'HASH' ) {
            CUFTS::Exception::App->throw("title_list_build_record did not return a hash ref");
        }

        $processed_count++;

        my @global_records = $class->_match_on_rs($global_resource->id, $global_rs, \@match_on, $record)->all;

        my $global_record;
        if ( scalar @global_records == 0 ) {
            my $err = "record $count: Could not match global record on:";
            foreach my $match_on (@match_on) {
                $err .= " '$match_on' => '" . $record->{$match_on} . "'";
            }
            push @$errors, $err;
            next;
        }
        elsif ( scalar @global_records == 1 ) {
            $global_record = $global_records[0];
        }
        else {
            my $err = "record $count: Matched multiple global records on:";
            foreach my $match_on (@match_on) {
                $err .= " '$match_on' => '" . $record->{$match_on} . "'";
            }
            push @$errors, $err;
            next;
        }

        # Find an existing cached local title, or create a new one

        my $local_record = $lmap{$global_record->id};
        if ( !defined $local_record ) {
            $local_record = $local_rs->create({ resource => $local_resource->id, $map_field => $global_record->id });
            $new_count++;
        }

        $local_record->active('true');
        $local_record->scanned($timestamp);
        foreach my $column (keys %$record) {
            next if $column =~ /^___/;
            next unless defined $record->{$column};
            next if grep {$_ eq $column} @match_on;
            next unless $local_record->can( $column );

           $local_record->$column($record->{$column});
        }

        $local_record->update;
    }
    close(IN);

    my $deactivated_count = 0;
    if ( $deactivate ) {
        $deactivated_count = $class->_deactivate_old_records($schema, $local_resource->id, $timestamp, 1);
    }

    $schema->txn_commit();

    return {
        errors            => $errors,
        error_count       => $error_count,
        processed_count   => $processed_count,
        new_count         => $new_count,
        deactivated_count => $deactivated_count,
    };
}


sub _match_on {
    my ($class, $resource_id, $module, $fields, $data) = @_;

    hascontent($resource_id) or
        CUFTS::Exception::App->throw('No resource_id passed into _match_on');

    hascontent($module) or
        CUFTS::Exception::App->throw('No database module passed into _match_on');

    defined($fields) && ref($fields) eq 'ARRAY' && scalar(@$fields) > 0 or
        CUFTS::Exception::App->throw('No fields array reference passed into _match_on');

    defined($data) && ref($data) eq 'HASH' or
        CUFTS::Exception::App->throw('No data hash reference passed into _match_on');

    my $search = { resource => $resource_id };
    my $can_search = 0;
    foreach my $field (@$fields) {
        next if !hascontent($data->{$field});

        # Special case ISSN to search both issn and e_issn fields
        if ($field eq 'issn') {
            my $issn_search = [ {issn => $data->{issn}}, {e_issn => $data->{issn}} ];
            # Also search e_issn if it's included in the data.
            if ( hascontent($data->{e_issn}) ) {
                push @$issn_search, {issn => $data->{e_issn}}, {e_issn => $data->{e_issn}};
            }
            $search->{-nest} = $issn_search;
        } else {
            $search->{$field} = $data->{$field};
        }

        $can_search++;
    }

    return [] if !$can_search;  # Don't search if we have no data fields.

    my @matches = $module->search_where($search);

    return \@matches;
}

sub _match_on_rs {
    my ($class, $resource_id, $rs, $fields, $data) = @_;

    hascontent($resource_id) or
        CUFTS::Exception::App->throw('No resource_id passed into _match_on_rs');

    defined $rs or
        CUFTS::Exception::App->throw('No database rs passed into _match_on_rs');

    defined($fields) && ref($fields) eq 'ARRAY' && scalar(@$fields) > 0 or
        CUFTS::Exception::App->throw('No fields array reference passed into _match_on_rs');

    defined($data) && ref($data) eq 'HASH' or
        CUFTS::Exception::App->throw('No data hash reference passed into _match_on_rs');

    my $search = { resource => $resource_id };
    my $can_search = 0;
    foreach my $field (@$fields) {
        next if !hascontent($data->{$field});

        # Special case ISSN to search both issn and e_issn fields
        if ($field eq 'issn') {
            my $issn_search = [ {issn => $data->{issn}}, {e_issn => $data->{issn}} ];
            # Also search e_issn if it's included in the data.
            if ( hascontent($data->{e_issn}) ) {
                push @$issn_search, {issn => $data->{e_issn}}, {e_issn => $data->{e_issn}};
            }
            $search->{-or} = $issn_search;
        }
        else {
            $search->{$field} = $data->{$field};
        }

        $can_search++;
    }

    return [] if !$can_search;  # Don't search if we have no data fields.

    return $rs->search($search);
}

sub _log_record_field {
    my ( $class, $record, $field ) = @_;

    $field .= '_display' if $record->can($field . '_display');

    return $record->can($field) && hascontent($record->$field) ? $record->$field : '';
}

sub log_new_title {
    my ($class, $resource, $db_record, $timestamp) = @_;

    my $resource_id = $resource->id;

    my $log_dir = $CUFTS::Config::CUFTS_TTILES_LOG_DIR || '/tmp';
    my $log_file = "$log_dir/new_titles_${resource_id}_" . substr($timestamp, 0, 19);

    my $file_exists = -e $log_file && -s $log_file;

    open LOG, ">>$log_file";

    # Write a header line if the file does not yet exist.  If it exists, we can assume
    # it's been written to before and already has the header line.

    unless ($file_exists) {
        print LOG 'CUFTS UPDATE: New titles in ', $resource->name, ' loaded ', substr($timestamp, 0,19 ), "\n";
        print LOG join "\t", @{$class->title_list_fields};
        print LOG "\n";
    }

    print LOG join "\t", map { $class->_log_record_field($db_record, $_) } @{$class->title_list_fields};
    print LOG "\n";

    close LOG;

    return 1;
}


sub log_deleted_title {
    my ($class, $schema, $resource, $db_record, $timestamp, $local) = @_;

    my $resource_id = $resource->id;

    $local eq 'global' and
        $class->log_deleted_local_title($schema, $resource, $db_record, $timestamp);

    my $log_dir = $CUFTS::Config::CUFTS_TTILES_LOG_DIR || '/tmp';
    my $log_file = "$log_dir/deleted_titles_${local}_${resource_id}_" . substr($timestamp, 0, 19);

    my $file_exists = -e $log_file && -s $log_file;

    open LOG, ">>$log_file";

    # Write a header line if the file does not yet exist.  If it exists, we can assume
    # it's been written to before and already has the header line.

    unless ($file_exists) {
        print LOG 'CUFTS UPDATE: Deleted titles from ', $resource->name, ' loaded ', substr($timestamp, 0, 19), "\n";
        print LOG join "\t", @{$class->title_list_fields};
        print LOG "\n";
    }

    print LOG join "\t", map { $class->_log_record_field($db_record, $_) } @{$class->title_list_fields};
    print LOG "\n";

    close LOG;

    return 1;
}

sub log_deleted_local_title {
    my ($class, $schema, $resource, $db_record, $timestamp) = @_;

    my $match_field = $class->local_to_global_field or
        return 0;

    my @title_list_fields = @{$class->title_list_fields};
    foreach my $field (@{$class->overridable_title_list_fields}) {
        grep {$field eq $_} @title_list_fields or
            push @title_list_fields, $field;
    }

    my $local_rs = $class->local_rs($schema);

    my $local_resources_rs = $resource->local_resources({ active => 't' });
    while ( my $local_resource = $local_resources_rs->next ) {
        my $local_resource_id = $local_resource->id;
        my @local_records = $local_rs->search({ $match_field => $db_record->id, resource => $local_resource_id, active => 't'})->all;
        next unless scalar(@local_records) > 0;
        scalar(@local_records) > 1 and
            warn("Multiple local overrides found for record in log_deleted_local_title"),
            next;

        my $local_record = $local_records[0];

        my $site = $local_resource->site;
        my $site_id = $site->id;

        my $log_dir = $CUFTS::Config::CUFTS_TTILES_LOG_DIR || '/tmp';
        my $log_file = "$log_dir/deleted_titles_local_${local_resource_id}_${site_id}_" . substr($timestamp, 0, 19);

        my $file_exists = -e $log_file && -s $log_file;

        open LOG, ">>$log_file";

        # Write a header line if the file does not yet exist.  If it exists, we can assume
        # it's been written to before and already has the header line.

        unless ($file_exists) {
            print LOG 'CUFTS UPDATE: Deleted titles from ', $resource->name, ' loaded ', substr($timestamp, 0, 19), "\n";
            print LOG join "\t", @title_list_fields;
            print LOG "\n";
        }

        $class->can('overlay_global_title_data') and
            $class->overlay_global_title_data($local_record, $db_record);

        print LOG join "\t", map { $class->_log_record_field($local_record, $_) } @title_list_fields;
        print LOG "\n";

        close LOG;
    }

    return 1;
}

sub log_modified_title {
    my ($class, $schema, $resource, $db_record, $new_record, $timestamp, $local) = @_;

    my $resource_id = $resource->id;

    $local eq 'global' and
        $class->log_modified_local_title($schema, $resource, $db_record, $new_record, $timestamp);

    my $log_dir = $CUFTS::Config::CUFTS_TTILES_LOG_DIR || '/tmp';
    my $log_file = "$log_dir/modified_titles_${resource_id}_" . substr($timestamp, 0, 19);

    my $file_exists = -e $log_file && -s $log_file;

    open LOG, ">>$log_file";

    # Write a header line if the file does not yet exist.  If it exists, we can assume
    # it's been written to before and already has the header line.

    unless ($file_exists) {
        print LOG 'CUFTS UPDATE: Modified titles in ', $resource->name, ' loaded ', substr($timestamp, 0, 19), "\n";
        print LOG join "\t", @{$class->title_list_fields};
        print LOG "\n";
    }

    print LOG join "\t", map { $class->_log_record_field($db_record, $_) } @{$class->title_list_fields};
    print LOG "\n";

    close LOG;

    return 1;
}

sub log_modified_local_title {
    my ($class, $schema, $resource, $db_record, $new_record, $timestamp) = @_;

    my $match_field = $class->local_to_global_field or
        return 0;

    my $local_rs = $class->local_rs($schema);

    my @title_list_fields = @{$class->title_list_fields};
    foreach my $field (@{$class->overridable_title_list_fields}) {
        grep {$field eq $_} @title_list_fields or
            push @title_list_fields, $field;
    }

    my $local_resources_rs = $resource->local_resources({ active => 't' });
    while ( my $local_resource = $local_resources_rs->next ) {
        my $local_resource_id = $local_resource->id;
        my @local_records = $local_rs->search({ $match_field => $db_record->id, resource => $local_resource_id, active => 't' })->all;
        next unless scalar(@local_records) > 0;
        scalar(@local_records) > 1 and
            warn("Multiple local overrides found for record in log_modified_local_title"),
            next;

        my $local_record = $local_records[0];

        my $site = $local_resource->site;
        my $site_id = $site->id;

        my $log_dir = $CUFTS::Config::CUFTS_TTILES_LOG_DIR || '/tmp';
        my $log_file = "$log_dir/modified_titles_local_${local_resource_id}_${site_id}_" . substr($timestamp, 0, 19);

        my $file_exists = -e $log_file && -s $log_file;

        open LOG, ">>$log_file";

        # Write a header line if the file does not yet exist.  If it exists, we can assume
        # it's been written to before and already has the header line.

        unless ($file_exists) {
            print LOG 'CUFTS UPDATE: Modified titles in ', $resource->name, ' loaded ', substr($timestamp, 0, 19), "\n";
            print LOG join "\t", @title_list_fields;
            print LOG "\n";
        }

        my $count = 0;
        foreach my $field (@title_list_fields) {
            print LOG "\t" unless $count++ == 0;
            defined($db_record->$field) and
                print LOG $class->_log_record_field($db_record, $field);

            next if $field eq 'id';

            defined($local_record->$field) and
                print LOG ' [' . $class->_log_record_field($local_record, $field) . ']';
            defined($new_record->{$field}) && (!defined($db_record->$field) || ($new_record->{$field} ne $db_record->$field)) and
                print LOG ' (' . $new_record->{$field} . ')';


        }
        print LOG "\n";

        close LOG;
    }

    return 1;
}


sub activate_all {
    my ($class, $schema, $resource, $commit) = @_;
}


sub prepend_proxy {
    my ($class, $result, $resource, $site, $request) = @_;

    return if !defined($result->url);

    # There's two checks for proxy_prefix_alternate below.  The second is useless because it wont get hit
    # due to the first one.  This is there so that the first one could be easily pulled out so Exceptions
    # are thrown for missing alternate proxies rather than falling back to the normal one.

    if ($resource->proxy) {
        if (defined($request->pid) && defined($request->pid->{'CUFTSproxy'}) && ($request->pid->{CUFTSproxy} eq 'alternate') && defined($site->proxy_prefix_alternate)) {
            defined($site->proxy_prefix_alternate) or
                CUFTS::Exception::App->throw('Alternate proxy requested, but no alternate proxy is defined for site');

            $result->url($site->proxy_prefix_alternate . $result->url);
        } else {
            if ( hascontent($site->proxy_prefix) ) {
                $result->url($site->proxy_prefix . $result->url);
            } elsif ( hascontent($site->proxy_wam) ) {
                my $url = $result->url;
                my $wam = $site->proxy_wam;
                $url =~ s{ (https?):// ([^/]+) /? }{$1://0-$2.$wam/}xsm;
                $result->url($url);
            }
        }
    }

    return $class;
}



##
## Email all the sites who have this resource active.
##

sub email_changes {
    my ( $class, $resource, $results ) = @_;

    my $resource_id = $resource->id;

    my $local_resources_rs = $resource->local_resources({ active => 't', auto_activate => 'f' });
    while ( my $local_resource = $local_resources_rs->next ) {
        my $site = $local_resource->site;
        next if !hascontent($site->email);

        my $local_resource_id = $local_resource->id;

        my $site_id = $site->id;
        my $host = defined($CUFTS::Config::CUFTS_SMTP_HOST) ? $CUFTS::Config::CUFTS_SMTP_HOST : 'localhost';
        my $msg = MIME::Lite->new(
            From    => $CUFTS::Config::CUFTS_MAIL_FROM,
            To      => $site->email,
            Subject => "CUFTS UPDATE ALERT: " . $resource->name,
            Type    => 'multipart/mixed',
        );

        if ( defined($msg) ) {

            $msg->attach(
                Type => 'TEXT',
                Data => 'You have received this message because one of your CUFTS local resources has been updated.  If any of your active titles were modified or deleted, then files will be attached to this email containing the previous values.  Please check these files to see if any of the titles you have enabled in CUFTS have changed. This may require re-enabling individual titles to ensure continued linking for your users. If you have any questions, please contact researcher-support@sfu.ca.' . "\n\n" .
                    'Resource: ' . $resource->name . "\n" .
                    'Processed: ' . $results->{'processed_count'} . "\n" .
                    'New: ' . $results->{'new_count'} . "\n" .
                    'Modified: ' . $results->{'modified_count'} . "\n" .
                    'Deleted: ' . $results->{'deleted_count'} . "\n"
            ) or CUFTS::Exception::App->throw("Unable to attach text message to MIME::Lite object: $!");

            my $filename = ($CUFTS::Config::CUFTS_TTILES_LOG_DIR || '/tmp/') . "new_titles_${resource_id}_" . substr($results->{timestamp}, 0, 19);
            if (-e "$filename") {
                $msg->attach(
                    Type => 'text/plain',
                    Path => $filename,
                    Filename => "new_titles_${resource_id}_" . substr($results->{timestamp}, 0, 19),
                    Disposition => 'attachment'
                ) or CUFTS::Exception::App->throw("Unable to attach new titles file to MIME::Lite object: $!");
            }

            $filename = ($CUFTS::Config::CUFTS_TTILES_LOG_DIR || '/tmp/') . "modified_titles_local_${local_resource_id}_${site_id}_" . substr($results->{'timestamp'}, 0, 19);
            print "$filename\n";
            if (-e "$filename") {
                print "found\n";
                $msg->attach(
                    Type => 'text/plain',
                    Path => $filename,
                    Filename => "modified_titles_local_${local_resource_id}_${site_id}_" . substr($results->{timestamp}, 0, 19),
                    Disposition => 'attachment'
                ) or CUFTS::Exception::App->throw("Unable to attach modified titles file to MIME::Lite object: $!");
            }

            $filename = ($CUFTS::Config::CUFTS_TTILES_LOG_DIR || '/tmp/') . "deleted_titles_local_${local_resource_id}_${site_id}_" . substr($results->{'timestamp'}, 0, 19);
            print STDERR "$filename\n";
            if (-e "$filename") {
                print STDERR "found\n";
                $msg->attach(
                    Type => 'text/plain',
                    Path => $filename,
                    Filename => "deleted_titles_local_${local_resource_id}_${site_id}_" . substr($results->{timestamp}, 0, 19),
                    Disposition => 'attachment'
                ) or CUFTS::Exception::App->throw("Unable to attach deleted titles file to MIME::Lite object: $!");
            }

            eval {
                print "Sending update mail to: ", $site->name, "\n";
                MIME::Lite->send('smtp', $host);
                $msg->send;
            };
            if ($@) {
                warn("Unable to send message using MIME::Lite: $@");
            }
        }
        else {
            warn("Unable to create MIME::Lite object: $!");
        }
    }

    return 1;
}


# ---------------------------------------------------


my $__required = {};

sub __require {
    my ($class) = @_;
    return 1 if defined($__required->{$class}) && $__required->{$class} == 1;
    $class =~ /[^a-zA-Z:_]/ and
        CUFTS::Exception::App::CGI->throw("Invalid class name passed into __require_class - \"$class\"");

    eval "require $class";
    if ($@) {
        CUFTS::Exception::App::CGI->throw("Error requiring class = \"$@\"");
    }

    $__required->{$class} = 1;
    return 1;
}


sub __module_name {
    return $CUFTS::Config::CUFTS_MODULE_PREFIX . $_[0];
}

1;
