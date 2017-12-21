unit PacketCreator;

interface

uses
  ClientPacket, PangyaClient, Enum, ItemData, Tools, PList, System.Math.Vectors, System.SysUtils, System.Math,
  System.DateUtils, PlayersList, Defines;

type
  TRoomError = (reRoomFull = $2, reRoomNotExist = $3, rePasswordError = $4,
                reLevelRequire = $5, reRoomCreateFail = $7, reRoomIsInProgress = $8);
  TLobbyAction = (laSendLobby = $1, laLeaveLobby = $2, laUpdatePlayer = $3);
  TGameAction = (gaCreate = $1, gaDestroy = $2, gaUpdate = $3);

function ShowBuyItem(Item: TAddData; BuyData: TBuyItem; Pang, Cookie: UInt32): TClientPacket;
function ShowBuyItemSucceed(Pang, Cookie: UInt32): TClientPacket;
function ChatText(const Nickname,Text: AnsiString; GM: Boolean): TClientPacket;
function ShowRoomError(Error: TRoomError): TClientPacket;
function ShowPlayerAction(const Player: TClientPlayer; Action: TLobbyAction): TClientPacket;
function ShowGameAction(GameInfomation: AnsiString; Action: TGameAction): TClientPacket;
// ## Box
function ShowOpenBoxFail: TClientPacket;
function ShowBoxItem(Lists: TPointerList): TClientPacket; overload;
function ShowBoxITem(BoxTypeID, TypeID, Quantity: UInt32): TClientPacket; overload;
function ShowBoxNewItem(Lists: TPointerList; Pang, Cookie: UInt32): TClientPacket;
function ShowBoxAnnounce(const Text: AnsiString): TClientPacket;
// ## Game
function ShowLeaveGame: TClientPacket;
function ShowWhoPlay(ConnectionID: UInt32): TClientPacket;
function ShowGameIcon(ConnectionID: UInt32;IconType: UInt16): TClientPacket;
function ShowSleep(ConnectionID: UInt32; SleepType: UInt8): TClientPacket;
function ShowPlayerUseItem(TypeID, ConnectionID: UInt32): TClientPacket;
function ShowPlayerChangeClub(ConnectionID: UInt32; ClubType: UInt8): TClientPacket;
function ShowPlayerRotate(ConnectionID: UInt32; Angle: Single): TClientPacket;
function ShowAssistPutting(AssistTypeID, UID: UInt32): TClientPacket;
function ShowRoomEntrance(ConnectionID: UInt32): TClientPacket;
function ShowGameMarking(ConnectionID: UInt32; Pos: TPoint3D): TClientPacket;
function ShowGameReady(ConnectionID: UInt32; Types: UInt8): TClientPacket;
function ShowPlayerLoading(ConnectionID: UInt32; Progess: UInt8): TClientPacket;
function ShowPlayerPauseGame(ConnectionID: UInt32; Types: UInt8): TClientPacket;
function ShowPlayerTimeBoost(ConnectionID: UInt32): TClientPacket;
function ShowMatchTimeUsed(SecondUsed: UInt32): TClientPacket;
function ShowWeather(Weather: UInt16): TClientPacket;
function ShowWind(Power, Direction: UInt16): TClientPacket;
function ShowGameLeave(Name: AnsiString): TClientPacket; overload;
function ShowGameLeave(ConnectionID: UInt32; Opt: UInt8 = 1): TClientPacket; overload;
function ShowNewMaster(ConnectionID: UInt32): TClientPacket;
function ShowSendGameLobby: TClientPacket;
function SendPlayerPlay(ConnectionID: UInt32): TClientPacket;
function ShowDropItem(ConnectionID: UInt32): TClientPacket;
function ShowNameScore(const Nickname: AnsiString; Score: Integer; Pang: UInt32; Assist: Boolean = False): TClientPacket;
function ShowHoleData(ConID: UInt32; CurHole, TotalShot: UInt8; Score: Integer; Pang, BonusPang: UInt32; Finished: Boolean = True): TClientPacket;
function ShowLeaveMatch(ConID: UInt32; Types: UInt8): TClientPacket;
function ShowTreasureGuage(Gauge: UInt32): TClientPacket;
function ShowTeam(ConnectionID: UInt32; Team: TTEAM_VERSUS): TClientPacket;
function ShowShotData(ShotData: TShotData): TClientPacket;
function ShowDropBall(Position: TPoint3D): TClientPacket;
function ShowPowerShot(ConID: UInt32; PowerShot: TPOWER_SHOT): TClientPacket;
function ShowSecGP(Sec: UInt32): TClientPacket;
// ## Game effect
function ShowAnimalEffect(UID: UInt32): TClientPacket;
// ## Lobby
function LobbyInfo(const LobbyName: AnsiString; MaxPlayer, PlayerCount, LobbyID: Integer): AnsiString;
// ## nickname
function ShowNicknameChangeDup: TClientPacket;
function ShowNicknameChangeSucceed(Nickname: AnsiString): TClientPacket;
// ## club
function ShowClubUpgrade(Pos: TCLUB_STATUS; ClubIndex: UInt32; PangConsume: UInt32): TClientPacket;
function ShowClubDowngrade(Pos: TCLUB_STATUS; ClubIndex: UInt32; PangConsume: UInt32): TClientPacket;
// ## auth
function ShowAuthNotice(const Name, Msg: AnsiString): TClientPacket;

