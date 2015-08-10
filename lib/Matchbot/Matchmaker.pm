package Matchbot::Matchmaker;
use Mojo::Base -strict;
use Exporter 'import';
use List::Util qw(shuffle);
use Data::Dumper qw(Dumper);
use 5.18.2;

our @EXPORT_OK = qw(find_queue_matches);

sub generate_user_password {
	my @corpus = ('a' .. 'z', 'A' .. 'Z', 0 .. 9, qw|! @ $ % ^ & * ( )|);
	return join '', (shuffle @corpus)[0 .. 8];
}

sub generate_1v1s {
    my ($players, $map_pool, $game_pool) = @_;
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
				player => {
                    0 => {
                        name => $one,
                        password => generate_user_password(),
                    },
                    1 => {
                        name => $two,
                        password => generate_user_password(),
                    }
                },
                team => {
                    0 => {
                        AllyTeam => 0,
                    },
                    1 => {
                        AllyTeam => 0,
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
	my @matches;
	#TODO: smart matching logic, extensibility so its easy to write new
	#matching algos, whatever.
	my @players = keys %{$queue->{players}};
    my $details = $queue->{details};
    # just 1v1 for now
    my @matches = generate_1v1s(\@players, $details->{gameNames}, $details->{mapNames});
	return @matches;
}

1;
