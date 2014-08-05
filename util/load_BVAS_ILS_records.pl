# Loads ERM records exported from SFU's III system

use lib 'lib';
use strict;

use Data::Dumper;

use CUFTS::Config;
use Date::Manip;
use Unicode::String qw(utf8);
use CUFTS::CJDB::Util;
use CUFTS::Util::Simple;

my $DEBUG = 0;
my $OVERWRITE_COSTS = 1;

# load started at erm main id 7343
#                 costs id 22

# CONFIG STUFF, GET IDS FROM DATABASE

my $site_id = 1;
my $resource_type_id = 31;

my @month_names = qw( january february march april may june july august september october november december );
my $month_names_for_regex = join '|', @month_names;

my %print_included_map = (
    '-' => 0, # e-journal
    'j' => 1, # e-journal
    'o' => 0, # e-journal collection
    'p' => 1, # e-journal collection
    'e' => 0, # e-book collection
    'd' => 0, # datasets
    'x' => 0, # other
);

my %resource_type_map = (
    '-' => 98, # e-journal
    'j' => 98, # e-journal
    'o' => 12, # e-journal collection
    'p' => 12, # e-journal collection
    'e' => 15, # e-book collection
    'd' => 101, # datasets
    'x' => 19,  # other
);

my %resolver_map = (
    '-' => 1, # e-journal
    'j' => 1, # e-journal
    'o' => 1, # e-journal collection
    'p' => 1, # e-journal collection
    'e' => 0, # e-book collection
    'd' => 0, # datasets
    'x' => 0, # other
);


my @field_names = qw(
    bib_num
    erm_main_id
    journal_auth
    title
    publisher
    acq_num
    resource_type
    fund
);

my @remainder_field_names = qw(
    paid_date
    invoice_date
    invoice_num
    amount_paid
    voucher
    copies
    sub_from
    sub_to
    note
);

my %currency_map = (
    usd => 'USD',
    gbp => 'GBP',
    eur => 'EUR',
    cad => 'CAD',
    at  => 'AUD',
    dk  => 'DKK',
    hk  => 'HKD',
    in  => 'INR',
    jp  => 'JPY',
    mx  => 'MXN',
    nz  => 'NZD',
    no  => 'NOK',
    pk  => 'PKR',
    sg  => 'SGD',
    sa  => 'ZAR',
    sw  => 'SEK',
    sz  => 'CHF',
    us  => 'USD',
    uk  => 'GBP',
    eu  => 'EUR',
);

my $load_timestamp = time();

my $schema = CUFTS::Config::get_schema();

my %records;

print "\n--------\nStarting Parsing\n--------\n";

# Skip first row
my $row = <>;

while ($row = <>) {

    $row =~ s/[\r\n]*$//;

    my $results = parse_row($row, $schema);
    if ( !ref($results) eq 'HASH' ) {
        print "Attempt to parse record failed, debug information was not returned properly.";
        next;
    }
    my ( $record, $debug ) = @$results;

    clean_record( $record );

    # print Dumper($record);

    # Pretty print record

    print "---\n";
    print join( '   ', map { $record->{$_} } ( qw( acq_num bib_num other_num ) ) );
    print "\n";
    print $record->{title}, "  ", join( ', ', map { substr($_, 0, 4) . '-' . substr($_, 4, 4) } @{ $record->{issns} } );
    print "\n";
    print join "\n", @$debug;
    print "\n";

    # Add to hash merged by bib or erm_main number

    my $num = $record->{erm_main_id} || $record->{bib_num};
    die("Record found with no ERM number or bib_number: " . $record->{title})
        if !defined($num);

    # If a match for the record exists, append the acq_num and payment details.
    # Possibly merge payment info if the voucher number is the same

    if ( exists($records{$num}) ) {
        $records{$num}->{acq_num}->{ $record->{acq_num} }++;
        print "Adding payments to a previously parsed record.\n";
        push @{$records{$num}->{payments}}, @{$record->{payments}};
    }
    else {
        $record->{acq_num} = { $record->{acq_num} => 1 };
        $records{$num} = $record;
    }

}

print "\n--------\nStarting Data Load\n--------\n";


