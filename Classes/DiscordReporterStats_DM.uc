class DiscordReporterStats_DM extends DiscordReporterStats;

var int iTimerCnt;
var int xGInfoDelay, xGDetailsDelay, xSDetailsDelay;
var TournamentGameReplicationInfo TGRI;
var int iRowKills[64];
var bool bGameOver, bFirstRun, bDoneAd;

// Override Initialization Function
function Initialize()
{
  super.Initialize();
  TGRI = TournamentGameReplicationInfo(GRI);

  // Initiate Class Timer
  SetTimer(3, TRUE);
}

// Override InClientMessage Function
function InClientMessage(coerce string S, optional name Type, optional bool bBeep)
{
  local string sNick, sMessage;
  local bool bIsSpec;
  local bool bSend;
  local int i;
  local PlayerReplicationInfo lPRI;
  bIsSpec = FALSE;
  bSend = TRUE;

  sNick = Link.ParseDelimited(S, ":", 1);
  if (Len(sNick) > 0) {
    sMessage = Link.ParseDelimited(S, ":", 2, TRUE);

    for (i = 0; i<32; i++)
    {
      lPRI = TGRI.PRIArray[i];

      if (lPRI == None)
        continue;

      if (lPRI.PlayerName == sNick && lPRI.bIsSpectator)
      {
        bIsSpec = TRUE;
        SendMessage(bold(sNick) $ ": " $ sMessage);
      }
    }
  }

  /*
  if (!bIsSpec)
    SendMessage(conf.colGen $ "* " $ S);
  */

  if (!bIsSpec) {
    if (conf.bSilent) {
      // Allow entered or left
      if (InStr(S, "entered the game") > 0 || InStr(S, "left the game") > 0) {
        bSend = TRUE;
      }
      // Allow admin login or logout
      else if (InStr(S, "became a server administrator") > 0 || InStr(S, "gave up administrator abilities") > 0) {
        bSend = TRUE;
      }
      // Skip all other messages
      else {
        bSend = FALSE;
      }
    }

    // Send message?
    if (bSend)
      SendMessage(S);
  }

  // Check wheater we have a JOIN Message!
  // If so -> reset Kills in a row to zer0
  if (InStr(S, "entered the game") > 0)
  {
    sNick = Link.ParseDelimited(S, " ", 1);
    for (i = 0; i < 32; i++)
    {
      lPRI = TGRI.PRIArray[i];
      if ((lPRI != none) && (lPRI.PlayerName == sNick))
        iRowKills[i] = 0;
    }
  }
}

// Override InTeamMessage Function
function InTeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep)
{
  SendMessage(bold(PRI.PlayerName) $ ": " $ Lower(S));
}

// Censor
static final function string Lower(coerce string Text)
{
  local int IndexChar;
  for (IndexChar = 0; IndexChar < Len(Text); IndexChar++)
    if (Mid(Text, IndexChar, 1) >= "A" &&
        Mid(Text, IndexChar, 1) <= "Z")
      Text = Left(Text, IndexChar) $ Chr(Asc(Mid(Text, IndexChar, 1)) + 32) $ Mid(Text, IndexChar + 1);
  return Text;
}

// Replace for censor
static final function string ReplaceText(coerce string Text, coerce string Replace, coerce string With)
{
  local int i;
  local string Output;

  i = InStr(Text, Replace);
  while (i != -1) {
    Output = Output $ Left(Text, i) $ With;
    Text = Mid(Text, i + Len(Replace));
    i = InStr(Text, Replace);
  }
  Output = Output $ Text;
  return Output;
}

// Override InLocalizedMessage Function
function InLocalizedMessage(class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
  local string sHigh;
  sHigh = "";

  // If we have Sudden Death Overtime -> Highlight Message
  if (ClassIsChildOf(Message, class'BotPack.DeathMatchMessage'))
  {
    switch(Switch)
    {
      // Overtime :)
      case 0:
        sHigh = conf.colHigh;
        break;
      // Team Change
      case 3:
        // SendMessage(conf.colGen$"* "$conf.colHead$RelatedPRI_1.PlayerName$" is now on " $ GetTeamColor(RelatedPRI_1.Team) $ TeamInfo(OptionalObject).TeamName);
        SendMessage(bold(RelatedPRI_1.PlayerName) @ "is now on" @ bold(TeamInfo(OptionalObject).TeamName));
        return;
    }
  }

  // If we have a first bl00d message -> activate highlight
  if (ClassIsChildOf(Message, class'BotPack.FirstBloodMessage'))
    sHigh = conf.colHigh;

  // Send Message
  SendMessage(GetColoredMessage("", sHigh, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));

  // Check for Killing Sprees
  if (ClassIsChildOf(Message, class'BotPack.DeathMessagePlus'))
    ProcessKillingSpree(Switch, RelatedPRI_1, RelatedPRI_2);
}

