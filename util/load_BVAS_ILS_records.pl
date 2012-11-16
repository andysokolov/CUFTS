# Loads ERM records exported from SFU's III system

use lib 'lib';
use strict;

use Data::Dumper;

use CUFTS::Schema;
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
    issn
    journal_auth
    title
    publisher
    coverage
    vendor
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

my $schema = CUFTS::Schema->connect( 'dbi:Pg:dbname=CUFTS3', 'tholbroo', '' );

my %records;

print "\n--------\nStarting Parsing\n--------\n";

# Skip first row
my $row = <>;

while ($row = <>) {

    chomp($row);
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


    my $issns = get_comma_field( \$row, 'issns' );
    $record{issns} = [ map { $_ =~ s/-//; $_ } split /";"/, $issns ];

    $record{journal_auth}  = get_comma_field( \$row, 'journal_auth' );
    $record{title}         = utf8( get_comma_field( \$row, 'title' ) )->latin1;
    $record{publisher}     = utf8( get_comma_field( \$row, 'publisher' ) )->latin1;
    $record{coverage}      = get_comma_field( \$row, 'coverage' );
    $record{vendor}        = get_comma_field( \$row, 'vendor' );
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
            
            if ( $payment =~ / \\ ([a-zA-Z]{2,3}) \s* ([-.\d]+) $/xsm ) {
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
                push @debug, "* Found usable cost data: " . $payment_record{invoice_num} . ' - ' . $payment_record{start_date} . ' - ' . $payment_record{end_date} . ' - ' . $payment_record{amount_paid};
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

"RECORD #(BIBLIO)","RECORD #(ORDER)","FUND","ISBN/ISSN","TITLE","260|b","CODE3","LIB. HAS","035|s","Paid Date","Invoice Date","Invoice Num","Amount Paid","Voucher Num","Copies","Sub From","Sub To","Note"
"b52266722","o1222120","psycp","15326942";"87565641","Developmental neuropsychology. [electronic resource]","Lawrence Erlbaum Associates,","-","Available full text from InformaWorld - Taylor and Francis - InformaWorld: 1997-01-01 (v.16 i.1) -";"Available full text from Biomedical Reference Collection: Comprehensive - EBSCO: 1999-01-01 -  12 months embargo","CJDB141102","96-01-16","95-11-29","9344859","304.59","4027","001","  -  -  ","  -  -  ","  1YR 010196 FRM 01-96\us220.00";"96-12-10","96-07-11","9363381","402.42","10248","001","  -  -  ","  -  -  ","  1YR FRM 01-97\us295.00";"97-11-18","97-10-29","9384310","474.25","15403","001","  -  -  ","  -  -  ","  1YR FRM 01-98\us330.00";"98-11-18","98-10-28","9408578","927.88","21019","001","  -  -  ","  -  -  ","  15(01/99)-17(12/99)\us595.00";"99-11-17","99-03-11","9428832","1027.16","26690","001","  -  -  ","  -  -  ","  (01/00)-(12/00)\us645.00";"01-02-01","00-02-11","9456640","1158.27","33396","001","  -  -  ","  -  -  ","  (01/01)-(12/01)\us695.00";"01-12-11","01-10-25","9477467","1200.19","39056","001","  -  -  ","  -  -  ","  (01/02)-(12/02)\us750.00";"02-01-02","01-01-25","9477467adj1","0.00","39220","001","  -  -  ","  -  -  ","  GST ADJ\us0.00";"02-12-06","02-11-02","9492876","1231.30","45358","001","  -  -  ","  -  -  ","  23(01/03)-24(12/03)\us720.00";"04-01-23","03-11-21","9514553","1056.78","51977","001","  -  -  ","  -  -  ","  25(01/04)-26(12/04)\us755.00";"04-03-03","04-02-13","S-64184","183.63","52701","001","  -  -  ","  -  -  ","  RE:9492876:+2003 ONLINE\us126.76";"04-03-03","04-02-13","S-64184","132.13","52701","001","  -  -  ","  -  -  ","  RW:9514553 +2004 ONLINE\us91.21";"04-08-12","04-06-13","005990","-47.20","55612","001","  -  -  ","  -  -  ","  re:9492876 rate adj \us-35.49";"05-01-21","04-12-02","9545333","1119.38","57328","001","  -  -  ","  -  -  ","  27(01/05)-28(12/05)!X61817\us860.00";"05-05-19","05-03-13","0004154","-110.96","59646","001","  -  -  ","  -  -  ","  Re:9545333 online only ch\us-85.00";"05-12-16","05-11-04","9564026","1034.39","63434","001","  -  -  ","  -  -  ","  29(01/06)-30(1\us 800.00";"07-01-19","06-11-08","9582785","986.98","69622","001","  -  -  ","  -  -  ","  31(01/07)-32(1\us 867.00";"07-02-08","07-01-13","S-37209","220.26","70379","001","  -  -  ","  -  -  ","  v.31-32,2007\us 173.40";"07-12-14","07-10-26","9603697","958.48","75314","001","  -  -  ","  -  -  ","  33(01/08)-34(1\us 942.00"
"b52288985","o122542x","geogp","07038992","Canadian journal of remote sensing. [electronic resource]","Canadian Aeronautics and Space Institute,","-","Available full text from SFU Library - SFU Library: 2002-01-01 (v.28) -";"Available full text from National Research Council Affiliated Journals - NRC Research Press: 2002-02-01 (v.28 i.1) -","CJDB168159","96-02-06","95-11-29","9344809","101.68","4527","001","  -  -  ","  -  -  ","   1YR 010196 FRM 01-96";"96-12-10","96-07-11","9363423","101.68","10302","001","  -  -  ","  -  -  ","   1YR FRM 01-97";"97-11-18","97-10-29","9384353","101.80","15452","001","  -  -  ","  -  -  ","   1YR FRM 01-98";"98-12-02","98-11-12","9408620","101.80","21226","001","  -  -  ","  -  -  ","   24(01/99)-25(12/99)";"99-11-18","99-03-11","9428877","101.80","26735","001","  -  -  ","  -  -  ","   25(01/00)-26(12/00)";"01-01-24","00-02-11","9456693","152.70","33235","001","  -  -  ","  -  -  ","   V.27, 2001 [SEE GEN]";"01-11-28","01-10-25","9477520","152.85","38640","001","  -  -  ","  -  -  ","   27(01/02)-27(12/02)";"02-01-30","02-01-13","S-45188","5.45","39918","001","  -  -  ","  -  -  ","   RE:9477520 RATE INCREASE ";"02-12-10","02-11-02","9492929","168.84","45421","001","  -  -  ","  -  -  ","   29(01/03)-29(12/03)";"03-11-26","03-10-29","9514611","173.14","51177","001","  -  -  ","  -  -  ","   30(01/04)-30(12/04)";"04-02-05","04-01-13","S-54862","16.34","52194","001","  -  -  ","  -  -  ","   RATE INCR 2004 RE 9514611";"05-07-28","05-06-24","9556648","178.33","60671","001","  -  -  ","  -  -  ","   v.30,2005";"05-12-16","05-11-02","9564097","190.72","63409","001","  -  -  ","  -  -  ","  31(01/06)-32(12/06)!Y205";"07-01-18","06-11-08","9582881","197.47","69549","001","  -  -  ","  -  -  ","  32(01/07)-33(12/07)!A329";"08-01-15","07-11-09","9603806","215.19","75560","001","  -  -  ","  -  -  ","  33(01/08)-34(12/08)!C048"
"b52266795","o1228079","psycp","15374424";"15374416","Journal of clinical child and adolescent psychology. [electronic resource]","Lawrence Erlbaum Associates, Inc.,","-","Available full text from InformaWorld - Taylor and Francis - InformaWorld: 1997-01-01 (v.14 i.1) -";"Available full text from Academic Search Elite - EBSCO: 2002-02-01 -  12 months embargo";"Available full text from Biomedical Reference Collection: Comprehensive - EBSCO: 2002-02-01 -  12 months embargo","CJDB140582","96-01-17","95-11-29","9344870","325.35","4068","001","  -  -  ","  -  -  ","   1YR 010196 FRM 01-96\us235.00";"96-12-10","96-07-11","9363393","354.67","10260","001","  -  -  ","  -  -  ","   1YR FRM 01-97\us260.00";"97-11-18","97-10-29","9384322","423.96","15413","001","  -  -  ","  -  -  ","   1YR FRM 01-98\us295.00";"98-11-18","98-10-28","9408589","499.02","21029","001","  -  -  ","  -  -  ","   27(01/99)-28(12/99)\us320.00";"99-11-17","99-03-11","9428844","573.29","26702","001","  -  -  ","  -  -  ","   28(01/00)-29(12/00)\us360.00";"01-02-01","00-02-11","9456652","658.30","33408","001","  -  -  ","  -  -  ","   29(01/01)-30(12/01)\us395.00";"01-12-11","01-10-25","9477480","743.91","39068","001","  -  -  ","  -  -  ","   30(01/02)-31(12/02)\us435.00";"02-12-06","02-11-02","9492886","718.26","45371","001","  -  -  ","  -  -  ","   31(01/03)-32(12/03)\us420.00";"04-01-23","03-11-21","9514562","636.86","51986","001","  -  -  ","  -  -  ","   32(01/04)-33(12/04)\us455.00";"04-03-03","04-02-13","S-64184","88.88","52701","001","  -  -  ","  -  -  ","   RE:9514562(+ONLINE 2004)\us61.35";"04-03-03","04-02-13","S-64184","140.99","52701","001","  -  -  ","  -  -  ","   RE:9492886(+ONLINE 2003)\us97.32";"05-01-21","04-12-02","9545350","728.91","57345","001","  -  -  ","  -  -  ","   33(01/05)-34(12/05)!X61818\us560.00";"05-05-19","05-03-13","0004154","-71.80","59646","001","  -  -  ","  -  -  ","   Re:9545350 online only ch\us-55.00";"05-12-20","05-11-04","9564042","691.75","63475","001","  -  -  ","  -  -  ","   34(01/06)-35(1\us 535.00";"07-01-19","06-11-08","9582797","719.46","69634","001","  -  -  ","  -  -  ","   35(01/07)-36(1\us 632.00";"07-02-08","06-12-13","S-16065","160.56","70376","001","  -  -  ","  -  -  ","   Re:9582797 r\us 126.40";"07-12-14","07-10-26","9603698","1018.51","75315","001","  -  -  ","  -  -  ","   36(01/08)-37(\us 1001.00"
"b52257046","o1228444","biolp","00243590","Limnology and oceanography. [electronic resource]","American Society of Limnology and Oceanography.","-","Available full text from SFU Library - SFU Library: 1998-01-01 (v.43) -";"Available full text from JSTOR - Life Sciences Collection - JSTOR: 1956-01-01 - 2004-12-31";"Available full text from JSTOR - Ecology & Botany Collection - JSTOR: 1956-01-01 - 2004-12-31";"Available full text from Biological & Agricultural Index Plus - Wilson: 2001-03-01 - 2004-09-30";"Available full text from JSTOR - Biological Sciences Collection - JSTOR: 1956-01-01 - 2004-12-31","CJDB152485","96-01-17","95-11-29","9344877","242.28","4085","001","  -  -  ","  -  -  ","    1YR 010196 FRM 01-96\us175.00";"96-12-10","96-07-11","9363400","238.72","10269","001","  -  -  ","  -  -  ","    1YR FRM 01-97\us175.00";"97-11-18","97-10-29","9384329","251.50","15421","001","  -  -  ","  -  -  ","    1YR FRM 01-98\us175.00";"98-11-18","98-10-28","9408596","27.29","21036","001","  -  -  ","  -  -  ","    43(01/99)-44(12/99)\us175.00";"98-11-25","98-10-28","9408596adj1","-27.29","21076","001","  -  -  ","  -  -  ","    43-44,1999\us-175.00";"98-12-02","98-10-28","9408596","272.91","21220","001","  -  -  ","  -  -  ","    43(01/99)-44(12/99)\us175.00";"99-11-17","99-03-11","9428851","557.37","26709","001","  -  -  ","  -  -  ","    44(01/00)-45(12/00)\us350.00";"01-02-01","00-02-11","9456660","583.30","33416","001","  -  -  ","  -  -  ","    45(01/01)-46(12/01)\us350.00";"01-12-11","01-10-25","9477487","615.64","39075","001","  -  -  ","  -  -  ","    46(01/02)-46(12/02)\us360.00";"02-12-06","02-11-02","9492893","680.64","45378","001","  -  -  ","  -  -  ","    48(01/03)-48(12/03)\us398.00";"04-01-23","03-11-21","9514568","594.88","51992","001","  -  -  ","  -  -  ","    49(01/04)-49(12/04)\us425.00";"05-01-21","04-12-02","9545358","592.23","57353","001","  -  -  ","  -  -  ","    50(01/05)-50(12/05)!X61731\us455.00";"06-01-12","05-11-04","9566075","1079.65","63705","001","  -  -  ","  -  -  "," 2006\us 835.00";"07-01-19","06-11-08","9582804","952.83","69641","001","  -  -  ","  -  -  "," 52(01/07)-52(1\us 837.00";"07-12-14","07-10-26","9603699","851.64","75316","001","  -  -  ","  -  -  "," 53(01/08)-53(1\us 837.00"
"b52266837","o1228493","psycp","15327752";"00223891","Journal of personality assessment. [electronic resource]","Lawrence Erlbaum Associates, Publishers, etc.]","-","Available full text from InformaWorld - Taylor and Francis - InformaWorld: 1997-01-01 (v.39 i.1) -";"Available full text from Business Source Complete (BSC) - EBSCO: 1975-02-01 -  12 months embargo";"Available full text from Biomedical Reference Collection: Comprehensive - EBSCO: 1975-02-01 -  12 months embargo","CJDB141135","96-01-17","95-11-29","9344874","346.12","4082","001","  -  -  ","  -  -  "," 1YR 010196 FRM 01-96\us250.00";"96-12-10","96-07-11","9363397","368.31","10266","001","  -  -  ","  -  -  "," 1YR FRM 01-97\us270.00";"97-11-18","97-10-29","9384326","431.15","15420","001","  -  -  ","  -  -  "," 1YR FRM 01-98\us300.00";"98-11-18","98-10-28","9408593","506.83","21033","001","  -  -  ","  -  -  "," (01/99)-(12/99)\us325.00";"99-11-17","99-03-11","9428848","573.29","26706","001","  -  -  ","  -  -  "," (01/00)-(12/00)\us360.00";"01-02-01","00-02-11","9456656","658.30","33412","001","  -  -  ","  -  -  "," (01/01)-(12/01)\us395.00";"01-12-11","01-10-25","9477484","726.82","39072","001","  -  -  ","  -  -  "," (01/02)-(12/02)\us425.00";"02-12-06","02-11-02","9492890","709.70","45375","001","  -  -  ","  -  -  "," 80(01/03)-81(12/03)\us415.00";"04-01-23","03-11-21","9514566","615.86","51990","001","  -  -  ","  -  -  "," 82(01/04)-83(12/04)\us440.00";"04-03-03","04-02-13","S-64184","118.76","52701","001","  -  -  ","  -  -  "," RE:9492890(+ONLINE 2003)\us81.98";"04-03-03","04-02-13","S-64184","81.53","52701","001","  -  -  ","  -  -  "," RE:9514566(+ONLINE 2004)\us56.28";"04-08-12","04-06-13","005990","-34.07","55612","001","  -  -  ","  -  -  "," re:9492890 rate adj \us-25.62";"05-01-21","04-12-02","9545354","657.32","57349","001","  -  -  ","  -  -  "," 84(01/05)-85(12/05)!X61819\us505.00";"05-05-19","05-03-13","0004154","-65.27","59646","001","  -  -  ","  -  -  "," Re:9545354 online only ch\us-50.00";"05-12-20","05-11-04","9564047","620.63","63480","001","  -  -  ","  -  -  "," 86(01/06)-87(1\us 480.00";"07-01-19","06-11-08","9582801","594.24","69638","001","  -  -  ","  -  -  "," 88(01/07)-89(1\us 522.00";"07-02-08","06-12-13","S-16065","132.62","70376","001","  -  -  ","  -  -  "," Re:9582801 r\us 104.40";"07-12-14","07-10-26","9603699","598.29","75316","001","  -  -  ","  -  -  "," 90(01/08)-91(1\us 588.00"
"b52268718","o1229953","geogp","14350661";"03615995","Journal / Soil Science Society of America. [electronic resource]","Soil Science Society of America.","-","Available full text from Highwire - Highwire Press: 1921-01-01 -";"Available full text from Highwire - Free - Highwire: 1999-07-01 -  18 months embargo","CJDB146113","96-01-17","95-11-29","9344889","161.99","4138","001","  -  -  ","  -  -  ","         1YR 010196 FRM 01-96\us117.00";"96-12-10","96-07-11","9363414","186.89","10283","001","  -  -  ","  -  -  ","         1YR FRM 01-97\us137.00";"97-11-18","97-10-29","9384342","280.25","15435","001","  -  -  ","  -  -  ","         1YR FRM 01-98\us195.00";"98-11-18","98-10-28","9408610","335.28","21050","001","  -  -  ","  -  -  ","         63(01/99)-63(12/99)\us215.00";"99-02-25","99-02-13","S-44519","15.59","22538","001","  -  -  ","  -  -  ","         1999 RATE INC RE:9408610\us10.26";"99-11-17","99-03-11","9428864","342.39","26722","001","  -  -  ","  -  -  ","         63(01/00)-64(12/00)\us215.00";"01-02-01","00-02-11","9456673","411.65","33429","001","  -  -  ","  -  -  ","         65(01/01)-65(12/01)\us247.00";"01-06-28","01-06-13","S-70674","41.84","36108","001","  -  -  ","  -  -  ","         ONLINE ACCESS RE 9456673\us25.10";"01-12-11","01-10-25","9477500","422.41","39088","001","  -  -  ","  -  -  ","         65(01/02)-65(12/02)\us247.00";"02-04-25","02-04-13","S-64967","43.57","41675","001","  -  -  ","  -  -  ","         UPGD FOR ONLINE RE:9477500\us25.00";"02-12-06","02-11-02","9492906","465.16","45391","001","  -  -  ","  -  -  ","         67(01/03)-67(12/03)\us272.00";"04-01-23","03-11-21","9514580","923.80","52004","001","  -  -  ","  -  -  ","         68(01/04)-68(12/04)\us660.00";"05-01-21","04-12-02","9545376","859.06","57371","001","  -  -  ","  -  -  ","         69(01/05)-69(12/05)!X61726\us660.00";"05-12-20","05-11-04","9564068","795.19","63525","001","  -  -  ","  -  -  ","      70(01/06)-70(1\us 615.00";"06-11-22","06-11-03","12893","-72.37","68756","001","  -  -  ","  -  -  ","  Re:9545376 online only \us -60.00";"07-01-19","06-11-08","9582819","711.49","69657","001","  -  -  ","  -  -  "," 71(01/07)-71(1\us 625.00";"07-12-14","07-10-26","9603700","646.11","75317","001","  -  -  ","  -  -  "," 72(01/08)-72(1\us 635.00"
"b5127694x","o1230128","athlp","00397431","Swimming world. [electronic resource]","Swimming World and Junior Swimmer,","-","Available full text from SFU Library - SFU Library: 1960-01-01 -","CJDB149780","96-01-17","95-11-29","9344890","29.77","4139","001","  -  -  ","  -  -  ","          1YR 010196 FRM 01-96\us21.50";"96-12-10","96-07-11","9363415","40.86","10284","001","  -  -  ","  -  -  ","          1YR FRM 01-97\us29.95";"97-11-18","97-10-29","9384343","43.05","15436","001","  -  -  ","  -  -  ","          1YR FRM 01-98\us29.95";"98-11-18","98-10-28","9408611","46.71","21051","001","  -  -  ","  -  -  ","          39(01/99)-40(12/99)\us29.95";"99-11-17","99-03-11","9428866","47.69","26724","001","  -  -  ","  -  -  ","          40(01/00)-41(12/00)\us29.95";"01-02-01","00-02-11","9456675","49.91","33431","001","  -  -  ","  -  -  ","          42(01/01)-42(12/01)\us29.95";"01-12-11","01-10-25","9477501","51.21","39089","001","  -  -  ","  -  -  ","          42(01/02)-43(12/02)\us29.95";"02-12-06","02-11-02","9492907","51.21","45392","001","  -  -  ","  -  -  ","          44(01/03)-44(12/03)\us29.95";"04-01-23","03-11-21","9514581","41.92","52005","001","  -  -  ","  -  -  ","          45(01/04)-45(12/04)\us29.95";"05-01-21","04-12-02","9545378","38.98","57373","001","  -  -  ","  -  -  ","          46(01/05)-46(12/05)!X619928\us29.95";"05-12-20","05-11-04","9564070","33.55","63527","001","  -  -  ","  -  -  ","         (01/06)-(12/06)\us 25.95";"07-01-19","06-11-08","9582820","91.01","69658","001","  -  -  ","  -  -  ","    (01/07)-(12/07)\us 79.95";"07-12-14","07-10-26","9603700","91.52","75317","001","  -  -  ","  -  -  ","   (01/08)-(12/08)\us 89.95"
"b52302702","o1827352","glibp","12019364","CM : Canadian review of materials. [electronic resource]","","-","Available full text from CBCA Complete - Proquest: 1999-01-01 -";"Available full text from Open Access Journals - Simon Fraser University: 1995-01-01 (v.1) -","CJDB157285","97-05-28","97-05-15","9384528","45.75","12932","001","  -  -  ","  -  -  ","  1997";"97-11-18","97-10-29","9384355","27.23","15454","001","  -  -  ","  -  -  ","  1YR FRM 01-98";"98-12-02","98-11-12","9408622","27.21","21228","001","  -  -  ","  -  -  ","  (01/99)-(12/99)";"99-11-18","99-03-11","9428879","27.21","26737","001","  -  -  ","  -  -  ","  (01/00)-(12/00)";"01-01-24","00-02-11","9456695","27.21","33237","001","  -  -  ","  -  -  ","  (01/01)-(12/01)";"01-11-28","01-10-25","9477521","27.25","38641","001","  -  -  ","  -  -  ","  (01/02)-(12/02)";"02-12-10","02-11-02","9492930","27.15","45422","001","  -  -  ","  -  -  ","  (01/03)-(12/03)";"03-11-26","03-10-29","9514613","27.23","51179","001","  -  -  ","  -  -  ","  (01/04)-(12/04)";"05-01-18","04-12-02","9545434","27.18","57245","001","  -  -  ","  -  -  ","  (01/05)-(12/05)!X6165176";"05-12-16","05-11-02","9564099","26.84","63411","001","  -  -  ","  -  -  ","  (01/06)-(12/06)!Y2054670";"07-01-18","06-11-08","9582883","26.63","69551","001","  -  -  ","  -  -  ","  (01/07)-(12/07)!A3294551";"08-01-15","07-11-09","9603807","26.67","75561","001","  -  -  ","  -  -  "," (01/08)-(12/08)!C0481469"
"b51983084","o2126266","lingp","07427778","CALICO journal. [electronic resource]","CALICO,","-","Available full text from SFU Library - SFU Library: 1983-09-01 (v.1 i.1) -","CJDB169881","98-11-18","98-10-28","9408573","124.76","21014","001","  -  -  ","  -  -  ","       15(09/98)-17(08/99)\us80.00";"99-11-17","99-03-11","9428828","111.48","26686","001","  -  -  ","  -  -  ","       16(09/99)-17(08/00)\us70.00";"01-02-01","00-02-11","9456636","116.66","33392","001","  -  -  ","  -  -  ","       17(09/00)-18(08/01)\us70.00";"01-12-11","01-10-25","9477463","119.71","39052","001","  -  -  ","  -  -  ","       18(09/01)-19(08/02)\us70.00";"02-12-06","02-11-02","9492872","136.81","45354","001","  -  -  ","  -  -  ","       20(09/02)-20(08/03)\us80.00";"04-01-23","03-11-21","9514549","111.97","51973","001","  -  -  ","  -  -  ","       21(09/03)-21(08/04)\us80.00";"05-01-21","04-12-02","9545327","104.16","57322","001","  -  -  ","  -  -  ","       22(09/04)-22(08/05)!X617645\us80.00";"05-12-16","05-11-04","9564020","122.83","63428","001","  -  -  ","  -  -  ","       23(09/05)-23(08/06)\us 95.00";"07-01-19","06-11-08","9582780","110.42","69617","001","  -  -  ","  -  -  ","       24(09/06)-24(08/07)\us 97.00";"07-11-08","07-10-19","9609202","104.58","74741","001","  -  -  ","  -  -  ","  25(09/07)-25(08/08)\us 97.00";"08-05-06","08-04-04","9613701","105.64","77603","001","  -  -  ","  -  -  "," 26(09/08)-26(08/09)\us 97.00"
"b52266783","o2546826","psycp","15327078";"15250008","Infancy : the official journal of the International Society on Infant Studies. [electronic resource]","Lawrence Erlbaum Associates,","-","Available full text from InformaWorld - Taylor and Francis - InformaWorld: 1997-01-01 (v.1 i.1) -","CJDB141115","01-02-01","00-02-11","9456649","324.99","33405","001","  -  -  ","  -  -  "," 2(01/01)-2(12/01)\us195.00";"01-12-11","01-10-25","9477476","418.99","39064","001","  -  -  ","  -  -  "," 3(01/02)-3(12/02)\us245.00";"02-12-06","02-11-02","9492883","436.08","45365","001","  -  -  ","  -  -  "," 4(01/03)-4(12/03)\us255.00";"04-01-23","03-11-21","9514559","755.84","51983","001","  -  -  ","  -  -  "," 5(01/04)-6(12/04)\us540.00";"04-03-03","04-02-13","S-64184","535.29","52701","001","  -  -  ","  -  -  "," RE:9492883(+ONLINE 2003)\us369.49";"04-03-03","04-02-13","S-64184","103.33","52701","001","  -  -  ","  -  -  "," RE:9514559(+ONLINE 2004)\us71.32";"04-08-12","04-06-13","005990","-436.05","55612","001","  -  -  ","  -  -  "," re:9492883 rate adj \us-327.86";"05-01-21","04-12-02","9545344","780.97","57339","001","  -  -  ","  -  -  "," 7(01/05)-8(12/05)!X6181857\us600.00";"05-05-19","05-03-13","0004154","-78.32","59646","001","  -  -  ","  -  -  "," Re:9545344 online only ch\us-60.00";"05-12-16","05-11-04","9564036","743.49","63444","001","  -  -  ","  -  -  "," 8(01/06)-8(12/\us 575.00";"07-01-19","06-11-08","9582793","719.46","69630","001","  -  -  ","  -  -  "," 9(01/07)-9(12/\us 632.00";"07-02-08","06-12-13","S-16065","160.56","70376","001","  -  -  ","  -  -  "," Re:9582793 r\us 126.40";"07-12-14","07-10-26","9603698","689.86","75315","001","  -  -  ","  -  -  "," 13(01/08)-14(1\us 678.00"
"b52266801","o2546863","psycp","15327647";"15248372","Journal of cognition and development : official journal of the Cognitive Development Society. [electronic resource]","Lawrence Erlbaum Associates,","-","Available full text from InformaWorld - Taylor and Francis - InformaWorld: 1997-01-01 (v.1 i.1) -","CJDB141124","01-02-01","00-02-11","9456653","299.99","33409","001","  -  -  ","  -  -  ","  2(01/01)-2(12/01)\us180.00";"01-12-11","01-10-25","9477480","376.23","39068","001","  -  -  ","  -  -  ","  3(01/02)-3(12/02)\us220.00";"02-12-06","02-11-02","9492886","393.33","45371","001","  -  -  ","  -  -  ","  4(01/03)-4(12/03)\us230.00";"04-01-23","03-11-21","9514562","426.91","51986","001","  -  -  ","  -  -  ","  5(01/04)-5(12/04)\us305.00";"04-03-03","04-02-13","S-64184","174.19","52701","001","  -  -  ","  -  -  ","  RE:9492886(+ONLINE 2003)\us120.23";"04-03-03","04-02-13","S-64184","59.92","52701","001","  -  -  ","  -  -  ","  RE:9514562(+ONLINE 2004)\us41.36";"04-08-12","04-06-13","005990","-104.29","55612","001","  -  -  ","  -  -  ","  re:9492886 rate adj \us-78.41";"05-01-21","04-12-02","9545350","468.57","57345","001","  -  -  ","  -  -  ","  6(01/05)-6(12/05)!X6181894\us360.00";"05-05-19","05-03-13","0004154","-45.69","59646","001","  -  -  ","  -  -  ","  Re:9545350 online only ch\us-35.00";"05-12-20","05-11-04","9564042","452.55","63475","001","  -  -  ","  -  -  ","  7(01/06)-7(12/\us 350.00";"07-01-19","06-11-08","9582797","463.32","69634","001","  -  -  ","  -  -  "," 8(01/07)-8(12/\us 407.00";"07-02-08","06-12-13","S-84180","103.40","70377","001","  -  -  ","  -  -  "," Re:9582797 r\us 81.40";"07-12-14","07-10-26","9603698","460.92","75315","001","  -  -  ","  -  -  "," 9(01/08)-9(12/\us 453.00"
