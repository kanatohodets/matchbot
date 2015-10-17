use Test::More;
use strict;
use warnings;
use Spring::Game;

my $match = {
	map => "Test Map",
	game => "Test Game",
	players => {
		0 => { name => "Test Player One", team => 0, ally => 0 },
		1 => { name => "Test Player Two", team => 1, ally => 1 }
	},
};

my $game = Spring::Game->new({
	match => $match,
	root_dir => 't/games',
	spring_binary => 'foobar does not matter'
});

my $ast = $game->prepare_startscript_ast($match);
my $mock_ast = {
	'player' => {
		'1' => {
			'password' => $ast->{player}->{1}->{password},
			'team' => 1,
			'name' => 'Test Player Two'
		},
		'0' => {
			'name' => 'Test Player One',
			'password' => $ast->{player}->{0}->{password},
			'team' => 0
		}
	},
	'allyteam' => {
		'0' => { 'NumAllies' => 0 },
		'1' => { 'NumAllies' => 0 },
	},
	'team' => {
		'1' => {
			'TeamLeader' => '1',
			'AllyTeam' => 1
		},
		'0' => {
			'AllyTeam' => 0,
			'TeamLeader' => '0'
		}
	}
};
is_deeply $ast, $mock_ast, "right AST generated";

my $script = $game->generate_startscript;

like $script, qr/^\[game\]\s*{/, "starts with [game]";
like $script, qr/AutohostPort=\d+;/, "has autohost port";
like $script, qr/HostPort=\d+;/, "has host port";
like $script, qr/OnlyLocal=0;/, "is onlylocal";
like $script, qr/MapName=[\w|\s]+;/, "has map name";
like $script, qr/GameType=[\w|\s]+;/, "has map name";
like $script, qr/}$/, "ends with }";

done_testing();
