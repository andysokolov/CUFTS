#!/usr/local/bin/perl

##
## This script checks exports a global sync file for a specified site
##

use lib qw(lib);

use HTML::Entities;
use Date::Calc qw();

use CUFTS::Exceptions;
use CUFTS::Config;
use CUFTS::Util::Simple;

use CUFTS::DB::DBI;

use CUFTS::DB::Sites;
use CUFTS::DB::Resources;
use CUFTS::DB::Journals;
use CUFTS::DB::JournalsActive;
use CUFTS::DB::Stats;

use CUFTS::ResourcesLoader;

use Getopt::Long;

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

if ( defined($prev_days) ) {

    my @dc = Date::Calc::Today(); 
    while ( $prev_days > 0 || Date::Calc::Day_of_Week(@dc) > 5 ) {
        @dc = Date::Calc::Add_Delta_Days( @dc, -1 );
        $prev_days--;
    }
    $exact_timestamp = sprintf( "%4i%02i%02i", @dc );

}
elsif ( defined($after_timestamp) ) {

    if ( $after_timestamp =~ / (\d{4}) - (\d{2}) - (\d{2}) /xsm ) {
        $after_timestamp = "$1$2$3";
        print "Checking for title updates after: $after_timestamp\n";
    }
    else {
        die("Timestamp does not match YYYY-MM-DD format: $after_timestamp");
    }
    
}
elsif ( defined($exact_timestamp) ) {
    if ( $exact_timestamp =~ / (\d{4}) - (\d{2}) - (\d{2}) /xsm ) {
        $exact_timestamp = "$1$2$3";
        print "Checking for title updates on: $exact_timestamp\n";
    }
    else {
        die("Timestamp does not match YYYY-MM-DD format: $exact_timestamp");
    }
}

my @resource_keys;
if ( defined($resource_keys) ) {
    @resource_keys = split /,/, $resource_keys;
}

export();

sub export {

    my $site;
    if ( $options{site_id} ) {
        $site = CUFTS::DB::Sites->search( id => int($options{site_id}) )->first or
            die("Could not find site: " . $options{site_id});
    }
    elsif ( $options{site_key} ) {
        $site = CUFTS::DB::Sites->search( key => $options{site_key} )->first or
            die("Could not find site: " . $options{site_key});
    }
    else {
        usage();
        exit;
    }

    my $site_id = $site->id;

    my $timestamp = get_timestamp();
    if ( defined($force_output_dir) ) {
        $output_dir = $force_output_dir;
    }
    else {
        $output_dir .= '_' . $timestamp;
    }

    mkdir ${output_dir} or
        die("Unable to create output dir: $!");

    my $local_resources_iter = CUFTS::DB::LocalResources->search( 
        site => $site_id, 
        active => 't', 
        resource => { '!=' => undef }
    );
    
    my $resource_xml;

RESOURCE:

    while ( my $local_resource = $local_resources_iter->next ) {
        my $resource = $local_resource->resource;

        print "Checking: ", $resource->name, "\n";

        if ( !$resource->do_module('has_title_list') ) {
            print "Resource does not use title lists, skipping.\n";
            next RESOURCE;
        }

        if ( defined($after_timestamp) || defined($exact_timestamp) ) {
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
        if ( !defined($key) ) {
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

        if ( scalar(@resource_keys) && !grep { $key eq $_ } @resource_keys ) {
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
            id => 1,
            journal_auth => 1,
            cjdb_note => 1,
            local_note => 1,
        );
        @$columns = grep { !$ignore_columns{$_} } @$columns;

        print OUTPUT join "\t", @$columns;
        print OUTPUT "\n";
        
        my $db_module = $resource->do_module( 'global_db_module' );
        if ( is_empty_string($db_module) ) {
            print "Missing DB module, skipping resource.\n";
            next RESOURCE;
        }
        
        my $titles_iter = $db_module->search( resource => $resource->id );
        while ( my $title = $titles_iter->next ) {
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
        if ( $local_resource->can($column) && not_empty_string($local_resource->$column) ) {
            $value = $local_resource->$column;
        }
        else {
            $value = $resource->$column;
        }

        next if is_empty_string( $value );

        $value = encode_entities( $value );
        
        $output .= "<$column>$value</$column>\n";
        
    }
        
    ##
    ## Resource type - linked table
    ##
        
    my $value = defined( $local_resource->resource_type )
                ? $local_resource->resource_type->type
                : $resource->resource_type->type;

    $output .= "<resource_type>" . encode_entities( $value ) . "</resource_type>\n";
    
    ##
    ## Services - linked table
    ##
    
    $output .= "<services>\n";

    my @services = $local_resource->services;
    if ( !scalar(@services) ) {
        @services = $resource->services;
    }

    foreach my $service ( @services ) {
        $output .= "<service>" . encode_entities( $service->name) . "</service>\n";
    }
    
    $output .= "</services>\n";
    
    $output .= "</resource>\n";
    
    return $output;
}


sub get_timestamp {
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();

    $year += 1900;
    $mon  += 1;

    return sprintf( "%04i%02i%02i%02i%02i%02i", $year, $mon, $mday, $hour, $min, $sec );
}




1;