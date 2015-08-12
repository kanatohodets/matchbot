use Test::More;
use strict;
use warnings;
use Spring::Game;
use Matchbot::Matchmaker;
use Matchbot::Util qw(generate_password);

my $match = {
	map => "Test Map",
	game => "Test Game",
	player => {
		0 => {
			name => "Test Player One",
			password => generate_password,
		},
		1 => {
			name => "Test Player Two",
			password => generate_password,
		}
	},
	team => {
		0 => {
			AllyTeam => 0,
		},
		1 => {
			AllyTeam => 1,
		},
	},
	allyteam => { 0 => { NumAllies => 0 }, 1 => { NumAllies => 0 }},
};

my $game = Spring::Game->new({
	match => $match,
	root_dir => 't/games',
	spring_binary => 'foobar does not matter'
});

my $script = $game->write_startscript;

like $script, qr/^\[game\]\s*{/, "starts with [game]";
like $script, qr/AutohostPort=\d+;/, "has autohost port";
like $script, qr/HostPort=\d+;/, "has host port";
like $script, qr/OnlyLocal=0;/, "is onlylocal";
like $script, qr/MapName=[\w|\s]+;/, "has map name";
like $script, qr/GameType=[\w|\s]+;/, "has map name";
like $script, qr/}$/, "ends with }";

done_testing();
