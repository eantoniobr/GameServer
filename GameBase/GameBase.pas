unit GameBase;

interface

uses
  System.Generics.Collections, System.Generics.Defaults,
  System.SysUtils, System.SyncObjs, System.Math.Vectors,
  PangyaClient, ClientPacket,
  Enum, Defines, Tools, PacketCreator, TimerQueue, uWriteConsole;

type
  TGameBase = class;

  fGameEvent = procedure(Game: TGameBase) of object;
  fPlayerEvent = procedure(Game: TGameBase; Player: TClientPlayer) of object;
  fTimer = procedure(const ASender: TObject) of object;

  TGameBase = class
    private
      procedure SetOwner(UID: UInt32);
    protected
      fID: UInt32;
      fGameData: TGameInfo;
      fOwner: UInt32;
      fStarted: Boolean;
      fTrophy: UInt32;
      fIdle: UInt8;

      { Trophy Showing }
      fGold: UInt32;
      fSilver1: UInt32;
      fSilver2: UInt32;
      fBronze1: UInt32;
      fBronze2: UInt32;
      fBronze3: UInt32;

      { Medal Showing }
      fBestRecovery: UInt32;
      fBestChipIn: UInt32;
      fBestDrive: UInt32;
      fBestSpeeder: UInt32;
      fLongestPutt: UInt32;
      fLuckyAward: UInt32;

      { Map }
      fMap: UInt8;

      { Timer Handle }
      fTimer: THandle;

      fPlayers: TList<TClientPlayer>;
      fPlayerData: TList<PPGameData>;
      { UID AND GAMEDATA }
      fScores: TDictionary<UInt32, PGameData>;
      fHoles: TList<TGameHoleInfo>;

      fGameKey: array [0 .. $F] of AnsiChar;
      fRecv: TCriticalSection;

      { Event }
      fCreate: fGameEvent;
      fUpdate: fGameEvent;
      fDestroy: fGameEvent;
      { Player Event }
      fPlayerJoin: fPlayerEvent;
      fPlayerLeave: fPlayerEvent;
      { Terminating }
      fTerminating: Boolean;
      fTerminateTime: TDateTime;

      { Timer }
      procedure CancelTimer;

      procedure ShotDecrypt(DATA: PAnsiChar; Size: UInt32);
      procedure GameUpdate;
      procedure CreateKey;

      function GetGameType: TGAME_TYPE;
      function GetPWD: AnsiString;
      function GetGameHeadData: AnsiString; virtual;
      procedure SendPlayerOnCreate(const PL: TClientPlayer); virtual; abstract;
      procedure SendPlayerOnJoin(const PL: TClientPlayer); virtual; abstract;
      procedure SendHoleData(const PL: TClientPlayer); virtual; abstract;
      procedure SetRole(const PL: TClientPlayer; IsAdmin: Boolean); virtual;
      procedure FindNewMaster;
      procedure ComposePlayer; virtual;
      procedure OnPlayerLeave; virtual; abstract;
      function Validate: Boolean; virtual; abstract;
      procedure ClearPlayerData;

      { Generate Medal and Trophy }
      procedure AfterMatchDone;

      { all finished? }
      function _allFinished: Boolean;

      { GameModePractice.pas }
      { Match Data }
      procedure SendMatchData(const PL: TClientPlayer); virtual;
      procedure SendUnfinishedData; virtual;
      procedure CopyScore;

      { Generate Experience }
      procedure GenerateExperience; virtual; abstract;

      { Game Timer UP! }
      procedure GameTimeUP; virtual; abstract;

      { Hole }
      procedure BuildHole;
      procedure ClearHole;

      { Trophy }
      procedure GenerateGameTrophy;

      { Game Packet }
      procedure PlayerAction(const PL: TClientPlayer; const CP: TClientPacket);
      procedure PlayerGameSetting(const PL: TClientPlayer; const CP: TClientPacket);
      procedure PlayerGameReady(const PL: TClientPlayer; const CP: TClientPacket);
      procedure PlayerMatchData(const PL: TClientPlayer; const CP: TClientPacket);
      procedure PlayerHoleData(const PL: TClientPlayer; const CP: TClientPacket);
      procedure PlayerSendResult(const PL: TClientPlayer; const CP: TClientPacket);
      procedure PlayerShotInfo(const PL: TClientPlayer; const CP: TClientPacket); virtual; abstract;
      procedure PlayerShotData(const PL: TClientPlayer; const CP: TClientPacket); virtual; abstract;
      procedure PlayerLoadSuccess(const PL: TClientPlayer); virtual; abstract;
      procedure PlayerLeavePractice; virtual; abstract;
      procedure PlayerStartGame; virtual; abstract;
      procedure PlayerSyncShot(const PL: TClientPlayer; const CP: TClientPacket); virtual; abstract;
      procedure PlayerPutt(const PL: TClientPlayer; const CP: TClientPacket);
      procedure PlayerUseItem(const PL: TClientPlayer; const CP: TClientPacket);
      procedure PlayerRebuildHole;

      { Sleep Icon }
      procedure PlayerShowSleepIcon(const PL: TClientPlayer; const CP: TClientPacket);
      { Game Action }
      procedure PlayerShotReady(const PL: TClientPlayer); virtual;
      procedure PlayerMoveBar(const PL: TClientPlayer; const CP: TClientPacket); virtual;
      procedure PlayerRotate(const PL: TClientPlayer; const CP: TClientPacket); virtual;
      procedure PlayerSwitchClub(const PL: TClientPlayer; const CP: TClientPacket); virtual;
      procedure PlayerPowerShot(const PL: TClientPlayer; const CP: TClientPacket); virtual;
      procedure PlayerShowChatIcon(const PL: TClientPlayer; const CP: TClientPacket); virtual;

      { Final Result }
      procedure PlayerSendFinalResult(const PL: TClientPlayer; const CP: TClientPacket); virtual; abstract;

      procedure test();
    public
      constructor Create(const PL: TClientPlayer; GameData: TGameInfo;
        CreateEvent, UpdateEvent, DestroyEvent: fGameEvent;
        OnJoin, OnLeave: fPlayerEvent; GameID: UInt16);
      destructor Destroy; override;
      procedure HandlePacket(const Packet: TGAMEPACKET; const PL: TClientPlayer; const CP: TClientPacket);

      function GameInformation: AnsiString; virtual; abstract;

      function AddPlayer(const PL: TClientPlayer): Boolean;
      function RemovePlayer(const PL: TClientPlayer): Boolean;

      procedure DestroyRoom; virtual; abstract;
      procedure AcquireData(PL: TClientPlayer); virtual; abstract;

      { Packet }
      procedure Write(const CP: TClientPacket); overload; virtual;
      procedure write(const Data: AnsiString); overload; virtual;
      procedure Send(const Data: Ansistring); overload; virtual;
      procedure Send(const CP: TClientPacket); overload; virtual;

      property ID: UInt32 read fID write fID;
      property Password: AnsiString read GetPWD;
      property GameData: TGameInfo read fGameData write fGameData;
      property GameType: TGAME_TYPE read GetGameType;
      property Terminating: Boolean read fTerminating write fTerminating;
      property TerminateTime: TDateTime read fTerminateTime write fTerminateTime;
  end;

