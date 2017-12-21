unit IffManager.Mascot;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type

  PIffMascot = ^TIffMascot;

  TIffMascot = packed record
    var Base: TBaseIff;
    var MPet: array[$0..$27] of AnsiChar;
    var Texture: array[$0..$27] of AnsiChar;
    var Price1: UInt16;
    var Price7: UInt32;
    var Price30: UInt32;
    var C0, C1, C2, C3, C4: UInt8;
    var Slot1, Slot2, Slot3, Slot4, Slot5: UInt8;
    var Effect1, Effect2, Effect3: UInt32;
    var Un1, Un2: UInt16;
  end;

  TIffMascots = class
    private
      FMascot: TDictionary<UInt32, PIffMascot>;
    public
      constructor Create;
      destructor Destroy; override;
      function IsExist(TypeId: UInt32): Boolean;
      function GetItemName(TypeId: UInt32): AnsiString;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeId: UInt32; ADay: UInt32): UInt32;
      function LoadItem(TypeId: UInt32; var Mascot: PIffMascot): Boolean;
      property MascotData: TDictionary<UInt32, PIffMascot> read FMascot;
  end;

implementation

{ TIffMascots }

constructor TIffMascots.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Item : PIffMascot;
begin
  FMascot := TDictionary<UInt32, PIffMascot>.Create;

  if not FileExists('data\Mascot.iff') then begin
    WriteConsole(' data\Mascot.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\Mascot.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 0 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base.Enabled, SizeOf(TIffMascot));
      FMascot.Add(Item.Base.TypeID, Item);
    end;
  finally
    Packet.Free;
  end;
end;

destructor TIffMascots.Destroy;
var
  Items : PIffMascot;
begin
  for Items in FMascot.Values do
  begin
    Dispose(Items);
  end;
  FMascot.Clear;
  FreeAndNil(FMascot);
  inherited;
end;

function TIffMascots.GetItemName(TypeId: UInt32): AnsiString;
var
  Items : PIffMascot;
begin
  if not LoadItem(TypeId, Items) then Exit;
  Exit(Items.Base.Name);
end;

function TIffMascots.GetPrice(TypeId, ADay: UInt32): UInt32;
var
  Items : PIffMascot;
begin
  if not LoadItem(TypeId, Items) then Exit(0);

  if (Items.Base.Enabled = 1) then
  begin
    case ADay of
      1:
        begin
          Exit(Items.Price1);
        end;
      7:
        begin
          Exit(Items.Price7);
        end;
      30:
        begin
          Exit(Items.Price30);
        end;
    end;
    if (Items.Price1 = 0) and (Items.Price7 = 0) and (Items.Price30 = 0) then
    begin
      Exit(Items.Base.ItemPrice);
    end;
    Exit(0);
  end;
  Exit(0);
end;

function TIffMascots.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Items : PIffMascot;
begin
  if not LoadItem(TypeId, Items) then Exit(-1);

  if (Items.Base.Enabled = 1) then
  begin
    Exit(Items.Base.PriceType);
  end;

  Exit(-1);
end;

function TIffMascots.IsBuyable(TypeId: UInt32): Boolean;
var
  Items : PIffMascot;
begin
  if not LoadItem(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) and (Items.Base.ItemFlag and 1 <> 0) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffMascots.IsExist(TypeId: UInt32): Boolean;
var
  Items : PIffMascot;
begin
  if not LoadItem(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffMascots.LoadItem(TypeId: UInt32; var Mascot: PIffMascot): Boolean;
begin
  if not FMascot.TryGetValue(TypeId, Mascot) then
  begin
    Exit(False);
  end;
  Exit(True);
end;

end.
