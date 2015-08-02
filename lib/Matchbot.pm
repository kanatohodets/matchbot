package Matchbot;
use Mojo::Base 'Mojolicious';
use Spring::LobbyClient;
use Matchbot::MockQueues;

has queues => sub { {} };
has games => sub { {} };
has 'client' => sub { state $client = Spring::LobbyClient->new() };

# This method will run once at server start
sub startup {
	my $self = shift;
	my $conn = {
		address => 'localhost',
		port => 8200,
		user => 'FooUser',
		password => "foobar"
	};

	$self->client->connect($conn => sub {
		my $queues = Matchbot::MockQueues::get_queues();
		for my $queue (@$queues) {
			$self->client->open_queue($queue);
		}
	});
}

1;
