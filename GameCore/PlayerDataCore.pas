unit PlayerDataCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  PangyaClient, ClientPacket, Enum, uItemSlot, Tools,
  uFurniture, uMascot, uCharacter, uCaddie, uWarehouse,
  uCard,
  JunkPacket, System.SysUtils, LobbyList, MailCore, UWriteConsole;

procedure PlayerRequestInfo(const PL: TClientPlayer);
procedure PlayerLogin(const PL: TClientPlayer; const clientPlayer: TClientPacket);

implementation

uses
  MainServer;

procedure PlayerLogin(const PL: TClientPlayer; const clientPlayer: TClientPacket);
var
  UserID, Code1, Code2, Version: AnsiString;
  UID: UInt32;
  Query: TFDQuery;
  Con: TFDConnection;
  Code: Byte;
  Client: TClientPlayer;
begin
  if not clientPlayer.ReadPStr(UserID) then Exit;
  if not clientPlayer.ReadUInt32(UID) then Exit;

  clientPlayer.Skip(6);

  if not clientPlayer.ReadPStr(Code1) then Exit;
  if not clientPlayer.ReadPStr(Version) then Exit;

  clientPlayer.Skip(8);

  if not clientPlayer.ReadPStr(Code2) then Exit;

  Client := TGameServer(PL.GameServer).GetPlayerByUID(UID);

  if not (Client = nil) then
  begin
    WriteConsole('[ERROR]: client <> nil');
    PL.Send(#$76#$02#$2D#$01#$00#$00); // ## send code 300
    PL.Disconnect;
    Exit;
  end;

  CreateQuery(Query, Con);
  try
    Query.Open('EXEC [dbo].[USP_GAME_LOGIN] @USERID = :USERID, @UID = :UID, @Code1 = :Code1, @Code2 = :Code2', [UserID, UID, Code1,Code2]);

    Code := Query.FieldByName('Code').AsInteger;

    if not (Code = 1) then
    begin
      WriteConsole('[ERROR]: code <> 1');
      PL.Send(#$76#$02#$2C#$01#$00#$00); // ## send code 300
      PL.Disconnect;
      Exit;
    end;

    PL.SetLogin(Query.FieldByName('Username').AsAnsiString);
    PL.SetNickname(Query.FieldByName('Nickname').AsAnsiString);
    PL.SetSex(Query.FieldByName('Sex').AsInteger);
    PL.SetCapabilities(Query.FieldByName('Capabilities').AsInteger);
    PL.SetUID(UID);

    PL.SetCookie(Query.FieldByName('Cookie').AsLongWord);
    PL.LockerPang := Query.FieldByName('PangLockerAmt').AsInteger;

    PL.LockerPwd := Query.FieldByName('LockerPwd').AsAnsiString;
    PL.SetAUTH_KEY_1(Code1);
    PL.SetAUTH_KEY_2(Code2);
  finally
    FreeQuery(Query, Con);
  end;

  if Code = 1 then
  begin
    PL.Verified := True;
    PlayerRequestInfo(PL);
  end;
end;

procedure PlayerRequestInfo(const PL: TClientPlayer);
var
  Reply: TClientPacket;
  Query: TFDQuery;
  Con: TFDConnection;
  CLUB_COUNT: Cardinal;
  ItemTypeData: Pointer;
  Index: UInt16;
  SlotData: TItemsSlot;
begin
  Reply := TClientPacket.Create;
  CreateQuery(Query, Con);
  try
    Query.FetchOptions.RowsetSize := 9999;

    Reply.WriteStr(#$44#$00#$D3#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$01#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$03#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$1C#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$1E#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$20#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$05#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$08#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$0B#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$10#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$12#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$1F#$01#$03#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$15#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$0E#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$14#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$16#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$18#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$1A#$00#$00#$00);
    PL.Send(Reply);
    Reply.Clear;

    Reply.WriteStr(#$44#$00#$D2#$22#$00#$00#$00);
    PL.Send(Reply);

    { get statistic }
    Query.Open('EXEC [dbo].[ProcGetStatistic] @UID = :UID', [PL.GetUID]);

    with PL.Statistic do
    begin
      Drive := Query.FieldByName('Drive').AsInteger;
      Putt := Query.FieldByName('Putt').AsInteger;
      PlayTime := Query.FieldByName('Playtime').AsInteger;
      ShotTime := Query.FieldByName('ShotTime').AsInteger;
      LongestDistance := Query.FieldByName('Longest').AsSingle;
      Pangya := Query.FieldByName('Pangya').AsInteger;
      TimeOut := Query.FieldByName('TimeOut').AsInteger;
      OB := Query.FieldByName('OB').AsInteger;
      DistanceTotal := Query.FieldByName('Distance').AsInteger;
      Hole := Query.FieldByName('Hole').AsInteger;
      TeamHole := Query.FieldByName('TeamHole').AsInteger;
      HIO := Query.FieldByName('Holeinone').AsInteger;
      Bunker := Query.FieldByName('Bunker').AsInteger;
      Fairway := Query.FieldByName('Fairway').AsInteger;
      Albratoss := Query.FieldByName('Albatross').AsInteger;
      Holein := Query.FieldByName('Holein').AsInteger;
      Puttin := Query.FieldByName('PuttIn').AsInteger;
      LongestPutt := Query.FieldByName('LongestPuttin').AsSingle;
      LongestChip := Query.FieldByName('LongestChipIn').AsSingle;
      EXP := Query.FieldByName('Game_Point').AsInteger;
      Level := Query.FieldByName('Game_Level').AsInteger;
      Pang := Query.FieldByName('Pang').AsInteger;
      TotalScore := Query.FieldByName('TotalScore').AsInteger;
      Score[0] := Query.FieldByName('BestScore0').AsInteger;
      Score[1] := Query.FieldByName('BestScore1').AsInteger;
      Score[2] := Query.FieldByName('BestScore2').AsInteger;
      Score[3] := Query.FieldByName('BestScore3').AsInteger;
      Score[4] := Query.FieldByName('BESTSCORE4').AsInteger;
      Unknown := 0;
      MaxPang0 := Query.FieldByName('MaxPang0').AsLargeInt;
      MaxPang1 := Query.FieldByName('MaxPang1').AsLargeInt;
      MaxPang2 := Query.FieldByName('MaxPang2').AsLargeInt;
      MaxPang3 := Query.FieldByName('MaxPang3').AsLargeInt;
      MaxPang4 := Query.FieldByName('MaxPang4').AsLargeInt;
      SumPang := Query.FieldByName('SumPang').AsLargeInt;
      GamePlayed := Query.FieldByName('GameCount').AsInteger;
      Disconnected := Query.FieldByName('DisconnectGames').AsInteger;
      TeamWin := Query.FieldByName('wTeamWin').AsInteger;
      TeamGame := Query.FieldByName('wTeamGames').AsInteger;
      LadderPoint := Query.FieldByName('LadderPoint').AsInteger;
      LadderWin := Query.FieldByName('LadderWin').AsInteger;
      LadderLose := Query.FieldByName('LadderLose').AsInteger;
      LadderDraw := Query.FieldByName('LadderDraw').AsInteger;
      LadderHole := Query.FieldByName('LadderHole').AsInteger;
      ComboCount := Query.FieldByName('ComboCount').AsInteger;
      MaxCombo := Query.FieldByName('MaxComboCount').AsInteger;
      NoMannerGameCount := Query.FieldByName('NoMannerGameCount').AsInteger;
      SkinsPang := Query.FieldByName('SkinsPang').AsInteger;
      SkinsWin := Query.FieldByName('SkinsWin').AsInteger;
      SkinsLose := Query.FieldByName('SkinsLose').AsInteger;
      SkinsRunHole := Query.FieldByName('SkinsRunHoles').AsInteger;
      SkinsStrikePoint := Query.FieldByName('SkinsStrikePoint').AsInteger;
      SKinsAllinCount := Query.FieldByName('SkinsAllinCount').AsInteger;
      Unknown1[0] := #$00;
      Unknown1[1] := #$00;
      Unknown1[2] := #$00;
      Unknown1[3] := #$00;
      Unknown1[4] := #$00;
      GameCountSeason := Query.FieldByName('GameCountSeason').AsInteger;
      Unknown2[0] := #$00;
      Unknown2[1] := #$00;
      Unknown2[2] := #$00;
      Unknown2[3] := #$00;
      Unknown2[4] := #$00;
      Unknown2[5] := #$00;
      Unknown2[6] := #$00;
      Unknown2[7] := #$00;
    end;

    { main packet }
    { get player guild data }
    Query.Open('EXEC [dbo].[ProcGuildGetPlayerData] @UID = :UID', [PL.GetUID]);

    with PL.GuildData do
    begin
      GuildName := Query.FieldByName('GUILD_NAME').AsAnsiString;
      GuildID := Query.FieldByName('GUILD_INDEX').AsInteger;
      GuildPosition := Query.FieldByName('GUILD_POSITION').AsInteger;
      GuildImage := Query.FieldByName('GUILD_IMAGE').AsAnsiString;
    end;

    Reply.Clear;
    Reply.WriteStr(#$44#$00#$00#$06#$00);
    Reply.WriteStr('829.01', 6);
    Reply.WriteStr(#$FF#$FF);
    Reply.WriteStr(PL.GetLogin, 15);
    Reply.WriteStr(#$00, 7);
    Reply.WriteStr(PL.GetNickname, 16);
    Reply.WriteStr(#$00, 6);
    Reply.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, 21);
    Reply.WriteStr(PL.GuildData.GuildImage, $9);
    Reply.WriteStr(#$00, 7);
    Reply.WriteUInt32(PL.GetCapabilities);
    Reply.WriteUInt32(0);
    Reply.WriteUInt32(PL.ConnectionID);
    Reply.WriteStr(#$00, 12);
    Reply.WriteUInt32(PL.GuildData.GuildID); // GUILD ID SHUOLD UPDATE SOON
    Reply.WriteStr(#$00#$00#$00#$00#$80#$00#$FF#$FF#$FF#$FF#$FF#$FF#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
    Reply.WriteStr(PL.GetLogin + '@NT', 18);
    Reply.WriteStr(#$00, $6E);
    Reply.WriteUInt32(PL.GetUID);
    Reply.Write(PL.Statistic.Drive, SizeOf(TStatistic));
    Reply.WriteStr(JunkLogin);
    Reply.WriteStr(GameTime());
    Reply.WriteStr(#$02#$00#$00#$FF#$FF#$FF#$FF#$FF#$FF#$00#$00#$00#$00);
    Reply.WriteStr(#$00#$00#$00 + #$00 + #$00#$00#$00#$00);
    Reply.WriteStr(#$01#$00#$00#$00#$00);
    Reply.WriteUInt8(8); // Grand Prix 0 for normal
    Reply.WriteStr(#$00#$00);

    Reply.WriteUInt32(Query.FieldByName('GUILD_INDEX').AsInteger); // Guild ID
    Reply.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, 20); // Guild Name
    Reply.WriteStr(#$00, 9);
    Reply.WriteUInt32(Query.FieldByName('GUILD_TOTAL_MEMBER').AsInteger); // Guild total member
    Reply.WriteStr(Query.FieldByName('GUILD_IMAGE').AsAnsiString, 9); // Guild Images
    Reply.WriteStr(#$00, 3);
    Reply.WriteStr(Query.FieldByName('GUILD_NOTICE').AsAnsiString, $65);
    Reply.WriteStr(Query.FieldByName('GUILD_INTRODUCING').AsAnsiString, 101); // Guild Introducing
    Reply.WriteUInt32(Query.FieldByName('GUILD_POSITION').AsInteger); // Guild Position
    Reply.WriteUInt32(Query.FieldByName('GUILD_LEADER_UID').AsInteger); // Guild Leader UID
    Reply.WriteStr(Query.FieldByName('GUILD_LEADER_NICKNAME').AsAnsiString, 22); // Guild Leader Nick
    PL.Send(Reply);

    { CARD }
    Query.Open('EXEC [DBO].ProcGetCardEquip @UID = :UID' , [PL.GetUID]);

    while not Query.Eof do
    begin
      New(PCardEquip(ItemTypeData));
      PCardEquip(ItemTypeData).ID := Query.FieldByName('ID').AsInteger;
      PCardEquip(ItemTypeData).CID := Query.FieldByName('CID').AsInteger;
      PCardEquip(ItemTypeData).CHAR_TYPEID := Query.FieldByName('CHAR_TYPEID').AsInteger;
      PCardEquip(ItemTypeData).CARD_TYPEID := Query.FieldByName('CARD_TYPEID').AsInteger;
      PCardEquip(ItemTypeData).SLOT := Query.FieldByName('SLOT').AsInteger;
      PCardEquip(ItemTypeData).FLAG := Query.FieldByName('FLAG').AsInteger;
      PCardEquip(ItemTypeData).REGDATE := Query.FieldByName('REGDATE').AsDateTime;
      PCardEquip(ItemTypeData).ENDDATE := Query.FieldByName('ENDDATE').AsDateTime;
      PCardEquip(ItemTypeData).VALID := 1;
      PCardEquip(ItemTypeData).NEEDUPDATE := False;
      Query.Next;

      PL.Inventory.ItemCharacter.sCard.AddCard(PCardEquip(ItemTypeData));
    end;

    { Character Data }
    Query.Open('EXEC [dbo].[ProcGetCharacter] @UID = :UID', [PL.GetUID]);

    while not Query.Eof do
    begin
      // Add CharacterInfo
      New(PCharacter(ItemTypeData));
      PCharacter(ItemTypeData).TypeID := Query.FieldByName('TYPEID').AsInteger;
      PCharacter(ItemTypeData).Index := Query.FieldByName('CID').AsInteger;
      PCharacter(ItemTypeData).HairColour := Query.FieldByName('HAIR_COLOR').AsInteger;
      PCharacter(ItemTypeData).GiftFlag := Query.FieldByName('GIFT_FLAG').AsInteger;
      PCharacter(ItemTypeData).Power := Query.FieldByName('POWER').AsInteger;
      PCharacter(ItemTypeData).Control := Query.FieldByName('CONTROL').AsInteger;
      PCharacter(ItemTypeData).Impact := Query.FieldByName('IMPACT').AsInteger;
      PCharacter(ItemTypeData).Spin := Query.FieldByName('SPIN').AsInteger;
      PCharacter(ItemTypeData).Curve := Query.FieldByName('CURVE').AsInteger;

      for Index := 1 to 24 do
      begin
        PCharacter(ItemTypeData).EquipTypeID[Index-1] := Query.FieldByName(Format('PART_TYPEID_%d',[Index])).AsInteger;
      end;

      for Index := 1 to 24 do
      begin
        PCharacter(ItemTypeData).EquipIndex[Index-1] := Query.FieldByName(Format('PART_IDX_%d',[Index])).AsInteger;
      end;

      PCharacter(ItemTypeData).FCutinIndex := Query.FieldByName('CUTIN').AsInteger;
      PL.Inventory.ItemCharacter.Add(PCharacter(ItemTypeData));

      Query.Next;
    end;
    PL.Send(PL.Inventory.ItemCharacter.GetCharData);

    // Caddie Data
    Query.Open('EXEC [dbo].[ProcGetCaddies] @UID = :UID', [PL.GetUID]);
    Reply.Clear;
    Reply.WriteStr(#$71#$00);
    Reply.WriteUInt16(Query.RecordCount);
    Reply.WriteUInt16(Query.RecordCount);

    while not Query.Eof do
    begin
      Reply.WriteUInt32(Query.FieldByName('CID').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('SKIN_TYPEID').AsInteger);
      Reply.WriteUInt8(Query.FieldByName('cLevel').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('EXP').AsInteger);
      Reply.WriteUInt8(Query.FieldByName('RentFlag').AsInteger); // IS TEMP OR LIFETIME ?  // 2 PANG 0 COOKIE
      Reply.WriteUInt16(Query.FieldByName('DAY_LEFT').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('SKIN_HOUR_LEFT').AsInteger);
      Reply.WriteStr(#$00);
      Reply.WriteUInt16(Query.FieldByName('TriggerPay').AsInteger);
      // Add Caddie
      New(PCaddie(ItemTypeData));
      PCaddie(ItemTypeData).CaddieIdx := Query.FieldByName('CID').AsInteger;
      PCaddie(ItemTypeData).CaddieTypeId := Query.FieldByName('TYPEID').AsInteger;
      PCaddie(ItemTypeData).CaddieSkin := Query.FieldByName('SKIN_TYPEID').AsInteger;
      PCaddie(ItemTypeData).CaddieSkinEndDate := Query.FieldByName('SKIN_END_DATE').AsDateTime;
      PCaddie(ItemTypeData).CaddieLevel := Query.FieldByName('cLevel').AsInteger;
      PCaddie(ItemTypeData).CaddieExp := Query.FieldByName('EXP').AsInteger;
      PCaddie(ItemTypeData).CaddieType := Query.FieldByName('RentFlag').AsInteger; // Should Be Fix Soon
      PCaddie(ItemTypeData).CaddieDay := Query.FieldByName('DAY_LEFT').AsInteger;
      PCaddie(ItemTypeData).CaddieSkinDay := Query.FieldByName('SKIN_HOUR_LEFT').AsInteger;
      PCaddie(ItemTypeData).CaddieAutoPay := Query.FieldByName('TriggerPay').AsInteger;
      PCaddie(ItemTypeData).CaddieDateEnd := Query.FieldByName('END_DATE').AsDateTime;
      PL.Inventory.ItemCaddie.Add(PCaddie(ItemTypeData));
      Query.Next;
    end;
    PL.Send(Reply);

    // Get Items
    Query.Open('EXEC [dbo].[ProcGetItemWarehouse] @UID = :UID', [PL.GetUID]);

    Reply.Clear;
    Reply.WriteStr(#$73#$00);
    Reply.WriteUInt16(Query.RecordCount + 1);
    Reply.WriteUInt16(Query.RecordCount + 1);

    while not Query.Eof do
    begin

      if GetItemGroup(Query.FieldByName('TYPEID').AsInteger) = 4 then
      begin
        if Query.FieldByName('CLUB_WORK_COUNT').AsInteger = 0 then
        begin
          CLUB_COUNT := $FFFFFFFF;
        end
        else
        begin
          CLUB_COUNT := Query.FieldByName('CLUB_WORK_COUNT').AsInteger;
        end;
      end
      else
      begin
        CLUB_COUNT := 0;
      end;

      Reply.WriteUInt32(Query.FieldByName('IDX').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('HOURLEFT').AsInteger); // HOUR LEFT
      Reply.WriteUInt16(Query.FieldByName('C0').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('C1').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('C2').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('C3').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('C4').AsInteger);
      Reply.WriteStr(#$00);
      Reply.WriteUInt8(Query.FieldByName('Flag').AsInteger); // Item Flag
      Reply.WriteUInt32(UnixTimeConvert(Query.FieldByName('RegDate').AsDateTime));  // RegDate
      Reply.WriteUInt32(0); // UnKnown
      Reply.WriteUInt32(UnixTimeConvert(Query.FieldByName('DateEnd').AsDateTime));  // EndDate
      Reply.WriteStr(#$00, $4);
      Reply.WriteStr(#$02);
      Reply.WriteStr(Query.FieldByName('UCC_NAME').AsAnsiString, $10);
      Reply.WriteStr(#$00, $19);
      Reply.WriteStr(Query.FieldByName('UCC_UNIQE').AsAnsiString, 9);
      Reply.WriteUInt8(Query.FieldByName('UCC_STATUS').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('UCC_COPY_COUNT').AsInteger);
      Reply.WriteStr(Query.FieldByName('UCC_DRAWER').AsAnsiString, 16);
      Reply.WriteStr(#$00, $3C);
      Reply.WriteUInt16(Query.FieldByName('C0_SLOT').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('C1_SLOT').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('C2_SLOT').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('C3_SLOT').AsInteger);
      Reply.WriteUInt16(Query.FieldByName('C4_SLOT').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('CLUB_POINT').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('CLUB_SLOT_CANCEL').AsInteger);
      Reply.WriteUInt32(CLUB_COUNT);
      Reply.WriteStr(#$00, 4);

      New(PItem(ItemTypeData));
      PItem(ItemTypeData).ItemIndex := Query.FieldByName('IDX').AsInteger;
      PItem(ItemTypeData).ItemTypeID := Query.FieldByName('TYPEID').AsInteger;
      PItem(ItemTypeData).ItemC0 := Query.FieldByName('C0').AsInteger;
      PItem(ItemTypeData).ItemC1 := Query.FieldByName('C1').AsInteger;
      PItem(ItemTypeData).ItemC2 := Query.FieldByName('C2').AsInteger;
      PItem(ItemTypeData).ItemC3 := Query.FieldByName('C3').AsInteger;
      PItem(ItemTypeData).ItemC4 := Query.FieldByName('C4').AsInteger;
      PItem(ItemTypeData).ItemUCCUnique := Query.FieldByName('UCC_UNIQE').AsAnsiString;
      PItem(ItemTypeData).ItemUCCStatus := Query.FieldByName('UCC_STATUS').AsInteger;
      PItem(ItemTypeData).ItemUCCDrawer := Query.FieldByName('UCC_DRAWER').AsAnsiString;
      PItem(ItemTypeData).ItemUCCDrawerUID := Query.FieldByName('UCC_DRAWER_UID').AsInteger;
      PItem(ItemTypeData).ItemUCCName := Query.FieldByName('UCC_NAME').AsAnsiString;
      PItem(ItemTypeData).ItemUCCCopyCount := Query.FieldByName('UCC_COPY_COUNT').AsInteger;
      PItem(ItemTypeData).ItemClubPoint := Query.FieldByName('CLUB_POINT').AsInteger;
      PItem(ItemTypeData).ItemClubWorkCount := Query.FieldByName('CLUB_WORK_COUNT').AsInteger;
      PItem(ItemTypeData).ItemClubPointLog := Query.FieldByName('CLUB_POINT_TOTAL_LOG').AsInteger;
      PItem(ItemTypeData).ItemClubPangLog := Query.FieldByName('CLUB_UPGRADE_PANG_LOG').AsInteger;
      PItem(ItemTypeData).ItemC0Slot := Query.FieldByName('C0_SLOT').AsInteger;
      PItem(ItemTypeData).ItemC1Slot := Query.FieldByName('C1_SLOT').AsInteger;
      PItem(ItemTypeData).ItemC2Slot := Query.FieldByName('C2_SLOT').AsInteger;
      PItem(ItemTypeData).ItemC3Slot := Query.FieldByName('C3_SLOT').AsInteger;
      PItem(ItemTypeData).ItemC4Slot := Query.FieldByName('C4_SLOT').AsInteger;
      PItem(ItemTypeData).ItemClubSlotCancelledCount := Query.FieldByName('CLUB_SLOT_CANCEL').AsInteger;
      PItem(ItemTypeData).ItemGroup := GetItemGroup(Query.FieldByName('TYPEID').AsInteger);
      PItem(ItemTypeData).ItemFlag := Query.FieldByName('Flag').AsInteger; // ITEM FLAG
      PItem(ItemTypeData).ItemEndDate := Query.FieldByName('DateEnd').AsDateTime;
      PItem(ItemTypeData).ItemIsValid := 1; // because we only select item the valided
      PL.Inventory.ItemWarehouse.Add(PItem(ItemTypeData));

      Query.Next;
    end;

    // [Tiki]
    Reply.WriteStr(
      #$F4#$B4#$0D#$46#$42#$00#$00#$1A#$18#$00#$00#$00#$01#$00#$A4#$00#$17#$02#$00#$00#$00#$00#$00#$20#$F0#$E1#$78#$59#$00#$00#$00#$00#$80#$33#$7A#$59#$00#$00+
      #$00#$00#$02#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00+
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00+
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00+
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00+
      #$00#$00#$00#$00#$00#$00
    );
    PL.Send(Reply);

    // -------------------------- MASTCOTS -------------------------\\
    Query.Open('EXEC [dbo].[ProcGetMascot] @UID = :UID', [PL.GetUID]);

    Reply.Clear;
    Reply.WriteStr(#$E1#$00);
    Reply.WriteUInt8(Query.RecordCount);

    while not Query.Eof do
    begin
      Reply.WriteUInt32(Query.FieldByName('MID').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('MASCOT_TYPEID').AsInteger);
      Reply.WriteStr(#$00#$00#$00#$00#$00);
      Reply.WriteStr(Query.FieldByName('MESSAGE').AsAnsiString, 16);
      Reply.WriteStr(#$00, $E);
      Reply.WriteUInt16(Query.FieldByName('END_DATE_INT').AsInteger);
      Reply.WriteStr(GetFixTime(Query.FieldByName('DateEnd').AsDateTime));
      Reply.WriteStr(#$00);

      New(PMascot(ItemTypeData));
      PMascot(ItemTypeData).MascotIndex := Query.FieldByName('MID').AsInteger;
      PMascot(ItemTypeData).MascotTypeID := Query.FieldByName('MASCOT_TYPEID').AsInteger;
      PMascot(ItemTypeData).MascotMessage := Query.FieldByName('MESSAGE').AsAnsiString;
      PMascot(ItemTypeData).MascotEndDate := Query.FieldByName('DateEnd').AsDateTime;
      PL.Inventory.ItemMascot.Add(PMascot(ItemTypeData));

      Query.Next;
    end;

    PL.Send(Reply);

    // -------------------------- ANY TOOLBARS -------------------------\\

    Query.Open('EXEC [dbo].[ProcGetToolbar] @UID = :UID', [PL.GetUID]);

    Reply.Clear;
    Reply.WriteStr(#$72#$00);
    Reply.WriteUInt32(Query.FieldByName('CADDIE').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('CHARACTER_ID').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('CLUB_ID').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('BALL_ID').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_1').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_2').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_3').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_4').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_5').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_6').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_7').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_8').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_9').AsInteger);
    Reply.WriteUInt32(Query.FieldByName('ITEM_SLOT_10').AsInteger);
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Title IDX
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Unknown
    Reply.WriteUInt32(0); // Title TypeID
    Reply.WriteUInt32(Query.FieldByName('MASCOT_ID').AsInteger); // MASCOT INDEX
    Reply.WriteUInt32(Query.FieldByName('POSTER_1').AsInteger); // POSTER LEFT
    Reply.WriteUInt32(Query.FieldByName('POSTER_2').AsInteger); // POSTER RIGHT

    PL.Send(Reply);

    SlotData.Slot1 := Query.FieldByName('ITEM_SLOT_1').AsInteger;
    SlotData.Slot2 := Query.FieldByName('ITEM_SLOT_2').AsInteger;
    SlotData.Slot3 := Query.FieldByName('ITEM_SLOT_3').AsInteger;
    SlotData.Slot4 := Query.FieldByName('ITEM_SLOT_4').AsInteger;
    SlotData.Slot5 := Query.FieldByName('ITEM_SLOT_5').AsInteger;
    SlotData.Slot6 := Query.FieldByName('ITEM_SLOT_6').AsInteger;
    SlotData.Slot7 := Query.FieldByName('ITEM_SLOT_7').AsInteger;
    SlotData.Slot8 := Query.FieldByName('ITEM_SLOT_8').AsInteger;
    SlotData.Slot9 := Query.FieldByName('ITEM_SLOT_9').AsInteger;
    SlotData.Slot10 := Query.FieldByName('ITEM_SLOT_10').AsInteger;

    PL.Inventory.ItemSlot.SetItemSlot(SlotData);

    PL.Inventory.SetCharIndex(Query.FieldByName('CHARACTER_ID').AsInteger);
    PL.Inventory.SetCaddieIndex(Query.FieldByName('CADDIE').AsInteger);
    PL.Inventory.SetBallTypeID(Query.FieldByName('BALL_ID').AsInteger);
    PL.Inventory.SetClubIndex(Query.FieldByName('CLUB_ID').AsInteger);
    PL.Inventory.SetPoster(Query.FieldByName('POSTER_1').AsInteger, Query.FieldByName('POSTER_2').AsInteger);
    // --------------------------- LOBBY ----------------------\\

    Reply.Clear;
    Reply.WriteStr(LobbyLists.Build);
    PL.Send(Reply);

    // -------------------------- JERK -------------------------\\
    Reply.Clear;
    Reply.WriteStr(#$31#$01#$01#$15#$00#$EE#$02#$00#$00#$01#$CA#$03#$00#$00#$02#$DE#$03#$00#$00#$03#$D4#$03#$00#$00#$04#$D4#$03#$00#$00#$05#$DE#$03#$00#$00#$06#$84#$03#$00#$00#$07#$DE#$03#$00#$00#$08#$DE#$03#$00#$00#$09#$DE#$03#$00#$00#$0A#$DE#$03
      +
      #$00#$00#$0B#$8E#$03#$00#$00#$0C#$E8#$03#$00#$00#$0D#$E4#$02#$00#$00#$0E#$84#$03#$00#$00#$0F#$D4#$03#$00#$00#$10#$D4#$03#$00#$00#$11#$00#$00#$00#$00#$12#$D4#$03#$00#$00#$13#$AC#$03#$00#$00#$14#$C0#$03#$00#$00);
    PL.Send(Reply);
    // END JERK

    // ++++++++++++++++++++++++++++++++++++++++++ SUPER JERK ++++++++++++++++++++++++++++++++++ \\

    PL.ReloadAchievement;

    PL.SendCounter;
    PL.SendAchievement;

    Reply.Clear;
    Reply.WriteStr(#$F1#$00#$00);
    PL.Send(Reply);

    Reply.Clear;
    Reply.WriteStr(#$35#$01);
    PL.Send(Reply);

    // -------------------------- CARDS -------------------------\\

    Query.Open('EXEC [dbo].[ProcGetCard] @UID = :UID', [PL.GetUID]);

    Reply.Clear;
    Reply.WriteStr(#$38#$01#$00#$00#$00#$00);
    Reply.WriteUInt16(Query.RecordCount);

    if Query.RecordCount > 0 then
    begin
      while not Query.Eof do
      begin
        Reply.WriteUInt32(Query.FieldByName('CARD_IDX').AsInteger);
        Reply.WriteUInt32(Query.FieldByName('CARD_TYPEID').AsInteger);
        Reply.WriteStr(#$00, 12);
        Reply.WriteUInt32(Query.FieldByName('QTY').AsInteger);
        Reply.WriteStr(#$00, $20);
        Reply.WriteStr(#$01#$00);

        New(PCard(ItemTypeData));
        PCard(ItemTypeData).CardIndex := Query.FieldByName('CARD_IDX').AsInteger;
        PCard(ItemTypeData).CardTypeID := Query.FieldByName('CARD_TYPEID').AsInteger;
        PCard(ItemTypeData).CardQuantity := Query.FieldByName('QTY').AsInteger;
        PCard(ItemTypeData).CardIsValid := Query.FieldByName('VALID').AsInteger;
        PL.Inventory.ItemCard.Add(PCard(ItemTypeData));

        Query.Next;
      end;
      PL.Send(Reply);
    end;

    Reply.Clear;
    Reply.WriteStr(#$36#$01);
    PL.Send(Reply);

    // -------------------------- CARD SPCL NOT YET IMPLEMENTED -------------------------\\
    PL.Write(PL.Inventory.ItemCharacter.sCard.ShowCard);
    // END CARD SPCL

    Reply.Clear;
    Reply.WriteStr(#$81#$01#$00#$00#$00#$00#$00);
    PL.Send(Reply);

    // -------------------------- COOKIE -------------------------\\
    Reply.Clear;
    Reply.WriteStr(#$96#$00);
    Reply.WriteUInt32(PL.GetCookie);
    Reply.WriteStr(#$00, 4);
    PL.Send(Reply);

    // -------------------------- JERK -------------------------\\

    Reply.Clear;
    Reply.WriteStr(#$69#$01#$05#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00);
    PL.Send(Reply);

    Reply.Clear;
    Reply.WriteStr(#$69#$01#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00);
    PL.Send(Reply);

    Reply.Clear;
    Reply.WriteStr(#$B4#$00#$05#$00#$00);
    PL.Send(Reply);

    Reply.Clear;
    Reply.WriteStr(#$B4#$00#$00#$00#$00);
    PL.Send(Reply);

    Reply.Clear;
    Reply.WriteStr(#$58#$01#$00#$01#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00
      + #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$10 +
      #$27#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$7F#$7F#$7F#$7F#$7F#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$D0#$07#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00 +
      #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
    PL.Send(Reply);

    Reply.Clear;
    Reply.WriteStr(#$5D#$02#$05#$00#$00#$00#$00#$00#$00#$00#$00);
    PL.Send(Reply);

    Reply.Clear;
    Reply.WriteStr(#$5D#$02#$00#$00#$00#$00#$00#$64#$00#$00#$00#$D0#$0D#$00#$00#$02#$01#$01#$2F#$01#$00#$00#$00#$D1#$0D#$00#$00#$02#$02
      + #$02#$2F#$02#$00#$00#$00#$D2#$0D#$00#$00#$01#$01#$01#$2F#$01#$00#$00#$00#$D3#$0D#$00#$00#$03#$02#$02#$2F#$01#$00#$00 +
      #$00#$6D#$3C#$01#$00#$03#$01#$01#$2F#$01#$00#$00#$00#$6E#$3C#$01#$00#$02#$64#$64#$2F#$01#$00#$00#$00#$6F#$3C#$01#$00 +
      #$01#$02#$02#$2F#$01#$00#$00#$00#$70#$3C#$01#$00#$01#$64#$64#$2F#$02#$00#$00#$00#$10#$78#$00#$00#$02#$01#$01#$2F#$01 +
      #$00#$00#$00#$11#$78#$00#$00#$01#$02#$02#$2F#$07#$00#$00#$00#$12#$78#$00#$00#$01#$01#$01#$2F#$09#$00#$00#$00#$13#$78 +
      #$00#$00#$02#$02#$02#$2F#$01#$00#$00#$00#$14#$78#$00#$00#$01#$04#$04#$2F#$06#$00#$00#$00#$15#$78#$00#$00#$01#$64#$64 +
      #$2F#$27#$00#$00#$00#$16#$78#$00#$00#$02#$64#$64#$2F#$04#$00#$00#$00#$17#$78#$00#$00#$01#$65#$64#$2F#$01#$00#$00#$00 +
      #$18#$78#$00#$00#$03#$64#$64#$2F#$01#$00#$00#$00#$AA#$50#$00#$00#$01#$02#$02#$2F#$04#$00#$00#$00#$AB#$50#$00#$00#$01 +
      #$01#$01#$2F#$04#$00#$00#$00#$AC#$50#$00#$00#$01#$04#$04#$2F#$4D#$00#$00#$00#$AD#$50#$00#$00#$01#$03#$03#$2F#$01#$00 +
      #$00#$00#$AE#$50#$00#$00#$03#$64#$64#$2F#$02#$00#$00#$00#$AF#$50#$00#$00#$01#$64#$64#$2F#$96#$00#$00#$00#$B0#$50#$00 +
      #$00#$02#$64#$64#$2F#$09#$00#$00#$00#$B1#$50#$00#$00#$01#$65#$64#$2F#$31#$00#$00#$00#$B2#$50#$00#$00#$03#$65#$64#$2F +
      #$02#$00#$00#$00#$B3#$50#$00#$00#$02#$04#$04#$2F#$01#$00#$00#$00#$B4#$50#$00#$00#$01#$06#$06#$2F#$01#$00#$00#$00#$B5 +
      #$50#$00#$00#$02#$65#$64#$2F#$01#$00#$00#$00#$CA#$38#$00#$00#$02#$02#$02#$2F#$01#$00#$00#$00#$CB#$38#$00#$00#$03#$02 +
      #$02#$2F#$01#$00#$00#$00#$85#$F1#$00#$00#$01#$02#$02#$2F#$01#$00#$00#$00#$86#$F1#$00#$00#$03#$04#$04#$2F#$01#$00#$00 +
      #$00#$87#$F1#$00#$00#$01#$01#$01#$2F#$01#$00#$00#$00#$1F#$31#$01#$00#$01#$02#$02#$2F#$02#$00#$00#$00#$20#$31#$01#$00 +
      #$01#$01#$01#$2F#$02#$00#$00#$00#$21#$31#$01#$00#$01#$64#$64#$2F#$12#$00#$00#$00#$58#$95#$00#$00#$01#$01#$01#$2F#$02 +
      #$00#$00#$00#$07#$2C#$01#$00#$01#$04#$04#$2F#$06#$00#$00#$00#$08#$2C#$01#$00#$02#$04#$04#$2F#$01#$00#$00#$00#$09#$2C +
      #$01#$00#$03#$04#$04#$2F#$01#$00#$00#$00#$D2#$BC#$00#$00#$03#$02#$02#$2F#$02#$00#$00#$00#$D3#$BC#$00#$00#$01#$02#$02 +
      #$2F#$0B#$00#$00#$00#$D4#$BC#$00#$00#$01#$01#$01#$2F#$0A#$00#$00#$00#$D5#$BC#$00#$00#$02#$02#$02#$2F#$04#$00#$00#$00 +
      #$D6#$BC#$00#$00#$01#$05#$05#$2F#$05#$00#$00#$00#$D7#$BC#$00#$00#$02#$04#$04#$2F#$06#$00#$00#$00#$D8#$BC#$00#$00#$01 +
      #$03#$03#$2F#$05#$00#$00#$00#$D9#$BC#$00#$00#$01#$04#$04#$2F#$44#$01#$00#$00#$DA#$BC#$00#$00#$02#$03#$03#$2F#$03#$00 +
      #$00#$00#$DB#$BC#$00#$00#$03#$05#$05#$2F#$01#$00#$00#$00#$DC#$BC#$00#$00#$03#$01#$01#$2F#$01#$00#$00#$00#$DD#$BC#$00 +
      #$00#$03#$06#$06#$2F#$01#$00#$00#$00#$DE#$BC#$00#$00#$02#$01#$01#$2F#$02#$00#$00#$00#$DF#$BC#$00#$00#$03#$04#$04#$2F +
      #$01#$00#$00#$00#$E0#$BC#$00#$00#$01#$64#$64#$2F#$0F#$00#$00#$00#$E1#$BC#$00#$00#$01#$06#$06#$2F#$01#$00#$00#$00#$15 +
      #$4B#$00#$00#$03#$02#$02#$2F#$01#$00#$00#$00#$16#$4B#$00#$00#$01#$02#$02#$2F#$03#$00#$00#$00#$17#$4B#$00#$00#$01#$01 +
      #$01#$2F#$02#$00#$00#$00#$D4#$20#$01#$00#$01#$02#$02#$2F#$02#$00#$00#$00#$D5#$20#$01#$00#$02#$01#$01#$2F#$01#$00#$00 +
      #$00#$D6#$20#$01#$00#$01#$01#$01#$2F#$01#$00#$00#$00#$D7#$20#$01#$00#$01#$04#$04#$2F#$02#$00#$00#$00#$4B#$4B#$01#$00 +
      #$02#$02#$02#$2F#$01#$00#$00#$00#$4C#$4B#$01#$00#$02#$04#$04#$2F#$01#$00#$00#$00#$4D#$4B#$01#$00#$03#$02#$02#$2F#$02 +
      #$00#$00#$00#$4E#$4B#$01#$00#$01#$01#$01#$2F#$01#$00#$00#$00#$4F#$4B#$01#$00#$01#$64#$64#$2F#$0D#$00#$00#$00#$50#$4B +
      #$01#$00#$02#$64#$64#$2F#$02#$00#$00#$00#$51#$4B#$01#$00#$01#$02#$02#$2F#$02#$00#$00#$00#$52#$4B#$01#$00#$03#$64#$64 +
      #$2F#$03#$00#$00#$00#$AA#$50#$00#$00#$01#$02#$02#$2F#$04#$00#$00#$00#$AB#$50#$00#$00#$01#$01#$01#$2F#$04#$00#$00#$00 +
      #$AC#$50#$00#$00#$01#$04#$04#$2F#$4D#$00#$00#$00#$AD#$50#$00#$00#$01#$03#$03#$2F#$01#$00#$00#$00#$AE#$50#$00#$00#$03 +
      #$64#$64#$2F#$02#$00#$00#$00#$AF#$50#$00#$00#$01#$64#$64#$2F#$96#$00#$00#$00#$B0#$50#$00#$00#$02#$64#$64#$2F#$09#$00 +
      #$00#$00#$B1#$50#$00#$00#$01#$65#$64#$2F#$31#$00#$00#$00#$B2#$50#$00#$00#$03#$65#$64#$2F#$02#$00#$00#$00#$B3#$50#$00 +
      #$00#$02#$04#$04#$2F#$01#$00#$00#$00#$B4#$50#$00#$00#$01#$06#$06#$2F#$01#$00#$00#$00#$B5#$50#$00#$00#$02#$65#$64#$2F +
      #$01#$00#$00#$00#$AA#$50#$00#$00#$01#$02#$02#$2F#$04#$00#$00#$00#$AB#$50#$00#$00#$01#$01#$01#$2F#$04#$00#$00#$00#$AC +
      #$50#$00#$00#$01#$04#$04#$2F#$4D#$00#$00#$00#$AD#$50#$00#$00#$01#$03#$03#$2F#$01#$00#$00#$00#$AE#$50#$00#$00#$03#$64 +
      #$64#$2F#$02#$00#$00#$00#$AF#$50#$00#$00#$01#$64#$64#$2F#$96#$00#$00#$00#$B0#$50#$00#$00#$02#$64#$64#$2F#$09#$00#$00 +
      #$00#$B1#$50#$00#$00#$01#$65#$64#$2F#$31#$00#$00#$00#$B2#$50#$00#$00#$03#$65#$64#$2F#$02#$00#$00#$00#$B3#$50#$00#$00 +
      #$02#$04#$04#$2F#$01#$00#$00#$00#$B4#$50#$00#$00#$01#$06#$06#$2F#$01#$00#$00#$00#$B5#$50#$00#$00#$02#$65#$64#$2F#$01 +
      #$00#$00#$00#$89#$54#$01#$00#$01#$01#$01#$2F#$03#$00#$00#$00#$8A#$54#$01#$00#$01#$04#$04#$2F#$B3#$00#$00#$00#$8B#$54 +
      #$01#$00#$03#$04#$04#$2F#$01#$00#$00#$00#$8C#$54#$01#$00#$02#$04#$04#$2F#$08#$00#$00#$00#$64#$9C#$00#$00#$01#$02#$02 +
      #$2F#$06#$00#$00#$00);
    PL.Send(Reply);
    // End Jerk

    // ## mail popup
    PlayerShowMailPopUp(PL);

    // ## generate assistance
    if PL.Inventory.GetQuantity(467664918) = 1 then
      PL.Assist := 1;

    // ## get room data
    Query.Open('EXEC [dbo].[ProcGetRoomData] @UID = :UID', [PL.GetUID]);
    // ## add to room data list
    while not Query.Eof do
    begin
      New(PFurniture(ItemTypeData));
      PFurniture(ItemTypeData).Index := Query.FieldByName('IDX').AsInteger;
      PFurniture(ItemTypeData).TypeID := Query.FieldByName('TYPEID').AsInteger;
      PFurniture(ItemTypeData).PosX := Query.FieldByName('POS_X').AsInteger;
      PFurniture(ItemTypeData).PosY := Query.FieldByName('POS_Y').AsInteger;
      PFurniture(ItemTypeData).PosZ := Query.FieldByName('POS_Z').AsInteger;
      PFurniture(ItemTypeData).PosR := Query.FieldByName('POS_R').AsInteger;
      PFurniture(ItemTypeData).Valid := 1;
      PL.Inventory.ItemRoom.Add(PFurniture(ItemTypeData));
      Query.Next;
    end;

  finally
    FreeQuery(Query, Con);
    FreeAndNil(Reply);
  end;
end;

end.
