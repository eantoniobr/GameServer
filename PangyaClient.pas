unit PangyaClient;

interface

uses
  CryptLib, PangyaBuffer, ClientPacket,
  uInventory, uAction, Buffer, IdContext,
  Classes, System.SyncObjs, Tools, JunkPacket, System.Math.Vectors, UWriteConsole, Enum,
  PList, ListPair, ServerStr, Transactions, System.SysUtils, System.DateUtils, Defines,
  ItemData, MyList, System.Generics.Collections, UserMatchHistory;

type

  TClientPlayer = class
  private
    fConnectionID: UInt32;
    fStatus: Boolean;
    fSocket: TIdContext;
    fKey: Byte;
    fLogin: AnsiString;
    fNickname: AnsiString;
    fSex: Byte;
    fCapability: Byte;
    fUID: UInt32;
    FAUTH_KEY_1: AnsiString;
    FAUTH_KEY_2: AnsiString;
    fInventory: TPlayerInventory;
    fRoomID: UInt16;
    fAssist: UInt8;

    fMatchHistory: TMatchHistory;
    fCookie: UInt32;
    fCrypt: TCrypt;

    fGameServer: TObject;
    fLobby: TObject;

    fAchievements: TMyList<PAchievement>;
    fAchievementQuests: TMyList<PAchievementQuest>;
    fAchievementCounters: TDictionary<UInt32, PAchievementCounter>;

    fRecvCrit, fSendCrit: TCriticalSection;

    fInLobby: Boolean;
    fInGame: SmallInt;
    fVisible: Byte;

    fLockerPwd: AnsiString;
    fLockerPang: UInt32;
    fVerified: Boolean;

    procedure FreeAchievement;
    function GetLevel: UInt8;
    function GetExpPoint: UInt32;
    procedure SetLevel(Amount: UInt8);
    procedure SetExp(Amount: UInt32);
  public
    GameInfo: TPGameData;
    GuildData: TPlayerGuildData;
    Statistic: TStatistic;
    fClubTemporary: TClubUpgradeTemporary;

    procedure ReloadAchievement;

    function AddPang(Amount: UInt32): Boolean;
    function AddCookie(Amount: UInt32): Boolean;
    function RemovePang(Amount: UInt32): Boolean;
    function RemoveCookie(Amount: UInt32): Boolean;
    function GetPang: UInt32;
    function GetCookie: UInt32;
    procedure SetCookie(Cookie: UInt32);

    procedure Send(const Data: AnsiString; Encrypt: Boolean = True); overload;
    procedure Send(const Data: TPangyaBuffer; Encrypt: Boolean = True); overload;
    procedure Write(Data: TClientPacket);
    procedure SendKey;
    procedure SendTransaction;
    procedure SendPang;
    procedure SendCookies;
    procedure SendMailPopup;
    procedure SendExp;
    procedure Disconnect;
    procedure SendGuildData;
    procedure PushOffline;
    procedure SendAchievement;
    procedure SendCounter;

    procedure Process(const PacketData: AnsiString);

    function SetStatus(TStatus: Boolean): Boolean;
    function SetKey(TKey: Byte): Boolean;
    function SetLogin(const TLogin: AnsiString): Boolean;
    function SetNickname(const TNickname: AnsiString): Boolean;
    function SetSex(TSex: Byte): Boolean;
    function SetCapabilities(TCapa: Byte): Boolean;
    function SetUID(TUID: UInt32): Boolean;
    function SetAUTH_KEY_1(const TAUTH_KEY_1: AnsiString): Boolean;
    function SetAUTH_KEY_2(const TAUTH_KEY_2: AnsiString): Boolean;

    function GetAddress: AnsiString;
    function GetStatus: Boolean;
    function GetKey: Byte;
    function GetLogin: AnsiString;
    function GetNickname: AnsiString;
    function GetUID: UInt32;
    function GetPlayerAuth1: AnsiString;
    function GetPlayerAuth2: AnsiString;
    function GetSex: Byte;
    function GetCapabilities: Byte;
    function GetLobbyInfo: AnsiString;
    function GetGameInfo: AnsiString;
    function GetGameInfomations(Level: UInt8): AnsiString;
    function GetVSInfomation: AnsiString;

    function AddExp(Count: UInt32): Boolean;
    function AddItem(ItemAddData: TAddItem): TAddData;

    function RemoveLockerPang(Amount: UInt32): Boolean;
    function AddLockerPang(Amount: UInt32): Boolean;
    procedure SendLockerPang;

    constructor Create(TSocket: TIdContext);
    destructor Destroy; override;

    procedure SetGameID(ID: UInt32);

    //procedure AddAchivementQuest(TypeID, Count: UInt32);
    //procedure SendAchievement;

    property GameID: UInt16 read fRoomID;
    property Inventory: TPlayerInventory read fInventory write fInventory;
    property ConnectionID: UInt32 read fConnectionID write fConnectionID;
    property Context: TIdContext read fSocket;
    property InLobby: Boolean read fInLobby write fInLobby;
    property Visible: Byte read fVisible write fVisible;
    property LockerPWD: AnsiString read fLockerPwd write fLockerPwd;
    property LockerPang: UInt32 read fLockerPang write fLockerPang;
    property Verified: Boolean read fVerified write fVerified;
    property Lobby: TObject read fLobby write fLobby;

    { The below property is using for helper class }
    property Crypts: TCrypt read fCrypt;
    property Level: UInt8 read GetLevel write SetLevel;
    property Exp: UInt32 read GetExpPoint write SetExp;
    property Assist: UInt8 read fAssist write fAssist;

    property AchievemetCounters: TDictionary<UInt32, PAchievementCounter> read fAchievementCounters;
    property Achievements: TMyList<PAchievement> read fAchievements;
    property AchievementQuests: TMyList<PAchievementQuest> read fAchievementQuests;

    property GameServer: TObject read fGameServer write fGameServer;
  end;

