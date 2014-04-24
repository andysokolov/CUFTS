package CUFTS::Util::Simple;

use strict;
use Perl6::Export::Attrs;

# Basic string/list utility routines used throughout CUFTS

# is_empty_string - returns 1 if string is not defined or is empty ''

sub is_empty_string :Export( :DEFAULT ) {
    my ($string) = @_;

    return 1 if !defined($string);
    return 1 if $string eq q{};

    return 0;  # Not empty
}

sub not_empty_string :Export( :DEFAULT ) {
    return !is_empty_string(@_);
}

sub ltrim_string :Export( :DEFAULT ) {
    my ($string, $trim) = @_;
    return undef if !defined($string);
    if (!defined($trim) ) {
        $trim = '';
    }
    $string =~ s/^ [\n\s]* $trim? [\n\s]* //xsm;
    return $string;
}

sub rtrim_string :Export( :DEFAULT ) {
    my ($string, $trim) = @_;
    return undef if !defined($string);
    if (!defined($trim) ) {
        $trim = '';
    }
    $string =~ s/ [\n\s]* $trim? [\n\s]* $//xsm;
    return $string;
}

sub trim_string :Export( :DEFAULT ) {
    my ($string, $trim) = @_;
    return undef if !defined($string);
    $string = ltrim_string($string, $trim);
    $string = rtrim_string($string, $trim);
    return $string;
}

sub dashed_issn :Export( :DEFAULT ) {
    my ($string) = @_;
    return undef if !defined $string;
    if ( length($string) == 8 ) {
        substr( $string, 4, 0 ) = '-';
    }
    return $string;
}

sub set_default_dates :Export( :DEFAULT ) {
    my ( $date, $period ) = @_;

    return undef if !defined($date);

    my @end = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

    # Set incomplete start date fields to -01 or -01-01

    if ( $period eq 'start' ) {
        if ( $date =~ /^\d{4}-\d{2}$/ ) {
            $date .= '-01';
        }
        elsif ( $date =~ /^\d{4}$/ ) {
            $date .= '-01-01';
        }
    }

    if ( $period eq 'end' ) {

        if ( $date =~ /^\d{4}-(\d{2})$/ ) {
            $date .= '-' . $end[ $1 - 1 ];
        }
        elsif ( $date =~ /^(\d{4})$/ ) {
            $date .= '-12-31';
        }
    }

    return $date;
}



##
## Converts latin-1 characters with diacritics to their base character.  When we switch to UTF-8, this should
## be replaced with something that uses character decomposition and normalization.
##

# Character maps borrowed from Greenstone

my %diacritic_map = (
    '�' => 'a',   # A WITH GRAVE
    '�' => 'a',
    '�' => 'a',   # A WITH ACUTE
    '�' => 'a',
    '�' => 'a',   # A WITH CIRCUMFLEX
    '�' => 'a',
    '�' => 'a',   # A WITH TILDE
    '�' => 'a',
    '�' => 'a',   # A WITH RING ABOVE
    '�' => 'a',   # AE
    '�' => 'c',   # C WITH CEDILLA
    '�' => 'c',
    '�' => 'e',   # E WITH GRAVE
    '�' => 'e',
    '�' => 'e',   # E WITH ACUTE
    '�' => 'e',
    '�' => 'e',   # E WITH CIRCUMFLEX
    '�' => 'e',
    '�' => 'e',   # E WITH DIAERESIS
    '�' => 'e',
    '�' => 'i',   # I WITH GRAVE
    '�' => 'i',
    '�' => 'i',   # I WITH ACUTE
    '�' => 'i',
    '�' => 'i',   # I WITH CIRCUMFLEX
    '�' => 'i',
    '�' => 'i',   # I WITH DIAERESIS
    '�' => 'i',
    '�' => 'dh',  # ETH
    '�' => 'n',   # N WITH TILDE
    '�' => 'n',
    '�' => 'o',   # O WITH GRAVE
    '�' => 'o',
    '�' => 'o',   # O WITH ACUTE
    '�' => 'o',
    '�' => 'o',   # O WITH CIRCUMFLEX
    '�' => 'o',
    '�' => 'o',   # O WITH TILDE
    '�' => 'O',
    '�' => 'o',   # O WITH STROKE
    '�' => 'o',
    '�' => 'u',   # U WITH GRAVE
    '�' => 'u',
    '�' => 'u',   # U WITH ACUTE
    '�' => 'u',
    '�' => 'u',   # U WITH CIRCUMFLEX
    '�' => 'u',
    '�' => 'y',   # Y WITH ACUTE
    '�' => 'th',  # THORN
    '�' => 'y',   # Y WITH DIAERESIS
    '�' => 'ae',  # A WITH DIAERESIS
    '�' => 'ae',
    '�' => 'oe',  # O WITH DIAERESIS
    '�' => 'oe',
    '�' => 'ue',  # U WITH DIAERESIS
    '�' => 'ue',
    '�' => 'ss',  # SHARP S
);

my $regex_search_string = join('|', keys(%diacritic_map));

sub convert_diacritics {
    my ( $string ) = @_;

    $string =~ s/($regex_search_string)/$diacritic_map{$1}/g;

    return $string;
}

1;
