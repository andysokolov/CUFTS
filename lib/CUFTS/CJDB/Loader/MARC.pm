package CUFTS::CJDB::Loader::MARC;

use base ('CUFTS::CJDB::Loader');

use Business::ISSN;
use MARC::Record;
use MARC::Batch;
use CUFTS::CJDB::Util;
use String::Util qw( hascontent trim );

use MARC::Field;
MARC::Field->allow_controlfield_tags('FMT', 'LDX');

use Data::Dumper;

use strict;

sub get_batch {
    my $self = shift;

    return MARC::Batch->new( 'USMARC', @_ );
}

sub get_title {
    my ( $self, $record, $fields ) = @_;

    if ( !defined($fields) ) {
        $fields = $self->MARC_title_subfield_order();
    }

    my $field245 = $record->field('245');
    my @data;

    if ( !ref($field245) ) {
        warn("245 field missing from record: \n" . Dumper($record) );
        return undef;
    }

    foreach my $subfield ( @$fields ) {
        my @subfield_data = $field245->subfield( $subfield );
        push @data, @subfield_data;
    }

    my $title = join ' ', @data;
    eval {
        $title = $self->encode_to_latin1( $self->clean_title( $title ) );
    };
    if ( $@ ) {
        warn($@);
        warn("Skipping title \"$title\" due to MARC8->latin1 translation error.");
        return undef;
    }

    $title = substr( $title, 0, 1024 );

    return $title;
}

sub clean_title {
    my ( $self, $title ) = @_;

    $title =~ s/ \s+ ---? \.? \s* $//xsm;  # trailing ---
    $title =~ s/ \. $//xsm;                # trailing .
    $title =~ s/ \s+  \[ .+ \]  \s*$//xsm; # trailing [ ... ]

    return $title;
}

sub get_sort_title {
    my ( $self, $record ) = @_;

    my $title;
    my $title_field = $record->field('245');
    if (defined($title_field)) {
        $title = substr( $self->get_title( $record ), $record->field('245')->indicator('2') );
    } else {
        $title = $self->get_title( $record );
    }
    eval {
        $title = $self->encode_to_latin1($title);
    };
    if ( $@ ) {
        warn($@);
        warn("Skipping title \"$title\" due to MARC8->latin1 translation error.");
        return undef;
    }

    $title = $self->clean_title($title);

    return $title;
}

sub get_issns {
    my ( $self, $record ) = @_;

    my @issns;
    foreach my $issn_field ( $record->field('022') ) {
        foreach my $issn ( split / /, $issn_field->as_string ) {
            my $issn = $self->clean_issn($issn);
            next if !$self->test_issn($issn);
            $issn = $self->strip_issn_dash($issn);
            push @issns, $issn;
        }
    }

    return @issns;
}

sub get_alt_titles {
    my ( $self, $record ) = @_;

    my @alt_titles;

    my @alt_marc_titles = $record->field('246');

    # Also load abbreviations and previous titles

    push @alt_marc_titles, $record->field('210');
#    push @alt_marc_titles, $record->field('247');

ALT_TITLE:
    foreach my $alt_title (@alt_marc_titles) {
        my $title = $alt_title->subfield('a');

        # Grab: b - Remainder of title
        #       n - Number of part/section of a work
        # 	    p - Name of part/section of a work

        if ( defined( $alt_title->subfield('b') ) ) {
            $title .= ' ' . $alt_title->subfield('b');
        }
        if ( defined( $alt_title->subfield('n') ) ) {
            $title .= ' ' . $alt_title->subfield('n');
        }
        if ( defined( $alt_title->subfield('p') ) ) {
            $title .= ' ' . $alt_title->subfield('p');
        }

        $title = trim( $title );

        # Drop articles

        $title = $self->strip_articles($title);

        # Remove trailing (...)  eg. (Toronto, ON)

        $title =~ s/ \( .+? \)  \s* \.? \s* $//xsm;

        # Fix up diacritics

        eval {
            $title = $self->encode_to_latin1($title);
        };
        if ( $@ ) {
            warn($@);
            warn("Skipping alt title \"$title\" due to MARC8->latin1 translation error.");
            next ALT_TITLE;
        }

        # Trim title to 1024 characters

        $title = substr( $title, 0, 1024 );

        my $stripped_title = $self->strip_title($title);

        # Make sure we have a non-empty title

        next ALT_TITLE if    !hascontent($title)
                          || !hascontent($stripped_title);

        # Skip weird titles like "Membership..."

        next ALT_TITLE if $title =~ m{ Membership }xsm;

        # Skip alternate titles that match common single words
        # like "Journal" and "Review".

SKIP_WORD:
        foreach my $skip_word ( 'review', 'journal' ) {
            next ALT_TITLE if $stripped_title eq $skip_word;
        }

        push @alt_titles, [ $stripped_title, $title ];
    }

    return @alt_titles;
}

