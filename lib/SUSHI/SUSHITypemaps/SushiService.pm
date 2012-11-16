package SUSHI::SUSHITypemaps::SushiService;
use strict;
use warnings;

our $typemap_1 = {
       'Fault' => 'SOAP::WSDL::SOAP::Typelib::Fault11',
       'Fault/detail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'Fault/faultactor' => 'SOAP::WSDL::XSD::Typelib::Builtin::token',
       'Fault/faultcode' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
       'Fault/faultstring' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportRequest' => 'SUSHI::SUSHIElements::ReportRequest',
       'ReportRequest/CustomerReference' => 'SUSHI::SUSHITypes::CustomerReference',
       'ReportRequest/CustomerReference/ID' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportRequest/CustomerReference/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportRequest/ReportDefinition' => 'SUSHI::SUSHITypes::ReportDefinition',
       'ReportRequest/ReportDefinition/Filters' => 'SUSHI::SUSHITypes::ReportDefinition::_Filters',
       'ReportRequest/ReportDefinition/Filters/UsageDateRange' => 'SUSHI::SUSHITypes::Range',
       'ReportRequest/ReportDefinition/Filters/UsageDateRange/Begin' => 'SOAP::WSDL::XSD::Typelib::Builtin::date',
       'ReportRequest/ReportDefinition/Filters/UsageDateRange/End' => 'SOAP::WSDL::XSD::Typelib::Builtin::date',
       'ReportRequest/Requestor' => 'SUSHI::SUSHITypes::Requestor',
       'ReportRequest/Requestor/Email' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportRequest/Requestor/ID' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportRequest/Requestor/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse' => 'SUSHI::SUSHIElements::ReportResponse',
       'ReportResponse/CustomerReference' => 'SUSHI::SUSHITypes::CustomerReference',
       'ReportResponse/CustomerReference/ID' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/CustomerReference/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Exception' => 'SUSHI::SUSHITypes::Exception',
       'ReportResponse/Exception/Data' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyType',
       'ReportResponse/Exception/HelpUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
       'ReportResponse/Exception/Message' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Exception/Number' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
       'ReportResponse/Exception/Severity' => 'SUSHI::SUSHITypes::ExceptionSeverity',
       'ReportResponse/Report' => 'SUSHI::SUSHITypes::Reports',
       'ReportResponse/Report/Report' => 'SUSHI::SUSHITypes::Report',
       'ReportResponse/Report/Report/Customer' => 'SUSHI::SUSHITypes::Report::_Customer',
       'ReportResponse/Report/Report/Customer/Consortium' => 'SUSHI::SUSHITypes::Consortium',
       'ReportResponse/Report/Report/Customer/Consortium/Code' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/Consortium/WellKnownName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/Contact' => 'SUSHI::SUSHITypes::Contact',
       'ReportResponse/Report/Report/Customer/Contact/Contact' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/Contact/E-mail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/ID' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/InstitutionalIdentifier' => 'SUSHI::SUSHITypes::Identifier',
       'ReportResponse/Report/Report/Customer/InstitutionalIdentifier/Type' => 'SUSHI::SUSHITypes::IdentifierType',
       'ReportResponse/Report/Report/Customer/InstitutionalIdentifier/Value' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/LogoUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
       'ReportResponse/Report/Report/Customer/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/ReportItems' => 'SUSHI::SUSHITypes::ReportItem',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemDataType' => 'SUSHI::SUSHITypes::DataType',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemIdentifier' => 'SUSHI::SUSHITypes::Identifier',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemIdentifier/Type' => 'SUSHI::SUSHITypes::IdentifierType',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemIdentifier/Value' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPerformance' => 'SUSHI::SUSHITypes::Metric',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPerformance/Category' => 'SUSHI::SUSHITypes::Category',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPerformance/Instance' => 'SUSHI::SUSHITypes::PerformanceCounter',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPerformance/Instance/Count' => 'SOAP::WSDL::XSD::Typelib::Builtin::nonNegativeInteger',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPerformance/Instance/MetricType' => 'SUSHI::SUSHITypes::MetricType',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPerformance/Period' => 'SUSHI::SUSHITypes::DateRange',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPerformance/Period/Begin' => 'SOAP::WSDL::XSD::Typelib::Builtin::date',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPerformance/Period/End' => 'SOAP::WSDL::XSD::Typelib::Builtin::date',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPlatform' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/ReportItems/ItemPublisher' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Customer/WebSiteUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
       'ReportResponse/Report/Report/Vendor' => 'SUSHI::SUSHITypes::Vendor',
       'ReportResponse/Report/Report/Vendor/Contact' => 'SUSHI::SUSHITypes::Contact',
       'ReportResponse/Report/Report/Vendor/Contact/Contact' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Vendor/Contact/E-mail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Vendor/ID' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Vendor/LogoUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
       'ReportResponse/Report/Report/Vendor/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Report/Report/Vendor/WebSiteUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
       'ReportResponse/ReportDefinition' => 'SUSHI::SUSHITypes::ReportDefinition',
       'ReportResponse/ReportDefinition/Filters' => 'SUSHI::SUSHITypes::ReportDefinition::_Filters',
       'ReportResponse/ReportDefinition/Filters/UsageDateRange' => 'SUSHI::SUSHITypes::Range',
       'ReportResponse/ReportDefinition/Filters/UsageDateRange/Begin' => 'SOAP::WSDL::XSD::Typelib::Builtin::date',
       'ReportResponse/ReportDefinition/Filters/UsageDateRange/End' => 'SOAP::WSDL::XSD::Typelib::Builtin::date',
       'ReportResponse/Requestor' => 'SUSHI::SUSHITypes::Requestor',
       'ReportResponse/Requestor/Email' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Requestor/ID' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
       'ReportResponse/Requestor/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
};

sub get_class {
  my $name = join '/', @{ $_[1] };
  return $typemap_1->{ $name };
}

sub get_typemap {
    return $typemap_1;
}

1;

__END__

=pod

=head1 NAME

SUSHI::SUSHITypemaps::SushiService - typemap for SushiService

=head1 DESCRIPTION

Typemap created by SOAP::WSDL for map-based SOAP message parsers.

=cut

