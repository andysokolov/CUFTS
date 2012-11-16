package CUFTS::CJDB::Authentication::LDAP;

use Net::LDAPS qw(LDAP_SUCCESS);

use strict;

sub authenticate {
    my ( $class, $site, $user, $password ) = @_;

    my $auth_server = $site->cjdb_authentication_server
        or die("No authentication server set while attempting LDAP authentication");

    my $ldap = Net::LDAPS->new($auth_server)
        or die("Unable to connect to LDAP server");

    # Get bind strings and replace user variable if necessary
    my @bind_strings = split( /\|/, $site->cjdb_authentication_string1 );
    
    if ( !scalar(@bind_strings) ) {
        die("No bind string set in LDAP authentication (cjdb_authentication_string1)");
    }
        

    my $bound = 0;
    foreach my $bind_string (@bind_strings) {
        $bind_string =~ s/\$user/$user/g;
        my $mesg = $ldap->bind( $bind_string, password => $password );
        if ( $mesg->code == LDAP_SUCCESS ) {
            $bound = 1;
            last;
        }
    }

    if ( !$bound ) {
        die("Unable to bind user '$user', probably bad password");
    }

    # Get base and filter strings and replace user variables if necessary
    my $base_string = $site->cjdb_authentication_string2
        or die("No base string set in LDAP authentication");
    $base_string =~ s/\$user/$user/g;

    my $filter_string = $site->cjdb_authentication_string3
        or die("No base string set in LDAP authentication");
    $filter_string =~ s/\$user/$user/g;

    # Search for the user record 

    my $result = $ldap->search(
        base   => $base_string,
        filter => $filter_string
    );
    $ldap->unbind;

    if (    $result->code  != LDAP_SUCCESS
         || $result->count != 1 )
    {
        die("Unable to retrieve user record.");
    }

    $result = $result->first_entry;

    if ( my $level100_string = $site->cjdb_authentication_level100 ) {
        my ($field, $regex) = split('=', $level100_string, 2);
        my $value = $result->get_value($field);
        if ( $value =~ /$regex/ ) {
            return 100;
        }
    }

    if ( my $level50_string = $site->cjdb_authentication_level50 ) {
        my ($field, $regex) = split('=', $level50_string, 2);
        my $value = $result->get_value($field);
        if ($value =~ /$regex/) {
            return 50;
        }
    }

    return 0;
}

1;