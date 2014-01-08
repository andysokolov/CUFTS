package CUFTS::ResultSet::Sites;

use strict;
use base 'DBIx::Class::ResultSet';

sub search_by_domain {
    my ( $self, $domain ) = @_;

    return $self->search(
        {
            'domains.domain' => $domain,
        },
        {
            join   => 'domains',
        }
    );
}

sub search_by_ip {
    my ( $self, $ip ) = @_;

    return $self->search(
        {
            'ips.ip_low'  => { '>=' => $ip },
            'ips.ip_high' => { '<=' => $ip },
        },
        {
            join => 'ips',
        }
    );
}


1;