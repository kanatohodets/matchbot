package Matchbot::QueueManager;
use Mojo::Base 'Mojo::EventEmitter';
use List::Util qw(all any);
use Data::Dumper qw(Dumper);

use Matchbot::Matchmaker qw(find_queue_matches);;

use 5.18.2;
$Data::Dumper::Sortkeys = 1;

has games => sub { {} };
has queues => sub { {} };
has 'client';

sub start {
	my $self = shift;
	$self->client->on(joinqueuerequest => sub {
		my ($client, $id, $data) = @_;
		$self->add_users_to_queue($data->{name}, $data->{userNames});
	});

	$self->client->on(queueleft => sub {
		my ($client, $id, $data) = @_;
		$self->remove_users_from_queue($data->{name}, $data->{userNames});
	});

	$self->client->on(removeuser => sub {
		my ($client, $id, $data) = @_;
		$self->remove_user($data->[0]);
	});

	$self->client->on(readycheckresponse => sub {
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
				status => 'unknown'
			};
		}

		$self->client->join_queue_accept($queue_name, $users);
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
	say "matchmaking! $queue_name";
	my $queue = $self->queues->{$queue_name};
	my @games = find_queue_matches($queue);
	say "any games found in matched players? ", Dumper(@games);
	if (@games) {
		for my $game (@games) {
			my $players = $game->{players};
			$self->client->ready_check($queue_name, $players, 10);
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
		$self->client->open_queue($queue);
	}
}

sub handle_ready_check_response {
	my ($self, $queue_name, $user, $response) = @_;

	my $queue = $self->queues->{$queue_name};
	my $queue_players = $queue->{players};

	$queue_players->{$user}->{status} = $response;
	my @player_statuses = values %$queue_players;

	my $still_waiting_for_responses = any { $_->{status} eq 'unknown' } @player_statuses;
	if (!$still_waiting_for_responses) {
		my $all_ready = all { $_->{status} eq 'ready' } @player_statuses;
		my @players = sort keys %$queue_players;

		if ($all_ready) {
			#TODO: spawn a game and issue CONNECTUSER
			$self->client->ready_check_result($queue_name, \@players, 'pass');
		} else {
			$self->client->ready_check_result($queue_name, \@players, 'fail');
		}
	}
}

1;
