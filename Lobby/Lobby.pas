unit Lobby;

interface

uses
  SysUtils, PangyaClient, PangyaBuffer, PacketData,
  ClientPacket, GameBase, Tools,
  GameList, IffMain, IffManager.GrandPrixData, Utils, UWriteConsole,
  MyList, PacketCreator, Defines, DateUtils, Enum, ItemData, TimerQueue,
  GameModeChat, GameModeStroke, GameModeMatch, GameModePractice;

type
  TPlayerList = TMyList<TClientPlayer>;

  TLobby = class
  private
    var FLobbyID: UInt8;

    var FLobbyName: AnsiString;
    var FLobbyMaxPlayer: UInt16;
    var ClientList: TPlayerList;

    var fGameList: TGameList;
    var FGameFree: TMyList<TGameBase>;

    procedure CreateGameEvent(GameHandle: TGameBase);
    procedure DestroyGameEvent(GameHandle: TGameBase);
    procedure UpdateGameEvent(GameHandle: TGameBase);

    procedure PlayerJoinGameEvent(GameHandle: TGameBase; player: TClientPlayer);
    procedure PlayerLeaveGameEvent(GameHandle: TGameBase; player: TClientPlayer);

    function GetGameHandle(Player: TClientPlayer): TGameBase; overload;
    function GetGameHandle(GameID: Uint16): TGameBase; overload;

    function BuildPlayerLists: TClientPacket;
    function BuildGameLists: AnsiString;

    function CreateGame(const PL: TClientPlayer; GameData: TGameInfo): TGameBase;
    procedure FreeGame;
  public
    function Build: TPacketData;

    procedure DestroyGame(GameHandle: TGameBase);

    function AddPlayer(Player: TClientPlayer): Boolean;
    procedure RemovePlayer(Player: TClientPlayer);

    procedure Send(const Data: AnsiString); overload;
    procedure Send(Data: TPangyaBuffer); overload;
    procedure Write(Data: TClientPacket);

    procedure JoinMultiplayerGamesList(Player: TClientPlayer);
    procedure LeaveMultiplayerGamesList(Player: TClientPlayer);

    procedure PlayerSendChat(Player: TClientPlayer; const Messages: AnsiString);
    procedure UpdatePlayerLobbyInfo(Player: TClientPlayer);
    function GetPlayerByConnectionId( ConnectionId : UInt32): TClientPlayer;

    procedure PlayerCreateGame(Const CP : TClientPacket; Player : TClientPlayer);
    procedure PlayerLeaveGame(Const clientPacket : TClientPacket; Player : TClientPlayer);
    procedure PlayerLeaveGP(const clientPacket: TClientPacket; Player: TClientPlayer);

    procedure PlayerJoinGame(Const clientPacket : TClientPacket; Player : TClientPlayer);
    procedure PlayerJoinGrandPrix(Const clientPacket : TClientPacket; Player : TClientPlayer);
    procedure PlayerRequestGameInfo(Const clientPacket : TClientPacket; Player : TClientPlayer);

    constructor Create(const Name: AnsiString; MaxPlayer: UInt16);
    destructor Destroy; override;
    property LobbyID: UInt8 read FLobbyID write FLobbyID;
    property LobbyName: AnsiString read FLobbyName;
    property MaxPlayer: UInt16 read FLobbyMaxPlayer;
    property PlayerCount: TPlayerList read ClientList;

    property GameHandle[GameID: UInt16]: TGameBase read GetGameHandle; default;
    property GameHandle[Player: TClientPlayer]: TGameBase read GetGameHandle; default;
  end;

implementation

{ TLobby }

function TLobby.AddPlayer(Player: TClientPlayer): Boolean;
begin
  if not (ClientList.Add(Player) = -1) then
  begin
    Player.Lobby := Self;
    Exit(True);
  end;
  Exit(False);
end;

function TLobby.Build: TPacketData;
begin
  Exit(LobbyInfo(Self.LobbyName, FLobbyMaxPlayer, ClientList.Count, LobbyID));
end;

function TLobby.BuildGameLists: AnsiString;
var
  Game: TGameBase;
  Packet: TClientPacket;
  Reply: TClientPacket;
  Count: UInt16;