// Override InVoiceMessage Function
function InVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
  local string sMsg;
  sMsg = GetClientVoiceMessageString(Sender, Recipient, messagetype, messageID);
  if (Len(sMsg) > 0)
  {
    // SendMessage(GetTeamColor(Sender.Team)$Sender.PlayerName$": "$conf.colBody$sMsg);
    SendMessage(bold(Sender.PlayerName) $ ": " $ sMsg);
  }
}

// Send the message
function SendMessage(string msg, optional bool bNoTime)
{
  // local string Time;
  local float Time;
  local string Message;

  // Check is null or blank
  if (msg == "" || msg == conf.colHead)
    return;

  // Check if EUT MMI's are in the message
  if (conf.xReportMMI == False)
  {
    if (InStr(Caps(msg), Caps("[MMI]")) != -1)
    {
      if (Mid(msg, 5, 2) == "[]")
        return;
    }
  }

  // Add Time to message if neccessary
  if (bNoTime)
    Message = msg;
  else
  {
    // Get the Time (Remaining / Elapsed)
    if (TGRI.TimeLimit == 0)
      Time = TGRI.ElapsedTime;
    else
      Time = TGRI.RemainingTime;

    // Message = "`[" $ GetStrTime(Time) $ "]`" @ msg;
    Message = "[" $ GetStrTime(Time) $ "]" @ msg;
  }

  // Send Message to our Link Class
  Link.SendMessage(Message);
}

// Recieve ad
function OnAdvertise()
{
  if (conf.AdMessage != "")
    BroadCastMessage(conf.AdMessage);

  bDoneAd = True;
}

// Our Timer Event
event Timer()
{
  if (!Link.bIsConnected)
    return;

  // Beim ersten durchlauf!
  if ((iTimerCnt == 0) && (bFirstRun == TRUE))
  {
    bFirstRun = FALSE;
    SendMessage("`Discord Reporter " $ Link.Controller.sVersion $ " by snap`", TRUE);
    SendMessage(GetGameInfo());
  }

  // Advertising
  if (!bDoneAd && conf.bAdvertise)
  {
    if (TGRI.Timelimit == 0)
    {
      if (TGRI.ElapsedTime > 0)
        OnAdvertise();
    }
    else
    {
      if ((TGRI.Timelimit * 60 - TGRI.RemainingTime) > 0)
        OnAdvertise();
    }
  }

  // Map Info (Mapname/Gamename/ServerURL)
  if ((iTimerCnt % xGInfoDelay) == 0)
  {
    if ((TGRI.NumPlayers > 0) && (iTimerCnt != 0))
      SendMessage(GetGameInfo());
  }

  // Detailed Game Information
  if (((iTimerCnt % xGDetailsDelay) == 0) && (iTimerCnt > 0) && (TGRI.NumPlayers > 0))
  {
    if (!Level.Game.bGameEnded)
      OnGameDetails();
  }

  // Detailed Score Information
  if (((iTimerCnt % xSDetailsDelay) == 0) && (iTimerCnt > 0) && (TGRI.NumPlayers > 0))
  {
    if (!Level.Game.bGameEnded)
      OnScoreDetails();
  }

  // Check whether the game is over or not
  if (Level.Game.bGameEnded && (!bGameOver))
  {
    bGameOver = TRUE;
    OnGameOver();
  }

  // Increase Counter 4 Timer
  if (iTimerCnt > 3600)
    iTimerCnt = 0;
  else
    iTimerCnt += 5;
}

// Additional Functions

// Get Team Color (may be inherited!)
function string GetTeamColor(byte iTeam)
{
  return ircColor $ "02";
}

