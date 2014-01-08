package CUFTS::Schema::ERMKeywords;

use strict;
use base qw/DBIx::Class::Core/;

use CUFTS::Util::Simple;

__PACKAGE__->load_components(qw//);

__PACKAGE__->table('erm_keywords');
__PACKAGE__->add_columns( qw(
    id
    erm_main
    keyword
));

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( erm_main => 'CUFTS::Schema::ERMMain' );

sub store_column {
    my ( $self, $name, $value ) = @_;

    if ($name eq 'keyword') {
        $value = $self->strip_keyword($value);
    }

    $self->next::method($name, $value);
}


sub strip_keyword {
    my ( $class, $name ) = @_;

    # $name =~ s/\s+\&\s+/ and /g;
    $name = lc($name);
    # $name = CUFTS::Util::Simple::convert_diacritics( $name );
    # $name =~ s/[^a-z0-9 ]//g;
    $name =~ s/\s\s+/ /g;
    $name = trim_string($name);

    return $name;
}

1;