implementation

function ShowBuyItem(Item: TAddData; BuyData: TBuyItem; Pang, Cookie: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$AA#$00#$01#$00);
    WriteUInt32(Item.ItemTypeID);
    WriteUInt32(Item.ItemIndex);
    WriteUInt16(BuyData.DayTotal);
    WriteUInt8(BuyData.Flag);
    WriteUInt16(Item.ItemNewQty);
    WriteStr(GetFixTime(BuyData.EndDate));
    WriteStr(Item.ItemUCCKey ,$9);
    WriteUInt64(Pang);
    WriteUInt64(Cookie);
  end;
end;

function ShowBuyItemSucceed(Pang, Cookie: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$68#$00);
    WriteUInt32(0); // Show Succeed
    WriteUInt64(Pang);
    WriteUInt64(Cookie);
  end;
end;

function ChatText(const Nickname,Text: AnsiString; GM: Boolean): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$40#$00);
    WriteStr(TCompare.IfCompare<AnsiString>(GM, #$80, #$00));
    WritePStr(Nickname);
    WritePStr(Text);
  end;
end;

function LobbyInfo(const LobbyName: AnsiString; MaxPlayer, PlayerCount, LobbyID: Integer): AnsiString;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(LobbyName, 10);
    Packet.WriteStr(#$00, $36);
    Packet.WriteUInt16(MaxPlayer);
    Packet.WriteUInt16(PlayerCount);
    Packet.WriteUInt8(LobbyID);
    Packet.WriteUInt32(1);
    Packet.WriteUInt32(0);
    Exit(Packet.ToStr);
  finally
    Packet.Free;
  end;
end;

function ShowRoomError(Error: TRoomError): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$49#$00);
    WriteUInt8(Integer(Error));
  end;
end;

function ShowLeaveGame: TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$4C#$00#$FF#$FF);
  end;
end;

function ShowPlayerAction(const Player: TClientPlayer; Action: TLobbyAction): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$46#$00);
    WriteUInt8(Integer(Action));
    WriteUInt8(1); // player count: Should always be 1
    WriteStr(Player.GetLobbyInfo);
  end;
end;

function ShowGameAction(GameInfomation: AnsiString; Action: TGameAction): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$47#$00);
    WriteUInt8(1);
    WriteUInt8(Integer(Action));
    WriteStr(#$FF#$FF);
    WriteStr(GameInfomation);
  end;
end;

function ShowOpenBoxFail: TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$9D#$01#$3A#$0B#$20#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
  end;
end;

function ShowBoxItem(Lists: TPointerList): TClientPacket;
var
  APoint: Pointer;
begin
  Result := TClientPacket.Create;
  Result.WriteStr(#$A7#$00);
  Result.WriteUInt8(Lists.Count);
  with Result do
  begin
    for APoint in Lists do
    begin
      WriteUInt32(PItemData(APoint).TypeID);
      WriteUInt32(PItemData(APoint).ItemIndex);
      WriteUInt16(PItemData(APoint).ItemQuantity);
    end;
  end;
end;

function ShowBoxITem(BoxTypeID, TypeID, Quantity: UInt32): TClientPacket; overload;
begin
  Result := TClientPacket.Create;
  Result.WriteStr(#$9D#$01);
  Result.WriteUInt32(0);
  Result.WriteUInt32(BoxTypeID);
  Result.WriteUInt32(TypeID);
  Result.WriteUInt32(Quantity);
end;

function ShowBoxNewItem(Lists: TPointerList; Pang, Cookie: UInt32): TClientPacket;
var
  APoint: Pointer;
begin
  Result := TClientPacket.Create;
  Result.WriteStr(#$AA#$00);
  Result.WriteUInt16(Lists.Count);
  with Result do
  begin
    for APoint in Lists do
    begin
      WriteUInt32(PItemData(APoint).TypeID);
      WriteUInt32(PItemData(APoint).ItemIndex);
      WriteStr(#$00, 3);
      WriteUInt16(PItemData(APoint).ItemQuantity);
      WriteStr(#$00, 25);
    end;
    WriteUInt64(Pang);
    WRiteUInt64(Cookie);
  end;
end;

function ShowBoxAnnounce(const Text: AnsiString): TClientPacket;
begin
  Result := TClientPacket.Create;
  Result.WriteStr(#$04#$00);
  Result.WritePStr(Text);
end;

function ShowWhoPlay(ConnectionID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$53#$00);
    WriteUInt32(ConnectionID);
  end;
end;

function ShowGameIcon(ConnectionID: UInt32;IconType: UInt16): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$5D#$00);
    WriteUInt32(ConnectionID);
    WriteUInt16(IconType);
  end;
end;

function ShowSleep(ConnectionID: UInt32; SleepType: UInt8): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$8E#$00);
    WriteUInt32(ConnectionID);
    WriteUInt8(SleepType);
  end;
end;

function ShowPlayerUseItem(TypeID, ConnectionID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$5A#$00);
    WriteUInt32(TypeID);
    WriteUInt32(Random($FFFF));
    WriteUInt32(ConnectionID);
  end;
end;

function ShowPlayerChangeClub(ConnectionID: UInt32; ClubType: UInt8): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$59#$00);
    WriteUInt32(ConnectionID);
    WriteUInt8(ClubType);
  end;
end;

function ShowPlayerRotate(ConnectionID: UInt32; Angle: Single): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$56#$00);
    WriteUInt32(ConnectionID);
    WriteSingle(Angle);
  end;
end;

function ShowAssistPutting(AssistTypeID, UID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$6B#$02);
    WriteUInt32(0);
    WriteUInt32(AssistTypeID);
    WriteUInt32(UID);
  end;
end;

function ShowRoomEntrance(ConnectionID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$96#$01);
    WriteUInt32(ConnectionID);
    WriteStr(
      #$00#$00#$80 +
      #$3F#$00#$00 +
      #$80#$3F#$00 +
      #$00#$80#$3F +
      #$00#$00#$80 +
      #$3F#$00#$00 +
      #$80#$3F);
  end;
end;

function ShowGameMarking(ConnectionID: UInt32; Pos: TPoint3D): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$F8#$01);
    WriteUInt32(ConnectionID);
    Write(Pos, SizeOf(TPoint3D));
  end;
end;

function ShowGameReady(ConnectionID: UInt32; Types: UInt8): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$78#$00);
    WriteUInt32(ConnectionID);
    WriteUInt8(Types);
  end;
end;

function ShowPlayerLoading(ConnectionID: UInt32; Progess: UInt8): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$A3#$00);
    WriteUInt32(ConnectionID);
    WriteUInt8(Progess);
  end;
end;

function ShowPlayerPauseGame(ConnectionID: UInt32; Types: UInt8): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$8B#$00);
    WriteUInt32(ConnectionID);
    WriteUInt8(Types);
  end;
end;

function ShowAnimalEffect(UID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$36#$02);
    WriteUInt32(UID);
  end;
end;

function ShowPlayerTimeBoost(ConnectionID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$C7#$00);
    WriteStr(#$00#$00#$40#$40);
    WriteUInt32(ConnectionID);
  end;
end;

function ShowMatchTimeUsed(SecondUsed: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$8D#$00);
    WriteUInt32(SecondUsed);
  end;
end;

function ShowWeather(Weather: UInt16): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$9E#$00);
    WriteUInt16(Weather);
    WriteUInt8(0);
  end;
end;

function ShowWind(Power, Direction: UInt16): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$5B#$00);
    WriteUInt16(Power);
    WriteUInt16(Direction);
    WriteUInt8(1);
  end;
end;

function ShowGameLeave(Name: AnsiString): TClientPacket; overload;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$40#$00);
    WriteUInt8(2);
    WritePStr(Name);
    WriteStr(#$00#$00);
  end;
end;

function ShowGameLeave(ConnectionID: UInt32; Opt: UInt8 = 1): TClientPacket; overload;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    case Opt of
      1:
        begin
          WriteStr(#$61#$00);
          WriteUInt32(ConnectionID);
        end;
      2:
        begin
          WriteStr(#$48#$00);
          WriteUInt8(2); // ## Leave Game
          WriteStr(#$FF#$FF);
          WriteUInt32(ConnectionID);
        end;
      3:
        begin
          WriteStr(#$6C#$00);
          WriteUInt32(ConnectionID);
          WriteUInt8(3); // ## 2: leave from game to lobby game, 3: leave from room
        end;
    end;
  end;
end;

function ShowNewMaster(ConnectionID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$7C#$00);
    WriteUInt32(ConnectionID);
    WriteStr(#$FF#$FF);
  end;
end;

function ShowSendGameLobby: TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$67#$00);
  end;
end;

function SendPlayerPlay(ConnectionID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$63#$00);
    WriteUInt32(ConnectionID);
  end;
end;

function ShowDropItem(ConnectionID: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$CC#$00);
    WriteUInt32(ConnectionID);
    WriteUInt8(0);
  end;
end;

function ShowNameScore(const Nickname: AnsiString; Score: Integer; Pang: UInt32; Assist: Boolean): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$40#$00);
    WriteStr(#$11);
    WritePStr(Nickname);
    WriteStr(#$00#$00);
    WriteUInt32(Score);
    WriteUInt64(Pang);
    WriteUInt8(0);
  end;
end;

function ShowHoleData(ConID: UInt32; CurHole, TotalShot: UInt8; Score: Integer; Pang, BonusPang: UInt32; Finished: Boolean = True): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$6D#$00);
    WriteUInt32(ConID);
    WriteUInt8(CurHole);
    WriteUInt8(TotalShot);
    WriteUInt32(Score);
    WriteUInt64(Pang);
    WriteUInt64(BonusPang);
    WriteUInt8(TCompare.IfCompare<UInt8>(Finished, 1, 0));
  end;
end;

function ShowLeaveMatch(ConID: UInt32; Types: UInt8): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$6C#$00);
    WriteUInt32(ConID);
    WriteUInt8(Types);
  end;
end;

function ShowTreasureGuage(Gauge: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$32#$01);
    WriteUInt32(Gauge);
  end;
end;

function ShowNicknameChangeDup: TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$50#$00);
    WriteUInt32(2);
  end;
end;

function ShowNicknameChangeSucceed(Nickname: AnsiString): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$50#$00);
    WriteUInt32(0);
    WritePStr(Nickname);
  end;
end;

function ShowClubUpgrade(Pos: TCLUB_STATUS; ClubIndex: UInt32; PangConsume: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$A5#$00);
    WriteUInt8(1);
    WriteUInt8(1);
    WriteUInt8(UInt8(Pos));
    WriteUInt32(ClubIndex);
    WriteUInt32(PangConsume);
    WriteUInt32(0);
  end;
end;

function ShowClubDowngrade(Pos: TCLUB_STATUS; ClubIndex: UInt32; PangConsume: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$A5#$00);
    WriteUInt8(2);
    WriteUInt8(3);
    WriteUInt8(UInt8(Pos));
    WriteUInt32(ClubIndex);
    WriteUInt32(PangConsume);
    WriteUInt32(0);
  end;
end;

function ShowTeam(ConnectionID: UInt32; Team: TTEAM_VERSUS): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$7D#$00);
    WriteUInt32(ConnectionID);
    WriteUInt8(UInt8(Team));
  end;
end;

function ShowShotData(ShotData: TShotData): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$64#$00);
    Write(ShotData, SizeOf(TShotData));
  end;
end;

function ShowDropBall(Position: TPoint3D): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$60#$00);
    Write(Position.X, SizeOf(TPoint3D));
  end;
end;

function ShowPowerShot(ConID: UInt32; PowerShot: TPOWER_SHOT): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$58#$00);
    WriteUInt32(ConID);
    WriteUInt8(UInt8(PowerShot));
  end;
end;

function ShowSecGP(Sec: UInt32): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$40#$00);
    WriteUInt32($C);
    WriteUInt8(0);
    WriteUInt32(Sec);
  end;
end;

function ShowAuthNotice(const Name, Msg: AnsiString): TClientPacket;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$02#$00);
    WritePStr(Name);
    WritePStr(Msg);
  end;
end;

end.
