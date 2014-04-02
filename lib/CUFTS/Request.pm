package CUFTS::Request;

use strict;

use URI::OpenURL;
use URI::Escape;
use CUFTS::Exceptions;

use String::Util qw( trim hascontent );

use Moose;
use Moose::Util::TypeConstraints;

# use Data::Dumper;

subtype 'CUFTS::Types::ISSN'
    => as 'Str'
    => where { $_ =~ /^\d{7}[\dX]$/ };

subtype 'CUFTS::Types::ArrayOfISSNs'
    => where { scalar( grep { $_ =~ /^\d{7}[\dX]$/ } @$_ ) == scalar @$_; }
    => as 'ArrayRef';

coerce 'CUFTS::Types::ISSN'
    => from 'Str'
        => via { _clean_issn($_) };

coerce 'CUFTS::Types::ArrayOfISSNs'
    => from 'ArrayRef'
        => via { [ map { _clean_issn($_) } @$_ ] };

sub _clean_issn {
    my $issn = uc($_);
    $issn =~ s/[^\dX]//g;
    return $issn;
}

has 'id' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'sid' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'genre' => (
	isa        => 'Str',
	is         => 'rw',
    default    => 'article',
);

has 'aulast' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'aufirst' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'auinit' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'auinit1' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'auinitm' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'au' => (
    isa        => 'Str',
    is         => 'rw',
);

has 'issn' => (
	isa        => 'CUFTS::Types::ISSN',
	is         => 'rw',
    coerce     => 1,
);

has 'eissn' => (
	isa        => 'CUFTS::Types::ISSN',
	is         => 'rw',
    coerce     => 1,
);

has 'coden' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'isbn' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'sici' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'bici' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'title' => (
	isa        => 'Str',
	is         => 'rw',
    default    => sub { my $self = shift; return hascontent($self->jtitle) ? $self->jtitle : undef; },
    lazy       => 1,
);

has 'stitle' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'atitle' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'jtitle' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'volume' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'part' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'issue' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'spage' => (
	isa        => 'Maybe[Str]',
	is         => 'rw',
    default    => sub { my $self = shift; return ( hascontent( $self->pages ) && $self->pages =~ /^(\d+)/ ) ? $1 : undef },
    lazy       => 1,
);

has 'epage' => (
	isa        => 'Maybe[Str]',
	is         => 'rw',
    default    => sub { my $self = shift; return ( hascontent( $self->pages ) && $self->pages =~ /(\d+)$/ ) ? $1 : undef },
    lazy       => 1,
);

has 'pages' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'artnum' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'date' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'ssn' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'quarter' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'doi' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'oai' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'pmid' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'bibcode' => (
	isa        => 'Str',
	is         => 'rw',
);

has 'pub' => (
    isa        => 'Str',
    is         => 'rw',
);

has 'pid' => (
	isa        => 'Any',  # May be a HashRef
	is         => 'rw',
);

has 'other_issns' => (
	isa        => 'CUFTS::Types::ArrayOfISSNs',
	is         => 'rw',
    coerce     => 1,
);

has 'journal_auths' => (
	isa        => 'ArrayRef',
	is         => 'rw',
);

sub year {
    my ( $self, $value ) = @_;
    if (defined($value)) {
        CUFTS::Exception::App->throw('Cannot set year in Request object - year is derived from date.');
    }

    return undef if !hascontent( $self->date );

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

    return undef if !hascontent( $self->date );

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

    return undef if !hascontent( $self->date );

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
        my $value = $fields->{$field};
        $value =~ s/\n/ /g;
        $value = trim($value);
        next if !hascontent($value);

        if ($field eq 'id') {
            # Move id fields into seperate fields

            my ($subfield, $value) = split ':', $value;
            if ( grep {$_ eq $subfield} qw( doi oai pmid bibcode ) ) {
                $request->$subfield($value);
            }

        }
        else {
            if ( $request->can($field) ) {
                $request->$field($value);
            }
            else {
                warn("Unrecognized OpenURL parameter: $field");
            }
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
        my $value = $md{$field};
        $value =~ s/\n/ /g;
        $value = trim($value);
        next if !hascontent($value);

        if ( $request->can($field) ) {
            $request->$field($value);
        }
        else {
            warn("Unrecognized OpenURL parameter: $field");
        }
    }

    # Grab "id" fields if we support them (oai,doi)

    foreach my $id ( $openurl->referent->id ) {
        foreach my $id_type ( 'oai', 'doi', 'bibcode', 'pmid' ) {
            if ( $id =~ m#^ info:${id_type} / (.+) #xsm ) {
                $request->$id_type($1);
            }
        }
    }

    return $request;
}

sub _cleanup {
    my ($self) = @_;

    # Remove dashes from ISSN/ISBNs, uppercase [xX]
    foreach my $method ( 'isbn' ) {
        my $value = $self->$method;
        if ( defined($value) ) {
            $value = uc($value);
            $value =~ s/[^\dX]//g;
            $self->$method($value);
        }
    }

    return $self;
}

sub issns {
    my ( $self ) = @_;

    my @issns;

    push(@issns, $self->issn)  if hascontent($self->issn);
    push(@issns, $self->eissn) if hascontent($self->eissn);

    if ( ref($self->other_issns) eq 'ARRAY' && scalar( @{$self->other_issns} ) ) {
        push @issns, @{$self->other_issns};
    }

    return @issns;
}

no Moose::Util::TypeConstraints;
no Moose;
__PACKAGE__->meta->make_immutable;

1;