implementation

uses
  ClientHelper, MailCore;

{ TClientPlayer }

procedure TClientPlayer.Send(const Data: AnsiString; Encrypt: Boolean = True);
var
  Stream: TMemoryStream;
  Buffer: AnsiString;
begin
  if not fSocket.Connection.Connected then
  begin
    WriteConsole(' Client is not connected nor yet created');
    Exit;
  end;

  if Length(Data) <= 0 then
  begin
    Exit;
  end;

  Stream := TMemoryStream.Create;
  try
    if Encrypt then
    begin
      Buffer := fCrypt.Encrypt(Data, Self.fKey);
      Stream.Write(Buffer[1], Length(Buffer));
    end
    else
    begin
      Stream.Write(Data[1], Length(Data));
    end;

    fSendCrit.Acquire;
    try
      fSocket.Connection.IOHandler.Write(Stream);
    finally
      fSendCrit.Leave;
    end;
  finally
    FreeAndNil(Stream);
  end;
end;

{ TClientPlayer }

{procedure TClientPlayer.AddAchivementQuest(TypeID, Count: UInt32);
begin
  Self.FAddAchivementQuest(TypeID, Count);
end;

procedure TClientPlayer.SendAchievement;
begin
  Self.FSendAchievement;
end; }

function TClientPlayer.AddCookie(Amount: UInt32): Boolean;
begin
  if fCookie >= High(UInt32) then
  begin
    Exit(False);
  end;
  Inc(fCookie, Amount);
  Exit(True);
end;

function TClientPlayer.AddExp(Count: UInt32): Boolean;
begin
  Exit(FAddExp(Count));
end;

function TClientPlayer.AddItem(ItemAddData: TAddItem): TAddData;
begin
  { case of pang and exp pocket }
  case ItemAddData.ItemIffId of
    $1A00015D: // exp pocket
      begin
        Self.AddExp(ItemAddData.Quantity);
      end;
    $1A000010: // pang pocket
      begin
        Self.AddPang(ItemAddData.Quantity);
      end;
  else
    Exit(Self.fInventory.AddItem(ItemAddData));
  end;
end;

procedure TClientPlayer.FreeAchievement;
var
  Achievement: PAchievement;
  Quest: PAchievementQuest;
  Counter: PAchievementCounter;
begin
  for Achievement in Self.Achievements do
    Dispose(Achievement);

  Self.Achievements.Clear;

  for Quest in Self.AchievementQuests do
    Dispose(Quest);

  Self.AchievementQuests.Clear;

  for Counter in Self.AchievemetCounters.Values do
    Dispose(Counter);

  Self.AchievemetCounters.Clear;
end;

