package Spring::Game;
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::Template;
use Mojo::IOLoop::ReadWriteFork;
use Mojo::Util qw(spurt);

use IO::Socket::INET;
use File::Path qw(make_path remove_tree);

use Spring::AutohostInterface;
use Matchbot::Util qw(generate_password);

use Data::Dumper qw(Dumper);

has process => sub { my $fork = Mojo::IOLoop::ReadWriteFork->new };
has 'manager';
has 'match';
has root_dir => sub { shift->manager->app->config->{root_dir} };
has spring_binary => sub { shift->manager->app->config->{spring} };
has host_interface => sub { my $interface = Spring::AutohostInterface->new };

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

has dir => sub {
	my $self = shift;
	# HACK (using time). probably best to increment IDs in the code based on
	# reading dirnames (so it survives restarts without overwriting existing
	# dirs)
	my $root = $self->root_dir;
	my $path = $self->manager->app->home->rel_file("$root/" . time);
	return $path;
};

has 'players';

sub start {
	my $self = shift;
	make_path $self->dir;

	$self->process->on(error => sub {
		my ($fork, $err) = @_;
		my $dir = $self->dir;
		warn "Spring $dir ERR >>> $err\n";
	});
	$self->process->on(read => sub {
		my ($fork, $buffer) = @_;
		my $dir = $self->dir;
		warn "Spring $dir >>> $buffer\n";
	});

	$self->process->on(close => sub {
		$self->cleanup;
	});

	my $script_file = $self->write_startscript;
	die "could not write startscript!" if !$script_file;

	my $match = $self->match;
	$self->process->start(
		program => $self->spring_binary,
		program_args => [ $script_file ],
		conduit => 'pty'
	);
}

sub write_startscript {
	my $self = shift;
	my $templ = Mojo::Template->new;
	my $match = $self->match;
	my $params = {
		StartPosType => 1,
		OnlyLocal => 0,
		IsHost => 1,
		GameType => $match->{game},
		MapName => $match->{map},
		HostIP => '',
		HostPort => $self->port,
		AutoHostIP => '127.0.0.1',
		AutohostPort => $self->host_interface->port
	};

	my $ast = {
		player => {},
		team => {},
		allyteam => {}
	};

	my @players;
	for my $player_id (sort keys %{$match->{players}}) {
		my $player = $match->{players}->{$player_id};
		my $ast_player = $ast->{player}->{$player_id} //= {};
		$ast->{team} //= {};
		my $ast_team = $ast->{team}->{$player->{team}} //= {};
		if (exists $ast_team->{AllyTeam} && $ast_team->{AllyTeam} ne $player->{ally}) {
			warn "matchmaker produced players on the same team " .
				 "but with different allyteams. This doesn't make sense.\n";
		}

		$ast_team->{AllyTeam} = $player->{ally};
		$ast_team->{TeamLeader} = $player_id;

		$ast_player->{team} = $player->{team};
		$ast_player->{name} = $player->{name};
		$ast_player->{password} = generate_password();
		push @players, $ast_player;

		my $ast_ally = $ast->{allyteam}->{$player->{ally}} //= {};
		$ast_ally->{NumAllies} //= -1;
		$ast_ally->{NumAllies}++;
	}

	$self->players(\@players);

	my %counts;
	for my $group (qw(team player allyteam)) {
		for my $num (sort keys %{$ast->{$group}}) {
			$counts{$group}++;
			my $key = "$group$num";
			$params->{$key} = $ast->{$group}->{$num};
		}
	}

	my $script = $templ->render_file('templates/_script.ep.txt', $params);
	my $script_file = $self->dir . '/_script.txt';
	spurt $script, $script_file;

	return $script_file if -r $script_file;
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

1;
