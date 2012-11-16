## CUFTS::Schema::ERMMain
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

package CUFTS::Schema::ERMMain;

use CUFTS::Resources;    # For prepend_proxy()
use CUFTS::Util::Simple;

use strict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('erm_main');
__PACKAGE__->add_columns(
    'id' => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        default_value       => undef,
        is_nullable         => 0,
        size                => 8,
    },
    'key' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'site' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 0,
        size          => 10,
    },
    'license' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    'provider' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    'vendor' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'internal_name' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'publisher' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'access' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'resource_type' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    'resource_medium' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    'file_type' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => '255',
    },
    'description_brief' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000,
    },
    'description_full' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000,
    },
    'update_frequency' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'coverage' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'embargo_period' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'simultaneous_users' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'public_list' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0,
    },
    'public' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'public_message' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'proxy' => {
        data_type   => 'boolean',
        is_nullable => 1,
    },
    'group_records' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'active_alert' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'print_equivalents' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'pick_and_choose' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'marc_available' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'marc_history' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'marc_alert' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'requirements' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'maintenance' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'issn' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'isbn' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'title_list_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'help_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'status_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'resolver_enabled' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0,
    },
    'refworks_compatible' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0,
    },
    'refworks_info_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'user_documentation' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000,
    },
    'subscription_type' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'subscription_status' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'print_included' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0,
    },
    'subscription_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'subscription_ownership' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'subscription_ownership_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'misc_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'cost' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'invoice_amount' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'currency' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => '3',
    },
    'pricing_model' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    'pricing_model_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000,
    },
    'gst' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'pst' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'pst_amount' => {
        data_type     => 'varchar',
        size          => 1024,
        default_value => undef,
        is_nullable   => 1,
    },
    'gst_amount' => {
        data_type     => 'varchar',
        size          => 1024,
        default_value => undef,
        is_nullable   => 1,
    },
    'payment_status' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'contract_start' => {
        data_type     => 'date',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'contract_end' => {
        data_type          => 'date',
        default_value      => undef,
        is_nullable        => 1,
        size               => 0,
    },
    'order_date' => {
        data_type          => 'date',
        default_value      => undef,
        is_nullable        => 1,
        size               => 0,
    },
    'original_term' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'auto_renew' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'renewal_notification' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    'notification_email' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'notice_to_cancel' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    'requires_review' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'review_by' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'review_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'local_bib' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'local_customer' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'local_vendor' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'local_vendor_code' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'local_acquisitions' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'local_fund' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'journal_auth' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    'consortia' => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    'consortia_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'date_cost_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'subscription' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'price_cap' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'license_start_date' => {
        data_type     => 'date',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'stats_available' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'stats_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'stats_frequency' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'stats_delivery' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'stats_counter' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'stats_user' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'stats_password' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'stats_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'counter_stats' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'open_access' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    'admin_subscription_no' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'admin_user' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'admin_password' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'admin_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'support_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'access_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'public_account_needed' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'public_user' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'public_password' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'training_user' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'training_password' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'marc_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'ip_authentication' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'referrer_authentication' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'referrer_url' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'openurl_compliant' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'access_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'breaches' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'admin_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'alert' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'alert_expiry' => {
        data_type          => 'date',
        default_value      => undef,
        is_nullable        => 1,
        size               => 0,
    },
    
    'provider_name' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'local_provider_name' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'provider_contact' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'provider_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    'support_email' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'support_phone' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'knowledgebase' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'customer_number' => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    'cancellation_cap' => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    'cancellation_cap_notes' => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
);
__PACKAGE__->mk_group_accessors( column => qw/ result_name sort_name rank / );

__PACKAGE__->set_primary_key('id');

# Check the ResultSet for more predefined complex searches

__PACKAGE__->resultset_class('CUFTS::ResultSet::ERMMain');

__PACKAGE__->belongs_to(
    'license' => 'CUFTS::Schema::ERMLicense',
    undef, { join_type => 'left outer' }
);

__PACKAGE__->has_many( 'names' => 'CUFTS::Schema::ERMNames', 'erm_main' );
__PACKAGE__->has_many( 'keywords' => 'CUFTS::Schema::ERMKeywords', 'erm_main' );
__PACKAGE__->has_many( 'uses' => 'CUFTS::Schema::ERMUses', 'erm_main' );

__PACKAGE__->has_many(
    'subjects_main' => 'CUFTS::Schema::ERMSubjectsMain',
    'erm_main'
);
__PACKAGE__->has_many( content_types_main => 'CUFTS::Schema::ERMContentTypesMain', 'erm_main' );

__PACKAGE__->many_to_many( content_types => 'content_types_main', 'content_type' );
__PACKAGE__->many_to_many( subjects      => 'subjects_main',      'subject' );