constructor TClientPlayer.Create(TSocket: TIdContext);
begin
  fCrypt := TCrypt.Create;
  fInventory := TPlayerInventory.Create;
  fSocket := TSocket;
  Randomize;
  //Self.Key := Random($F) + 1;
  Self.fKey := 1;
  fInLobby := False;
  fInGame := -1;
  fVisible := 0;
  LockerPwd := '0';
  fRoomID := $FFFF;
  Verified := False;
  fUID := 0;
  fAssist := 0;
  fLockerPang := 0;

  fLobby := nil;

  fRecvCrit := TCriticalSection.Create;
  fSendCrit := TCriticalSection.Create;

  fAchievements := TMyList<PAchievement>.Create;
  fAchievementCounters := TDictionary<UInt32, PAchievementCounter>.Create;
  fAchievementQuests := TMyList<PAchievementQuest>.Create;
end;

destructor TClientPlayer.Destroy;
begin
  FreeAndNil(fInventory);
  FreeAndNil(fCrypt);

  FreeAndNil(fRecvCrit);
  FreeAndNil(fSendCrit);

  FreeAchievement;
  FreeAndNil(fAchievements);
  FreeAndNil(fAchievementCounters);
  FreeAndNil(fAchievementQuests);
  inherited;
end;

procedure TClientPlayer.Disconnect;
begin
  fSocket.Connection.Disconnect;
end;

function TClientPlayer.GetGameInfomations(Level: UInt8): AnsiString;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteInt32(Self.ConnectionId);
    if Level >= 1 then
    begin
      Packet.WriteStr(GetGameInfo);
    end;

    if Level >= 2 then
    begin
      Packet.WriteStr(fInventory.GetCharData);
    end;
    Result := Packet.ToStr;
  finally
    FreeAndNil(Packet);
  end;
end;

function TClientPlayer.GetKey: Byte;
begin
  Exit(fKey);
end;

function TClientPlayer.GetAddress: AnsiString;
begin
  Exit(AnsiString(fSocket.Binding.PeerIP));
end;

function TClientPlayer.GetPang: UInt32;
begin
  Exit(Self.Statistic.Pang);
end;

function TClientPlayer.GetPlayerAuth1: AnsiString;
begin
  Exit(Self.FAUTH_KEY_1);
end;

function TClientPlayer.GetPlayerAuth2: AnsiString;
begin
  Exit(Self.FAUTH_KEY_2);
end;

function TClientPlayer.GetCapabilities: Byte;
begin
  Exit(Self.fCapability);
end;

function TClientPlayer.GetCookie: UInt32;
begin
  Exit(Self.fCookie);
end;

function TClientPlayer.GetExpPoint: UInt32;
begin
  Exit(Self.Statistic.EXP);
end;

function TClientPlayer.GetGameInfo: AnsiString;
var
  Reply : TClientPacket;