implementation

{ TGameBase }

function TGameBase.AddPlayer(const PL: TClientPlayer): Boolean;
begin
  Self.fRecv.Acquire;
  try
    { Add Player }
    if (Self.fPlayers.Count > Self.fGameData.MaxPlayer) then
    begin
      PL.Send(#$49#$00#$02);
      Exit;
    end;

    if (not(Self.fPlayers.Add(PL) = -1)) then
    begin
      PL.SetGameID(Self.fID);
      PL.GameInfo.SetDefault;
      Self.SetRole(PL, False);
      Self.ComposePlayer;
      Self.GameUpdate;
      PL.Send(#$49#$00#$00#$00 + Self.GameInformation); // TODO
      Self.fUpdate(Self);
      Self.fPlayerJoin(Self, PL);
      Self.SendPlayerOnJoin(PL);
    end;
  finally
    Self.fRecv.Release;
  end;
end;

procedure TGameBase.PlayerRebuildHole;
var
  I: UInt8;
  WP, WD, P: UInt8;
begin
  if (Self.fGameData.GameType = HOLE_REPEAT) and (Self.fGameData.HoleNumber > 0)
  then
  begin
    WP := Random($9);
    WD := Random($FF);
    P := Random($3);
    for I := 0 to 17 do
    begin
      Self.fHoles[I].Hole := (I + 1);
      Self.fHoles[I].Weather := Random($3);
      Self.fHoles[I].WindPower := WP;
      Self.fHoles[I].WindDirection := WD;
      Self.fHoles[I].Map := Self.fGameData.Map;
      Self.fHoles[I].Pos := P;
    end;
  end;
end;

procedure TGameBase.BuildHole;
var
  I: UInt8;
  H: THole18;
  M: TMap19;

  WP, WD, P: UInt8;
begin
  Self.ClearHole;

  if (Self.fGameData.Map = $7F) then
    fMap := GetMap
  else
    fMap := Self.fGameData.Map;

  { Reseed }
  Randomize;

  { Add Holes }
  for I := 0 to 17 do
    Self.fHoles.Add(TGameHoleInfo.Create());

  if (Self.fGameData.GameType = HOLE_REPEAT) and (Self.fGameData.HoleNumber > 0) then
  begin
    WP := Random($9);
    WD := Random($FF);
    P := Random($3);
    for I := 0 to 17 do
    begin
      Self.fHoles[I].Hole := (I + 1);
      Self.fHoles[I].Weather := Random($3);
      Self.fHoles[I].WindPower := WP;
      Self.fHoles[I].WindDirection := WD;
      Self.fHoles[I].Map := fMap;
      Self.fHoles[I].Pos := P;
    end;
    { leave }
    Exit;
  end;


  case TGAME_MODE(Self.fGameData.Mode) of
    GAME_MODE_FRONT:
      begin
        for I := 0 to 17 do
        begin
          Self.fHoles[I].Hole := (I + 1);
          Self.fHoles[I].Weather := Random($3);
          Self.fHoles[I].WindPower := Random($9);
          Self.fHoles[I].WindDirection := Random($FF);
          Self.fHoles[I].Map := fMap;
          Self.fHoles[I].Pos := Random($3);
        end;
      end;
    GAME_MODE_BACK:
      begin
        for I := 0 to 17 do
        begin
          Self.fHoles[I].Hole := (18 - I);
          Self.fHoles[I].Weather := Random($3);
          Self.fHoles[I].WindPower := Random($9);
          Self.fHoles[I].WindDirection := Random($FF);
          Self.fHoles[I].Map := fMap;
          Self.fHoles[I].Pos := Random($3);
        end;
      end;
    GAME_MODE_SHUFFLE,
    GAME_MODE_RANDOM:
      begin
        H := RandomHole;
        for I := 0 to 17 do
        begin
          Self.fHoles[I].Hole := H[I];
          Self.fHoles[I].Weather := Random($3);
          Self.fHoles[I].WindPower := Random($9);
          Self.fHoles[I].WindDirection := Random($FF);
          Self.fHoles[I].Map := fMap;
          Self.fHoles[I].Pos := Random($3);
        end;
      end;
    GAME_MODE_SSC:
      begin
        H := RandomHole;
        M := RandomMap;
        for I := 0 to 17 do
        begin
          Self.fHoles[I].Hole := H[I];
          Self.fHoles[I].Weather := Random($3);
          Self.fHoles[I].WindPower := Random($9);
          Self.fHoles[I].WindDirection := Random($FF);
          Self.fHoles[I].Map := M[I];
          Self.fHoles[I].Pos := Random($3);
        end;
        Self.fHoles.Last.Hole := (Random($2) + 1);
        Self.fHoles.Last.Map := $11;
      end;
  else
    begin
      for I := 0 to 17 do
      begin
        Self.fHoles[I].Hole := (I + 1);
        Self.fHoles[I].Weather := Random($3);
        Self.fHoles[I].WindPower := Random($9);
        Self.fHoles[I].WindDirection := Random($FF);
        Self.fHoles[I].Map := fMap;
        Self.fHoles[I].Pos := Random($3);
      end;
    end;
  end;
end;

procedure TGameBase.CancelTimer;
begin
  if Self.fTimer > 0 then
  begin
    Sched.CancelSchedule(Self.fTimer);
    Self.fTimer := 0;
  end;
end;

procedure TGameBase.ClearHole;
var
  H: TGameHoleInfo;
begin
  for H in Self.fHoles do
    H.Free;

  fHoles.Clear;
end;

procedure TGameBase.ClearPlayerData;
var
  P: PPGameData;
begin
  for P in Self.fPlayerData do
    Dispose(P);

  Self.fPlayerData.Clear;
end;

procedure TGameBase.ComposePlayer;
var
  P: TClientPlayer;
  I: UInt16;
begin
  I := 0;
  for P in Self.fPlayers do
  begin
    Inc(I, 1);
    P.GameInfo.GameSlot := I;
  end;
end;

procedure TGameBase.CopyScore;
var
  P: TClientPlayer;
  S: PPGameData;
begin
  { Clear Old SCore First }
  Self.ClearPlayerData;

  { Copy to list }
  for P in Self.fPlayers do
  begin
    New(S);
    S^ := P.GameInfo;
    Self.fPlayerData.Add(S);
  end;
end;

constructor TGameBase.Create(const PL: TClientPlayer; GameData: TGameInfo;
  CreateEvent, UpdateEvent, DestroyEvent: fGameEvent;
  OnJoin, OnLeave: fPlayerEvent; GameID: UInt16);
begin
  fPlayers := TList<TClientPlayer>.Create;
  fPlayerData := TList<PPGameData>.Create;
  fScores := TDictionary<UInt32, PGameData>.Create;
  fHoles := TList<TGameHoleInfo>.Create;
  fRecv := TCriticalSection.Create;

  { Game Data }
  fGameData := GameData;
  Self.fID := GameID;

  fCreate := CreateEvent;
  fUpdate := UpdateEvent;
  fDestroy := DestroyEvent;
  fPlayerJoin := OnJoin;
  fPlayerLeave := OnLeave;

  Self.CreateKey;
  fTerminating := False;
  fStarted := False;
  fTrophy := 0;
  fIdle := 0;

  { Validator }
  if not Self.Validate then
  begin
    PL.Send(#$49#$00#$07);
    Exit;
  end;

  { Add Player }
  if (Self.fPlayers.Count > Self.fGameData.MaxPlayer) then
  begin
    PL.Send(#$49#$00#$02);
    Exit;
  end;

  if ( not (Self.fPlayers.Add(PL) = -1)) then
  begin
    Self.SetOwner(PL.GetUID);
    PL.SetGameID(Self.fID);
    PL.GameInfo.SetDefault;
    Self.SetRole(PL, True);

    Self.GameUpdate;
    PL.Send(#$49#$00#$00#$00 + Self.GameInformation); // TODO
    Self.ComposePlayer;
    Self.SendPlayerOnCreate(PL);
    Self.fCreate(Self);
    Self.fPlayerJoin(Self, PL);
  end;
end;

procedure TGameBase.CreateKey;
var
  I: UInt8;
begin
  Randomize;
  for I := 0 to Length(fGameKey) - 1 do
    fGameKey[I] := AnsiChar(Random($FF));
end;

destructor TGameBase.Destroy;
var
  D: PGameData;
begin
  for D in Self.fScores.Values do
    Dispose(D);

  Self.ClearPlayerData;

  Self.fPlayers.Clear;
  Self.fScores.Clear;
  Self.ClearHole;

  FreeAndNil(fPlayerData);
  FreeAndNil(fScores);
  FreeAndNil(fPlayers);
  FreeAndNil(fHoles);
  FreeAndNil(fRecv);

  Self.CancelTimer;

  inherited;
end;

procedure TGameBase.FindNewMaster;
var
  P: TClientPlayer;
begin
  for P in Self.fPlayers do
  begin
    Self.Write(ShowNewMaster(P.ConnectionID));
    Self.fOwner := P.GetUID;
    Exit;
  end;
end;

procedure TGameBase.GameUpdate;
begin
  Self.Send(Self.GetGameHeadData);
end;

procedure TGameBase.GenerateGameTrophy;
var
  SumLevel: UInt32;
  AvgLevel: UInt32;
  P: TClientPlayer;
begin
  SumLevel := 0;
  AvgLevel := 0;

  for P in Self.fPlayers do
    Inc(SumLevel, P.Level);

  if SumLevel <= 0 then
    AvgLevel := 0
  else
    AvgLevel := SumLevel div Self.fPlayers.Count;

  case AvgLevel of
    0 .. 5:
      Self.fTrophy := $2C000000; // AmaF
    6 .. 10:
      Self.fTrophy := $2C010000;
    11 .. 15:
      Self.fTrophy := $2C020000;
    16 .. 20:
      Self.fTrophy := $2C030000;
    21 .. 25:
      Self.fTrophy := $2C040000;
    26 .. 30:
      Self.fTrophy := $2C050000;
    31 .. 35:
      Self.fTrophy := $2C060000;
    36 .. 40:
      Self.fTrophy := $2C070000;
    41 .. 45:
      Self.fTrophy := $2C080000;
    46 .. 50:
      Self.fTrophy := $2C090000;
    51 .. 55:
      Self.fTrophy := $2C0A0000;
    56 .. 60:
      Self.fTrophy := $2C0B0000;
    61 .. 65:
      Self.fTrophy := $2C0C0000;
    66 .. 70:
      Self.fTrophy := $2C0C0000;
  end;
end;

procedure TGameBase.AfterMatchDone;
var
  I: UInt32;
begin
  { Generate Longest Distance }
  fPlayerData.Sort(TComparer<PPGameData>.Construct(
    function(const P1, P2: PPGameData): Integer
    begin
      if P1.GameData.Statistic.LongestDistance <
        P2.GameData.Statistic.LongestDistance then
        Result := 1
      else if P1.GameData.Statistic.LongestDistance >
        P2.GameData.Statistic.LongestDistance then
        Result := -1
      else
        Result := 0;
    end)
  );

  { Map Longest Distance }
  if (fPlayerData.First.GameData.Statistic.LongestDistance > 0) then
  begin
    fPlayerData.First.GameData.Reward.BestDrive := True;
    Self.fBestDrive := fPlayerData.First.ConnectionID;
  end;

  { We need to generate ranks at final  }
  { Generate Rank }
  fPlayerData.Sort(TComparer<PPGameData>.Construct(
    function(const P1, P2: PPGameData): Integer
    begin
      if P1.GameData.Score < P2.GameData.Score then
        Result := -1
      else if P1.GameData.Score > P2.GameData.Score then
        Result := 1
      else if P1.GameData.Pang > P2.GameData.Pang then
        Result := -1
      else if P1.GameData.Pang < P2.GameData.Pang then
        Result := 1
      else
        Result := 0;
    end)
  );

  { Map Rank }
  for I := 0 to fPlayerData.Count - 1 do
    fPlayerData[I].GameData.Rate := I + 1;

end;

function TGameBase.GetGameHeadData: AnsiString;
var
  CP: TClientPacket;
begin
  CP := TClientPacket.Create;
  try
    with CP do
    begin
      WriteStr(#$4A#$00);
      WriteStr(#$FF#$FF);
      WriteUInt8(UInt8(Self.fGameData.GameType));
      WriteUInt8(Self.fGameData.Map);
      WriteUInt8(Self.fGameData.HoleTotal);
      WriteUInt8(Self.fGameData.Mode);
      WriteUInt32(Self.fGameData.NaturalMode);
      WriteUInt8(Self.fGameData.MaxPlayer);
      WriteStr(#$1E);
      WriteUInt8(fIdle); // Room Idle?
      WriteUInt32(Self.fGameData.VSTime);
      WriteUInt32(Self.fGameData.GameTime);
      WriteUInt32(0); // Trophy?
      WriteUInt8(TCompare.IfCompare<UInt8>( Length(Self.fGameData.Password) > 0, $0, $1));
      WritePStr(Self.fGameData.Name);
      Exit(ToStr);
    end;
  finally
    CP.Free;
  end;
end;

function TGameBase.GetGameType: TGAME_TYPE;
begin
  Exit(Self.fGameData.GameType);
end;

function TGameBase.GetPWD: AnsiString;
begin
  Exit(Self.fGameData.Password);
end;

procedure TGameBase.HandlePacket(const Packet: TGAMEPACKET;
  const PL: TClientPlayer; const CP: TClientPacket);
begin
  fRecv.Acquire;
  try
    case Packet of
      PLAYER_ACTION:
        PlayerAction(PL, CP);
      PLAYER_CHANGE_GAME_OPTION:
        Self.PlayerGameSetting(PL, CP);
      PLAYER_PRESS_READY:
        Self.PlayerGameReady(PL, CP);
      PLAYER_START_GAME:
        Self.PlayerStartGame;
      PLAYER_MATCH_DATA:
        Self.PlayerMatchData(PL, CP);
      PLAYER_ACTION_SHOT:
        Self.PlayerShotInfo(PL, CP);
      PLAYER_SHOT_DATA:
        Self.PlayerShotData(PL, CP);
      PLAYER_HOLE_INFORMATIONS:
        Self.PlayerHoleData(PL, CP);
      PLAYER_LOAD_OK:
        Self.PlayerLoadSuccess(PL);
      PLAYER_HOLE_COMPLETE:
        Self.PlayerSendResult(PL, CP);
      PLAYER_QUIT_SINGLE_PLAYER:
        Self.PlayerLeavePractice;
      PLAYER_SHOT_SYNC:
        Self.PlayerSyncShot(PL, CP);
      PLAYER_WIND_CHANGE:
        Self.PlayerRebuildHole;
      PLAYER_CALL_ASSIST_PUTTING:
        Self.PlayerPutt(PL, CP);
      PLAYER_USE_ITEM:
        Self.PlayerUseItem(PL, CP);
      PLAYER_SLEEP_ICON:
        Self.PlayerShowSleepIcon(PL, CP);
      PLAYER_1ST_SHOT_READY:
        Self.PlayerShotReady(PL);
      PLAYER_MOVE_BAR:
        Self.PlayerMoveBar(PL, CP);
      PLAYER_GAME_ROTATE:
        Self.PlayerRotate(PL, CP);
      PLAYER_CHANGE_CLUB:
        Self.PlayerSwitchClub(PL, CP);
      PLAYER_POWER_SHOT:
        Self.PlayerPowerShot(PL, CP);
      PLAYER_CHAT_ICON:
        Self.PlayerShowChatIcon(PL, CP);
      PLAYER_SEND_GAMERESULT:
        self.test;
      else
        WriteConsole(Format('%d failed to detected packed by game', [UInt8(Packet)]), 12);
    end;
  finally
    fRecv.Release;
  end;
end;

procedure TGameBase.PlayerAction(const PL: TClientPlayer;
  const CP: TClientPacket);
var
  TD: AnsiString;
  Packet: TClientPacket;
  Action: UInt8;
  Vector: TPoint3D;

begin
  TD := CP.GetRemainingData;
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$C4#$00);
      WriteUInt32(PL.ConnectionID);
      WriteStr(TD);
    end;
    Self.Send(Packet);

    if not CP.ReadUInt8(Action) then Exit;

    case Action of
      4: { Player Appearance }
        begin
          if not CP.Read(PL.GameInfo.Action.Vector.X, SizeOf(TPoint3D)) then Exit;
        end;
      5: { Player Posture }
        begin
          if not CP.ReadUInt32(PL.GameInfo.Action.Posture) then Exit;
        end;
      6: { Player Move }
        begin
          if not CP.Read(Vector.X, SizeOf(TPoint3D)) then Exit;
          PL.GameInfo.AddWalk(Vector);
        end;
      8: { Player Animation }
        begin
          if not CP.ReadUInt32(PL.GameInfo.Action.Animate) then Exit;
        end;
    end;
  finally
    Packet.Free;
  end;
end;

procedure TGameBase.PlayerGameReady(const PL: TClientPlayer;
  const CP: TClientPacket);
var
  S: UInt8;
begin
  if not CP.ReadUInt8(S) then Exit;
  with PL.GameInfo do
  begin
    GameReady := S > 0;
  end;
  Self.Write(ShowGameReady(PL.ConnectionID, S));
end;

procedure TGameBase.PlayerGameSetting(const PL: TClientPlayer;
  const CP: TClientPacket);
var
  I, B: UInt8;
  S: TGameShift;
  T8: UInt8;
begin
  CP.Skip(2);
  if not CP.ReadUInt8(I) then Exit;
  for B := 0 to I do
  begin
    if not CP.Read(S, SizeOf(S)) then Break;

    case S of
      SHIFT_NAME:
        begin
          CP.ReadPStr(Self.fGameData.Name);
        end;
      SHIFT_PWD:
        begin
          CP.ReadPStr(Self.fGameData.Password);
        end;
      SHIFT_STROK:
        begin

        end;
      SHIFT_MAP:
        begin
          CP.ReadUInt8(Self.fGameData.Map);
        end;
      SHIFT_NUMHOLE:
        begin
          CP.ReadUInt8(Self.fGameData.HoleTotal);
        end;
      SHIFT_MODE:
        begin
          CP.ReadUInt8(Self.fGameData.Mode);
        end;
      SHIFT_VSTIME:
        begin
          CP.ReadUInt8(T8);
          Self.fGameData.VSTime := T8 * 1000;
        end;
      SHIFT_MAXPLAYER:
        begin
          CP.ReadUInt8(T8);
          if (T8 <= Self.fPlayers.Count) then
            Self.fGameData.MaxPlayer := T8;
        end;
      SHIFT_MATCHTIME:
        begin
          CP.ReadUInt8(T8);
          Self.fGameData.GameTime := (60 * T8) * 1000;
        end;
      SHIFT_IDLE:
        begin
          CP.ReadUInt8(Self.fIdle);
        end;
      SHIFT_NATURAL:
        begin
          CP.ReadUInt32(Self.fGameData.NaturalMode);
        end;
      SHIFT_HOLENUM:
        begin
          CP.ReadUInt8(Self.fGameData.HoleNumber);
        end;
      SHIFT_HOLELOCK:
        begin
          CP.ReadUInt32(Self.fGameData.LockHole);
        end;
    else
      raise Exception.Create('PlayerGameSetting: Unknown Setting type');
    end;
  end;
  Self.GameUpdate;
  Self.fUpdate(Self);
end;

procedure TGameBase.PlayerHoleData(const PL: TClientPlayer;
  const CP: TClientPacket);
type
  THoleData = packed record
    HolePosition: UInt32;
    Unknown: array [0 .. 4] of AnsiChar;
    Par: UInt8;
    A, B, // start pos?
    X, Z: Single; // hole position
  end;
var
  H: THoleData;
begin
  if not CP.Read(H, SizeOf(THoleData)) then Exit;

  PL.GameInfo.HolePos3D.X := H.X;
  PL.GameInfo.HolePos3D.Z := H.Z;
  PL.GameInfo.HolePos := H.HolePosition;
  PL.GameInfo.GameData.ParCount := H.Par;

  if (not ((Self.fGameData.NaturalMode and 2) = 0)) then
  begin
    case H.Par of
      4:
        PL.GameInfo.GameData.ShotCount := 2;
      5:
        PL.GameInfo.GameData.ShotCount := 3;
      else
        PL.GameInfo.GameData.ShotCount := 1;
    end;
  end else begin
    PL.GameInfo.GameData.ShotCount := 1;
  end;

  Self.SendHoleData(PL);
end;

procedure TGameBase.PlayerMatchData(const PL: TClientPlayer;
  const CP: TClientPacket);
var
  Packet: TClientPacket;
begin
  inherited;
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$F7#$01);
      WriteUInt32(PL.ConnectionID);
      WriteUInt8(PL.GameInfo.HolePos);
      WriteStr(CP.GetRemainingData);
      Self.Send(Packet);
    end;
  finally
    FreeAndNil(Packet);
  end;
end;

procedure TGameBase.PlayerPutt(const PL: TClientPlayer;
  const CP: TClientPacket);
var
  TypeID: UInt32;
begin
  if not CP.ReadUInt32(TypeID) then Exit;

  if not (TypeID = $1BE00016) then Exit;

  PL.Write(ShowAssistPutting(TypeID, PL.GetUID));
end;

procedure TGameBase.PlayerSendResult(const PL: TClientPlayer;
  const CP: TClientPacket);
begin
  if not CP.Read(PL.GameInfo.GameData.Statistic.Drive, SizeOf(TStatistic)) then Exit;
end;

procedure TGameBase.PlayerUseItem(const PL: TClientPlayer;
  const CP: TClientPacket);
var
  TypeID: UInt32;
begin
  if not CP.ReadUInt32(TypeID) then Exit;
  Self.Write(ShowPlayerUseItem(TypeID, PL.ConnectionID));
end;

function TGameBase.RemovePlayer(const PL: TClientPlayer): Boolean;
begin
  Self.fRecv.Acquire;
  try
    if (not(Self.fPlayers.Remove(PL) = -1)) then
    begin
      PL.SetGameID($FFFF);
      Self.fPlayerLeave(Self, PL);
      OnPlayerLeave;
      Self.Write(ShowGameLeave(PL.ConnectionID, 2));
      { Find New Master }
      if (PL.GetUID = Self.fOwner) then
        Self.FindNewMaster;
      { Room Update }
      Self.fUpdate(Self);
      PL.Write(ShowLeaveGame);
    end;
    if (Self.fPlayers.Count = 0)then
    begin
      Self.fDestroy(Self);
    end;
  finally
    Self.fRecv.Release;
  end;
end;

procedure TGameBase.Send(const CP: TClientPacket);
var
  P: TClientPlayer;
begin
  for P in Self.fPlayers do
    P.Send(CP);
end;

procedure TGameBase.SendMatchData(const PL: TClientPlayer);
var
  Packet: TClientPacket;
begin
  Packet := TCLientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$79#$00);
      WriteUInt32(PL.GameInfo.GameData.EXP);
      WriteUInt32(Self.fTrophy);
      WriteStr(#$00#$02);
      WriteUInt32(Self.fLuckyAward);
      WriteUInt32(0);
      WriteUInt32(Self.fBestSpeeder);
      WriteUInt32(0);
      WriteUInt32(Self.fBestDrive);
      WriteUInt32(0);
      WriteUInt32(Self.fBestChipIn);
      WriteUInt32(0);
      WriteUInt32(Self.fLongestPutt);
      WriteUInt32(0);
      WriteUInt32(Self.fBestRecovery);
      WriteUInt32(0);
      WriteUInt32(Self.fGold);
      WriteUInt32(0);
      WriteUInt32(Self.fSilver1);
      WriteUInt32(0);
      WriteUInt32(Self.fSilver2);
      WriteUInt32(0);
      WriteUInt32(Self.fBronze1);
      WriteUInt32(0);
      WriteUInt32(Self.fBronze2);
      WriteUInt32(0);
      WriteUInt32(Self.fBronze3);
      WriteUInt32(0);
    end;
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure TGameBase.SendUnfinishedData; { Match Mode }
var
  P: PPGameData;
begin
  for P in Self.fPlayerData do
    if not P.GameCompleted then
      Self.Write(ShowHoleData(P.ConnectionID, P.HolePos, P.GameData.TotalShot, P.GameData.Score, P.GameData.Pang, P.GameData.BonusPang, False));
end;

procedure TGameBase.Send(const Data: Ansistring);
var
  P: TClientPlayer;
begin
  for P in Self.fPlayers do
    P.Send(Data);
end;

procedure TGameBase.SetOwner(UID: UInt32);
begin
  Self.fOwner := UID;
end;

procedure TGameBase.SetRole(const PL: TClientPlayer; IsAdmin: Boolean);
begin
  if (IsAdmin) then
    PL.GameInfo.Role := $8
  else
    PL.GameInfo.Role := $1;
end;

procedure TGameBase.ShotDecrypt(DATA: PAnsiChar; Size: UInt32);
var
  I: UInt32;
begin
  for I := 0 to (Size - 1) do
    DATA[I] := AnsiChar(Byte(DATA[I]) xor Byte(fGameKey[I mod 16]));
end;

procedure TGameBase.test;
begin
  self.Write(#$b9#$00#$00);
end;

procedure TGameBase.Write(const Data: AnsiString);
var
  P: TClientPlayer;
begin
  for P in Self.fPlayers do
    P.Send(Data);
end;

function TGameBase._allFinished: Boolean;
var
 P: TClientPlayer;
begin
  for P in Self.fPlayers do
    if not P.GameInfo.GameCompleted then
      Exit(False);

  Exit(True);
end;

procedure TGameBase.Write(const CP: TClientPacket);
begin
  try
    Self.Send(CP);
  finally
    CP.Free;
  end;
end;

procedure TGameBase.PlayerShotReady(const PL: TClientPlayer);
begin
  { do nothing }
end;

procedure TGameBase.PlayerShowChatIcon(const PL: TClientPlayer; const CP: TClientPacket);
begin

end;

procedure TGameBase.PlayerShowSleepIcon(const PL: TClientPlayer; const CP: TClientPacket);
var
  I: UInt8;
begin
  if not CP.ReadUInt8(I) then Exit;
  Self.Write(ShowSleep(PL.ConnectionID, I));
end;

procedure TGameBase.PlayerSwitchClub(const PL: TClientPlayer; const CP: TClientPacket);
begin
  { do nothing }
end;

procedure TGameBase.PlayerMoveBar(const PL: TClientPlayer; const CP: TClientPacket);
begin
  { do nothing }
end;

procedure TGameBase.PlayerRotate(const PL: TClientPlayer; const CP: TClientPacket);
begin
  { do nothing }
end;

procedure TGameBase.PlayerPowerShot(const PL: TClientPlayer; const CP: TClientPacket);
begin
  { do nothing }
end;

end.
