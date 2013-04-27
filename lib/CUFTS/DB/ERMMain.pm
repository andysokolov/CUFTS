## CUFTS::DB::ERMMain
##
## Copyright Todd Holbrook, Simon Fraser University (2007)
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

package CUFTS::DB::ERMMain;

use strict;
use base 'CUFTS::DB::DBI';

use CUFTS::DB::Resources;
use DateTime;
use Data::Dumper;
use CUFTS::Util::Simple;

__PACKAGE__->table('erm_main');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
    id
    key
    site
    license
    provider

    vendor
    publisher
    internal_name
    url
    access
    resource_type
    resource_medium
    file_type
    description_brief
    description_full
    update_frequency
    coverage
    embargo_period
    simultaneous_users
    public
    public_list
    public_message
    proxy
    group_records
    subscription_status
    print_included
    active_alert
    print_equivalents
    pick_and_choose
    marc_available
    marc_history
    marc_alert
    marc_notes
    marc_schedule
    marc_schedule_interval

    requirements
    maintenance
    title_list_url
    help_url
    status_url
    resolver_enabled
    refworks_compatible
    refworks_info_url
    user_documentation
    subscription_type
    subscription_notes
    subscription_ownership
    subscription_ownership_notes
    misc_notes
    issn
    isbn

    pricing_model
    pricing_model_notes
    cost
    invoice_amount
    currency
    gst
    pst
    gst_amount
    pst_amount
    payment_status
    order_date
    contract_start
    contract_end
    original_term
    auto_renew
    renewal_notification
    notification_email
    notice_to_cancel
    requires_review
    review_by
    review_notes
    local_bib
    local_customer
    local_vendor
    local_vendor_code
    local_acquisitions
    local_fund
    journal_auth
    consortia
    consortia_notes
    date_cost_notes
    subscription
    price_cap
    license_start_date
    
    stats_available
    stats_url
    stats_frequency
    stats_delivery
    stats_counter
    stats_user
    stats_password
    stats_notes
    counter_stats

    open_access
    admin_subscription_no
    admin_user
    admin_password
    admin_url
    support_url
    access_url
    public_account_needed
    public_user
    public_password
    training_user
    training_password
    marc_url
    ip_authentication
    referrer_authentication
    referrer_url
    openurl_compliant
    access_notes
    breaches
    admin_notes
    
    alert
    alert_expiry
    
    provider_name
    local_provider_name
    provider_contact
    provider_notes
    support_email
    support_phone
    knowledgebase
    customer_number

    cancellation_cap
    cancellation_cap_notes
));                                                                                                        

__PACKAGE__->columns( Essential => __PACKAGE__->columns );
__PACKAGE__->columns( TEMP => qw( result_name rank ) );
__PACKAGE__->has_a('consortia', 'CUFTS::DB::ERMConsortia');
__PACKAGE__->has_a('pricing_model', 'CUFTS::DB::ERMPricingModels');
__PACKAGE__->has_a('resource_medium', 'CUFTS::DB::ERMResourceMediums');
__PACKAGE__->has_a('resource_type', 'CUFTS::DB::ERMResourceTypes');
__PACKAGE__->has_many('subjects', ['CUFTS::DB::ERMSubjectsMain' => 'subject'], 'erm_main');
__PACKAGE__->has_many('subjectsmain' => 'CUFTS::DB::ERMSubjectsMain');
__PACKAGE__->has_many('content_types', ['CUFTS::DB::ERMContentTypesMain' => 'content_type'], 'erm_main');
__PACKAGE__->has_many('content_types_main' => 'CUFTS::DB::ERMContentTypesMain' );
__PACKAGE__->has_many( 'names' => 'CUFTS::DB::ERMNames'  );
__PACKAGE__->has_many( 'keywords' => 'CUFTS::DB::ERMKeywords'  );
__PACKAGE__->has_a( 'license', 'CUFTS::DB::ERMLicense' );
__PACKAGE__->has_a( 'provider', 'CUFTS::DB::ERMProviders' );
__PACKAGE__->has_many( 'costs' => 'CUFTS::DB::ERMCosts' );
__PACKAGE__->has_many( 'uses' => 'CUFTS::DB::ERMUses' );
__PACKAGE__->has_many( 'counter_source_links' => 'CUFTS::DB::ERMCounterLinks' );
__PACKAGE__->has_many( 'counter_sources', [ 'CUFTS::DB::ERMCounterLinks' => 'counter_source' ], 'erm_main' );

