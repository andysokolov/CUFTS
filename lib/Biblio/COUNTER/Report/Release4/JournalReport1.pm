package Biblio::COUNTER::Report::Release4::JournalReport1;

use strict;
use warnings;

use Biblio::COUNTER::Report qw(REQUESTS MAY_BE_BLANK NOT_BLANK);

@Biblio::COUNTER::Report::Release4::JournalReport1::ISA = qw(Biblio::COUNTER::Report);

sub canonical_report_name { 'Journal Report 1 (R4)' }
sub canonical_report_description { 'Number of Successful Full-Text Article Requests by Month and Journal' };
sub canonical_report_code { 'JR1' }
sub release_number { 4 }

sub process_header_rows {
    my ($self) = @_;

    # Report name and title
    $self->begin_row
         ->check_report_name
         ->check_report_description
         ->end_row;

    # Report Customer
    $self->begin_row
         ->check_report_customer
         ->end_row;

    # Report Institution
    $self->begin_row_optional
         ->check_report_institution
         ->end_row;

    # Date run label
    $self->begin_row
         ->check_label('Period covered by Report:')
         ->end_row;

    # Report Start/End
    $self->begin_row
         ->check_report_period_covered
         ->end_row;

    # Date run label
    $self->begin_row
         ->check_label('Date run:')
         ->end_row;

    # Date run
    $self->begin_row
         ->check_date_run
         ->end_row;

    # Data column labels
    $self->begin_row
         ->check_label('Journal',                 qr/^(?i)journal/)
         ->check_label('Publisher',               qr/^(?i)pub/)
         ->check_label('Platform',                qr/^(?i)plat/)
         ->check_label('Journal DOI',             qr/(?i)doi/)
         ->check_label('Proprietary Identifier',  qr/(?i)ident/)
         ->check_label('Print ISSN',              qr/^(?i)print\s+issn/)
         ->check_label('Online ISSN',             qr/^(?i)online\s+issn/)
         ->check_label('Reporting Period Total',  qr/^(?i)reporting\s+period\s+total/)
         ->check_label('Reporting Period HTML',   qr/^(?i)reporting\s+period\s+html/)
         ->check_label('Reporting Period PDF',    qr/^(?i)reporting\s+period\s+pdt/)
         ->check_period_labels
         ->end_row;

    # Data summary
    $self->begin_row
         ->check_label('Total for all journals', qr/^(?i)total\s+for\s+all\s+journals/)
         ->check_publisher(MAY_BE_BLANK)
         ->check_platform(MAY_BE_BLANK)
         ->check_blank
         ->check_blank
         ->check_blank
         ->check_blank
         ->check_ytd_total(REQUESTS)
         ->check_ytd_html(REQUESTS)
         ->check_ytd_pdf(REQUESTS)
         ->check_count_by_periods(REQUESTS)
         ->end_row;

}

sub process_record {
    my ($self) = @_;
    $self->begin_row
         ->check_title(NOT_BLANK)
         ->check_publisher(MAY_BE_BLANK)
         ->check_platform(NOT_BLANK)
         ->check_doi(MAY_BE_BLANK)
         ->check_identifier(MAY_BE_BLANK)
         ->check_print_issn
         ->check_online_issn
         ->check_ytd_total
         ->check_ytd_html
         ->check_ytd_pdf
         ->check_count_by_periods(REQUESTS)
         ->end_row;
}


sub begin_row_optional {
    my ($self) = @_;
    $self->trigger_callback('begin_row');
    my $row = $self->_read_next_row;
    my $row_str = join('', @$row);
    return $self;
}


1;

=pod

=head1 NAME

Biblio::COUNTER::Report::Release4::JournalReport1 - a JR1 (R4) COUNTER report

=head1 SYNOPSIS

    $report = Biblio::COUNTER::Report::Release4::JournalReport1->new(
        'file' => $file,
    );
    $report->process;

=cut
