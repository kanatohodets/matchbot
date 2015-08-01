package Matchbot;
use Mojo::Base 'Mojolicious';
use Matchbot::Client;

# This method will run once at server start
sub startup {
	my $self = shift;
	my $conn = { address => 'localhost', port => 8200 };
	my $client = Matchbot::Client->new();
	$client->connect($conn);
}

1;
