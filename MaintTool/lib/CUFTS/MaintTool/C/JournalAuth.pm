package CUFTS::MaintTool::C::JournalAuth;

use strict;
use base 'Catalyst::Base';
use MARC::Record;
use CUFTS::Util::Simple;
use CUFTS::JournalsAuth;
use CUFTS::CJDB::Util;

my $marc_fields = {
    '022' => {
               subfields => [ qw(a) ],
               size      => [ 10 ],
               repeats   => 1,
             },
    '050' => {
               subfields => [ qw(a) ],
               size      => [ 10 ],
               repeats   => 1,
             },
    '110' => {
               subfields => [ qw(a b c) ],
               size      => [ 40, 40 , 10 ],
               repeats   => 0,
             },
    '210' => {
               subfields => [ qw(a) ],
               size      => [ 40 ],
               repeats   => 1,
             },
    '222' => {
               subfields => [ qw(a b) ],
               size      => [ 40, 40 ],
               repeats   => 1,
             },
    '245' => {
               indicators => [ 2 ],
               subfields  => [ qw(a b c n p) ],
               size       => [ 40, 40, 10, 10, 10 ],
               repeats    => 0,
             },
    '246' => {
               subfields => [ qw(a b n p) ],
               size      => [ 40, 40, 10, 10 ],
               repeats   => 1,
             },
    '260' => {
               subfields => [ qw(a b) ],
               size      => [ 40, 40 ],
               repeats   => 1,
             },
    '310' => {
                subfields => [ qw(a b) ],
                size      => [ 40, 40 ],
                repeats   => 0,
             },
    '321' => {
                subfields => [ qw(a b) ],
                size      => [ 40, 40 ],
                repeats   => 1,
             },
    '362' => {
                subfields => [ qw(a z) ],
                size      => [ 40, 40 ],
                repeats   => 1,
             },
    '650' => {
               subfields => [ qw(a b z0 z1 y0 y1 x0 x1 x2 x3 v) ],
               size      => [ 30, 30, 10, 10, 10, 10, 10 ],
               repeats   => 1,
             },
    '710' => {
               subfields => [ qw(a b c) ],
               size      => [ 40, 40, 10 ],
               repeats   => 1,
             },
    '780' => {
               subfields => [ qw(a s t x) ],
               size      => [ 40, 10, 40, 10 ],
               repeats   => 1,
             },
    '785' => {
               subfields => [ qw(a s t x) ],
               size      => [ 40, 10, 40, 10 ],
               repeats   => 1,
             },
};

my $form_validate_create = {
    required => [ 'title', 'create' ],
    optional => [ 'issn1', 'issn2', 'confirm' ],
    filters  => [ 'trim' ],
    missing_optional_valid => 1,
};

my $form_validate_search = {
    optional => [
        'string', 'field', 'search', 'cancel',
    ],
    filters => ['trim'],
    missing_optional_valid => 1,
};

my $form_validate_marc = {
    optional => [
        'save', 'cancel',
    ],
    optional_regexp => qr/^\d+-\d{3}/,
    filters => ['trim'],
};

my $form_validate_marc_upload = {
    optional    => [ 'upload' ],
    dependency_groups => {
        data_upload => [ 'upload', 'upload_data' ],
    },
};

my $form_validate_merge = {
    required => [ 'merge_records', 'merge', 'merge_to' ],
};


sub auto : Private {
    my ($self, $c, $resource_id) = @_;

    $c->stash->{current_account}->{journal_auth} || $c->stash->{current_account}->{administrator} or
        die('User not authorized for journal auth maintenance');

    $c->stash->{header_section} = 'Journal Auth';
    push( @{ $c->stash->{load_css} }, 'journal_auth.css' );

    return 1;
}

