unit uCaddie;

interface

uses
  ClientPacket, Tools, Math, DateUtils, SysUtils, MyList, XSuperObject;

type
  PCaddie = ^TPlayerCaddies;

  TPlayerCaddies = packed record
    var CaddieIdx : UInt32;
    var CaddieTypeId : UInt32;
    var CaddieSkin : UInt32;
    var CaddieSkinEndDate: TDateTime;
    var CaddieLevel : UInt8;
    var CaddieExp : UInt32;
    var CaddieType : UInt8;
    var CaddieDay : UInt16;
    var CaddieSkinDay : UInt16;
    var CaddieUnknown : UInt8;
    var CaddieAutoPay : UInt16;
    var CaddieDateEnd: TDateTime;
    var CaddieNeedUpdate: Boolean;
    function GetCaddieInfo: AnsiString;
    procedure UpdateCaddieSkin(SkinTypeId: UInt32; Period: UInt32);
    function GetSQLUpdateString: String;
  end;

  TSerialCaddies = class(TMyList<PCaddie>)
    private
    public
      constructor Create;
      destructor Destroy; override;
      function GetCaddie: AnsiString;
      function Add( Const Value : PCaddie ): Integer;
      function IsExist(TypeId: UInt32): Boolean;
      function CanHaveSkin(SkinTypeId: UInt32): Boolean;
      function GetCaddieBySkinId(SkinTypeId: UInt32): PCaddie;
      function GetCaddieByIndex(Index: UInt32): PCaddie;
      function GetSQLUpdateString: String;
      function GetSQLUpdateJSON: AnsiString;
  end;

implementation

{ TPlayerCaddies }

function TPlayerCaddies.GetCaddieInfo: AnsiString;
var
  Packet : TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteUInt32(CaddieIdx);
    Packet.WriteUInt32(CaddieTypeId);
    Packet.WriteUInt32(CaddieSkin);
    Packet.WriteUInt8(CaddieLevel);
    Packet.WriteUInt32(CaddieExp);
    Packet.WriteUInt8(CaddieType);
    Packet.WriteUInt16(CaddieDay);
    Packet.WriteUInt16(CaddieSkinDay);
    Packet.WriteStr(#$00);
    Packet.WriteUInt16(CaddieAutoPay);
    Result := Packet.ToStr;
  finally
    FreeAndNil(Packet);
  end;
end;

function TPlayerCaddies.GetSQLUpdateString: String;
var
  SQLString: TStringBuilder;
begin
  SQLString := TStringBuilder.Create;
  try
    SQLString.Append('^');
    SQLString.Append(CaddieIdx);
    SQLString.Append('^');
    SQLString.Append(CaddieSkin);
    SQLString.Append('^');
    SQLString.Append(GetSQLTime(CaddieSkinEndDate));
    SQLString.Append('^');
    SQLString.Append(CaddieAutoPay);
    SQLString.Append(','); // close for next player
    Exit(SQLString.ToString);
  finally
    FreeAndNil(SQLString);
  end;
end;

procedure TPlayerCaddies.UpdateCaddieSkin(SkinTypeId, Period: UInt32);
begin
  CaddieNeedUpdate := True;

  CaddieSkin := SkinTypeId;

  if IsZero(CaddieSkinEndDate) OR (CaddieSkinEndDate < Now() ) then
  begin
    CaddieSkinEndDate := IncDay(Now(), Period);
    Exit;
  end;

  CaddieSkinEndDate := IncDay(CaddieSkinEndDate, Period);
end;

{ TSerialCaddies }

function TSerialCaddies.Add(const Value: PCaddie): Integer;
begin
  Value.CaddieNeedUpdate := False;
  Exit(inherited Add(Value));
end;

constructor TSerialCaddies.Create;
begin
  inherited;
end;

destructor TSerialCaddies.Destroy;
var
  CaddieInfo : PCaddie;
begin
  for CaddieInfo in self do
  begin
    Dispose(CaddieInfo);
  end;
  Clear;
  inherited;
end;

function TSerialCaddies.GetCaddie: AnsiString;
var
  CaddieInfo : PCaddie;
begin
  for CaddieInfo in self do
  begin
    Result := Result + CaddieInfo.GetCaddieInfo;
  end;
end;

function TSerialCaddies.IsExist(TypeId: UInt32): Boolean;
var
  CaddieInfo : PCaddie;
begin
  for CaddieInfo in Self do
  begin
    if (CaddieInfo.CaddieTypeId = TypeId) then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

function TSerialCaddies.CanHaveSkin(SkinTypeId: UInt32): Boolean;
var
  CaddieInfo : PCaddie;
begin
  for CaddieInfo in Self do
  begin
    if CaddieInfo.CaddieTypeId = GetCaddieTypeIDBySkinID(SkinTypeId)  then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

function TSerialCaddies.GetCaddieByIndex(Index: UInt32): PCaddie;
var
  CaddieInfo : PCaddie;
begin
  for CaddieInfo in Self do
  begin
    if CaddieInfo.CaddieIdx = Index then
    begin
      Exit(CaddieInfo);
    end;
  end;
  Exit(nil);
end;

function TSerialCaddies.GetCaddieBySkinId(SkinTypeId: UInt32): PCaddie;
var
  CaddieInfo : PCaddie;
begin
  for CaddieInfo in Self do
  begin
    if CaddieInfo.CaddieTypeId = GetCaddieTypeIDBySkinID(SkinTypeId)  then
    begin
      Exit(CaddieInfo);
    end;
  end;
  Exit(nil);
end;

function TSerialCaddies.GetSQLUpdateJSON: AnsiString;
var
  JSON, NestJS: ISuperObject;
  Caddies : PCaddie;
begin
  JSON := SO;
  for Caddies in Self do
  begin
    if Caddies.CaddieNeedUpdate then
    begin
      Caddies.CaddieNeedUpdate := False;
      NestJS := SO;
      NestJS.I['CaddieIndex'] := Caddies.CaddieIdx;
      NestJS.I['CaddieSkin'] := Caddies.CaddieSkin;
      NestJS.D['CaddieSkinEndDate'] := Caddies.CaddieSkinEndDate;
      NestJS.I['CaddieAutoPay'] := Caddies.CaddieAutoPay;
      JSON.A['Caddies'].Add(NestJS);
    end;
  end;
  Exit(AnsiString(JSON.AsJSON()));
end;

function TSerialCaddies.GetSQLUpdateString: String;
var
  CaddieInfo : PCaddie;
  StringBuilder: TStringBuilder;
begin
  StringBuilder := TStringBuilder.Create;
  try
    for CaddieInfo in Self do
    begin
      if CaddieInfo.CaddieNeedUpdate then
      begin
        StringBuilder.Append(CaddieInfo.GetSQLUpdateString);
        // update to false when get string
        CaddieInfo.CaddieNeedUpdate := False;
      end;
    end;
    Exit(StringBuilder.ToString);
  finally
    FreeAndNil(StringBuilder);
  end;
end;

end.
