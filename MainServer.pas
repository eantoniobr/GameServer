unit MainServer;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Windows, Classes, IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer, IdContext,
  IdTCPConnection, System.SysUtils, PangyaClient, SerialID,
  FiredacPooling, LobbyList, Tools, Utils, PangyaBuffer, BoxRandom, Lobby, IffMain, ScratchCard,
  AuthClient, UWriteConsole, MyList, ExceptionLog, System.StrUtils,
  System.Threading, Console, Defines;

type
  TGameServer = class
  private
    FServer: TIdTCPServer;
    FPlayers: TMyList<TClientPlayer>;
    FSerialID : TSerialId;
    fCommand: ITask;

    procedure OnConnect(AContext: TIdContext);
    procedure OnExecute(AContext: TIdContext);
    procedure OnDisconnect(AContext: TIdContext);
    procedure OnException(AContext: TIdContext; AException: Exception);
    {$Hints Off}
    function GetPlayerByContext(AContext: TIdContext): TClientPlayer;
    {$Hints On}
  public
    constructor Create;
    destructor Destroy; override;

    procedure Run;
    procedure Shutdown;
    procedure HandleNotice(const Messages : AnsiString);
    procedure Send(Data: TPangyaBuffer);
    procedure HandleStaffSendNotice(const Nickname, Msg: AnsiString);

    function GetPlayerByNickname(const Nickname: AnsiString): TClientPlayer;

    function GetPlayerByUsername(const Username: AnsiString): TClientPlayer;
    function GetPlayerByUID(UID: UInt32): TClientPlayer;
    function GetClientByConnectionId(ConnectionId: UInt32): TClientPlayer;
    procedure RunCommand;
  end;

implementation

{ TMainServer }

constructor TGameServer.Create;
begin
  FServer := TIdTCPServer.Create;
  FServer.DefaultPort := 20201;
  FServer.OnConnect := OnConnect;
  FServer.OnExecute := OnExecute;
  FServer.OnDisconnect := OnDisconnect;
  //FServer.OnException := OnException;

  FServer.UseNagle := True;
  FPlayers := TMyList<TClientPlayer>.Create;
  FSerialID := TSerialId.Create;
  IffEntry := TIffManager.Create;
  AuthController.ClientList := FPlayers;

  Self.RunCommand;
end;

destructor TGameServer.Destroy;
begin
  FreeAndNil(FSerialID);
  FreeAndNil(FPlayers);
  FreeAndNil(FServer);
  FreeAndNil(IffEntry);
  inherited;
end;

function TGameServer.GetClientByConnectionId(ConnectionId: UInt32): TClientPlayer;
begin
  for Result in FPlayers do
    if Result.ConnectionId = ConnectionId then
      Exit;

  Result := nil;
end;

function TGameServer.GetPlayerByContext(AContext: TIdContext): TClientPlayer;
begin
  for Result in FPlayers do
    if Result.Context = AContext then
      Exit;

  Result := nil;
end;

function TGameServer.GetPlayerByNickname(const Nickname: AnsiString): TClientPlayer;
begin
  for Result in FPlayers do
    if SameText(Result.GetNickname, Nickname) then
      Exit;

  Result := nil;
end;

function TGameServer.GetPlayerByUID(UID: UInt32): TClientPlayer;
begin
  for Result in FPlayers do
    if Result.GetUID = UID then
      Exit;

  Result := nil;
end;

function TGameServer.GetPlayerByUsername(const Username: AnsiString): TClientPlayer;
begin
  for Result in FPlayers do
    if SameText(Result.GetLogin, Username) then
      Exit;

  Result := nil;
end;

procedure TGameServer.OnConnect(AContext: TIdContext);
var
  Client: TClientPlayer;
begin
  Client := TClientPlayer.Create(AContext);
  Client.ConnectionId := FSerialID.GetId;

  Client.GameServer := Self;

  AContext.Data := Client;

  FPlayers.Add(Client);

  Client.SendKey;

  WriteConsole(AnsiFormat('Client Connected to %s:%d with Connect Id %d',[ AContext.Binding.PeerIP, AContext.Binding.PeerPort, Client.ConnectionId]));
end;

procedure TGameServer.OnDisconnect(AContext: TIdContext);
var
  PLobby: TLobby;
begin
  if Assigned(AContext.Data) and (AContext.Data is TClientPlayer) then
  begin
    WriteConsole(AnsiFormat('User (%s) is disconnected', [TClientPlayer(AContext.Data).GetLogin]));
    PLobby := TLobby(TClientPlayer(AContext.Data).Lobby);
    if not(PLobby = nil) then
    begin
      PLobby.RemovePlayer(TClientPlayer(AContext.Data));
    end;

    { push player to offline }
    TClientPlayer(AContext.Data).PushOffline;
    { remove from player lists }
    FPlayers.Remove(TClientPlayer(AContext.Data));
    { remove from unique id }
    FSerialID.RemoveId(TClientPlayer(AContext.Data).ConnectionId);
    { free player class }
    TClientPlayer(AContext.Data).Free;
    AContext.Data := nil;
  end;
