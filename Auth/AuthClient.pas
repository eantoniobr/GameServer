unit AuthClient;

interface

uses
  ScktComp, SysUtils, ClientPacket, Tools, ExtCtrls, Buffer, PangyaClient, MyList, UWriteConsole, SyncObjs;

type
  TAuthClient = class
    private
      var ClientSocket : TClientSocket;
      var FAddress : String;
      var FPort : UInt16;
      var FTimer : TTimer;
      var FType : UInt16;
      var FBuffer : TBuffer;
      var FLockSend: TCriticalSection;
      var FClientlist: TMyList<TClientPlayer>;
      procedure OnConnect(Sender: TObject; Socket: TCustomWinSocket);
      procedure OnRead(Sender: TObject; Socket: TCustomWinSocket);
      procedure OnError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
      procedure OnDisconnect(Sender: TObject; Sockets: TCustomWinSocket);
      procedure OnTimer(Sender: TObject);
      // PROGRESS
      procedure SendToAllPlayer(const Data : AnsiString);
      procedure HandleClientReceiveTicker(Const clientPacket : TClientPacket);
      procedure HandleClientReciveUID(Const clientPacket : TClientPacket);
      procedure HandleServerTopNotice(Const clientPacket: TClientPacket);
      procedure HandlePlayerAnnounceReward(Const clientPacket: TClientPacket);
      procedure HandleSendGuildData(Const clientPacket: TClientPacket);
      function GetPlayerByUID( UID : UInt32): TClientPlayer;
    public
      function isConnect: Boolean;
      constructor Create(const Address : String; Port : UInt16; ServerType : UInt8);
      destructor Destroy; override;
      procedure Send(const Text : AnsiString);
      procedure Write(const Data: TClientPacket);
      property ClientList : TMyList<TClientPlayer> read FClientlist write FClientlist;
  end;

var
  AuthController: TAuthClient;

implementation

{ TAuthClient }

constructor TAuthClient.Create(const Address: String; Port: UInt16;
  ServerType: UInt8);
begin
  FAddress := Address;
  FPort := Port;
  FType := ServerType;

  ClientSocket := TClientSocket.Create(nil);
  ClientSocket.Host := Address;
  ClientSocket.Port := FPort;
  ClientSocket.OnConnect := Self.OnConnect;
  ClientSocket.OnRead := Self.OnRead;
  ClientSocket.OnError := Self.OnError;
  Clientsocket.OnDisconnect := Self.OnDisconnect;
  ClientSocket.ClientType := ctNonBlocking;

  FTimer := TTimer.Create(nil);
  FTimer.Interval := 10000;
  FTimer.OnTimer := OnTimer;
  FTimer.Enabled := True;

  FBuffer := TBuffer.Create;
  FLockSend := TCriticalSection.Create;

  ClientSocket.Open;
end;

destructor TAuthClient.Destroy;
begin
  ClientSocket.Free;
  FTimer.Free;
  FBuffer.Free;
  FLockSend.Free;
  inherited;
end;

function TAuthClient.GetPlayerByUID(UID: UInt32): TClientPlayer;
var
  Client : TClientPlayer;
begin
  for Client in ClientList do
    if Client.GetUID = UID then
      Exit(Client);

  Exit(nil);
end;

procedure TAuthClient.HandleClientReceiveTicker(const clientPacket: TClientPacket);
var
  Nickname, Messages : AnsiString;
  Packet : TClientPacket;
begin
  if not clientPacket.ReadPStr(Nickname) then Exit;
  if not clientPacket.ReadPStr(Messages) then Exit;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$C9#$00);
    Packet.WritePStr(Nickname);
    Packet.WritePStr(Messages);

    Self.SendToAllPlayer(Packet.ToStr);
  finally
    Packet.Free;
  end;
end;

procedure TAuthClient.HandleClientReciveUID(const clientPacket: TClientPacket);
var
  UID : UInt32;
  Client : TClientPlayer;
begin
  if not clientPacket.ReadUInt32(UID) then Exit;

  Client := Self.GetPlayerByUID(UID);

  if Client = nil then
  begin
    Exit;
  end;

  //Client.Send(#$76#$02#$00#$00#$00#$00); // SEND CODE 0
  Client.Disconnect;
end;

procedure TAuthClient.HandlePlayerAnnounceReward(
  const clientPacket: TClientPacket);
var
  Param: AnsiString;
  Packet : TClientPacket;
begin
  if not clientPacket.ReadPStr(Param) then Exit;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$D3#$01#$01#$00#$00#$00#$01#$00#$00#$00);
    Packet.WritePStr(Param);
    Self.SendToAllPlayer(Packet.ToStr);
  finally
    Packet.Free;
  end;

end;

