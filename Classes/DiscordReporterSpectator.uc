class DiscordReporterSpectator extends MessagingSpectator;

var DiscordReporter Controller;
var DiscordReporterLink Link;
var DiscordReporterStats Stats;
var string LastMessage;

// Init Function
function Engage(DiscordReporter InController, DiscordReporterLink InLink)
{
  local Class<DiscordReporterStats> StatsClass;
  local DiscordReporterMutator_1on1 Mut1on1;
  local Actor OutActor;
  local Mutator M;
  local string GameClass;
  local bool bOneOnOne;

  Controller = InController;
  Link = InLink;

  // 1 on 1 is only applied for DM
  GameClass = caps(GetItemName(string(Level.Game.Class)));
  if (GameClass == "DEATHMATCHPLUS" || GameClass == "EUTDEATHMATCHPLUS")
  {
    if (Level.Game.MaxPlayers == 2)
    {
      StatsClass = class'DiscordReporterStats_1on1';
      bOneOnOne = True;
    }
    else
      StatsClass = class'DiscordReporterStats_DM';
  }
  else if (GameClass == "TEAMGAMEPLUS" || GameClass == "EUTTEAMGAMEPLUS")
  {
    StatsClass = class'DiscordReporterStats_TDM';
  }
  else if (GameClass == "CTFGAME")
  {
    StatsClass = class'DiscordReporterStats_CTF';
  }
  else if (GameClass == "SMARTCTFGAME")
  {
    StatsClass = class'DiscordReporterStats_EUT';
  }
  else if (GameClass == "DOMINATION")
  {
    StatsClass = class'DiscordReporterStats_DOM';
  }
  else if (GameClass == "LASTMANSTANDING")
  {
    StatsClass = class'DiscordReporterStats_LMS';
  }
  else if (Left(string(Level), 3) == "BT-" || Left(string(Level), 5) == "CTF-BT-")
  {
    StatsClass = class'DiscordReporterStats_BT';
  }
  else
    StatsClass = class'DiscordReporterStats_DM';

  // Is 1v1?
  if (Controller.conf.bExtra1on1Stats && (bOneOnOne))
  {
    Level.Game.BaseMutator.AddMutator(Level.Game.Spawn(class'DiscordReporterMutator_1on1'));
    M = Level.Game.BaseMutator;

    while (M.NextMutator != None)
    {
      if (InStr(string(M.Class), "DiscordReporterMutator_1on1") != -1)
        break;
      else
        M = M.NextMutator;
    }

    Mut1on1 = DiscordReporterMutator_1on1(M);
    Mut1on1.Link = Link;
    Mut1on1.conf = Controller.conf;
  }

  // Spawn Actor
  Stats = Spawn(StatsClass);

  // Check if spawn was success
  if (Stats == none)
    Log("++ Unable to spawn Stats Class!");
  else
  {
    Stats.Link = Link;
    Link.Spec = self;

    if ( Mut1on1 != None)
      Mut1on1.Stats = DiscordReporterStats_1on1(Stats);

    Stats.Spec = self;
    Stats.conf = Controller.conf;
    Stats.Level = Level;
    Stats.GRI = Level.Game.GameReplicationInfo;
    Stats.Initialize();
  }
}

function ClientMessage(coerce string S, optional name Type, optional bool bBeep)
{
  if (Type == 'None')
    LastMessage=S;
  if (Stats != None)
    Stats.InClientMessage(S, Type, bBeep);
}

function TeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep)
{
  Stats.InTeamMessage(PRI, S, Type, bBeep);
}

function ReceiveLocalizedMessage(class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
  Stats.InLocalizedMessage(Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

function ClientVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
  Stats.InVoiceMessage(Sender, Recipient, messagetype, messageID);
}

function string ServerMutate(string MutateString)
{
  local String Str;
  local Mutator Mut;
  Mut = Level.Game.BaseMutator;
  Mut.Mutate(MutateString, Self);
  return LastMessage;
}

defaultproperties
{
}
