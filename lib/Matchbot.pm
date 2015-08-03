package Matchbot;
use Mojo::Base 'Mojolicious';
use Spring::LobbyClient;
use Matchbot::MockQueues;
use Matchbot::QueueManager;

has 'queue';
has client => sub { state $client = Spring::LobbyClient->new() };
has queue => sub {
	state $queue = Matchbot::QueueManager->new({
		client => shift->client
	});
};

# This method will run once at server start
sub startup {
	my $self = shift;
	my $conn = {
		address => 'localhost',
		port => 8200,
		username => 'FooUser',
		password => "foobar"
	};

	my $queues = Matchbot::MockQueues::get_queues();
	$self->client->connect($conn => sub {
		$self->queue->start;
		$self->queue->open($queues);
	});
}

1;
