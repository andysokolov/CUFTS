#!/usr/local/bin/perl

##
## This script checks imports a global sync file
##

use lib qw(lib);

use HTML::Entities;

use CUFTS::Exceptions;
use CUFTS::Config;
use CUFTS::Util::Simple;
use CUFTS::ResourcesLoader;

use String::Util qw(hascontent trim);
use XML::Parser::Lite::Tree;
use Data::Dumper;
use Getopt::Long;

use strict;

my $tmp_dir = '/tmp/global_import';


my %options;

my $infile = shift(@ARGV);

my $schema = CUFTS::Config::get_schema();

import($schema);

sub import {
    my ( $schema ) = @_;

    -e $infile or
        die("Unable to find import file");

    my $timestamp = get_timestamp();
    $tmp_dir .= '_' . $timestamp;

    mkdir $tmp_dir or
        die("Unable to create temp dir: $!");

    `tar xzf ${infile} -C ${tmp_dir}`;

    -e "${tmp_dir}/update.xml" or
        die("Unable to extract import file.");

    my $resources_tree = parse_resource_file( *INPUT_RESOURCE );

    foreach my $node ( ref($resources_tree->{xml}) eq 'ARRAY' ? @{$resources_tree->{xml}} : ( $resources_tree->{xml} ) ) {

        my $resource_node = $node->{resource};
        next if !defined $resource_node;

        $schema->txn_do( sub { load_resource($schema, $resource_node); } );
    }
}

sub load_resource {
    my ( $schema, $resource_node ) = @_;

    my $key = $resource_node->{key};
    if ( !hascontent($key) ) {
        die( "Unable to locate resource key in resource XML: " . Dumper($resource_node) );
    }

    my $resource = $schema->resultset('GlobalResources')->find({ key => $key }) || create_resource( $resource_node, $schema );
    defined $resource or
        die("Unable to create resource");

    print "Starting title load for: ", $resource->name, "\n";

    my $module = $resource->module;
    $module = CUFTS::Resources::__module_name($module);

    # This is very hackish.. Replace all the custom load methods with the ones from CUFTS::Resources

    no strict 'refs';
    *{"${module}::title_list_column_delimiter"}   = *CUFTS::Resources::title_list_column_delimiter;
    *{"${module}::title_list_field_map"}          = *CUFTS::Resources::title_list_field_map;
    *{"${module}::title_list_skip_lines_count"}   = *CUFTS::Resources::title_list_skip_lines_count;
    *{"${module}::title_list_skip_blank_lines"}   = *CUFTS::Resources::title_list_skip_blank_lines;
    *{"${module}::title_list_extra_requires"}     = *CUFTS::Resources::title_list_extra_requires;

    *{"${module}::preprocess_file"}               = *CUFTS::Resources::preprocess_file;
    *{"${module}::title_list_get_field_headings"} = *CUFTS::Resources::title_list_get_field_headings;
    *{"${module}::skip_record"}                   = *CUFTS::Resources::skip_record;
    *{"${module}::title_list_skip_lines"}         = *CUFTS::Resources::title_list_skip_lines;
    *{"${module}::title_list_read_row"}           = *CUFTS::Resources::title_list_read_row;
    *{"${module}::title_list_parse_row"}          = *CUFTS::Resources::title_list_parse_row;
    *{"${module}::title_list_split_row"}          = *CUFTS::Resources::title_list_split_row;
    *{"${module}::title_list_skip_comment_line"}  = *CUFTS::Resources::title_list_skip_comment_line;
    *{"${module}::clean_data"}                    = *CUFTS::Resources::clean_data;

    my $results = $module->load_global_title_list($schema, $resource, "${tmp_dir}/$key");

    print 'Resource: '         . $resource->name . "\n";
    print 'Processed: '        . $results->{processed_count} . "\n";
    print 'Errors: '           . $results->{error_count} . "\n";
    print 'New: '              . $results->{new_count} . "\n";
    print 'Modified: '         . $results->{modified_count} . "\n";
    print 'Deleted: '          . $results->{deleted_count} . "\n";
    print 'Update Timestamp: ' . $results->{timestamp} . "\n\nErrors\n-------\n";

    foreach my $error (@{$results->{errors}}) {
        print "$error\n";
    }
    print "-------\n";

    CUFTS::Resources->email_changes( $resource, $results );
}

sub create_resource {
    my ( $resource_node, $schema ) = @_;

    # Try to find a resource type

    my $resource_type = $schema->resultset('ResourceTypes')->find({ type => $resource_node->{resource_type} });
    defined $resource_type or
        die("Unable to find resource type: " . $resource_node->{resource_type});

    # Create base resource record

    my $resource_hash = {
        name          => $resource_node->{name},
        module        => $resource_node->{module},
        resource_type => $resource_type->id,
    };

    my $resource = $schema->resultset('GlobalResources')->create( $resource_hash );
    die("Unable to create resource record.") if !defined $resource;

    # Update new resource record with other fields (including details fields)

    foreach my $field ( keys %$resource_node ) {
        next if grep { $field eq $_ } ( 'services', 'resource_type', 'module', 'name' );

        $resource->$field( $resource_node->{$field} );
    }

    $resource->update;

    return $resource;
}


sub get_timestamp {
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();

    $year += 1900;
    $mon  += 1;

    return sprintf( "%04i%02i%02i%02i%02i%02i", $year, $mon, $mday, $hour, $min, $sec );
}

sub parse_resource_file {
    my ( $INPUT ) = @_;

    open INPUT_RESOURCE, "${tmp_dir}/update.xml" or
        die("Unable to open resource input file");

    my $xml;
    while ( my $line = <$INPUT> ) {
        $xml .= $line;
    }

    close INPUT_RESOURCE;

    my $tree = XML::Parser::Lite::Tree::instance()->parse($xml);
    $tree = flatten_tree( $tree->{children}->[0] );

    return $tree;

}


sub flatten_tree {
    my ( $tree ) = @_;

    my $data;

    my $name = $tree->{name};
    my $content;

    if ( exists($tree->{children}) && ref($tree->{children}) && scalar( @{$tree->{children}} ) > 1 ) {

        foreach my $child ( @{$tree->{children}} ) {

            my $result = flatten_tree( $child );
            next if !defined($result);

            foreach my $key ( keys(%$result) ) {

                if ( ref($data->{$name}) eq 'ARRAY' ) {
                    push @{$data->{$name}}, $result;
                }
                else {

                    if ( !exists($data->{$name}->{$key}) ) {
                        $data->{$name}->{$key} = $result->{$key};
                    }
                    else {
                        if ( ref($data->{$name}->{$key}) ne 'ARRAY' ) {
                            $data->{$name} = [ { $key =>$data->{$name}->{$key} } ];
                        }
                        push @{$data->{$name}}, $result;
                    }
                }
            }

        }

    }
    else {
        $content = $tree->{children}->[0]->{content};
        return undef if !defined($content);
        $data->{$name} = $content;
    }

    return $data;

}



1;
