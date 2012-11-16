package CUFTS::Util::CSVParse;

##
## A replacement for Text::CSV which does not choke on weird characters
## and thus can be used to parse ISO-8859-1 title lists.  99% of the code
## is ripped directly from Alan Citterman's Text::CSV.
##

use strict;

################################################################################
# new
#
#    class/object method expecting no arguments and returning a reference to a
#    newly created Text::CSV object.
################################################################################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{'_STATUS'}      = undef;
    $self->{'_ERROR_INPUT'} = undef;
    $self->{'_STRING'}      = undef;
    $self->{'_FIELDS'}      = undef;
    $self->{'_DELIM'}       = ',';
    bless $self, $class;
    return $self;
}

sub delim {
    my $self = shift;
    my $set  = shift;
    defined($set)
        and $self->{'_DELIM'} = $set;
    return $self->{'_DELIM'};
}

################################################################################
# status
#
#    object method returning the success or failure of the most recent combine()
#    or parse().  there are no side-effects.
################################################################################
sub status {
    my $self = shift;
    return $self->{'_STATUS'};
}

################################################################################
# error_input
#
#    object method returning the first invalid argument to the most recent
#    combine() or parse().  there are no side-effects.
################################################################################
sub error_input {
    my $self = shift;
    return $self->{'_ERROR_INPUT'};
}

################################################################################
# string
#
#    object method returning the result of the most recent combine() or the
#    input to the most recent parse(), whichever is more recent.  there are no
#    side-effects.
################################################################################
sub string {
    my $self = shift;
    return $self->{'_STRING'};
}

################################################################################
# fields
#
#    object method returning the result of the most recent parse() or the input
#    to the most recent combine(), whichever is more recent.  there are no
#    side-effects.
################################################################################
sub fields {
    my $self = shift;
    if ( ref( $self->{'_FIELDS'} ) ) {
        return @{ $self->{'_FIELDS'} };
    }
    return undef;
}

################################################################################
# parse
#
#    object method returning success or failure.  the given argument is expected
#    to be a valid comma-separated value.  failure can be the result of
#    no arguments or an argument containing an invalid sequence of characters.
#    side-effects include:
#      setting status()
#      setting fields()
#      setting string()
#      setting error_input()
################################################################################
sub parse {
    my $self = shift;
    $self->{'_STRING'}      = shift;
    $self->{'_FIELDS'}      = undef;
    $self->{'_ERROR_INPUT'} = $self->{'_STRING'};
    $self->{'_STATUS'}      = 0;
    if ( !defined( $self->{'_STRING'} ) ) {
        return $self->{'_STATUS'};
    }
    my $keep_biting = 1;
    my $palatable   = 0;
    my $line        = $self->{'_STRING'};
    if ( $line =~ /\n$/ ) {
        chop($line);
        if ( $line =~ /\r$/ ) {
            chop($line);
        }
    }
    my $mouthful = '';
    my @part     = ();
    while ( $keep_biting
        and ( $palatable = $self->_bite( \$line, \$mouthful, \$keep_biting ) )
        )
    {
        push( @part, $mouthful );
    }
    if ($palatable) {
        $self->{'_ERROR_INPUT'} = undef;
        $self->{'_FIELDS'}      = \@part;
    }
    return $self->{'_STATUS'} = $palatable;
}

################################################################################
# _bite
#
#    *private* class/object method returning success or failure.  the arguments
#    are:
#      - a reference to a comma-separated value string
#      - a reference to a return string
#      - a reference to a return boolean
#    upon success the first comma-separated value of the csv string is
#    transferred to the return string and the boolean is set to true if a comma
#    followed that value.  in other words, "bite" one value off of csv
#    returning the remaining string, the "piece" bitten, and if there's any
#    more.  failure can be the result of the csv string containing an invalid
#    sequence of characters.
#
#    from the csv string and
#    to be a valid comma-separated value.  failure can be the result of
#    no arguments or an argument containing an invalid sequence of characters.
#    side-effects include:
#      setting status()
#      setting fields()
#      setting string()
#      setting error_input()
################################################################################
sub _bite {
    my ( $self, $line_ref, $piece_ref, $bite_again_ref ) = @_;
    my $in_quotes = 0;
    my $ok        = 0;
    $$piece_ref      = '';
    $$bite_again_ref = 0;
    while (1) {
        if ( length($$line_ref) < 1 ) {

            # end of string...
            if ($in_quotes) {

                # end of string, missing closing double-quote...
                last;
            }
            else {

                # proper end of string...
                $ok = 1;
                last;
            }
        }
        elsif ( $$line_ref =~ /^\042/ ) {

            # double-quote...
            if ($in_quotes) {
                if ( length($$line_ref) == 1 ) {

                    # closing double-quote at end of string...
                    substr( $$line_ref, 0, 1 ) = '';
                    $ok = 1;
                    last;
                }
                elsif ( $$line_ref =~ /^\042\042/ ) {

                    # an embedded double-quote...
                    $$piece_ref .= "\042";
                    substr( $$line_ref, 0, 2 ) = '';
                }
                elsif ( $$line_ref =~ /^\042$self->{'_DELIM'}/o ) {

                    # closing double-quote followed by a comma...
                    substr( $$line_ref, 0, 2 ) = '';
                    $$bite_again_ref = 1;
                    $ok              = 1;
                    last;
                }
                else {

 # double-quote, followed by undesirable character (bad character sequence)...
                    last;
                }
            }
            else {
                if ( length($$piece_ref) < 1 ) {

                    # starting double-quote at beginning of string
                    $in_quotes = 1;
                    substr( $$line_ref, 0, 1 ) = '';
                }
                else {

          # double-quote, outside of double-quotes (bad character sequence)...
                    last;
                }
            }
        }
        elsif ( $$line_ref =~ /^\\$self->{'_DELIM'}/o ) {
        
            # backslash followed by a comma 
            $$piece_ref .= substr( $$line_ref, 1, 1 );
            substr( $$line_ref, 0, 2 ) = '';

        }
        elsif ( $$line_ref =~ /^$self->{'_DELIM'}/o ) {

            # comma...
            if ($in_quotes) {

                # a comma, inside double-quotes...
                $$piece_ref .= substr( $$line_ref, 0, 1 );
                substr( $$line_ref, 0, 1 ) = '';
            }
            else {

                # a comma, which separates values...
                substr( $$line_ref, 0, 1 ) = '';
                $$bite_again_ref = 1;
                $ok              = 1;
                last;
            }
        }
        elsif ( $$line_ref =~ /^[\t\040-\176]/ ) {

            # a tab, space, or printable...
            $$piece_ref .= substr( $$line_ref, 0, 1 );
            substr( $$line_ref, 0, 1 ) = '';
        }
        else {

            $$piece_ref .= substr( $$line_ref, 0, 1 );
            substr( $$line_ref, 0, 1 ) = '';
        }
    }
    return $ok;
}

1;

__END__

