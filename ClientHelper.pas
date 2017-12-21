unit ClientHelper;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  System.Classes, PangyaClient, ClientPacket, Lobby, GameBase, Buffer, Defines,
  UWriteConsole, Tools, Crypts, PapelSystem, BoxRandom, ScratchCard, LobbyList, System.SysUtils,
  System.SyncObjs, XSuperObject, Enum, PList, ListPair, System.Generics.Collections,
  MailSystem, EXPSystem, ServerStr, MyList,
  MailCore, PlayerDataCore, GameShopCore, LobbyCore, GuildCore, GameCore,
  ClubSystemCore, SelfDesignCore, ItemCore, QuestCore, LockerCore, GamePlayCore;

type
  THelper = class helper for TClientPlayer
    public
      procedure fProcess(const PacketData: AnsiString);
      procedure fPushOffline;

      procedure ReloadAchievement;
      procedure ClearAchievement;

      procedure FSendGuildData;
      function FUpdateMapStatistic(const Statistic: TStatistic; Map: UInt8; Score: ShortInt; MaxPang: UInt32): Boolean;
      function FAddExp(Count: UInt32): Boolean;
  end;

implementation

{ THelper }

procedure THelper.fProcess(const PacketData: AnsiString);
var
  BuffTemp: TBuffer;
  ProcessPacket: TClientPacket;
  Size, realPacketSize: UInt32;
  X, Y, Rand: Integer;
  StringBuffer: AnsiString;
  PacketId: UInt16;
  PLobby: TLobby;
  PlayerGame: TGameBase;
  CounterMS: UInt32;
