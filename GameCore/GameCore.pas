unit GameCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  ClientPacket, PangyaClient, Tools, System.SysUtils, ItemData,
  Lobby, GameBase, uCharacter, uItemSlot, uFurniture,
  MyList, Enum, System.Generics.Collections, IffMain,
  uWarehouse, AuthClient, PacketCreator, Defines;

procedure PlayerSaveMacro(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerChangeServer(const PL: TClientPlayer);
procedure PlayerControlAssist(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerSaveBar(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerChangeEquipment(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerWhispering(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGetTime(const PL: TClientPlayer);
procedure GMSendNotice(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGetPlayerInfo(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerChangeMascotMessage(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerEnterPersonalRoom(const PL: TClientPlayer);
procedure PlayerEnterPersonalRoomGetCharData(const PL: TClientPlayer);
procedure PlayerGetMatchHistory(const PL: TClientPlayer);

procedure PlayerUpgradeStatus(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerDowngradeStatus(const PL: TClientPlayer; const ClientPacket: TClientPacket);

procedure PlayerGetPlayerData(const PL: TClientPlayer; const ClientPacket: TClientPacket);

procedure PlayerDailyLoginCheck(const PL: TClientPlayer);
procedure PlayerDailyLoginItem(const PL: TClientPlayer);

procedure PlayerCheckNoticeCookie(const PL: TClientPlayer);
procedure PlayerSendTopNotice(const PL: TClientPlayer; const ClientPacket: TClientPacket);

procedure PlayerGetCutinData(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGetAchievement(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure SendAchievement(const PL: TClientPlayer;
  const Achievements: TMyList<PAchievement>;
  const Quests: TMyList<PAchievementQuest>;
  const Counters: TDictionary<UInt32, PAchievementCounter>);

implementation

uses
  MainServer;

procedure PlayerSaveMacro(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  MacroData: array[$0..$7] of AnsiString;
  Query: TFDQuery;
  Con: TFDConnection;
begin

  if not ClientPacket.ReadStr(MacroData[0], $40) then Exit;
  if not ClientPacket.ReadStr(MacroData[1], $40) then Exit;
  if not ClientPacket.ReadStr(MacroData[2], $40) then Exit;
  if not ClientPacket.ReadStr(MacroData[3], $40) then Exit;
  if not ClientPacket.ReadStr(MacroData[4], $40) then Exit;
  if not ClientPacket.ReadStr(MacroData[5], $40) then Exit;
  if not ClientPacket.ReadStr(MacroData[6], $40) then Exit;
  if not ClientPacket.ReadStr(MacroData[7], $40) then Exit;

  CreateQuery(Query, Con);
  try
    Query.SQL.Add('EXEC [dbo].[ProcSaveMacro]');
    Query.SQL.Add('@UID = :UID,');
    Query.SQL.Add('@Macro1 = :M1,');
    Query.SQL.Add('@Macro2 = :M2,');
    Query.SQL.Add('@Macro3 = :M3,');
    Query.SQL.Add('@Macro4 = :M4,');
    Query.SQL.Add('@Macro5 = :M5,');
    Query.SQL.Add('@Macro6 = :M6,');
    Query.SQL.Add('@Macro7 = :M7,');
    Query.SQL.Add('@Macro8 = :M8');
    Query.ParamByName('UID').AsInteger := PL.GetUID;
    Query.ParamByName('M1').AsAnsiString := Trim(MacroData[0]);
    Query.ParamByName('M2').AsAnsiString := Trim(MacroData[1]);
    Query.ParamByName('M3').AsAnsiString := Trim(MacroData[2]);
    Query.ParamByName('M4').AsAnsiString := Trim(MacroData[3]);
    Query.ParamByName('M5').AsAnsiString := Trim(MacroData[4]);
    Query.ParamByName('M6').AsAnsiString := Trim(MacroData[5]);
    Query.ParamByName('M7').AsAnsiString := Trim(MacroData[6]);
    Query.ParamByName('M8').AsAnsiString := Trim(MacroData[7]);
    Query.ExecSQL;
  finally
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerChangeServer(const PL: TClientPlayer);
var
  Reply : TClientPacket;
  Query: TFDQuery;
  Con: TFDConnection;
begin
  CreateQuery(Query, Con);
  Reply := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcUpdateAuth] @UID = :UID', [PL.GetUID]);

    Reply.WriteStr(#$D4#$01#$00#$00#$00#$00);
    Reply.WritePStr(Query.FieldByName('KEY_GAME').AsAnsiString);

    PL.Send(Reply);
  finally
    FreeAndNil(Reply);
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerControlAssist(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  AssistItem: UInt32;
  Item: TAddItem;
begin
  AssistItem := 467664918;

  case PL.Inventory.GetQuantity(AssistItem) of
    1: // TO CLOSE {plus item 1]
      begin
        with Item do
        begin
          ItemIffId := AssistItem;
          Quantity := 1;
          Transaction := True;
          Day := 0;
        end;
        PL.AddItem(Item);
        PL.Assist := $0;
      end;
    2: // TO OPEN {minus item 1}
      begin
        PL.Inventory.Remove(AssistItem, 1, True);
        PL.Assist := $1;
      end;
  else
    Exit;
  end;

  PL.SendTransaction;
  PL.Send(#$6A#$02#$00#$00#$00#$00);
end;

procedure PlayerSaveBar(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  THeader = packed record
    Action: UInt8;
    Id: UInt32;
  end;
var
  Header: THeader;
  Packet: TClientPacket;
  PLobby: TLobby;
  GameHandle: TGameBase;
begin
  // 0C 00 07 61 B4 8C 00 CF 9C 44 00 1C 2B 9D 42 00 00 00 14
  // Character ID, CaddieID, ClubID, BallTYPEID
  if not ClientPacket.ReadUInt8(Header.Action) then Exit;
  if not ClientPacket.ReadUInt32(Header.Id) then Exit;

  PLobby := TLobby(PL.Lobby);
  GameHandle := PLobby.GameHandle[PL];

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$4B#$00);
    Packet.WriteUInt32(0);
    Packet.WRiteUInt8(Header.Action);
    Packet.WriteUInt32(PL.ConnectionID);

    case Header.Action of
      3: // ## club
        begin
          if not PL.Inventory.SetClubIndex(Header.Id) then
          begin
            PL.Disconnect;
            Exit;
          end;
          Packet.WriteStr(PL.Inventory.GetClubData);
        end;
      1: // ## caddie
        begin
          if not PL.Inventory.SetCaddieIndex(Header.Id) then
          begin
            PL.Disconnect;
            Exit;
          end;
          Packet.WriteStr(PL.Inventory.GetCaddieData);
        end;
      4: // ## char
        begin
          if not PL.Inventory.SetCharIndex(Header.Id) then
          begin
            PL.Disconnect;
            Exit;
          end;
          Packet.WriteStr(PL.Inventory.GetCharData);
        end;
      5: // ## mascot
        begin
          if not PL.Inventory.SetMascotIndex(Header.Id) then
          begin
            PL.Disconnect;
            Exit;
          end;
          Packet.WriteStr(PL.Inventory.GetMascotData);
        end;
      7: // ## start game
        begin
          if GameHandle = nil then Exit;
          GameHandle.AcquireData(PL);
        end
    else
      begin
        Exit;
      end;
    end;

    if (Header.Action = 4) and (not (GameHandle = nil)) then // ## header = character
    begin
      GameHandle.Send(Packet); // ## send to game
      Packet.Clear;
      Packet.WriteStr(#$48#$00 + #$03 + #$FF#$FF);
      Packet.WriteStr(PL.GetGameInfomations(0) + PL.GetGameInfomations(1));

      GameHandle.Send(Packet);
    end else
    begin
      PL.Send(Packet); // ## send to self
    end;
  finally
    Packet.Free;
  end;
end;

procedure PlayerChangeEquipment(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TClubBallInfo = packed record
    var BallTypeID: UInt32;
    var ClubIndex: UInt32;
  end;
var
  Action: UInt8;
  Packet: TClientPacket;
  CharTypeId, CharIdx, CaddieIdx, MascotIdx, ClubIndex, BallTypeID: UInt32;
  Status: Boolean;
  ItemSlots: TItemsSlot;
  Character: PCharacter;
  //ClubBallInfo: TClubBallInfo;
begin
  if not ClientPacket.ReadUInt8(Action) then Exit;
  Status := False;
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$6B#$00#$04);
    Packet.WriteUInt8(Action);

    case Action of
      0:  // ## save char equip
        begin
          if not ClientPacket.ReadUInt32(CharTypeId) then Exit;
          Character := PL.Inventory.GetCharacter(CharTypeId);

          if (Character = nil) then
          begin
            Exit;
          end;

          ClientPacket.Skip(8);
          if not ClientPacket.Read(Character.EquipTypeID, SizeOf(Character.EquipTypeID)) then Exit;
          if not ClientPacket.Read(Character.EquipIndex, SizeOf(Character.EquipIndex)) then Exit;
          ClientPacket.Skip(236);
          if not ClientPacket.ReadUInt32(Character.FCutinIndex) then Exit;

          Character.NEEDUPDATE := True; // update to database when player logout
          Status := True;
          Packet.WriteStr(PL.Inventory.ItemCharacter.GetCharData(Character.Index));
        end;
      1:  // ## change caddie
        begin
          if not ClientPacket.ReadUInt32(CaddieIdx) then Exit;
          if not PL.Inventory.SetCaddieIndex(CaddieIdx) then
          begin
            PL.Disconnect;
            Exit;
          end;
          Status := True;
          Packet.WriteUInt32(CaddieIdx);
        end;
      5:  // ## change char
        begin
          if not ClientPacket.ReadUInt32(CharIdx) then Exit;
          if not PL.Inventory.SetCharIndex(CharIdx) then
          begin
            PL.Disconnect;
            Exit;
          end;
          Status := True;
          Packet.WriteUInt32(CharIdx);
        end;
      2: // ## item for play
        begin
          if not ClientPacket.Read(ItemSlots, sizeOf(TItemsSlot)) then Exit;
          PL.Inventory.ItemSlot := ItemSlots;
          Status := True;
          Packet.WriteStr(PL.Inventory.ItemSlot.GetItemSlot);
        end;
      8: // ## change mascot
        begin
          if not ClientPacket.ReadUInt32(MascotIdx) then
            Exit;
          if not PL.Inventory.SetMascotIndex(MascotIdx) then
          begin
            PL.Disconnect;
            Exit;
          end;
          Status := True;
          Packet.WriteStr(PL.Inventory.GetMascotData);
        end;
      9:
        begin
          PL.Send(#$6B#$00#$04#$09#$D4#$07#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
          Exit;
        end;
      4:
        begin
          PL.Send(#$6B#$00#$04#$04#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$5E#$01#$80#$39);
          Exit;
        end;
      3:
        begin
          if not ClientPacket.ReadUInt32(BallTypeID) then Exit;
          if not ClientPacket.ReadUInt32(ClubIndex) then Exit;
          if not PL.Inventory.SetGolfEQP(BallTypeID, ClubIndex) then
          begin
            PL.Disconnect;
            Exit;
          end;
          Status := True;
          Packet.WriteStr(PL.Inventory.GetGolfEQP);
        end;
    end;

    if Status then
    begin
      PL.Send(Packet);
    end;
  finally
    FreeAndNil(Packet);
  end;
end;

procedure PlayerWhispering(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Nickname, Msg: AnsiString;
  Client: TClientPlayer;
  Packet: TClientPacket;
begin
  clientPacket.Skip(4);
  if not clientPacket.ReadPStr(Nickname) then Exit;
  if not clientPacket.ReadPStr(Msg) then Exit;

  Client := TGameServer(PL.GameServer).GetPlayerByNickname(Nickname);

  Packet := TClientPacket.Create;
  try
    if (Client = nil) then
    begin
      Packet.WriteStr(#$40#$00);
      Packet.WriteUInt8(5); // Status
      Packet.WritePStr(Nickname);
      PL.Send(Packet);
      Exit;
    end;

    if not Client.InLobby then
    begin
      Packet.WriteStr(#$40#$00);
      Packet.WriteUInt8(4); // Status
      Packet.WritePStr(Nickname);
      PL.Send(Packet);
      Exit;
    end;

    Packet.WriteStr(#$84#$00);
    Packet.WriteUInt8(1); // For Targeting
    Packet.WritePStr(PL.GetNickname);
    Packet.WritePStr(Msg);
    Client.Send(Packet);

    Packet.Clear;
    Packet.WriteStr(#$84#$00);
    Packet.WriteUInt8(0); // For Targeting
    Packet.WritePStr(Nickname);
    Packet.WritePStr(Msg);
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGetTime(const PL: TClientPlayer);
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$BA#$00);
    Packet.WriteStr(GameTime());
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure GMSendNotice(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Messages: AnsiString;
begin
  if not ClientPacket.ReadPStr(Messages) then Exit;
  TGameServer(PL.GameServer).HandleStaffSendNotice(PL.GetNickname, Messages);
end;

procedure PlayerGetPlayerInfo(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  UID : UInt32;
  Season: UInt8;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet : TClientPacket;
begin
  if not clientPacket.ReadUInt32(UID) then Exit;
  if not clientPacket.ReadUInt8(Season) then Exit;

  CreateQuery(Query, Con, False);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [DBO].ProcGet_UserInfo @UID = :UID', [UID]);

    if Query.RecordCount <= 0 then
    begin
      Packet.WriteStr(#$89#$00);
      Packet.WriteUInt32(2);
      Packet.WriteUInt8(Season);
      Packet.WriteUInt32(UID);
      PL.Send(Packet);
      raise Exception.CreateFmt('HandlePlayerRequestPlayerInfo: request client %d not found', [UID]);
    end;

    // ## basic user info
    Packet.WriteStr(#$57#$01);
    Packet.WriteUInt8(Season);
    Packet.WriteUInt32(Query.ParamByName('UID').AsInteger);
    Packet.WriteStr(#$FF#$FF);
    Packet.WriteStr(Query.FieldByName('Username').AsAnsiString, $16);
    Packet.WriteStr(Query.FieldByName('Nickname').AsAnsiString, $16);
    Packet.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, $15);
    Packet.WriteStr(Query.FieldByName('GUILD_IMAGE').AsAnsiString, $9);
    Packet.WriteStr(#$00, $1F);
    Packet.WriteUInt32(Query.FieldByName('GUILDINDEX').AsInteger);
    Packet.WriteUInt32(0);
    Packet.WriteUInt16($80); // ## SEX
    Packet.WriteStr(#$FF#$FF#$FF#$FF#$FF#$FF);
    Packet.WriteStr(#$00, $10);
    Packet.WriteStr(Query.FieldByName('Username').AsAnsiString + '@NT', $12);
    Packet.WriteStr(#$00, $6E);
    Packet.WriteUInt32(Query.ParamByName('UID').AsInteger);
    Packet.WriteStr(#$00, 4);
    PL.Send(Packet);

    // ## character data
    Query.NextRecordSet;
    Query.FetchAll;
    Packet.Clear;
    Packet.WriteStr(#$5E#$01);
    Packet.WriteUInt32(UID);
    Packet.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('CID').AsInteger);
    Packet.WriteUInt16(Query.FieldByName('HAIR_COLOR').AsInteger);
    Packet.WriteUInt16(Query.FieldByName('GIFT_FLAG').AsInteger);
    // ## ITEM TYPEID
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_1').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_2').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_3').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_4').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_5').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_6').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_7').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_8').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_9').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_10').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_11').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_12').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_13').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_14').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_15').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_16').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_17').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_18').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_19').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_20').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_21').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_22').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_23').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_TYPEID_24').AsInteger);
    // ## ITEM INDEX
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_1').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_2').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_3').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_4').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_5').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_6').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_7').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_8').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_9').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_10').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_11').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_12').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_13').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_14').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_15').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_16').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_17').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_18').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_19').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_20').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_21').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_22').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_23').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('PART_IDX_24').AsInteger);
    Packet.WriteStr(#$00, $D8);
    Packet.WriteUInt32(0); // Right Ring
    Packet.WriteUInt32(0); // Left Ring
    Packet.WriteUInt32(0); // Unknown Yet
    Packet.WriteUInt32(0); // Unknown Yet
    Packet.WriteUInt32(0); // Unknown Yet
    Packet.WriteUInt32(Query.FieldByName('CUTIN').AsInteger);
    // Unknown Yet -- MAY BE CUTIN
    Packet.WriteUInt32(0); // Unknown Yet
    Packet.WriteUInt32(0); // Unknown Yet
    Packet.WriteUInt32(0); // Unknown Yet
    Packet.WriteUInt8(Query.FieldByName('POWER').AsInteger);
    Packet.WriteUInt8(Query.FieldByName('CONTROL').AsInteger);
    Packet.WriteUInt8(Query.FieldByName('IMPACT').AsInteger);
    Packet.WriteUInt8(Query.FieldByName('SPIN').AsInteger);
    Packet.WriteUInt8(Query.FieldByName('CURVE').AsInteger);
    Packet.WriteUInt8(0); // Slot Mastery
    Packet.WriteStr(#$00, $33);
    PL.Send(Packet);

    // ## result
    Packet.Clear;
    Packet.WriteStr(#$89#$00);
    Packet.WriteUInt32(1);
    Packet.WriteUInt8(Season);
    Packet.WriteUInt32(UID);
    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerChangeMascotMessage(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  MASCOT_IDX: UInt32;
  MASCOT_MSG: AnsiString;
  Packet: TClientPacket;
begin
  if not ClientPacket.ReadUInt32(MASCOT_IDX) then Exit;
  if not ClientPacket.ReadPStr(MASCOT_MSG) then Exit;

  Packet := TClientPacket.Create;
  try
    if not PL.Inventory.SetMascotText(MASCOT_IDX, MASCOT_MSG) then
    begin
      PL.Send(#$E2#$00#$01);
      Exit;
    end;

    Packet.WriteStr(#$E2#$00);
    Packet.WriteStr(#$04); // STATUS
    Packet.WriteUInt32(MASCOT_IDX);
    Packet.WritePStr(MASCOT_MSG);
    Packet.WriteUInt32(PL.GetPang);
    Packet.WriteUInt32(0);
    // SEND
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure PlayerEnterPersonalRoom(const PL: TClientPlayer);
var
  Packet : TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$2B#$01#$01#$00#$00#$00);
    Packet.WriteUInt32(PL.GetUID);
    Packet.WriteUInt32(1);
    Packet.WriteStr(#$00, $63);
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure PlayerEnterPersonalRoomGetCharData(const PL: TClientPlayer);
var
  Packet : TClientPacket;
  Furniture: PFurniture;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$68#$01);
    Packet.WriteStr(PL.GetGameInfomations(2));
    PL.Send(Packet);

    // ## ROOM DATA/ FURNITURE LIST
    Packet.Clear;
    Packet.WriteStr(#$2D#$01);
    Packet.WriteUInt32(1);
    Packet.WriteUInt16(PL.Inventory.ItemRoom.Count);

    for Furniture in PL.Inventory.ItemRoom do
    begin
      Packet.WriteUInt32(Furniture.Index);
      Packet.WriteUInt32(Furniture.TypeID);
      Packet.WriteUInt16(0);
      Packet.WriteSingle(Furniture.PosX);
      Packet.WriteSingle(Furniture.PosY);
      Packet.WriteSingle(Furniture.PosZ);
      Packet.WriteSingle(Furniture.PosR);
      Packet.WriteUInt8(0);
    end;
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGetAchievement(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  UID: UInt32;

  Query: TFDQuery;
  Con: TFDConnection;
  Achievement: PAchievement;
  Counter: PAchievementCounter;
  Quest: PAchievementQuest;
  Achievements: TMyList<PAchievement>;
  AchievementQuests: TMyList<PAchievementQuest>;
  AchievementCounters: TDictionary<UInt32, PAchievementCounter>;
begin
  if not ClientPacket.ReadUInt32(UID) then Exit;

  if (UID = PL.GetUID) then
  begin
    SendAchievement(PL, PL.Achievements, PL.AchievementQuests, PL.AchievemetCounters);
  end else begin
    CreateQuery(Query, Con, False);
    Achievements := TMyList<PAchievement>.Create;
    AchievementQuests := TMyList<PAchievementQuest>.Create;
    AchievementCounters := TDictionary<UInt32, PAchievementCounter>.Create;
    try
      Query.Open('EXEC [dbo].[ProcGetAchievement] @UID = :UID',[UID]);

      while not Query.Eof do
      begin
        New(Achievement);
        Achievement.Id := Query.FieldByName('ID').AsInteger;
        Achievement.TypeID := Query.FieldByName('TypeID').AsInteger;
        Achievements.Add(Achievement);
        Query.Next;
      end;

      Query.NextRecordSet;
      Query.FetchAll;

      while not Query.Eof do
      begin
        New(Counter);
        Counter.Id := Query.FieldByName('ID').AsInteger;
        Counter.TypeID := Query.FieldByName('TypeID').AsInteger;
        Counter.Quantity := Query.FieldByName('Quantity').AsInteger;
        AchievementCounters.Add(Counter.Id, Counter);
        Query.Next;
      end;

      Query.NextRecordSet;
      Query.FetchAll;

      while not Query.Eof do
      begin
        New(Quest);
        Quest.Id := Query.FieldByName('ID').AsInteger;
        Quest.AchievementIndex := Query.FieldByName('Achievement_Index').AsInteger;
        Quest.AchievementTypeID := Query.FieldByName('Achivement_Quest_TypeID').AsInteger;
        Quest.CounterIndex := Query.FieldByName('Counter_Index').AsInteger;
        Quest.SuccessDate := Query.FieldByName('SuccessDate').AsInteger;
        Quest.Total := Query.FieldByName('Count').AsInteger;

        AchievementQuests.Add(Quest);

        Query.Next;
      end;

      SendAchievement(PL, Achievements, AchievementQuests, AchievementCounters);
    finally
      for Achievement in Achievements do
        Dispose(Achievement);

      Achievements.Clear;

      for Counter in AchievementCounters.Values do
        Dispose(Counter);

      AchievementCounters.Clear;

      for Quest in AchievementQuests do
        Dispose(Quest);

      AchievementQuests.Clear;

      FreeAndNil(Achievements);
      FreeAndNil(AchievementQuests);
      FreeAndNil(AchievementCounters);
      FreeQuery(Query, Con);
    end;
  end;
end;

procedure SendAchievement(const PL: TClientPlayer;
  const Achievements: TMyList<PAchievement>;
  const Quests: TMyList<PAchievementQuest>;
  const Counters: TDictionary<UInt32, PAchievementCounter>);
var
  Packet, Packet2: TClientPacket;
  Achievement: PAchievement;
  Quest: PAchievementQuest;
  Counter: PAchievementCounter;
  Count: UInt32;
  CounterQty: UInt32;
begin
    Packet := TClientPacket.Create;
    Packet2 := TClientPacket.Create;
    try
      Packet.WriteStr(#$2D#$02);
      Packet.WriteUInt32(0);
      Packet.WriteUInt32(Achievements.Count);
      Packet.WriteUInt32(Achievements.Count);

      for Achievement in Achievements do
      begin
        Packet.WriteUInt32(Achievement.TypeID);
        Packet.WriteUInt32(Achievement.Id);

        Count := 0;
        Packet2.Clear;
        for Quest in Quests do
        begin
          if Achievement.Id = Quest.AchievementIndex then
          begin
            Inc(Count);

            if Counters.TryGetValue(Quest.CounterIndex, Counter) then
              CounterQty := Counter.Quantity
            else
              CounterQty := 0;

            Packet2.WriteUInt32(Quest.AchievementTypeID);
            Packet2.WriteUInt32(CounterQty);
            Packet2.WriteUInt32(Quest.SuccessDate);
          end;
        end;
        Packet.WriteUInt32(Count);
        Packet.WriteStr(Packet2.ToStr);
      end;

      PL.Send(Packet);
      PL.Send(#$2C#$02#$00#$00#$00#$00);
    finally
      FreeAndNil(Packet);
      FreeAndNil(Packet2);
    end;
end;

procedure PlayerGetCutinData(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TCutin = packed record
    var UID: UInt32;
    var Unknown1: UInt32;
    var Unknown2: UInt16;
    var TypeID: UInt32;
    var CutinType: UInt8;
  end;
var
  CutinData: TCutin;
  Char: PCharacter;
  Item: PItem;
begin
  if not ClientPacket.Read(CutinData, SizeOf(TCutin)) then Exit;

  case CutinData.CutinType of
    0:
      begin
        PL.Send(IffEntry.FCutin.GetCutinString(CutinData.TypeID));
      end;
    1:
      begin
        Char := PL.Inventory.GetCharacter(CutinData.TypeID);
        Item := PL.Inventory.ItemWarehouse.GetItem(Char.FCutinIndex);
        if (Item = nil) then Exit;
        PL.Send(IffEntry.FCutin.GetCutinString(Item.ItemTypeID));
      end;
  end;
end;

procedure PlayerGetMatchHistory(const PL: TClientPlayer);
var
  Packet: TClientPacket;
  Query: TFDQuery;
  Con: TFDConnection;
begin
  Packet := TClientPacket.Create;
  CreateQuery(Query, Con);
  try
    Query.Open('EXEC [DBO].ProcGetMatchHistory @UID = :UID', [PL.GetUID]);

    Packet.WriteZero($106);

    Packet.WriteStr(#$0E#$01);

    while not Query.Eof do
    begin
      Packet.WriteUInt32(Query.FieldByName('SEX').AsInteger);
      Packet.WriteStr(Query.FieldByName('NICKNAME').AsAnsiString ,$16);
      Packet.WriteStr(Query.FieldByName('USERID').AsAnsiString ,$16);
      Packet.WriteUInt32(Query.FieldByName('UID').AsInteger);

      Query.Next;
    end;

    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerGetPlayerData(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  IType: UInt8;
  Username: AnsiString;
  Query: TFDQuery;
  Con: TFDConnection;
  Reply: TClientPacket;
begin
  if not ClientPacket.ReadUInt8(IType) then
    Exit;

  case IType of
    1:
      begin
        if not ClientPacket.ReadPStr(Username) then Exit;
        Reply := TClientPacket.Create;
        CreateQuery(Query, Con);
        try
          Query.Open('EXEC [dbo].[ProcCheckUsername] @USERNAME = :USERID', [Username]);

          if not (Query.RecordCount > 0) then
          begin
            PL.Send(#$A1#$00#$02);
            Exit;
          end;

          Reply.WriteStr(#$A1#$00#$00);
          Reply.WriteUInt32(Query.FieldByName('UID').AsInteger);
          Reply.WriteStr(Query.FieldByName('Username').AsAnsiString, 16);
          Reply.WriteStr(#$00, 6);
          Reply.WriteStr(Query.FieldByName('Nickname').AsAnsiString, 16);
          Reply.WriteStr(#$00, 99);
          Reply.WriteStr(Query.FieldByName('Username').AsAnsiString + '@NT', 19);
          Reply.WriteStr(#$00, 109);
          Reply.WriteUInt32(Query.FieldByName('UID').AsInteger);
          // SEND
          PL.Send(Reply);

        finally
          FreeQuery(Query, Con);
          FreeAndNil(Reply);
        end;
      end;
  end;
end;

procedure PlayerDailyLoginCheck(const PL: TClientPlayer);
var
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
begin
    CreateQuery(Query, Con);
    Packet := TClientPacket.Create;
    try
      Query.Open('EXEC [dbo].[ProcAlterDaily] @UID = :UID',[PL.GetUID]);

      Packet.WriteStr(#$48#$02);
      Packet.WriteUInt32(0);
      Packet.WriteUInt8(Query.FieldByName('CODE').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('ItemTypeID').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('Quantity').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('ItemTypeIDTmr').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('ItemQuantityTmr').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('DailyCount').AsInteger);
      PL.Send(Packet);
    finally
      FreeQuery(Query, Con);
      FreeAndNil(Packet);
    end;
end;

procedure PlayerDailyLoginItem(const PL: TClientPlayer);
var
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
begin
  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcAlterDaily] @UID = :UID, @TYPE = 1', [PL.GetUID]);

    Packet.WriteStr(#$49#$02);
    Packet.WriteUInt32(0);
    // Packet.WriteUInt8(Query.FieldByName('CODE').AsInteger);
    Packet.WRiteUInt8(1);
    Packet.WriteUInt32(Query.FieldByName('ItemTypeID').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('Quantity').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('ItemTypeIDTmr').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('ItemQuantityTmr').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('DailyCount').AsInteger);

    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerSendTopNotice(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Msg: AnsiString;
begin
  if not ClientPacket.ReadPStr(Msg) then Exit;
  
  if not PL.RemoveCookie(500) then
  begin
    PL.Send(#$CB#$00#$00#$00#$00#$00#$00#$00);
    Exit;
  end;

  PL.SendCookies;
  AuthController.Write(ShowAuthNotice(PL.GetNickname, Msg));
end;

procedure PlayerCheckNoticeCookie(const PL: TClientPlayer);
begin
  if (PL.GetCookie >= 500) then
  begin
    PL.Send(#$CA#$00#$00#$00#$00#$00#$00#$00);
  end else begin
    PL.Send(#$CB#$00#$00#$00#$00#$00#$00#$00);
  end;
end;

procedure PlayerUpgradeStatus(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TData = packed record
    var Slot: UInt32;
    var CharTypeID: UInt32;
    var CharID: UInt32;
  end;
var
  Data: TData;
  CHAR: PCharacter;
  PangUpgrade: UInt32;
  Packet: TClientPacket;
begin
  if not ClientPacket.Read(Data, SizeOf(TData)) then Exit;

  CHAR := PL.Inventory.ItemCharacter.GetChar(Data.CharID, bIndex);

  if (CHAR = nil) or ( not (CHAR.TypeID = Data.CharTypeID) ) then Exit;

  PangUpgrade := CHAR.GetPangUpgrade(Data.Slot);

  if (PangUpgrade = 0) then
  begin
    PL.Send(#$6F#$02#$06#$00#$00#$00);
    Exit;
  end;

  if not PL.RemovePang(PangUpgrade) then
  begin
    PL.Send(#$6F#$02#$05#$00#$00#$00);
    Exit;
  end;

  if CHAR.UpgradeSlot(Data.Slot) then
  begin
    PL.SendPang;

    PL.Inventory.Transaction.AddCharStatus($C9, CHAR);
    PL.SendTransaction;

    Packet := TClientPacket.Create;
    try
      with Packet do
      begin
        WriteStr(#$6F#$02);
        WriteUInt32(0); // Success
        WriteUInt32(Data.Slot);
      end;
      PL.Send(Packet);
    finally
      Packet.Free;
    end;
  end;
end;

procedure PlayerDowngradeStatus(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TData = packed record
    var Slot: UInt32;
    var CharTypeID: UInt32;
    var CharID: UInt32;
  end;
var
  Data: TData;
  CHAR: PCharacter;
  Packet: TClientPacket;
begin
  if not ClientPacket.Read(Data, SizeOf(TData)) then Exit;

  CHAR := PL.Inventory.ItemCharacter.GetChar(Data.CharID, bIndex);

  if (CHAR = nil) or ( not (CHAR.TypeID = Data.CharTypeID) ) then Exit;

  if CHAR.DowngradeSlot(Data.Slot) then
  begin
    PL.Inventory.Transaction.AddCharStatus($C9, CHAR);
    PL.SendTransaction;

    Packet := TClientPacket.Create;
    try
      with Packet do
      begin
        WriteStr(#$70#$02);
        WriteUInt32(0); // Success
        WriteUInt32(Data.Slot);
      end;
      PL.Send(Packet);
    finally
      Packet.Free;
    end;
  end;
end;

end.
