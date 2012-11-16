# Load ERM data from a CSV file

use lib 'lib';
use strict;

use Data::Dumper;

use Getopt::Long;
use CUFTS::Util::CSVParse;
use CUFTS::Util::Simple;
use Text::CSV_XS;
use CUFTS::Schema;

my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i' );
my @files = @ARGV;


my $schema = CUFTS::Schema->connect( 'dbi:Pg:dbname=CUFTS3-test', 'tholbroo', '' );

my $site;
if ($options{site_id}) {
    $site = $schema->resultset('Sites')->find( { id => $options{site_id} } );
}
elsif ( $options{site_key} ) {
    $site = $schema->resultset('Sites')->find( { key => $options{site_key} } );
}
else {
    die("A site must be specified either through a site_id or site_key parameter.");
}

if ( !defined($site) ) {
    die("Unable to find site.");
}

foreach my $file ( @files ) {
    open my $fh, "<", $file or die "Error opening CSV file: $!";
    my $csv = Text::CSV_XS->new({binary => 1});

    # Get field headings

    my $fields = $csv->getline($fh);
    
    RECORD:
    while ( my $data = $csv->getline($fh) ) {

        my %record_data;
        my $record;

        foreach my $field ( @$fields ) {

            my $data = shift(@$data);
            next if is_empty_string($data);


            if ( $field eq 'id' ) {
                if ( !defined($record) ) {
                    $record = $schema->resultset('ERMMain')->find({ id => $data, site_id => $site->id });
                    if ( defined($record) ) {
                        print("Found existing record by id: $data\n");
                    }
                    else {
                        print("A record id was found, but a matching record could not be found, skipping: $data\n");
                        next RECORD;
                    }
                }
            }

            elsif ( $field eq 'subjects' ) {
#                $record_data{$field} = split(',', $data);
            }
            elsif ( $field eq 'content_types' ) {
#                $record_data{$field} = split(',', $data);
            }
            elsif ( $field eq 'consortia' ) {
            }
            elsif ( $field eq 'pricing_model' ) {
#                $record_data{$field} = { pricing_model => $data, site_id => $site_id };
            }
            elsif ( $field eq 'provider' ) {
            }
            elsif ( $field eq 'resource_type' ) {
                my $rt = $schema->resultset('ERMResourceTypes')->find({ site => $site->id, resource_type => $data });
                if ( defined($rt) ) {
                    $record_data{$field} = $rt->id;
                }
                else {
                    print("Resource type in list could not be matched to a resource type for this site: $data\n");
                    next;
                }
            }
            elsif ( $field eq 'resource_medium' ) {
#                $record_data{$field} = { resource_medium => $data, site_id => $site_id };
            }
            else {
                # Normal field, just add to erm_main
                $record_data{$field} = $data;
            }

        }

        warn(Dumper(\%record_data));
        if ( defined($record) ) {
            $schema->txn_do( sub { update_record($site->id, $record, \%record_data) } );
        }
        else {
            if ( defined($record_data{key}) ) {
                $schema->txn_do( sub { create_record($site->id, \%record_data) } );
            }
            else {
                print("A new resource was found, however the required key field was blank.\n");
            }
        }
    
    }

    close($fh);    
}


sub create_record {
    my ( $site_id, $record_data ) = @_;

    # Check whether a record with this key is loaded already, and skip it if so

    if ( defined($record_data->{key}) && $schema->resultset('ERMMain')->find({ key => $record_data->{key}, site => $site_id }) ) {
        die("Record with key already exists, skipping: $record_data->{key}\n");
        return;
    }

    $record_data->{site} = $site_id;
    $schema->resultset('ERMMain')->create($record_data);
}

sub update_record {
    my ( $site_id, $record, $record_data ) = @_;

    $record->update($record_data);
}

