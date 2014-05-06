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

use CUFTS::Request;
use CUFTS::ResourcesLoader;
use CUFTS::ResolverResource;

use CUFTS::Exceptions;
use CUFTS::Config;

use String::Util qw(trim hascontent);

use Moose;

has 'schema' => (
    isa => 'Object',
    is  => 'rw',
    default => sub { CUFTS::Config::get_schema(); },
);


sub resolve {
    my ( $self, $sites, $request ) = @_;

    my %global_resource_dedupe;
    my $final_results;

SITE:
    foreach my $site (@$sites) {
        my %provider_dedupe;

        next SITE if !defined $site;

RESOURCE:
        foreach my $local_resource ( $self->get_active_resources($site) ) {

            my $global_resource = $local_resource->resource;
            my $resource = $self->overlay_global_resource_data($local_resource);
            my $provider = $resource->provider;

            # Skip resource if there's no handling module
            next RESOURCE if !defined $resource->module;

            # Skip resource if we've already got results from another site
            next RESOURCE if defined($global_resource)
                             && $global_resource_dedupe{ $global_resource->id };

            my $module = __module_name( $resource->module );

            # Get records to work with.  This can also be used to modify the
            # request object for things like adding extra metadata, in which
            # case no records will be returned

            next RESOURCE if !$module->can('get_records');
            my $records = $module->get_records( $self->schema, $resource, $site, $request );
            next RESOURCE if !defined $records || scalar @$records == 0;

            # Loop through the active services to get results.

            my $services = $self->get_services( $local_resource, $module, $site, $request );
            my $compiled_results;
SERVICE:
            foreach my $service (@$services) {

                # Dedupe providers that have already provided a link at this service level

                next SERVICE if $local_resource->dedupe
                                && hascontent($provider)
                                && $provider_dedupe{$provider}->{$service};

                # Search for and build results

                my $method = 'build_link' . $module->services_methods->{$service};
                if ( $module->can($method) ) {

                    my $results = $module->$method( $self->schema, $records, $resource, $site, $request );
                    next SERVICE if !defined($results) || scalar(@$results) == 0;

                    # Add the proxy prefix to the results

                    foreach my $result (@$results) {
                        $module->prepend_proxy( $result, $resource, $site, $request );
                    }

                    push @{ $compiled_results->{services}->{ $service }->{results} }, @$results;

                    # store details about services/resources if they haven't been set yet

                    if ( !defined( $compiled_results->{resource} ) ) {
                        $compiled_results->{resource} = $resource;
                    }

                    if ( !defined( $compiled_results->{services}->{ $service }->{service} ) ) {
                        $compiled_results->{services}->{ $service }->{service} = $service;
                    }

                    $provider_dedupe{ $resource->provider }->{ $service } = 1;
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

    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime;
    $mon++;
    $year += 1900;

    unless ( open LOG, ">>$CUFTS::Config::CUFTS_REQUEST_LOG" ) {
        warn("Unable to open request log: $!");
        return 0;
    }

    printf LOG "%04i%02i%02i %02i:%02i:%02i\t", ( $year, $mon, $mday, $hour, $min, $sec );
    if ( scalar(@$sites) > 0 ) {
        print LOG ( join ',', map { $_->key } @$sites ), "\t";
    }
    else {
        print LOG "UNKNOWN\t";
    }

    print LOG join "\t",
        map { defined( $request->$_() ) ? $request->$_() : '' } @request_fields;

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
                request_date => sprintf( "%04i%02i%02i", $year, $mon, $mday ),
                request_time => sprintf( "%02i:%02i:%02i", $hour, $min, $sec ),
                site         => $site->id,
                issn         => defined($request->issn) ? $request->issn : $request->eissn,
                isbn         => $request->isbn,
                title        => defined($request->title) ? $request->title : $request->stitle,
                volume       => $request->volume,
                issue        => $request->issue,
                date         => $request->date,
                doi          => $request->doi,
                results      => scalar(@$results) > 0 ? 't' : 'f',
            };

            $self->schema->resultset('Stats')->create($db_log);
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
        my @db_sites = $self->schema->resultset('Sites')->search({ key => $site_key });
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
        my $site = $self->schema->resultset('Sites')->search_by_domain($domain)->first;
        return $site if defined($site);
    }

    return undef;
}

sub get_site_from_ip {
    my ( $self, $ip ) = @_;

    return $self->schema->resultset('Sites')->search_by_ip($ip)->first;
}

sub get_active_resources {
    my ( $self, $site ) = @_;

    my $resources_rs = $site->local_resources(
        { active => 'true', },
        { order_by => 'rank DESC NULLS LAST', }
    );

    # Filter out resources that are not active at the global level. This could maybe be done in DBIC now.

    my @active_resources;
    while ( my $resource = $resources_rs->next ) {
        next if defined($resource->resource) && !$resource->resource->active;  # Skip deactivated global resources
        push @active_resources, $resource;
    }

    return @active_resources;
}


sub get_services {
    my ( $self, $resource, $module, $site, $request ) = @_;

    my @valid_services;
    my $services        = $module->services;
    my $global_resource = $resource->resource;

    foreach my $service (@$services) {
        my $method = 'can_get' . $module->services_methods->{$service};

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
    my $is_local = !defined $global;
    if ($is_local) {
        $resource->resource($local);
        $resource->is_local(1);
    }
    else {
        $resource->resource($global);
        $resource->is_local(0);
    }

    foreach my $column ( $resource->columns ) {
        next if $column eq 'resource';

        my $value =   $is_local || hascontent($local->$column) ? $local->$column
                    : $global->can($column)                    ? $global->$column
                    : undef;

        # Flatten simple objetcs
        $value = $value->type if $column eq 'resource_type';

        $resource->$column($value);
    }

    return $resource;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
