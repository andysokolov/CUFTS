package CUFTS::CJDB::Util;

use Pod::Escapes;
use String::Approx qw(amatch);
use CUFTS::Util::Simple;
use MARC::Charset;
use Data::Dumper;

my @stop_words     = qw(of and the an a la le les der das die et in for);

my @generic_titles = (
    'journal',     'review',       'bulletin', 'newsletter',
    'proceedings', 'transactions', 'symposium'
);

my @articles = (

    #	'A\s+',
    'An\s+',
    'The\s+',
    'La\s+',
    'Le\s+',
    'Les\s+',
    'L\'',
    'Der\s+',
    'Das\s+',
    'Die\s+',
);

use strict;

sub strip_title {
    my ($string) = @_;

    $string =~ s/\s+\&\s+/ and /g;

    $string = latin1_fallback($string);

    $string = lc($string);
    $string =~ s/[^a-z0-9 ]//g;

    # !!! Should this go here? We'll see how it works long term
    #	$string =~ s/\s+and\s+/ /g;

    # Remove extra spaces

    $string =~ s/\s\s+/ /g;

    $string = trim_string($string);

    return $string;
}

sub strip_articles {
    my ( $string, $removed_count ) = @_;

    foreach my $article (@articles) {
        my $orig_length = length($string);
        if ( $string =~ s/^${article}//i ) {
            if ( ref($removed_count) ) {
                $$removed_count = $orig_length - length($string);
            }
            return $string;
        }
    }

    if ( ref($removed_count) ) {
        $$removed_count = 0;
    }

    return $string;
}

sub count_articles {
    my ($string) = @_;

    foreach my $article (@articles) {
        my $orig_length = length($string);
        if ( $string =~ s/^${article}//i ) {
            return $orig_length - length($string);
        }
    }

    return 0;
}

sub latin1_to_marc8 {
    my ($line) = @_;

#    $line =~ s/([\x80-\xFF])/chr(0xC0|ord($1)>>6).chr(0x80|ord($1)&0x3F)/eg;

    return MARC::Charset::utf8_to_marc8($line);
}

