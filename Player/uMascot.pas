unit uMascot;

interface

uses
  ClientPacket, Tools, Math, DateUtils, SysUtils, MyList;

type

  PMascot = ^TPlayerMascots;

  TPlayerMascots = packed record
    var MascotIndex: UInt32;
    var MascotTypeID: UInt32;
    var MascotMessage: AnsiString;
    var MascotEndDate: TDateTime;
    var MascotIsValid: UInt8;
    var MascotNeedUpdate: Boolean;
    function GetMascotInfo: AnsiString;
    procedure AddDay(DayTotal: UInt32);
    procedure SetText(Text: AnsiString);
  end;

  TSerialMascots = class(TMyList<PMascot>)
    public
      constructor Create;
      destructor Destroy; override;
      function Add( Const Value : PMascot ): Integer;
      function GetMascotByTypeId(MascotTypeId: UInt32): PMascot;
      function GetMascotByIndex(MascotIndex: UInt32): PMascot;
      function MascotExist(TypeId: UInt32): Boolean;
  end;

implementation

{ TSerialMascots }

function TSerialMascots.Add(const Value: PMascot): Integer;
begin
  Value.MascotNeedUpdate := False;
  Exit(inherited Add(Value));
end;

constructor TSerialMascots.Create;
begin
  inherited;
end;

destructor TSerialMascots.Destroy;
var
  MascotInfo : PMascot;
begin
  for MascotInfo in self do
  begin
    Dispose(MascotInfo);
  end;
  Clear;
  inherited;
end;

function TSerialMascots.GetMascotByIndex(MascotIndex: UInt32): PMascot;
var
  Mascot: PMascot;
begin
  for Mascot in Self do
  begin
    if (Mascot.MascotIndex = MascotIndex) AND (Mascot.MascotEndDate > Now()) then
    begin
      Exit(Mascot);
    end;
  end;
  Exit(nil);
end;

function TSerialMascots.GetMascotByTypeId(MascotTypeId: UInt32): PMascot;
var
  Mascot: PMascot;
begin
  for Mascot in Self do
  begin
    if (Mascot.MascotTypeID = MascotTypeId) AND (Mascot.MascotEndDate > Now()) then
    begin
      Exit(Mascot);
    end;
  end;
  Exit(Nil);
end;

function TSerialMascots.MascotExist(TypeId: UInt32): Boolean;
var
  Mascot: PMascot;
begin
  for Mascot in Self do
  begin
    if (Mascot.MascotTypeID = TypeId) and (Mascot.MascotEndDate > Now()) then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

{ TPlayerMascots }

procedure TPlayerMascots.AddDay(DayTotal: UInt32);
begin
  Self.MascotNeedUpdate := True;

  if IsZero(Self.MascotEndDate) OR (Self.MascotEndDate < Now())  then
  begin
    Self.MascotEndDate := IncDay(Now(), DayTotal);
    Exit;
  end;

  Self.MascotEndDate := IncDay(Self.MascotEndDate, DayTotal);
end;

function TPlayerMascots.GetMascotInfo: AnsiString;
var
  Packet : TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteUInt32(Self.MascotIndex);
    Packet.WriteUInt32(Self.MascotTypeID);
    Packet.WriteStr(#$00, 5);
    Packet.WriteStr(Self.MascotMessage, 16);
    Packet.WriteStr(#$00, 14);
    Packet.WriteStr(#$01#$00);
    Packet.WriteStr(GetFixTime(Self.MascotEndDate));
    Packet.WriteStr(#$00);
    Result := Packet.ToStr;
  finally
    FreeAndNil(Packet);
  end;
end;

procedure TPlayerMascots.SetText(Text: AnsiString);
begin
  Self.MascotNeedUpdate := True;
  Self.MascotMessage := Text;
end;

end.
