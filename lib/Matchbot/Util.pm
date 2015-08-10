package Matchbot::Util;
use Mojo::Base -strict;
use Exporter 'import';
use IO::Socket::INET;
use List::Util qw(shuffle);
use Data::Dumper qw(Dumper);
use 5.18.2;

our @EXPORT_OK = qw(generate_password);

my @corpus = ('a' .. 'z', 'A' .. 'Z', 0 .. 9, qw|! @ $ % ^ & * ( )|);
sub generate_password {
	return join '', (shuffle @corpus)[0 .. 8];
}

sub host_ip {
	my $sock = IO::Socket::INET->new(
		Proto => 'udp',
		PeerAddr => '8.8.8.8', # google public DNS
		PeerPort => '53'
	);

	my $ip => $sock->sockhost;
	return $ip;
}

1;
