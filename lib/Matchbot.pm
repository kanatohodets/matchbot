package Matchbot;
use Mojo::Base 'Mojolicious';
use Spring::LobbyClient;
use Matchbot::MockQueues;
use Matchbot::QueueManager;
use Mojolicious::Plugin::Config;

has 'queue';
has client => sub { state $client = Spring::LobbyClient->new() };
has queue => sub {
	my $self = shift;
	state $queue = Matchbot::QueueManager->new({
		app => $self
	});
};

sub startup {
	my $self = shift;
	$self->plugin('Config');

	my $conn = $self->config->{connection};

	my $queues = Matchbot::MockQueues::get_queues();
	$self->client->connect($conn => sub {
		$self->queue->start;
		$self->queue->open($queues);
	});
}

1;
