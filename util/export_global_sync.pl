#!/usr/local/bin/perl

##
## This script checks exports a global sync file for a specified site
##

use lib qw(lib);

use HTML::Entities;
use Date::Calc qw();
use String::Util qw(trim hascontent);
use Getopt::Long;

use CUFTS::Exceptions;
use CUFTS::Config;
use CUFTS::Util::Simple;

use CUFTS::ResourcesLoader;

use strict;

my $output_dir = '/tmp/global_export' ;

my %options;
GetOptions( \%options, 'site_key=s', 'site_id=i', 'timestamp=s', 'resource_keys=s', 'prev_days=i', 'output_dir=s', 'exact=s' );

my $prev_days        = $options{prev_days};
my $force_output_dir = $options{output_dir};
my $after_timestamp  = $options{timestamp};
my $resource_keys    = $options{resource_keys};
my $exact_timestamp  = $options{exact};

# Try to find a business week day at least $prev_days in the past

if ( defined $prev_days ) {

    my @dc = Date::Calc::Today();
	while ( $prev_days > 0 || Date::Calc::Day_of_Week(@dc) > 5 ) {
	    if ( Date::Calc::Day_of_Week(@dc) <= 5 ) {
	    	$prev_days--;
	    }
	    @dc = Date::Calc::Add_Delta_Days( @dc, -1 );
	}
    $exact_timestamp = sprintf( "%4i%02i%02i", @dc );
    print "Matching timestamp: $exact_timestamp\n";
}
elsif ( defined $after_timestamp ) {

    if ( $after_timestamp =~ / (\d{4}) - (\d{2}) - (\d{2}) /xsm ) {
        $after_timestamp = "$1$2$3";
        print "Checking for title updates after: $after_timestamp\n";
    }
    else {
        die("Timestamp does not match YYYY-MM-DD format: $after_timestamp");
    }

}
elsif ( defined $exact_timestamp ) {
    if ( $exact_timestamp =~ / (\d{4}) - (\d{2}) - (\d{2}) /xsm ) {
        $exact_timestamp = "$1$2$3";
        print "Checking for title updates on: $exact_timestamp\n";
    }
    else {
        die("Timestamp does not match YYYY-MM-DD format: $exact_timestamp");
    }
}

my @resource_keys;
if ( defined $resource_keys ) {
    @resource_keys = split /,/, $resource_keys;
}

export();