// Get a Colored Message !!
// SendMessage(GetColoredMessage("", sHigh, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
function string GetColoredMessage(string sPreFix, string sHighLight, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
  local string sMsg, sPlayer_1, sPlayer_2;
  // Set Playernames with Colors!
  if (RelatedPRI_1 != None)
  {
    sPlayer_1 = RelatedPRI_1.PlayerName;
    // RelatedPRI_1.PlayerName = GetTeamColor(RelatedPRI_1.Team)$sPlayer_1 $ sHighLight;
    RelatedPRI_1.PlayerName = sPlayer_1 $ sHighLight;
  }
  if (RelatedPRI_2 != None)
  {
    sPlayer_2 = RelatedPRI_2.PlayerName;
    // RelatedPRI_2.PlayerName = GetTeamColor(RelatedPRI_2.Team)$sPlayer_2 $ sHighLight;
    RelatedPRI_2.PlayerName =sPlayer_2 $ sHighLight;
  }

  // Send Message
  sMsg = sHighLight $ sPreFix $ Message.static.GetString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

  // Restore Player Names
  if (RelatedPRI_1 != None)
    RelatedPRI_1.PlayerName = sPlayer_1;
  if (RelatedPRI_2 != None)
    RelatedPRI_2.PlayerName = sPlayer_2;

  return sMsg;
}

// Process Killing Sprees.
function ProcessKillingSpree(int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
  local int iID_1, iID_2;
  iID_1 = RelatedPRI_1.PlayerID;

  // Player made a suicide
  if (RelatedPRI_2 == none)
  {
    // If the Player was on a spree -> tell end Message
    if (iRowKills[iID_1] > 4)
      SendMessage(bold(RelatedPRI_1.PlayerName) @ "was looking good, until he killed himself!");

    iRowKills[iID_1] = 0;
  }
  else
  {
    // Switch 0 or 8 means a frag occured!
    // Report sprees?
    if (conf.xReportSprees)
    {
      // Enhanced sprees?
      if (conf.xEnhancedSprees)
      {
        iID_2 = RelatedPRI_2.PlayerID;

        if (conf.xReportESprees)
        {
          if (iRowKills[iID_2] > 4 && iRowKills[iID_2] < 10)
            SendMessage(bold(RelatedPRI_2.PlayerName) $ "'s Killing Spree was ended by" @ bold(RelatedPRI_1.PlayerName) $ "!");
          if (iRowKills[iID_2] > 9 && iRowKills[iID_2] < 15)
            SendMessage(bold(RelatedPRI_2.PlayerName) $ "'s Rampage was ended by" @ bold(RelatedPRI_1.PlayerName) $ "!");
          if (iRowKills[iID_2] > 14 && iRowKills[iID_2] < 20)
            SendMessage(bold(RelatedPRI_2.PlayerName) $ "'s Dominating Spree was ended by" @ bold(RelatedPRI_1.PlayerName) $ "!");
          if (iRowKills[iID_2] > 19 && iRowKills[iID_2] < 25)
            SendMessage(bold(RelatedPRI_2.PlayerName) $ "'s Unstoppable Spree was ended by" @ bold(RelatedPRI_1.PlayerName) $ "!");
          if (iRowKills[iID_2] > 24 && iRowKills[iID_2] < 30)
            SendMessage(bold(RelatedPRI_2.PlayerName) $ "'s Godlike Spree was ended by" @ bold(RelatedPRI_1.PlayerName) $ "!");
          if (iRowKills[iID_2] > 29)
            SendMessage(bold(RelatedPRI_2.PlayerName) $ "'s Wicked Sick Spree was ended by" @ bold(RelatedPRI_1.PlayerName) $ "!");
        }

        iRowKills[iID_2] = 0;
        iRowKills[iID_1] += 1;

        if (conf.xReportBSprees)
        {
          switch (iRowKills[iID_1])
          {
            case 5:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is on a Killing Spree!"); break;
            case 10:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is on a Rampage!"); break;
            case 15:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is Dominating!"); break;
            case 20:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is Unstoppable!"); break;
            case 25:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is Godlike!"); break;
            case 30:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is W I C K E D  S I C K"); break;
          }
        }
      }
      else
      {
        iID_2 = RelatedPRI_2.PlayerID;

        if (conf.xReportESprees)
        {
          if (iRowKills[iID_2] > 4)
            SendMessage(bold(RelatedPRI_2.PlayerName) $ "'s Killing Spree was ended by" @ bold(RelatedPRI_1.PlayerName) $ "!");
        }

        iRowKills[iID_2] = 0;
        iRowKills[iID_1] += 1;

        if (conf.xReportBSprees)
        {
          switch (iRowKills[iID_1])
          {
            case 5:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is on a Killing Spree!"); break;
            case 10:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is on a Rampage!"); break;
            case 15:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is Dominating!"); break;
            case 20:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is Unstoppable!"); break;
            case 25:
              SendMessage(bold(RelatedPRI_1.PlayerName) @ "is Godlike!"); break;
          }
        }
      }
    }
  }
}

