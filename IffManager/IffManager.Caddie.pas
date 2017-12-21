unit IffManager.Caddie;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type

  PIffCaddie = ^TIffCaddie;

  TIffCaddie = packed record
    var Base: TBaseIff;
    var Salary: UInt32;
    var MPet: array[$0..$27] of AnsiChar;
    var C0, C1, C2, C3, C4, Un1: UInt16;
  end;

  TIffCaddies = class(TList<PIffCaddie>)
    public
      constructor Create;
      destructor Destroy; override;
      function IsExist(TypeId: UInt32): Boolean;
      function GetItemName(TypeId: UInt32): AnsiString;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeId: UInt32): UInt32;
      function GetSalary(TypeId: UInt32): UInt32;
  end;

implementation

{ TIffCaddies }

constructor TIffCaddies.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Item : PIffCaddie;
begin
  inherited;

  if not FileExists('data\Caddie.iff') then begin
    WriteConsole(' data\Caddie.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\Caddie.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 0 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base, SizeOf(TIffCaddie));
      Add(Item);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TIffCaddies.Destroy;
var
  Items : PIffCaddie;
begin
  for Items in self do
  begin
    Dispose(Items);
  end;
  Clear;
  inherited;
end;

function TIffCaddies.GetItemName(TypeId: UInt32): AnsiString;
var
  Items : PIffCaddie;
begin
  for Items in Self do
  begin
    if Items.Base.TypeID = TypeId then
    begin
      Exit(Items.Base.Name);
    end;
  end;
end;

function TIffCaddies.GetPrice(TypeId: UInt32): UInt32;
var
  Items : PIffCaddie;
begin
  for Items in Self do
  begin
    if (Items.Base.TypeID = TypeId) and (Items.Base.Enabled = 1) then
    begin
      Exit(Items.Base.ItemPrice);
    end;
  end;
  Exit(0);
end;

function TIffCaddies.GetSalary(TypeId: UInt32): UInt32;
var
  Items : PIffCaddie;
begin
  for Items in Self do
  begin
    if (Items.Base.TypeID = TypeId) and (Items.Base.Enabled = 1) then
    begin
      Exit(Items.Salary);
    end;
  end;
  Exit(0);
end;

function TIffCaddies.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Items : PIffCaddie;
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

function TIffCaddies.IsBuyable(TypeId: UInt32): Boolean;
var
  Items : PIffCaddie;
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

function TIffCaddies.IsExist(TypeId: UInt32): Boolean;
var
  Items : PIffCaddie;
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
