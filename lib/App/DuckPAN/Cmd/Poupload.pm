package App::DuckPAN::Cmd::Poupload;
# ABSTRACT: Command for uploading .po files to the DuckDuckGo Community Platform

use Moo;
with qw( App::DuckPAN::Cmd );

use MooX::Options protect_argv => 0;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use Dist::Zilla::Util;

option domain => (
	is => 'ro',
	format => 's',
	predicate => 1,
	doc => 'set token domain in upload',
);

option upload_uri => (
	is => 'ro',
	format => 's',
	lazy => 1,
	builder => 1,
	doc => 'URI for token uploads. defaults to "https://duck.co/translate/po/upload"',
);

sub _build_upload_uri { 'https://duck.co/translate/po/upload' }

sub get_request {
	my ( $self, $file ) = @_;
	my ( $user, $pass ) = $self->app->ddg->get_dukgo_user_pass;
	my $req = POST(
		$self->upload_uri,
		Content_Type => 'form-data',
		Content => {
			CAN_MULTIPART => 1,
			HIDDENNAME => $user,
			po_upload => [ $file ],
			$self->has_domain ? ( token_domain => $self->domain ) : (),
		},
	);
	$req->authorization_basic($user, $pass);
	return $req;
}

sub run {
	my ( $self, @args ) = @_;
	for (@args) {
		$self->upload($_);
	}
}

sub upload {
	my ($self, $file) = @_;
	$self->app->emit_and_exit(1, "File not found: " . $file) unless -f $file;
	$self->app->emit_info("Uploading $file... ");
	my $response = $self->app->http->request($self->get_request($file));
	$self->app->emit_and_exit(1, "Error: " . $response->code) if $response->is_error || $response->is_redirect;
	$self->app->emit_info("Upload completed successfully.");
}

1;
