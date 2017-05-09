class DiscordReporter extends Actor;

var bool bInitialized;
var string sVersion, sBuild;
var DiscordReporterConfig conf;
var DiscordReporterLink Link;
var DiscordReporterSpectator Spectator;
// var DiscordReporterMutator Mut;
var GameReplicationInfo GRI;

// Event: PreBeginPlay
event PreBeginPlay()
{
  // Check if we're already initialized
  if (bInitialized)
    return;
  bInitialized = TRUE;

  // Load...
  conf = Spawn(class'DiscordReporter.DiscordReporterConfig');
  LoadTeamNames();
  // CheckIRCColors();

  // Start Reporter Engine
  conf.SaveConfig();
  Log("+-----------------------+");
  Log("| Discord Reporter 0.1b |");
  Log("+-----------------------+");
  InitReporter();
}

// FUNCTION: Enabled / Enable/Disable Reporter
function InitReporter()
{
  local Mutator M;

  // Start Discord Link
  if (Link == none)
    Link = Spawn(class'DiscordReporter.DiscordReporterLink');

  if (Link == none)
  {
    Log("++ Error Spawning Discord Reporter Link Class!");
    return;
  }

  if (conf.bEnabled)
  {
    Log("++ Starting Connection Process...");
    Link.Connect(self, conf);
  }

  if (Spectator == None)
    Spectator = Level.Spawn(class'DiscordReporter.DiscordReporterSpectator');

  // Level.Game.BaseMutator.AddMutator(Level.Game.Spawn(class'DiscordReporterMutator'));
  // M = Level.Game.BaseMutator;

  // While (M.NextMutator != None)
  // {
  //   if (InStr(string(M.Class),"DiscordReporterMutator") != -1)
  //     break;
  //   else
  //     M = M.NextMutator;
  // }

  // Mut = DiscordReporterMutator(M);
  // Mut.Controller = self;
  // Mut.conf = conf;
  // Mut.Link = Link;

  Spectator.Engage(Self, Link);
}

// FUNCTION: Load the Team Names
function LoadTeamNames()
{
  if (Level.Game.GetPropertyText("RedTeamName") != "")
    conf.sTeams[0] = Level.Game.GetPropertyText("RedTeamName");
  else
    conf.sTeams[0] = conf.teamRed;
  if (Level.Game.GetPropertyText("BlueTeamName") != "")
    conf.sTeams[1] = Level.Game.GetPropertyText("BlueTeamName");
  else
    conf.sTeams[1] = conf.teamBlue;
  conf.sTeams[2] = conf.teamGreen;
  conf.sTeams[3] = conf.teamGold;

  conf.SaveConfig();
}

defaultproperties
{
  sVersion="0.1b"
  sBuild="05/06/2017"
}
