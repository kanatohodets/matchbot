package Matchbot::Client;
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use MIME::Base64;
use Digest::MD5 qw(md5);
use Data::Dumper qw(Dumper);

use v5.18.2;

use Matchbot::Protocol qw(parse_message prepare_message);;

use constant DEBUG => $ENV{MATCHBOT_DEBUG} ? 1 : 0;

has _response_handlers => sub { {} };

sub new {
	my $self = shift->SUPER::new(@_);

	$self->on(message => sub {
		my $self = shift;
		my ($command, $id, $data) = @_;
		# re-emit as a unique event
		$self->emit(lc $command, $id, $data);
		$self->_handle_response($command, $id, $data);
	});

	return $self;
}
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

		$self->{stream} = $stream;

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
	$self->_write("LOGIN", "FooUser", $pw, 3200, "198.162.1.13", "PerlBot 0.01", 0, "sp cl p");
}

sub _read {
	my ($self, $stream, $bytes) = @_;
	my @commands = parse_message($bytes);
	# assumes commands can't be interleaved.
	# e.g.
	# 0 ADDUSER part1
	# 1 LOGINACCEPTED
	# 0 ADDUSER part2
	# will never happen
	for my $command (@commands) {
		for my $id (sort keys %$command) {
			my $command_version = $command->{$id};
			my $name = $command_version->{name};
			my $data = $command_version->{data};
			$self->emit(message => $name, $id, $data);
		}
	}
}

sub _handle_response {
	my ($self, $command, $id, $data) = @_;
	my $command_handlers = $self->{response_handlers}->{$command};
	# yes, autoviv. all commands will have an empty hash at least.
	if (exists $command_handlers->{$id}) {
		my $handler = $command_handlers->{$id};
		$self->$handler->($command, $id, $data);
	}
}

sub _write {
	my ($self, $command, @params) = @_;

	my $response_handler;
	if (ref $params[$#params] eq 'CODE') {
		$response_handler = pop @params;
	}

	# max ID is 2147483647; with ping every 5 seconds that's 340 years.
	# probably fine to not check for overflow...
	my $id = $self->{msg_ids}->{$command}++;

	# writer wanted a cb to ping on response
	if ($response_handler) {
		say "registering a response handler for $command with id $id";
		$self->{response_handlers}->{$command}->{$id} = $response_handler;
	}

	my $message = prepare_message($command, $id, @params);
	warn "Client: sending $message" if DEBUG;
	$self->{stream}->write($message);
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
