## CUFTS::DB::LocalResources
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

package CUFTS::DB::LocalResources;

use CUFTS::DB::LocalJournals;
use CUFTS::DB::HiddenFields;
use CUFTS::DB::Resources;
use CUFTS::DB::ResourceTypes;
use CUFTS::DB::ERMMain;

use CUFTS::Util::Simple;

use strict;
use base 'CUFTS::DB::DBI';

__PACKAGE__->table('local_resources');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	site

	name

	resource

	provider
	resource_type

	module

	proxy
	dedupe
	auto_activate
	rank

	resource_identifier
	database_url
	auth_name
	auth_passwd
	url_base
	proxy_suffix
	proquest_identifier

	active

	title_list_scanned

	cjdb_note

    erm_main

	erm_basic_name
	erm_basic_vendor
	erm_basic_publisher
	erm_basic_subscription_notes

	erm_datescosts_cost
	erm_datescosts_contract_end
	erm_datescosts_renewal_notification
	erm_datescosts_notification_email
	erm_datescosts_local_fund
	erm_datescosts_local_acquisitions
	erm_datescosts_consortia
	erm_datescosts_consortia_notes
	erm_datescosts_notes

	erm_statistics_notes

	erm_admin_notes

	erm_terms_simultaneous_users
	erm_terms_allows_ill
	erm_terms_ill_notes
	erm_terms_allows_ereserves
	erm_terms_ereserves_notes
	erm_terms_allows_coursepacks
	erm_terms_coursepacks_notes
	erm_terms_notes

	erm_contacts_notes

	erm_misc_notes

	created
	modified
));


__PACKAGE__->columns(Essential => qw(
	id

	site

	name

	resource

	provider
	resource_type

	module

	proxy
	dedupe
	auto_activate
	rank

	resource_identifier
	database_url
	auth_name
	auth_passwd
	url_base
	proxy_suffix

	active

	title_list_scanned

	cjdb_note

	created
	modified
));

__PACKAGE__->sequence('local_resources_id_seq');

__PACKAGE__->has_a('resource_type' => 'CUFTS::DB::ResourceTypes');
__PACKAGE__->has_a('resource' => 'CUFTS::DB::Resources');
__PACKAGE__->has_a('site' => 'CUFTS::DB::Sites');

__PACKAGE__->has_many('hidden_fields', ['CUFTS::DB::HiddenFields' => 'field'], 'resource');
__PACKAGE__->has_many('local_journals' => 'CUFTS::DB::LocalJournals');

__PACKAGE__->has_a('erm_main' => 'CUFTS::DB::ERMMain');

__PACKAGE__->add_trigger('before_delete' => \&delete_titles);


sub record_count {
	my ($self, @other) = @_;

	if ($self->do_module('has_title_list')) {
		my $titles_module = $self->do_module('local_db_module');
		return $titles_module->count_search('resource' => $self->id, @other);
	}

	return undef;
}


sub normalize_column_values {
	my ($self, $values) = @_;

	# Force rank to 0 if it is empty

	if ( exists($values->{rank}) && defined($values->{rank}) && $values->{rank} eq '' ) {
		$values->{rank} = 0;
	}

	return 1;   # ???
}


sub do_module {
	my ($self, $method, @args) = @_;

	my $module = $self->module;
	defined($module) or
		defined($self->resource) and
			$module = $self->resource->module;

	if ( is_empty_string( $module ) ) {
	    warn( "Empty module being used, defaulting to blank" );
	    $module = 'blank';
	}

	$module = $CUFTS::Config::CUFTS_MODULE_PREFIX . $module;

	return $module->$method(@args);
}

sub activate_titles {
	$_[0]->_tivate_titles('true');
}

sub deactivate_titles {
	$_[0]->_tivate_titles('false');
}

sub _tivate_titles {
	my ($self, $flag) = @_;

	my $global_resource = $self->resource;

	my $module = $CUFTS::Config::CUFTS_MODULE_PREFIX;
	$module .= defined($self->module) ? $self->module : $global_resource->module;

	my $local_titles_module = $module->local_db_module or
		die("No local title module for resource when attempting bulk activation");

	if (defined($global_resource)) {
		my $global_titles_module = $module->global_db_module or
			die("No global title module for resource when attempting bulk activation");

		my $global_titles = $global_titles_module->search( resource => $global_resource->id );
		my $local_to_global_field = $module->local_to_global_field;

        # Check to see if we already have completely (de-)activated records so we're not doing extra work.

        my $local_count = $local_titles_module->count_search( resource => $self->id, active => 'true' );
        if ($flag eq 'true') {
            return 1 if $local_count == $global_titles->count;
        }
        elsif ($flag eq 'false') {
            return 1 if $local_count == 0;
        }

        # Updates are needed

		while (my $global_title = $global_titles->next) {
			# Check for existing local title record, create it if it does not exist.

			my @local_titles = $local_titles_module->search( resource => $self->id, $local_to_global_field => $global_title->id);
			if (scalar(@local_titles) == 0) {
				my $record = {
					'active' => $flag,
					'resource' => $self->id,
					$local_to_global_field => $global_title->id,
				};
				$local_titles_module->create($record);
			} elsif (scalar(@local_titles) == 1) {
					$local_titles[0]->active($flag);
					$local_titles[0]->update;
			} else {
				die("Multiple local title matches for global title " . $global_title->id);
			}
		}
	} else {
		my $titles = $local_titles_module->search( resource => $self->id);

		while (my $title = $titles->next) {
			$title->active($flag);
			$title->update;
		}
	}

	return 1;
}

sub delete_titles {
	my ($self) = @_;

	return $self->do_module('delete_title_list', $self->id, 1);
}


sub is_local_resource {
	return 1;
}

1;
