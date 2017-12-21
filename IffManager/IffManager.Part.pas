unit IffManager.Part;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type

  PIffPart = ^TIffPart;

  TIffPart = packed record
    var Base: TBaseIff;
    var MPet: array[$0..$27] of AnsiChar;
    var UCCType: UInt32;
    var SlotCount: UInt32;
    var Un1: UInt32;
    var Texture1: array[$0..$27] of AnsiChar;
    var Texture2: array[$0..$27] of AnsiChar;
    var Texture3: array[$0..$27] of AnsiChar;
    var Texture4: array[$0..$27] of AnsiChar;
    var Texture5: array[$0..$27] of AnsiChar;
    var Texture6: array[$0..$27] of AnsiChar;
    var C0, C1, C2, C3, C4: UInt16;
    var Slot1, Slot2, Slot3, Slot4, Slot5: UInt16;
    var Blank: array[$0..$2F] of AnsiChar;
    var Un2, Un3: UInt32;
    var RentPang: UInt32;
    var Un4: UInt32;
  end;

  TIffParts = class
    private
      var FPart: TDictionary<UInt32, PIffPart>;
    public
      constructor Create;
      destructor Destroy; override;
      function GetItemName(TypeId: UInt32): AnsiString;
      function IsExist(TypeId: UInt32): Boolean;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeId: UInt32): UInt32;
      function LoadItem(TypeId: UInt32; var PartItem: PIffPart): Boolean;
      function GetRentalPrice(TypeID: UInt32): UInt32;
      property PartData: TDictionary<UInt32, PIffPart> read FPart;
  end;

implementation

{ TIffParts }

constructor TIffParts.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Item : PIffPart;
  Total, Count : UInt32;
begin
  FPart := TDictionary<UInt32, PIffPart>.Create;

  if not FileExists('data\Part.iff') then begin
    WriteConsole(' data\Part.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\Part.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 1 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base.Enabled, SizeOf(TIffPart));
      FPart.Add(Item.Base.TypeID ,Item);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TIffParts.Destroy;
var
  Item: PIffPart;
begin
  for Item in FPart.Values do
  begin
    Dispose(Item);
  end;
  FPart.Clear;
  FreeAndNil(FPart);
  inherited;
end;

function TIffParts.GetItemName(TypeId: UInt32): AnsiString;
var
  Items : PIffPart;
begin
  if not LoadItem(TypeId, Items) then Exit;
  Exit(Items.Base.Name);
end;

function TIffParts.GetPrice(TypeId: UInt32): UInt32;
var
  Items : PIffPart;
begin
  if not LoadItem(TypeId, Items) then Exit(0);
  if (Items.Base.Enabled = 1) then
  begin
    Exit(Items.Base.ItemPrice);
  end;
  Exit(0);
end;

function TIffParts.GetRentalPrice(TypeID: UInt32): UInt32;
var
  Items : PIffPart;
begin
  if not LoadItem(TypeId, Items) then Exit(0);

  if (Items.Base.Enabled = 1) then
    Exit(Items.RentPang);

  Exit(0);
end;

function TIffParts.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Items : PIffPart;
begin
  if not LoadItem(TypeId, Items) then Exit(-1);
  if (Items.Base.Enabled = 1) then
  begin
    Exit(Items.Base.PriceType);
  end;

  Exit(-1);
end;

function TIffParts.IsBuyable(TypeId: UInt32): Boolean;
var
  Items : PIffPart;
begin
  if not LoadItem(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) and (Items.Base.ItemFlag and 1 <> 0) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffParts.IsExist(TypeId: UInt32): Boolean;
var
  Items : PIffPart;
begin
  if not LoadItem(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffParts.LoadItem(TypeId: UInt32; var PartItem: PIffPart): Boolean;
begin
  if not FPart.TryGetValue(TypeId, PartItem) then
  begin
    Exit(False);
  end;
  Exit(True);
end;

end.
