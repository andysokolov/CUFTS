package CUFTS::CJDB::ILSAccount::III;

use URI::Escape;
use LWP::UserAgent;

use Class::Accessor;

use strict;

#__PACKAGE__->mk_accessors(qw(level name barcode email site));

sub new {
	my ($class, $site, $barcode) = @_;
	
	my $self = bless {}, $class;
	if (defined($site) && defined($barcode)) {
		$self->init($site->cjdb_patron_site, $site->cjdb_patron_port, $barcode);
	}
	
	return $self;
}


sub init {
	my ($self, $host, $port, $barcode) = @_;

	my $url = $self->url($host, $port, $barcode);
	
	my $ua = new LWP::UserAgent;
	my $request = new HTTP::Request GET => $url;
	$request->header('Accept' => 'text/html');
	my $res = $ua->request($request);
	
	$res->is_success or
		die("Failed request - $url - " . $res->message . "(" . $res->message . ") - ");
		
	my $web_page = $res->content;

	warn($web_page);
	
	$web_page = &pl_str::trim_beg_end($web_page);
	return split(/<BR>/i, $web_page);
}

sub url {
	my ($self, $host, $port, $barcode) = @_;

	return("http://${host}:${port}/PATRONAPI/" . URI::Escape::uri_escape($barcode) .  "/dump");
}
	

1;















