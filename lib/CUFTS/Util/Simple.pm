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
    return undef if !defined($string);
    if ( length($string) == 8 ) {
        $string = substr( $string, 0, 4 ) . '-' . substr( $string, 4, 4 )
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
    'à' => 'a',   # A WITH GRAVE
    'À' => 'a',
    'á' => 'a',   # A WITH ACUTE
    'Á' => 'a',
    'â' => 'a',   # A WITH CIRCUMFLEX
    'Â' => 'a',
    'ã' => 'a',   # A WITH TILDE
    'Ã' => 'a',
    'å' => 'a',   # A WITH RING ABOVE
    'æ' => 'a',   # AE
    'ç' => 'c',   # C WITH CEDILLA
    'Ç' => 'c',
    'è' => 'e',   # E WITH GRAVE
    'È' => 'e',
    'é' => 'e',   # E WITH ACUTE
    'É' => 'e',
    'ê' => 'e',   # E WITH CIRCUMFLEX
    'Ê' => 'e',
    'ë' => 'e',   # E WITH DIAERESIS
    'Ë' => 'e',
    'ì' => 'i',   # I WITH GRAVE
    'Ì' => 'i',
    'í' => 'i',   # I WITH ACUTE
    'Í' => 'i',
    'î' => 'i',   # I WITH CIRCUMFLEX
    'Î' => 'i',
    'ï' => 'i',   # I WITH DIAERESIS
    'Ï' => 'i',
    'ð' => 'dh',  # ETH
    'ñ' => 'n',   # N WITH TILDE
    'Ñ' => 'n',
    'ò' => 'o',   # O WITH GRAVE
    'Ò' => 'o',
    'ó' => 'o',   # O WITH ACUTE
    'Ó' => 'o',
    'ô' => 'o',   # O WITH CIRCUMFLEX
    'Ô' => 'o',
    'õ' => 'o',   # O WITH TILDE
    'Õ' => 'O',
    'ø' => 'o',   # O WITH STROKE
    'Ø' => 'o',
    'ù' => 'u',   # U WITH GRAVE
    'Ù' => 'u',
    'ú' => 'u',   # U WITH ACUTE
    'Ú' => 'u',
    'û' => 'u',   # U WITH CIRCUMFLEX
    'Û' => 'u',
    'ý' => 'y',   # Y WITH ACUTE
    'þ' => 'th',  # THORN
    'ÿ' => 'y',   # Y WITH DIAERESIS
    'ä' => 'ae',  # A WITH DIAERESIS
    'Ä' => 'ae',
    'ö' => 'oe',  # O WITH DIAERESIS
    'Ö' => 'oe',
    'ü' => 'ue',  # U WITH DIAERESIS
    'Ü' => 'ue',
    'ß' => 'ss',  # SHARP S
);

my $regex_search_string = join('|', keys(%diacritic_map));

sub convert_diacritics {
    my ( $string ) = @_;
    
    $string =~ s/($regex_search_string)/$diacritic_map{$1}/g;

    return $string;
}

1;