sub export {

    my $schema = CUFTS::Config::get_schema();

    my $site;
    if ( $options{site_id} ) {
        $site = $schema->resultset('Sites')->find({ id => int($options{site_id}) }) or
            die("Could not find site: " . $options{site_id});
    }
    elsif ( $options{site_key} ) {
        $site = $schema->resultset('Sites')->find({ key => $options{site_key} }) or
            die("Could not find site: " . $options{site_key});
    }
    else {
        usage();
        exit;
    }

    my $site_id = $site->id;

    my $timestamp = get_timestamp();
    if ( defined $force_output_dir ) {
        $output_dir = $force_output_dir;
    }
    else {
        $output_dir .= '_' . $timestamp;
    }

    mkdir ${output_dir} or
        die("Unable to create output dir: $!");

    my $local_resources_rs = $site->local_resources({
        active   => 't',
        resource => { '!=' => undef }
    });

    my $resource_xml;

RESOURCE:

    while ( my $local_resource = $local_resources_rs->next ) {
        my $resource = $local_resource->global_resource;

        print "Checking: ", $resource->name, "\n";

        if ( !$resource->do_module('has_title_list') ) {
            print "Resource does not use title lists, skipping.\n";
            next RESOURCE;
        }

        if ( defined $after_timestamp || defined $exact_timestamp ) {
            my $scanned = $resource->title_list_scanned;
            if ( $scanned =~ /^ (\d{4}) - (\d{2}) - (\d{2}) /xsm ) {
                $scanned = "$1$2$3";
            }
            else {
                print "Unable to match date in timestamp: " . $resource->title_list_scanned . "\n";
                next RESOURCE;
            }

            if ( defined($after_timestamp) && $scanned >= $after_timestamp ) {
                print "Updated after timestamp check date.\n";
            }
            elsif ( defined($exact_timestamp) && $scanned == $exact_timestamp ) {
                print "Updated on exact timestamp date.\n";
            }
            else {
                print "Not updated within timestamp range: $scanned\n";
                next RESOURCE;
            }

        }

        ##
        ## Check for a global export key.  Resources without a key will not be
        ## exported since they can't be matched reliably with a remote install.
        ##


        my $key = $resource->key;
        if ( !defined $key ) {
            print "No key defined, skipping resource.\n";
            next RESOURCE;
        }
        if ( $key =~ / [^a-zA-Z_0-9] /xsm ) {
            print "Invalid characters detected in key ($key), skipping resource.\n";
            next RESOURCE;
        }

        ##
        ## Skip if this record does not match a supplied resource key
        ##

        if ( scalar @resource_keys && !grep { $key eq $_ } @resource_keys ) {
            print "Key does not match requested resource keys.\n";
            next RESOURCE;
        }

        ##
        ## Create titles export file
        ##

        my $columns = $resource->do_module( 'title_list_fields' );
        next RESOURCE if !defined($columns);

        open OUTPUT, ">$output_dir/$key" or
            die "Unable to create output file: $!";

        my %ignore_columns = (
            id           => 1,
            journal_auth => 1,
            cjdb_note    => 1,
            local_note   => 1,
        );
        @$columns = grep { !$ignore_columns{$_} } @$columns;

        print OUTPUT join "\t", @$columns;
        print OUTPUT "\n";

        my $titles_rs = $resource->do_module('global_rs', $schema)->search({ resource => $resource->id });
        while ( my $title = $titles_rs->next ) {
            print OUTPUT join "\t", map { $title->$_ } @$columns;
            print OUTPUT "\n";
        }

        close OUTPUT;

        $resource_xml .= create_resource_xml( $local_resource, $resource );

    }

    open OUTPUT, ">$output_dir/update.xml" or
        die "Unable to create XML output file: $!";

    print OUTPUT "<xml>\n" . $resource_xml . "</xml>\n";

    close OUTPUT;

    `cd $output_dir; tar --create --gzip  --file ${output_dir}/update.tgz .`;

    print "Your update file is done:\n${output_dir}/update.tgz\n";

}


sub create_resource_xml {
    my ( $local_resource, $resource ) = @_;

    my $output = "<resource>\n";

    my @skip_fields = qw(
        id
        resource_type
        active
        title_list_scanned
        created
        modified
        resource_identifier
        title_count
    );

    foreach my $column ( $resource->columns ) {
        next if grep { $_ eq $column } @skip_fields;

        my $value;
        if ( $local_resource->can($column) && hascontent($local_resource->$column) ) {
            $value = $local_resource->$column;
        }
        else {
            $value = $resource->$column;
        }

        next if !hascontent( $value );

        $value = encode_entities( $value );

        $output .= "<$column>$value</$column>\n";

    }

    ##
    ## Resource type - linked table
    ##

    my $value = defined($local_resource->resource_type)
                ? $local_resource->resource_type->type
                : $resource->resource_type->type;

    $output .= "<resource_type>" . encode_entities($value) . "</resource_type>\n";

    $output .= "</resource>\n";

    return $output;
}


sub get_timestamp {
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();

    $year += 1900;
    $mon  += 1;

    return sprintf( "%04i%02i%02i%02i%02i%02i", $year, $mon, $mday, $hour, $min, $sec );
}

sub usage {
    print <<EOF;

export_global_sync - creates a set of export XML and title lists, then compresses them.

 site_key=XXX          - CUFTS site key (example: BVAS)
 site_id=111           - CUFTS site id (example: 23)
 timestamp=2013-03-01  - export only resources updated on or after this date (YYYY-MM-DD)
 exact=2013-03-23      - export only resources updated on this date (YYYY-MM-DD)
 resource_keys=abc     - comma separated list of resources to export (example: ebsco_edh,proquest_ap)
 prev_days=5           - export only resources updated in the last X days
 output_dir=/tmp/123   - directory to write export files to

EOF
}

1;
