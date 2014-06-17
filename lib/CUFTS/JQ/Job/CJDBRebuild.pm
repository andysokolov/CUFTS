package CUFTS::JQ::Job::CJDBRebuild;

use strict;

use Moose;
use CUFTS::Config;
use String::Util qw( trim hascontent );
use CUFTS::CJDB::LoadingScript;

use CHI;

extends 'CUFTS::JQ::Job';

sub work {
    my $self = shift;

    $self->terminate_possible();

    # my $file = $self->data->{file};
    # return $self->fail( 'Title list file does not exist: ' . $self->data->{file} ) if !-e $file;

    eval {
        $self->start();

        # Use a file cache here and make sure it doesn't expire things. This is to cut memory
        # usage a bit. If we're losing things from the cache, then this should be rewritten to
        # use a temporary database table.
        my $MARC_cache = CHI->new(
            driver     => 'File',
            root_dir   => '/tmp/cjdb_load_temp_cache_' . $self->site->id,
        );
        $MARC_cache->clear();

        my %options = %{ $self->data };

        my $logger = CUFTS::CJDBJobLogger->new({ job => $self });

        my $schema = $self->work_schema;
        $schema->txn_do( sub {
            $self->debug('Rebuilding CJDB');
            $self->checkpoint( 0, 'Starting CJDB rebuild' );

            CUFTS::CJDB::LoadingScript::build_local_journal_auths( $logger, $self->site, $schema, $self );
            my $count = CUFTS::CJDB::LoadingScript::load_cufts_data( $logger, $self->site, \%options, $MARC_cache, $schema, $self );

            eval {
                CUFTS::CJDB::LoadingScript::email_site( $logger, $self->site, 'CJDB update completed for ' . $self->site->name . '. ' . $count . ' CJDB journals were loaded.' );
            };

        });

        build_dump( $logger, $self->site, $MARC_cache, $schema, $self );
        $self->checkpoint( 100, 'Finished CJDB rebuild.' );
        $self->finish('Completed rebuild.');


    };
    if ( $@ ) {
        if ( !$self->has_status('terminated') ) {
            $self->fail('Title load operation died: ' . $@);
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

package CUFTS::CJDBJobLogger;

use Moose;

has 'job' => (
    is => 'rw',
    isa => 'CUFTS::JQ::Job',
);

has 'trace_flag' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

sub info {
    shift->job->log( 1, 'info', join('', @_) );
}

sub trace {
    my $self = shift;
    return if !$self->trace_flag;
    $self->job->log( 0, 'trace', join('', @_) );
}

sub debug {
    shift->job->log( 0, 'debug', join('', @_) );
}

sub warn {
    shift->job->log( 0, 'warn', join('', @_) );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
