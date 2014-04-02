package CUFTS::ResultSet::ERMMain;

use strict;
use base 'DBIx::Class::ResultSet';

use Set::Object;

use Data::Dumper;

my @fast_search_columns = qw(
    id
    key
    vendor
    description_brief
    description_full
    url
    open_access
    proxy
    access
    alert
    license.id
);

sub facet_search {
    my ( $self, $site, $fields, $override_main_name, $offset, $limit ) = @_;

    my $config = {
        joins  => { 'names' => undef, 'license' => undef },
        order  => [ 'sort_name' ],    # Default order by resource name
        extra_columns => {
            'distinct_erm_main'  => 'names.erm_main',
            'main_erm_main_name' => 'names.main',
            'sort_name'          => 'names.search_name',
            'result_name'        => 'names.name',
        },
        replace_columns => {
        },
        search => {
            'me.site' => $site,
        },
        main_name_only => defined($override_main_name) ? $override_main_name : 1
    };


    # Dispatch to handle special setup for certain fields.  Default to normal field
    # search if there is no matching "_facet_search..." handler.

    foreach my $field ( keys %$fields ) {
        # Cleanup field, it may end up in an SQL statement.

        $field =~ tr/-a-zA-Z_//cd;

        my $handler = "_facet_search_${field}";
        if ( $self->can($handler) ) {
            $self->$handler( $field, $fields->{$field}, $config );
        }
        else {
            # Check that it's a valid column.  This used to skip the check but random
            # searches from exploit searching scripts would cause weird column names to
            # get through and an SQL failure.


            # if ( $self->result_source->has_column($field) ) {
                $config->{search}->{ "me.${field}" } = $fields->{$field};
            # }

        }

    }

    # If we're not doing a name search, limit just to main names

    if ( $config->{main_name_only} ) {
        $config->{search}->{'names.main'} = 1;
    }

    # Build select and as lists to pass as search attributes.  This pulls
    # from the column list merged with any "replace_columns" config setting

    my ( @select_columns, @as_columns );
    foreach my $column ( @fast_search_columns ) {
        push @as_columns, $column;

        if ( exists( $config->{replace_columns}->{$column} ) ) {
            push @select_columns, $config->{replace_columns}->{$column};
        }
        else {
            push @select_columns, ( $column =~ /\./ ? $column : "me.${column}" );
        }

    }


    # Build +select and +as lists to pass as search attributes

    my ( @extra_select_columns, @extra_as_columns );
    foreach my $as_column ( keys %{ $config->{extra_columns} } ) {
        push @extra_as_columns, $as_column;
        push @extra_select_columns, $config->{extra_columns}->{$as_column};
    }

    push @select_columns, 'license.allows_downloads';
    push @as_columns,     'license.allows_downloads';


    # Build join list from HASH ref.  Flatten with value 1

    my @joins = map { defined( $config->{joins}->{$_} ) ? { $_ => $config->{joins}->{$_} } : $_ } keys %{ $config->{joins} };

    # Do the search and return a result set

    my %search_attrs = (
        'select'   => \@select_columns,
        'as'       => \@as_columns,
        'distinct' => 1,
        'join'     => \@joins,
        '+as'      => \@extra_as_columns,
        '+select'  => \@extra_select_columns,
        'order_by' => [ 'names.erm_main', { '-desc' => 'names.main' } ],
    );

    return $self->search(
        $config->{search},
        \%search_attrs,
    );

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

    $field =~ s/^license_(\w+)$/license.$1/;

    # Detect some common boolean data values

    if ( $data =~ /^(yes|true)$/i ) {
        $data = 1;
    }
    elsif ( $data =~ /^(no|false)$/i ) {
        $data = 0;
    }
    else {
        $data =~ $data ? 1 : 0
    }

    $config->{search}->{$field} = $data;
}

sub _facet_search_subject {
    my ( $class, $field, $data, $config ) = @_;

    $config->{joins}->{subjects_main} ||= undef;

    $config->{extra_columns}->{rank} = 'subjects_main.rank';

    $config->{replace_columns}->{description_brief} =  \'COALESCE(subjects_main.description, me.description_brief)';

    $config->{search}->{'subjects_main.subject'} = $data;
}