procedure TAuthClient.HandleSendGuildData(const clientPacket: TClientPacket);
var
  UID: UInt32;
  Player: TClientPlayer;
begin
  if not clientPacket.ReadUInt32(UID) then Exit;

  Player := GetPlayerByUID(UID);

  if (Player = nil) then
  begin
    Exit;
  end;
  Player.SendGuildData;
end;

procedure TAuthClient.HandleServerTopNotice(const clientPacket: TClientPacket);
var
  Messages : AnsiString;
  Client : TClientPlayer;
  Packet : TClientPacket;
begin
  if not clientPacket.ReadPStr(Messages) then Exit;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$42#$00);
    Packet.WritePStr(Messages);

    for Client in FClientlist do
    begin
      Client.Send(Packet.ToStr);
    end;
  finally
    Packet.Free;
  end;
end;

function TAuthClient.isConnect: Boolean;
begin
  if not ClientSocket.Socket.Connected then
  begin
    Exit(False);
  end;
  Exit(True);
end;

procedure TAuthClient.OnConnect(Sender: TObject; Socket: TCustomWinSocket);
var
  Packet : TClientPacket;
begin
  if Socket.Connected then
  begin
    // SEND SERVER DETAIL
    Packet := TClientPacket.Create;
    try
      Packet.WriteStr(#$01#$00);
      Packet.WriteUInt16(FPort);
      Packet.WriteUInt16(FType);
      self.Send(Packet.ToStr);
    finally
      Packet.Free;
    end;
  end;

end;

procedure TAuthClient.OnDisconnect(Sender: TObject; Sockets: TCustomWinSocket);
begin
  WriteConsole(' connection lost from auth server trying to reconnect ...', 2);
end;

procedure TAuthClient.OnError(Sender: TObject; Socket: TCustomWinSocket;
  ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
  ErrorCode := 0;
  Socket.Close;
end;

procedure TAuthClient.OnRead(Sender: TObject; Socket: TCustomWinSocket);
var
  size,realPacketSize : UInt32;
  Buffer: AnsiString;
  ClientPacket : TClientPacket;
  packetId : UInt16;
begin

  size := 0;

  self.FBuffer.Write(Socket.ReceiveText);

  if (self.FBuffer.GetLength > 2) then
  begin
    move(self.FBuffer.GetData[1], size, 2);
  end
  else
  begin
    Exit;
  end;

  realPacketSize := size + 2;

  while self.FBuffer.GetLength >= realPacketSize do
  begin
    Buffer := self.FBuffer.Read(0, realPacketSize);
    self.FBuffer.Delete(0, realPacketSize);

    // DELETE LENGTH
    Delete(Buffer, 1, 2);
    clientPacket := TClientPacket.Create(Buffer);

    //Tool.Write(Tool.getHexEncode(Buffer) , 2);

    if not ClientPacket.ReadUInt16(PacketId) then
    begin
      Exit;
    end;

    case packetId of
      5:
        begin
          Self.HandleClientReceiveTicker(clientPacket);
        end;
      6:
        begin
          Self.HandleClientReciveUID(clientPacket);
        end;
      7:
        begin
          Self.HandleServerTopNotice(clientPacket);
        end;
      8:
        begin
          Self.HandlePlayerAnnounceReward(clientPacket);
        end;
      9:
        begin
          Self.HandleSendGuildData(clientPacket);
        end;
    end;

    clientPacket.Free;

    if (self.FBuffer.GetLength > 2) then
    begin
      move(self.FBuffer.GetData[1], size, 2);
      realPacketSize := size + 2;
    end
    else
    begin
      Exit;
    end;
  end;
end;

procedure TAuthClient.OnTimer(Sender: TObject);
begin
  if not ClientSocket.Socket.Connected then
  begin
    WriteConsole(' no connection from auth server trying to reconnect ...', 2);
    ClientSocket.Open;
  end;
end;

procedure TAuthClient.Send(const Text: AnsiString);
var
  Packet : TClientPacket;
begin
  FLockSend.Acquire;
  try
    Packet := TClientPacket.Create;
    try
      Packet.WriteUInt16(Length(Text));
      Packet.WriteStr(Text);
      ClientSocket.Socket.SendText(Packet.ToStr);
    finally
      Packet.Free;
    end;
  finally
    FLockSend.Release;
  end;
end;

procedure TAuthClient.SendToAllPlayer(const Data: AnsiString);
var
  client : TClientPlayer;
begin
  for client in FClientlist do
    client.Send(Data);
end;

procedure TAuthClient.Write(const Data: TClientPacket);
begin
  try
    Send(Data.ToStr);
  finally
    Data.Free;
  end;
end;

initialization
  AuthController := TAuthClient.Create('127.0.0.1', 10111,1);
finalization
  AuthController.Free;

end.
