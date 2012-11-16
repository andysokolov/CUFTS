use lib qw(lib);
use strict;

use CUFTS::DB::ERMMain;
use CUFTS::DB::ERMLicense;
use CUFTS::DB::ERMMainLink;
use CUFTS::DB::Resources;
use CUFTS::Util::Simple;

my %mapping = (
    erm_basic_name                      => undef, # special handling
    erm_basic_vendor                    => undef, # special handling
    erm_basic_publisher                 => 'erm_main.publisher',
    erm_basic_subscription_notes        => 'erm_main.subscription_notes',
    erm_datescosts_cost                 => 'erm_main.cost',
    erm_datescosts_contract_end         => 'erm_main.contract_end',
    erm_datescosts_renewal_notification => 'erm_main.renewal_notification',
    erm_datescosts_notification_email   => 'erm_main.notification_email',
    erm_datescosts_local_fund           => 'erm_main.local_fund',
    erm_datescosts_local_acquisitions   => 'erm_main.local_acquisitions',
    erm_datescosts_consortia            => undef,  # Needs lookup table
    erm_datescosts_consortia_notes      => 'erm_main.consortia_notes',
    erm_datescosts_notes                => 'erm_main.date_cost_notes',
    erm_statistics_notes                => 'erm_main.stats_notes',
    erm_admin_notes                     => 'erm_main.access_notes',
    erm_terms_simultaneous_users        => 'erm_main.simultaneous_users',
    erm_terms_allows_ill                => 'erm_license.allows_ill',
    erm_terms_ill_notes                 => 'erm_license.ill_notes',
    erm_terms_allows_ereserves          => 'erm_license.allows_ereserves',
    erm_terms_ereserves_notes           => 'erm_license.ereserves_notes',
    erm_terms_allows_coursepacks        => 'erm_license.allows_coursepacks',
    erm_terms_coursepacks_notes         => 'erm_license.coursepack_notes',
    erm_terms_notes                     => 'erm_license.terms_notes',
    erm_contacts_notes                  => 'erm_license.contact_notes',
    erm_misc_notes                      => 'erm_main.misc_notes',
);

my $search = [ map { $_ => { '!=' => undef } } keys %mapping ];

my @local_resources = CUFTS::DB::LocalResources->search($search);

foreach my $local_resource (@local_resources) {

    print "\n------ STARTING RESOURCE ", $local_resource->id, "------\n";

    my $site = $local_resource->site->id;

    print "Got site $site: ", $local_resource->site->name, "\n";

    my $name =   not_empty_string( $local_resource->erm_basic_name )
               ? $local_resource->erm_basic_name
               : not_empty_string( $local_resource->name )
               ? $local_resource->name
               : defined( $local_resource->resource )
               ? $local_resource->resource->name
               : undef;

    die( "No usable name found for local resource: " . $local_resource->id )
        if is_empty_string($name);

    print "Got name: $name\n";

    my $vendor =   not_empty_string( $local_resource->erm_basic_vendor )
                 ? $local_resource->erm_basic_vendor
                 : not_empty_string( $local_resource->provider )
                 ? $local_resource->provider
                 : defined( $local_resource->resource )
                 ? $local_resource->resource->provider
                 : undef;

    print "Got vendor: $vendor\n";

    # find_or_create consortia

    my $consortia;
    if ( not_empty_string( $local_resource->erm_datescosts_consortia ) ) {
        $consortia = CUFTS::DB::ERMConsortia->find_or_create( { site => $site, consortia => $local_resource->erm_datescosts_consortia });
        
        if ( defined( $consortia ) ) {
            print "Got consortia: ", $consortia->consortia, "\n";
        }
        else {
            print "No consortia needed\n";
        }
        
    }
    
    # create erm_license

    my $license;

    while ( my ( $key, $value ) = each %mapping ) {

        my ( $table, $field ) = split /\./, $value;
        next if $table ne 'erm_license';

        my $data = $local_resource->$key();

        next if is_empty_string( $data );
        
        if ( !defined( $license ) ) {
            $license = CUFTS::DB::ERMLicense->create({
                site => $site,
                key => $name,
            });
            
            print "Created new license record\n";
        }

        $license->$field( $data );
        print "Updated license field $field: ", substr( $data, 0, 10 ), " ... \n";

    }

    if ( defined( $license ) ) {
        $license->update();
        print "Committed license field updates\n";
    }

    # create erm_main

    my $main = CUFTS::DB::ERMMain->create({
        site => $site,
        key => $name . ' - ' . $vendor,
        vendor => $vendor,
        license => $license,
    });

    print "Created ERM Main record ", $main->id, ": ", $main->key, "\n";

    while ( my ( $key, $value ) = each %mapping ) {

        my ( $table, $field ) = split /\./, $value;

        my $data = $local_resource->$key();
        if ( not_empty_string( $data ) ) {

            if ( $table eq 'erm_main' ) {
                $main->$field( $data );
                print "Updated ERM Main field $field: ", substr( $data, 0, 10 ), " ... \n";
            }

        }

    }
    $main->update();
    print "Committed ERM Main field updates\n";
    

    # create erm_name
    
    my $erm_name = CUFTS::DB::ERMNames->create({
        erm_main => $main->id,
        name => $name,
        search_name => CUFTS::DB::ERMNames::strip_name( $name ),
        main => 1,
    });
    
    print "Created names record ", $erm_name->id, ": ", $erm_name->name, "\n";
    
    # create link
    
    my $link = CUFTS::DB::ERMMainLink->create({
        erm_main => $main->id,
        link_type => 'r',
        link_id => $local_resource->id,
    
    });

    print "Created link record ", $link->id, "\n";

}


CUFTS::DB::DBI->dbi_rollback();