## CUFTS::Resolve
##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## This file is part of CUFTS.
##
## CUFTS is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
##
## CUFTS is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CUFTS; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

package CUFTS::Resolve;

use strict;

use CUFTS::DB::Sites;
use CUFTS::DB::Resources;
use CUFTS::DB::ResourceTypes;
use CUFTS::DB::LocalResources;
use CUFTS::DB::Stats;

use CUFTS::Request;
use CUFTS::ResourcesLoader;
use CUFTS::ResolverResource;

use CUFTS::Exceptions;
use CUFTS::Config;
use CUFTS::Util::Simple;

use Data::Dumper;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub resolve {
    my ( $self, $sites, $request ) = @_;

    my %global_resource_dedupe;
    my $final_results;

SITE:
    foreach my $site (@$sites) {
        my %provider_dedupe;

        my $resources = defined($site) 
                        ? $self->get_active_resources($site)
                        : [];

RESOURCE:
        foreach my $local_resource (@$resources) {

            my $global_resource = $local_resource->resource;
            my $resource = $self->overlay_global_resource_data($local_resource);
            my $provider = $resource->provider;

            # Skip resource if there's no handling module
            next RESOURCE if !defined( $resource->module );

            # Skip resource if we've already got results from another site
            next RESOURCE if defined($global_resource)
                             && $global_resource_dedupe{ $global_resource->id };

            my $module = __module_name( $resource->module );

            # Get records to work with.  This can also be used to modify the 
            # request object for things like adding extra metadata, in which
            # case no records will be returned

            next RESOURCE if !$module->can('get_records');
            my $records = $module->get_records( $resource, $site, $request );
            next RESOURCE if !defined($records) || scalar(@$records) == 0;

            # Loop through the active services to get results.

            my $services = $self->get_services( $local_resource, $module, $site, $request );
            my $compiled_results;
SERVICE:
            foreach my $service (@$services) { 
                my $service_name = $service->name;

                # Dedupe providers that have already provided a link at this service level

                next SERVICE if $local_resource->dedupe
                                && not_empty_string( $provider )
                                && $provider_dedupe{ $provider }->{ $service_name };

                # Search for and build results

                my $method = 'build_link' . $service->method;
                if ( $module->can($method) ) {

                    my $results = $module->$method( $records, $resource, $site, $request );
                    next SERVICE if !defined($results) || scalar(@$results) == 0;

                    # Add the proxy prefix to the results

                    foreach my $result (@$results) {
                        $module->prepend_proxy( $result, $resource, $site, $request );
                    }

                    push @{ $compiled_results->{services}->{ $service_name }->{results} }, @$results;

                    # store details about services/resources if they haven't been set yet

                    if ( !defined( $compiled_results->{resource} ) ) {
                        $compiled_results->{resource} = $resource;
                    }

                    if ( !defined( $compiled_results->{services}->{ $service_name }->{service} ) ) {
                        $compiled_results->{services}->{ $service_name }->{service} = $service;
                    }

                    $provider_dedupe{ $resource->provider }->{ $service_name } = 1;
                }
            }

            # Keep track of which resources have been linked to for
            # de-duping in multi-site searches

            if ( defined($compiled_results) ) {
                push @$final_results, $compiled_results;
                if ( defined($global_resource) ) {
                    $global_resource_dedupe{ $global_resource->id } = 1;
                }
            }

        }
    }

    $self->log_request( $request, $final_results, $sites );

    return $final_results;
}

sub log_request {
    my ( $self, $request, $results, $sites ) = @_;

    my @request_fields = qw(
        genre
        issn
        eissn
        title
        atitle
        volume
        issue
        spage
        epage
        pages
        date
        doi

        aulast
        aufirst
        auinit
        auinit1
        auinitm

        artnum
        part
        coden
        isbn
        sici
        bici
        stitle

        ssn
        quarter

        oai
        pmid
        bibcode

        id
        sid
    );

    unless ( open LOG, ">>$CUFTS::Config::CUFTS_REQUEST_LOG" ) {
        warn("Unable to open request log: $!");
        return 0;
    }

    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime;
    $mon++;
    $year += 1900;

    printf LOG "%04i%02i%02i %02i:%02i:%02i\t",
        ( $year, $mon, $mday, $hour, $min, $sec );
    if ( scalar(@$sites) > 0 ) {
        print LOG ( join ',', map { $_->key } @$sites ), "\t";
    }
    else {
        print LOG "UNKNOWN\t";
    }

    print LOG join "\t",
        map { defined( $request->$_() ) ? $request->$_() : '' }
        @request_fields;

    foreach my $result (@$results) {
        print LOG "\t", $result->{resource}->id, "\t";
        print LOG $result->{resource}->name, "\t";
        print LOG join ',', keys %{ $result->{services} };
    }

    print LOG "\n";
    close LOG;

    if ( scalar(@$sites) > 0 ) {
        foreach my $site (@$sites) {
            my $db_log = {
                'request_date' =>
                    sprintf( "%04i%02i%02i", $year, $mon, $mday ),
                'request_time' =>
                    sprintf( "%02i:%02i:%02i", $hour, $min, $sec ),
                'site' => $site->id,
                'issn' => ( defined( $request->issn ) 
                            ? $request->issn
                            : $request->eissn
                ),
                'isbn'  => $request->isbn,
                'title' => ( defined( $request->title ) 
                             ? $request->title
                             : $request->stitle
                ),
                'volume'  => $request->volume,
                'issue'   => $request->issue,
                'date'    => $request->date,
                'doi'     => $request->doi,
                'results' => ( scalar(@$results) > 0 ? 't' : 'f' ),
            };

            CUFTS::DB::Stats->create($db_log);
            CUFTS::DB::Stats->dbi_commit;
        }
    }

    return 1;
}

