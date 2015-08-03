package Matchbot::MockQueues;
use Mojo::JSON;

sub get_queues {
  return [
    {
      name => "S44",
      gameNames => [ "Spring: 1944 \$VERSION" ],
      mapNames => [ "1944_Red_Planet" ],
      engineVersions => [ "99" ],
      title => "MOAR S44",
      description => "TACTICS",
      minPlayers => 10,
      maxPlayers => 30,
      teamJoinAllowed => Mojo::JSON->true
    },
    {
      name => "BADSD1",
      gameNames => [ "Balanced Annihilation V8.12" ],
      mapNames => [ "DeltaSiegeDry" ],
      engineVersions => [ "101" ],
      title => "BADSD24/7",
      description => "Join the grind",
      minPlayers => 10,
      maxPlayers => 30,
      teamJoinAllowed => Mojo::JSON->true
    },
    {
      name => "BADSD2",
      gameNames => [ "Balanced Annihilation V8.12" ],
      mapNames => [ "DeltaSiegeDry" ],
      engineVersions => [ "101" ],
      title => "BA 1v1",
      description => "Join the grind",
      minPlayers => 10,
      maxPlayers => 30,
      teamJoinAllowed => Mojo::JSON->true
    },
    {
      name => "CURSED",
      gameNames => [ "Cursed v5" ],
      mapNames => [ "DeltaSiegeDry" ] ,
      engineVersions => [ "101" ],
      title => "Cursed",
      description => "Join the grind",
      minPlayers => 10,
      maxPlayers => 30,
      teamJoinAllowed => Mojo::JSON->true
    },
    {
      name => "EVONORMAL",
      gameNames => [ "EvolutionRTS v1" ],
      mapNames => [ "DeltaSiegeDry" ] ,
      engineVersions => [ "101" ],
      title => "EvolutionRTS",
      description => "Join the grind",
      minPlayers => 10,
      maxPlayers => 30,
      teamJoinAllowed => Mojo::JSON->true
    },
    {
      name => "MYGAME",
      gameNames => [ "My New game v1" ],
      mapNames => [ "DeltaSiegeDry" ] ,
      engineVersions => [ "101" ],
      title => "My new game!",
      description => "Join the grind",
      minPlayers => 10,
      maxPlayers => 30,
      teamJoinAllowed => Mojo::JSON->true
    },
    {
      name => "MANYGAMES",
      gameNames => [ "EvolutionRTS v1", "Balanced Annihilation V8.12", "Cursed 3" ],
      mapNames => [ "DeltaSiegeDry" ] ,
      engineVersions => [ "101" ],
      title => "Bunch of games",
      description => "Join the grind",
      minPlayers => 10,
      maxPlayers => 30,
      teamJoinAllowed => Mojo::JSON->true
    }
  ];
}

1;
