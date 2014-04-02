# Create a set of fake clickthrough data for testing.

use lib 'lib';
use strict;

use Data::Dumper;

use CUFTS::DB::ERMMain;
use CUFTS::DB::ERMCosts;

my @field_names = qw(
    other_num
    bib_num
    order_num
    issn
    title
    imprint
);

my @remainder_field_names = qw(
    paid_date
    invoice_date
    invoice_num
    amount_paid
    voucher
    copies
    note
);

my $row = <>;

while ($row = <>) {
    chomp($row);
    my $record = parse_row($row);
    
    print Dumper($record);
    
    # Pretty print record
    
    print "\n--------\n";
    print join( '   ', map { $record->{$_} } ( qw( order_num record_num other_num ) ) );
    print "\n";
    print $record->{title}, "  ", join( ', ', map { substr($_, 0, 4) . '-' . substr($_, 4, 4) } @{ $record->{issns} } );
    print "\n";
    foreach my $payment ( sort { $b->{end_date} cmp $a->{end_date} } @{ $record->{payments} } ) {
        print "   ", $payment->{start_date}, ' - ', $payment->{end_date};
        printf( "%8i", $payment->{voucher} );
        printf( "   \$ %9.2f  %3s \$ %9.2f", $payment->{amount_paid}, $payment->{currency_billed}, $payment->{amount_billed} );
        print "  ($payment->{references})" if exists $payment->{references};
        print "\n";
    }
    
}