begin
  Reply := TClientPacket.Create;
  try
    Reply.WriteStr(Self.fNickname , $10);
    Reply.WriteStr(#$00, $6);
    Reply.WriteStr(Self.GuildData.GuildName, $15);
    Reply.WriteUInt8(Self.GameInfo.GameSlot);
    Reply.WriteUInt32(Self.fVisible);
    Reply.WriteUInt32(0); // Title TypeId
    Reply.WriteUInt32(fInventory.GetCharTypeID); // Char TypeId
    Reply.WriteStr(#$00, $14); // Unknown Yet
    Reply.WriteUInt32(0); // Title TypeId
    Reply.WriteUInt8(Self.GameInfo.Role);
    Reply.WriteUInt8(TCompare.IfCompare<UInt8>(GameInfo.GameReady, $2, $0));
    Reply.WriteUInt8(Self.Statistic.Level); // Level
    Reply.WriteUInt8(0); // GM Notsure
    Reply.WriteStr(#$0A);
    Reply.WriteUInt32(Self.GuildData.GuildID); // GulidID
    Reply.WriteStr(TCompare.IfCompare<AnsiString>(Length(Self.GuildData.GuildImage) <= 0, 'guildmark', Self.GuildData.GuildImage), $9);
    Reply.WriteUInt32(0);
    Reply.WriteUInt32(Self.GetUID);
    Reply.WriteStr(GameInfo.Action.ToStr);
    Reply.WriteUInt32(1);
    Reply.WriteStr('Store Name', $1F);
    Reply.WriteStr(#$00, $21);
    Reply.WriteUInt32(fInventory.GetMascotTypeID); // Mascot TypeID
    Reply.WriteUInt8(TCompare.IfCompare<UInt8>(fInventory.IsExist(436207618), $1, $0)); // Pang Mastery
    Reply.WriteUInt8(TCompare.IfCompare<UInt8>(fInventory.IsExist(436207621), $1, $0)); // Nitro Pang Mastery
    Reply.WriteUInt32(0);
    Reply.WriteStr( AnsiFormat('%s@NT' ,[Self.fLogin]), 18);
    Reply.WriteStr(#$00, $6E);
    Reply.WriteStr(#$14#$00#$00#$6C#$42#$00#$00#$00);

    Result := Reply.ToStr;
  finally
    FreeAndNil(Reply);
  end;
end;

function TClientPlayer.GetLevel: UInt8;
begin
  Exit(Self.Statistic.Level);
end;

function TClientPlayer.GetLobbyInfo: AnsiString;
var
  Reply : TClientPacket;
begin
  Reply := TClientPacket.Create;
  try
    Reply.WriteUInt32(Self.fUID);
    Reply.WriteUInt32(Self.connectionId);
    Reply.WriteUInt16(Self.GameID); // Room Number
    Reply.WriteStr(Self.fNickname, 16);
    Reply.WriteStr(#$00 , 6);
    Reply.WriteUInt8(Self.Statistic.Level); // Level
    Reply.WriteUInt32(fVisible); // GM
    Reply.WriteUInt32(0);//964689929); // Title TypeID
    Reply.WriteStr(#$E8#$03#$00#$00); // Unknown
    Reply.WriteUInt8(fSex); // Add $10 for wings  + $10 + $20
    Reply.WriteUInt32(GuildData.GuildID); // Guild ID
    Reply.WriteStr(GuildData.GuildImage, 9); // Guild Images 9 Length
    Reply.WriteStr(#$00#$00#$00);
    Reply.WriteUInt8(1); // IS VIP ?
    Reply.WriteStr(#$00 , 6);
    Reply.WriteStr(Self.fLogin + '@NT' , 18);
    Reply.WriteStr(#$00, $6E);

    Result := Reply.ToStr;
  finally
    FreeAndNil(Reply);
  end;

end;

function TClientPlayer.GetLogin: AnsiString;
begin
  Exit(Self.fLogin);
end;

function TClientPlayer.GetNickname: AnsiString;
begin
  Exit(Self.fNickname);
end;

function TClientPlayer.GetSex: Byte;
begin
  Exit(Self.fSex);
end;

function TClientPlayer.GetStatus: Boolean;
begin
  Exit(Self.fStatus);
end;

function TClientPlayer.GetUID: UInt32;
begin
  Exit(Self.fUID);
end;

function TClientPlayer.GetVSInfomation: AnsiString;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteUInt16(fRoomID);
    Packet.WriteStr(fLogin, 15);
    Packet.WriteStr(#$00, 7);
    Packet.WriteStr(fNickname, 16);
    Packet.WriteStr(#$00, 6);
    Packet.WriteStr(Self.GuildData.GuildName, 21); // Guild Name
    Packet.WriteStr(Self.GuildData.GuildImage, 9); // Guild Emblem
    Packet.WriteStr(#$00, 15); // Unknown
    Packet.WriteUInt32(fConnectionID);
    Packet.WriteStr(JunkVersus1);
    Packet.WriteUInt32(fUID);
    Packet.WriteStr(JunkVersus2);
    Packet.WriteStr(fInventory.ItemSlot.GetItemSlot);
    Packet.WriteStr(JunkVersus3);
    Packet.WriteStr(fInventory.GetCharData);
    Packet.WriteStr(fInventory.GetCaddieData);
    Packet.WriteStr(fInventory.GetClubData);// Club Temp
    Packet.WriteStr(fInventory.GetMascotData);
    Packet.WriteStr(GameTime());
    Packet.WriteStr(#$00);
    Exit(Packet.ToStr);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure TClientPlayer.SetCookie(Cookie: UInt32);
begin
  Self.fCookie := Cookie;
end;

procedure TClientPlayer.Send(const Data: TPangyaBuffer; Encrypt : Boolean = True);
var
  OldPosition: Integer;
  Size: Integer;
  Buffer: AnsiString;
  Stream: TMemoryStream;
begin
  if not fSocket.Connection.Connected then
  begin
    WriteConsole(' Client is not connected nor yet created');
    Exit;
  end;

  fSendCrit.Acquire;

  Stream := TMemoryStream.Create;
  try
    OldPosition := Data.Seek(0, 1);
    Data.Seek(0, 0);
    Size := Data.GetSize;
    Data.ReadStr(Buffer, Size);
    Data.Seek(OldPosition, 0);

    if not fSocket.Connection.Connected then Exit;

    if Length(Buffer) <= 0 then Exit;

    if Encrypt then
    begin
      Buffer := fCrypt.Encrypt(Buffer, Self.fKey);
      Stream.Write(Buffer[1], Length(Buffer));
    end else begin
      Stream.Write(Buffer[1], Length(Buffer));
    end;

    fSocket.Connection.IOHandler.Write(Stream);
  finally
    FreeAndNil(Stream);
    fSendCrit.Leave;
  end;
end;

procedure TClientPlayer.SendCounter;
var
  Packet: TClientPacket;
  Counter: PAchievementCounter;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$1D#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(Self.AchievemetCounters.Count);
    Packet.WriteUInt32(Self.AchievemetCounters.Count);

    for Counter in Self.AchievemetCounters.Values do
    begin
      Packet.WriteUInt8(1);
      Packet.WriteUInt32(Counter.TypeID);
      Packet.WriteUInt32(Counter.ID);
      Packet.WriteUInt32(Counter.Quantity);
    end;

    Self.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure TClientPlayer.SendExp;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$D9#$01);
      WriteUInt32(Self.Statistic.Level);
      WriteUInt32(Self.Statistic.EXP);
    end;
    Self.Send(Packet);
  finally
    Packet.Free;
  end;
end;

procedure TClientPlayer.SendAchievement;
var
  Achievement: PAchievement;
  Counter: PAchievementCounter;
  Quest: PAchievementQuest;
  Packet, Packet2: TClientPacket;
  Count: UInt32;
  CounterTypeID, CounterID: UInt32;
begin
  Packet := TClientPacket.Create;
  Packet2 := TClientPacket.Create;
  try
    Packet.WriteStr(#$1E#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(Self.Achievements.Count);
    Packet.WriteUInt32(Self.Achievements.Count);

    for Achievement in Self.Achievements do
    begin
      Packet.WriteUInt8(1);
      Packet.WriteUInt32(Achievement.TypeID);
      Packet.WriteUInt32(Achievement.ID);
      Packet.WriteUInt32(Achievement.AchievementType);

      Count := 0;
      Packet2.Clear;
      for Quest in Self.AchievementQuests do
      begin
        if Quest.AchievementIndex = Achievement.ID then
        begin
          Inc(Count, 1);

          if Self.AchievemetCounters.TryGetValue(Quest.CounterIndex, Counter) then
          begin
            CounterTypeID := Counter.TypeID;
            CounterID := Counter.ID;
          end else begin
            CounterTypeID := 0;
            CounterID := 0;
          end;

          Packet2.WriteUInt32(Quest.AchievementTypeID);
          Packet2.WriteUInt32(CounterTypeID);
          Packet2.WriteUInt32(CounterID);
          Packet2.WriteUInt32(Quest.SuccessDate);
        end;
      end;

      Packet.WriteUInt32(Count);
      Packet.WriteStr(Packet2.ToStr);
    end;

    Self.Send(Packet);
  finally
    FreeAndNil(Packet);
    FreeAndNil(Packet2);
  end;
end;

procedure TClientPlayer.SendCookies;
var
  Reply : TClientPacket;
begin
  Reply := TClientPacket.Create;
  try
    Reply.WriteStr(#$96#$00);
    Reply.WriteUInt32(fInventory.PlayerCookie);
    Reply.WriteStr(#$00 , 4);
    Self.Send(Reply.ToStr);
  finally
    FreeAndNil(Reply);
  end;
end;

procedure TClientPlayer.SendGuildData;
begin
  Self.FSendGuildData;
end;

procedure TClientPlayer.SendKey;
var
  Reply: TPangyaBuffer;
begin
  Reply := TPangyaBuffer.Create;
  try
    Reply.WriteStr(#$00);
    Reply.WriteUInt16(Length(GetAddress) + 8);
    Reply.WriteStr(#$00#$3F#$00#$01#$01);
    Reply.WriteUInt8(GetKey);
    Reply.WritePStr(GetAddress);
    Send(Reply, False);
  finally
    FreeAndNil(Reply);
  end;
end;

procedure TClientPlayer.SendLockerPang;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$72#$01);
    Packet.WriteUInt64(Self.fLockerPang);
    Self.Send(Packet);
  finally
    Packet.Free;
  end;
end;

procedure TClientPlayer.SendPang;
var
  Packet : TPangyaBuffer;
begin
  Packet := TPangyaBuffer.Create;
  try
    Packet.WriteStr(#$C8#$00);
    Packet.WriteUInt32(fInventory.PlayerPang);
    Packet.WriteStr(#$00, 12);

    Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure TClientPlayer.SendTransaction;
begin
  if Self.fInventory.TranCount <= 0 then
  begin
    Exit;
  end;

  Self.Send(fInventory.GetTransaction);
end;

function TClientPlayer.SetAUTH_KEY_1(const TAUTH_KEY_1: AnsiString): Boolean;
begin
  Self.FAUTH_KEY_1 := TAUTH_KEY_1;
  Result := True;
end;

function TClientPlayer.SetAUTH_KEY_2(const TAUTH_KEY_2: AnsiString): Boolean;
begin
  Self.FAUTH_KEY_2 := TAUTH_KEY_2;
  Result := True;
end;

function TClientPlayer.SetCapabilities(TCapa: Byte): Boolean;
begin
  Self.fCapability := TCapa;
  if TCapa = 4 then
  begin
    Self.fVisible := 4;
  end;
  Result := True
end;

procedure TClientPlayer.SetExp(Amount: UInt32);
begin
  Self.Statistic.EXP := Amount;
end;

procedure TClientPlayer.SetGameID(ID: UInt32);
begin
  Self.fRoomID := ID;
end;

function TClientPlayer.SetKey(TKey: Byte): Boolean;
begin
  Self.fKey := TKey;
  Result := True;
end;

procedure TClientPlayer.SetLevel(Amount: UInt8);
begin
  Self.Statistic.Level := Amount;
end;

function TClientPlayer.SetLogin(const TLogin: AnsiString): Boolean;
begin
  Self.fLogin := TLogin;
  Result := True;
end;

function TClientPlayer.SetNickname(const TNickname: AnsiString): Boolean;
begin
  Self.fNickname := TNickname;
  Result := True;
end;

function TClientPlayer.SetSex(TSex: Byte): Boolean;
begin
  Self.fSex := TSex;
  Result := True
end;

function TClientPlayer.SetStatus(TStatus: Boolean): Boolean;
begin
  Self.fStatus := TStatus;
  Result := True;
end;

function TClientPlayer.SetUID(TUID: UInt32): Boolean;
begin
  Self.fUID := TUID;
  fInventory.UID := TUID;
  Result := True;
end;

procedure TClientPlayer.Write(Data: TClientPacket);
begin
  try
    Send(Data);
  finally
    FreeAndNil(Data);
  end;
end;

procedure TClientPlayer.SendMailPopup;
begin
  fRecvCrit.Acquire;
  try
    PlayerShowMailPopUp(Self);
  finally
    fRecvCrit.Leave;
  end;
end;

procedure TClientPlayer.Process(const PacketData: AnsiString);
begin
  fRecvCrit.Acquire;
  try
    Self.fProcess(PacketData);
  finally
    fRecvCrit.Release;
  end;
end;

procedure TClientPlayer.PushOffline;
begin
  if Self.fUID <= 0 then Exit;

  Self.fPushOffline;
end;

procedure TClientPlayer.ReloadAchievement;
begin
  Self.ReloadAchievement;
end;

function TClientPlayer.RemoveCookie(Amount: UInt32): Boolean;
begin
  if fCookie < Amount then
  begin
    Exit(False);
  end;
  Dec(fCookie, Amount);
  Exit(True);
end;

function TClientPlayer.RemoveLockerPang(Amount: UInt32): Boolean;
begin
  if (Self.fLockerPang < Amount) then Exit(False);
  Dec(Self.fLockerPang, Amount);
  Exit(True);
end;

function TClientPlayer.RemovePang(Amount: UInt32): Boolean;
begin
  if Self.Statistic.Pang < Amount then
  begin
    Exit(False);
  end;
  Dec(Self.Statistic.Pang, Amount);
  Exit(True);
end;

function TClientPlayer.AddLockerPang(Amount: UInt32): Boolean;
begin
  Inc(Self.fLockerPang, Amount);
  Exit(True);
end;

function TClientPlayer.AddPang(Amount: UInt32): Boolean;
begin
  if Self.Statistic.Pang >= High(UInt32) then
  begin
    Exit(False);
  end;
  Inc(Self.Statistic.Pang, Amount);
  Exit(True);
end;

end.
