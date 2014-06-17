package CUFTS::JQ::Client;

use Readonly;
use Moose;
use Storable qw(freeze);
use Sys::Hostname;
use IO::File;
use CUFTS::Config;

has 'job_schema' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has 'work_schema' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has 'errors' => (
    is         => 'rw',
    traits     => ['Array'],
    isa        => 'ArrayRef[Str]',
    default    => sub { [] },
    handles    => {
        add_error    => 'push',
        has_errors   => 'count',
        join_errors  => 'join',
        clear_errors => 'clear',
    },
);

has 'identifier' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { return hostname },
);

has 'account_id' => (
    is  => 'rw',
    isa => 'Maybe[Int]',
);

has 'site_id' => (
    is  => 'rw',
    isa => 'Maybe[Int]',
);

has 'log_fh' => (
    is      => 'rw',
    isa     => 'Maybe[IO::File]',
    default => sub {
        return IO::File->new( $CUFTS::Config::CUFTS_JQ_LOG, '>>' );
    },
);

has 'job_log_dir' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { $CUFTS::Config::CUFTS_JQ_JOBS_LOG_DIR },
);

#
# Map job types to modules
#

Readonly my $class_map => {
    'cjdb rebuild'             => 'CJDBRebuild',
    'global title list load'   => 'GlobalTitleListLoad',
    'global resource delete'   => 'GlobalResourceDelete',
    'local resource delete'    => 'LocalResourceDelete',
    'local title list load'    => 'LocalTitleListLoad',
    'local title list overlay' => 'LocalTitleListOverlay',
    'site delete'              => 'SiteDelete',
    'test'                     => 'Test',
};


sub BUILD {
    my $self = shift;

    # Check that the schemas are valid?
}

sub list_jobs {
    my ( $self, $filter, $options ) = @_;

    $options->{page}     ||=  1;
    $options->{rows}     ||= 25;
    $options->{order_by} ||= [ { -desc => 'run_after' }, { -desc => 'priority' }, { -desc => 'id' } ];

    my $jobs_rs = $self->job_schema->resultset('JobQueue')->search($filter, $options);
    my @jobs;
    foreach my $job ( $jobs_rs->all ) {
        push @jobs, $self->_create_job_obj( $job );
    }

    return(\@jobs, $jobs_rs->pager );
}

sub list_runnable_jobs {
    my ( $self, $filter, $options ) = @_;

    $filter->{status} = { -in => [ 'new', 'runnable' ] };

    return $self->list_jobs($filter, $options);
}


sub get_job {
    my ( $self, $id ) = @_;

    my $job = $self->job_schema->resultset('JobQueue')->find($id);
    if ( defined $job ) {
        return $self->_create_job_obj( $job );
    }

    return undef;
}

sub claim_next_job {
    my ( $self, $filter ) = @_;

    $filter->{status} = { '-IN' => [ qw( new runnable ) ] };

    my $job = $self->job_schema->resultset('JobQueue')->search( $filter, { order_by => [ { -desc => 'run_after' }, { -desc => 'priority' } ] } )->first;

    # It's possible we don't have a job to run.  This may need to change to return something more explicit so we can catch
    # errors as undef?

    return undef if !defined $job;

    # RACE CONDITION, WE NEED AN ATOMIC GET AND CLAIM HERE
    # SEE HOW THE SCHWARTZ DOES THIS AND DUPLICATE?

    $job->status('claimed');
    $job->claimed_by( $self->identifier );
    $job->update();

    my $job_obj = $self->_create_job_obj( $job );
    $job_obj->debug( 'Job claimed by: ' . $self->identifier );

    return $job_obj;
}

sub add_job {
    my ( $self, $job ) = @_;

    # This should move into the Job class, perhaps?

    # Validate job data

    foreach my $column ( qw( type class info ) ) {
        if ( !defined $job->{$column} ) {
            $self->add_error( "Missing required data when adding job: $column" );
        }
    }

    return undef if $self->has_errors;

    my $db_data = {
        type        => $job->{type},
        class       => $job->{class},
        info        => $job->{info},
        status      => 'new',
    };

    # Add standard optional fields, either passed in or from client defaults

    foreach my $field ( qw( account_id site_id priority global_resource_id local_resource_id ) ) {
        if ( defined $job->{$field} ) {
            $db_data->{$field} = $job->{$field};
        }
        elsif ( $self->can($field) && defined $self->$field ) {
            $db_data->{$field} = $self->$field;
        }
    }

    # Create job in queue

    my $job_db = $self->job_schema->resultset('JobQueue')->create($db_data);
    if ( !defined $job_db ) {
        $self->errors->push( 'Unable to create JobQueue database record.' );
        return undef;
    }

    # Add frozen field

    if ( defined $job->{data} ) {
        # $db_data->{data} = freeze($job->{data});
        $job_db->update({ data => $job->{data} });
    }

    my $job_obj = $self->_create_job_obj($job_db);

    $job_obj->log( 1, 'job added', 'Job added to queue.' );

    return $job_obj;
}

sub _create_job_obj {
    my ( $self, $db_obj ) = @_;

    my $class = $class_map->{$db_obj->class};
    if ( !defined $class ) {
        die('Unable to map job class from database class field: ' . $db_obj->class);
    }
    $class = "CUFTS::JQ::Job::$class";
    eval "require $class";
    if ( $@ ) {
        die($@);
    }

    return $class->new(
        queue       => $self,
        db_obj      => $db_obj,
        work_schema => $self->work_schema,
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