sub get_sites {
    my ( $self, $request, $site_keys ) = @_;

    my @sites;

    my @site_keys;
    if ( defined($site_keys) ) {
        @site_keys = ref($site_keys) eq 'ARRAY'
                     ? @$site_keys
                     : split ',', $site_keys;
    }
    if ( defined($request) && defined($request->pid) ) {
        if ( defined($request->pid->{CUFTSSite}) ) {
            push @site_keys, split(',', $request->pid->{CUFTSSite});
        }
    }
    
    foreach my $site_key (@site_keys) {
        my @db_sites = CUFTS::DB::Sites->search( 'key' => $site_key );
        if ( scalar(@db_sites) == 1 ) {
            push @sites, $db_sites[0];
        }
    }

    if ( scalar(@sites) == 0 ) {
        my $site = $self->get_site_from_domain( $ENV{'REMOTE_HOST'} );

        if ( defined($site) ) {
            push @sites, $site;
        }
    }

    if ( scalar(@sites) == 0 ) {
        my $site = $self->get_site_from_ip( $ENV{'REMOTE_ADDR'} );
        if ( defined($site) ) {
            push @sites, $site;
        }
    }

    return \@sites;
}

sub get_site_from_domain {
    my ( $self, $domain ) = @_;
    return undef if !defined($domain);

    while ( $domain =~ s/^.+?\././ ) {
        my @domains = CUFTS::DB::SiteDomains->search( 'domain' => $domain );
        return $domains[0]->site if scalar(@domains);
    }

    return undef;
}

sub get_site_from_ip {
    my ( $self, $ip ) = @_;
    
    my @IPs = CUFTS::DB::SiteIPs->search_network($ip);
    return $IPs[0]->site if scalar(@IPs);

    return undef;
}

sub get_active_resources {
    my ( $self, $site ) = @_;

    my @resources = CUFTS::DB::LocalResources->search(
        active => 'true',
        site   => $site->id,
        { order_by => 'rank desc nulls last' }
    );

    # Filter out resources that are not active at the global level

    my @active_resources;
    foreach my $resource (@resources) {
        if ( defined( $resource->resource ) ) {
	            next if !$resource->resource->active;
        }
        push @active_resources, $resource;
    }

    return \@active_resources;
}


sub get_services {
    my ( $self, $resource, $module, $site, $request ) = @_;

    my @valid_services;
    my @services        = $resource->services;
    my $global_resource = $resource->resource;

    # Check whether the service is active at the global level as well
    if ( defined( $global_resource ) ) {

        my @global_services = $global_resource->services;
        my @new_services;
        foreach my $service (@services) {
            foreach my $global_service (@global_services) {
                $global_service->id == $service->id
                    and push @new_services, $service;
            }
        }
        @services = @new_services;
    }

    foreach my $service (@services) {
        my $method = 'can_get' . $service->method;

        if ( $module->can($method) && $module->$method($request) ) {
            push @valid_services, $service;
        }
    }

    return \@valid_services;
}


sub __module_name {
    return $CUFTS::Config::CUFTS_MODULE_PREFIX . $_[0];
}

##
## overlay_global_resource_data - Overlay global resource data into a non-CDBI object
## with merged local/global fields.  Previous versions used CDBI objects but modifying
## the fields, even temporarily was too slow due to triggers, etc.
##

sub overlay_global_resource_data {
    my ( $self, $local ) = @_;

    my $resource = CUFTS::ResolverResource->new();

    my $global = $local->resource;
    my $is_local = !defined( $global );
    if (!$is_local) {
        $resource->resource($global);
    }

    foreach my $column ( $resource->columns ) {
        next if $column eq 'resource';
        
        $resource->$column( 
            $is_local || not_empty_string( $local->$column ) 
            ? $local->$column
            : $global->can($column) 
            ? $global->$column 
            : undef );
    }

    return $resource;
}

1;
