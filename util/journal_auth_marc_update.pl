#!/usr/local/bin/perl

use lib qw(lib);

use strict;

use Data::Dumper;

use CUFTS::Config;
use CUFTS::Exceptions qw(assert_ne);
use String::Util qw(hascontent trim);

use CUFTS::CJDB::Loader::MARC;

use MARC::Batch;
use MARC::Record;
use MARC::Field;

$|=1;

my $DEBUG = 1;

my $field_mappings = {
    '050' => [qw(a)],
    '055' => [qw(a)],
    '110' => [qw(a b c)],
    '222' => [qw(a b)],
    '260' => [qw(a b)],
    '310' => [qw(a b)],
    '321' => [qw(a b)],
    '362' => [qw(a z)],
    '6..' => [qw(a b x y z v)],
    '710' => [qw(a b c)],
    '780' => [qw(a s t x)],
    '785' => [qw(a s t x)],
};

my $field_stopwords_re = {
    '110' => [qw(
       ejournal
       electronic
       jstor
       iop
       online
    )],
};
$field_stopwords_re->{'710'} = $field_stopwords_re->{'110'};

my $field_stopwords_eq = {

};


use Getopt::Long;

# Read command line arguments

my %options;
GetOptions(\%options, 'ztarget');

if (!$options{ztarget} && !scalar(@ARGV)) {
    usage();
    exit;
}

run(\%options, \@ARGV);

sub run {
    my ($options, $files) = @_;

    my $stats = {
        found => 0,
        total => 0,
    };

    my $schema = CUFTS::Config::get_schema();

    my $loader = CUFTS::CJDB::Loader::MARC->new();

    my $marc_cache = marc_cache($loader, $files);

    my $journals_auth_rs = $schema->resultset('JournalsAuth')->search({ MARC => undef });
    while ( my $journals_auth = $journals_auth_rs->next ) {
        $stats->{total}++;

        my @records;
        foreach my $target ($options{ztarget}) {
            push @records, z3950_lookup($loader, $target, $journals_auth);
        }

        push @records, marc_cache_lookup($loader, $marc_cache, $journals_auth);

        $stats->{found} += process_records($loader, \@records, $journals_auth);
    }

    print "\n\n";
    print "Total: ", $stats->{total}, "\n";
    print "Found: ", $stats->{found}, "\n";
}


sub z3950_lookup {
    my ($loader, $target, $journals_auth) = @_;
    return ();
}

sub marc_cache {
    my ($loader, $files) = @_;

    my $cache = {};
    my $count;

    $DEBUG and print "Building MARC cache.\n";

    my $batch = MARC::Batch->new('USMARC', @$files);
    while (my $record = $batch->next) {
        my @issns = $loader->get_clean_issn_list($record);
        foreach my $issn (@issns) {
            $count++;
            if ( is_too_brief($record) ) {
                if ( $DEBUG ) {
                    print 'S';
                }
                next;
            }
            push @{$cache->{$issn}}, $record;
            if ( $DEBUG ) {
                print '.';
                print "\n$count\n" if $count && $count % 100 == 0;
            }
        }
    }

    print "Cached $count ISSNs from MARC files.\n";

    return $cache;
}

sub is_too_brief {
    my $record = shift;

    my $count = 0;
    foreach my $field ( keys %$field_mappings ) {
        my @fields = $record->field($field);
        $count += scalar(@fields);
    }

    return !$count;
}

sub marc_cache_lookup {
    my ($loader, $marc_cache, $journals_auth) = @_;

    my @records;
    my @j_a_issns = map {$_->issn} $journals_auth->issns;
    foreach my $issn (@j_a_issns) {
        foreach my $record (@{$marc_cache->{$issn}}) {
            if (match($loader, $record, $journals_auth)) {
                push @records, $record;
            }
        }
    }

    return @records;
}


sub process_records {
    my ($loader, $records, $journals_auth) = @_;

    return 0 unless scalar(@$records);

    print $journals_auth->title, ": ", scalar(@$records), " records found\n";
    my $new_record = build_marc_record($loader, $records, $journals_auth);

    $journals_auth->marc($new_record->as_usmarc);
    $journals_auth->update;

    print $new_record->as_formatted;
    print "\n\n";


    return 1;
}

sub match {
    my ($loader, $marc, $journals_auth) = @_;

    my @j_a_issns = map {$_->issn} $journals_auth->issns;
    return 0 unless scalar(@j_a_issns);

    my @marc_issns = $loader->get_clean_issn_list($marc);

    # For now only match records that have ISSNs

    my $issn_match = 0;
    foreach my $j_a_issn (@j_a_issns) {
        if (grep {$j_a_issn eq $_} @marc_issns) {
            $issn_match++;
            last;
        }
    }
    return 0 unless $issn_match;

    # Do a title check and make sure we've got a good record.

    my @journals_auth_titles = map {$_->title} $journals_auth->titles;
    my @marc_titles = $loader->get_title($marc);
    push @marc_titles, $loader->get_alt_titles($marc);

    if (CUFTS::CJDB::Util::title_match(\@journals_auth_titles, \@marc_titles)) {
        return 1;
    }


    return 0;
}

