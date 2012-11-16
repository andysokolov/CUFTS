package SUSHI::SUSHITypes::Report;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(0);

sub get_xmlns { 'http://www.niso.org/schemas/counter' };

our $XML_ATTRIBUTE_CLASS = 'SUSHI::SUSHITypes::Report::_Report::XmlAttr';

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Vendor_of :ATTR(:get<Vendor>);
my %Customer_of :ATTR(:get<Customer>);

__PACKAGE__->_factory(
    [ qw(        Vendor
        Customer

    ) ],
    {
        'Vendor' => \%Vendor_of,
        'Customer' => \%Customer_of,
    },
    {
        'Vendor' => 'SUSHI::SUSHITypes::Vendor',

        'Customer' => 'SUSHI::SUSHITypes::Report::_Customer',
    },
    {

        'Vendor' => 'Vendor',
        'Customer' => 'Customer',
    }
);

} # end BLOCK




package SUSHI::SUSHITypes::Report::_Customer;
use strict;
use warnings;
{
our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(SUSHI::SUSHITypes::Customer);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Name_of :ATTR(:get<Name>);
my %ID_of :ATTR(:get<ID>);
my %Contact_of :ATTR(:get<Contact>);
my %WebSiteUrl_of :ATTR(:get<WebSiteUrl>);
my %LogoUrl_of :ATTR(:get<LogoUrl>);
my %Consortium_of :ATTR(:get<Consortium>);
my %InstitutionalIdentifier_of :ATTR(:get<InstitutionalIdentifier>);
my %ReportItems_of :ATTR(:get<ReportItems>);

__PACKAGE__->_factory(
    [ qw(        Name
        ID
        Contact
        WebSiteUrl
        LogoUrl
        Consortium
        InstitutionalIdentifier
        ReportItems

    ) ],
    {
        'Name' => \%Name_of,
        'ID' => \%ID_of,
        'Contact' => \%Contact_of,
        'WebSiteUrl' => \%WebSiteUrl_of,
        'LogoUrl' => \%LogoUrl_of,
        'Consortium' => \%Consortium_of,
        'InstitutionalIdentifier' => \%InstitutionalIdentifier_of,
        'ReportItems' => \%ReportItems_of,
    },
    {
        'Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'ID' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'Contact' => 'SUSHI::SUSHITypes::Contact',
        'WebSiteUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
        'LogoUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
        'Consortium' => 'SUSHI::SUSHITypes::Consortium',
        'InstitutionalIdentifier' => 'SUSHI::SUSHITypes::Identifier',
        'ReportItems' => 'SUSHI::SUSHITypes::ReportItem',
    },
    {

        'Name' => 'Name',
        'ID' => 'ID',
        'Contact' => 'Contact',
        'WebSiteUrl' => 'WebSiteUrl',
        'LogoUrl' => 'LogoUrl',
        'Consortium' => 'Consortium',
        'InstitutionalIdentifier' => 'InstitutionalIdentifier',
        'ReportItems' => 'ReportItems',
    }
);

} # end BLOCK






}



package SUSHI::SUSHITypes::Report::_Report::XmlAttr;
use base qw(SOAP::WSDL::XSD::Typelib::AttributeSet);

{ # BLOCK to scope variables

my %Created_of :ATTR(:get<Created>);
my %ID_of :ATTR(:get<ID>);
my %Version_of :ATTR(:get<Version>);
my %Name_of :ATTR(:get<Name>);
my %Title_of :ATTR(:get<Title>);

__PACKAGE__->_factory(
    [ qw(
        Created
        ID
        Version
        Name
        Title
    ) ],
    {

        Created => \%Created_of,

        ID => \%ID_of,

        Version => \%Version_of,

        Name => \%Name_of,

        Title => \%Title_of,
    },
    {
        Created => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
        ID => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        Version => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        Name => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        Title => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    }
);

} # end BLOCK



1;


=pod

=head1 NAME

SUSHI::SUSHITypes::Report

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Report from the namespace http://www.niso.org/schemas/counter.

An individual COUNTER Report. (See comments in the XSD for attribute definitions).




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Vendor


=item * Customer




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # SUSHI::SUSHITypes::Report
   Vendor => 
 # No documentation generated for complexContent / extension yet
,
   Customer =>  {
     ReportItems =>  { # SUSHI::SUSHITypes::ReportItem
       ItemIdentifier =>  { # SUSHI::SUSHITypes::Identifier
         Type => $some_value, # IdentifierType
         Value =>  $some_value, # string
       },
       ItemPlatform =>  $some_value, # string
       ItemPublisher =>  $some_value, # string
       ItemName =>  $some_value, # string
       ItemDataType => $some_value, # DataType
       ItemPerformance =>  { # SUSHI::SUSHITypes::Metric
         Period =>  { # SUSHI::SUSHITypes::DateRange
           Begin =>  $some_value, # date
           End =>  $some_value, # date
         },
         Category => $some_value, # Category
         Instance =>  { # SUSHI::SUSHITypes::PerformanceCounter
           MetricType => $some_value, # MetricType
           Count =>  $some_value, # nonNegativeInteger
         },
       },
     },
   },
 },



=head2 attr

NOTE: Attribute documentation is experimental, and may be inaccurate.
See the correspondent WSDL/XML Schema if in question.

This class has additional attributes, accessibly via the C<attr()> method.

attr() returns an object of the class SUSHI::SUSHITypes::Report::_Report::XmlAttr.

The following attributes can be accessed on this object via the corresponding
get_/set_ methods:

=over

=item * Created

 Date/time the report was created.



This attribute is of type L<SOAP::WSDL::XSD::Typelib::Builtin::dateTime|SOAP::WSDL::XSD::Typelib::Builtin::dateTime>.

=item * ID

 An identifier assigned by the application creating the message for tracking purposes.



This attribute is of type L<SOAP::WSDL::XSD::Typelib::Builtin::string|SOAP::WSDL::XSD::Typelib::Builtin::string>.

=item * Version

 The version of the COUNTER report.



This attribute is of type L<SOAP::WSDL::XSD::Typelib::Builtin::string|SOAP::WSDL::XSD::Typelib::Builtin::string>.

=item * Name

 The short name of the report as would be defined in the SUSHI::SUSHI request. See the reports registry at http://www.niso.org/workrooms/sushi/reports 



This attribute is of type L<SOAP::WSDL::XSD::Typelib::Builtin::string|SOAP::WSDL::XSD::Typelib::Builtin::string>.

=item * Title

 The COUNTER report name, e.g. Journal Report 1. See the reports registry at http://www.niso.org/workrooms/sushi/reports



This attribute is of type L<SOAP::WSDL::XSD::Typelib::Builtin::string|SOAP::WSDL::XSD::Typelib::Builtin::string>.


=back




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

