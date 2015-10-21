package Matchbot::QueueManager;
use Mojo::Base 'Mojo::EventEmitter';
use List::Util qw(all any);
use Data::Dumper qw(Dumper);
use Spring::Game;
use Matchbot::Matchmaker qw(find_queue_matches);;

use 5.18.2;
$Data::Dumper::Sortkeys = 1;

has games => sub { {} };
has queues => sub { {} };
has 'app';

sub start {
	my $self = shift;
	$self->app->client->on(joinqueuerequest => sub {
		my ($client, $id, $data) = @_;
		$self->add_users_to_queue($data->{name}, $data->{userNames});
	});

	$self->app->client->on(queueleft => sub {
		my ($client, $id, $data) = @_;
		$self->remove_users_from_queue($data->{name}, $data->{userNames});
	});

	$self->app->client->on(removeuser => sub {
		my ($client, $id, $data) = @_;
		$self->remove_user($data->[0]);
	});

	$self->app->client->on(readycheckresponse => sub {
		my ($client, $id, $data) = @_;
		$self->handle_ready_check_response($data->{name}, $data->{userName}, $data->{response});
	});
}

sub add_users_to_queue {
	my ($self, $queue_name, $users) = @_;
	if (exists $self->queues->{$queue_name}) {
		my $queue = $self->queues->{$queue_name};
		say "time to add queue people to $queue_name", Dumper($users);
		for my $user (@$users) {
			# assuming player can only be in one queue at once -- correct?
			$self->{players_to_queues}->{$user} = $queue->{name};
			$queue->{players}->{$user} = {
				status => 'unknown',
				game => undef
			};
		}

		$self->app->client->join_queue_accept($queue_name, $users);
		#TODO: determine an appropriate response to listen for to signal that
		#it's ok to start matchmaking. or use a more informed constant.
		Mojo::IOLoop->timer(1 => sub {
			$self->matchmake($queue_name);
		});
	}
}

# see if there are any games to be had
sub matchmake {
	my ($self, $queue_name) = @_;
	my $queue = $self->queues->{$queue_name};
	my @matches = find_queue_matches($queue);
	if (@matches) {
		for my $match (@matches) {
			my $players = $match->{players};
			my @player_list;
			for my $player_id (keys %$players) {
				my $player_name = $players->{$player_id}->{name};
				push @player_list, $player_name;
				# associate match with each player so we can snag the match
				# details regardless of which player reponds last to the ready
				# check
				$queue->{players}->{$player_name}->{match} = $match;
			}
			$self->app->client->ready_check($queue_name, \@player_list, 10);
		}
	}
}

sub remove_users_from_queue {
	my ($self, $queue_name, $users) = @_;
	my $queue = $self->queues->{$queue_name};
	say "deleting from queue $queue_name: " . join ', ', @$users;
	# sorry about the syntax: deleting from a hash slice.
	delete @{$queue->{players}}{@$users};
	delete @{$self->{players_to_queues}}{@$users};
}

sub remove_user {
	my ($self, $user) = @_;
	my $queue = delete ${$self->{players_to_queues}}{$user};
	if ($queue) {
		say "$user disconnected; removed from $queue->{name}";
		delete ${$queue->{players}}{$user};
	}
}

sub open {
	my ($self, $queues) = @_;
	for my $queue (@$queues) {
		my $name = $queue->{name};
		$self->queues->{$name} = {
			details => $queue,
			players => {}
		};
		$self->app->client->open_queue($queue);
	}
}

sub handle_ready_check_response {
	my ($self, $queue_name, $user, $response) = @_;

	my $queue = $self->queues->{$queue_name};
	my $queue_players = $queue->{players};

	$queue_players->{$user}->{status} = $response;

	my $match = $queue_players->{$user}->{match};
	my @player_statuses = map { $_->{status} } values %$queue_players;

	my $still_waiting_for_responses = any { $_ eq 'unknown' } @player_statuses;
	if (!$still_waiting_for_responses) {
		my $all_ready = all { $_ eq 'ready' } @player_statuses;
		my @players = sort keys %$queue_players;

		if ($all_ready) {
			$self->app->client->ready_check_result($queue_name, \@players, 'pass');
			$self->start_game($match);
		} else {
			for my $name (@players) {
				my $player = $queue_players->{$name};
				delete ${$player}{match};
				# delete unready/timeout from queue?
				$player->{status} = 'unknown';
			}
			$self->app->client->ready_check_result($queue_name, \@players, 'fail');
		}
	}
}

sub register_game {
	my ($self, $game) = @_;
	$self->games->{$game->process->pid} = $game;
}

sub start_game {
	my ($self, $match) = @_;
	my $game = Spring::Game->new({
		root_dir => $self->app->config->{root_dir},
		spring_binary => $self->app->config->{spring},
		match => $match
	});

	$game->start;

	$self->register_game($game);

	# TODO: external IP from app
	my $ip = '127.0.0.1';
	my $port = $game->port;
	for my $player (@{ $game->players }) {
		my ($name, $password) = @{$player}{qw(name password)};
		$self->app->client->connect_user($name, $ip, $port, '0', $password);
	}
}

1;
