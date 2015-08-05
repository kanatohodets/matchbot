package Matchbot::Matchmaker;
use Mojo::Base -strict;
use Exporter 'import';
use Data::Dumper qw(Dumper);
use 5.18.2;

our @EXPORT_OK = qw(find_queue_matches);

sub find_queue_matches {
	my $queue = shift;
	my @games;
	#TODO: smart matching logic, extensibility so its easy to write new
	#matching algos, whatever.
	my @players = keys %{$queue->{players}};
	#just 1v1 for now
	while (@players) {
		my ($one, $two) = (shift @players, shift @players);
		if (defined $one && defined $two) {
			push @games, {
				players => [$one, $two]
			};
		}
	}
	return @games;
}
