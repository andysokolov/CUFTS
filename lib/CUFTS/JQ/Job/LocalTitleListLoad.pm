package CUFTS::JQ::Job::LocalTitleListLoad;

use strict;

use Moose;
use CUFTS::Config;
use String::Util qw( trim hascontent );

extends 'CUFTS::JQ::Job';

sub work {
    my $self = shift;

    $self->terminate_possible();

    my $resource = $self->work_schema->resultset('LocalResources')->find( $self->local_resource_id );
    return $self->fail( 'Unable to load local resource id ' . $self->local_resource_id ) if !defined $resource;

    my $file = $self->data->{file};
    return $self->fail( 'Title list file does not exist: ' . $self->data->{file} ) if !-e $file;

    eval {
        $self->start();

        $self->work_schema->txn_do( sub {
            $self->debug('Loaded local resource: ' . $resource->name);
            $self->checkpoint( 0, 'Starting to load title list' );

            my $results = $resource->do_module( 'load_title_list', $self->work_schema, $resource, $file, 1, $self );

            $self->checkpoint( 100, 'Finished loading from title list.' );

            my $account = $self->account;

            ##
            ## Email the person who submitted the job request.
            ##

            eval {

                my $email = $account->email;
                if ( hascontent($email) ) {
                    my $host = defined($CUFTS::Config::CUFTS_SMTP_HOST) ? $CUFTS::Config::CUFTS_SMTP_HOST : 'localhost';
                    my $smtp = Net::SMTP->new($host);
                    if ( defined $smtp ) {
                        $self->debug('Emailing notification to: ' . $account->name . ' at ' . $email);
                        $smtp->mail($CUFTS::Config::CUFTS_MAIL_FROM);
                        $smtp->to(split /\s*,\s*/, $email);
                        $smtp->data();
                        $smtp->datasend("To: $email\n");
                        $smtp->datasend("Subject: Updated local CUFTS list: " . $resource->name . "\n");
                        if ( defined $CUFTS::Config::CUFTS_MAIL_REPLY_TO ) {
                            $smtp->datasend("Reply-To: ${CUFTS::Config::CUFTS_MAIL_REPLY_TO}\n");
                        }
                        $smtp->datasend("\n");
                        $smtp->datasend('Resource: ' . $resource->name . "\n");
                        $smtp->datasend('Provider: ' . $resource->provider . "\n");
                        $smtp->datasend('Processed: ' . $results->{'processed_count'} . "\n");
                        $smtp->datasend('Errors: ' . $results->{'error_count'} . "\n");
                        $smtp->datasend('New: ' . $results->{'new_count'} . "\n");
                        $smtp->datasend('Modified: ' . $results->{'modified_count'} . "\n");
                        $smtp->datasend('Deleted: ' . $results->{'deleted_count'} . "\n");
                        foreach my $error (@{$results->{'errors'}}) {
                            $smtp->datasend("$error\n");
                        }
                        $smtp->datasend("-------\n");
                        $smtp->dataend();
                        $smtp->quit();
                    }
                    else {
                        warn('Unable to create Net::SMTP object.');
                        $self->error('Unable to create Net::SMTP object.');
                    }
                }
                else {
                    $self->notification('Account missing email address: ' . $account->name);
                }
            };
            if ( $@ ) {
                $self->error("Error sending notification email: $@");
            }

            my $printed_results = <<EOF;
Processed: $results->{processed_count}
Errors: $results->{error_count}
New: $results->{new_count}
Modified: $results->{modified_count}
Deleted: $results->{deleted_count}
EOF

            if ( defined $results->{errors} && scalar @{$results->{errors}} ) {
                $printed_results .= 'See raw log for error details.';
                foreach my $error (@{$results->{errors}}) {
                    $self->rawlog($error);
                }
            }

            $self->notification($printed_results);

            $self->finish('Completed title list load and notifications.');
        });
    };
    if ( $@ ) {
        if ( !$self->has_status('terminated') ) {
            $self->fail('Title load operation died: ' . $@);
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
