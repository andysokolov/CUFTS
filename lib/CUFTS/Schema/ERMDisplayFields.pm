## CUFTS::Schema::ERMDisplayFields
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

package CUFTS::Schema::ERMDisplayFields;

use strict;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_display_fields');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    site => {
        data_type => 'integer',
        size => 8,
    },
    field => {
        data_type => 'varchar',
        size => 256,
    },
    staff_view => {
        data_type => 'boolean',
        default_value => 0
    },
    staff_edit => {
        data_type => 'boolean',
        default_value => 0
    },
    display_order => {
        data_type => 'integer',
        size => 8,
    },
);

__PACKAGE__->set_primary_key( 'id' );

# This is pretty hacky... try to determine the field type by checking for the column data in various ERM Main
# associated tables.

sub field_type {
    my ( $self ) = shift;

    my $schema = $self->result_source->schema;
    my $erm_main     = $schema->resultset('ERMMain')->result_source;
    my $erm_license  = $schema->resultset('ERMLicense')->result_source;
    my $erm_provider = $schema->resultset('ERMProviders')->result_source;

    my $field = $self->field;

    my $type;
    if ( $erm_main->has_column($field) ) {
        $type = $erm_main->column_info($field)->{data_type};
    }
    elsif ( $erm_license->has_column($field) ) {
        $type = $erm_license->column_info($field)->{data_type};
    }
    elsif ( $erm_provider->has_column($field) ) {
        $type = $erm_provider->column_info($field)->{data_type};
    }

    if ( $type =~ /^varc/i || $type =~ /^char/ ) {
        $type = 'text';
    }
    if ( !defined($type) ) {
        $type = 'text';
    }

    return lc($type);
}

1;
