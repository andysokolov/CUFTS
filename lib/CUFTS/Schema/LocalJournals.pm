package CUFTS::Schema::LocalJournals;

use strict;

use Moose;

use String::Util qw(hascontent trim);
use CUFTS::Util::Simple qw(dashed_issn clean_issn);
use CUFTS::Resources::Base::Journals;

extends qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ FromValidatorsCUFTS InflateColumn::DateTime TimeStamp /);

__PACKAGE__->table('local_journals');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      is_nullable => 0,
    },
    title => {
      data_type => 'varchar',
      is_nullable => 1,
      size => 1024,
    },
    issn => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 8,
    },
    e_issn => {
        data_type => 'varchar',
        is_nullable => 1,
        size => 8,
    },
    journal_auth => {
        data_type => 'integer',
        is_nullable => 1,
    },
    resource => {
        data_type => 'integer',
        is_nullable => 0,
    },
    journal => {
        data_type => 'integer',
        is_nullable => 1,
    },
    erm_main => {
        data_type => 'integer',
        is_nullable => 1,
    },
    vol_cit_start => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    vol_cit_end => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    vol_ft_start => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    vol_ft_end => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    iss_cit_start => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    iss_cit_end => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    iss_ft_start => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    iss_ft_end => {
        data_type => 'varchar',
        size => 128,
        is_nullable => 1,
    },
    cit_start_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    cit_end_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    ft_start_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    ft_end_date => {
        data_type => 'date',
        is_nullable => 1,
    },
    embargo_months => {
        data_type => 'integer',
        is_nullable => 1,
    },
    embargo_days => {
        data_type => 'integer',
        is_nullable => 1,
    },
    db_identifier => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    toc_url => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    journal_url => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    urlbase => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    publisher => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    abbreviation => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    current_months => {
        data_type => 'integer',
        is_nullable => 1,
    },
    current_years => {
        data_type => 'integer',
        is_nullable => 1,
    },
    coverage => {
        data_type => 'text',
        is_nullable => 1,
    },
    cjdb_note => {
        data_type => 'text',
        is_nullable => 1,
    },
    local_note => {
        data_type => 'text',
        is_nullable => 1,
    },
    scanned => {
        data_type => 'datetime',
        is_nullable => 1,
    },
    created => {
        data_type => 'datetime',
        set_on_create => 1,
        is_nullable => 1,
    },
    modified => {
        data_type => 'datetime',
        set_on_create => 1,
        set_on_update => 1,
        is_nullable => 1,
    },
    active => {
        data_type     => 'boolean',
        default_value => 'false',
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( local_resource => 'CUFTS::Schema::LocalResources',  'resource' );
__PACKAGE__->belongs_to( global_journal => 'CUFTS::Schema::GlobalJournals',  'journal',       { join_type => 'left' } );
__PACKAGE__->belongs_to( journal        => 'CUFTS::Schema::GlobalJournals',  'journal',       { join_type => 'left' } ); # Alias of above
__PACKAGE__->belongs_to( journal_auth   => 'CUFTS::Schema::JournalsAuth',    'journal_auth',  { join_type => 'left' } );
__PACKAGE__->belongs_to( erm_main       => 'CUFTS::Schema::ERMMain',         'erm_main',      { join_type => 'left' } );

__PACKAGE__->has_many( cjdb_links => 'CUFTS::Schema::CJDBLinks', 'local_journal' );

__PACKAGE__->resultset_class('CUFTS::ResultSet::LocalJournals');

sub journal_auth_merged    { $_[0]->_field_merged('journal_auth') }
sub title_merged           { $_[0]->_field_merged('title') }
sub issn_merged            { $_[0]->_field_merged('issn') }
sub e_issn_merged          { $_[0]->_field_merged('e_issn') }
sub ft_start_date_merged   { $_[0]->_field_merged('ft_start_date') }
sub ft_end_date_merged     { $_[0]->_field_merged('ft_end_date') }
sub cit_start_date_merged  { $_[0]->_field_merged('cit_start_date') }
sub cit_end_date_merged    { $_[0]->_field_merged('cit_end_date') }
sub vol_ft_start_merged    { $_[0]->_field_merged('vol_ft_start') }
sub vol_ft_end_merged      { $_[0]->_field_merged('vol_ft_end') }
sub iss_ft_start_merged    { $_[0]->_field_merged('iss_ft_start') }
sub iss_ft_end_merged      { $_[0]->_field_merged('iss_ft_end') }
sub embargo_days_merged    { $_[0]->_field_merged('embargo_days') }
sub embargo_months_merged  { $_[0]->_field_merged('embargo_months') }



sub _field_merged {
    my ( $self, $field ) = @_;

    return   defined($self->$field)         ? $self->$field()
           : defined($self->global_journal) ? $self->global_journal->$field()
                                            : undef;
}

sub journal_auth_id_merged {
    my ( $self, $field ) = @_;

    return   defined($self->get_column('journal_auth'))  ? $self->get_column('journal_auth')
           : defined($self->global_journal)              ? $self->global_journal->get_column('journal_auth')
                                                         : undef;
}

around issn => sub {
    my ($orig, $self) = (shift, shift);

    if (@_) {
        $self->$orig( clean_issn($_[0]) );
    }
    else {
        $self->$orig();
    }
};

around e_issn => sub {
    my ($orig, $self) = (shift, shift);

    if (@_) {
        $self->$orig( clean_issn($_[0]) );
    }
    else {
        $self->$orig();
    }
};

around update => sub {
    my ($orig, $self) = (shift, shift);

    if (@_) {
        my $data = $_[0];

        # Expand YYYY and YYYY-MM dates
        CUFTS::Resources::Base::Journals->clean_data_dates($data);

        $data->{issn}   = clean_issn( $data->{issn} )   if exists $data->{issn};
        $data->{e_issn} = clean_issn( $data->{e_issn} ) if exists $data->{e_issn};

        $self->$orig($data);
    }
    else {
        $self->$orig();
    }
};


sub title_display {
    return shift->title_merged;
}

sub issn_display {
    return dashed_issn( shift->issn );
}

sub e_issn_display {
    return dashed_issn( shift->e_issn );
}

sub journal_auth_display {
    return shift->get_column('journal_auth');
}

sub ft_start_date_display {
    return _date_display( shift->ft_start_date );
}

sub ft_end_date_display {
    return _date_display( shift->ft_end_date );
}

sub cit_start_date_display {
    return _date_display( shift->cit_start_date );
}

sub cit_end_date_display {
    return _date_display( shift->cit_end_date );
}

sub _date_display {
    my $date = shift;
    return defined $date ? $date->ymd : undef;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
