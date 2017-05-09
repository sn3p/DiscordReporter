# Reporter Actor for UT99

This is an Unreal Tournament 99 Server Actor. It sends messages from the game to a [Discord](https://discordapp.com) bot. This is where [discord-reporter](https://github.com/sn3p/discord-reporter) comes into play, a Discord bot that relays the messages to the Discord server and channel of your choice.

This was originally developed as [MvReporter](https://github.com/sn3p/MvReporter) for IRC.


## Installation

1. Add the mutator's class to the ServerActors (not ServerPackages!) list in the `[Engine.GameEngine]` section in UnrealTournament.ini (or whatever ini file you/your host has). This should go after or at the end of the list of server ServerActors:

```ini
ServerActors=DiscordReporter.DiscordReporter
```

2. Copy the contents of the "System" directory to the "System" directory on your UT Server.  
(Do not upload the system folder INTO the system folder, only the contents!) (`*.u|*.int`).

3. You'll need [discord-reporter](https://github.com/sn3p/discord-reporter) to relay the messages to Discord.


## Configuration

The configuration is stored in your UnrealTournament.ini file. Most of the options can be found in the section `[DiscordReporter.DiscordReporterConfig]`.

Coming soon ...
