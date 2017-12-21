unit uCharacter;

interface

uses
  ClientPacket, MyList, SysUtils, XSuperObject, Defines, uCardEquip;

const
  POWPANG : UInt32 = 2100;
  CONPANG : UInt32 = 1700;
  IMPPANG : UInt32 = 2400;
  SPINPANG: UInt32 = 1900;
  CURVPANG: UInt32 = 1900;

type
  PCharacter = ^TCharacterInfo;

  TCharacterInfo = packed record
    var TypeID : UInt32;
    var Index : UInt32;
    var HairColour : UInt16;
    var GiftFlag : UInt16;

    var EquipTypeID: array[$0..$17] of UInt32;
    var EquipIndex: array[$0..$17] of UInt32;

    var FLRingTypeID : UInt32;
    var FRRingTypeID : UInt32;
    var FCutinIndex: UInt32;
    var Power, Control, Impact, Spin, Curve, MasteryPoint : UInt8;
    var NEEDUPDATE : Boolean;

    procedure Clear;
    function GetTypeID : UInt32;
    function GetPangUpgrade(Slot: UInt8): UInt32;
    function UpgradeSlot(Slot: UInt8): Boolean;
    function DowngradeSlot(Slot: UInt8): Boolean;
  end;

  TSerialCharacter = class(TMyList<PCharacter>)
    private
      var fCard: TSerialEquipCard;
    public
      constructor Create;
      destructor Destroy; override;
      function Add(Const Value : PCharacter): Integer;
      function GetChar(ID: UInt32; GetType: gCharType): PCharacter;
      function GetCharData: AnsiString; overload;
      function GetCharData(CID: UInt32): AnsiString; overload;
      function CreateChar(CharData: PCharacter; CardData: AnsiString): AnsiString;
      function GetSQLUpdateJSON: AnsiString;
      property sCard: TSerialEquipCard read fCard write fCard;
  end;

implementation

{ TCharacterInfo }

procedure TCharacterInfo.Clear;
begin
  FillChar(TypeID, SizeOf(TCharacterInfo), 0);
end;

function TCharacterInfo.GetTypeID: UInt32;
begin
  Exit(Self.TypeID);
end;

function TCharacterInfo.UpgradeSlot(Slot: UInt8): Boolean;
begin
  case Slot of
    0:
      Inc(Self.Power, 1);
    1:
      Inc(Self.Control, 1);
    2:
      Inc(Self.Impact, 1);
    3:
      Inc(Self.Spin, 1);
    4:
      Inc(Self.Curve, 1);
  else
    Exit(False)
  end;

  Self.NEEDUPDATE := True;
  Exit(True);
end;

function TCharacterInfo.DowngradeSlot(Slot: UInt8): Boolean;
begin
  case Slot of
    0:
      begin
        if (Self.Power <= 0) then Exit(False);
        Dec(Self.Power, 1);
      end;
    1:
      begin
        if (Self.Control <= 0) then Exit(False);
        Dec(Self.Control, 1);
      end;
    2:
      begin
        if (Self.Impact <= 0) then Exit(False);
        Dec(Self.Impact, 1);
      end;
    3:
      begin
        if (Self.Spin <= 0) then Exit(False);
        Dec(Self.Spin, 1);
      end;
    4:
      begin
        if (Self.Curve <= 0) then Exit(False);
        Dec(Self.Curve, 1);
      end;
  end;

  Self.NEEDUPDATE := True;
  Exit(True);
end;

function TCharacterInfo.GetPangUpgrade(Slot: UInt8): UInt32;
begin
  case Slot of
    0:
      begin
        Exit( (Self.Power * POWPANG) + POWPANG );
      end;
    1:
      begin
        Exit( (Self.Control * CONPANG) + CONPANG );
      end;
    2:
      begin
        Exit( (Self.Impact * IMPPANG) + IMPPANG );
      end;
    3:
      begin
        Exit( (Self.Spin * SPINPANG) + SPINPANG );
      end;
    4:
      begin
        Exit( (Self.Curve * CURVPANG) + CURVPANG );
      end;
  end;

  Exit(0);
end;

{ TSerialCharacter }

function TSerialCharacter.Add(const Value: PCharacter): Integer;
begin
  Value.NEEDUPDATE := False;
  Exit(inherited Add(Value));
end;

constructor TSerialCharacter.Create;
begin
  inherited;

  fCard := TSerialEquipCard.Create;
end;

