unit GameModePractice;

interface

uses
  System.SysUtils, GameBase, PangyaClient, Enum, Defines, ClientPacket, Tools,
  PacketCreator, uWriteConsole, TimerQueue, GameExpTable;

type
  TGamePractice = class(TGameBase)
    protected
      { Generate Experience }
      procedure GenerateExperience; override;

      { Validate Game Data }
      function Validate: Boolean; override;

      { Game Timer UP! }
      procedure GameTimeUP; override;

      function GetPangDivide: UInt8;

      procedure _onAllPlayerFinished;

      procedure SendPlayerOnCreate(const PL: TClientPlayer); override;
      procedure SendPlayerOnJoin(const PL: TClientPlayer); override;
      procedure PlayerShotInfo(const PL: TClientPlayer; const CP: TClientPacket); override;
      procedure PlayerShotData(const PL: TClientPlayer; const CP: TClientPacket); override;
      procedure SendHoleData(const PL: TClientPlayer); override;
      procedure OnPlayerLeave; override;
      function GetGameHeadData: AnsiString; override;
      procedure PlayerStartGame; override;
      procedure PlayerLoadSuccess(const PL: TClientPlayer); override;
      procedure PlayerLeavePractice; override;
      procedure PlayerSyncShot(const PL: TClientPlayer; const CP: TClientPacket); override;

      procedure SendUnfinishedData; override;

      { Final Result }
      procedure PlayerSendFinalResult(const PL: TClientPlayer; const CP: TClientPacket); override;
    public
      function GameInformation: AnsiString; override;
      procedure AcquireData(PL: TClientPlayer); override;
      constructor Create(const PL: TClientPlayer; GameData: TGameInfo;
        CreateEvent, UpdateEvent, DestroyEvent: fGameEvent;
        OnJoin, OnLeave: fPlayerEvent; GameID: UInt16);
      destructor Destroy; override;
  end;

implementation

{ TGameChat }

procedure TGamePractice.AcquireData(PL: TClientPlayer);
var
  Packet: TClientPacket;
  H: TGameHoleInfo;
