package CUFTS::Schema::ERMCounterCounts;

use strict;
use base qw/DBIx::Class::Core/;

use Date::Calc qw(Days_in_Month);

__PACKAGE__->load_components( qw/TimeStamp/ );

__PACKAGE__->table('erm_counter_counts');
__PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    counter_title => {
        data_type => 'integer',
        is_nullable => 0,
        size => 8,
    },
    counter_source => {
        data_type => 'integer',
        is_nullable => 0,
        size => 8,
    },
    start_date => {
        data_type => 'date',
        is_nullable => 0,
    },
    end_date => {
        data_type => 'date',
        is_nullable => 0,
    },
    type => {
        data_type => 'varchar',
        size => 255,
        is_nullable => 0,
    },
    count => {
        data_type => 'integer',
        size => 8,
        default_value => 0,
    },
    timestamp => {
        data_type => 'datetime',
        set_on_create => 1,
    },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( 'counter_source' => 'CUFTS::Schema::ERMCounterSources' );

# sub new {
#     my ($self, $attrs) = @_;
#
#     # Set the end date if it isn't already set.
#
#     if ( !exists($attrs->{end_date}) && defined($attrs->{start_date}) && $attrs->{start_date} =~ /(\d{4})-(\d{2})-\d{2}/ ) {
#         $attrs->{end_date} = "$1-$2-" . Days_in_Month($1,$2);
#     }
#
#     return 1;   # ???
# }


1;
