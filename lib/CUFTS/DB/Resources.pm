## CUFTS::DB::Resources
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

package CUFTS::DB::Resources;

use strict;
use base 'CUFTS::DB::DBI';

use CUFTS::DB::ResourceTypes;
use CUFTS::DB::LocalResources;

use CUFTS::Util::Simple;

__PACKAGE__->table('resources');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	key
	name

	provider
	resource_type

	module

	resource_identifier
	database_url
	auth_name
	auth_passwd
	url_base
	proxy_suffix

    cjdb_note
    notes_for_local
	proquest_identifier
	
	active

	title_list_scanned

	title_count

	created
	modified
));
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('resources_id_seq');

__PACKAGE__->has_a('resource_type' => 'CUFTS::DB::ResourceTypes');

__PACKAGE__->has_many('local_resources' => 'CUFTS::DB::LocalResources');

__PACKAGE__->add_trigger('before_delete' => \&delete_titles);

sub delete_titles {
	my ($self) = @_;

	return $self->do_module('delete_title_list', $self->id, 0);
}


sub record_count {
	my ($self, @other) = @_;

	my $module = $CUFTS::Config::CUFTS_MODULE_PREFIX . $self->module;
	if ($module->has_title_list) {
		my $titles_module = $module->global_db_module;
		return $titles_module->count_search('resource' => $self->id, @other);
	}

	return undef;
}


sub do_module {
	my ($self, $method, @args) = @_;

	my $module = $self->module;
	if ( is_empty_string( $module ) ) {
	    warn( "Empty module being used, defaulting to blank" );
	    $module = 'blank';
	}

	$module = $CUFTS::Config::CUFTS_MODULE_PREFIX . $module;

	return $module->$method(@args);
}



sub is_local_resource {
	return 0;
}


1;