foreach my $record ( values %records ) {

    print "Processing: ", $record->{title}, "\n";
    # print Dumper($record), "\n";
    # next;

    # Find or create ERM Main record

    my $erm;
    if ( int($record->{erm_main_id}) ) {
        $erm = $schema->resultset('ERMMain')->find( { site => $site_id, id => $record->{erm_main_id} } );
        if ( !defined($erm) ) {
            print "**** ERROR: Record contains an ERM main id, however the ERM record could not be found. Skipping record.\n";
            next;
        }
    }

    if ( !defined($erm) ) {
        print "* Unable to find matching ERM number, skipping record.\n";
        next;
    }

    # Fall back to trying to match on bib_num

    # elsif ( not_empty_string($record->{bib_num}) ) {
    #     $erm = $schema->resultset('ERMMain')->find( { site => $site_id, local_bib => $record->{bib_num} } );
    # }


    # Otherwise, find/create a new record

    if ( !defined($erm) ) {
#         $erm = $schema->resultset('ERMMain')->find_or_create( {
#             site  => $site_id,
#             key   => $record->{title},
#             issn  => join( ', ', map { substr($_, 0, 4) . '-' . substr($_, 4, 4) } @{ $record->{issns} } ),
#             publisher => $record->{publisher},
# #            journal_auth => int($record->{journal_auth}) || undef,
#             local_bib => $record->{bib_num},
#             local_acquisitions => $record->{acq_num},
#             public => 0,
#             public_list => 0,
#             local_fund => $record->{fund},
#             coverage => $record->{coverage},
#             resource_type => map_resource_type( $record->{resource_type} ),
#             print_included => map_print_included( $record->{resource_type} ),
#             resolver_enabled => map_resolver( $record->{resource_type} ),
#             subscription_status => 'Active',
#             subscription_type => 'Direct Subscription',
#             vendor => $record->{vendor} eq 'caneb' ? 'EBSCO Canada Ltd.' : undef,
#             pricing_model => 14,
#             misc_notes => $load_timestamp,
#         } );
#         $erm->main_name( $record->{title} );
#         print "* CREATED ERM MAIN: ", $erm->id, "\n";
        print "No ERM match: ", $record->{title}, " id: ", $record->{erm_main_id}, "\n";
    }
    else {
        print "* FOUND ERM MAIN: ", $erm->id, "\n";
        $erm->local_acquisitions( join( ', ', keys(%{$record->{acq_num}}) ) );
        $erm->local_bib( $record->{bib_num} );
        $erm->local_fund( $record->{fund} );
        # $erm->vendor($record->{vendor}),
        $erm->update();
    }

    foreach my $payment ( sort { $b->{end_date} cmp $a->{end_date} } @{ $record->{payments} } ) {
        print "   ", $payment->{invoice_date};
        print "   ", $payment->{start_date}, ' - ', $payment->{end_date};
        printf( "%8i", $payment->{voucher} );
        print "   ", $payment->{acq_num};
        printf( "   \$ %9.2f  %3s \$ %9.2f", $payment->{amount_paid}, $payment->{currency_billed}, $payment->{amount_billed} );
        print "  ($payment->{references})" if exists $payment->{references};
        if ( $payment->{sub_from} =~ /\d/ || $payment->{sub_to} =~ /\d/ ) {
            print "   FROM: ", $payment->{sub_from}, ' TO: ', $payment->{sub_to};
        }
        print "\n";

        my $cost = $schema->resultset('ERMCosts')->search( { erm_main => $erm->id, number => $payment->{voucher}, order_number => $payment->{acq_num} } )->first();

        if ( defined($cost) && $OVERWRITE_COSTS ) {
            $cost->delete;
            undef $cost;
        }

        if ( !defined($cost) ) {
            $cost = $schema->resultset('ERMCosts')->create( {
                erm_main         => $erm->id,
                order_number     => $payment->{acq_num},
                number           => $payment->{voucher},
                reference        => $payment->{references},
                date             => $payment->{invoice_date},
                period_start     => $payment->{start_date},
                period_end       => $payment->{end_date},
                paid             => $payment->{amount_paid},
                paid_currency    => 'CAD',  # ???
                invoice          => $payment->{amount_billed} || $payment->{amount_paid},
                invoice_currency => map_currency( $payment->{currency_billed} ),
            } );
            print "* CREATED COSTS: ", $cost->id, "\n";
        }
        else {
            print "* FOUND EXISTING COSTS: ", $cost->id, "\n";
        }


    }

}



