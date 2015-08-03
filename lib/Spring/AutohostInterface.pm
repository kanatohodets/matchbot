package Spring::AutohostInterface;
use Mojo::Base -strict;
use Mojo::IOLoop;
use IO::Socket::IP;

use constant DEBUG => $ENV{MATCHBOT_DEBUG} ? 1 : 0;

sub new {
	my ($self) = shift->SUPER::new(@_);
	my $spring_port = shift;
	$self->{sock} = IO::Socket::IP->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $spring_port,
		Proto => 'udp',
		Blocking => 0
	);

	if (!$self->{sock}) {
		die "could not bind autohost interface port: $!";
	}

	$self->{send_buffer} = [];

	Mojo::IOLoop->singleton->reactor->io($sock => sub {
		my ($readable, $writable) = @_;
		if ($readable) {
			# read up to one byte more than max UDP packet size for IPv4
			$sock->recv(my $buffer, 65_508, 0);
			if ($buffer) {
				warn "autohost <<< $message\n" if DEBUG;
				$self->parse_message($buffer);
			}
		}

		if ($writable && @{$self->{send_buffer}}) {
			my $message = pop @{$self->{send_buffer}};
			warn "autohost >>> $message\n" if DEBUG;
			$sock->send($message, 0);
		}
	});

	return $self;
}

sub send {
	my ($self, $message) = @_;
	unshift @{$self->{send_buffer}}, $message;
}

sub parse_message {
	my ($self, $message) = @_;
	say "got a message from spring on autohost interface: $message";
}

1;
