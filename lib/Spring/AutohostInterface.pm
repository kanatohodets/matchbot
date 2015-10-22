package Spring::AutohostInterface;
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use IO::Socket::INET;

use constant DEBUG => $ENV{MATCHBOT_DEBUG} ? 1 : 0;

has port => sub {
	my $self = shift;
	return $self->sock->sockport;
};

has sock => sub {
	state $sock = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		Proto => 'udp',
		Blocking => 0
	) or die "could not bind autohost interface port: $!";
};

sub new {
	my ($self) = shift->SUPER::new(@_);

	$self->{send_buffer} = [];

	Mojo::IOLoop->singleton->reactor->io($self->sock => sub {
		my ($readable, $writable) = @_;
		if ($readable) {
			# read up to one byte more than max UDP packet size for IPv4
			$self->sock->recv(my $buffer, 65_508, 0);
			if ($buffer) {
				warn "autohost <<< $buffer\n" if DEBUG;
				$self->parse_message($buffer);
			}
		}

		if ($writable && @{$self->{send_buffer}}) {
			my $message = pop @{$self->{send_buffer}};
			warn "autohost >>> $message\n" if DEBUG;
			$self->sock->send($message, 0);
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
}

1;

=encoding utf8

=head1 NAME

Spring::AutohostInterface - interact with the Spring AH interface

=head1 SYNOPSIS

	use Spring::AutohostInterface;

	my $interface = Spring::AutohostInterface->new;

=head1 DESCRIPTION

This listens on the port of the newly created Spring::Game process and sends/receives packets to the Spring AutohostInterface. 

=head1 TODO

=over

=item * 

emit data events

=item *

provide send interface

=back

=cut
