unit LobbyCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  ClientPacket, PangyaClient, LobbyList, Lobby, System.SysUtils,
  PacketCreator, Tools, GameBase, MailSystem, IffMain;

procedure PlayerSelectLobby(const PL: TClientPlayer; const ClientPacket: TClientPacket; RequestJoinGameList: Boolean = False);
procedure PlayerJoinMultiGameList(const PL: TClientPlayer; const ClientPacket: TClientPacket; GrandPrix: Boolean = False);
procedure PlayerLeaveMultiGamesList(const PL: TClientPlayer; const ClientPacket: TClientPacket; GrandPrix: Boolean = False);
procedure PlayerChat(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerChangeNickname(const PL: TClientPlayer; const ClientPacket: TClientPacket);

procedure GMCommand(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure GMDestroyRoom(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure GMDisconnectUserByConnectID(const PL: TClientPlayer; const ClientPacket: TClientPacket);

procedure PlayerCreateGame(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerLeaveGame(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerLeaveGP(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerJoinGame(const PL: TClientPlayer; const clientPacket: TClientPacket);

procedure PlayerGetGameInfo(const PL: TClientPlayer; const clientPacket: TClientPacket);
procedure PlayerGetLobbyInfo(const PL: TClientPlayer);

procedure PlayerEnterGP(const PL: TClientPlayer; const ClientPacket: TClientPacket);

implementation

uses
  MainServer;

procedure PlayerSelectLobby(const PL: TClientPlayer; const ClientPacket: TClientPacket; RequestJoinGameList: Boolean = False);
var
  LobbyId: Byte;
  PLobby: TLobby;
begin
  // ## read lobby id
  if not clientPacket.ReadUInt8(LobbyId) then Exit;

  // ## get player lobby if exists
  PLobby := TLobby(PL.Lobby);

  // ## if not nil then leave the player
  if not (PLobby = nil) then
  begin
    PLobby.RemovePlayer(PL);
  end;

  // ## if player's lobby is nil
  if PLobby = nil then
  begin
    PL.Send(#$95#$00#$02#$01#$00);
  end;

  // ## get lobby by id
  PLobby := LobbyLists.GetLobby(LobbyId);

  // ## if lobby is not exist then quit
  if PLobby = nil then
  begin
    raise Exception.Create('HandlePlayerSelectLobby: Player''s selected invalid lobby');
  end;

  // ## if player lobby is reached
  if PLobby.PlayerCount.Count >= PLobby.MaxPlayer then
  begin
    PL.Send(#$4E#$00#$02);
    Exit;
  end;

  // ## add player
  if PLobby.AddPlayer(PL) then
  begin
    PL.Send(#$4E#$00#$01);
    // ## if request join lobby
    if RequestJoinGameList then
    begin
      PLobby.JoinMultiplayerGamesList(PL);
    end;
  end;
end;

procedure PlayerJoinMultiGameList(const PL: TClientPlayer; const ClientPacket: TClientPacket; GrandPrix: Boolean = False);
var
  PLobby: TLobby;
begin
  PLobby := TLobby(PL.Lobby);

  if PLobby = nil then
  begin
    Exit;
  end;

  PLobby.JoinMultiplayerGamesList(PL);

  if GrandPrix then
  begin
    PL.Send(
      #$50#$02#$00#$00#$00#$00#$03#$00#$00#$00#$01#$00#$00#$00#$02 +
      #$00#$00#$00#$03#$00#$00#$00#$00#$00#$00#$00#$00#$00#$34#$43
    );
  end
  else if not GrandPrix then
  begin
    PL.Send(#$F5#$00);
  end;
end;

procedure PlayerLeaveMultiGamesList(const PL: TClientPlayer; const ClientPacket: TClientPacket; GrandPrix: Boolean = False);
var
  PLobby: TLobby;
begin
  // ## get lobby player
  PLobby := TLobby(PL.Lobby);

  // ## if lobby is nil
  if PLobby = nil then
  begin
    raise Exception.Create('HandlePlayerLeaveMultiGamesList: Player selected invalid lobby');
  end;

  // ## leave multi game list
  PLobby.LeaveMultiplayerGamesList(PL);

  if GrandPrix then
  begin
    PL.Send(#$51#$02#$00#$00#$00#$00);
  end
  else if not GrandPrix then
  begin
    PL.Send(#$F6#$00);
  end;
end;

procedure PlayerChat(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  PLobby: TLobby;
  Messages, Nickname: AnsiString;
begin
  PLobby := TLobby(PL.Lobby);

  if PLobby = nil then
  begin
    Exit;
  end;

  ClientPacket.Skip(4);

  if not ClientPacket.ReadPStr(Nickname) then Exit;
  if not ClientPacket.ReadPStr(Messages) then Exit;

  if not (Nickname = PL.GetNickname) then
  begin
    Exit;
  end;
  PLobby.PlayerSendChat(PL, Messages);
end;

procedure PlayerChangeNickname(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Nickname: AnsiString;
  Query: TFDQuery;
  Con: TFDConnection;
  Code: Byte;
  PLobby: TLobby;
begin
  if not ClientPacket.ReadPStr(Nickname) then Exit;

  if (Length(Nickname) < 4) or (Length(Nickname) > $10) then
  begin
    PL.Send(#$50#$00#$01#$00#$00#$00);
    Exit;
  end;

  if PL.GetCookie < 1500 then
  begin
    PL.Send(#$50#$00#$04#$00#$00#$00); // Send Cookie not enought
    raise Exception.Create('HandlePlayerChangeNickname: Player haven''t had enought cookie to change his nickname');
  end;

  CreateQuery(Query, Con);
  try
    Query.Open
      ('EXEC [dbo].[ProcUpdateNickname] @UID = :UID, @NICKNAME = :NICKNAME',
      [PL.GetUID, Nickname]);

    Code := Query.FieldByName('Code').AsInteger;

    if Code = 2 then // Return 2 is name duplicated
    begin
      PL.Write(ShowNicknameChangeDup);
      Exit;
    end;

    if Code = 0 then // Something Wrong
    begin
      PL.Send(#$50#$00#$01#$00#$00#$00);
      Exit;
    end;

    if Code = 1 then // Success
    begin
      PL.Write(ShowNicknameChangeSucceed(Nickname));
      // ## Set Player New Nickname
      PL.SetNickname(Nickname);

      if not(PL.GetCapabilities = 4) then // ## free for gm
      begin
        PL.RemoveCookie(1500);
        PL.SendCookies;
      end;

      PLobby := TLobby(PL.Lobby);

      if not(PLobby = nil) then
      begin
        PLobby.UpdatePlayerLobbyInfo(PL);
      end;
    end;
  finally
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerCreateGame(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  PLobby: TLobby;
begin
  PLobby := TLobby(PL.Lobby);
  if PLobby = nil then
  begin
    Exit;
  end;
  PLobby.PlayerCreateGame(ClientPacket, PL);
end;

procedure PlayerLeaveGame(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  PLobby: TLobby;
begin
  PLobby := TLobby(PL.Lobby);
  if PLobby = nil then
  begin
    Exit;
  end;
  PLobby.PlayerLeaveGame(ClientPacket, PL);
end;

procedure PlayerLeaveGP(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  PLobby: TLobby;
begin
  PLobby := TLobby(PL.Lobby);
  if PLobby = nil then
  begin
    Exit;
  end;
  PLobby.PlayerLeaveGP(ClientPacket, PL);
end;

procedure PlayerJoinGame(const PL: TClientPlayer; const clientPacket: TClientPacket);
var
  PLobby: TLobby;
begin
  PLobby := TLobby(PL.Lobby);
  if PLobby = nil then
  begin
    Exit;
  end;

  PLobby.PlayerJoinGame(clientPacket, PL);
end;

procedure GMCommand(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  PLobby: TLobby;
  CommandId: Word;
  arg1: UInt8;
  ConnectionID, ItemTypeID, Quantity: UInt32;
  Game: TGameBase;
  Client: TClientPlayer;
  Packet: TClientPacket;
  AddMail: TMailSender;
begin
  if not (PL.GetCapabilities = 4) then
  begin
    raise Exception.Create('HandleGMCommands: Player has requested gm command but he is not an admin');
  end;

  clientPacket.ReadUInt16(CommandId);

  PLobby := TLobby(PL.Lobby);

  if (PLobby = nil) then Exit;

  case CommandId of
    $3:
      begin
        if not clientPacket.ReadUInt8(arg1) then Exit;
        case arg1 of
          0:
            begin
              PL.Visible := 4;
            end;
          1:
            begin
              PL.Visible := 0;
            end;
        end;
        PLobby.UpdatePlayerLobbyInfo(PL);
      end;
    $F:
      begin
        if not clientPacket.ReadUInt8(arg1) then Exit;
        Game := PLobby.GameHandle[PL];
        if Game = nil then
        begin
          Exit;
        end;
        Packet := TClientPacket.Create;
        try
          Packet.WriteStr(#$9E#$00);
          Packet.WriteUInt8(arg1);
          Packet.WriteStr(#$00#$00);
          Game.Send(Packet);
        finally
          FreeAndNil(Packet);
        end;
      end;
    $12:
      begin
        if not clientPacket.ReadUInt32(ConnectionID) then Exit;  // Connection Id
        if not clientPacket.ReadUInt32(ItemTypeID) then Exit;  // TypeID
        if not clientPacket.ReadUInt32(Quantity) then Exit;  // Quantity
        if not IffEntry.IsExist(ItemTypeID) then Exit; // If Item EXISTS

        Client := PLobby.GetPlayerByConnectionId(ConnectionID);

        if Client = nil then
        begin
          Exit;
        end;

        AddMail := TMailSender.Create;
        try
          AddMail.Sender := 'System';
          AddMail.AddText('GM presents you ');
          AddMail.AddItem(ItemTypeID, Quantity, True);
          // Add to db
          AddMail.Send(Client.GetUID);
          Client.SendMailPopup;
        finally
          FreeAndNil(AddMail);
        end;
      end;
    $0A:
      begin
        if not ClientPacket.ReadUInt32(ConnectionID) then Exit;

        Client := PLobby.GetPlayerByConnectionId(ConnectionID);

        if Client = nil then
        begin
          Exit;
        end;

        Client.Disconnect;
      end;
  end;
end;

procedure GMDestroyRoom(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  GameHandle: TGameBase;
  GameID: Word;
  PLobby : TLobby;
begin
  if not (PL.GetCapabilities = 4) then
  begin
    raise Exception.Create('HandleGMDestroyRoom: GM was trying to destroy a room but he is not an admin');
  end;

  if not clientPacket.ReadUInt16(GameID) then Exit;

  PLobby := TLobby(PL.Lobby);

  GameHandle := PLobby.GameHandle[GameID];
  if GameHandle = nil then
    Exit;
  GameHandle.DestroyRoom;
end;

procedure GMDisconnectUserByConnectID(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  ConnectionId: UInt32;
  Client: TClientPlayer;
begin
  if not (PL.GetCapabilities = 4) then
  begin
    raise Exception.Create('HandleGMDisconnectUserByConnectId: GM was trying to disconnect a player but he is not an admin');
  end;

  if not ClientPacket.ReadUInt32(ConnectionId) then Exit;
  Client := TGameServer(PL.GameServer).GetClientByConnectionId(ConnectionId);
  if Client = nil then
  begin
    Exit;
  end;
  Client.Send(#$76#$02#$FA#$00#$00#$00);
  Client.Disconnect;
end;

procedure PlayerGetLobbyInfo(const PL: TClientPlayer);
var
  Reply: TClientPacket;
begin
  Reply := TClientPacket.Create;
  try
    Reply.WriteStr(LobbyLists.Build);
    PL.Send(Reply);
  finally
    FreeAndNil(Reply);
  end;
end;

procedure PlayerGetGameInfo(const PL: TClientPlayer; const clientPacket: TClientPacket);
var
  PLobby : TLobby;
begin
  PLobby := TLobby(PL.Lobby);

  if PLobby = nil then
  begin
    Exit;
  end;

  PLobby.PlayerRequestGameInfo(clientPacket, PL);
end;

procedure PlayerEnterGP(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  PLobby : TLobby;
begin
  PLobby := TLobby(PL.Lobby);

  if PLobby = nil then
  begin
    Exit;
  end;

  PLobby.PlayerJoinGrandPrix(clientPacket, PL);
end;

end.
