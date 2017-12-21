unit LobbyList;

interface

uses
  SysUtils, Lobby, PacketData, ClientPacket, PangyaClient, Tools, MyList;

type

  TLobbiesList = class
    private
      var FLobbyList: TMyList<TLobby>;
    public
      constructor Create;
      destructor Destroy; override;
      function Build: TPacketData;
      function GetLobby(LobbyID: UInt8): TLobby;

      procedure DestroyLobbies;
  end;

  var
    LobbyLists: TLobbiesList;

implementation

{ TLobbiesList }

function TLobbiesList.Build: TPacketData;
var
  Lobby : TLobby;
  Packet : TClientPacket;
begin

  Packet := TClientPacket.Create;

  Packet.WriteStr(#$4D#$00);
  Packet.WriteUInt8(FLobbyList.Count);

  Result := Packet.ToStr;

  Packet.Free;

  for Lobby in FLobbyList do begin
    Result := Result + Lobby.Build;
  end;
end;

constructor TLobbiesList.Create;
var
  Lobby, Lobby1, Lobby2, Lobby3 : TLobby;
begin
  FLobbyList := TMyList<TLobby>.Create;

  Lobby := TLobby.Create('Free#1' ,300);
  Lobby.LobbyID := FLobbyList.Add(Lobby);

  Lobby1 := TLobby.Create('Free#2' ,300);
  Lobby1.LobbyID := FLobbyList.Add(Lobby1);

  Lobby2 := TLobby.Create('Free#3' ,300);
  Lobby2.LobbyID := FLobbyList.Add(Lobby2);

  Lobby3 := TLobby.Create('Free#4' ,300);
  Lobby3.LobbyID := FLobbyList.Add(Lobby3);
end;

destructor TLobbiesList.Destroy;
begin
  DestroyLobbies;
  FLobbyList.Free;
  inherited;
end;

procedure TLobbiesList.DestroyLobbies;
var
  Lobby : TLobby;
begin
  for Lobby in FLobbyList do begin
    Lobby.Free;
  end;
end;


function TLobbiesList.GetLobby(LobbyID: UInt8): TLobby;
begin
  for Result in Self.FLobbyList do
    if Result.LobbyID = LobbyID then
      Exit;

  Exit(nil);
end;

initialization
  begin
    LobbyLists := TLobbiesList.Create;
  end;

finalization
  begin
    LobbyLists.Free;
  end;

end.