end;

procedure TGameServer.OnException(AContext: TIdContext; AException: Exception);
begin
  WriteConsole( AnsiFormat(' Socket Exception %s', [AException.Message]) );
end;

procedure TGameServer.OnExecute(AContext: TIdContext);
var
  Con: TIdTCPConnection;
  Data: TMemoryStream;
  Buffer: AnsiString;
  Player: TClientPlayer;
begin
  Con := AContext.Connection;
  repeat
    if not Con.IOHandler.InputBufferIsEmpty then
    begin
      Data := TMemoryStream.Create;
      try
        Con.IOHandler.InputBufferToStream(Data);
        if (not Assigned(AContext.Data)) or (not (AContext.Data is TClientPlayer)) then
        begin
          Con.Disconnect;
        end else
        begin
          try
            Player := TClientPlayer(AContext.Data);
            SetString(Buffer, PAnsiChar(Data.Memory), Data.Size);
            Player.Process(Buffer);
          except
            on E: Exception do
            begin
              WriteConsole( AnsiFormat('User: %s causes exception with message: %s', [Player.GetLogin, E.Message]));
              FException.SaveLog(Player.GetUID, Player.GetLogin, E.Message + E.StackTrace);
            end;
          end;
        end;
      finally
        FreeAndNil(Data);
      end;
    end;
    SleepEx(1, True);
  until (not Con.Connected);
end;

procedure TGameServer.HandleNotice(const Messages: AnsiString);
var
  Reply : TPangyaBuffer;
begin
  Reply := TPangyaBuffer.Create;
  try
    Reply.WriteStr(#$42#$00);
    Reply.WritePStr(Messages);
    Self.Send(Reply);
  finally
    FreeAndNil(Reply);
  end;
end;

procedure TGameServer.HandleStaffSendNotice(const Nickname, Msg: AnsiString);
var
  Reply : TPangyaBuffer;
begin
  Reply := TPangyaBuffer.Create;
  try
    if (Length(Nickname) <= 0) OR (Length(Msg) <= 0) then
    begin
      Exit
    end;

    Reply.WriteStr(#$40#$00#$07);
    Reply.WritePStr(Nickname);
    Reply.WritePStr(Msg);

    Self.Send(Reply);
  finally
    FreeAndNil(Reply);
  end;
end;

procedure TGameServer.Run;
begin
  FServer.Active := True;
  WriteConsole( AnsiFormat(' Server is running at %d ', [FServer.DefaultPort]) , $7);
end;

procedure TGameServer.RunCommand;
var
  Command, CommandParameters: string;
  InputArray: TArray<string>;
  C: string;
  P: TClientPlayer;
  D: Double;
begin
  fCommand := TTask.Create(
    procedure()
    begin
      while True do
      begin
        Readln(C);
        InputArray := C.Split([' ']);

        if Length(InputArray) >= 1 then
          Command := InputArray[0]
        else
          Command := string.Empty;

        if Length(InputArray) >= 2 then
          CommandParameters := InputArray[1]
        else
          CommandParameters := string.Empty;

        case IndexStr(Command, ['kickuid', 'kickname', 'kickuser', 'topnotice', 'clear', 'exp']) of
          0:
            begin
              if not TryStrToFloat(CommandParameters, D) then Continue;
              P := Self.GetPlayerByUID(CommandParameters.ToInteger());
              if (P = nil) then
              begin
                WriteConsole('[COMMAND] THIS UID IS NOT ONLINE!');
                Continue;
              end;
              P.Disconnect;
            end;
          1:
            begin
              P := Self.GetPlayerByNickname(CommandParameters);
              if (P = nil) then
              begin
                WriteConsole('[COMMAND] THIS NICKNAME IS NOT ONLINE!');
                Continue;
              end;
              P.Disconnect;
            end;
          2:
            begin
              P := Self.GetPlayerByUsername(CommandParameters);
              if (P = nil) then
              begin
                WriteConsole('[COMMAND] THIS USERNAME IS NOT ONLINE!');
                Continue;
              end;
              P.Disconnect;
            end;
          3:
            begin
              Self.HandleNotice(CommandParameters);
            end;
          4:
            begin
              ClrScr;
            end;
          5:
            begin
              if (not TryStrToFloat(CommandParameters, D)) or (StrToInt(CommandParameters) <= 0) then begin
                WriteConsole('[COMMAND] This is not a number or less than zero!!');
                Continue;
              end;
              SetMultiplierExp(StrToInt(CommandParameters));
              WriteConsole( Format('[COMMAND] Multiplier Exp is %d', [MultiplierExp]));
            end;
          -1:
            WriteConsole('!!! Unknown command');
        end;
      end;
    end);

  fCommand.Start;
end;

procedure TGameServer.Send(Data: TPangyaBuffer);
var
  Client: TClientPlayer;
begin
  for Client in FPlayers do
  begin
    Client.Send(Data);
  end;
end;

procedure TGameServer.Shutdown;
begin
  FServer.Active := False;
end;

end.
