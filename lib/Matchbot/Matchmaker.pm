package Matchbot::Matchmaker;
use Mojo::Base -strict;
use Exporter 'import';
use List::Util qw(shuffle);
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
			push @matches, {
				status => 'readycheck',
				map => $map,
				game => $game,
				players => {
					0 => { name => $one, team => 0, ally => 0 },
					1 => { name => $two, team => 1, ally => 1 }
				},
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
