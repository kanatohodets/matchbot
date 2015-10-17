#Matchbot

This is a matchmaking bot for a SpringRTS lobby server, following the protocol
defined [here](https://springrts.com/phpbb/viewtopic.php?f=71&t=33072).

## Installation
Matchbot is a Perl daemon with a few dependencies, and it uses
[Carton](https://metacpan.org/pod/Carton) to manage them. To install:

- Install `carton`: `sudo apt-get install carton` on Ubuntu 14.04,
	- Ubuntu: `sudo apt-get install carton` 
	- elsewhere: `sudo cpan -i Carton`
- Install Matchbot dependencies: `carton install`

## Configuration

Create a matchbot.conf file with contents like so (where <STUFF> means "fill in
with data specific to your deployment"):

	{
		spring => <ABSOLUTE_PATH_TO_SPRING_DEDICATED_EXECUTABLE>,
		root_dir => <staging ground for game startscripts>,
		connection => {
			address => 'springrts.com',
			port => 8200,
			username => <BOT_USERNAME>,
			password => <BOT_PASSWORD>
		},
	}

## Running

	carton exec script/matchbot daemon

Will start the bot. The (not yet implemented) interface will be available on
localhost:3000.