sub build_marc_record {
    my ($loader, $records, $journals_auth) = @_;

    my $new = MARC::Record->new;

    # Grab all the ISSNs

    my %issns;
    foreach my $record (@$records) {
        foreach my $issn ((map {$_->issn} $journals_auth->issns), $loader->get_clean_issn_list($record)) {
            next if $issns{$issn}++;
            $new->append_fields(MARC::Field->new('022', '#', '#', 'a' => $issn));
            $issns{$issn} = 1;
        }
    }

    # Try taking the main title from a MARC record.  Pick the biggest one until
    # we have a better way to judge.

    my %seen;
    my ($x, $max_title_length, $title_length_index) = (0, 0, 0);
    foreach my $record (@$records) {
        my $temp_title = '';
        my $title_field = $record->field('245');
        foreach my $subfield (qw/a b c n p/) {
            $temp_title .= $title_field->subfield($subfield);
        }

        if (length($temp_title) > $max_title_length) {
            $max_title_length = length($temp_title);
            $title_length_index = $x;
        }

        $x++;
    }
    my $best_title_field = $records->[$title_length_index]->field('245');
    my @title_subfields;
    my $best_title_seen = '';
    foreach my $subfield (qw/a b c n p/) {
        next unless defined($best_title_field->subfield($subfield));
        my $temp_title = $best_title_field->subfield($subfield);
        $temp_title =~ s/\.$//;
        $best_title_seen .= lc($temp_title);
        push @title_subfields, $subfield, $best_title_field->subfield($subfield)
    }
    $seen{'title'}->{$best_title_seen}++;

    my $new_title_field = MARC::Field->new('245', $best_title_field->indicator(1), $best_title_field->indicator(2), @title_subfields);
    $new->append_fields($new_title_field);

    # Grab all the alternate titles from MARC records and the journals_auth files and compile them

    foreach my $record (@$records) {
        foreach my $title_field ($record->field('245'), $record->field('246')) {
            my $seen_title = '';
            my @subfields;
            foreach my $subfield (qw/a b c n p/) {
                next unless defined($title_field->subfield($subfield));
                my $temp_title = lc($title_field->subfield($subfield));
                $temp_title =~ s/\.$//;
                $seen_title .= $temp_title;
                push @subfields, $subfield, $title_field->subfield($subfield);
            }
            next if $seen{'title'}{$seen_title}++;
            next if !scalar(@subfields);

            my $new_title_field = MARC::Field->new('246', '0', '#', @subfields);
            $new->append_fields($new_title_field);
        }

        foreach my $abbr_field ($record->field('210')) {
            my $seen_title = $abbr_field->subfield('a');
            next if $seen{'title'}{$seen_title}++;
            $new->append_fields($abbr_field);
        }

    }

    foreach my $title_field ($journals_auth->titles) {
        next if $seen{'title'}{lc($title_field->title)}++;
        $new->append_fields(MARC::Field->new('246', '0', '#', 'a' => $title_field->title));
    }


    foreach my $record (@$records) {
        foreach my $field_type (sort keys(%$field_mappings)) {
            foreach my $field ($record->field($field_type)) {

                # Only allow one 110 field, switch others to 710

                $field_type eq '110' && defined($seen{'110'}) and
                    $field_type = '710';

                my $seen_value = '';
                my @subfields;

                foreach my $subfield (@{$field_mappings->{$field_type}}) {
                    next unless defined($field->subfield($subfield));
                    $seen_value .= lc($field->subfield($subfield));
                    push @subfields, $subfield, $field->subfield($subfield);
                }

                next if check_stopwords($field_type, $seen_value);
                next if $seen{$field_type}->{$seen_value}++;
                next unless scalar(@subfields);

                my @indicators;
                if (defined($field->indicator(1))) {
                    push @indicators, $field->indicator(1);
                }
                if (defined($field->indicator(2))) {
                    push @indicators, $field->indicator(2);
                }

                my $new_field = MARC::Field->new($field->tag, @indicators, @subfields);

                $new->append_fields($new_field);
            }
        }
    }

    return $new;
}


sub check_stopwords {
    my ($field_type, $seen_value) = @_;

    foreach my $stopword ( @{$field_stopwords_eq->{$field_type}} ) {
        return 1 if $seen_value eq $stopword;
    }
    foreach my $stopword ( @{$field_stopwords_re->{$field_type}} ) {
        return 1 if $seen_value =~ /$stopword/;
    }
    return 0;
}


sub usage {
    print "journal_auth_marc [options] [files]- Build MARC records for the JournalsAuth table\n";
    print "--ztarget module - Search a Z39.50 server for records.  Repeatable.\n";
    print "files - scan MARC files for matching records.\n";
}
