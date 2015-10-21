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
has 'match';
has 'root_dir';
has 'spring_binary';
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
	my $path = sprintf "%s/%s", $self->root_dir, time;
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

	my $script = $self->generate_startscript;
	my $script_file = $self->dir . '/_script.txt';
	spurt $script, $script_file;

	die "could not write startscript!" if !-r $script_file;

	my $match = $self->match;
	$self->process->start(
		program => $self->spring_binary,
		program_args => [ $script_file ],
		conduit => 'pty'
	);
}

sub generate_startscript {
	my $self = shift;
	my $match = $self->match;

	my $ast = $self->prepare_startscript_ast($match);

	# TODO: ditch this side-effect
	my @players = map { $ast->{player}->{$_} } sort keys %{ $ast->{player} };
	$self->players(\@players);

	return $self->compile_startscript($match->{game}, $match->{map}, $ast);
}

sub prepare_startscript_ast {
	my ($self, $match) = @_;
	my $ast = {
		player => {},
		team => {},
		allyteam => {}
	};

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

		my $ast_ally = $ast->{allyteam}->{$player->{ally}} //= {};
		$ast_ally->{NumAllies} //= -1;
		$ast_ally->{NumAllies}++;
	}

	return $ast;
}

sub compile_startscript {
	my ($self, $game, $map, $ast) = @_;
	my $templ = Mojo::Template->new;

	my $params = {
		StartPosType => 1,
		OnlyLocal => 0,
		IsHost => 1,
		GameType => $game,
		MapName => $map,
		HostIP => '',
		HostPort => $self->port,
		AutoHostIP => '127.0.0.1',
		AutohostPort => $self->host_interface->port
	};

	my %counts;
	for my $group (qw(team player allyteam)) {
		for my $num (sort keys %{$ast->{$group}}) {
			$counts{$group}++;
			my $key = "$group$num";
			$params->{$key} = $ast->{$group}->{$num};
		}
	}

	return $templ->render_file('templates/_script.ep.txt', $params);
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

=encoding utf8

=head1 NAME

Spring::Game - start Spring host (by writing startscripts)

=head1 SYNOPSIS

	use Spring::Game;

	my $game = Spring::Game->new({
		root_dir => $path_to_directory_for_startscripts,
		spring_binary => $path_to_spring_dedicated,
		match => $match
	});

	$game->start;

=cut
