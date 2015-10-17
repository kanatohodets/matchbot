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

Create a matchbot.conf file with contents like so (where `<STUFF>` means "fill in
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

Next, make a `queue.json` file somewhere with your queue details. It should look like
this (using S44 as an example):

	[
	   {
		  "teamJoinAllowed" : true,
		  "title" : "MOAR S44",
		  "name" : "S44",
		  "gameNames" : [
			 "Spring: 1944 $VERSION"
		  ],
		  "maxPlayers" : 30,
		  "minPlayers" : 10,
		  "engineVersions" : [
			 "99"
		  ],
		  "mapNames" : [
			 "1944_Red_Planet"
		  ],
		  "description" : "TACTICS"
	   },
	   <more queue defs go here>
	]

## Running

	carton exec script/matchbot daemon --queue <path-to-queue.json>

Will start the bot. If your queue.json lives in the same dir as the bot script,
that argument is not needed.