sub create : Local {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{create} ) {
        $c->form($form_validate_create);

        $c->stash->{title} = $c->form->valid->{title};
        $c->stash->{issn1} = $c->form->valid->{issn1};
        $c->stash->{issn2} = $c->form->valid->{issn2};

        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my @records;
            if ( !$c->form->valid->{confirm} ) {
                # Check for existing similar records

                push @records, CUFTS::DB::JournalsAuth->search_by_title($c->form->valid->{title});
                if ( $c->form->valid->{issn1} ) {
                    push @records, CUFTS::DB::JournalsAuth->search_by_issns($c->form->valid->{issn1});
                }
                if ( $c->form->valid->{issn2} ) {
                    push @records, CUFTS::DB::JournalsAuth->search_by_issns($c->form->valid->{issn2});
                }

                if ( scalar(@records) > 0 ) {
                    $c->stash->{records} = \@records;
                }
            }

            if ( $c->form->valid->{confirm} || !scalar(@records) ) {
                # User has confirmed new record, or no close matches were found

                my $ja = CUFTS::DB::JournalsAuth->create({title => $c->form->valid->{title}});
                $ja->add_to_titles({title => $c->form->valid->{title}});

                foreach my $field ( 'issn1', 'issn2' ) {

                    if ( not_empty_string($c->form->valid->{$field}) ) {
                        my $issn = $c->form->valid->{$field};
                        if ( $issn =~ / (\d{4}) -? (\d{3}[\dxX]) /xsm ) {
                            $ja->add_to_issns({
                                issn  => uc("$1$2"),
                                info  => 'New from form',
                            });
                        } else {
                            push @{$c->stash->{errors}}, "Invalid ISSN: $issn";
                        }
                    }

                }

                if ( defined($c->stash->{errors}) ) {
                    CUFTS::DB::DBI->dbi_rollback();
                } else {
                    CUFTS::DB::DBI->dbi_commit();
                    return $c->redirect('/journalauth/search?search=sesarch&field=ids&string=' . $ja->id);
                }

            }

        }

    }

    $c->stash->{template} = 'journalauth/create.tt';
}

sub search : Local {
    my ($self, $c) = @_;

    if ($c->req->params->{search}) {
        $c->form($form_validate_search);

        if ($c->form->valid->{string}) {
            my @records;
            if ($c->form->valid->{field} eq 'title') {
                @records = CUFTS::DB::JournalsAuth->search_by_title($c->form->valid->{string} . '%');
            } elsif ($c->form->valid->{field} eq 'official_title') {
                @records = CUFTS::DB::JournalsAuth->search_like('title' => $c->form->valid->{string});
            } elsif ($c->form->valid->{field} eq 'issn') {
                @records = CUFTS::DB::JournalsAuth->search_by_issns($c->form->valid->{string});
            } elsif ($c->form->valid->{field} eq 'ids') {
                my @ids = split /\s+/,  $c->form->valid->{string};
                @records = CUFTS::DB::JournalsAuth->search( { 'id' => {'in' => \@ids} } );
            }
            $c->stash->{journal_auths} = \@records;

            # Stash search field/string for display on search box and into the session for

            $c->session->{journal_auth_search_field} = $c->stash->{field} = $c->form->valid->{field};
            $c->session->{journal_auth_search_string} = $c->stash->{string} = $c->form->valid->{string};
        }
    } elsif ($c->req->params->{cancel}) {
        $c->redirect('/main');
    }

    $c->stash->{template} = 'journalauth/search.tt';
}