# Enabling both of these causes a weird Class::DBI loop
# __PACKAGE__->has_many( 'local_journals' => 'CUFTS::DB::LocalJournals' );
# __PACKAGE__->has_many( 'local_resources' => 'CUFTS::DB::LocalResources' );

__PACKAGE__->sequence('erm_main_id_seq');

__PACKAGE__->set_sql( with_name => << 'SQL' );
    SELECT __ESSENTIAL(me)__, erm_names.name AS result_name%s
    FROM   %s
    JOIN erm_names ON (me.id = erm_names.erm_main)
    WHERE  erm_names.main = 1 AND %s
SQL


sub to_hash {
    my ( $self ) = @_;

    my %hash;
    foreach my $column ( __PACKAGE__->columns ) {
        next if !defined($self->$column);
        
        # Handle has-a relationship columns
        if ( grep { $_ eq $column } qw( consortia pricing_model resource_medium resource_type ) ) {
            $hash{$column} = $self->$column->$column;
        }
        elsif ( $column eq 'license') {
            $hash{$column} = $self->license->key;
        }
        elsif ( $column eq 'provider') {
            $hash{$column} = $self->provider->provider_name;
        }
        else {
            $hash{$column} = $self->$column();
        }
        
    }

    # Add flattened has-many/many-to-many columns
    
    $hash{subjects}      = join ', ', sort map { $_->subject }      $self->subjects;
    $hash{content_types} = join ', ', sort map { $_->content_type } $self->content_types;
    $hash{names}         = join ', ', sort map { $_->name }         $self->names;
    
    return \%hash;
}


sub clone {
    my $self = shift;

    my %hash;
    foreach my $column ( __PACKAGE__->columns ) {
        next if !defined($self->$column) or $column eq 'id';
        
        # Handle has-a relationship columns
        if ( grep { $_ eq $column } qw( consortia pricing_model resource_medium resource_type license provider ) ) {
            $hash{$column} = $self->$column->id;
        }
        else {
            $hash{$column} = $self->$column;
        }
    }

    $hash{key} = 'Clone of ' . $hash{key};

    # my $subjects        = delete $clone_hash->{subjects};
    # my $content_types   = delete $clone_hash->{content_types};
    # my $names           = delete $clone_hash->{names};

    # use Data::Dumper;
    # warn(Dumper(\%hash));

    my $clone = CUFTS::DB::ERMMain->insert(\%hash);
    my $clone_id = $clone->id;

    warn( 'Created: ' . $clone_id );

    foreach my $name ( $self->names ) {
        CUFTS::DB::ERMNames->insert({
            name        => $name->main ? 'Clone of ' . $name->name        : $name->name,
            search_name => $name->main ? 'clone of ' . $name->search_name : $name->search_name,
            erm_main    => $clone_id,
            main        => $name->main,
        });
    }

    foreach my $content_type ( $self->content_types_main ) {
        CUFTS::DB::ERMContentTypesMain->insert({
            content_type  => $content_type->content_type->id,
            erm_main      => $clone_id,
        });
    }

    foreach my $subject ( $self->subjectsmain ) {
        CUFTS::DB::ERMSubjectsMain->insert({
            subject     => $subject->subject,
            rank        => $subject->rank,
            description => $subject->description,
            erm_main    => $clone_id,
        });
    }


    CUFTS::DB::DBI->dbi_commit();

    return CUFTS::DB::ERMMain->retrieve( $clone->id );
}