sub get_rank {
    return -1;
}

sub get_identifier {
    my ( $self, $record ) = @_;

}

sub get_coverage {
    my ( $self, $record ) = @_;

}

sub get_MARC_subjects {
    my ( $self, $record, $fields ) = @_;

    if ( !defined($fields) ) {
        $fields = $self->MARC_subject_subfield_order();
    }

    my @subjects;

    my @marc_subjects = $record->field('6..');

    foreach my $subject_field (@marc_subjects) {

        my @data;

        foreach my $subfield ( @$fields ) {
            my @subfield_data = $subject_field->subfield( $subfield );
            push @data, @subfield_data;
        }

        my $subject = join ' ', @data;
        eval {
            $subject = $self->encode_to_latin1( $self->clean_subject( $subject ) );
        };
        if ( $@ ) {
            warn($@);
            warn("Skipping subject \"$subject\" due to MARC8->latin1 translation error.");
            next;
        }

        push @subjects, $subject;
    }

    return @subjects;
}

sub get_image {
    my ( $self, $record ) = @_;

    return undef;
}

sub get_image_link {
    my ( $self, $record ) = @_;

    return undef;
}

sub get_rss {
    my ( $self, $record ) = @_;

    return undef;
}

sub get_miscellaneous {
    my ( $self, $record ) = @_;

    return undef;
}

sub get_call_numbers {
    my ( $self, $record ) = @_;

    my @call_numbers;

    my @call_number_fields = $record->field('050');

    foreach my $call_number_field (@call_number_fields) {
        push @call_numbers, uc( $call_number_field->subfield('a') );
    }

    # Try the Canadian specific call number field

    if ( !scalar(@call_numbers) ) {
        @call_number_fields = $record->field('055');
        foreach my $call_number_field (@call_number_fields) {
            push @call_numbers, uc( $call_number_field->subfield('a') );
        }
    }

    return \@call_numbers;
}

sub get_associations {
    my ( $self, $record ) = @_;

    my @associations;

    my @marc_associations = $record->field('110');
    push @marc_associations, $record->field('710');

    foreach my $association (@marc_associations) {
        eval {
            my $association_string = $self->encode_to_latin1( $self->clean_association( $association->as_string ) );
            push @associations, $association_string;
        };
        if ( $@ ) {
            warn($@);
            warn("Skipping association \"" . $association->as_string . "\" due to MARC8->latin1 translation error.");
            next;
        }

    }

    return @associations;
}


sub get_relations {
    my ( $self, $record ) = @_;

    my @relations;

    my @preceeding = $record->field('780');
    my @succeeding = $record->field('785');
    my @other      = $record->field('775');

    foreach my $preceeding (@preceeding) {
        push @relations, $self->_get_relation( $preceeding, 'preceeding' );
    }
    foreach my $succeeding (@succeeding) {
        push @relations, $self->_get_relation( $succeeding, 'succeeding' );
    }
    foreach my $other (@other) {
        push @relations, $self->_get_relation( $other, 'other' );
    }

    return @relations;
}


