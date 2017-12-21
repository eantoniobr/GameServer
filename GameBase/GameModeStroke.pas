unit GameModeStroke;

interface

uses
  System.SysUtils, GameBase, PangyaClient, Enum, Defines, ClientPacket, Tools,
  PacketCreator;

type
  TGameStroke = class(TGameBase)
    protected
      procedure SendPlayerOnCreate(const PL: TClientPlayer); override;
      procedure SendPlayerOnJoin(const PL: TClientPlayer); override;
      procedure OnPlayerLeave; override;
      function Validate: Boolean; override;
    public
      function GameInformation: AnsiString; override;
      constructor Create(const PL: TClientPlayer; GameData: TGameInfo;
        CreateEvent, UpdateEvent, DestroyEvent: fGameEvent;
        OnJoin, OnLeave: fPlayerEvent; GameID: UInt16);
      destructor Destroy; override;
  end;

implementation

{ TGameChat }

constructor TGameStroke.Create(const PL: TClientPlayer; GameData: TGameInfo;
  CreateEvent, UpdateEvent, DestroyEvent: fGameEvent;
  OnJoin, OnLeave: fPlayerEvent; GameID: UInt16);
begin
  inherited Create(PL, GameData, CreateEvent, UpdateEvent, DestroyEvent, Onjoin, OnLeave, GameID);

end;

destructor TGameStroke.Destroy;
begin

  inherited;
end;

function TGameStroke.GameInformation: AnsiString;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(Self.fGameData.Name, $28);
      WriteStr(#$00, $18);
      WriteUInt8(TCompare.IfCompare(Length(Self.fGameData.Password) > 0, 0, 1));
      WriteUInt8(TCompare.IfCompare(fStarted, 0, 1));
      WriteStr(#$00); { orange }
      WriteUInt8(Self.fGameData.MaxPlayer);
      WriteUInt8(UInt8(Self.fPlayers.Count));
      Write(fGameKey[0], 16);
      WriteStr(#$00#$1E);
      WriteUInt8(Self.fGameData.HoleTotal);
      WriteUInt8(UInt8(Self.fGameData.GameType));
      WriteUInt16(fID);
      WriteUInt8(Self.fGameData.Mode);
      WriteUInt8(Self.fGameData.Map);
      WriteUInt32(Self.fGameData.VSTime);
      WriteUInt32(Self.fGameData.GameTime);
      WriteUInt32(Self.fTrophy); { trophy }
      WriteUInt8(Self.fIdle);
      WriteUInt8(TCompare.IfCompare(Self.fGameData.GMEvent, $1 , $0)); { is gm }
      WriteStr(#$00, $4A);
      WriteStr(#$64#$00#$00#$00#$64#$00#$00#$00);
      WriteUInt32(fOwner); { owner uid }
      WriteUInt8($FF); { is practise }
      WriteUInt32(Self.fGameData.Artifact); { artifact }
      WriteUInt32(Self.fGameData.NaturalMode);
      WriteUInt32(Self.fGameData.GPTypeID);
      WriteUInt32(Self.fGameData.GPTypeIDA);
      WriteUInt32(Self.fGameData.GPTime);
      WriteUInt32(TCompare.IfCompare(Self.fGameData.GP, 1, 0));
      Exit(ToStr);
    end;
  finally
    Packet.Free;
  end;
end;

procedure TGameStroke.OnPlayerLeave;
begin
  inherited;
  { This chat class is do nothing }
end;

procedure TGameStroke.SendPlayerOnCreate(const PL: TClientPlayer);
var
  Packet: TClientPacket;
begin
  inherited;
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$48#$00);
      WriteUInt8(0);
      WriteStr(#$FF#$FF);
      WriteUInt8(Self.fPlayers.Count);
      WriteStr(PL.GetGameInfomations(2));
      WriteUInt8(0);
    end;
    Self.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure TGameStroke.SendPlayerOnJoin(const PL: TClientPlayer);
var
  Packet: TClientPacket;
  P: TClientPlayer;
begin
  inherited;
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$48#$00);
      WriteUInt8(0);
      WriteStr(#$FF#$FF);
      WriteUInt8(Self.fPlayers.Count);
      for P in Self.fPlayers do
      begin
        WriteStr(P.GetGameInfomations(2));
      end;
      WriteUInt8(0);
    end;
    PL.Send(Packet);

    with Packet do
    begin
      Clear;
      WriteStr(#$48#$00);
      WriteUInt8(1);
      WriteStr(#$FF#$FF);
      WriteStr(PL.GetGameInfomations(2));
    end;
    Self.Send(Packet);
  finally
    Packet.Free;
  end;
end;

function TGameStroke.Validate: Boolean;
begin
  if (Self.fGameData.MaxPlayer > 4) then
  begin
    Exit(False);
  end;

  Exit(True);
end;

end.
