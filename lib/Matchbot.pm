package Matchbot;
use Mojo::Base 'Mojolicious';
use Mojo::IOLoop;
use MIME::Base64;
use Digest::MD5 qw(md5);
use 5.20.0;
use experimental qw(postderef signatures);
use Data::Dumper qw(Dumper);

# This method will run once at server start
sub startup {
	my $self = shift;
	my $conn = { address => 'localhost', port => 8200 };
	my $client = Mojo::IOLoop->client($conn => sub {
		my ($loop, $err, $stream) = @_;
		$stream->on(read => sub ($stream, $bytes) {
			if ($bytes ne "PONG\n") {
				print "bytes from server: $bytes";
			}
		});

		Mojo::IOLoop->recurring(5 => sub ($timer) {
			$stream->write("PING\n");
		});

		my $pw = encode_base64(md5('foobar'));
		chomp($pw);
		$stream->write("LOGIN FooUser $pw 3200 198.162.1.13 PerlBot 0.01\n");

		$stream->start;
	});
}

1;