my @fast_columns = qw(
    id
    url
    vendor
    description_brief
);

sub main_name {
    my ( $self, $new_name ) = @_;
    
    my $name_record = CUFTS::DB::ERMNames->search({
        erm_main => $self->id,
        main     => 1,
    })->first;

    if ( defined($new_name) ) {

        if ( defined($name_record) ) {
            if ( $name_record->name ne $new_name ) {
                $name_record->name( $new_name );
                $name_record->update;
            }
        }
        else {
            $name_record = CUFTS::DB::ERMNames->create({
                name        => $new_name,
                erm_main    => $self->id,
                main        => 1,
            });
        }
    }

    return defined($name_record) ? $name_record->name : undef;
}

sub alternate_names {
    my ( $self ) = @_;

    return CUFTS::DB::ERMNames->search({
        erm_main => $self->id,
        main => 0,
    },
    {
        order_by => 'search_name',
    });
}

sub retrieve_all_for_site {
    my ( $class, $site_id, $no_objects ) = @_;

    my $columns = join ', ', map { 'erm_main.' . $_ } ( $no_objects ? @fast_columns : __PACKAGE__->columns );
    my $sql = qq{
        SELECT *
        FROM (
            SELECT DISTINCT ON (erm_names.erm_main) $columns,
                erm_names.search_name AS sort_name,
                erm_names.name AS result_name
            FROM erm_main
            JOIN erm_names ON (erm_names.erm_main = erm_main.id)
            WHERE erm_main.site = ?
            ORDER BY erm_names.erm_main, erm_names.main DESC
        ) AS erm_results
        ORDER BY sort_name
    };

    my $sth = $class->db_Main()->prepare( $sql, {pg_server_prepare => 1} );
    if ( $no_objects ) {
        my $rv = $sth->execute( $site_id );
        return $sth->fetchall_arrayref({});
    }

    my @results = $class->sth_to_objects( $sth, [ $site_id ] );
    return \@results;
}

sub name {
    my ( $self ) = @_;
    
    if ( defined($self->result_name) ) {
        return $self->result_name;
    }

    return $self->main_name;
}


sub facet_search {
    my ( $class, $site, $fields, $no_objects, $offset, $limit ) = @_;

    my $config = {
        joins  => {},
        order  => [ 'sort_name' ],    # Default order by resource name
        extra_columns => {
            'sort_name'   => 'erm_names.search_name',
            'result_name' => 'erm_names.name',
        },
        replace_columns => {
        },
        search => {
            'erm_main.site' => $site,
        },
    };
    
    my $sql = qq{
        SELECT *
        FROM (
            SELECT DISTINCT ON (erm_names.erm_main) %COLUMNS%
            FROM erm_main
            JOIN erm_names ON (erm_names.erm_main = erm_main.id)
            %JOINS%
            %WHERE%
            ORDER BY erm_names.erm_main, erm_names.main DESC
        ) AS erm_results
        ORDER BY %ORDER%
    };

    foreach my $field ( keys %$fields ) {

        my $handler = "_facet_search_$field";
        $handler =~ tr/\./_/;
        if ( $class->can($handler) ) {
            $class->$handler( $field, $fields->{$field}, $config, \$sql );
        }
        else {
            # default
            $config->{search}->{$field} = $fields->{$field};
        }

    }
    
    my $SQLAbstract = SQL::Abstract->new;
    my ( $where, @bind ) = $SQLAbstract->where( $config->{search} );

    # Untaint $where
    $where =~ /(.*)/s or die;
    $where = $1;
    
    # Build column list
    
    my @columns;
    foreach my $column ( $no_objects ? @fast_columns : __PACKAGE__->columns ) {
        if ( exists($config->{replace_columns}->{$column} ) ) {
            push @columns, $config->{replace_columns}->{$column};
        }
        else {
            push @columns, "erm_main.${column}";
        }
    }

    foreach my $column ( keys %{ $config->{extra_columns} } ) {
        my $string = $config->{extra_columns}->{$column} . ' AS ' . $column;
        push @columns, $string;
    }

    $sql =~ s/%WHERE%/$where/e;
    $sql =~ s/%JOINS%/join( ' ', values( %{ $config->{joins} } ) )/e;
    $sql =~ s/%ORDER%/join( ', ', @{ $config->{order} } )/e;
    $sql =~ s/%COLUMNS%/join( ', ', @columns )/e;

    if ( $offset ) {
        $sql .= " OFFSET $offset";
    }
    if ( $limit ) {
        $sql .= " LIMIT $limit";
    }

#    warn($sql);
#    warn(Dumper(\@bind));

    my $sth = $class->db_Main()->prepare( $sql, {pg_server_prepare => 1} );
    if ( $no_objects ) {
        my $rv = $sth->execute( @bind );
        return $sth->fetchall_arrayref({});
    }

    my @results = $class->sth_to_objects( $sth, \@bind );
    return \@results;

}




