package Matchbot;
use Mojo::Base 'Mojolicious';
use Spring::LobbyClient;

# This method will run once at server start
sub startup {
	my $self = shift;
	my $conn = { address => 'localhost', port => 8200 };
	my $client = Spring::LobbyClient->new();
	$client->connect($conn);
}

1;
