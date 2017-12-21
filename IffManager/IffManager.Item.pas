unit IffManager.Item;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type

  PIffItem = ^TIffItem;

  TIffItem = packed record
    var Base: TBaseIff;
    var ItemType: UInt32;
    var MPet: array[$0..$27] of AnsiChar;
    var C0, C1, C2, C3, C4, Un1: UInt16;
  end;

  TIffItems = class
  private
    var FItemDB: TDictionary<UInt32, PIffItem>;
  public
    constructor Create;
    destructor Destroy; override;
    function IsExist(TypeId: UInt32): Boolean;
    function GetItemName(TypeId: UInt32): AnsiString;
    function IsBuyable(TypeId: UInt32): Boolean;
    function GetShopPriceType(TypeId: UInt32): ShortInt;
    function GetPrice(TypeId: UInt32): UInt32;
    function GetRealQuantity(TypeId, Qty: UInt32): UInt32;
    function LoadItem(ID: UInt32; var Item: PIffItem): Boolean;
    property FItem: TDictionary<UInt32, PIffItem> read FItemDB;
  end;

implementation

{ TIffItems }

constructor TIffItems.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Item : PIffItem;
begin
  FItemDB := TDictionary<UInt32, PIffItem>.Create;

  if not FileExists('data\Item.iff') then begin
    WriteConsole(' data\Item.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\Item.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 0 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base.Enabled, SizeOf(TIffItem));
      // Add item to TDictionary
      FItemDB.Add(Item.Base.TypeID, Item);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TIffItems.Destroy;
var
  Items : PIffItem;
begin
  for Items in FItemDB.Values do
  begin
    Dispose(Items);
  end;
  FItemDB.Clear;
  FreeAndNil(FItemDB);
  inherited;
end;

function TIffItems.GetRealQuantity(TypeId, Qty: UInt32): UInt32;
var
  Items : PIffItem;
begin
  if not LoadItem(TypeId, Items) then Exit(0);

  if (Items.Base.Enabled = 1) and (Items.C0 > 0) then
  begin
    Exit(Items.C0);
  end;

  Exit(Qty);
end;

function TIffItems.GetItemName(TypeId: UInt32): AnsiString;
var
  Items : PIffItem;
begin
  if not LoadItem(TypeId, Items) then Exit;
  Exit(Items.Base.Name);
end;

function TIffItems.GetPrice(TypeId: UInt32): UInt32;
var
  Items : PIffItem;
begin
  if not LoadItem(TypeId, Items) then Exit(99999999);

  if (Items.Base.Enabled = 1) then
  begin
    Exit(Items.Base.ItemPrice);
  end;
  Exit(0);
end;

function TIffItems.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Items : PIffItem;
begin
  if not LoadItem(TypeId, Items) then Exit(-1);
  if (Items.Base.Enabled = 1) then
  begin
    Exit(Items.Base.PriceType);
  end;
  Exit(-1);
end;

function TIffItems.IsBuyable(TypeId: UInt32): Boolean;
var
  Items : PIffItem;
begin
  if not LoadItem(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) and (Items.Base.ItemFlag AND 1 <> 0) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffItems.IsExist(TypeId: UInt32): Boolean;
var
  Items: PIffItem;
begin
  if not LoadItem(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffItems.LoadItem(ID: UInt32; var Item: PIffItem): Boolean;
begin
  if not FItemDB.TryGetValue(UInt32(ID), Item) then
  begin
    Exit(False);
  end;
  Exit(True);
end;

end.