sub edit : Local {
    my ($self, $c, $journal_auth_id) = @_;

    my $form_validate_edit = {
        optional => [
            'save', 'cancel', 'title', 'rss'
        ],
        optional_regexp => qr/_(issn|info|title|count)$/,
        filters => ['trim'],
    };

    my $journal_auth = CUFTS::DB::JournalsAuth->retrieve($journal_auth_id);

    $c->form($form_validate_edit);

    if ( $c->form->valid->{cancel} ) {
        return $c->forward('/journalauth/done_edits');
    }
    if ( $c->form->valid->{save} ) {
        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {
        eval {
                $journal_auth->title($c->form->valid->{'title'});
                $journal_auth->rss($c->form->valid->{'rss'});
                $journal_auth->update();

                $journal_auth->issns->delete_all;
                foreach my $param ( keys %{$c->form->valid} ) {
                    next if $param !~ / ^(.+)_issn $/xsm;

                    my $prefix = $1;
                    my $value  = $c->form->valid->{$param};

                    next if is_empty_string($value);
                    if ($value =~ / (\d{4}) -? (\d{3}[\dxX]) /xsm ) {
                        $journal_auth->add_to_issns({
                            issn  => uc("$1$2"),
                            info  => $c->form->valid->{"${prefix}_info"}
                        });
                    } else {
                        push @{$c->stash->{errors}}, "Invalid ISSN: $value";
                    }
                }

                $journal_auth->titles->delete_all;
                foreach my $param ( keys %{$c->form->valid} ) {
                    next if $param !~ / ^(.+)_title $/xsm;

                    my $prefix = $1;
                    my $value  = $c->form->valid->{$param};

                    next if is_empty_string($value);

                    $journal_auth->add_to_titles({
                            title       => $value,
                            title_count => $c->form->valid->{"${prefix}_count"}
                    });
                }

            };
            if ($@) {
                push @{$c->stash->{errors}}, $@;
            }
            if ( defined($c->stash->{errors}) ) {
                CUFTS::DB::DBI->dbi_rollback();

                # See if there's any "new" fields that need to be added

                foreach my $param ( keys %{$c->form->valid} ) {
                    if ( $param =~ / new(\d+)_issn /xsm ) {
                        if ( $1 > $c->stash->{max_issn_field} ) {
                            $c->stash->{max_issn_field} = $1;
                        }
                    }
                    if ( $param =~ / new(\d+)_title /xsm ) {
                        if ( $1 > $c->stash->{max_title_field} ) {
                            $c->stash->{max_title_field} = $1;
                        }
                    }
                }

            } else {
                CUFTS::DB::DBI->dbi_commit;
                return $c->forward('/journalauth/done_edits');
            }
        }
    }

    $c->stash->{max_title_field} ||= 0;
    $c->stash->{max_issn_field}  ||= 0;

    $c->stash->{load_javascript} = 'journal_auth.js';
    $c->stash->{journal_auth}    = $journal_auth;
    $c->stash->{template}        = 'journalauth/edit.tt';
}


sub edit_marc : Local {
    my ($self, $c, $journal_auth_id) = @_;

    my $journal_auth = CUFTS::DB::JournalsAuth->retrieve($journal_auth_id);

    if ($c->req->params->{cancel}) {
        return $c->forward('/journalauth/done_edits');
    }
    if ($c->req->params->{save}) {

        $c->form($form_validate_marc);
        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my @fields;
            foreach my $field_type (sort keys %$marc_fields) {
                my $row = 0;
                $c->stash->{max_seen_fields}->{$field_type} = -1;

                while ($c->form->valid->{"${row}-${field_type}-exists"}) {
                    my @subfields;
                    my $indicators = [];

                    foreach my $subfield (@{$marc_fields->{$field_type}->{subfields}}) {
                        my $value = $c->form->valid->{"${row}-${field_type}${subfield}"};
                        next unless defined($value) && $value ne '';
                        $value = CUFTS::CJDB::Util::latin1_to_marc8($value);
                        my $subfield_indicator = substr( $subfield, 0, 1);  # Grab the real subfield indicator for the MARC record
                        push @subfields, ($subfield_indicator, $value);
                    }
                    $indicators->[0] = $c->form->valid->{"${row}-${field_type}-1"};
                    $indicators->[1] = $c->form->valid->{"${row}-${field_type}-2"};
                    $row++;

                    next unless scalar(@subfields);  # Don't save blank fields, they're to be "deleted"

                    $c->stash->{max_seen_fields}->{$field_type} = $row;

                    my $field;
                    eval { $field = MARC::Field->new($field_type, @$indicators, @subfields); };
                    if ($@) {
                        warn($@);
                        push @{$c->stash->{errors}}, $@;
                    } else {
                        push @fields, $field;
                    }
                }
            }

            if (!defined($c->stash->{errors})) {
                my $record;
                eval {
                    $record = new MARC::Record();
                    $record->append_fields(@fields);
                };
                if ($@) {
                    CUFTS::DB::DBI->dbi_rollback();
                    push @{$c->stash->{errors}}, "Error creating MARC record: $@";
                } else {
                    $journal_auth->marc($record->as_usmarc());
                    $journal_auth->update();
                    CUFTS::DB::JournalsAuth->dbi_commit();
                    return $c->forward('/journalauth/done_edits');
                }
            }
        }
    }

    $c->stash->{marc_fields} = $marc_fields;
    $c->stash->{load_javascript} = 'journal_auth.js';
    $c->stash->{journal_auth} = $journal_auth;
    $c->stash->{template} = 'journalauth/edit_marc.tt';
}

