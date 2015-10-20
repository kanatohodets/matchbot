package Matchbot;
use Mojo::Base 'Mojolicious';
use Spring::LobbyClient;
use Matchbot::QueueManager;
use Mojolicious::Plugin::Config;
use Getopt::Long;
use Mojo::JSON qw(decode_json);
use Mojo::Util qw(slurp);

has client => sub { state $client = Spring::LobbyClient->new() };
has queue => sub {
	my $self = shift;
	state $queue = Matchbot::QueueManager->new({
		app => $self
	});
};

sub startup {
	my $self = shift;
	use feature qw(say); use Data::Dumper qw(Dumper);
	my $conf_file = 'matchbot.conf';
	my $queue_file = 'queue.json';

	GetOptions(	"config=s" => \$conf_file,
				"queue=s" => \$queue_file );

	$self->plugin(Config => { file => $conf_file });

	my $conn = $self->config->{connection};
	my $queue_data = slurp $queue_file;

	my $queues = decode_json($queue_data);
	$self->client->connect($conn => sub {
		$self->queue->start;
		$self->queue->open($queues);
	});
}

1;
=encoding utf8

=head1 NAME

Matchbot - a matchmaking bot for SpringRTS servers

=head1 SYNOPSIS

	carton exec script/matchbot daemon --queue <path-to-queue.json>

=cut