begin
  Count := 0;
  Packet := TClientPacket.Create;
  Reply := TClientPacket.Create;
  try
    Packet.WriteStr(#$47#$00);
    for Game in Self.fGameList.Games do
    begin
      if (Game.GameType = HOLE_REPEAT) or (Game.Terminating) then
        Continue;

      Reply.WriteStr(Game.GameInformation);
      Inc(Count);
    end;
    Packet.WriteUInt16(Count);
    Packet.WriteStr(#$FF#$FF);
    Packet.WriteStr(Reply.ToStr);
    Exit(Packet.ToStr);
  finally
    Reply.Free;
    Packet.Free;
  end;
end;

function TLobby.BuildPlayerLists: TClientPacket;
var
  Player: TClientPlayer;
  Packet: TClientPacket;
  Count: UInt16;
begin
  Result := TClientPacket.Create;
  Packet := TClientPacket.Create;
  Count := 0;
  try
    with Result do
    begin
      Result.WriteStr(#$46#$00);
      Result.WriteUInt8(4); // Show Player Lists
      for Player in ClientList do
      begin
       if Player.InLobby then
       begin
         Inc(Count);
         Packet.WriteStr(Player.GetLobbyInfo);
       end;
      end;
      Result.WriteUInt8(Count);
      Result.WriteStr(Packet.ToStr);
    end;
  finally
    Packet.Free;
  end;
end;

constructor TLobby.Create(const Name: AnsiString; MaxPlayer: UInt16);
begin
  ClientList := TMyList<TClientPlayer>.Create;
  FLobbyMaxPlayer := MaxPlayer;
  FLobbyName := Name;

  fGameList := TGameList.Create;
  FGameFree := TMyList<TGameBase>.Create;

  Sched.AddSchedule(5000, Self.FreeGame);
end;

destructor TLobby.Destroy;
begin
  ClientList.Free;
  fGameList.Free;
  inherited;
end;

procedure TLobby.DestroyGame(GameHandle: TGameBase);
begin
  { send room destroy to all lobby }
  Self.DestroyGameEvent(GameHandle);

  GameHandle.Terminating := True;
  GameHandle.TerminateTime := IncSecond(Now(), 5);
  { remove from game list }
  fGameList.Games.Remove(GameHandle);
  { add game handle to deleted queue }
  FGameFree.Add(GameHandle);
end;

function TLobby.GetGameHandle(Player: TClientPlayer): TGameBase;
begin
  Exit(fGameList.GameHandle[Player.GameID]);
end;

function TLobby.GetGameHandle(GameID: Uint16): TGameBase;
begin
  Exit(fGameList.GameHandle[GameID]);
end;

function TLobby.GetPlayerByConnectionId(ConnectionId: UInt32): TClientPlayer;
var
  Client : TClientPlayer;
begin
  for Client in ClientList do begin
    if Client.connectionId = ConnectionId then
    begin
      Exit(Client);
    end;
  end;
  Exit(nil);
end;

{
 02 : The Room is full
 03 : The Room is not exist
 04 : wrong password
 05 : you cannot get in this room level
 07 : can not create game
 08 : game is in progress
}

procedure TLobby.PlayerCreateGame(Const CP : TClientPacket; Player: TClientPlayer);
var
  GameHandle: TGameBase;
  GameData: TGameInfo;
begin
  if not CP.Read(GameData.Unknown1, $E) then Exit;

  if (GameData.GameType = HOLE_REPEAT) and (CP.GetSize = 68) then
  begin
    if not CP.Read(GameData.HoleNumber, $9) then Exit;
  end else begin
    GameData.HoleNumber := 0;
    GameData.LockHole := 0;
    if not CP.Read(GameData.NaturalMode, $4) then Exit;
  end;

  if not CP.ReadPStr(GameData.Name) then Exit;
  if not CP.ReadPStr(GameData.Password) then Exit;
  if not CP.ReadUInt32(GameData.Artifact) then Exit;

  GameData.GP := False;
  GameData.GPTypeID := 0;
  GameData.GPTypeIDA := 0;
  GameData.GPTime := 0;

  { GM Event }
  if (Player.GetCapabilities = 4) and (GameData.MaxPlayer >= 100) then
    GameData.GMEvent := True
  else
    GameData.GMEvent := False;

  { Chat Room }
  if (GameData.GameType = CHAT_ROOM) and (Player.GetCapabilities = 4) then
  begin
    GameData.MaxPlayer := 100;
    GameData.GMEvent := True;
  end;

  GameHandle := Self.CreateGame(Player, GameData);
end;

procedure TLobby.PlayerJoinGrandPrix(const clientPacket: TClientPacket; Player: TClientPlayer);
  function ReDate(const GPDate: TDateTime): TDateTime;
  begin
    if GPDate < Now() then
      Exit(IncDay(GPDate, 1));

    Exit(GPDate);
  end;

  function Check(Hour, Min, HourEnd, MinEnd: Word): Boolean;
  var
    OpenDateTime: TDateTime;
    EndDateTime: TDateTime;
  begin
    if (Hour = 0) and (Min = 0) and (HourEnd = 0) and (MinEnd = 0) then
    begin
      Exit(True);
    end;
    OpenDateTime := CreateGPDateTime(Hour, Min);
    EndDateTime := ReDate(CreateGPDateTime(HourEnd, MinEnd));
    if DateTimeInRange(Now, OpenDateTime, EndDateTime, False) then
    begin
      Exit(True);
    end;
    Exit(False);
  end;
  function GPStart(Hour, Min: UInt16): Boolean;
  begin
    Exit( (Hour > 0) or (Min > 0) );
  end;
var
  GPTypeID: UInt32;
  GP: PGrandPrixData;
  GPGame: TGameBase;
  GameInfo: TGameInfo;
begin
  if not clientPacket.ReadUInt32(GPTypeID) then Exit;

  if not IffEntry.FGrandPrixData.IsGPExist(GPTypeID) then
  begin
    Player.Write(ShowRoomError(reRoomCreateFail));
    raise Exception.Create('PlayerJoinGrandPrix: GrandPrix''s typeid is not existed.');
  end;

  GP := IffEntry.FGrandPrixData.GetGP(GPTypeID);

  GPGame := fGameList.GetGPID(GPTypeID);

  if (GPGame = nil) or (GP.IsNovice = True) then
  begin
    WriteLn(DateTimeToStr(CreateGPDateTime(GP.Hour_Open, GP.Min_Open)));
    WriteLn(DateTimeToStr(ReDate(CreateGPDateTime(GP.Hour_End, GP.Min_End))));

    if not Check(GP.Hour_Open, GP.Min_Open, GP.Hour_End, GP.Min_End) then
    begin
      Player.Write(ShowRoomError(reRoomCreateFail));
      Exit;
    end;

    GameInfo.VSTime := 0;
    GameInfo.GameTime := 0;
    GameInfo.MaxPlayer := $1E;
    GameInfo.GameType := GRANDPRIX;// $14;
    GameInfo.HoleTotal := GP.TotalHole;
    GameInfo.Map := GP.Map;
    GameInfo.Mode := GP.Mode;
    GameInfo.NaturalMode := GP.Natural + (GP.ShortGame * 2);
    GameInfo.GP := True;
    GameInfo.GPTypeID := GP.TypeId;
    GameInfo.GPTypeIDA := GP.TrueTypeId;
    GameInfo.GPTime := GP.TimeHole * 1000;
    GameInfo.GMEvent := False;
    GameInfo.Name := GP.Name;
    GameInfo.Artifact := GP.Artifact;

    GPGame := Self.CreateGame(Player, GameInfo);
    //GPGame.AddPlayer(Player, True);

    if GPStart(GP.Hour_Start, GP.Min_Start) then
    begin
      //GPGame.SetGPTime(ReDate(CreateGPDateTime(GP.Hour_Start, GP.Min_Start)));
      //GPGame.StartGPCounter;
    end;
  end else begin
    GPGame.AddPlayer(Player);
  end;

  Player.Send(#$53#$02#$00#$00#$00#$00);
end;

procedure TLobby.PlayerLeaveGame(const clientPacket: TClientPacket; Player: TClientPlayer);
var
  GameHandle: TGameBase;
begin
  GameHandle := GetGameHandle(Player);
  if (GameHandle = nil) then
    Exit;
  GameHandle.RemovePlayer(Player);
end;

procedure TLobby.PlayerLeaveGP(const clientPacket: TClientPacket; Player: TClientPlayer);
var
  GameHandle: TGameBase;
begin
  GameHandle := GetGameHandle(Player);
  if GameHandle = nil then
  begin
    Exit;
  end;
  GameHandle.RemovePlayer(Player);
  //Player.Write(ShowLeaveGame);
  Player.Send(#$BA#$00 + GameTime);
  Player.Send(#$54#$02#$00#$00#$00#$00#$FF#$FF);
end;

procedure TLobby.PlayerJoinGame(Const clientPacket : TClientPacket; Player: TClientPlayer);
var
  GameID : UInt16;
  Password : AnsiString;
  GameHandle: TGameBase;
begin
  if not clientPacket.ReadUInt16(GameID) then Exit;
  if not clientPacket.ReadPStr(Password) then Exit;
  GameHandle := GetGameHandle(GameID);
  if GameHandle = nil then
  begin
    Player.Write(ShowRoomError(reRoomNotExist));
    Exit;
  end;
  if (Length(GameHandle.Password) > 0) and (Player.GetCapabilities < 4) then
  begin
    if not (GameHandle.Password = Password) then
    begin
      Player.Write(ShowRoomError(rePasswordError));
      Exit;
    end;
  end;
  GameHandle.AddPlayer(Player);
end;

procedure TLobby.PlayerRequestGameInfo(Const clientPacket : TClientPacket;
  Player: TClientPlayer);
var
  GameID : UInt16;
  GameHandle : TGameBase;
begin
  if not clientPacket.ReadUInt16(GameID) then Exit;

  GameHandle := GetGameHandle(GameID);

  if GameHandle = nil then
    Exit;

  //Player.Send(GameHandle.PlayerGetGameInfo); // : TODO ---------------------
end;

procedure TLobby.JoinMultiplayerGamesList(Player: TClientPlayer);
begin
  if player.InLobby then
    Exit;
  Player.InLobby := True; // Set Current User To Lobby
  Player.Write(BuildPlayerLists);
  Player.Send(BuildGameLists);
  // Send to All Player
  Write(ShowPlayerAction(Player, laSendLobby));
end;

procedure TLobby.LeaveMultiplayerGamesList(Player: TClientPlayer);
begin
  if Player.InLobby then
  begin
    Player.InLobby := False;
    Write(ShowPlayerAction(Player, laLeaveLobby));
  end;
end;

function TLobby.CreateGame(const PL: TClientPlayer; GameData: TGameInfo): TGameBase;
var
  GB: TGameBase;
begin
  if fGameList.Games.Count > 100 then
  begin
    Exit(nil);
  end;

  case GameData.GameType of
    VERSUS_STROKE,
    VERSUS_MATCH:
      begin
        Result := TGameStroke.Create(PL, GameData, CreateGameEvent, UpdateGameEvent, DestroyGame, PlayerJoinGameEvent, PlayerLeaveGameEvent, Self.fGameList.GetID);
      end;
    CHAT_ROOM:
      begin
        Result := TGameChat.Create(PL, GameData, CreateGameEvent, UpdateGameEvent, DestroyGame, PlayerJoinGameEvent, PlayerLeaveGameEvent, Self.fGameList.GetID);
      end;
    TOURNEY:
      begin
        Result := TGameMatch.Create(PL, GameData, CreateGameEvent, UpdateGameEvent, DestroyGame, PlayerJoinGameEvent, PlayerLeaveGameEvent, Self.fGameList.GetID);
      end;
    TOURNEY_TEAM: ;
    TOURNEY_GUILD: ;
    PANG_BATTLE: ;
    SSC: ;
    CHIP_IN_PRACTICE:;
    HOLE_REPEAT:
      begin
        Result := TGamePractice.Create(PL, GameData, CreateGameEvent, UpdateGameEvent, DestroyGame, PlayerJoinGameEvent, PlayerLeaveGameEvent, Self.fGameList.GetID);
      end;
    GRANDPRIX: ;
  end;

  if not (Result = nil) then
    fGameList.Games.Add(Result);

  Exit(Result);
end;

procedure TLobby.CreateGameEvent(GameHandle: TGameBase);
begin
  if (GameHandle = nil) or (GameHandle.GameType = HOLE_REPEAT) then
    Exit;

  Write(ShowGameAction(GameHandle.GameInformation, gaCreate));
end;

procedure TLobby.DestroyGameEvent(GameHandle: TGameBase);
begin
  if (GameHandle = nil) or (GameHandle.GameType = HOLE_REPEAT) then
    Exit;

  Write(ShowGameAction(GameHandle.GameInformation, gaDestroy));
end;

procedure TLobby.FreeGame;
var
  A, B: TGameBase;
  Deleting: TMyList<TGameBase>;
begin
  Deleting := TMyList<TGameBase>.Create;
  try
    { put games into clear list }
    for A in FGameFree do
    begin
      if (A.Terminating) and (A.TerminateTime <= Now()) then
      begin
        Deleting.Add(A);
      end;
    end;

    { clearing }
    for A in Deleting do
    begin
      { check if the game contains }
      if FGameFree.Contains(A) then
        FGameFree.Remove(A);
      { check whether the game is assigned }
      B := A;
      if Assigned(B) then
      begin
        { delete the game }
        Self.fGameList.RemoveID(B.ID);
        FreeAndNil(B);
      end;
    end;
  finally
    Deleting.Clear;
    Deleting.Free;
    Sched.AddSchedule(5000, Self.FreeGame);
  end;
end;

procedure TLobby.PlayerJoinGameEvent(GameHandle: TGameBase; player: TClientPlayer);
begin
  if (GameHandle = nil) or (GameHandle.GameType = HOLE_REPEAT) then
    Exit;

  Write(ShowPlayerAction(Player, laUpdatePlayer));
end;

procedure TLobby.PlayerLeaveGameEvent(GameHandle: TGameBase; player: TClientPlayer);
begin
  if (GameHandle = nil) or (GameHandle.GameType = HOLE_REPEAT) then
    Exit;

  Write(ShowPlayerAction(Player, laUpdatePlayer));
end;

procedure TLobby.UpdateGameEvent(GameHandle: TGameBase);
begin
  if (GameHandle = nil) or (GameHandle.GameType = HOLE_REPEAT) then
    Exit;

  Write(ShowGameAction(GameHandle.GameInformation, gaUpdate));
end;

procedure TLobby.PlayerSendChat(Player: TClientPlayer; const Messages: AnsiString);
var
  GameHandle : TGameBase;
  Client: TClientPlayer;
begin
  GameHandle := GetGameHandle(Player);

  if GameHandle <> nil then
  begin
    GameHandle.Write(ChatText(Player.GetNickname, Messages, Player.GetCapabilities = 4));
    Exit;
  end;

  for Client in ClientList do
    if (Client.InLobby) and ((Client.GameID = $FFFF)) then
      Client.Write(ChatText(Player.GetNickname, Messages, Player.GetCapabilities = 4));
end;

procedure TLobby.RemovePlayer(Player: TClientPlayer);
var
  GameHandle: TGameBase;
begin
  ClientList.Remove(player);

  GameHandle := fGameList.GameHandle[player.GameID];

  if not(GameHandle = nil) then
  begin
    GameHandle.RemovePlayer(player);
  end;
  if player.InLobby then
  begin
    Self.LeaveMultiplayerGamesList(player);
  end;
end;

procedure TLobby.Send(const Data: AnsiString);
var
  Client: TClientPlayer;
begin
  for Client in ClientList do
  begin
    Client.Send(Data, True);
  end;
end;

procedure TLobby.Send(Data: TPangyaBuffer);
var
  Client: TClientPlayer;
begin
  for Client in ClientList do
  begin
    Client.Send(Data);
  end;
end;

procedure TLobby.UpdatePlayerLobbyInfo(Player: TClientPlayer);
begin
  if Player.InLobby then
  begin
    Write(ShowPlayerAction(Player, laUpdatePlayer));
    Player.Send(#$F0#$00);
  end;
end;

procedure TLobby.Write(Data: TClientPacket);
begin
  try
    Self.Send(Data);
  finally
    FreeAndNil(Data);
  end;
end;

end.