sub done_edits : Local {
    my ($self, $c) = @_;

    $c->req->params({
        'field'  => $c->session->{journal_auth_search_field},
        'string' => $c->session->{journal_auth_search_string},
        'search' => 'search',
    });
    return $c->forward('/journalauth/search');
}

sub marc_file : Local {
    my ( $self, $c, $journal_auth_id) = @_;

    my $journal_auth = CUFTS::DB::JournalsAuth->retrieve($journal_auth_id);

    if ( $c->req->params->{upload} ) {

        $c->form($form_validate_marc_upload);
        unless ($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) {

            my $marc_string = $c->request->upload('upload_data')->slurp();
            my $record;

            eval {
                $record = MARC::Record->new_from_usmarc($marc_string);
                if ( !scalar($record->fields) ) {
                    push @{$c->stash->{errors}}, 'No fields loaded, please ensure the uploaded file is in MARC communications format.';
                }
            };
            if ($@) {
                push @{$c->stash->{errors}}, "Error creating MARC record: $@";
            }

            if ( defined($c->stash->{errors}) && scalar(@{$c->stash->{errors}}) ) {
                CUFTS::DB::DBI->dbi_rollback();
            } else {
                $journal_auth->marc($record->as_usmarc());
                $journal_auth->update();
                CUFTS::DB::JournalsAuth->dbi_commit();
                return $c->forward('/journalauth/done_edits');
            }
        }
    }

    $c->stash->{journal_auth} = $journal_auth;
    $c->stash->{template} = 'journalauth/marc_file.tt';
}

sub marc_download : Local {
    my ( $self, $c, $journal_auth_id) = @_;

    my $journal_auth = CUFTS::DB::JournalsAuth->retrieve($journal_auth_id);
    $c->res->content_type( 'application/marc' );
    $c->res->headers->push_header( 'Content-Disposition' => "attachment; filename=\"${journal_auth_id}.mrc\"" );
    $c->res->body( $journal_auth->marc );
}


sub merge : Local {
    my ($self, $c) = @_;
    $c->form($form_validate_merge);

    if ( !($c->form->has_missing || $c->form->has_invalid || $c->form->has_unknown) ) {

        my $ids = $c->form->valid->{merge};
        my $merge_to = $c->form->valid->{merge_to};

        $ids = ref($ids) eq 'ARRAY' ? $ids : [ $ids ];

        $ids = [ grep { $_ != $merge_to } @$ids ];
        unshift( @$ids, $merge_to );

        my $schema = $c->model('CUFTS')->schema;

        if ( scalar(@$ids) < 2 ) {
            push @{$c->stash->{errors}}, "You must select multiple records to merge.";
        }
        else {
            my $merged_ja;
            eval {
                $schema->txn_do( sub {
                    $merged_ja = CUFTS::JournalsAuth->merge($schema, @$ids);
                });
            };
            if ($@) {
                push @{$c->stash->{errors}}, "Error merging records: $@";
            }
            else {
                return $c->redirect("/journalauth/search?search=search&field=ids&string=" . $merged_ja->id);
            }
        }
    }
    else {
        push @{$c->stash->{errors}},'You must select at least one record to merge and specify a record to merge to.';
    }

    return $c->forward('/journalauth/done_edits');
}

1;
