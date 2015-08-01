package Matchbot::Client;
use v5.18.2;
use Matchbot::Protocol;

use Mojo::IOLoop;
use Mojo::Base 'Mojo::EventEmitter';
use MIME::Base64;
use Digest::MD5 qw(md5);
use Data::Dumper qw(Dumper);

use constant DEBUG => $ENV{MATCHBOT_DEBUG} ? 1 : 0;

has '_stream';
has _msg_ids => sub { {} };
has _response_handlers => sub { {} };

sub connect {
	my $self = shift;
	my $connection_details = shift;
	my $reconnect = sub {
		Mojo::IOLoop->timer(5 => sub {
			$self->connect($connection_details);
		});
	};

	Mojo::IOLoop->client($connection_details => sub {
		my ($loop, $err, $stream) = @_;

		if ($err) {
			warn "blorg!! $err\n";
			$reconnect->();
			return;
		}

		$self->_stream($stream);

		$stream->on(read => sub {
			$self->_read(@_);
		});

		$stream->on(close => sub {
			warn "Client: stream closed\n" if DEBUG;
			$reconnect->();
		});

		$stream->on(error => sub {
			my ($stream, $err) = @_;
			warn "blorg! $err";
			$stream->close_gracefully;
			$reconnect->();
		});

		$stream->start;
		$self->_start_keepalive;
		$self->login;
	})
}

sub login {
	my $self = shift;
	my $pw = encode_base64(md5('foobar'));
	chomp($pw);
	$self->_write("LOGIN", "FooUser", $pw, 3200, "198.162.1.13", "PerlBot 0.01", 0, "sp cl p" => sub {
		my ($self, $res, $id) = @_;
		$self->emit('login');
	});
}

sub _parse {
	my ($self, $bytes) = @_;
	warn "Client: got some bytes; $bytes" if DEBUG;
}

sub _read {
	my ($self, $stream, $bytes) = @_;
	my ($command, $id, $data) = $self->_parse($bytes);
}

# register a callback to run when a specific response arrives
sub _register_response_handler {
	my ($self, $command, $id, $handler) = @_;
}

sub _write {
	my ($self, $command, @params) = @_;

	my $response_handler;
	if (ref $params[$#params] eq 'CODE') {
		$response_handler = pop @params;
	}

	my $param_string = '';
	for my $param (@params) {
		if ($param =~ /\t/) {
			$param =~ s/\t/  /g;
		}
		if ($param =~ /\s/) {
			# sentence: MUST be surrounded on both sides by tabs
			$param_string .= "\t$param\t";
		} else {
			# nom the space from the previous param (if any)
			$param_string =~ s/[ ]+$//g;
			$param_string .= " $param";
		}
	}

	# trim off any trailing spaces/tabs
	$param_string =~ s/\s+$//g;

	# max ID is 2147483647; with ping every 5 seconds that's 340 years.
	# probably fine to not check for overflow...
	my $id = $self->_msg_ids->{$command}++;

	if ($response_handler) {
		$self->_register_response_handler($command, $id, $response_handler);
	}

	my $message = sprintf("#%s %s%s\n", $id, $command, $param_string);
	warn "Client: sending $message" if DEBUG;
	$self->_stream->write($message);
}

sub _start_keepalive {
	my $self = shift;
	Mojo::IOLoop->recurring(5 => sub { $self->_ping });
}

sub _ping {
	my $self = shift;
	$self->_write("PING");
}

1;
