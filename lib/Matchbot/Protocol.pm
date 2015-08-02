package Matchbot::Protocol;
use Mojo::Base -base;
use Exporter 'import';
use Data::Dumper qw(Dumper);
use 5.18.2;

our @EXPORT_OK = qw(parse_message prepare_message);

sub parse_message {
	my $bytes = shift;
	my @messages = split /\n/, $bytes;
	my $commands = {};
	my @receipt_order;
	for my $message (@messages) {
		$message =~ s/^#(\d+) //; my $id = $1 // 'no ID';

		# first message from server, the banner
		if ($id eq 'no ID') {
			push @receipt_order, 'banner';
			$commands->{banner}->{0} = {
				name => 'banner',
				data => [$message]
			};
			next;
		}

		# the optional whitespace NOM is to get it off the front of the
		# remaining bits of the message
		$message =~ s/^([A-Z]+) ?//;
		my $command = $1;
		
		if (!exists $commands->{$command}) {
			push @receipt_order, $command;
		}

		$commands->{$command}->{$id} //= {
			name => $command,
			data => []
		};

		chomp($message);
		# for now just shove the entire data string into the list.
		push @{$commands->{$command}->{$id}->{data}}, $message;
	}

	my @ordered_commands = map { $commands->{$_} } @receipt_order;
	return @ordered_commands;
}

sub prepare_message {
	my ($command, $id) = (shift, shift);
	my @params = @_;

	my $param_string = '';
	for my $param (@params) {
		if ($param =~ /\t/) {
			$param =~ s/\t/  /g;
		}
		if ($param =~ /\s/) {
			# sentence: MUST be surrounded on both sides by tabs
			$param_string .= "\t$param\t";
		} else {
			# nom the space from the previous param (if any)
			$param_string =~ s/[ ]+$//g;
			$param_string .= " $param";
		}
	}

	# trim off any trailing spaces/tabs
	$param_string =~ s/\s+$//g;

	say "wtf no id?? $command $param_string" if !defined $id;
	my $message = sprintf("#%s %s%s\n", $id, $command, $param_string);
	return $message;
}

1;
