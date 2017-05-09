class DiscordReporterLink extends UBrowserBufferedTCPLink;

var bool bIsConnected;
var IpAddr ServerIpAddr;
// var string UserIdent, ReporterNick;
// var int NickCounter;
// var int iTimerType;
// var bool SwitchLink;
// var localized string FullName;
var DiscordReporter Controller;
var DiscordReporterConfig conf;
var DiscordReporterSpectator Spec;
// var float iFloodCount, iFloodCurrent, xAFloodDelay;
// var string sQueue[32];
// var int ifHead, ifFoot, ifCount;
// var float GameSpeed;
// var bool bUTGLEnabled;

// FUNCTION: Connect / Startup (INIT)
function Connect(DiscordReporter InController, DiscordReporterConfig InConfig)
{
  local int i;

  // Get the Variables passed from the Controller
  Controller = InController;
  conf = InConfig;
  bIsConnected = FALSE;

  ResetBuffer();

  ServerIpAddr.Port = conf.DiscordBotPort;
  Resolve(conf.DiscordBotHost);
}

function Disconnect()
{
  SendQuit("Disconnecting Discord Bot.");
  bIsConnected = FALSE;
  Close();
}

// FUNCTION (EVENT): Resolved / Resolved IP Address
function Resolved(IpAddr Addr)
{
  ServerIpAddr.Addr = Addr.Addr;

  if (BindPort() == 0)
  {
    Log("++ Failed to resolve Discord Bot port.");
    return;
  }

  Log("++ Successfully resolved Server IP Address.");
  Open(ServerIpAddr);
}

function ResolveFailed()
{
  Log("++ Failed to resolve Discord Bot host.");
}

// EVENT: Opened / Discord Bot Link Opened
event Opened()
{
  Log("++ Link to Discord Bot is open.");
  Enable('Tick');
  GotoState('LoggingIn');
}

// EVENT: Closed
event Closed()
{
  Log("++ Lost connection to server.");
  // TODO: Should we reconnect?
}

// STATE: LoggingIn / Logging In to Discord Bot
state LoggingIn
{
  function ProcessInput(string Line)
  {
    // Unauthorized
    if (Line == "401") {
      Log("++ Disconnecting Discord Bot.");
      Disconnect();
      return;
    }

    // Authorized
    else if (Line == "200") {
      Log("++ Switching state to 'LoggedIn'");
      GotoState('LoggedIn');
    }

    Global.ProcessInput(Line);
  }

  Begin:
    Log("++ Logging in...");
    SendText("PASS" @ conf.Password $ LF);
}

// STATE: LoggedIn / Logged In to Server
state LoggedIn
{
  function ProcessInput(string Line)
  {
    Global.ProcessInput(Line);
  }

  Begin:
    Log("++ Successfully connected to the Discord Bot");

    // Initialize in 5 seconds
    // iTimerType = 2;
    // SetTimer(5, FALSE);
    bIsConnected = TRUE;
}

// FUNCTION: PostBeginPlay
function PostBeginPlay()
{
  Super.PostBeginPlay();
  Disable('Tick');
}

// FUNCTION: Tick
function Tick(float DeltaTime)
{
  local string Line;

  // SendLine();
  DoBufferQueueIO();

  if (ReadBufferedLine(Line))
    ProcessInput(Line);
}

// FUNCTION ProccessInput / Standard Processing Function
function ProcessInput(string Line)
{
  if (conf.bDebug)
    Log("++ [Debug]:" @ Line);
}

// Send a Message
function SendMessage(string msg)
{
  if ((conf.bMuted == FALSE) && (bIsConnected))
  {
    // Log("++ [Debug]: "$msg);
    // SendBufferedData("PRIVMSG #channel: " $msg$CRLF);
    SendBufferedData("" $ msg $ CRLF);
  }
}

// Send a Notice
function SendNotice(string nick, string msg)
{
  if (bIsConnected)
    SendBufferedData("@" $ nick $ ":" @ msg $ CRLF);
}

// function AddLine(string line)
// {
//   local int ilHead;
//   ilHead = (ifHead + 1) % 32;
//   if (ilHead != ifFoot) {
//     sQueue[ifHead] = line;
//     ifHead = ilHead;
//     ifCount = Min(ifCount + 1, 32);
//   }
// }

// Quit from Discord Bot
function SendQuit(string msg)
{
  if (bIsConnected)
    SendBufferedData("QUIT:" @ msg $ CRLF);
}

defaultproperties
{
}