sub _facet_search_name {
    my ( $self, $field, $data, $config ) = @_;

    $data = CUFTS::Schema::ERMNames->strip_name( $data );
    $config->{search}->{'names.search_name'} = { '~' => "^$data" };
    $config->{main_name_only} = 0;
}

sub _facet_search_name_regex {
    my ( $self, $field, $data, $config ) = @_;

    $config->{search}->{'names.search_name'} = { '~' => $data };
    $config->{main_name_only} = 0;
}



sub _facet_search_content_type {
    my ( $class, $field, $data, $config ) = @_;

    $config->{joins}->{content_types_main} ||= undef;

    $config->{search}->{'content_types_main.content_type'} = $data;
}

# Sigh. I kindof screwed myself by creating a virutal "keyword" field that searched across a lot of other fields.
# Anyway, this is another virtual one to do a search just across just name fields and exact keyword table matches.

sub _facet_search_name_exact_keyword {
    my ( $class, $field, $data, $config ) = @_;

    $config->{joins}->{keywords} = undef;
    $config->{search}->{'-or'} = [
    	'names.search_name'    => { '~'  => '[[:<:]]' . CUFTS::Schema::ERMNames->strip_name( $data ) },
    	'keywords.keyword'     => { '~'  => CUFTS::Schema::ERMKeywords->strip_keyword( $data ) },
	];
    $config->{main_name_only} = 0;
}

# Virtual field name to search across a variety of tables

sub _facet_search_keyword {
    my ( $class, $field, $data, $config ) = @_;

    $config->{joins}->{subjects_main} = 'subject';
    $config->{joins}->{keywords} = undef;

    my $escaped = $data;
    # $escaped =~ s/([^\w])/'\x' . unpack('H*', $1) /gsemx;
    $escaped = quotemeta($escaped);
    $escaped = '[[:<:]]' . $escaped . '[[:>:]]';   # Match only whole words

    $config->{search}->{'-or'} = [
            'subject.subject'      => { '~*' => $escaped },
            'me.description_brief' => { '~*' => $escaped },
            'me.description_full'  => { '~*' => $escaped },
            'me.key'               => { '~*' => $escaped },
            'me.vendor'            => { '~*' => $escaped },
            'me.publisher'         => { '~*' => $escaped },
            'names.search_name'    => { '~'  => '[[:<:]]' . CUFTS::Schema::ERMNames->strip_name( $data ) },
 	        'keywords.keyword'     => { '~'  => CUFTS::Schema::ERMKeywords->strip_keyword( $data ) },
    ];
    $config->{main_name_only} = 0;
}

sub _facet_search_publisher {
    my ( $class, $field, $data, $config ) = @_;

    $data =~ s/\s\s+/ /g;
    $data = trim_string($data);

    $config->{search}->{publisher} = { '~*' => $data };
}

sub _facet_search_vendor {
    my ( $class, $field, $data, $config ) = @_;

    $data =~ s/\s\s+/ /g;
    $data = trim_string($data);

    $config->{search}->{vendor} = { '~*' => $data };
}


##
## Restricted column information
##

sub restricted_columns {
    my ( $class, $site, $account ) = @_;

    my $account_type = $class->get_account_type( $account );

    if ( $account_type eq 'patron' ) {
        return grep { grep { $_ eq 'patron' } @{ $class->result_source->column_info($_)->{default_can_view} } } $class->result_source->columns;
    }
    elsif ( $account_type eq 'staff' ) {
        return grep { grep { $_ eq 'staff' } @{ $class->result_source->column_info($_)->{default_can_view} } } $class->result_source->columns;
    }
    else {
        die("Unrecognized account type: ${account_type}");
    }

}

sub get_account_type {
    my ( $class, $account ) = @_;   # CJDB::Schema::Account

    # Lowest level access if there is not account

    return 'patron' if !defined($account);

    return $account->get_account_type();
}

1;
