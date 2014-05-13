package CUFTS::JQ::Job::SiteDelete;

use Moose;

extends 'CUFTS::JQ::Job';

sub work {
    my $self = shift;

    my @tables = qw(
        CJDBAccounts
        CJDBISSNs
        CJDBJournalsAssociations
        CJDBJournalsSubjects
        CJDBJournalsTitles
        CJDBLinks
        CJDBRelations
        CJDBJournals
        CJDBTags

        ERMConsortia
        ERMContentTypes
        ERMCounterSources
        ERMDisplayFields
        ERMLicense
        ERMPricingModels
        ERMProviders
        ERMResourceMediums
        ERMResourceTypes
        ERMSubjects
        ERMSushi

        ERMMain

        Stats
        AccountsSites
    );

    $self->terminate_possible();

    my $site_id = $self->data->{site_id};
    my $site    = $self->work_schema->resultset('Sites')->find( $site_id );

    return $self->fail( 'Unable to load site id ' . $site_id ) if !defined $site;

    my $local_resources_rs = $site->local_resources;
    my $progress_max = $local_resources_rs->count + scalar @tables;

    eval {
        $self->start();

        $self->work_schema->txn_do( sub {

            my $count = 0;
            foreach my $table ( @tables ) {
                $self->checkpoint( (++$count / $progress_max)*100, "Clearing table $table" );
                $self->work_schema->resultset($table)->search({ site => $site_id })->delete;
            }

            while ( my $resource = $local_resources_rs->next ) {
                $self->checkpoint( (++$count / $progress_max)*100, "Clearing local resource id " . $resource->id );
                $resource->delete_titles();
            }

            $site->delete();

            $self->finish('Completed deleting site and associated resources');
        });
    };
    if ( $@ ) {
        if ( !$self->has_status('terminated') ) {
            $self->fail('Delete operation died: ' . $@);
        }
    }

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
