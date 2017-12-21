unit Ticker;

interface

uses
 AuthClient, PangyaClient, ClientPacket;

type
  TTicker = class
    private
      var FAuthClient : TAuthClient;
    public
      procedure HandlePlayerCheckCookieForTicker(Const Player : TClientPlayer);
      procedure HandlePlayerSendTicker(Const clientPacket : TClientPacket; Const Player : TClientPlayer);
      property AuthClient : TAuthClient read FAuthClient write FAuthClient;
  end;

implementation

{ TTicker }

procedure TTicker.HandlePlayerSendTicker(const clientPacket: TClientPacket;
  const Player: TClientPlayer);
var
  Messages : AnsiString;
  Packet : TClientPacket;
begin
  if not FAuthClient.IsConnect then Exit;
  
  if not clientPacket.ReadPStr(Messages) then Exit;

  if not Player.RemoveCookie(500) then
  begin
    Player.Send(#$CB#$00#$00#$00#$00#$00#$00#$00);
    Exit;
  end;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$02#$00);
    Packet.WritePStr(Player.GetNickname);
    Packet.WritePStr(Messages);
    FAuthClient.Send(Packet.ToStr);
  finally
    Packet.Free;
  end;
end;

{ TTicker }

procedure TTicker.HandlePlayerCheckCookieForTicker(const Player: TClientPlayer);
begin
  if Player.GetCookie < 500 then
  begin
    Player.Send(#$CB#$00#$00#$00#$00#$00#$00#$00);
    Exit;
  end;

  Player.Send(#$CA#$00#$00#$00#$00#$00#$00#$00);
end;

end.
