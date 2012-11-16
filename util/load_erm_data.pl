# Load ERM data from a CSV file

use lib 'lib';
use strict;

use Data::Dumper;

use CUFTS::Util::CSVParse;
use CUFTS::Util::Simple;
use Text::CSV_XS;
use CUFTS::Schema;
use String::Util qw(trim);

my $site_id = 1;  # YCLIB, using as a test site

open my $fh, "<", $ARGV[0] or die "Error opening CSV file: $!";

my $schema = CUFTS::Schema->connect( 'dbi:Pg:dbname=CUFTS3', 'tholbroo', '' );

#my $csv = CUFTS::Util::CSVParse->new();
my $csv = Text::CSV_XS->new({ binary => 1, sep_char => "\t" });

# Get field headings

my $fields = $csv->getline($fh);


# Parse rows

while ( my $data = $csv->getline($fh) ) {
    
    my %main_data = (
        site => $site_id,
    );
    
    foreach my $field ( @$fields ) {
        my $data = trim(shift(@$data));
        next if is_empty_string($data);
        
        if ( $field eq 'id' ) {
            next;
        }
        elsif ( $field eq 'content_types' ) {
            $main_data{$field} = split(',', $data);
        }
        elsif ( $field eq 'consortia' ) {
        }
        elsif ( $field eq 'subjects' ) {
            $main_data{$field} = split(',', $data);
        }
        elsif ( $field eq 'pricing_model' ) {
            $main_data{$field} = { pricing_model => $data, site => $site_id };
        }
        elsif ( $field eq 'provider' ) {
        }
        elsif ( $field eq 'resource_type' ) {
            $main_data{$field} = { resource_type => $data, site => $site_id };
        }
        elsif ( $field eq 'resource_medium' ) {
            $main_data{$field} = { resource_medium => $data, site => $site_id };
        }
        elsif ( $field eq 'open_access' ) {
            if ( $data =~ /^[yt]/i ) {
                $main_data{$field} = 'true';
            }
            else {
                $main_data{$field} = 'false';
            }
        }
        else {
            # Normal field, just add to erm_main
            $main_data{$field} = $data;
        }
    }
    
    warn(Dumper(\%main_data));
    
    $schema->txn_do( sub {
            if ( $schema->resultset('ERMMain')->find({ key => $main_data{key}, site => $site_id }) ) {
                die("Record with key already exists, skipping: $main_data{key}\n");
                return;
            }

            my $erm_main = $schema->resultset('ERMMain')->create(\%main_data);
            $erm_main->main_name($main_data{key});
    } );
}




close($fh);