begin
  BuffTemp := TBuffer.Create;
  ProcessPacket := TClientPacket.Create;
  Size := 0;
  try
    BuffTemp.Write(PacketData);

    if (BuffTemp.GetLength > 2) then
    begin
      move(BuffTemp.GetData[2], Size, 2);
    end
    else
    begin
      Exit;
    end;

    realPacketSize := Size + 4;

    while BuffTemp.GetLength >= realPacketSize do
    begin
      StringBuffer := BuffTemp.Read(0, realPacketSize);
      BuffTemp.Delete(0, realPacketSize);

      // SECURITY CHECK
      Rand := Ord(StringBuffer[1]);
      X := Byte(Keys[((Self.GetKey) shl 8) + Rand + 1]);
      Y := Byte(Keys[((Self.GetKey) shl 8) + Rand + 4097]);

      if not (y = (x xor ord(StringBuffer[5]))) then
      begin
        Exit;
      end;
      // SECURITY CHECK

      StringBuffer := Crypts.Decrypt(StringBuffer, Self.GetKey);
      Delete(StringBuffer, 1, 5);

      ProcessPacket.Clear;
      ProcessPacket.WriteStr(StringBuffer);
      ProcessPacket.Seek(0, 0);

      if not ProcessPacket.ReadUInt16(PacketId) then
      begin
        Exit;
      end;

      if not (PacketId = 2) and not (Verified) then
      begin
        Exit;
      end;

      WriteConsole( AnsiFormat('Packet -> [%d] %s {ID: %s, Nick: %s}', [PacketId, ShowHex(StringBuffer), Self.GetLogin, Self.GetNickname]) );

      CounterMS := Gettick;

      case TGAMEPACKET(PacketId) of
        PLAYER_LOGIN:
          begin
            PlayerLogin(Self, ProcessPacket);
          end;
        PLAYER_SELECT_LOBBY:
          begin
            PlayerSelectLobby(Self, ProcessPacket)
          end;
        PLAYER_JOIN_MULTIGAME_LIST:
          begin
            PlayerJoinMultiGameList(Self, ProcessPacket);
          end;
        PLAYER_LEAVE_MULTIGAME_LIST:
          begin
            PlayerLeaveMultiGamesList(Self, ProcessPacket);
          end;
        PLAYER_CHANGE_NICKNAME:
          begin
            PlayerChangeNickname(Self, ProcessPacket);
          end;
        PLAYER_CHAT:
          begin
            PlayerChat(Self, ProcessPacket);
          end;
        PLAYER_OPEN_PAPEL:
          begin
            Papel.HandlePlayerOpenPapel(Self);
          end;
        PLAYER_OPEN_NORMAL_BONGDARI:
          begin
            Papel.HandlePlayerPlayNormalPapel(Self);
          end;
        PLAYER_OPEN_BIG_BONGDARI:
          begin
            Papel.HandlePlayerPlayBigPapel(Self);
          end;
        PLAYER_SAVE_MACRO:
          begin
            PlayerSaveMacro(Self, ProcessPacket);
          end;
        PLAYER_OPEN_MAILBOX:
          begin
            PlayerGetMailList(Self, ProcessPacket);
          end;
        PLAYER_READ_MAIL:
          begin
            PlayerReadMail(Self, ProcessPacket);
          end;
        PLAYER_RELEASE_MAILITEM:
          begin
            PlayerReleaseItem(Self, ProcessPacket);
          end;
        PLAYER_DELETE_MAIL:
          begin
            PlayerDeleteMail(Self, ProcessPacket);
          end;
        PLAYER_GM_COMMAND:
          begin
            GMCommand(Self, ProcessPacket);
          end;
        PLAYER_CREATE_GAME:
          begin
            PlayerCreateGame(Self, ProcessPacket);
          end;
        PLAYER_AFTER_UPLOAD_UCC:
          begin
            PlayerAfterUploaded(Self, ProcessPacket);
          end;
        PLAYER_REQUEST_UPLOAD_KEY:
          begin
            PlayerRequestUploadKey(Self, ProcessPacket);
          end;
        PLAYER_BUY_ITEM_GAME:
          begin
            PlayerBuyItemGameShop(Self, ProcessPacket);
          end;
        PLAYER_ENTER_TO_SHOP:
          begin
            PlayerEnterGameShop(Self);
          end;
        PLAYER_CHECK_USER_FOR_GIFT:
          begin
            PlayerGetPlayerData(Self, ProcessPacket);
          end;
        PLAYER_SAVE_BAR,
        PLAYER_CHANGE_EQUIPMENT:
          begin
            PlayerSaveBar(Self, ProcessPacket);
          end;
        PLAYER_CHANGE_EQUIPMENTS:
          begin
            PlayerChangeEquipment(Self, ProcessPacket);
          end;
        PLAYER_JOIN_GAME:
          begin
            PlayerJoinGame(Self, ProcessPacket);
          end;
        PLAYER_WHISPER:
          begin
            PlayerWhispering(Self, ProcessPacket);
          end;
        PLAYER_REQUEST_TIME:
          begin
            PlayerGetTime(Self);
          end;
        PLAYER_GM_DESTROY_ROOM:
          begin
            GMDestroyRoom(Self, ProcessPacket);
          end;
        PLAYER_GM_KICK_USER:
          begin
            GMDisconnectUserByConnectID(Self, ProcessPacket);
          end;
        PLAYER_REQUEST_LOBBY_INFO:
          begin
            PlayerGetLobbyInfo(Self);
          end;
        PLAYER_REMOVE_ITEM:
          begin
            PlayerRemoveItem(Self, ProcessPacket);
          end;
        PLAYER_PLAY_AZTEC_BOX:
          begin
            PlayerOpenAztecBox(Self, ProcessPacket);
          end;
        PLAYER_OPEN_BOX:
          begin
            BoxRand.HandlePlayerOpenBox(ProcessPacket, Self);
          end;
        PLAYER_CHANGE_SERVER:
          begin
            PlayerChangeServer(Self);
          end;
        PLAYER_ASSIST_CONTROL:
          begin
            PlayerControlAssist(Self, ProcessPacket);
          end;
        PLAYER_SELECT_LOBBY_WITH_ENTER_CHANNEL:
          begin
            PlayerSelectLobby(Self, ProcessPacket, True);
          end;
        PLAYER_REQUEST_GAMEINFO:
          begin
            PlayerGetGameInfo(Self, ProcessPacket);
          end;
        PLAYER_JOIN_MULTIGAME_GRANDPRIX:
          begin
            PlayerJoinMultiGameList(Self, ProcessPacket, True);
          end;
        PLAYER_LEAVE_MULTIGAME_GRANDPRIX:
          begin
            PlayerLeaveMultiGamesList(Self, ProcessPacket, True);
          end;
        PLAYER_ENTER_GRANDPRIX:
          begin
            PlayerEnterGP(Self, ProcessPacket);
          end;
        PLAYER_GM_SEND_NOTICE:
          begin
            GMSendNotice(Self, ProcessPacket);
          end;
        PLAYER_REQUEST_PLAYERINFO:
          begin
            PlayerGetPlayerInfo(Self, ProcessPacket);
          end;
        PLAYER_CHANGE_MASCOT_MESSAGE:
          begin
            PlayerChangeMascotMessage(Self, ProcessPacket);
          end;
        PLAYER_ENTER_ROOM:
          begin
            PlayerEnterPersonalRoom(Self);
          end;
        PLAYER_ENTER_ROOM_GETINFO:
          begin
            PlayerEnterPersonalRoomGetCharData(Self);
          end;
        PLAYER_OPENUP_SCRATCHCARD:
          begin
            Scratch.HandlePlayerOpenScratchCard(Self);
          end;
        PLAYER_PLAY_SCRATCHCARD:
          begin
            Scratch.HandlePlayerScratchCard(Self);
          end;
        PLAYER_FIRST_SET_LOCKER:
          begin
            PlayerSetLocker(Self, ProcessPacket);
          end;
        PLAYER_ENTER_TO_LOCKER:
          begin
            HandleEnterRoom(Self);
          end;
        PLAYER_REQUEST_UNKNOWN:
          begin

          end;
        PLAYER_UPGRADE_CLUB:
          begin
            PlayerUpgradeClub(Self, ProcessPacket);
          end;
        PLAYER_UPGRADE_ACCEPT:
          begin
            PlayerUpgradeClubAccept(Self);
          end;
        PLAYER_UPGRADE_CALCEL:
          begin
            PlayerUpgradeClubCancel(Self);
          end;
        PLAYER_UPGRADE_RANK:
          begin
            PlayerUpgradeRank(Self, ProcessPacket);
          end;
        PLAYER_TRASAFER_CLUBPOINT:
          begin
            PlayerTransferClubPoint(Self, ProcessPacket);
          end;
        PLAYER_CLUBSET_ABBOT:
          begin
            PlayerUseAbbot(Self, ProcessPacket);
          end;
        PLAYER_CLUBSET_POWER:
          begin
            PlayerUseClubPowder(Self, ProcessPacket);
          end;
        PLAYER_CALL_GUILD_LIST:
          begin
            PlayerCallGuildList(Self, ProcessPacket);
          end;
        PLAYER_SEARCH_GUILD:
          begin
            PlayerSearchGuild(Self, ProcessPacket);
          end;
        PLAYER_GUILD_AVAIABLE:
          begin
            PlayerCheckGuildAvailble(Self, ProcessPacket);
          end;
        PLAYER_CREATE_GUILD:
          begin
            PlayerCreateGuild(Self, ProcessPacket);
          end;
        PLAYER_REQUEST_GUILDDATA:
          begin
            PlayerRequestGuildData(Self, ProcessPacket);
          end;
        PLAYER_GUILD_GET_PLAYER:
          begin
            PlayerGetGuildPlayer(Self, ProcessPacket);
          end;
        PLAYER_GUILD_LOG:
          begin
            PlayerGetGuildLog(Self);
          end;
        PLAYER_JOIN_GUILD:
          begin
            PlayerJoinGuild(Self, ProcessPacket);
          end;
        PLAYER_CANCEL_JOIN_GUILD:
          begin
            PlayerCancelJoinGuild(Self, ProcessPacket);
          end;
        PLAYER_GUILD_ACCEPT:
          begin
            PlayerGuildAccept(Self, ProcessPacket);
          end;
        PLAYER_GUILD_KICK:
          begin
            PlayerGuildKick(Self, ProcessPacket);
          end;
        PLAYER_GUILD_PROMOTE:
          begin
            PlayerGuildPromote(Self, ProcessPacket);
          end;
        PLAYER_CHANGE_INTRO:
          begin
            PlayerChangeGuildIntro(Self, ProcessPacket);
          end;
        PLAYER_CHANGE_NOTICE:
          begin
            PlayerChangeGuildNotice(Self, ProcessPacket);
          end;
        PLAYER_CHANGE_SELFINTRO:
          begin
            PlayerChangeGuildSelfIntro(Self, ProcessPacket);
          end;
        PLAYER_LEAVE_GUILD:
          begin
            PlayerLeaveGuild(Self, ProcessPacket);
          end;
        PLAYER_REQUEST_CHECK_DAILY_ITEM:
          begin
            PlayerDailyLoginCheck(Self);
          end;
        PLAYER_REQUEST_ITEM_DAILY:
          begin
            PlayerDailyLoginItem(Self);
          end;
        PLAYER_GUILD_DESTROY:
          begin

          end;
        PLAYER_GUILD_CALL_UPLOAD:
          begin
            PlayerGuildCallUpload(Self, ProcessPacket);
          end;
        PLAYER_GUILD_CALL_AFTER_UPLOAD:
          begin
            PlayerGuildAfterUpload(Self);
          end;
        PLAYER_CALL_ACHIEVEMENT:
          begin
            PlayerGetAchievement(Self, ProcessPacket);
          end;
        PLAYER_OPEN_TIKIREPORT:
          begin
            PlayerOpenTikiReport(Self, ProcessPacket);
          end;
        PLAYER_LEAVE_GAME:
          begin
            PlayerLeaveGame(Self, ProcessPacket);
          end;
        PLAYER_UPGRADE_CLUB_SLOT:
          begin
            PlayerUpgradeClubSlot(Self, ProcessPacket);
          end;
        PLAYER_LEAVE_GRANDPRIX:
          begin
            PlayerLeaveGP(Self, ProcessPacket);
          end;
        PLAYER_CALL_CUTIN:
          begin
            PlayerGetCutinData(Self, ProcessPacket);
          end;
        PLAYER_MEMORIAL:
          begin
            PlayerMemorialGacha(Self, ProcessPacket);
          end;
        PLAYER_OPEN_CARD:
          begin
            PlayerOpenCardpack(Self, ProcessPacket);
          end;
        PLAYER_DO_MAGICBOX:
          begin
            PlayerMagicBox(Self, ProcessPacket);
          end;
        PLAYER_RENEW_RENT:
          begin
            PlayerRenewRent(Self, ProcessPacket);
          end;
        PLAYER_DELETE_RENT:
          begin
            PlayerDeleteRent(Self, ProcessPacket);
          end;
        PLAYER_LOAD_QUEST:
          begin
            PlayerLoadQuest(Self);
          end;
        PLAYER_ACCEPT_QUEST:
          begin
            PlayerAcceptQuest(Self, ProcessPacket);
          end;
        PLAYER_MATCH_HISTORY:
          begin
            PlayerGetMatchHistory(Self);
          end;
        PLAYER_PUT_CARD:
          begin
            PlayerPutCard(Self, ProcessPacket);
          end;
        PLAYER_PUT_BONUS_CARD:
          begin
            PlayerPutBonusCard(Self, ProcessPacket);
          end;
        PLAYER_REMOVE_CARD:
          begin
            PlayerCardRemove(Self, ProcessPacket);
          end;
        PLAYER_OPEN_LOCKER:
          begin
            PlayerOpenLocker(Self, ProcessPacket);
          end;
        PLAYER_CHANGE_LOCKERPWD:
          begin
            PlayerChangeLockerPwd(Self, ProcessPacket);
          end;
        PLAYER_GET_LOCKERPANG:
          begin
            PlayerGetPangLocker(Self);
          end;
        PLAYER_LOCKERPANG_CONTROL:
          begin
            PlayerLockerProcessPang(Self, ProcessPacket);
          end;
        PLAYER_CALL_LOCKERITEMLIST:
          begin
            PlayerGetLockerItem(Self, ProcessPacket);
          end;
        PLAYER_PUT_ITEMLOCKER:
          begin
            PlayerPutItemLocker(Self, ProcessPacket);
          end;
        PLAYER_TAKE_ITEMLOCKER:
          begin
            PlayerTakeItemLocker(Self, ProcessPacket);
          end;
        PLAYER_CARD_SPECIAL:
          begin
            PlayerCardSpecial(Self, ProcessPacket);
          end;
        PLAYER_SEND_TOP_NOTICE:
          begin
            PlayerSendTopNotice(Self, ProcessPacket);
          end;
        PLAYER_CHECK_NOTICE_COOKIE:
          begin
            PlayerCheckNoticeCookie(Self);
          end;
        PLAYER_UPGRADE_STATUS:
          begin
            PlayerUpgradeStatus(Self, ProcessPacket);
          end;
        PLAYER_DOWNGRADE_STATUS:
          begin
            PlayerDowngradeStatus(Self, ProcessPacket);
          end;
        PLAYER_USE_ITEM,
        PLAYER_PRESS_READY,
        PLAYER_START_GAME,
        PLAYER_LOAD_OK,
        PLAYER_SHOT_DATA,
        PLAYER_ENTER_TO_ROOM,
        PLAYER_ACTION,
        PLAYER_CLOSE_SHOP,
        PLAYER_EDIT_SHOP,
        PLAYER_MASTER_KICK_PLAYER,
        PLAYER_CHANGE_GAME_OPTION,
        PLAYER_1ST_SHOT_READY,
        PLAYER_LOADING_INFO,
        PLAYER_GAME_ROTATE,
        PLAYER_CHANGE_CLUB,
        PLAYER_GAME_MARK,
        PLAYER_ACTION_SHOT,
        PLAYER_SHOT_SYNC,
        PLAYER_HOLE_INFORMATIONS,
        PLAYER_REQUEST_ANIMALHAND_EFFECT,
        PLAYER_MY_TURN,
        PLAYER_HOLE_COMPLETE,
        PLAYER_CHAT_ICON,
        PLAYER_SLEEP_ICON,
        PLAYER_MATCH_DATA,
        PLAYER_MOVE_BAR,
        PLAYER_PAUSE_GAME,
        PLAYER_QUIT_SINGLE_PLAYER,
        PLAYER_CALL_ASSIST_PUTTING,
        PLAYER_USE_TIMEBOOSTER,
        PLAYER_DROP_BALL,
        PLAYER_CHANGE_TEAM,
        PLAYER_VERSUS_TEAM_SCORE,
        PLAYER_POWER_SHOT,
        PLAYER_WIND_CHANGE,
        PLAYER_SEND_GAMERESULT: // GAME PROCESS
          begin
            PLobby := TLobby(Self.Lobby);
            if PLobby = nil then
            begin
              Exit;
            end;

            PlayerGame := PLobby.GameHandle[Self];

            if PlayerGame = nil then
            begin
              Exit;
            end;

            PlayerGame.HandlePacket(TGAMEPACKET(PacketId), Self, ProcessPacket);
          end;
        else
          begin
            Self.Send(#$14#$02#$f8#$16#$2d#$00);
            WriteConsole('{Unknown Packet} -> ' + ShowHex(StringBuffer), 11);
          end;
      end;

      WriteConsole(AnsiFormat('Take %dms to completed' ,[Gettick - CounterMS]), $2);

      if (BuffTemp.GetLength > 2) then
      begin
        Move(BuffTemp.GetData[2], Size, 2);
        realPacketSize := Size + 4;
      end else begin
        Exit;
      end;
    end; {END WHILE}
  finally
    FreeAndNil(BuffTemp);
    FreeAndNil(ProcessPacket);
  end;
end;

procedure THelper.fPushOffline;
var
  Query: TFDQuery;
  Con: TFDConnection;
begin
  CreateQuery(Query, Con);
  try
    Query.ExecSQL('EXEC [dbo].[USP_GAME_LOGOUT] @UID = :UID', [Self.GetUID]);

    // SAVE ITEM
    Self.Inventory.Save;

  finally
    FreeQuery(Query, Con);
  end;
end;

procedure THelper.FSendGuildData;
var
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
begin
  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcGuildGetPlayerData] @UID = :UID',[GetUID]);

    if Query.RecordCount <= 0 then Exit;

    with GuildData do
    begin
      GuildName := Query.FieldByName('GUILD_NAME').AsAnsiString;
      GuildID := Query.FieldByName('GUILD_INDEX').AsInteger;
      GuildPosition := Query.FieldByName('GUILD_POSITION').AsInteger;
      GuildImage := Query.FieldByName('GUILD_IMAGE').AsAnsiString;
    end;

    Packet.WriteStr(#$BF#$01);
    Packet.WriteUInt32(1);
    Packet.WriteUInt32(Query.FieldByName('GUILD_INDEX').AsInteger); // Guild ID
    Packet.WriteStr(Query.FieldByName('GUILD_NAME').AsAnsiString, 20);
    Packet.WriteStr(#$00, 9);
    Packet.WriteUInt32(Query.FieldByName('GUILD_TOTAL_MEMBER').AsInteger);
    Packet.WriteStr(Query.FieldByName('GUILD_IMAGE').AsAnsiString, 9);
    Packet.WriteStr(#$00, 3);
    Packet.WriteStr(Query.FieldByName('GUILD_NOTICE').AsAnsiString, $65);
    Packet.WriteStr(Query.FieldByName('GUILD_INTRODUCING').AsAnsiString, 101);
    Packet.WriteUInt32(Query.FieldByName('GUILD_POSITION').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('GUILD_LEADER_UID').AsInteger);
    Packet.WriteStr(Query.FieldByName('GUILD_LEADER_NICKNAME').AsAnsiString,22);
    Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

function THelper.FUpdateMapStatistic(const Statistic: TStatistic; Map: UInt8; Score: ShortInt; MaxPang: UInt32): Boolean;
var
  Query: TFDQuery;
  Con: TFDConnection;
begin
  CreateQuery(Query, Con);
  try
    Query.SQL.Add('EXEC [dbo].[ProcUpdateMapStatistics]');
    Query.SQL.Add('@UID = :UID, @MAP = :MAP, @DRIVE = :DRIVE,@PUTT = :PUTT,@HOLE = :HOLE,@FAIRWAY = :FAIRWAY,');
    Query.SQL.Add('@HOLEIN = :HOLEIN,@PUTTIN = :PUTTIN, @TOTALSCORE = :TOTALSCORE, @BESTSCORE = :BESTSCORE,');
    Query.SQL.Add('@MAXPANG = :MAXPANG, @CHARTYPEID = :CHARTYPEID, @ASSIST = :ASSIST');

    Query.ParamByName('UID').AsInteger := Self.GetUID;
    Query.ParamByName('MAP').AsInteger := Map;
    Query.ParamByName('DRIVE').AsInteger := Statistic.Drive;
    Query.ParamByName('PUTT').AsInteger := Statistic.Putt;
    Query.ParamByName('HOLE').AsInteger := Statistic.Hole;
    Query.ParamByName('FAIRWAY').AsInteger := Statistic.Fairway;
    Query.ParamByName('HOLEIN').AsInteger := Statistic.Holein;
    Query.ParamByName('PUTTIN').AsInteger := Statistic.Puttin;
    Query.ParamByName('TOTALSCORE').AsInteger := Score;
    Query.ParamByName('BESTSCORE').AsInteger := Score;
    Query.ParamByName('MAXPANG').AsInteger := MaxPang;
    Query.ParamByName('CHARTYPEID').AsInteger := Self.Inventory.GetCharTypeID;
    Query.ParamByName('ASSIST').AsInteger := Self.Assist;
    Query.Open;

    Exit(Query.FieldByName('ISNEWRECORD').AsInteger = 1)
  finally
    FreeQuery(Query, Con);
  end;
end;

procedure THelper.ClearAchievement;
var
  Achievement: PAchievement;
  Counter: PAchievementCounter;
  Quest: PAchievementQuest;
begin
  for Achievement in Self.Achievements do
  begin
    Dispose(Achievement);
  end;

  for Quest in Self.AchievementQuests do
  begin
    Dispose(Quest);
  end;

  for Counter in Self.AchievemetCounters.Values do
  begin
    Dispose(Counter);
  end;

  Self.Achievements.Clear;
  Self.AchievementQuests.Clear;
  Self.AchievemetCounters.Clear;
end;

procedure THelper.ReloadAchievement;
var
  Query: TFDQuery;
  Con: TFDConnection;

  Achievement: PAchievement;
  Counter: PAchievementCounter;
  Quest: PAchievementQuest;
begin
  Self.ClearAchievement;

  CreateQuery(Query, Con, False);
  try
    Query.Open('EXEC [dbo].[ProcGetAchievement] @UID = :UID', [Self.GetUID]);

    while not Query.Eof do
    begin
      New(Achievement);
      Achievement.ID := Query.FieldByName('ID').AsInteger;
      Achievement.TypeID := Query.FieldByName('TypeID').AsInteger;
      Achievement.AchievementType := Query.FieldByName('Type').AsInteger;
      Self.Achievements.Add(Achievement);
      Query.Next;
    end;

    QueryNextSet(Query);

    while not Query.Eof do
    begin
      New(Counter);
      Counter.ID := Query.FieldByName('ID').AsInteger;
      Counter.TypeID := Query.FieldByName('TypeID').AsInteger;
      Counter.Quantity := Query.FieldByName('Quantity').AsInteger;
      Self.AchievemetCounters.Add(Counter.ID, Counter);
      Query.Next;
    end;

    QueryNextSet(Query);

    while not Query.Eof do
    begin
      New(Quest);
      Quest.ID := Query.FieldByName('ID').AsInteger;
      Quest.AchievementIndex := Query.FieldByName('Achievement_Index').AsInteger;
      Quest.AchievementTypeID := Query.FieldByName('Achivement_Quest_TypeID').AsInteger;
      Quest.CounterIndex := Query.FieldByName('Counter_Index').AsInteger;
      Quest.SuccessDate := Query.FieldByName('SuccessDate').AsInteger;
      Quest.Total := Query.FieldByName('Count').AsInteger;

      Self.AchievementQuests.Add(Quest);

      Query.Next;
    end;
  finally
    FreeQuery(Query, Con);
  end;
end;

function THelper.FAddExp(Count: UInt32): Boolean;
var
  EXPTotal: UInt32;
  Packet: TClientPacket;
  IsUpdate: Boolean;
  MailSender: TMailSender;
begin
  if Self.Level >= 70 then
  begin
    Exit(False);
  end;

  Self.Exp := Self.Exp + Count;
  IsUpdate := False;

  while true do
  begin
    if Self.Level >= 70 then
    begin
      Break;
    end;
    EXPList.TryGetValue(Self.Level, EXPTotal);
    if Self.Exp >= EXPTotal then
    begin
      Self.Level := Self.Level + 1;
      // Add Item
      MailSender := TMailSender.Create;
      try
        MailSender.Sender := 'System';
        MailSender.AddText(ReadString.GetText('LevelUP'));
        MailSender.AddItemLevel(Self.Level);
        MailSender.Send(Self.GetUID);
      finally
        FreeAndNil(MailSender);
      end;

      Self.Exp := Self.Exp - EXPTotal;
      IsUpdate := True;
    end else
    begin
      Break;
    end;
  end;

  Packet := TClientPacket.Create;
  try
    if IsUpdate then
    begin
      Packet.WriteStr(#$0F#$01#$00#$00#$00#$00#$01);
      Packet.WriteUInt8(Self.Level);
      Send(Packet);
    end;
    {Packet.Clear;
    Packet.WriteStr(#$D9#$01);
    Packet.WriteUInt32(Self.Level);
    Packet.WriteUInt32(Self.Exp);
    Send(Packet);}
  finally
    FreeAndNil(Packet);
  end;
  Exit(True);
end;

end.