function TSerialCharacter.CreateChar(CharData: PCharacter; CardData: AnsiString): AnsiString;
var
  Packet: TClientPacket;
  Index: UInt32;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteUInt32(CharData.TypeID);
    Packet.WriteUInt32(CharData.Index);
    Packet.WriteUInt16(CharData.HairColour);
    Packet.WriteUInt16(CharData.GiftFlag);

    for Index := 0 to $17 do
    begin
      Packet.WriteUInt32(CharData.EquipTypeID[Index]);
    end;

    for Index := 0 to $17 do
    begin
      Packet.WriteUInt32(CharData.EquipIndex[Index]);
    end;

    Packet.WriteStr(#$00, $D8);

    //Packet.WriteUInt32(leftRing);
    //Packet.WriteUInt32(rightRing);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(0);

    Packet.WriteStr(
      #$00#$00#$00#$00 +
      #$00#$00#$00#$00 +
      #$00#$00#$00#$00
    );

    Packet.WriteUInt32(CharData.FCutinIndex); // CUTIN IDX

    Packet.WriteStr(
      #$00#$00#$00#$00 +
      #$00#$00#$00#$00 +
      #$00#$00#$00#$00
    );

    Packet.WriteUInt8(CharData.Power);
    Packet.WriteUInt8(CharData.Control);
    Packet.WriteUInt8(CharData.Impact);
    Packet.WriteUInt8(CharData.Spin);
    Packet.WriteUInt8(CharData.Curve);
    Packet.WriteUInt8(CharData.MasteryPoint);

    Packet.WriteStr(#$00, $3);
    Packet.WriteStr(CardData, 40);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(0);

    Result := Packet.ToStr;
  finally
    Packet.Free;
  end;
end;

destructor TSerialCharacter.Destroy;
var
  CharacterInfo : PCharacter;
begin
  for CharacterInfo in self do
  begin
    Dispose(CharacterInfo);
  end;
  Clear;
  fCard.Free;
  inherited;
end;

function TSerialCharacter.GetChar(ID: UInt32; GetType: gCharType): PCharacter;
var
  Char: PCharacter;
begin
  case GetType of
    bTypeID:
      begin
        for Char in Self do
        begin
          if Char.TypeID = ID then
          begin
            Exit(Char);
          end;
        end;
        Exit(nil);
      end;
    bIndex:
      begin
        for Char in Self do
        begin
          if Char.Index = ID then
          begin
            Exit(Char);
          end;
        end;
        Exit(nil);
      end;
  end;
  Exit(nil);
end;

function TSerialCharacter.GetCharData(CID: UInt32): AnsiString;
var
  Char: PCharacter;
begin
  for Char in Self do
    if Char.Index = CID then
      Exit(Self.CreateChar(Char, Self.fCard.MapCard(Char.Index)));

  Exit;
end;

function TSerialCharacter.GetCharData: AnsiString;
var
  Packet: TClientPacket;
  Char: PCharacter;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$70#$00);
    Packet.WriteUInt16(Self.Count);
    Packet.WriteUInt16(Self.Count);

    for Char in Self do
    begin
      Packet.WriteStr(Self.CreateChar(Char, Self.fCard.MapCard(Char.Index)));
    end;

    Exit(Packet.ToStr);
  finally
    FreeAndNil(Packet);
  end;
end;

function TSerialCharacter.GetSQLUpdateJSON: AnsiString;
var
  JSON, NestJSON: ISuperObject;
  Char: PCharacter;
  Index: Byte;
begin
  JSON := SO;
  for Char in Self do
  begin
    if Char.NEEDUPDATE then
    begin
      Char.NEEDUPDATE := False;
      NestJSON := SO;
      NestJSON.I['CharIndex'] := Char.Index;
      NestJSON.I['C0'] := Char.Power;
      NestJSON.I['C1'] := Char.Control;
      NestJSON.I['C2'] := Char.Impact;
      NestJSON.I['C3'] := Char.Spin;
      NestJSON.I['C4'] := Char.Curve;

      { EQUIP TYPEID }
      for Index := 0 to Length(Char.EquipTypeID) - 1 do
      begin
        NestJSON.I[Format('EquipTypeID%d',[Index])] := Char.EquipTypeID[Index];
      end;

      { EQUIP INDEX }
      for Index := 0 to Length(Char.EquipIndex) - 1 do
      begin
        NestJSON.I[Format('EquipIndex%d',[Index])] := Char.EquipIndex[Index];
      end;

      JSON.A['Char'].Add(NestJSON);
    end;
  end;
  Exit(AnsiString(JSON.AsJSON()));
end;

end.
