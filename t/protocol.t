use Test::More;
use strict;
use warnings;
use Spring::LobbyProtocol qw(parse_message prepare_message);

my @ping = ('PING', 5, ());
my $ping_cmd = prepare_message(@ping);
# extra space is for params
is $ping_cmd, "#5 PING \n", "ping, no params";

my @login = ('LOGIN', 0, 'FooUser', 'password', '3200', '*', 'Matchbot', 0, 'sp cl p');
my $login_cmd = prepare_message(@login);
# final clause of params 'sp cl p' is a 'sentence', which must be tab delimited
is $login_cmd, "#0 LOGIN FooUser password 3200 * Matchbot 0\tsp cl p\n", "LOGIN, params";

my $incoming_pong = "#0 PONG\n";
my @parsed = parse_message($incoming_pong);
my $pong = $parsed[0];
is_deeply $pong, { 0 => { 'name' => 'PONG', data => [ '' ], } }, 'pong parse';

my $incoming_motd = "#0 MOTD Server's uptime is 24 second(s)";
my @parsed_motd = parse_message($incoming_motd);
my $motd = $parsed_motd[0];
is_deeply $motd, { 0 => { 'name' => 'MOTD', data => [ "Server's uptime is 24 second(s)" ], } }, 'motd parse';

done_testing;