sub facet_count {
    my ( $class, $site, $fields ) = @_;
    
    my $config = {
        joins  => {},
        order  => [ 'sort_name' ],    # Default order by resource name
        extra_columns => {
            'sort_name'   => 'erm_names.search_name',
            'result_name' => 'erm_names.name',
        },
        replace_columns => {
        },
        search => {
            'erm_main.site' => $site,
        },
    };
    
    my $sql = qq{
        SELECT count(*)
        FROM (
            SELECT DISTINCT ON (erm_names.erm_main) erm_main.id
            FROM erm_main
            JOIN erm_names ON (erm_names.erm_main = erm_main.id)
            %JOINS%
            %WHERE%
        ) AS erm_results
    };

    foreach my $field ( keys %$fields ) {

        my $handler = "_facet_search_$field";
        $handler =~ tr/\./_/;
        if ( $class->can($handler) ) {
            $class->$handler( $field, $fields->{$field}, $config, \$sql );
        }
        else {
            # default
            $config->{search}->{$field} = $fields->{$field};
        }

    }

    my $SQLAbstract = SQL::Abstract->new;
    my ( $where, @bind ) = $SQLAbstract->where( $config->{search} );

    # Untaint $where
    $where =~ /(.*)/s or die;
    $where = $1;

    $sql =~ s/%WHERE%/$where/e;
    $sql =~ s/%JOINS%/join( ' ', values( %{ $config->{joins} } ) )/e;

    my $sth = $class->db_Main()->prepare( $sql, {pg_server_prepare => 1} );
    $sth->execute( @bind );
    return ( $sth->fetchrow_array )[0];
}

sub _facet_search_license_allows_ill           { __facet_search_license_generic_boolean(@_); }
sub _facet_search_license_allows_ereserves     { __facet_search_license_generic_boolean(@_); }
sub _facet_search_license_allows_coursepacks   { __facet_search_license_generic_boolean(@_); }
sub _facet_search_license_allows_walkins       { __facet_search_license_generic_boolean(@_); }
sub _facet_search_license_allows_distance_ed   { __facet_search_license_generic_boolean(@_); }
sub _facet_search_license_allows_archiving     { __facet_search_license_generic_boolean(@_); }
sub _facet_search_license_perpetual_access     { __facet_search_license_generic_boolean(@_); }

sub __facet_search_license_generic_boolean {
    my ( $class, $field, $data, $config, $sql ) = @_;

    $config->{joins}->{license} = ' JOIN erm_license ON ( erm_license.id = erm_main.license )';
    $field =~ s/^.+\.(\w+)$/erm_license.$1/;
    $config->{search}->{$field} = $data ? 1 : 0;
}


sub _facet_search_name {
    my ( $class, $field, $data, $config, $sql ) = @_;

    $data = CUFTS::DB::ERMNames->strip_name( $data );

    $config->{search}->{search_name} = { '~' => "^$data" };
}

