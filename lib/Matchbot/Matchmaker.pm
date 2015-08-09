package Matchbot::Matchmaker;
use Mojo::Base -strict;
use Exporter 'import';
use List::Util qw(shuffle);
use Data::Dumper qw(Dumper);
use 5.18.2;

our @EXPORT_OK = qw(find_queue_matches);

sub find_queue_matches {
	my $queue = shift;
	my @matches;
	#TODO: smart matching logic, extensibility so its easy to write new
	#matching algos, whatever.
	my @players = keys %{$queue->{players}};
	my @game_pool = @{$queue->{details}->{gameNames}};
	my @map_pool = @{$queue->{details}->{mapNames}};
	#just 1v1 for now
	while (@players) {
		my ($one, $two) = (shift @players, shift @players);
		if (defined $one && defined $two) {
			my $map = (shuffle @map_pool)[0];
			my $game = (shuffle @game_pool)[0];
			push @matches, {
				status => 'readycheck',
				map => $map,
				game => $game,
				players => [$one, $two]
			};
		}
	}
	return @matches;
}