# Returns a record.  Yes, this is very ugly because of the bizarre III format.  See the END section for examples
sub parse_row {
    my ($row) = @_;
    # print $row;
    
    my %record;
    
    # $record{other_num}  = get_comma_field( \$row, 'other_num' );
    $record{record_num} = get_comma_field( \$row, 'record_num' );
    $record{order_num}  = get_comma_field( \$row, 'order_num' );

    $record{title}   = get_comma_field( \$row, 'title' );
    $record{imprint} = get_comma_field( \$row, 'imprint' );
    $record{currency}   = get_comma_field( \$row, 'currency' );

    $record{payments} = [];

    if ( $row !~ /^""/ ) {
        my %references;
        my @payments = split /";/, $row;
        foreach my $payment ( @payments ) {
            my %payment_record;

            # print($payment);
            
            $payment_record{paid_date}     = get_comma_field( \$payment, 'paid_date' );
            $payment_record{invoice_date}  = get_comma_field( \$payment, 'invoice_date' );
            $payment_record{invoice_num}   = get_comma_field( \$payment, 'invoice_num' );
            $payment_record{amount_paid}   = get_comma_field( \$payment, 'amount_paid' );
            $payment_record{voucher}       = get_comma_field( \$payment, 'voucher' );
            $payment_record{copies}        = get_comma_field( \$payment, 'copies' );

            $payment =~ s/^[",]\s*//;
            $payment =~ s/\s*[",]$//;
            $payment_record{note} = $payment;

            # Parse the price and currency
            
            if ( $payment =~ / \\ ([a-zA-Z]{2,3}) \s* ([-.\d]+) $/xsm ) {
                $payment_record{currency_billed} = $1;
                $payment_record{amount_billed} = $2;
            }

            # Try to parse a date out
            
            # 1YR 010196 FRM 01-96
            if ( $payment =~ m# 1YR \s* \d* \s* FRM \s* (\d{2})-(\d{2}) #xsmi ) {
                my $month = $1;
                my $year = int($2) + ( int($2) > 60 ? 1900 : 2000 );
                $payment_record{start_date} = sprintf( "%04i-%02i-01", $year,     $month );
                $payment_record{end_date}   = sprintf( "%04i-%02i-01", $year + 1, $month );
            }

            # 74(01/99)-75(12/99)
            elsif ( $payment =~ m# \( (\d{2}) / (\d{2}) \) .* - .*  \( (\d{2}) / (\d{2}) \) #xsmi ) {
                my $start_month = $1;
                my $start_year = int($2) + ( int($2) > 60 ? 1900 : 2000 );
                my $end_month = $1;
                my $end_year = int($2) + ( int($2) > 60 ? 1900 : 2000 );
                $payment_record{start_date} = sprintf( "%04i-%02i-01", $start_year,   $start_month );
                $payment_record{end_date}   = sprintf( "%04i-%02i-01", $end_year + 1, $end_month );
            }
            
            # sept 1/98 - oct 31/99
            elsif ( $payment =~ m# (\w{3,4}) \s* (\d{1,2}) \s* / \s* (\d{2}) [-&] (\w{3,4}) \s* (\d{1,2}) \s* / \s* (\d{2}) #xsm ) {
                my $start_month = format_month( $1 );
                my $start_day   = $2;
                my $start_year  = int($3) + ( int($3) > 60 ? 1900 : 2000 );
                my $end_month   = format_month( $4 );
                my $end_day     = $5;
                my $end_year    = int($6) + ( int($6) > 60 ? 1900 : 2000 );
                
                $payment_record{start_date} = sprintf( "%04i-%02i-%02i", $start_year, $start_month, $start_day );
                $payment_record{end_date}   = sprintf( "%04i-%02i-%02i", $end_year,   $end_month, $end_day );
            } 
            # sep/09 - sep/00
            elsif ( $payment =~ m# (\w{3,4}) / (\d{2}) [-&] (\w{3,4}) / (\d{2}) #xsm ) {
                my $start_month = format_month( $1 );
                my $start_year  = int($2) + ( int($2) > 60 ? 1900 : 2000 );
                my $end_month   = format_month( $3 );
                my $end_year    = int($4) + ( int($4) > 60 ? 1900 : 2000 );
                
                $payment_record{start_date} = sprintf( "%04i-%02i-01", $start_year, $start_month );
                $payment_record{end_date}   = sprintf( "%04i-%02i-01", $end_year,   $end_month );
            }
            # 02/09 - 02/00
            elsif ( $payment =~ m# (\d{2}) / (\d{2}) [-&] (\d{2}) / (\d{2}) #xsm ) {
                my $start_month = $1;
                my $start_year  = int($2) + ( int($2) > 60 ? 1900 : 2000 );
                my $end_month   = $3;
                my $end_year    = int($4) + ( int($4) > 60 ? 1900 : 2000 );
                
                $payment_record{start_date} = sprintf( "%04i-%02i-01", $start_year, $start_month );
                $payment_record{end_date}   = sprintf( "%04i-%02i-01", $end_year,   $end_month );
            }
            # re:23423
            elsif ( $payment =~ / re: \s* (o?\d+) /ixsm ) {   # Try for a reference number
                $payment_record{references} = $1;
                
                if ( exists $references{ $payment_record{references} } ) {
                    $payment_record{start_date} = $references{ $payment_record{references} }->{start_date};
                    $payment_record{end_date}   = $references{ $payment_record{references} }->{end_date};                 
                }
                else {  # Default to previous record if it exists
                    if ( scalar(@{ $record{payments} }) ) {
                        $payment_record{start_date} = $record{payments}->[ $#{ $record{payments} } ]->{start_date};
                        $payment_record{end_date}   = $record{payments}->[ $#{ $record{payments} } ]->{end_date};
                    }
                }
                
            }
            # 1998
            elsif ( $payment =~ / ((?:19|20)\d{2}) /xsm ) {  # Last ditch for a single year
                $payment_record{start_date} = sprintf( "%04i-01-01", $1 );
                $payment_record{end_date}   = sprintf( "%04i-12-31", $1 );
            }

            $references{ $payment_record{voucher} }->{start_date} = $payment_record{start_date};
            $references{ $payment_record{voucher} }->{end_date}   = $payment_record{end_date};
            
            push @{ $record{payments} }, \%payment_record;
        }
    }

    return \%record;
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
        CUFTS::Exception::App->throw("Unable to find month match: $month");
    }

}

sub get_end_day {
    my $month = int(shift);
    if ( $month > 0 && $month < 13 ) {
        return ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 )[$month - 1];
    }
    return 1;  # Safe default
}

__END__

"OTHER #","RECORD #(BIBLIO)","RECORD #(ORDER)","ISBN/ISSN","TITLE","IMPRINT","Paid Date","Invoice Date","Invoice Num","Amount Paid","Voucher Num","Copies","Note"
"e312","b14147634","o137929x","26638031","ABI/INFORM [electronic resource]. --","Ann Arbor, Mich. : University Microfilms,",""
"CJDB254214","b52071005","o4591471","1749-4885";"1749-4893","Nature Photonics [electronic resource]","","08-01-17","08-01-17","108736EI-rev","2575.00","75671","001","    Sep/07-Aug/08\us 2500.00"
"e260","b31760077","o3077676","","MLA international bibliography [electronic resource].","[Ipswich, Mass.] : EBSCO Pub.","02-12-05","02-11-26","2055","1687.75","45308","001"," SEPT 1/03-OCT 31/03[UNLI\us1075.00";"03-05-08","03-04-01","2280","1717.60","47723","001"," NOV/03-OCT/04\us1130.00";"04-02-26","04-02-09","2785","7115.34","52616","001"," NOV/03-OCT/04:ADD'L CHG\us5349.88";"04-03-24","04-03-16","3003","8458.80","53126","001"," NOV/04-OCT/05\us6360.00";"05-02-24","05-02-15","3583","600.54","58206","001"," Nov/04-Oct/05 add'l chg\us508.93";"05-03-23","05-03-21","4003","7759.20","58972","001"," Nov/05-Oct/06\us6360.00";"06-03-08","06-02-20","4657","997.53","64655","001"," Nov/05-Oct/06:\us 852.59";"06-03-23","06-03-13","5035","8424.00","65343","001"," Nov/06-Oct/07\us 7200.00";"06-04-07","06-03-13","5035adj1","-8424.00","65505","001"," Adj.Re:65343\us -7200.00";"06-04-27","06-03-13","5035adj2","8424.00","65682","001"," Nov/06-Oct/07\us 7200.00";"07-03-13","07-02-12","5656","271.89","71084","001"," Adj.re:65682\us 228.48";"07-05-02","07-04-01","6028","8642.00","71974","001"," Nov/07-Oct/08\us 7450.00"
"CJDB141186","b5233157x","o3159309","14764687";"00280836","Nature. -- [electronic resource]","[London, etc. : Macmillan Journals ltd.]","03-05-08","03-04-01","2280","5350.40","47723","001","         SEP/03-AUG/04\us3520.00";"04-02-26","04-02-09","2785","1356.60","52616","001","         SEP/03-AUG/04:ADD'L CHG\us1020.00";"04-03-24","04-03-16","3003","6277.60","53126","001","         SEP/04-AUG/05\us4720.00";"05-02-24","05-02-15","3583","-797.48","58206","001","         Sep/04-Aug/05 adj\us-675.83";"05-03-23","05-03-21","4003","5856.00","58972","001","         Sep 1/05-Aug 31/06\us4800.00";"06-03-08","06-02-20","4657","244.57","64655","001","        Sep/05-Aug/06:\us 209.03";"06-03-23","06-03-13","5035","5850.00","65343","001","        Sep/06-Aug/07\us 5000.00";"06-04-07","06-03-13","5035adj1","-5850.00","65505","001","        Adj.Re:65343\us -5000.00";"06-04-27","06-03-13","5035adj2","5850.00","65682","001","        Sep/06-Aug/07\us 5000.00";"07-03-13","07-02-12","5656","309.02","71084","001","     Adj.re:65682\us 259.68";"07-05-02","07-04-01","6028","6148.00","71974","001","   Sep/07-Aug/08\us 5300.00";"07-09-28","07-09-20","6398","173.25","74196","001","  Re:6028:add'l chg \us 165.00"
"e858","b47179247","o401666x","","Ebrary Canadian Public Policy Collection. [electronic resource] order record.","Saint-Lazare, QC : Gary Library Communications,","06-02-09","06-01-27","00000258","5136.00","64124","001","   2005& 2006:unlimited use";"06-11-22","06-11-07","364","3593.40","68794","001","2007\us 3000.00";"07-12-13","07-11-26","538","2810.33","75236","001","2008\us 2625.00"
"e621","b26861896","o4541108","","Books24x7","Toronto, On. : Micromedia","07-10-04","07-08-27","505696A","36204.78","74296","001","  Aug/07-Sep/08:5 user\us 32529.00";"07-10-04","07-08-27","505696A","-6739.97","74296","001"," Re:o3298243 \us -6419.02"






Bad Data in example records:

v.29-30,09/03-\us 484.00
31(01/06)-31(1\us 332.00