sub marc8_to_latin1 {
    my ($line) = @_;

    $line =~ s/(.)/sprintf ("%%%X", ord($1))/eg;

    my @orphan_chars_combined = (
        '%1B%67%61%1B%73', '%1B%67%62%1B%73',
        '%1B%67%63%1B%73', '%1B%62%30%1B%73',
        '%1B%62%31%1B%73', '%1B%62%32%1B%73',
        '%1B%62%33%1B%73', '%1B%62%34%1B%73',
        '%1B%62%35%1B%73', '%1B%62%36%1B%73',
        '%1B%62%37%1B%73', '%1B%62%38%1B%73',
        '%1B%62%39%1B%73', '%1B%62%28%1B%73',
        '%1B%62%2B%1B%73', '%1B%62%29%1B%73',
        '%1B%70%30%1B%73', '%1B%70%31%1B%73',
        '%1B%70%32%1B%73', '%1B%70%33%1B%73',
        '%1B%70%34%1B%73', '%1B%70%35%1B%73',
        '%1B%70%36%1B%73', '%1B%70%37%1B%73',
        '%1B%70%38%1B%73', '%1B%70%39%1B%73',
        '%1B%70%28%1B%73', '%1B%70%2D%1B%73',
        '%1B%70%2B%1B%73', '%1B%70%29%1B%73',
        '%E0%E6',          '%E1%E3',
        '%E1%E5',          '%E1%E6',
        '%E1%E8',          '%E2%A5',
        '%E2%B5',          '%E2%E4',
        '%E2%E5',          '%E2%E6',
        '%E2%E8',          '%E2%EA',
        '%E2%F0',          '%E3%E0',
        '%E3%E1',          '%E3%E2',
        '%E3%F2',          '%E4%E3',
        '%E4%E6',          '%E5%E4',
        '%E5%E7',          '%E5%E8',
        '%E5%A5',          '%E5%B5',
        '%E5%F1',          '%E5%F2',
        '%E6%F0',          '%E6%F2',
        '%E7%E2',          '%E7%F2',
        '%E8%E4',          '%E8%E5',
        '%E9%E8'
    );

    my @orphan_chars_single = (
        '%A1', '%A3', '%A6', '%A7', '%A9', '%AC', '%AD', '%AE',
        '%AF', '%B0', '%B1', '%B3', '%B6', '%B7', '%B8', '%BB',
        '%BC', '%BD', '%BE', '%BF', '%C1', '%C2', '%C4', '%E0',
        '%E5', '%E6', '%E7', '%E9', '%EB', '%EC', '%ED', '%EE',
        '%EF', '%F1', '%F2', '%F3', '%F4', '%F5', '%F6', '%F7',
        '%F8', '%F9', '%FA', '%FB', '%FC', '%FD', '%FE'
    );

    my %marc8_to_latin1_combined = (
        '%1B%70%32%1B%73' => 'B2',
        '%1B%70%33%1B%73' => 'B3',
        '%1B%70%31%1B%73' => 'B9',
        '%E1%41'          => 'C0',
        '%E2%41'          => 'C1',
        '%E3%41'          => 'C2',
        '%E4%41'          => 'C3',
        '%E8%41'          => 'C4',
        '%EA%41'          => 'C5',
        '%E2%43'          => '43',
        '%E3%43'          => '43',
        '%F0%43'          => 'C7',
        '%E1%45'          => 'C8',
        '%E2%45'          => 'C9',
        '%E3%45'          => 'CA',
        '%E4%45'          => '45',
        '%E8%45'          => 'CB',
        '%F0%45'          => '45',
        '%E2%47'          => '47',
        '%E3%47'          => '47',
        '%F0%47'          => '47',
        '%E3%48'          => '48',
        '%E8%48'          => '48',
        '%F0%48'          => '48',
        '%E1%49'          => 'CC',
        '%E2%49'          => 'CD',
        '%E3%49'          => 'CE',
        '%E4%49'          => '49',
        '%E8%49'          => 'CF',
        '%E3%4A'          => '4A',
        '%E2%4B'          => '4B',
        '%E3%4B'          => '4B',
        '%F0%4B'          => '4B',
        '%F2%4B'          => '4B',
        '%E2%4C'          => '4C',
        '%E3%4C'          => '4C',
        '%F0%4C'          => '4C',
        '%E2%4D'          => '4D',
        '%E1%4E'          => '4E',
        '%E2%4E'          => '4E',
        '%E4%4E'          => 'D1',
        '%F0%4E'          => '4E',
        '%E1%4F'          => 'D2',
        '%E2%4F'          => 'D3',
        '%E3%4F'          => 'D4',
        '%E4%4F'          => 'D5',
        '%E8%4F'          => 'D6',
        '%E2%50'          => '50',
        '%E2%52'          => '52',
        '%E2%53'          => '53',
        '%E3%53'          => '53',
        '%F0%53'          => '53',
        '%F0%54'          => '54',
        '%E1%55'          => 'D9',
        '%E2%55'          => 'DA',
        '%E3%55'          => 'DB',
        '%E4%55'          => '55',
        '%E8%55'          => 'DC',
        '%EA%55'          => '55',
        '%E4%56'          => '56',
        '%E1%57'          => '57',
        '%E2%57'          => '57',
        '%E3%57'          => '57',
        '%E8%57'          => '57',
        '%E8%58'          => '58',
        '%E1%59'          => '59',
        '%E2%59'          => 'DD',
        '%E3%59'          => '59',
        '%E4%59'          => '59',
        '%E8%59'          => '59',
        '%E2%5A'          => '5A',
        '%E3%5A'          => '5A',
        '%E1%61'          => 'E0',
        '%E2%61'          => 'E1',
        '%E3%61'          => 'E2',
        '%E4%61'          => 'E3',
        '%E8%61'          => 'E4',
        '%EA%61'          => 'E5',
        '%E2%63'          => '63',
        '%E3%63'          => '63',
        '%F0%63'          => 'E7',
        '%E1%65'          => 'E8',
        '%E2%65'          => 'E9',
        '%E3%65'          => 'EA',
        '%E4%65'          => '65',
        '%E8%65'          => 'EB',
        '%F0%65'          => '65',
        '%E2%67'          => '67',
        '%E3%67'          => '67',
        '%F0%67'          => '67',
        '%E3%68'          => '68',
        '%E8%68'          => '68',
        '%F0%68'          => '68',
        '%E1%69'          => 'EC',
        '%E2%69'          => 'ED',
        '%E3%69'          => 'EE',
        '%E4%69'          => '69',
        '%E8%69'          => 'EF',
        '%E3%6A'          => '6A',
        '%E2%6B'          => '6B',
        '%E3%6B'          => '6B',
        '%F0%6B'          => '6B',
        '%F2%6B'          => '6B',
        '%E2%6C'          => '6C',
        '%E3%6C'          => '6C',
        '%F0%6C'          => '6C',
        '%E2%6D'          => '6D',
        '%E1%6E'          => '6E',
        '%E2%6E'          => '6E',
        '%E4%6E'          => 'F1',
        '%F0%6E'          => '6E',
        '%E1%6F'          => 'F2',
        '%E2%6F'          => 'F3',
        '%E3%6F'          => 'F4',
        '%E4%6F'          => 'F5',
        '%E8%6F'          => 'F6',
        '%E2%70'          => '70',
        '%E2%72'          => '72',
        '%E2%73'          => '73',
        '%E3%73'          => '73',
        '%F0%73'          => '73',
        '%E8%74'          => '74',
        '%F0%74'          => '74',
        '%E1%75'          => 'F9',
        '%E2%75'          => 'FA',
        '%E3%75'          => 'FB',
        '%E4%75'          => '75',
        '%E8%75'          => 'FC',
        '%EA%75'          => '75',
        '%E4%76'          => '76',
        '%E1%77'          => '77',
        '%E2%77'          => '77',
        '%E3%77'          => '77',
        '%E8%77'          => '77',
        '%EA%77'          => '77',
        '%E8%78'          => '78',
        '%E1%79'          => '79',
        '%E2%79'          => 'FD',
        '%E3%79'          => '79',
        '%E4%79'          => '79',
        '%E8%79'          => '79',
        '%EA%79'          => '79',
        '%E8%79'          => 'FF',
        '%E2%7A'          => '7A',
        '%E3%7A'          => '7A',
        '%E2%A2'          => '4F',
        '%E1%AC'          => '4F',
        '%E2%AC'          => '4F',
        '%E4%AC'          => '4F',
        '%E1%AD'          => '55',
        '%E2%AD'          => '55',
        '%E4%AD'          => '55',
        '%E2%B2'          => '6F',
        '%E1%BC'          => '6F',
        '%E2%BC'          => '6F',
        '%E4%BC'          => '6F',
        '%E1%BD'          => '75',
        '%E2%BD'          => '75',
        '%E4%BD'          => '75'
    );

    my %marc8_to_latin1_single = (
        '%A2' => 'D8',
        '%A4' => 'DE',
        '%A5' => 'C6',
        '%A8' => 'B7',
        '%AA' => 'AE',
        '%AB' => 'B1',
        '%B2' => 'F8',
        '%B4' => 'FE',
        '%B5' => 'E6',
        '%B9' => 'A3',
        '%BA' => 'F0',
        '%C0' => 'B0',
        '%C3' => 'A9',
        '%C5' => 'BF',
        '%C6' => 'A1'
    );

    foreach my $char1 (@orphan_chars_combined) {
        $line =~ s/$char1//g;
    }

    foreach my $marc_char1 ( keys(%marc8_to_latin1_combined) ) {
        $line
            =~ s/$marc_char1/pack("C", hex($marc8_to_latin1_combined{$marc_char1}))/eg;
    }

    foreach my $char2 (@orphan_chars_single) {
        $line =~ s/$char2//g;
    }

    foreach my $marc_char2 ( keys(%marc8_to_latin1_single) ) {
        $line
            =~ s/$marc_char2/pack("C", hex($marc8_to_latin1_single{$marc_char2}))/eg;
    }

    $line =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/eg;

    return ($line);
}

