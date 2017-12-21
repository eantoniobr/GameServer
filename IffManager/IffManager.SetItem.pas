unit IffManager.SetItem;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type

  PIffSetItem = ^TIffSetItem;

  TIffSetItem = packed record
    var Base: TBaseIff;
    var Total : UInt32;
    var TypeIff: Array[0..9] of UInt32;
    var QtyIff: Array[0..9] of UInt16;
    var Un1: array[$0..$B] of AnsiChar;
  end;

  TIffSetItems = class
    private
      FSetItem: TDictionary<UInt32, PIffSetItem>;
    public
      constructor Create;
      destructor Destroy; override;
      function GetItemName(TypeId: UInt32): AnsiString;
      function IsExist(TypeId: UInt32): Boolean;
      function GetSetItemStr(TypeId: UInt32): AnsiString;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeId: UInt32): UInt32;
      function LoadSetItem(TypeId: UInt32; var SetItem: PIffSetItem): Boolean;
      property FItemSet: TDictionary<UInt32, PIffSetItem> read FSetItem;
      function SetList(TypeID: UInt32): TList<TPair<UInt32, UInt32>>;
  end;

implementation

{ TIffSetItems }

constructor TIffSetItems.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Item : PIffSetItem;
  Total, Count : UInt32;
  IffCount, QtyCount: UInt32;
begin
  FSetItem := TDictionary<UInt32, PIffSetItem>.Create;

  if not FileExists('data\SetItem.iff') then begin
    WriteConsole(' data\Item.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\SetItem.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 0 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base.Enabled, SizeOf(TIffSetItem));
      // Add to setitem database
      FSetItem.Add(Item.Base.TypeID, Item);
    end;
  finally
    Packet.Free;
  end;

end;

destructor TIffSetItems.Destroy;
var
  Item : PIffSetItem;
begin
  for Item in FSetItem.Values do
  begin
    Dispose(Item);
  end;
  FSetItem.Clear;
  FreeAndNil(FSetItem);
  inherited;
end;

function TIffSetItems.GetItemName(TypeId: UInt32): AnsiString;
var
  Items : PIffSetItem;
begin
  if not LoadSetItem(TypeId, Items) then Exit;
  Exit(Items.Base.Name);
end;

function TIffSetItems.GetPrice(TypeId: UInt32): UInt32;
var
  Items : PIffSetItem;
begin
  if not LoadSetItem(TypeId, Items) then Exit(0);

  if (Items.Base.Enabled = 1) then
  begin
    Exit(Items.Base.ItemPrice);
  end;
  Exit(0);
end;

function TIffSetItems.GetSetItemStr(TypeId: UInt32): AnsiString;
var
  Items : PIffSetItem;
  Count: UInt32;
begin
  if not LoadSetItem(TypeId, Items) then Exit;

  if (Items.Base.Enabled = 1) then
  begin
    for Count := 0 to 9 do
    begin
      if not(Items.TypeIff[Count] > 0) then
      begin
        Break;
      end;
      Result := Result + AnsiFormat('^%d^%d,', [Items.TypeIff[Count], Items.QtyIff[Count]]);
    end;
    Exit(Result);
  end;
  Exit('');
end;

function TIffSetItems.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Items : PIffSetItem;
begin
  if not LoadSetItem(TypeId, Items) then Exit(-1);

  if (Items.Base.Enabled = 1) then
  begin
    Exit(Items.Base.PriceType);
  end;

  Exit(-1);
end;

function TIffSetItems.IsBuyable(TypeId: UInt32): Boolean;
var
  Items : PIffSetItem;
begin
  if not LoadSetItem(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) and (Items.Base.ItemFlag and 1 <> 0) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffSetItems.IsExist(TypeId: UInt32): Boolean;
var
  Items : PIffSetItem;
begin
  if not LoadSetItem(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffSetItems.LoadSetItem(TypeId: UInt32; var SetItem: PIffSetItem): Boolean;
begin
  if not FSetItem.TryGetValue(TypeId, SetItem) then
  begin
    Exit(False);
  end;
  Exit(True);
end;

function TIffSetItems.SetList(TypeID: UInt32): TList<TPair<UInt32, UInt32>>;
var
  Items : PIffSetItem;
  Count: UInt8;
begin
  Result := TList<TPair<UInt32, UInt32>>.Create;
  if not LoadSetItem(TypeID, Items) then Exit;
  for Count := 0 to Length(Items.TypeIff) - 1 do
    if Items.TypeIff[Count] > 0 then
      Result.Add(TPair<UInt32, UInt32>.Create(Items.TypeIff[Count], Items.QtyIff[Count]));
end;

end.