sub _get_relation {
    my ( $self, $field, $relation_type ) = @_;

    my $relation = { relation => $relation_type };

    my $title = $field->subfield('t');

    eval {
        $title = $self->encode_to_latin1( $title );
    };
    if ( $@ ) {
        warn($@);
        warn("Skipping relation \"$title\" due to MARC8->latin1 translation error.");
        return undef;
    }

    $title = $self->clean_title( $title );
    my $stripped_sort_title = $self->strip_title($title);


    eval {

        if ( grep { $_ eq $stripped_sort_title } @CUFTS::CJDB::Util::generic_titles ) {
            $title .= ' / '
                   . $self->clean_title( $self->encode_to_latin1( $field->subfield('a') ) );
        }

        $relation->{title} = $title
                             || $self->clean_title( $self->encode_to_latin1( $field->subfield('a') ) );
    };
    if ( $@ ) {
        warn($@);
        warn("Skipping relation \"" . $field->subfield('a') . "\" due to MARC8->latin1 translation error.");
        return undef;
    }


    if ( hascontent( $field->subfield('b') ) ) {
        $relation->{title} .= ' ' . $field->subfield('b');
    }

    my $issn = $field->subfield('x');
    $issn = $self->clean_issn($issn);

    if ( $self->test_issn($issn) ) {
        $relation->{issn} = $self->strip_issn_dash($issn);
    }

    return $relation;
}

sub get_ceding_fields_issns {
    my ( $self, $record ) = @_;

    my @issns;

    foreach my $ceding_field ( $record->field('78.'), $record->field('775') ) {
        my $issn = $ceding_field->subfield('x');

        if ( defined($issn) ) {
            $issn = $self->clean_issn($issn);
            if ( defined($issn) ) {
                push @issns, $self->strip_issn_dash($issn);
            }
        }

    }

    return @issns;
}

sub clean_issn {
    my ( $self, $issn ) = @_;

    $issn = uc($issn);

    if ( $issn =~ / ( \d{4} \-? \d{3}[\dX] ) /xsm ) {
        return $1;
    } else {
        return undef;
    }
}

sub strip_issn_dash {
    my ( $self, $issn ) = @_;
    $issn =~ s/-//;
    return $issn;
}

sub test_issn {
    my ( $self, $issn, $err ) = @_;

    if ( !defined($issn) ) {
        $$err = 'Missing ISSN.';
        return 0;
    }

    unless ( $issn =~ /^ \d{4} \-? \d{3}[\dXx] $/xsm ) {
        $$err = 'Invalid ISSN: ' . $issn;
        return 0;
    }

    unless ( Business::ISSN::is_valid_checksum($issn) ) {
        $$err = 'ISSN fails checksum: ' . $issn;
        return 0;
    }

    return 1;
}

sub clean_subject {
    my ( $self, $subject ) = @_;

    $subject =~ s/ \. $//xsm;
    $subject = trim($subject);

    if ( $self->strip_subject_periodicals ) {
        $subject =~ s/ \s+ periodicals $//xsmi;
    }

    return trim($subject);
}

sub clean_association {
    my ( $self, $association ) = @_;

    $association =~ s/ \. $//xsm;

    return $association;
}

sub strip_subject_periodicals {

    # Default to yes.
    return 1;
}

sub preserve_print_MARC {
    return 0;
}

sub export_print_holdings {
    return 0;
}

sub MARC_subject_subfield_order {
    return [ qw( a b c d e z y x v 2 3 4 6 8 ) ];
}

sub MARC_title_subfield_order {
    return [ qw( a b c f g h k n p s ) ];
}

sub encode_to_latin1 {
    my $self = shift(@_);
    return CUFTS::CJDB::Util::marc8_to_latin1(@_);
}

sub modify_marc_dump_record {}

1;
