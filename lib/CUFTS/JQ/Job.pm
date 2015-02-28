package CUFTS::JQ::Job;

use Readonly;
use IO::File;

use Moose;

has db_obj => (
    is => 'ro',
    isa => 'DBIx::Class::Row',
    handles => [ qw(
        id
        type
        info
        site
        site_id
        account
        account_id
        global_resource
        global_resource_id
        local_resource
        local_resource_id
        completion
        claimed_by
        priority
        created
        modified
        data
        update
    ) ],
);

has queue => (
    is => 'ro',
    isa => 'CUFTS::JQ::Client',
    handles => {
        'client_identifier' => 'identifier',
    },
    # weak_ref => 1,
);

has work_schema => (
    is => 'rw',
    isa => 'Maybe[CUFTS::Schema]',
);

has log_fh => (
    is => 'rw',
    isa => 'Maybe[IO::File]',
    default => sub {
        my $self = shift;
        my $file = $self->queue->job_log_dir . '/' . $self->id . '.log';
        return IO::File->new( $file, '>>' );
    },
    lazy => 1,
);

has output_fh => (
    is => 'rw',
    isa => 'GlobRef',
    default => sub {
        my $self = shift;
        my $file = $self->queue->job_log_dir . '/' . $self->id . '.out';
        open( OUT, ">>$file" );
        return \*OUT;
        # return IO::File->new( $file, '>>' );
    },
    lazy => 1,
);

Readonly my $valid_statuses => [ qw(
    new
    runnable
    claimed
    working
    completed
    terminate
    terminated
    failed
)];

sub valid_statuses {
    return $valid_statuses;
}

sub status {
    my ( $self, $status ) = @_;

    return $self->db_obj->status if !$status;

    die("Invalid status: $status") if !grep { $status eq $_ } @$valid_statuses;
    $self->db_obj->status($status);

    return $status;
}

sub has_status {
    my $status = shift->status;
    return !! grep { $_ eq $status } @_;
}

sub job_schema {
    return shift->db_obj->result_source->schema;
}

sub start {
    my ( $self, $message ) = @_;

    $self->log( 1, 'status', $message || 'Job work started' );

    $self->status('working');
    $self->update;

    return $self;
}

sub fail {
    my ( $self, $message ) = @_;

    $self->log( 2, 'error', $message || 'Job registered failure from client: ' . $self->client_identifier );

    $self->status('failed');
    $self->claimed_by(undef);
    $self->update;

    return $self;
}

sub finish {
    my ( $self, $message ) = @_;

    $self->log( 1, 'status', $message || 'Job completed.' );

    $self->status('completed');
    $self->claimed_by(undef);
    $self->update;

    $self->reschedule();

    return $self;
}

sub reschedule {
    my $self = shift;

    # Clone this job to reschedule it if required.

    if ( $self->db_obj->reschedule_hours ) {
        my $new_job_data = {
            map { $_ => $self->db_obj->$_ } qw( type class info account_id site_id priority data )
        };
        my $new_job = $self->queue->add_job( $new_job_data );

        if ( defined $new_job ) {
            $self->log('Job rescheduled for ' . $new_job->run_after->ymd . ' ' . $new_job->run_after->hms)
        }
        else {
            $self->log('Job reschedule attempt failed to create a new job.');
        }
    }

}


sub can_terminate {
    return shift->has_status( qw( new runnable claimed working ) );
}

# This is used to set the job flag to terminate. It does not actually terminate the job (see terminate_possible)

sub terminate {
    my ( $self, $message ) = @_;

    $self->log( 1, 'status', $message || 'Job marked to terminate.' );

    my $terminate_now = $self->has_status( 'new', 'runnable' );

    $self->status('terminate');
    $self->update;

    eval { $self->terminate_possible if $terminate_now };

    return $self;
}

# This should be called occassionally through possibly long running jobs. It checks the jobs status, cleans up
# then dies.

sub terminate_possible {
    my ( $self, $message ) = @_;

    return if !$self->has_status('terminate');

    $self->log( 1, 'status', $message || 'Job terminated.' );

    $self->status('terminated');
    $self->claimed_by(undef);
    $self->update;

    $self->terminate_cleanup();

    die('job terminated');
}

# Virtual method for work that needs a cleanup before finally dieing on termination

sub terminate_cleanup {}


sub checkpoint {
    my ( $self, $pct, $message ) = @_;

    $pct = int($pct);

    $self->db_obj->completion($pct);
    $self->db_obj->update_checkpoint_timestamp();
    $self->db_obj->update;

    # Also a good time to update the job from the database in case the status has been changed
    $self->db_obj->discard_changes();

    if ( !$message ) {
        $message = 'Job registered checkpoint';
    }

    $self->log( 1, 'checkpoint', "${pct}%: ${message}" );
}

sub running_checkpoint {
    my ( $self, $count, $max, $start, $range, $message, $force_checkpoint ) = @_;

    return if $max == 0; # Avoid divide by 0

    my $checkpoint = int( ( $count / $max ) * $range ) + $start;  # start to ($start+range)

    if ( $force_checkpoint || $checkpoint > $self->completion ) {
        $self->checkpoint( $checkpoint, $message );
    }

}

sub rawlog {
    my ( $self, $level, $type, $message ) = @_;

    my $fh = $self->log_fh;
    return if !defined $fh;

    $message =~ s/\n(.)/\n\t\t$1/g;  # prepend double tabs to new lines for a bit better formatting

    my $line = join "\t", DateTime->now()->iso8601(), $level, $type, $message;
    $line .= "\n" if $line !~ /\n$/xsm;

    print $fh $line;
    $fh->flush();
}

sub error {
    my ( $self, $message ) = @_;
    $self->log( 2, 'error', $message );
}

sub notification {
    my ( $self, $message ) = @_;
    $self->log( 1, 'notification', $message );
}

sub debug {
    my ( $self, $message ) = @_;
    $self->log( 0, 'debug', $message );
}

#
# Level: 0 - debug, 1 - notification, 2 - error
#

sub log {
    my ( $self, $level, $type, $message ) = @_;

    if ( !defined $level || !defined $type || !defined $message ) {
        return $self->log( 0, 'debug', 'Bad call to log missing data from caller: ' . join(', ', caller) );
    }

    # Write a rawlog entry if possible before trying a database log

    $self->rawlog($level, $type, $message);

    # TODO: Add validation of data?

    my $db_data = {
        job_id              => $self->id,
        level               => $level,
        type                => $type,
        message             => $message,
        client_identifier   => $self->client_identifier,
    };

    # Add standard optional fields

    foreach my $field ( qw( account_id site_id  ) ) {
        $db_data->{$field} = $self->$field if defined($self->$field );
    }

    my $row;
    $self->job_schema->txn_do( sub {
        $row = $self->job_schema->resultset('JobQueueLog')->create($db_data);
    });

    if ( !defined $row ) {
        warn('Unable to write to JobQueueLog');
        return 0;
    }

    return 1;
}

sub get_logs {
    my ( $self, $filter, $options ) = @_;

    $options->{page}     ||= 1;
    $options->{rows}     ||= 30;
    $options->{order_by}   = [ { '-desc' => 'id' } ];

    my $logs_rs = $self->db_obj->logs( $filter, $options );

    return [ $logs_rs->all ], $logs_rs->pager;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
