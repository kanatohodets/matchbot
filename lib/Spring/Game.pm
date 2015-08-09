package Spring::Game;
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::Template;
use Mojo::IOLoop::ReadWriteFork;

use IO::Socket::INET;
use List::Util qw(shuffle);
use File::Path qw(make_path remove_tree);

use Spring::AutohostInterface;
use Data::Dumper qw(Dumper);

has process => sub { state $fork = Mojo::IOLoop::ReadWriteFork->new };
has 'manager';
has 'match';
has root_dir => sub { shift->manager->app->config->{root_dir} };
has spring_binary => sub { shift->manager->app->config->{spring} };
has host_interface => sub { state $interface = Spring::AutohostInterface->new };

has port => sub {
	my $self = shift;
	my $sock = IO::Socket::INET->new(
		Proto => 'udp',
		LocalAddr => '127.0.0.1',
	) or die "unable to bind udp port for spring to host on: $!";

	my $port = $sock->sockport;
	$sock->close;
	return $port;
};

has 'dir' => sub {
	my $self = shift;
	# HACK (using time). probably best to increment IDs in the code based on
	# reading dirnames (so it survives restarts without overwriting existing
	# dirs)
	return $self->root_dir . "/" . time;
};

sub new {
	my $self = shift->SUPER::new(@_);
	$self->process->on(error => sub {
		my ($fork, $err) = @_;
		my $dir = $self->dir;
		warn "Spring $dir ERR <<< $err\n";
	});
	$self->process->on(read => sub {
		my ($fork, $buffer) = @_;
		my $dir = $self->dir;
		warn "Spring $dir <<< $buffer\n";
	});

	$self->process->on(close => sub {
		$self->cleanup;
	});

	make_path $self->dir;

	$self->write_startscript;

	my $match = $self->match;
	$self->process->start(
		program => $self->spring_binary,
		program_args => [
			'--game' => $match->{game}, 
			'--map' => $match->{map}, 
			'--write-dir' => $self->dir,
			$self->dir . '/_script.txt'
		],
		conduit => 'pty'
	);

	return $self;
}

sub write_startscript {
	my $self = shift;
	my $templ = Mojo::Template->new;
	my $params = {
		Game => {
			HostPort => $self->port,
			AutohostPort => $self->host_interface->port
		}
	};
	my $output = $templ->render_file('templates/_script.ep.txt', $params);
	say "here's some script output";
	say $output;
}

sub cleanup {
	my $self = shift;
	say "time to clean up ", $self->dir;
	#remove_tree $self->dir;
}

sub force_shutdown {
	my $self = shift;
	$self->process->kill;
}

sub generate_user_password {
	my @corpus = ('a' .. 'z', 'A' .. 'Z', 0 .. 9, qw|! @ $ % ^ & * ( )|);
	return join '', (shuffle @corpus)[0 .. 8];
}

1;
