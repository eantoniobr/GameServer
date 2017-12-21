unit GuildCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  ClientPacket, PangyaClient, Tools, ErrorCode, System.SysUtils, Enum, ItemData,
  AuthClient;

procedure PlayerCallGuildList(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerSearchGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerCheckGuildAvailble(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerCreateGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerRequestGuildData(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGetGuildPlayer(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGetGuildLog(const PL: TClientPlayer);
procedure PlayerJoinGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerCancelJoinGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGuildAccept(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGuildKick(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGuildPromote(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerChangeGuildIntro(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerChangeGuildNotice(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerChangeGuildSelfIntro(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerLeaveGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGuildCallUpload(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGuildAfterUpload(const PL: TClientPlayer);
procedure SendUpdateGuild(const PL: TClientPlayer; UID: UInt32);

implementation

{
 GUILD POSITION
 1 = Guild Master
 2 = Officer
 3 = Member
 9 = Wait for approval
}

procedure PlayerCallGuildList(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Query: TFDQuery;
  Con: TFDConnection;
  PageSelected: UInt32;
  Packet: TClientPacket;
const
  PacketID: TChar = #$BC#$01;
  procedure SendCode(Code: UInt32); overload;
  var
    IPacket: TClientPacket;
  begin
    IPacket := TClientPacket.Create;
    try
      IPacket.WriteStr(PacketID);
      IPacket.WriteUInt32(Code);
      PL.Send(IPacket);
    finally
      FreeAndNil(IPacket);
    end;
  end;
  procedure SendCode(Code: TChar); overload;
  begin
    PL.Send(PacketID + Code);
  end;
begin
  if not ClientPacket.ReadUInt32(PageSelected) then
  begin
    SendCode(0);
    Exit;
  end;

  CreateQuery(Query, Con, False);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcGuildGetList] @PAGE = :PAGE, @TOTAL = :TOTAL', [PageSelected, 15]);

    Packet.WriteStr(PacketID);
    Packet.WriteUInt32(1);
    Packet.WriteUInt32(PageSelected);
    Packet.WriteUInt32(Query.FieldByName('GUILD_TOTAL').AsInteger);

    QueryNextSet(Query);

    Packet.WriteUInt16(Query.RecordCount);

    while not Query.Eof do
    begin
      Packet.WriteUInt32(Query.FieldByName('GUILD_INDEX').AsInteger);
      Packet.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, 21);
      Packet.WriteUInt32(Query.FieldByName('GUILD_PANG').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('GUILD_POINT').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('GUILD_TOTAL_MEMBER').AsInteger);
      Packet.WriteStr(GetFixTime(Query.FieldByName('GUILD_CREATE_DATE').AsDateTime));
      Packet.WriteStr(Query.FieldByName('GUILD_INTRODUCING').AsAnsiString , 105);
      Packet.WriteUInt32(Query.FieldByName('GUILD_LEADER_UID').AsInteger);
      Packet.WriteStr(Query.FieldByName('GUILD_LEADER_NICKNAME').AsAnsiString , 22);
      Packet.WriteStr(Query.FieldByName('GUILD_IMAGE').AsAnsiString , 9);
      Packet.WriteStr(#$00#$00#$00);

      Query.Next;
    end;

    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerSearchGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
const
  PacketID: TChar = #$BD#$01;
type
  TSearchGuild = packed record
    var PageSelect: UInt32;
    var GuildSearch: AnsiString;
  end;
var
  GuildSearch: TSearchGuild;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
begin
  if not ClientPacket.ReadUInt32(GuildSearch.PageSelect) then Exit;
  if not ClientPacket.ReadPStr(GuildSearch.GuildSearch) then Exit;

  CreateQuery(Query, Con, False);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcGuildGetList] @PAGE = :PAGE, @TOTAL = :TOTAL, @SEARCH = :SEARCH', [GuildSearch.PageSelect, 15, GuildSearch.GuildSearch]);

    Packet.WriteStr(PacketID);
    Packet.WriteUInt32(1);
    Packet.WriteUInt32(GuildSearch.PageSelect);
    Packet.WriteUInt32(Query.FieldByName('GUILD_TOTAL').AsInteger);

    QueryNextSet(Query);

    Packet.WriteUInt16(Query.RecordCount);

    while not Query.Eof do
    begin
      Packet.WriteUInt32(Query.FieldByName('GUILD_INDEX').AsInteger);
      Packet.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, 21);
      Packet.WriteUInt32(Query.FieldByName('GUILD_PANG').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('GUILD_POINT').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('GUILD_TOTAL_MEMBER').AsInteger);
      Packet.WriteStr(GetFixTime(Query.FieldByName('GUILD_CREATE_DATE').AsDateTime));
      Packet.WriteStr(Query.FieldByName('GUILD_INTRODUCING').AsAnsiString , 105);
      Packet.WriteUInt32(Query.FieldByName('GUILD_LEADER_UID').AsInteger);
      Packet.WriteStr(Query.FieldByName('GUILD_LEADER_NICKNAME').AsAnsiString , 22);
      Packet.WriteStr(Query.FieldByName('GUILD_IMAGE').AsAnsiString , 9);
      Packet.WriteStr(#$00#$00#$00);

      Query.Next;
    end;

    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerCheckGuildAvailble(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  GuildName: AnsiString;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
const
  PacketID: TChar = #$B6#$01;
begin
  if not ClientPacket.ReadPStr(GuildName) then
  begin
    Exit;
  end;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcGuildNameAvailable] @GUILDNAME = :GNAME', [GuildName]);

    Packet.WriteStr(PacketID);

    if Query.FieldByName('CODE').AsInteger = 1 then
    begin
      Packet.WriteStr(#$F3#$D2#$00#$00);
    end;

    if Query.FieldByName('CODE').AsInteger = 0 then
    begin
      Packet.WriteUInt32(1);
      Packet.WritePStr(GuildName);
    end;

    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerCreateGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TCreateGuild = packed record
    var GuildName: AnsiString;
    var GuildIntro: AnsiString;
  end;
var
  CreateGuild: TCreateGuild;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  RemoveItemData: TAddData;
const
  PackedID: TChar = #$B5#$01;
  GuildCreation: UInt32 = 436207919;
  function Check(Data: TPlayerGuildData): Boolean;
  begin
    Result := Data.GuildID = 0;
  end;
begin
  if not ClientPacket.ReadPStr(CreateGuild.GuildName) then Exit;
  if not ClientPacket.ReadPStr(CreateGuild.GuildIntro) then Exit;

  if not PL.Inventory.IsExist(GuildCreation) then
  begin
    PL.Send(#$B5#$01#$F1#$D2#$00#$00);
    Exit;
  end;

  if not Check(PL.GuildData) then
  begin
    PL.Send(#$B5#$01#$EE#$D4#$00#$00);
    Exit;
  end;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_CREATE] @UID = :UID, @GUILDNAME = :GUILDNAEME, @GUILDINTRO = :GUILDINTRO',
    [PL.GetUID, CreateGuild.GuildName, CreateGuild.GuildIntro]);

    if Query.FieldByName('CODE').AsInteger = 10 then
    begin
      // Player is in guild
      PL.Send(#$B5#$01#$EE#$D4#$00#$00);
      Exit;
    end;

    if Query.FieldByName('CODE').AsInteger = 2 then
    begin
      PL.Send(#$B5#$01#$00#$00#$00#$00);
      Exit;
    end;

    if Query.FieldByName('CODE').AsInteger = 9 then
    begin
      // Player is in guild
      PL.Send(#$B5#$01#$F3#$D2#$00#$00);
      Exit;
    end;

    if Query.FieldByName('CODE').AsInteger = 0 then
    begin
      // Delete Guild Creator
      RemoveItemData := PL.Inventory.Remove(GuildCreation, 1, False);
      // Successfully Created
      Packet.WriteStr(#$C5#$00);
      Packet.WriteUInt8(1);
      Packet.WriteUInt32(RemoveItemData.ItemTypeID);
      Packet.WriteUInt32(1);
      Packet.WriteUInt32(RemoveItemData.ItemIndex);
      PL.Send(Packet);

      Packet.Clear;
      Packet.WriteStr(#$B5#$01);
      Packet.WriteUInt32(1); // Status Successfully
      PL.Send(Packet);

      PL.SendGuildData;
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerRequestGuildData(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  GuildIndex: UInt32;
begin
  if not ClientPacket.ReadUInt32(GuildIndex) then Exit;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcGuildGetPlayerData] @UID = :UID, @GUILDID = :GID', [PL.GetUID, GuildIndex]);

    if Query.RecordCount <= 0 then
    begin
      PL.Send(#$B8#$01#$E4#$D4#$00#$00);
      Exit;
    end;

    Packet.WriteStr(#$B8#$01);
    Packet.WriteUInt32(1);
    Packet.WriteUInt32(Query.FieldByName('GUILD_INDEX').AsInteger);
    Packet.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, 20);
    Packet.WriteStr(#$00, 9);
    Packet.WriteUInt32(Query.FieldByName('GUILD_TOTAL_MEMBER').AsInteger);
    Packet.WriteStr(Query.FieldByName('GUILD_IMAGE').AsAnsiString, 9);
    Packet.WriteStr(#$00, 3);
    Packet.WriteStr(Query.FieldByName('GUILD_NOTICE').AsAnsiString, $65);
    Packet.WriteStr(Query.FieldByName('GUILD_INTRODUCING').AsAnsiString, 101);
    Packet.WriteUInt32(Query.FieldByName('GUILD_POSITION').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('GUILD_LEADER_UID').AsInteger);
    Packet.WriteStr(Query.FieldByName('GUILD_LEADER_NICKNAME').AsAnsiString, 22);
    Packet.WriteStr(GetFixTime(Query.FieldByName('GUILD_CREATE_DATE').AsDateTime));

    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGetGuildPlayer(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TGetGuildPlayer = packed record
    var GuildID: UInt32;
    var Page: UInt32;
  end;
var
  GuildPlayerData: TGetGuildPlayer;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
const
  PackedID: TChar = #$C6#$01;
begin
  if not ClientPacket.Read(GuildPlayerData, SizeOf(TGetGuildPlayer)) then Exit;

  CreateQuery(Query, Con, False);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcGuildGetData] @GUILDID = :GID, @PAGE = :PAGE', [GuildPlayerData.GuildID, GuildPlayerData.Page]);

    Packet.WriteStr(PackedID);
    Packet.WriteUInt32(1);
    Packet.WriteUInt32(GuildPlayerData.Page);
    Packet.WriteUInt32(Query.FieldByName('GUILD_TOTAL_MEMBER').AsInteger);

    QueryNextSet(Query);

    Packet.WriteUInt16(Query.RecordCount);

    while not Query.Eof do
    begin
      Packet.WriteUInt32(Query.FieldByName('GUILD_ID').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('GUILD_MEMBER_UID').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('GUILD_POSITION').AsInteger);
      Packet.WriteStr(Query.FieldByName('GUILD_MESSAGE').AsAnsiString, 25);
      Packet.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, 21);
      Packet.WriteStr(Query.FieldByName('PLAYER_NICKNAME').AsAnsiString, 22);
      Packet.WriteUInt8(Query.FieldByName('Logon').AsInteger);

      Query.Next;
    end;

    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGetGuildLog(const PL: TClientPlayer);
var
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
begin
  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcGuildGetLog] @UID = :UID', [PL.GetUID]);

    Packet.WriteStr(#$BE#$01);
    Packet.WriteUInt32(1);
    Packet.WriteUInt16(Query.RecordCount);

    while not Query.Eof do
    begin
      Packet.WriteStr(#$FF#$FF#$FF#$FF);
      Packet.WriteUInt32(Query.FieldByName('GUILD_ID').AsInteger);
      Packet.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, $15);
      Packet.WriteUInt32(Query.FieldByName('GUILD_ACTION').AsInteger);
      Packet.WriteStr(GetFixTime(Query.FieldByName('GUILD_ACTION_DATE').AsDateTime));

      Query.Next;
    end;

    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerJoinGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
const
  PacketID: TChar = #$C0#$01;
type
  TGuildJoin = packed record
    var GuildID: UInt32;
    var GuildIntro: AnsiString;
  end;
var
  GuildJoin: TGuildJoin;
  Query: TFDQuery;
  Con: TFDConnection;
  function Check(GuildData: TPlayerGuildData): Boolean;
  begin
    Exit(GuildData.GuildID = 0);
  end;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
begin
  if not ClientPacket.ReadUInt32(GuildJoin.GuildID) then Exit;
  if not ClientPacket.ReadPStr(GuildJoin.GuildIntro) then Exit;

  if not Check(PL.GuildData) then
  begin
    SendCode(GUILD_ALREADY_REGISTER);
    Exit;
  end;

  CreateQuery(Query, Con);
  try
    Query.Open('EXEC [dbo].[USP_GUILD_JOIN] @UID = :UID, @GUILDID = :GUID, @INTRO = :INTRO', [PL.GetUID, GuildJoin.GuildID, GuildJoin.GuildIntro]);

    if (Query.FieldByName('CODE').AsInteger = 2) then
    begin
      PL.Send(#$C0#$01#$00#$00#$00#$00);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 10) then
    begin
      SendCode(GUILD_WAIT_24);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 9) then
    begin
      SendCode(GUILD_NOT_FOUND);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 8) then
    begin
      SendCode(GUILD_ALREADY_REGISTER);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      PL.Send(#$C0#$01#$01#$00#$00#$00);
      PL.SendGuildData;
    end;
  finally
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerCancelJoinGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
const
  PacketID: TChar = #$C1#$01;
var
  GuildID: UInt32;
  Query: TFDQuery;
  Con: TFDConnection;
  function Check(GuildData: TPlayerGuildData): Boolean;
  begin
    Exit(GuildData.GuildID > 0);
  end;
  procedure SendError;
  begin
    PL.Send(#$C1#$01#$00#$00#$00#$00);
  end;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
begin
  if not ClientPacket.ReadUInt32(GuildID) then Exit;

  if not Check(PL.GuildData) then
  begin
    SendError;
    Exit;
  end;

  CreateQuery(Query, Con);
  try
    Query.Open('EXEC [dbo].[USP_GUILD_CANCELJOIN] @UID = :UID, @GUILDID = :GUID', [PL.GetUID, GuildID]);

    // Error in transaction
    if (Query.FieldByName('CODE').AsInteger = 2) then
    begin
      SendError;
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 10) then
    begin
      SendCode(GUILD_NOT_WAIT_FOR_ACCEPT);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 9) then
    begin
      SendCode(GUILD_NOT_FOUND);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 8) then
    begin
      SendCode(GUILD_NOT_WAIT_FOR_ACCEPT);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      PL.Send(PacketID + #$01#$00#$00#$00);
      PL.SendGuildData;
    end;
  finally
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerGuildAccept(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TAccept = packed record
    var GuildID: UInt32;
    var UID: UInt32;
  end;
var
  AcceptData: TAccept;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(#$C2#$01 + Code);
  end;
begin
  if not ClientPacket.Read(AcceptData, SizeOf(TAccept)) then
  begin
    Exit;
  end;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_ACTION] @UID = :UID, @GUILDID = :GUID, @GUILDACTION = 1, @GUILDVALUE = :GVAL', [PL.GetUID, AcceptData.GuildID, AcceptData.UID]);

    if (Query.FieldByName('CODE').AsInteger = 1) then
    begin
      SendCode(GUILD_NOT_WAIT_FOR_ACCEPT);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 2) then
    begin
      SendCode(GUILD_NOT_ADMIN);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      PL.Send(#$C2#$01#$01#$00#$00#$00);

      Packet.WriteStr(#$D1#$01);
      Packet.WriteUInt32(42);
      Packet.WriteUInt32(AcceptData.UID);
      PL.Send(Packet);

      SendUpdateGuild(PL, AcceptData.UID);
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGuildKick(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TKick = packed record
    var GuildID: UInt32;
    var UID: UInt32;
  end;
var
  KickPlayer: TKick;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(#$C8#$01 + Code);
  end;
begin
  if not ClientPacket.Read(KickPlayer, SizeOf(TKick)) then Exit;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_ACTION] @UID = :UID, @GUILDID = :GUID, @GUILDACTION = 2, @GUILDVALUE = :GVAL', [PL.GetUID, KickPlayer.GuildID, KickPlayer.UID]);

    if (Query.FieldByName('CODE').AsInteger = 1) then
    begin
      SendCode(#$00#$00#$00#$00);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 2) then
    begin
      SendCode(GUILD_NOT_ADMIN);
      raise Exception.Create('HandlePlayerGuildKick: Player want to kick his guild member but he is not an admin');
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      PL.Send(#$C8#$01#$01#$00#$00#$00);

      Packet.WriteStr(#$D1#$01);
      Packet.WriteUInt32(43);
      Packet.WriteUInt32(KickPlayer.UID);
      PL.Send(Packet);

      SendUpdateGuild(PL, KickPlayer.UID);
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGuildPromote(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TPromote = packed record
    var GuildID: UInt32;
    var UID: UInt32;
    var Position: UInt32
  end;
var
  PromoteData: TPromote;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(#$C4#$01 + Code);
  end;
begin
  if not ClientPacket.Read(PromoteData, SizeOf(TPromote)) then
  begin
    Exit;
  end;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_ACTION] @UID = :UID, @GUILDID = :GUID, @GUILDACTION = 3, @GUILDVALUE = :GVAL, @GUILDVALUE2 = :GVAL2', [PL.GetUID, PromoteData.GuildID, PromoteData.UID, PromoteData.Position]);

    if ( Query.FieldByName('CODE').AsInteger in [8,10] ) then
    begin
      SendCode(#$00#$00#$00#$00);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 9) then
    begin
      SendCode(GUILD_NOT_ADMIN);
      raise Exception.Create('HandlePlayerGuildPromote: Player want to promote his guild member but he is not an admin');
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      Packet.WriteStr(#$C4#$01);
      Packet.WriteUInt32(1);
      Packet.WriteUInt32(PromoteData.Position);
      PL.Send(Packet);

      SendUpdateGuild(PL, PromoteData.UID);
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerChangeGuildIntro(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TChangeIntro = packed record
    var GuildID: UInt32;
    var UID: UInt32;
    var IntroMsg: AnsiString;
  end;
var
  IntroData: TChangeIntro;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(#$BA#$01 + Code);
  end;
begin
  if not ClientPacket.ReadUInt32(IntroData.GuildID) then Exit;
  if not ClientPacket.ReadUInt32(IntroData.UID) then Exit;
  if not ClientPacket.ReadPStr(IntroData.IntroMsg) then Exit;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_ACTION] @UID = :UID, @GUILDID = :GUID, @GUILDACTION = 4, @GUILDVALUE3 = :INTRO', [PL.GetUID, IntroData.GuildID, IntroData.IntroMsg]);

    if ( Query.FieldByName('CODE').AsInteger = 8 ) then
    begin
      SendCode(#$00#$00#$00#$00);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 9) then
    begin
      SendCode(GUILD_NOT_ADMIN);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      Packet.WriteStr(#$BA#$01);
      Packet.WriteUInt32(1);
      PL.Send(Packet);
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerChangeGuildNotice(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TChangeNotice = packed record
    var GuildID: UInt32;
    var UID: UInt32;
    var IntroMsg: AnsiString;
  end;
var
  NoticeData: TChangeNotice;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(#$B9#$01 + Code);
  end;
begin
  if not ClientPacket.ReadUInt32(NoticeData.GuildID) then Exit;
  if not ClientPacket.ReadUInt32(NoticeData.UID) then Exit;
  if not ClientPacket.ReadPStr(NoticeData.IntroMsg) then Exit;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_ACTION] @UID = :UID, @GUILDID = :GUID, @GUILDACTION = 5, @GUILDVALUE3 = :INTRO', [PL.GetUID, NoticeData.GuildID, NoticeData.IntroMsg]);

    if ( Query.FieldByName('CODE').AsInteger = 8 ) then
    begin
      SendCode(#$00#$00#$00#$00);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 9) then
    begin
      SendCode(GUILD_NOT_ADMIN);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      Packet.WriteStr(#$B9#$01);
      Packet.WriteUInt32(1);
      PL.Send(Packet);
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerChangeGuildSelfIntro(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TSelfIntro = packed record
    var GuildID: UInt32;
    var UID: UInt32;
    var SelfIntro: AnsiString;
  end;
var
  SelfIntro: TSelfIntro;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(#$C5#$01 + Code);
  end;
begin
  if not ClientPacket.ReadUInt32(SelfIntro.GuildID) then Exit;
  if not ClientPacket.ReadUInt32(SelfIntro.UID) then Exit;
  if not ClientPacket.ReadPStr(SelfIntro.SelfIntro) then Exit;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_ACTION] @UID = :UID, @GUILDID = :GUID, @GUILDACTION = 6, @GUILDVALUE = :TOUID, @GUILDVALUE3 = :GMSG', [PL.GetUID, SelfIntro.GuildID, SelfIntro.UID, SelfIntro.SelfIntro]);

    if ( Query.FieldByName('CODE').AsInteger = 8 ) then
    begin
      SendCode(#$00#$00#$00#$00);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      Packet.WriteStr(#$C5#$01);
      Packet.WriteUInt32(1);
      PL.Send(Packet);
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerLeaveGuild(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  GuildID: UInt32;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(#$C7#$01 + Code);
  end;
begin
  if not ClientPacket.ReadUInt32(GuildID) then Exit;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_ACTION] @UID = :UID, @GUILDID = :GUID, @GUILDACTION = 7', [PL.GetUID, GuildID]);

    if ( Query.FieldByName('CODE').AsInteger = 8 ) then
    begin
      SendCode(#$00#$00#$00#$00);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      SendCode(#$01#$00#$00#$00);

      Packet.Clear;
      Packet.WriteStr(#$D1#$01);
      Packet.WriteUInt32($2B);
      Packet.WriteUInt32(PL.GetUID);
      PL.Send(Packet);

      PL.SendGuildData;
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGuildCallUpload(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  GuildID: UInt32;
  Packet: TClientPacket;
  Query: TFDQuery;
  Con: TFDConnection;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(#$C9#$01 + Code);
  end;
begin
  if not ClientPacket.ReadUInt32(GuildID) then Exit;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[USP_GUILD_EMBLEM] @UID = :UID, @GUILDID = :GUID', [PL.GetUID, GuildID]);

    if not PL.Inventory.IsExist(436207920) then
    begin
      SendCode(#$E6#$D4#$00#$00);
      Exit;
    end;

    if ( Query.FieldByName('CODE').AsInteger = 2 ) then
    begin
      SendCode(#$00#$00#$00#$00);
      Exit;
    end;

    if (Query.FieldByName('CODE').AsInteger = 1) then
    begin
      Packet.WriteStr(#$C9#$01);
      Packet.WriteUInt32(1);
      Packet.WriteUInt32( Query.FieldByName('EMBLEM_IDX').AsInteger );
      Packet.WritePStr( Query.FieldByName('GUILD_MARK_IMG').AsAnsiString );
      PL.Send(Packet);
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGuildAfterUpload(const PL: TClientPlayer);
var
  RemoveItem: TAddData;
  Packet: TClientPacket;
begin
  RemoveItem := PL.Inventory.Remove(436207920, 1, False);
  if not RemoveItem.Status then
  begin
    PL.Send(#$CA#$01#$E6#$D4#$00#$00);
    raise Exception.Create('HandlePlayerGuildAfterUpload: Player has requested for image guild upload but their item cannot be deleted.');
  end;

  PL.Send(#$CA#$01#$01#$00#$00#$00);

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$C5#$00);
    Packet.WriteUInt8(1);
    Packet.WriteUInt32(RemoveItem.ItemTypeID);
    Packet.WriteUInt32(1);
    Packet.WriteUInt32(RemoveItem.ItemIndex);
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure SendUpdateGuild(const PL: TClientPlayer; UID: UInt32);
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$05#$00);
    Packet.WriteUInt32(UID);
    AuthController.Send(Packet.ToStr);
  finally
    FreeAndNil(Packet);
  end;
end;

end.
