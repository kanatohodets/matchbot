package Matchbot::QueueManager;
use Mojo::Base 'Mojo::EventEmitter';
use 5.18.2;

has games => sub { {} };
has 'client';

sub start {
	my $self = shift;
	$self->client->on(joinqueuerequest => sub {
		my ($self, $id, $data) = @_;
		$self->add_users_to_queue($data);
	});

	$self->client->on(queueleft => sub {
		my ($self, $id, $data) = @_;
	});

	$self->client->on(readycheckresponse => sub {
		my ($self, $id, $data) = @_;
	});

	$self->client->on(removeuser => sub {
		my ($self, $id, $data) = @_;
	});
}

sub add_users_to_queue {
	my ($self, $users) = @_;
}

sub open {
	my ($self, $queues) = @_;
	for my $queue (@$queues) {
		$self->client->open_queue($queue);
	}
}


1;