# Returns a record.  Yes, this is very ugly because of the bizarre III format.  See the END section for examples
sub parse_row {
    my ($row, $schema) = @_;
    # print $row;

    my %record;
    my @debug;

    # $record{other_num}  = get_comma_field( \$row, 'other_num' );
    $record{bib_num} = get_comma_field( \$row, 'bib_num' );
    $record{erm_main_id}   = get_comma_field( \$row, 'erm_main_id' );


    $record{journal_auth}  = get_comma_field( \$row, 'journal_auth' );
    $record{title}         = utf8( get_comma_field( \$row, 'title' ) )->latin1;
    $record{publisher}     = utf8( get_comma_field( \$row, 'publisher' ) )->latin1;
    $record{acq_num}       = get_comma_field( \$row, 'acq_num' );
    $record{resource_type} = get_comma_field( \$row, 'resource_type' );
    $record{fund}          = get_comma_field( \$row, 'fund' );


    # $record{currency}      = get_comma_field( \$row, 'currency' );

    $record{payments} = [];

    if ( $row !~ /^""/ ) {
        my %references;
        my @payments = split /";/, $row;
        foreach my $payment ( @payments ) {
            my $payment_orig = $payment;
            my %payment_record;

            # print($payment);

            $payment_record{paid_date}     = get_comma_field( \$payment, 'paid_date' );
            $payment_record{invoice_date}  = get_comma_field( \$payment, 'invoice_date' );
            $payment_record{invoice_num}   = get_comma_field( \$payment, 'invoice_num' );
            $payment_record{amount_paid}   = get_comma_field( \$payment, 'amount_paid' );
            $payment_record{voucher}       = get_comma_field( \$payment, 'voucher' );
            $payment_record{copies}        = get_comma_field( \$payment, 'copies' );
            $payment_record{sub_from}      = get_comma_field( \$payment, 'sub_from' );
            $payment_record{sub_to}        = get_comma_field( \$payment, 'sub_to' );

            $payment =~ s/^[",]\s*//;
            $payment =~ s/\s*[",]$//;
            $payment_record{note} = $payment;

            $payment_record{acq_num}       = $record{acq_num};

            # Cleanup the invoice date

            my $inv_date_year = int( substr( $payment_record{invoice_date}, 0, 2 ) );
            substr( $payment_record{invoice_date}, 0, 2 ) = $inv_date_year + ( $inv_date_year > 60 ? 1900 : 2000 );

            # Parse the price and currency
            $payment = lc($payment);
            if ( $payment =~ / \\ ([a-z]{2,3}) \s* ([-.\d]+) $/xsm ) {
                $payment_record{currency_billed} = $1;
                $payment_record{amount_billed} = $2;
            }

            # Try to parse a date out

            # V. 19, JULY 95 - JUNE 96

            # if ( $payment =~ m# ($month_names_for_regex) \s* (\d{2}) \s* - \s* ($month_names_for_regex) \s* (\d{2}) #ixsm ) {
            #     my $start_month = format_month( $1 );
            #     my $start_year  = int($2) + ( int($2) > 60 ? 1900 : 2000 );
            #     my $end_month   = format_month( $3 );
            #     my $end_year    = int($4) + ( int($4) > 60 ? 1900 : 2000 );
            #     my $end_day     = get_end_day( $end_month );
            #
            #     $payment_record{start_date} = sprintf( "%04i-%02i-01",   $start_year, $start_month );
            #     $payment_record{end_date}   = sprintf( "%04i-%02i-%02i", $end_year,   $end_month, $end_day );
            # }
            #
            # # 74(01/99)-75(12/99)
            # # NOTE: This throws away the end month/year and uses 1 year from the start date.
            # elsif ( $payment =~ m# \( (\d{2}) / (\d{2}) \) .* - .*  \( (\d{2}) / (\d{2}) \) #xsmi ) {
            #     my $start_month = $1;
            #     my $start_year = int($2) + ( int($2) > 60 ? 1900 : 2000 );
            #     my $end_month = $1;
            #     my $end_year = int($2) + ( int($2) > 60 ? 1900 : 2000 );
            #     $payment_record{start_date} = sprintf( "%04i-%02i-01", $start_year,   $start_month );
            #     $payment_record{end_date}   = sprintf( "%04i-%02i-01", $end_year + 1, $end_month );
            # }
            #
            # # sept 1/98 - oct 31/99
            # # Oct1/08-Sep30/09
            # elsif ( $payment =~ m# (\w{3,4}?) \s* (\d{1,2}) \s* / \s* (\d{2}) [-&] (\w{3,4}?) \s* (\d{1,2}) \s* / \s* (\d{2}) #xsm ) {
            #     my $start_month = format_month( $1 );
            #     my $start_day   = $2;
            #     my $start_year  = int($3) + ( int($3) > 60 ? 1900 : 2000 );
            #     my $end_month   = format_month( $4 );
            #     my $end_day     = $5;
            #     my $end_year    = int($6) + ( int($6) > 60 ? 1900 : 2000 );
            #
            #     $payment_record{start_date} = sprintf( "%04i-%02i-%02i", $start_year, $start_month, $start_day );
            #     $payment_record{end_date}   = sprintf( "%04i-%02i-%02i", $end_year,   $end_month, $end_day );
            # }
            # # sep/09 - sep/00
            # elsif ( $payment =~ m# (\w{3,4}) / (\d{2}) [-&] (\w{3,4}) / (\d{2}) #xsm ) {
            #     my $start_month = format_month( $1 );
            #     my $start_year  = int($2) + ( int($2) > 60 ? 1900 : 2000 );
            #     my $end_month   = format_month( $3 );
            #     my $end_year    = int($4) + ( int($4) > 60 ? 1900 : 2000 );
            #
            #     $payment_record{start_date} = sprintf( "%04i-%02i-01", $start_year, $start_month );
            #     $payment_record{end_date}   = sprintf( "%04i-%02i-01", $end_year,   $end_month );
            # }
            # # 02/09 - 02/00
            # elsif ( $payment =~ m# (\d{2}) / (\d{2}) [-&] (\d{2}) / (\d{2}) #xsm ) {
            #     my $start_month = $1;
            #     my $start_year  = int($2) + ( int($2) > 60 ? 1900 : 2000 );
            #     my $end_month   = $3;
            #     my $end_year    = int($4) + ( int($4) > 60 ? 1900 : 2000 );
            #
            #     $payment_record{start_date} = sprintf( "%04i-%02i-01", $start_year, $start_month );
            #     $payment_record{end_date}   = sprintf( "%04i-%02i-01", $end_year,   $end_month );
            # }
            # # re:23423
            # elsif ( $payment =~ / re: \s* (o?\d+) /ixsm ) {   # Try for a reference number
            #     $payment_record{references} = $1;
            #
            #     if ( exists $references{ $payment_record{references} } ) {
            #         $payment_record{start_date} = $references{ $payment_record{references} }->{start_date};
            #         $payment_record{end_date}   = $references{ $payment_record{references} }->{end_date};
            #         push @debug, "Found a 're:' reference to: " . $payment_record{references};
            #     }
            #     else {
            #         if ( my $erm_id = $record{erm_main_id} ) {
            #             # Try to find an existing record with a matching reference number
            #             $erm_id =~ s/^e//;
            #             my $cost = $schema->resultset('ERMCosts')->search( { erm_main => $erm_id, number => $payment_record{references} } )->first;
            #             if ( defined($cost) ) {
            #                 $payment_record{start_date} = $cost->period_start;
            #                 $payment_record{end_date}   = $cost->period_end;
            #                 push @debug, "Found a 're:' reference and matching cost record: " . $payment_record{references} . " ERM id: $erm_id";
            #             }
            #             else {
            #                 push @debug, "Found a 're:' reference but no matching cost record: " . $payment_record{references} . " ERM id: $erm_id";
            #             }
            #         }
            #         else {
            #             push @debug, "Found a 're:' reference but no erm_main_id: " . $payment_record{references};
            #         }
            #
            #         # if ( scalar(@{ $record{payments} }) ) {
            #         #     $payment_record{start_date} = $record{payments}->[ $#{ $record{payments} } ]->{start_date};
            #         #     $payment_record{end_date}   = $record{payments}->[ $#{ $record{payments} } ]->{end_date};
            #         #     push @debug, "Found a 're:' reference but no match, defaulting to previous record";
            #         # }
            #     }
            #
            # }
            #
            # #
            # # Fall back to grabbing a single date and assuming a one year purchase period
            # #
            #
            # # 1YR 010196 FRM 01-96
            # elsif ( $payment =~ m# 1YR \s* \d* \s* FRM \s* (\d{2})-(\d{2}) #xsmi ) {
            #     my $month = $1;
            #     my $year = int($2) + ( int($2) > 60 ? 1900 : 2000 );
            #     $payment_record{start_date} = sprintf( "%04i-%02i-01", $year,     $month );
            #     $payment_record{end_date}   = sprintf( "%04i-%02i-01", $year + 1, $month );
            # }
            #
            # # 74(01/99)-   ... (truncated due to bad EBSCO data)
            # elsif ( $payment =~ m# \( (\d{2}) / (\d{2}) \) .* - .* #xsmi ) {
            #     my $start_month = $1;
            #     my $start_year = int($2) + ( int($2) > 60 ? 1900 : 2000 );
            #     $payment_record{start_date} = sprintf( "%04i-%02i-01", $start_year,     $start_month );
            #     $payment_record{end_date}   = sprintf( "%04i-%02i-01", $start_year + 1, $start_month );
            # }
            #
            # # 1998
            # elsif ( $payment =~ / ((?:19|20)\d{2}) (?!\.) /xsm ) {  # Last ditch for a single year
            #     $payment_record{start_date} = sprintf( "%04i-01-01", $1 );
            #     $payment_record{end_date}   = sprintf( "%04i-12-31", $1 );
            # }
            # else {
            #     push @debug, "* Can't parse: $payment. Attempting to use formatted date fields.";
            # }

            # Fallback to trying the pre-parsed sub_from/to fields

            if ( !defined($payment_record{start_date}) || (defined($payment_record{start_date}) && !ParseDate($payment_record{start_date})) ) {
                push @debug, "* Formatted start date: " . $payment_record{sub_from};
                my $prev_start_date = $payment_record{start_date};
                my ( @parts ) = split '-', $payment_record{sub_from};
                if ( not_empty_string($parts[0]) ) {
                    $parts[0] += $parts[0] > 20 ? 1900 : 2000;
                    $payment_record{start_date} = join '-', @parts;
                    push @debug, "* Full start date parsed: $payment_record{start_date}";
                }
            }
            if ( !defined($payment_record{end_date}) || (defined($payment_record{end_date}) && !ParseDate($payment_record{end_date})) ) {
                push @debug, "* Formatted end date: " . $payment_record{sub_to};
                my $prev_end_date = $payment_record{end_date};
                my ( @parts ) = split '-', $payment_record{sub_to};
                if ( not_empty_string($parts[0]) ) {
                    $parts[0] += $parts[0] > 20 ? 1900 : 2000;
                    $payment_record{end_date} = join '-', @parts;
                    push @debug, "* Full end date parsed: $payment_record{end_date}";
                }
            }

            # Validate all dates, or throw the row away.

            my $date_err = 0;
            if ( !defined($payment_record{start_date}) || !ParseDate($payment_record{start_date}) ) {
                $date_err++;
                push @debug, "* Could not parse start date: $payment_record{start_date}";
            }
            if ( !defined($payment_record{end_date}) || !ParseDate($payment_record{end_date}) ) {
                $date_err++;
                push @debug, "* Could not parse end date: $payment_record{end_date}";
            }
            if ( !defined($payment_record{invoice_date}) || !ParseDate($payment_record{invoice_date}) ) {
                $date_err++;
                push @debug, "* Could not parse invoice date: $payment_record{invoice_date}";
            }

            if ( $date_err ) {
                push @debug, "* Date error in payment line: $payment_orig";
            }
            else {
                push @{ $record{payments} }, \%payment_record;
                push @debug, "* Found usable cost data: "
                             . $payment_record{invoice_num}
                             . ' - ' . $payment_record{start_date} . ' - ' . $payment_record{end_date}
                             . ' - ' . $payment_record{amount_paid}
                             . ' ; ' . $payment_record{currency_billed} . ' ' . $payment_record{amount_billed};

                $references{ $payment_record{invoice_num} } = \%payment_record;
            }

        }
    }

    push @debug, "Found " . scalar(@{$record{payments}}) . " usable payment fields";

    return [ \%record, \@debug ];
}

sub get_comma_field {
    my ( $string, $fieldname ) = @_;
    if ( $$string =~ s/"(.*?)",//xsm ) {
        return $1;
    }
    die( "Error parsing $fieldname" );
}

sub format_month {
    my ( $month, $period ) = @_;

    defined($month) && $month ne ''
        or return undef;

    $month =~ /^\d+$/
        and return $month;

    if    ( $month =~ /^Jan/i )  { return 1 }
    elsif ( $month =~ /^Feb/i )  { return 2 }
    elsif ( $month =~ /^Mar/i )  { return 3 }
    elsif ( $month =~ /^Apr/i )  { return 4 }
    elsif ( $month =~ /^May/i )  { return 5 }
    elsif ( $month =~ /^Jun/i )  { return 6 }
    elsif ( $month =~ /^Jul/i )  { return 7 }
    elsif ( $month =~ /^Aug/i )  { return 8 }
    elsif ( $month =~ /^Sep/i )  { return 9 }
    elsif ( $month =~ /^Sept/i ) { return 9 }
    elsif ( $month =~ /^Oct/i )  { return 10 }
    elsif ( $month =~ /^Nov/i )  { return 11 }
    elsif ( $month =~ /^Dec/i )  { return 12 }
    elsif ( $month =~ /^Spr/i )  { return $period eq 'start' ? 1 : 6 }
    elsif ( $month =~ /^Sum/i )  { return $period eq 'start' ? 3 : 9 }
    elsif ( $month =~ /^Fal/i )  { return $period eq 'start' ? 6 : 12 }
    elsif ( $month =~ /^Aut/i )  { return $period eq 'start' ? 6 : 12 }
    elsif ( $month =~ /^Win/i )  { return $period eq 'start' ? 9 : 12 }
    else {
        return 99;
        CUFTS::Exception::App->throw("Unable to find month match: $month");
    }

}


sub clean_record {
    my ( $record ) = @_;

    # Remove [electronic resource] and other bits of trailing junk from titles
    # Order is important for these that match on the end of line

    $record->{title} =~ s/ \s* order \s+ record \s* $//xsm;
    $record->{title} =~ s/ \.? \s* \-* \s* \[electronic \s+ resource\] \s* //xsm;
    $record->{title} =~ s/ \.? \s* \-* \s* \[digital \s+ maps \s+ collection\] \s* //xsm;

    $record->{title} =~ s/^ \[ (.+) \] $/$1/xsm;
    $record->{title} =~ s/^ " (.+) " $/$1/xsm;

    $record->{title} =~ s/ \s*--\s* $//xsm;
    $record->{title} =~ s/ \s*\.\s* $//xsm;

    # Remove trailing comma from 260b (publisher)
    $record->{publisher} =~ s/ , \s* $//xsm;

    $record->{erm_main_id} =~ s/^e//;

}

sub get_end_day {
    my $month = int(shift);
    if ( $month > 0 && $month < 13 ) {
        return ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 )[$month - 1];
    }
    return 1;  # Safe default
}

sub map_resource_type {
    my ( $resource_type ) = @_;

    if ( exists($resource_type_map{$resource_type}) ) {
        return $resource_type_map{$resource_type};
    }

    die("Unrecognized resource type code (CODE3): $resource_type");
}


sub map_print_included {
    my ( $resource_type ) = @_;

    if ( exists($print_included_map{$resource_type}) ) {
        return $print_included_map{$resource_type};
    }

    die("Unrecognized resource type code (CODE3): $resource_type");
}

sub map_resolver {
    my ( $resource_type ) = @_;

    if ( exists($resolver_map{$resource_type}) ) {
        return $resolver_map{$resource_type};
    }

    die("Unrecognized resource type code (CODE3): $resource_type");
}


sub map_currency {
    my ( $currency ) = @_;

    my $new_currency = $currency_map{ $currency };
    if ( !defined($new_currency) ) {
        print("Missing currency, defaulting to CAD.\n");
        return 'CAD';
    }

    return $new_currency;
}

__END__

"RECORD #(BIBLIO)","930","035|s","245","260|b","RECORD #(ORDER)","CODE3","FUND","Paid Date","Invoice Date","Invoice Num","Amount Paid","Voucher Num","Copies","Sub From","Sub To","Note"
"b14356971","e11708","CJDB21784899","The Oxford literary review.","Oxford Literary Review, etc.]","o3557595","j","engls","10-11-30","10-11-03","9666104","169.18","89975","001","11-01-01","11-12-31","33(01/11)-33(12/11)!C0514658\usd163.05"
"b52385462","","CJDB154326","The Journal of fixed income. [electronic resource]","Institutional Investor,","o5624034","-","buadp","11-01-20","10-12-03","9675613B","253.25","90611","001","11-01-01","11-12-31","20(01/11)-21(12/11)\usd222.37"
"b52385942","","CJDB154365","Journal of portfolio management. [electronic resource]","Institutional Investor Systems]","o562406x","-","buadp","11-01-20","10-12-03","9675613B","253.26","90611","001","11-01-01","11-12-31","37(01/11)-38(12/11)\usd222.37"
"b51770969","e10002","CJDB151430","Canadian journal of science, mathematics and technology education = Revue canadienne de l'enseignement des sciences, des mathématiques et des technologies. [electronic resource]","OISE/University of Toronto = IEPO/Université de Toronto,","o5200817","-","educp","10-12-03","10-11-03","9666173","307.84","90092","001","11-01-01","11-12-31","(01/11)-(12/11)!B4892487\usd265.00";"11-12-05","11-11-11","9686804","311.28","93807","001","12-01-01","12-12-31","12(01/12)-12(12/12)!B4892487\usd276.00"
"b55184443","e10003","","The Canadian foreign relations index, CFRI [electronic resource].","Canadian Institute of International Affairs]","o5341991","-","poliw","10-11-25","10-11-03","9666257","610.16","89931","001","11-04-01","12-03-31","(04/11)-(03/12)!B7388303\";"11-04-28","11-04-13","0002480","-274.40","91822","001","11-04-01","12-03-31","Re:9666257:Rate Adj Apr/11-Mar/12\";"11-12-06","11-11-04","9686836","461.09","93828","001","12-04-01","12-12-31","(04/12)-(12/12)!B7388303\";"12-02-23","12-01-13","0078789","132.28","94647","001","12-04-01","12-12-31","Re:9686836:Rate Adj 04/12-12/12"
"b52173033","e10004","CJDB28907299";"(OCoLC)70663234","The Annals of applied statistics.","Institute of Mathematical Statistics","o5231516","j","statp","10-11-30","10-11-03","9666091","334.10","89962","001","11-01-01","11-12-31","v.5,2011\usd322.00";"11-12-05","11-11-16","9686729","392.87","93787","001","12-01-01","12-12-31","6(01/12)-6(12/12)!B4728950\usd390.00"
"b54923177","e10034","CJDB163279","Journal of the Audio Engineering Society. [electronic resource]","Audio Engineering Society.","o523153x","-","surrp","10-12-03","10-11-03","9666172","623.82","90091","001","11-01-01","11-12-31","59(01/11)-59(12/11)!B5172368\usd537.00";"11-12-05","11-11-11","9686803","605.65","93806","001","12-01-01","12-12-31","60(01/12)-60(12/12)!B5172368\usd537.00"
"b54923189","e10045","","American Society for Quality - Sustaining membership [electronic resource]","","o5231541","-","statp","10-11-30","10-11-03","9666091","894.38","89962","001","11-01-01","11-12-31","2011\usd862.00";"11-02-03","11-01-13","0056828","152.58","90824","001","11-01-01","11-12-31","Re:9666091 rate inc \usd150.00";"11-12-05","11-11-16","9686729","1019.43","93787","001","12-01-01","12-12-31","(01/12)-(12/12)!B5172350\usd1012.00"
"b54923190","e10049","","Additional Nature research journals [electronic resource]","","o5231553","-","gscip","10-04-28","10-04-01","9029","11940.59","87944","001","10-09-01","11-08-31","Sep/10-Aug/11\usd11902.50";"11-02-24","11-02-17","9779","1226.83","91143","001","10-09-01","11-08-31","Sep1/10-Aug31/11\usd1244.00";"11-05-09","11-04-01","11026","12974.73","91903","001","11-09-01","12-08-31","Sept 1/11-Aug 31/12\usd13586.10";"12-03-13","12-03-05","11745","2747.44","94934","001","11-09-01","12-08-31","Sept 1/11-Aug 31/12\usd2742.78"