__PACKAGE__->belongs_to( consortia       => 'CUFTS::Schema::ERMConsortia' );
__PACKAGE__->belongs_to( pricing_model   => 'CUFTS::Schema::ERMPricingModels' );
__PACKAGE__->belongs_to( resource_medium => 'CUFTS::Schema::ERMResourceMediums' );
__PACKAGE__->belongs_to( resource_type   => 'CUFTS::Schema::ERMResourceTypes' );
__PACKAGE__->belongs_to( provider        => 'CUFTS::Schema::ERMProviders' );


# Flatten to a hash, concatenating strings, etc. Will take an array of ERMDisplayFields to limit to, otherwise it does everything.
sub to_hash {
    my ( $self, $fields ) = @_;
    
    my @fields;
    if ( defined($fields) ) {
        @fields = map { $_->field } @$fields;
    }
    else {
        @fields = $self->columns();
        push @fields, qw( content_types subjects consortia pricing_model resource_medium resource_type provider );
        # TODO: Also add license fields?
    }

    # At the minimum we want the id and name (this may be overwritten below)
    my $hash = {
        id => $self->id,
        name => $self->main_name,
    };
    my $license = $self->license;
    foreach my $field ( @fields ) {
        if ( $field eq 'content_types' ) {
            $hash->{content_types} = join ', ', map { $_->content_type } $self->content_types;
        }
        elsif ( $field eq 'subjects' ) {
            $hash->{subjects} = join ', ', map { $_->subject } $self->subjects;
        }
        elsif ( $field eq 'consortia' ) {
            $hash->{consortia} = defined($self->consortia) ? $self->consortia->consortia : undef;
        }
        elsif ( $field eq 'pricing_model' ) {
            $hash->{pricing_model} = defined($self->pricing_model) ? $self->pricing_model->pricing_model : undef;
        }
        elsif ( $field eq 'resource_medium' ) {
            $hash->{resource_medium} = defined($self->resource_medium) ? $self->resource_medium->resource_medium : undef;
        }
        elsif ( $field eq 'resource_type' ) {
            $hash->{resource_type} = defined($self->resource_type) ? $self->resource_type->resource_type : undef;
        }
        elsif ( $field eq 'provider' ) {
            $hash->{provider} = defined($self->provider) ? $self->provider->provider : undef;
        }
        elsif ( $field eq 'group_records' && not_empty_string($self->group_records) ) {
            my $group_records = $self->get_group_records;
            if ( ref($group_records) eq 'ARRAY' && scalar(@$group_records) ) {
                $hash->{group_records} = [];
                foreach my $group_record (@$group_records) {
                    push @{$hash->{group_records}}, {
                        id => $group_record->id,
                        name => $group_record->main_name,
                        url => $group_record->url,
                        description_full => $group_record->description_full,
                    };
                }
            }
        }
        else {
            if ( $self->has_column($field) ) {
                $hash->{$field} = $self->$field();
            }
            else {
                if ( defined($license) && $license->has_column($field) ) {
                    $hash->{$field} = $license->$field();
                }
            }
        }
    }

    return $hash;
}

sub main_name {
    my ( $self, $new_name ) = @_;

    my $name_record = $self->names( { main => 1 } )->first;

    if ( defined($new_name) ) {

        if ( defined($name_record) ) {
            if ( $name_record->name ne $new_name ) {
                $name_record->name($new_name);
                $name_record->update;
            }
        }
        else {
            my $schema = $self->result_source->schema;
            $name_record = $schema->resultset('ERMNames')->create(
                {   name     => $new_name,
                    erm_main => $self->id,
                    main     => 1,
                }
            );
        }
    }

    return defined($name_record) ? $name_record->name : undef;
}

sub name {
    my ($self) = @_;

    if ( defined( $self->result_name ) ) {
        return $self->result_name;
    }

    return $self->main_name;
}

sub proxied_url {
    my ( $self, $site ) = @_;

    return undef if is_empty_string( $self->url );

    if ( !$self->proxy ) {
        return $self->url;
    }

    if ( not_empty_string( $site->proxy_prefix ) ) {
        return $site->proxy_prefix . $self->url;
    }
    elsif ( not_empty_string( $site->proxy_WAM ) ) {
        my $url = $self->url;
        my $wam = $site->proxy_WAM;
        $url =~ s{ http:// ([^/]+) /? }{http://0-$1.$wam/}xsm;
        return $url;
    }
}

sub get_group_records {
    my $self = shift;
    return [] if is_empty_string( $self->group_records );

    my @record_ids = split( /[,\s]+/, $self->group_records );
    my $recordset = $self->result_source->resultset->search(
        {   site => $self->site,
            id   => { '-in' => \@record_ids }
        }
    );

    my %records = map { $_->id => $_ } $recordset->all();
    my @records;
    foreach my $id ( @record_ids ) {
        push( @records, $records{$id} );
    }

    return \@records;
}

1;

