## CUFTS::Request
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

package CUFTS::Request;

use strict;
use URI::OpenURL;
use URI::Escape;
use CUFTS::Exceptions;

use CUFTS::Util::Simple;

use base qw(Class::Accessor);

# Accessors for OpenURL fields

__PACKAGE__->mk_accessors( qw(
        id
        sid

        genre

        aulast
        aufirst
        auinit
        auinit1
        auinitm

        issn
        eissn
        coden
        isbn
        sici
        bici
        title
        stitle
        atitle
        jtitle

        volume
        part
        issue
        spage
        epage
        pages
        artnum
        date
        ssn
        quarter

        doi
        oai
        pmid
        bibcode

        pid
        
        other_issns
        journal_auths
));

sub year {
    my ( $self, $value ) = @_;
    if (defined($value)) {
        CUFTS::Exception::App->throw('Cannot set year in Request object - year is derived from date.');
    }

    return undef if !defined( $self->date );

    if ( $self->date =~ /^(\d{4})/ ) {
        return $1;
    }

    return undef;
}

sub month {
    my ( $self, $value ) = @_;
    if (defined($value)) {
        CUFTS::Exception::App->throw('Cannot set month in Request object - month is derived from date.');
    }

    return undef if !defined( $self->date );

    if ( $self->date =~ /^\d{4}-(\d{2})/ ) {
        return $1;
    }
    elsif ( $self->date =~ /^ \d{4} ([01]\d) [0123]\d $/xsm ) {
        return $1;
    }

    return undef;
}

sub day {
    my ( $self, $value ) = @_;
    if (defined($value)) {
        CUFTS::Exception::App->throw('Cannot set day in Request object - day is derived from date.');
    }

    return undef if !defined( $self->date );

    if ( $self->date =~ /^\d{4}-\d{2}-(\d{2})/ ) {
        return $1;
    }
    elsif ( $self->date =~ /^ \d{4} [01]\d ([0123]\d) $/xsm ) {
        return $1;
    }

    return undef;
}

sub parse_openurl {
    my ( $class, $fields, $uri ) = @_;

    if ( exists( $fields->{url_ver} ) ) {
        return $class->parse_openurl_1($fields);
    }
    else {
        return $class->parse_openurl_0($fields);
    }
}


sub parse_openurl_0 {
    my ( $class, $fields, $uri ) = @_;

    my $request = $class->new();
    foreach my $field ( keys %$fields ) {
        $fields->{$field} =~ s/\n/ /g;

        if ($field eq 'id') {
            # Move id fields into seperate fields
            
            my ($subfield, $value) = split ':', $fields->{$field};
            if ( grep {$_ eq $subfield} qw(doi oai pmid bibcode ) ) {
                $request->$subfield($value);
            }
            
        } else {
            $request->can($field)
                or warn("Unrecognized OpenURL parameter: $field");
            $request->$field( $fields->{$field} );
        }

    }

    

    ##
    ## Deal with "pid" fields
    ##

# This is a lame <xxx>yyy</xxx>&<aaa>bbb</aaa> seperator.  It does NOT deal with
# & embedded in a block at this point!!

    if ( defined( $request->pid ) ) {
        my %pid_hash;
        foreach my $pid_field ( split /&/, $request->pid ) {
            if ( $pid_field =~ m{^ <([^>]+)> (.+) </[^>]+> $}xsm ) {
                $pid_hash{$1} = $2;
            }
        }
        $request->pid( \%pid_hash );
    }

    $request->_cleanup();

    return $request;
}

sub parse_openurl_1 {
    my ( $class, $fields, $uri ) = @_;

# Build up a URL from the fields.  Yuck.  Change this to use a passed in parameter
# when Catalyst supports it (5.5?)

    unless ( defined($uri) ) {
        $uri = 'http://base?';
        my @params;
        foreach my $field ( keys %$fields ) {
            my $value = $fields->{$field};
            if ( ref $value eq 'ARRAY' ) {
                push @params,
                    map { uri_escape($field) . '=' . uri_escape($_) } @$value;
            }
            else {
                push @params, uri_escape($field) . '=' . uri_escape($value);
            }
        }
        $uri .= join '&', @params;
    }

    my $openurl = URI::OpenURL->new($uri);

    my %md      = $openurl->referent->metadata();
    my $request = $class->new();
    foreach my $field ( keys %md ) {
        $md{$field} =~ s/\n/ /g;

        $request->can($field)
            or warn("Unrecognized OpenURL parameter: $field");
        $request->$field( $md{$field} );
    }

    # Grab "id" fields if we support them (oai,doi)

    foreach my $id ( $openurl->referent->id ) {
        foreach my $id_type ( 'oai', 'doi', 'bibcode', 'pmid' ) {
            if ( $id =~ m#^ info:${id_type} / (.+) #xsm ) {
                $request->$id_type($1);
            }
        }
    }

    $request->_cleanup();

    return $request;
}

sub _cleanup {
    my ($self) = @_;

    # Remove dashes from ISSN/ISBNs, uppercase [xX]
    foreach my $method ( 'issn', 'eissn', 'isbn' ) {
        my $value = $self->$method;
        if ( defined($value) ) {
            $value = uc($value);
            $value =~ s/[^\dxX]//g;
            $self->$method($value);
        }
    }

    # Fill in start page if it is not set and there is pages data
    if (     is_empty_string( $self->spage )
         && not_empty_string( $self->pages )
         && $self->pages =~ /^(\d+)/ ) {

        $self->spage($1);
    }


    # Fill in end page if it is not set and there is pages data
    if (     is_empty_string( $self->epage )
         && not_empty_string( $self->pages )
         && $self->pages =~ /(\d+)$/ ) {

        $self->epage($1);
    }

    # promote j-title to the title field since most searching/display is keyed off of that.
    if (     is_empty_string( $self->title ) 
         && not_empty_string( $self->jtitle ) ) {

        $self->title( $self->jtitle );
    }

    # Default to article genre

    if ( is_empty_string( $self->genre ) ) {
        $self->genre('article');
    }

    return $self;
}

sub issns {
    my ( $self ) = @_;
    
    my @issns;
    if ( not_empty_string( $self->issn ) ) {
        push @issns, $self->issn;
    };
    if ( not_empty_string( $self->eissn ) ) {
        push @issns, $self->eissn;
    };
    if ( ref($self->other_issns) eq 'ARRAY' && scalar( @{$self->other_issns} ) ) {
        push @issns, @{$self->other_issns};
    }
    
    return @issns;
}

1;