sub _facet_search_subject {
    my ( $class, $field, $data, $config, $sql ) = @_;

    $config->{joins}->{subject} = ' JOIN erm_subjects_main ON ( erm_subjects_main.erm_main = erm_main.id )';
    
    unshift( @{ $config->{order} }, 'rank' );
    $config->{extra_columns}->{rank} = 'erm_subjects_main.rank';
    $config->{replace_columns}->{description_brief} = 'COALESCE( erm_subjects_main.description, erm_main.description_brief ) AS description_brief';
    $config->{search}->{'erm_subjects_main.subject'} = $data;
}

sub _facet_search_content_type {
    my ( $class, $field, $data, $config, $sql ) = @_;

    $config->{joins}->{content_type} = ' JOIN erm_content_types_main ON ( erm_content_types_main.erm_main = erm_main.id )';
    
    $config->{search}->{'erm_content_types_main.content_type'} = $data;
}

sub _facet_search_keyword {
my ( $class, $field, $data, $config, $sql ) = @_;

    if ( !exists( $config->{joins}->{subject} ) ) {
        $config->{joins}->{subject} = ' LEFT JOIN erm_subjects_main ON ( erm_subjects_main.erm_main = erm_main.id )';
    }
    $config->{joins}->{subject_name} = ' LEFT JOIN erm_subjects ON ( erm_subjects_main.subject = erm_subjects.id )';

    if ( !exists( $config->{joins}->{consortia} ) ) {
        $config->{joins}->{consortia} = ' LEFT JOIN erm_consortia ON ( erm_main.consortia = erm_consortia.id )';
    }

    if ( !exists( $config->{joins}->{keywords} ) ) {
        $config->{joins}->{keywords} = ' LEFT JOIN erm_keywords ON ( erm_main.id = erm_keywords.erm_main )';
    }
    
    my $escaped = $data;
    $escaped =~ s/([^\w])/'\x' . unpack('H*', $1) /gsemx;

    $config->{search}->{'-nest'} = [
       'erm_subjects.subject'       => { '~*' => $escaped },
       'erm_consortia.consortia'    => { '~*' => $escaped },
       'erm_main.description_brief' => { '~*' => $escaped },
       'erm_main.description_full'  => { '~*' => $escaped },
       'erm_main.key'               => { '~*' => $escaped },
       'erm_main.vendor'            => { '~*' => $escaped },
       'erm_main.publisher'         => { '~*' => $escaped },
       'erm_main.internal_name'     => { '~*' => $escaped },
       'erm_names.search_name'      => { '~'  => CUFTS::DB::ERMNames->strip_name( $data ) },
       'erm_keywords.keyword'       => { '~'  => CUFTS::DB::ERMKeywords->strip_keyword( $data ) },
    ];
}

sub _facet_search_publisher {
    my ( $class, $field, $data, $config, $sql ) = @_;

    $data =~ s/\s\s+/ /g;
    $data = trim_string($data);

    $config->{search}->{publisher} = { '~*' => "$data" };
}

sub _facet_search_vendor {
    my ( $class, $field, $data, $config, $sql ) = @_;

    $data =~ s/\s\s+/ /g;
    $data = trim_string($data);

    $config->{search}->{vendor} = { '~*' => "$data" };
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
            @values = $self->$repeat_field();
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
                    
                    if ( is_empty_string($value) ) {
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
                if ( $keep_contents && scalar(@contents) ) {
                    push @subfields, (defined($subfield_num) ? $subfield_num : () ), join($default_subfield_join, @contents);
                }
            }

            if ( scalar(@subfields) ) {
                my @indicators = defined( $extra_conf->{indicators} ) ?  @{$extra_conf->{indicators}} : ( '', '' );
                $MARC->append_fields( MARC::Field->new( $field_num, @indicators, @subfields ) );
            }

        }

    }

    return $MARC;

}

1;
