package CUFTS::Schema::ERMMain;

use CUFTS::Resources;    # For prepend_proxy()
use String::Util qw(trim hascontent);
use MARC::Record;

use Moose;

use strict;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_main');
__PACKAGE__->add_columns(
    id => {
        data_type           => 'integer',
        is_auto_increment   => 1,
        default_value       => undef,
        is_nullable         => 0,
        size                => 8,
    },
    key => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    site => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 0,
        size          => 10,
    },
    license => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    provider => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    vendor => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    internal_name => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    publisher => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    access => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    resource_type => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    resource_medium => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    file_type => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => '255',
    },
    description_brief => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000,
    },
    description_full => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000,
    },
    update_frequency => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    coverage => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    embargo_period => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    simultaneous_users => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    public_list => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0,
    },
    public => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    public_message => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    proxy => {
        data_type   => 'boolean',
        is_nullable => 1,
    },
    group_records => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    active_alert => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    print_equivalents => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    pick_and_choose => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    marc_available => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    marc_history => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    marc_alert => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    marc_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    marc_schedule => {
        data_type     => 'date',
        default_value => undef,
        is_nullable   => 1,
    },
    marc_schedule_interval => {
        data_type     => 'integer',
        default_value => 0,
        is_nullable   => 1,
    },
    requirements => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    maintenance => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    issn => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    isbn => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    title_list_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    help_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    status_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    resolver_enabled => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0,
    },
    refworks_compatible => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0,
    },
    refworks_info_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    user_documentation => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000,
    },
    subscription_type => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    subscription_status => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    print_included => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0,
    },
    subscription_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    subscription_ownership => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    subscription_ownership_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    misc_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    cost => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    invoice_amount => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    currency => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => '3',
    },
    pricing_model => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    pricing_model_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000,
    },
    gst => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    pst => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    pst_amount => {
        data_type     => 'varchar',
        size          => 1024,
        default_value => undef,
        is_nullable   => 1,
    },
    gst_amount => {
        data_type     => 'varchar',
        size          => 1024,
        default_value => undef,
        is_nullable   => 1,
    },
    payment_status => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    contract_start => {
        data_type     => 'date',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    contract_end => {
        data_type          => 'date',
        default_value      => undef,
        is_nullable        => 1,
        size               => 0,
    },
    order_date => {
        data_type          => 'date',
        default_value      => undef,
        is_nullable        => 1,
        size               => 0,
    },
    original_term => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    auto_renew => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    renewal_notification => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    notification_email => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    notice_to_cancel => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    requires_review => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    review_by => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    review_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    local_bib => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    local_customer => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    local_vendor => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    local_vendor_code => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    local_acquisitions => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    local_fund => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    journal_auth => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    consortia => {
        data_type     => 'integer',
        default_value => undef,
        is_nullable   => 1,
        size          => 10,
    },
    consortia_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    date_cost_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    subscription => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    price_cap => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    license_start_date => {
        data_type     => 'date',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    stats_available => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    stats_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    stats_frequency => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    stats_delivery => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    stats_counter => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    stats_user => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    stats_password => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    stats_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    counter_stats => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    open_access => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    admin_subscription_no => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    admin_user => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    admin_password => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    admin_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    support_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    access_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    public_account_needed => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    public_user => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    public_password => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    training_user => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    training_password => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    marc_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    ip_authentication => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    referrer_authentication => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    referrer_url => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    openurl_compliant => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    access_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    breaches => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    admin_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    alert => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    alert_expiry => {
        data_type          => 'date',
        default_value      => undef,
        is_nullable        => 1,
        size               => 0,
    },

    provider_name => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    local_provider_name => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    provider_contact => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    provider_notes => {
        data_type     => 'text',
        default_value => undef,
        is_nullable   => 1,
        size          => 64000
    },
    support_email => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    support_phone => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    knowledgebase => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    customer_number => {
        data_type     => 'varchar',
        default_value => undef,
        is_nullable   => 1,
        size          => 1024
    },
    cancellation_cap => {
        data_type     => 'boolean',
        default_value => undef,
        is_nullable   => 1,
        size          => 0
    },
    cancellation_cap_notes => {
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

__PACKAGE__->belongs_to( 'license' => 'CUFTS::Schema::ERMLicense', undef, { join_type => 'left' } );

__PACKAGE__->has_many( names                => 'CUFTS::Schema::ERMNames',               'erm_main', { cascade_copy => 1 } );
__PACKAGE__->has_many( keywords             => 'CUFTS::Schema::ERMKeywords',            'erm_main', { cascade_copy => 1 } );
__PACKAGE__->has_many( uses                 => 'CUFTS::Schema::ERMUses',                'erm_main', { cascade_copy => 0 } );
__PACKAGE__->has_many( subjects_main        => 'CUFTS::Schema::ERMSubjectsMain',        'erm_main', { cascade_copy => 1 } );
__PACKAGE__->has_many( content_types_main   => 'CUFTS::Schema::ERMContentTypesMain',    'erm_main', { cascade_copy => 1 } );

__PACKAGE__->many_to_many( content_types => 'content_types_main', 'content_type' );
__PACKAGE__->many_to_many( subjects      => 'subjects_main',      'subject' );

__PACKAGE__->belongs_to( consortia       => 'CUFTS::Schema::ERMConsortia' );
__PACKAGE__->belongs_to( pricing_model   => 'CUFTS::Schema::ERMPricingModels' );
__PACKAGE__->belongs_to( resource_medium => 'CUFTS::Schema::ERMResourceMediums' );
__PACKAGE__->belongs_to( resource_type   => 'CUFTS::Schema::ERMResourceTypes' );
__PACKAGE__->belongs_to( provider        => 'CUFTS::Schema::ERMProviders' );
__PACKAGE__->belongs_to( site            => 'CUFTS::Schema::Sites' );


sub alternate_names {
    my ( $self ) = @_;

    return $self->names(
        {
            main => 0,
        },
        {
            order_by => 'search_name',
        }
    );
}


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
        elsif ( $field eq 'group_records' && hascontent($self->group_records) ) {
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

    my $name_record = $self->names->find({ main => 1 });

    if ( defined($new_name) ) {

        if ( defined($name_record) ) {
            if ( $name_record->name ne $new_name ) {
                $name_record->name($new_name);
                $name_record->update;
            }
        }
        else {
            $name_record = $self->add_to_names(
                {   name     => $new_name,
                    main     => 1,
                }
            );
        }
    }

    return defined($name_record) ? $name_record->name : undef;
}

sub name {
    my ($self) = @_;

    my $name;
    eval { $name = $self->result_name };
    return defined($name) ? $name : $self->main_name;
}

sub proxied_url {
    my ( $self, $site ) = @_;

    return undef if !hascontent( $self->url );
    return $self->url if !$self->proxy;

    $site = $self->site if !defined $site;

    if ( hascontent( $site->proxy_prefix ) ) {
        return $site->proxy_prefix . $self->url;
    }
    elsif ( hascontent( $site->proxy_wam ) ) {
        my $url = $self->url;
        my $wam = $site->proxy_wam;
        $url =~ s{ http:// ([^/]+) /? }{http://0-$1.$wam/}xsm;
        return $url;
    }
    else {
        return $self->url;
    }
}

sub get_group_records {
    my $self = shift;
    return [] if !hascontent( $self->group_records );

    my @record_ids = split( /[,\s]+/, $self->group_records );
    my $rs = $self->site->erm_mains({ id   => { '-in' => \@record_ids } });

    my %records = map { $_->id => $_ } $rs->all();
    my @records;
    foreach my $id ( @record_ids ) {
        push( @records, $records{$id} );
    }

    return \@records;
}


sub as_marc {
    my ( $self, $url_base ) = @_;

    my $default_subfield_join = '; ';

    my $configuration = [
        '001' => [ { indicators => [] }, undef, [ 'key' ] ],
        '020' => [ {}, 'a', [ 'isbn' ] ],
        '022' => [ {}, 'a', [ 'issn' ] ],
        '035' => [ {}, 'a', [ 'local_bib' ] ],
        '035' => [ {}, 'a', [ 'local_acquisitions' ] ],
        '035' => [ {}, 's', [ 'journal_auth', { prepend => 'CJDB' } ] ],
        '930' => [ {}, 'a', [ 'id', { prepend => 'e' } ] ],
        '245' => [ {}, 'a', [ 'main_name' ] ],
        '246' => [ { repeats => 1, repeat_field => 'alternate_names' }, 'a', [ 'name' ] ],
        '246' => [ {}, 'a', [ 'internal_name' ] ],
        '260' => [ {}, 'a', [ 'publisher' ] ],
        '500' => [ {}, 'a', [ 'description_brief' ] ],
        '856' => [ { indicators => [4,0] }, 'u', [ 'id', { prepend_url => 1 } ] ],
        '960' => [ {}, 'a', [ '', { timestamp => 1, label => 'Date of file creation: ' } ],
                       'b', [ 'cost', { label => 'Cost: ' } ],
                       'c', [ 'local_fund', { label => 'Local fund number: ' } ],
                       'd', [ 'vendor', { label => 'Vendor name: ' } ],
                       'e', [ 'local_vendor_code', { label => 'Local vendor code: ' } ],
        ],
        '961' => [ {}, 'a', [ 'subscription_type',              { label => 'Subscription type: ' },
                              'subscription_notes',             { label => 'Notes: ' }
                            ],
                       'b', [ 'subscription_ownership',         { label => 'Subscription ownership: ' },
                              'subscription_ownership_notes',   { label => 'Notes: ' },
                            ],
                       'c', [ 'consortia',                      { label => 'Consortia: ', call_method => 'consortia' },
                              'consortia_notes',                { label => 'Notes: ' }
                            ],
                       'd', [ 'pricing_model',                  { label => 'Pricing model: ', call_method => 'pricing_model' },
                              'pricing_model_notes',            { label => 'Notes: ' }
                            ],
                       'e', [ 'review_notes',                   { label => 'Review notes: '} ],
                       'f', [ 'date_cost_notes',                { label => 'Date cost notes: '} ],
                       'g', [ 'misc_notes',                     { label => 'Miscellaneous notes: '} ],
                       'h', [ 'coverage',                       { label => 'Coverage: '} ],
                       'i', [ 'resource_type',                  { label => 'Resource type: ', call_method => 'resource_type' } ],
                       'j', [ 'contract_start',                 { label => 'Contract start: ' } ],
                       'k', [ 'contract_end',                   { label => 'Contract end: ' } ],
                       'l', [ 'print_included',                 { label => 'Print included: ', boolean => 1 } ],
                       'm', [ 'local_vendor',                   { label => 'Local vendor number: ' } ],
                       'n', [ 'local_customer',                 { label => 'Local customer number: ' } ],
                       'o', [ 'simultaneous_users',             { label => 'Simultaneous users: ' } ],
                       'z', [ 'currency',                       { label => 'Currency: ' } ],
        ]
    ];

    my @subfields;

    my $MARC = MARC::Record->new();

    while ( my ( $field_num, $field_conf ) = splice( @$configuration, 0, 2 ) ) {


        my $extra_conf = shift(@$field_conf);

        my @values = (undef);
        if ( $extra_conf->{repeats} ) {
            my $repeat_field = $extra_conf->{repeat_field};
            @values = $self->$repeat_field()->all;
        }

        foreach my $current_value ( @values ) {

            my @subfields;
            my @field_conf = @$field_conf;  # Clone so we can splice off items but still use it for repeating fields
            while ( my ( $subfield_num, $subfield_conf ) = splice( @field_conf, 0, 2 ) ) {

                my @contents;
                my $keep_contents = 0;
                my @subfield_conf = @$subfield_conf;  # Clone so we can splice off items but still use it for repeating fields
                while ( my ( $erm_field, $content_conf ) = splice( @subfield_conf, 0, 2 ) ) {

                    my $label      = $content_conf->{label}   || '';
                    my $prepend    = $content_conf->{prepend} || ( $content_conf->{prepend_url} ? $url_base : '' );
                    my $append     = $content_conf->{append}  || '';

                    my $value = $extra_conf->{repeats}     ? ( $erm_field ? $current_value->$erm_field() : $current_value )
                              : $content_conf->{timestamp} ? DateTime->now()->ymd
                              : $self->$erm_field();

                    if ( $content_conf->{call_method} && defined($value) ) {
                        my $method = $content_conf->{call_method};
                        $value = $value->$method();
                    }

                    if ( !hascontent($value) ) {
                        $value = '';
                    }
                    else {
                        $keep_contents = 1;
                    }

                    if ( $content_conf->{boolean} ) {
                        $value = $value ? 'yes' : 'no';
                    }

                    $value =~ s/[\r\n]+/: /g;

                    push @contents, "${label}${prepend}${value}${append}";

                }
                if ( $keep_contents && scalar @contents ) {
                    push @subfields, (defined($subfield_num) ? $subfield_num : () ), join($default_subfield_join, @contents);
                }
            }

            if ( scalar @subfields ) {
                my @indicators = defined( $extra_conf->{indicators} ) ?  @{$extra_conf->{indicators}} : ( '', '' );
                $MARC->append_fields( MARC::Field->new( $field_num, @indicators, @subfields ) );
            }

        }

    }

    return $MARC;
}

sub clone {
    my $self = shift;
    my $schema = $self->result_source->schema;

    my $clone;
    $schema->txn_do( sub {
        $clone = $self->copy({ key => 'Clone of ' . $self->key });
        $clone->main_name('Clone of ' . $self->main_name);
    });

    return $clone;
}


1;