function bool CheckGameOver()
{
  if (Level.Game.bGameEnded)
    return TRUE;
  else
    return FALSE;
}

// Game Over event
function OnGameOver()
{
  SendMessage("Game has ended!");
  PostPlayerStats();
}

// Detailed Game Information
function OnGameDetails()
{
  local int i;
  local PlayerReplicationInfo lPRI, bestPRI;

  // Get the best PRI
  for (i = 0; i < 32; i++)
  {
    lPRI = TGRI.PRIArray[i];
    if (lPRI == None)
      continue;
    if (bestPRI == None)
      bestPRI = TGRI.PRIArray[i];
    if (bestPRI.Score <= lPRI.Score)
      bestPRI = TGRI.PRIArray[i];
  }

  // Post Stuff
  // SendMessage(" ");
  SendMessage("Game Details:");
  SendMessage("Timelimit / Fraglimit:" @ TGRI.TimeLimit @ "/" @ TGRI.Fraglimit);
  // SendMessage("> " $ GetTeamColor(bestPRI.Team) $ bestPRI.PlayerName $ conf.colHead $ " is in the lead with"$conf.colHigh$" "$string(int(bestPRI.Score))$conf.colHead$" frags!");
  SendMessage(bold(bestPRI.PlayerName) @ "is in the lead with" @ bold(string(int(bestPRI.Score))) @ "frags!");
  // SendMessage(" ");
}

// Detailed Score Information
function OnScoreDetails()
{
}

// Post Player Statistics
function PostPlayerStats()
{
  local int i;
  local PlayerReplicationInfo lPRI;
  local string sBot;

  // SendMessage(" ", TRUE);
  SendMessage("Final Player Status:", TRUE);

  // if (Link.bUTGLEnabled)
  //   SendMessage(conf.colHead$PostPad("Name", 22, " ") $ "| " $ PrePad("Login", 15, " ") $ "| " $ PrePad("Frags", 5, " ") $ " | " $ PrePad("Death", 5, " ") $ " | " $ PrePad("Ping", 4, " ") $ " | " $ PrePad("PL", 4, " ") $ " |", TRUE);
  // else
  //   SendMessage(conf.colHead$PostPad("Name", 22, " ") $ "| " $ PrePad("Frags", 5, " ") $ " | " $ PrePad("Death", 5, " ") $ " | " $ PrePad("Ping", 4, " ") $ " | " $ PrePad("PL", 4, " ") $ " |", TRUE);
  SendMessage(PostPad("Name", 22, " ") $ "|" @ PrePad("Frags", 5, " ") @ "|" @ PrePad("Death", 5, " ") @ "|" @ PrePad("Ping", 4, " ") @ "|" @ PrePad("PL", 4, " ") @ "|", TRUE);

  for (i = 0; i < 32; i++) {
    lPRI = TGRI.PRIArray[i];
    if (lPRI==None)
      continue;
    if (!lPRI.bIsSpectator)
    {
      if (lPRI.bIsABot) sBot = " (Bot)";
      else sBot = "";

      // if (Link.bUTGLEnabled)
      //   SendMessage("> "$conf.colHead$PostPad(lPRI.PlayerName $ sBot, 20, " ") $ conf.colHead $ "| " $ conf.colBody $ PrePad(Spec.ServerMutate("getlogin "$lPRI.PlayerName), 15, " ") $ "| " $ conf.colBody $ PrePad(string(int(lPRI.Score)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(int(lPRI.Deaths)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(lPRI.Ping), 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(lPRI.PacketLoss)$"%", 4, " ") $ conf.colHead $ " |", TRUE);
      // else
      //   SendMessage("> "$conf.colHead$PostPad(lPRI.PlayerName $ sBot, 20, " ") $ conf.colHead $ "| " $ conf.colBody $ PrePad(string(int(lPRI.Score)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(int(lPRI.Deaths)), 5, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(lPRI.Ping), 4, " ") $ conf.colHead $ " | " $ conf.colBody $ PrePad(string(lPRI.PacketLoss)$"%", 4, " ") $ conf.colHead $ " |", TRUE);
      SendMessage(PostPad(lPRI.PlayerName $ sBot, 20, " ") @ "|" @ PrePad(string(int(lPRI.Score)), 5, " ") @ "|" @ PrePad(string(int(lPRI.Deaths)), 5, " ") @ "|" @ PrePad(string(lPRI.Ping), 4, " ") @ "|" @ PrePad(string(lPRI.PacketLoss)$"%", 4, " ") @ "|", TRUE);
    }
  }

  // SendMessage(" ", TRUE);
}

