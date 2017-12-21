unit IffManager.CaddieItem;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type
  PIffCaddieItem = ^TIffCaddieItem;

  TIffCaddieItem = packed record
    var Base: TBaseIff;
    var MPet: array[$0..$27] of AnsiChar;
    var Texture: array[$0..$27] of AnsiChar;
    var Price1: UInt32;
    var Price15, Price30: UInt16;
    var Un1: UInt32;
  end;

  TIffCaddieItems = class(TList<PIffCaddieItem>)
    public
      constructor Create;
      destructor Destroy; override;
      function IsExist(TypeId: UInt32): Boolean;
      function GetItemName(TypeId: UInt32): AnsiString;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeId: UInt32; ADay: UInt32): UInt32;
  end;

implementation

{ TIffCaddieItems }

constructor TIffCaddieItems.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Item : PIffCaddieItem;
begin
  inherited;

  if not FileExists('data\CaddieItem.iff') then begin
    WriteConsole(' data\CaddieItem.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\CaddieItem.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 0 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base.Enabled, SizeOf(TIffCaddieItem));
      Add(Item);
    end;
  finally
    Packet.Free;
  end;

end;

destructor TIffCaddieItems.Destroy;
var
  Items : PIffCaddieItem;
begin
  for Items in self do
  begin
    Dispose(Items);
  end;
  Clear;
  inherited;
end;

function TIffCaddieItems.GetItemName(TypeId: UInt32): AnsiString;
var
  Items : PIffCaddieItem;
begin
  for Items in Self do
  begin
    if Items.Base.TypeID = TypeId then
    begin
      Exit(Items.Base.Name);
    end;
  end;
end;

function TIffCaddieItems.GetPrice(TypeId: UInt32; ADay: UInt32): UInt32;
var
  Items : PIffCaddieItem;
begin
  for Items in Self do
  begin
    if (Items.Base.TypeID = TypeId) and (Items.Base.Enabled = 1) then
    begin
      case ADay of
        1:
          begin
            Exit(Items.Price1);
          end;
        15:
          begin
            Exit(Items.Price15);
          end;
        30:
          begin
            Exit(Items.Price30);
          end;
      end;
      if (Items.Price1 = 0) and (Items.Price15 = 0) and (Items.Price30 = 0) then
      begin
        Exit(Items.Base.ItemPrice);
      end;
      Exit(0);
    end;
  end;
  Exit(0);
end;

function TIffCaddieItems.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Items : PIffCaddieItem;
begin
  for Items in Self do
  begin
    if (Items.Base.TypeID = TypeId) and (Items.Base.Enabled = 1) then
    begin
      Exit(Items.Base.PriceType);
    end;
  end;
  Exit(-1);
end;

function TIffCaddieItems.IsBuyable(TypeId: UInt32): Boolean;
var
  Items : PIffCaddieItem;
begin
  for Items in Self do
  begin
    if (Items.Base.TypeID = TypeId) and (Items.Base.Enabled = 1) and (Items.Base.ItemFlag AND 1 <> 0) then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

function TIffCaddieItems.IsExist(TypeId: UInt32): Boolean;
var
  Items : PIffCaddieItem;
begin
  for Items in Self do
  begin
    if (Items.Base.TypeID = TypeId) AND (Items.Base.Enabled = 1) then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

end.
