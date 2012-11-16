package CUFTS::CJDB::Model::CDBI;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use CUFTS::DB::DBI;

use CUFTS::DB::Accounts;
use CUFTS::DB::Sites;

use CUFTS::DB::Resources;

use CUFTS::DB::Journals;
use CUFTS::DB::JournalsActive;

use CJDB::DB::DBI;

use CJDB::DB::Accounts;
use CJDB::DB::Associations;
use CJDB::DB::Journals;
use CJDB::DB::LCCSubjects;
use CJDB::DB::Links;
use CJDB::DB::Subjects;
use CJDB::DB::Titles;
use CJDB::DB::Tags;

=head1 NAME

CUFTS::CJDB::Model::CDBI - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

tholbroo

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