// Set the GameInformation
function string GetGameInfo()
{
  return "Currently Playing: **" $ Level.Title @ "(" $ TGRI.GameName $ ")** on" @ bold(Level.Game.GameReplicationInfo.ServerName);
}


///////////////////////////////////////////////////////////////////

// Query of the Current Map (overriden)
function QueryMap(string sNick)
{
  Link.SendNotice(sNick, "Currently Reporting:" @ GetGameInfo());
}

// Query of the Current Gameinfo (overridden)
function QueryInfo(string sNick)
{
  // Send some nifty stuff to the user!
  Link.SendNotice(sNick, "Detailed Game Information for" @ bold(Level.Title) $ ":");
  Link.SendNotice(sNick, "Timelimit / Fraglimit:" @ bold(TGRI.TimeLimit @ "/" @ TGRI.Fraglimit));
  if (TGRI.TimeLimit > 0)
    Link.SendNotice(sNick, "Time Remaining:" @ GetStrTime(TGRI.RemainingTime));
  else
    Link.SendNotice(sNick, "Elapsed Time:" @ GetStrTime(TGRI.ElapsedTime));
}

// Query of the Current Spectator List (overridden)
function QuerySpecs(string sNick)
{
  local int i, iNum;
  local Spectator lSpec;

  Link.SendNotice(sNick, "Spectator List for" @ bold(Level.Game.GameReplicationInfo.ServerName) $ ":");

  // List our Speccs
  iNum = 0;
  foreach AllActors(class'Spectator', lSpec)
  {
    if (lSpec.bIsPlayer && NetConnection(lSpec.Player) != None)
    {
      // if (Link.bUTGLEnabled)
      //   Link.SendNotice(sNick, "> "$lSpec.PlayerReplicationInfo.PlayerName$" - Login: "$Spec.ServerMutate("getlogin "$lSpec.PlayerReplicationInfo.PlayerName));
      // else
      //   Link.SendNotice(sNick, "> "$lSpec.PlayerReplicationInfo.PlayerName);
      Link.SendNotice(sNick, lSpec.PlayerReplicationInfo.PlayerName);

      iNum++;
    }
  }

  if (iNum == 0)
    Link.SendNotice(sNick, "No specs on server!");
}

// Query of the Current Player List (overridden)
function QueryPlayers(string sNick)
{
  local int i, iNum;
  local string sMessage;
  local TournamentPlayer lPlr;
  local PlayerReplicationInfo lPRI;

  Link.SendNotice(sNick, "Player List for" @ bold(Level.Game.GameReplicationInfo.ServerName) $ ":");
  iNum = 0;
  foreach AllActors(class'TournamentPlayer', lPlr)
  {
    lPRI = lPlr.PlayerReplicationInfo;
    if (iNum > 0) sMessage = sMessage $ ", ";

    // if (Link.bUTGLEnabled)
    //   sMessage = sMessage $ lPRI.PlayerName $ " - Login: "$Spec.ServerMutate("getlogin "$lPRI.PlayerName)$" ("$string(int(lPRI.Score))$")";
    // else
    //   sMessage = sMessage $ lPRI.PlayerName $ " ("$string(int(lPRI.Score))$")";
    sMessage = sMessage $ lPRI.PlayerName @ "(" $ string(int(lPRI.Score)) $ ")";

    iNum++;
  }

  if (iNum == 0)
    sMessage = "No players on server!";

  Link.SendNotice(sNick, sMessage);
}

// Query of the Current Scores (overridden)
function QueryScore(string sNick)
{
  QueryPlayers(sNick);
}

defaultproperties
{
   xGInfoDelay=300
   xGDetailsDelay=240
   xSDetailsDelay=120
   bFirstRun=True
}