begin
  PL.GameInfo.GameData.Reverse;
  PL.GameInfo.ConnectionID := PL.ConnectionID;
  PL.GameInfo.UID := PL.GetUID;
  PL.GameInfo.GameCompleted := False;

  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$76#$00);
      WriteUInt8($4); // Match?
      WriteUInt32(1);
      WriteStr(GameTime());
    end;
    PL.Send(Packet);

    with Packet do
    begin
      Clear;
      WriteStr(#$52#$00);
      WriteUInt8(Self.fGameData.Map);
      WriteUInt8($4);
      WriteuInt8(Self.fGameData.Mode);
      WriteUInt8(Self.fGameData.HoleTotal);
      WriteUInt32(Self.fTrophy); // Trophy?
      WriteUInt32(0); // VS?
      WriteUInt32(Self.fGameData.GameTime);
      for H in Self.fHoles do
      begin
        WriteUInt32(Random(High(Integer)));
        WriteUInt8(H.Pos);
        WriteUInt8(H.Map);
        WriteUInt8(H.Hole);
      end;
      WriteStr(
        #$FF#$FF#$FF#$FF#$05#$01#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$41#$31#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$04#$00#$00#$00#$00#$00#$00#$00#$68#$12#$C4 +
      #$5A#$00#$00#$00#$00#$14#$00#$00#$00#$01#$00#$41#$31#$5C#$5F#$BD +
      #$43#$50#$CD#$8A#$C2#$2B#$BF#$04#$44#$03#$00#$00#$00#$00#$00#$00 +
      #$00#$D7#$D5#$C4#$5A#$00#$00#$00#$00#$14#$00#$00#$00#$01#$00#$41 +
      #$31#$FE#$D4#$AE#$41#$93#$D8#$BA#$C2#$04#$4E#$0B#$44#$03#$00#$00 +
      #$00#$00#$00#$00#$00#$56#$07#$C5#$5A#$00#$00#$00#$00#$14#$00#$00 +
      #$00#$01#$00#$41#$31#$C9#$B6#$96#$43#$DD#$A4#$8E#$C2#$D1#$82#$3D +
      #$C3#$03#$00#$00#$00#$00#$00#$00#$00#$C4#$9E#$C5#$5A#$00#$00#$00 +
      #$00#$14#$00#$00#$00#$01#$00#$41#$31#$AE#$F7#$C5#$43#$EC#$11#$90 +
      #$C2#$02#$0B#$E0#$43#$03#$00#$00#$00#$03#$01#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$41#$31#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$04#$00#$00#$00#$00#$00 +
      #$00#$00#$D5#$60#$EC#$38#$00#$00#$00#$00#$14#$00#$00#$00#$02#$01 +
      #$41#$31#$B0#$F2#$8C#$42#$CB#$61#$11#$C3#$3F#$75#$1A#$43#$03#$00 +
      #$00#$00#$00#$00#$00#$00#$32#$63#$EC#$38#$00#$00#$00#$00#$14#$00 +
      #$00#$00#$02#$01#$41#$31#$6D#$E7#$9D#$41#$F6#$C8#$02#$C3#$17#$D9 +
      #$0F#$C2#$03#$00#$00#$00#$05#$01#$00#$00#$00#$71#$41#$AA#$AB#$00 +
      #$00#$00#$00#$14#$00#$00#$00#$03#$02#$41#$31#$89#$41#$F8#$41#$D5 +
      #$98#$1C#$43#$C5#$30#$98#$C3#$02#$00#$00#$00#$00#$00#$00#$00#$96 +
      #$99#$AA#$AB#$00#$00#$00#$00#$14#$00#$00#$00#$03#$02#$41#$31#$4C +
      #$B7#$A2#$C2#$71#$3D#$8F#$C1#$56#$5E#$F0#$43#$03#$00#$00#$00#$00 +
      #$00#$00#$00#$E0#$13#$AB#$AB#$00#$00#$00#$00#$14#$00#$00#$00#$03 +
      #$02#$41#$31#$46#$B6#$99#$C1#$08#$6C#$90#$42#$A2#$05#$14#$C3#$03 +
      #$00#$00#$00#$00#$00#$00#$00#$A7#$93#$AB#$AB#$00#$00#$00#$00#$14 +
      #$00#$00#$00#$03#$02#$41#$31#$98#$AE#$88#$C2#$8F#$C2#$1B#$C1#$C7 +
      #$5B#$C4#$43#$03#$00#$00#$00#$00#$00#$00#$00#$5F#$BD#$AB#$AB#$00 +
      #$00#$00#$00#$14#$00#$00#$00#$03#$02#$41#$31#$C5#$60#$D0#$C2#$9A +
      #$19#$0B#$42#$0A#$97#$CA#$42#$03#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
    end;
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

constructor TGamePractice.Create(const PL: TClientPlayer; GameData: TGameInfo;
  CreateEvent, UpdateEvent, DestroyEvent: fGameEvent;
  OnJoin, OnLeave: fPlayerEvent; GameID: UInt16);
begin
  inherited Create(PL, GameData, CreateEvent, UpdateEvent, DestroyEvent, Onjoin, OnLeave, GameID);

end;

destructor TGamePractice.Destroy;
begin
  inherited;
end;

function TGamePractice.GameInformation: AnsiString;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(Self.fGameData.Name, $28);
      WriteStr(#$00, $18);
      WriteUInt8(TCompare.IfCompare(Length(Self.fGameData.Password) > 0, 0, 1));
      WriteUInt8(TCompare.IfCompare(fStarted, 0, 1));
      WriteStr(#$00); { orange }
      WriteUInt8(Self.fGameData.MaxPlayer);
      WriteUInt8(UInt8(Self.fPlayers.Count));
      Write(fGameKey[0], 16);
      WriteStr(#$00#$1E);
      WriteUInt8(Self.fGameData.HoleTotal);
      WriteUInt8($4);
      WriteUInt16(fID);
      WriteUInt8(Self.fGameData.Mode);
      WriteUInt8(Self.fGameData.Map);
      WriteUInt32(Self.fGameData.VSTime);
      WriteUInt32(Self.fGameData.GameTime);
      WriteUInt32(Self.fTrophy); { trophy }
      WriteUInt8(Self.fIdle);
      WriteUInt8(TCompare.IfCompare(Self.fGameData.GMEvent, $1 , $0)); { is gm }
      WriteStr(#$00, $4A);
      WriteStr(#$64#$00#$00#$00#$64#$00#$00#$00);
      WriteUInt32(fOwner); { owner uid }
      WriteUInt8($13); { is practise }
      WriteUInt32(Self.fGameData.Artifact); { artifact }
      WriteUInt32(Self.fGameData.NaturalMode);
      WriteUInt32(Self.fGameData.GPTypeID);
      WriteUInt32(Self.fGameData.GPTypeIDA);
      WriteUInt32(Self.fGameData.GPTime);
      WriteUInt32(TCompare.IfCompare(Self.fGameData.GP, 1, 0));
      Exit(ToStr);
    end;
  finally
    Packet.Free;
  end;
end;

procedure TGamePractice.GameTimeUP;
begin
  inherited;
  Self.fRecv.Acquire;
  try
    Self.fTimer := 0;
    Self.PlayerLeavePractice;
  finally
    Self.fRecv.Release;
  end;
end;

procedure TGamePractice.GenerateExperience;
var
  P: TClientPlayer;
begin
  inherited;

  for P in Self.fPlayers do
    P.GameInfo.GameData.EXP := GameEXP.GetEXP(HOLE_REPEAT, 0, 0, 0, P.GameInfo.GameData.HoleCompletedCount);
end;

function TGamePractice.GetGameHeadData: AnsiString;
var
  CP: TClientPacket;
begin
  CP := TClientPacket.Create;
  try
    with CP do
    begin
      WriteStr(#$4A#$00);
      WriteStr(#$FF#$FF);
      WriteUInt8($4);
      WriteUInt8(Self.fGameData.Map);
      WriteUInt8(Self.fGameData.HoleTotal);
      WriteUInt8(Self.fGameData.Mode);
      if (Self.fGameData.HoleNumber > 0) then
      begin
        WriteUInt8(Self.fGameData.HoleNumber);
        WriteUInt32(Self.fGameData.LockHole);
      end;
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

function TGamePractice.GetPangDivide: UInt8;
begin
  if Self.fGameData.HoleTotal > 0 then
    Exit(6)
  else
    Exit(3);

  Exit(0);
end;

procedure TGamePractice.OnPlayerLeave;
begin
  inherited;
  { This chat class is do nothing }
end;

procedure TGamePractice.PlayerLeavePractice;
var
  P: TClientPlayer;
begin
  inherited;

  { free timer to prevent violation }
  Self.CancelTimer;

  { Copy Score }
  Self.CopyScore;

  Self.AfterMatchDone;
  Self.GenerateExperience;

  for P in Self.fPlayers do
    Self.Write(ShowNameScore(P.GetNickname, P.GameInfo.GameData.Score, P.GameInfo.GameData.Pang));

  Self.SendUnfinishedData;

  Self.Write(#$8C#$00);

  for P in Self.fPlayers do
  begin
    { CE 00 }
    Self.SendMatchData(P);
    { 33 01 }
  end;

  Self.fStarted := False;
end;

procedure TGamePractice.PlayerLoadSuccess(const PL: TClientPlayer);
begin
  inherited;

  PL.GameInfo.GameData.HoleComplete := False;
  //PL.GameInfo.GameData.ShotCount := 0;

  PL.Write(ShowWhoPlay(PL.ConnectionID));
end;

procedure TGamePractice.PlayerSendFinalResult(const PL: TClientPlayer;
  const CP: TClientPacket);
begin
  inherited;

end;

procedure TGamePractice.PlayerShotData(const PL: TClientPlayer;
  const CP: TClientPacket);
var
  S: TShotData;
  C: TClientPacket;
begin
  inherited;
  if not CP.Read(S, SizeOf(S)) then Exit;

  Self.ShotDecrypt(@S, SizeOf(TShotData));

  if (S.ShotType = sSuccess) then
  begin
    { Check Pang }
    if (Integer(PL.GameInfo.GameData.Pang - S.Pang) > 4000) or (Integer(PL.GameInfo.GameData.BonusPang - S.BonusPang) > 4000) then
      PL.Disconnect;
    PL.GameInfo.GameData.Pang := S.Pang;
    PL.GameInfo.GameData.BonusPang := S.BonusPang;
    PL.GameInfo.GameData.HoleComplete := True;
    Inc(PL.GameInfo.GameData.HoleCompletedCount, 1);
    PL.GameInfo.UpdateScore(PL.GameInfo.GameData.HoleComplete);

    if (PL.GameInfo.GameData.HoleCompletedCount >= Self.fGameData.HoleTotal) then
      PL.GameInfo.GameCompleted := True;

    writeln(pl.GameInfo.GameData.Score.ToString);
  end;

  if (S.ShotType = sOB) then
  begin
    Inc(PL.GameInfo.GameData.ShotCount, 2);
    Inc(PL.GameInfo.GameData.TotalShot, 2)
  end else begin
    Inc(PL.GameInfo.GameData.ShotCount, 1);
    Inc(PL.GameInfo.GameData.TotalShot, 1);
  end;

  { ShotData }
  C := TClientPacket.Create;
  try
    with C do
    begin
      WriteStr(#$6E#$00);
      WriteUInt32(PL.ConnectionID);
      WriteUInt8(PL.GameInfo.HolePos);
      WriteSingle(S.Vector.X);
      WriteSingle(S.Vector.Z);
      Write(S.MatchData, SizeOf(S.MatchData));
      Self.Send(C);
    end;
  finally
    FreeAndNil(C);
  end;
end;

procedure TGamePractice.PlayerShotInfo(const PL: TClientPlayer;
  const CP: TClientPacket);
begin
  inherited;
  { This is ununsed procedure but must show to prevent abstract error }
end;

procedure TGamePractice.PlayerStartGame;
begin
  if (Self.fStarted) then
    raise Exception.Create('PlayerStartGame: failed game already started');

  { Clear Player Score Data }
  Self.ClearPlayerData;

  { Trophy }
  fGold := $FFFFFFFF;
  fSilver1 := $FFFFFFFF;
  fSilver2 := $FFFFFFFF;
  fBronze1 := $FFFFFFFF;
  fBronze2 := $FFFFFFFF;
  fBronze3 := $FFFFFFFF;

  { Medal }
  fBestRecovery := $FFFFFFFF;
  fBestChipIn := $FFFFFFFF;
  fBestDrive := $FFFFFFFF;
  fBestSpeeder := $FFFFFFFF;
  fLongestPutt := $FFFFFFFF;
  fLuckyAward := $FFFFFFFF;

  Self.fStarted := True;

  Self.BuildHole;
  Self.GenerateGameTrophy;

  Self.Send(#$30#$02);
  Self.Send(#$31#$02);
  Self.Send(#$77#$00#$64#$00#$00#$00);

  Self.fUpdate(Self);

  { free timer to prevent violation }
  Self.CancelTimer;
  { Start Timer Count }
  Self.fTimer := Sched.AddSchedule(Self.fGameData.GameTime, GameTimeUP);
end;

procedure TGamePractice.PlayerSyncShot(const PL: TClientPlayer;
  const CP: TClientPacket);
var
  Succeed: Boolean;
begin
  inherited;

  // TODO
  Self.Write(ShowDropItem(PL.ConnectionID));

  Succeed := PL.GameInfo.GameCompleted;

  if Succeed then
    PL.Send(#$99#$01);

  { Show Treasure Gauge }
  PL.Write(ShowTreasureGuage($FF));

  { Show Name,Score,Pang when player finish their game }
  if Succeed then
    Self.Write(ShowNameScore(PL.GetNickname, PL.GameInfo.GameData.Score, PL.GameInfo.GameData.Pang));

  if PL.GameInfo.GameCompleted then
  begin
    with PL.GameInfo do
    begin
      Self.Write(ShowHoleData(PL.ConnectionID, HolePos, GameData.TotalShot, GameData.Score, Round(GameData.Pang / GetPangDivide), Round(GameData.BonusPang / GetPangDivide) ));
    end;
  end else if PL.GameInfo.GameData.HoleComplete then
  begin
    with PL.GameInfo do
    begin
      Self.Write(ShowHoleData(PL.ConnectionID, HolePos, GameData.TotalShot, GameData.Score, GameData.Pang, GameData.BonusPang));
    end;
  end;

  { Send Leave to lobby }
  if Succeed then
    Self.Write(ShowLeaveMatch(PL.ConnectionID, 2));

  // TODO DONT FORGET TO SYNC COIN DATA

  if Self._allFinished then
    Self._onAllPlayerFinished;
end;

procedure TGamePractice.SendHoleData(const PL: TClientPlayer);
var
  H: TGameHoleInfo;
begin
  inherited;

  H := Self.fHoles[PL.GameInfo.HolePos];

  if (H = nil) then Exit;

  PL.Write(ShowWeather(H.Weather));
  PL.Write(ShowWind(H.WindPower, H.WindDirection));
end;

procedure TGamePractice.SendPlayerOnCreate(const PL: TClientPlayer);
var
  Packet: TClientPacket;
begin
  inherited;
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$48#$00);
      WriteUInt8(0);
      WriteStr(#$FF#$FF);
      WriteUInt8(Self.fPlayers.Count);
      WriteStr(PL.GetGameInfomations(1));
      WriteUInt8(0);
    end;
    Self.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure TGamePractice.SendPlayerOnJoin(const PL: TClientPlayer);
var
  Packet: TClientPacket;
  P: TClientPlayer;
begin
  inherited;
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$48#$00);
      WriteUInt8(0);
      WriteStr(#$FF#$FF);
      WriteUInt8(Self.fPlayers.Count);
      for P in Self.fPlayers do
      begin
        WriteStr(P.GetGameInfomations(1));
      end;
      WriteUInt8(0);
    end;
    PL.Send(Packet);
  finally
    Packet.Free;
  end;
end;

procedure TGamePractice.SendUnfinishedData;
var
  P: PPGameData;
begin
  for P in Self.fPlayerData do
    if not P.GameCompleted then
      Self.Write(
        ShowHoleData(P.ConnectionID, P.HolePos, P.GameData.TotalShot, P.GameData.Score, Round(P.GameData.Pang / GetPangDivide), Round(P.GameData.BonusPang / GetPangDivide), False)
      );
end;

function TGamePractice.Validate: Boolean;
begin
  if Self.fGameData.MaxPlayer > 1 then
    Exit(False);

  Exit(True);
end;

procedure TGamePractice._onAllPlayerFinished;
var
  P: TClientPlayer;
begin
  { cancel timer }
  Self.CancelTimer;

  { copy score }
  Self.CopyScore;

  Self.AfterMatchDone;
  Self.GenerateExperience;

  Self.SendUnfinishedData;

  for P in Self.fPlayers do
    Self.SendMatchData(P);

  Self.fStarted := False;
end;

end.
