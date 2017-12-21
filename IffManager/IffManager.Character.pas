unit IffManager.Character;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Defines, Enum;

type

  PIffCharacter = ^TIffCharacter;

  TIffCharacter = packed record
    var Base: TBaseIff;
    var MPet: array[$0..$27] of AnsiChar;
    var Texture1: array[$0..$27] of AnsiChar;
    var Texture2: array[$0..$27] of AnsiChar;
    var Texture3: array[$0..$27] of AnsiChar;
    var C0, C1, C2, C3, C4: UInt16;
    var Slot1, Slot2, Slot3, Slot4, Slot5: UInt8;
    var Un1: UInt8;
    var MasteryProb: Single;
    var Stat1, Stat2, Stat3, Stat4, Stat5: UInt8;
    var Texture4: array[$0..$27] of AnsiChar;
    var Un2: array[$0..$2] of AnsiChar;
  end;

  TIffCharacters = class
    private
      var FCharacter: TDictionary<UInt32, PIffCharacter>;
    public
      constructor Create;
      destructor Destroy; override;

      function IsExist(TypeId: UInt32): Boolean;
      function GetItemName(TypeId: UInt32): AnsiString;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeId: UInt32): UInt32;

      function LoadCharacter(ID: UInt32; var Char: PIffCharacter): Boolean;
  end;

implementation

{ TIffCharacters }

constructor TIffCharacters.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Item : PIffCharacter;
  Name: AnsiString;
begin
  FCharacter := TDictionary<UInt32, PIffCharacter>.Create;

  if not FileExists('data\Character.iff') then begin
    WriteConsole(' data\Character.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\Character.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 1 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base.Enabled, SizeOf(TIffCharacter));
      FCharacter.Add(Item.Base.TypeID, Item);
    end;
  finally
    Packet.Free;
  end;
end;

destructor TIffCharacters.Destroy;
var
  Items : PIffCharacter;
begin
  for Items in FCharacter.Values do
  begin
    Dispose(Items);
  end;
  FCharacter.Clear;
  FreeAndNil(FCharacter);
  inherited;
end;

function TIffCharacters.GetItemName(TypeId: UInt32): AnsiString;
var
  Char : PIffCharacter;
begin
  if not LoadCharacter(TypeId, Char) then Exit(Nulled);

  Exit(Char.Base.Name);
end;

function TIffCharacters.GetPrice(TypeId: UInt32): UInt32;
var
  Char : PIffCharacter;
begin
  if not LoadCharacter(TypeId, Char) then Exit(0);

  if (Char.Base.Enabled = 1) then
  begin
    Exit(Char.Base.ItemPrice);
  end;
  Exit(0);
end;

function TIffCharacters.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Char : PIffCharacter;
begin
  if not LoadCharacter(TypeId, Char) then Exit(-1);
  if (Char.Base.Enabled = 1) then
  begin
    Exit(Char.Base.PriceType);
  end;
  Exit(-1);
end;

function TIffCharacters.IsBuyable(TypeId: UInt32): Boolean;
var
  Char : PIffCharacter;
begin
  if not LoadCharacter(TypeId, Char) then Exit(False);
  if (Char.Base.Enabled = 1) and (Char.Base.ItemFlag AND 1 <> 0) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffCharacters.IsExist(TypeId: UInt32): Boolean;
var
  Char : PIffCharacter;
begin
  if not LoadCharacter(TypeId, Char) then Exit(False);
  if (Char.Base.Enabled = 1) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffCharacters.LoadCharacter(ID: UInt32; var Char: PIffCharacter): Boolean;
begin
  if not FCharacter.TryGetValue(UInt32(ID), Char) then
  begin
    Exit(False);
  end;
  Exit(True);
end;

end.