sub latin1_fallback {
    my ($string) = @_;

    $string =~ s/(.)/($Pod::Escapes::Latin1Char_to_fallback{$1} || $1)/eg;

    return $string;
}

sub strip_tag {
    my $text = shift;

    $text = lc($text);
    $text =~ tr/a-z0-9 //cd;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    return $text;
}

sub title_match {
    my ( $titles1, $titles2, $threshold ) = @_;

    my $found_match = 0;

    my @cleaned_titles1 = map { title_match_clean_titles($_) } @$titles1;
    my @cleaned_titles2 = map { title_match_clean_titles($_) } @$titles2;

MATCHING:
    foreach my $title1 (@cleaned_titles1) {

        my %title1_hash = map { $_, 1 } @$title1;

        foreach my $title2 (@cleaned_titles2) {
            my %title2_hash = map { $_, 1 } @$title2;

            my $match = 0;

            foreach my $title2_word ( keys %title2_hash ) {
                $title1_hash{$title2_word}
                    and $match++;
            }

            if ( $match == scalar( keys %title2_hash ) || $match > 2 ) {
                $found_match = 1;
                last MATCHING;
            }

            $match = 0;

            foreach my $title1_word ( keys %title1_hash ) {
                $title2_hash{$title1_word}
                    and $match++;
            }

            if ( $match == scalar( keys %title1_hash ) || $match > 2 ) {
                $found_match = 1;
                last MATCHING;
            }
        }
    }

    # If we don't have a match yet, try amatch for "close" titles

    if ( !$found_match ) {
    AMATCHING:
        foreach my $title1_array (@cleaned_titles1) {
            my $title1_string = join ' ', @$title1_array;

            foreach my $title2_array (@cleaned_titles2) {
                my $title2_string = join ' ', @$title2_array;

                ( $found_match
                        = amatch( $title1_string, ['20%'], $title2_string ) )
                    and last AMATCHING;
            }
        }
    }

    return $found_match;

    # Strips, removes articles, splits on words

    sub title_match_clean_titles {
        my @words;
        foreach my $word ( split / /, strip_title( strip_articles($_) ) ) {
            next if grep { $word eq $_ } @stop_words;
            push @words, $word;
        }
        return \@words;
    }
}

sub strip_title_for_matching {
    my ($title) = @_;

    foreach my $word (@stop_words) {
        $title =~ s/\s*\b$word\b\s*/ /g;
    }
    $title =~ s/\s\s+/ /g;
    $title =~ s/^\s+//;
    $title =~ s/\s+$//;

    return $title;
}

1;

__END__

marc8_to_latin1 lookup tables and some code used from:

# MARCtoLatin.pl
#
#  Version: 1.0
#
#  Created by Michael Doran, doran@uta.edu
#
#  University of Texas at Arlington Libraries
#  Box 19497, Arlington, TX 76019, USA
#
#  This function was originally written for newbooks.pl, a component
#  of the New Books List, an unofficial add-on for the Voyager 
#  integrated library management system.  For more information on
#  the New Books List, see http://rocky.uta.edu/doran/autolist/.
#
########################################################################
#
#  Copyright 2002, The University of Texas at Arlington ("UTA").
#  All rights reserved.
