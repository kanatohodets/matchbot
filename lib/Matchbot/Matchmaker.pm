package Matchbot::Matchmaker;
use Mojo::Base -strict;
use Exporter 'import';
use List::Util qw(shuffle);
use Matchbot::Util qw(generate_password);
use 5.18.2;

our @EXPORT_OK = qw(find_queue_matches);

sub generate_1v1s {
	my ($players, $game_pool, $map_pool) = @_;
	my @players = @$players;
	my @matches;
	while (@players) {
		my ($one, $two) = (shift @players, shift @players);
		if (defined $one && defined $two) {
			my $map = (shuffle @$map_pool)[0];
			my $game = (shuffle @$game_pool)[0];
			# TODO: something to translate a more human datastructure into
			# an AST for the startscript, instead of basically writing it out.
			push @matches, {
				status => 'readycheck',
				map => $map,
				game => $game,
				playerlist => [$one, $two],
				player => {
					0 => {
						name => $one,
						password => generate_password(),
					},
					1 => {
						name => $two,
						password => generate_password(),
					}
				},
				team => {
					0 => {
						AllyTeam => 0,
						TeamLeader => 0,
					},
					1 => {
						AllyTeam => 1,
						TeamLeader => 1,
					},
				},
				allyteam => { 0 => { NumAllies => 0 }, 1 => { NumAllies => 0 }},
			};
		}
	}
	return @matches;
}

sub find_queue_matches {
	my $queue = shift;
	#TODO: smart matching logic, extensibility so its easy to write new
	#matching algos, whatever.
	my @players = keys %{$queue->{players}};
	my $details = $queue->{details};

	# just 1v1 for now
	my @matches = generate_1v1s(\@players, $details->{gameNames}, $details->{mapNames});
	return @matches;
}

1;
