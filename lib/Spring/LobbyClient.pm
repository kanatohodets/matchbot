package Spring::LobbyClient;
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use MIME::Base64;
use Digest::MD5 qw(md5);
use Data::Dumper qw(Dumper);

use v5.18.2;

use Spring::LobbyProtocol qw(parse_message prepare_message);;

use constant DEBUG => $ENV{MATCHBOT_DEBUG} ? 1 : 0;

sub new {
	my $self = shift->SUPER::new(@_);

	$self->on(message => sub {
		my $self = shift;
		my ($command, $id, $data) = @_;
		# re-emit as a unique event
		$self->emit(lc $command, $id, $data);
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
		$self->login('FooUser', 'foobar');
	})

}

sub login {
	my $self = shift;
	my ($username, $password) = @_;
	my $pw = encode_base64(md5($password));
	chomp($pw);
	$self->_write("LOGIN", $username, $password, 3200, "198.162.1.13", "PerlBot 0.01", 0, "sp cl p");
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

sub _write {
	my ($self, $command, @params) = @_;

	# max ID is 2147483647; with ping every 5 seconds that's 340 years.
	# probably fine to not check for overflow...
	my $id = $self->{msg_ids}->{$command}++;

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
