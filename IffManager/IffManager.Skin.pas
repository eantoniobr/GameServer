unit IffManager.Skin;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type

  PIffSkin = ^TIffSkin;

  TIffSkin = packed record
    var Base: TBaseIff;
    var MPet: array[$0..$27] of AnsiChar;
    var Un1: array[$0..$B] of AnsiChar;
    var Price15, Price30, Price365: UInt32;
  end;

  TIffSkins = class
    private
      var FSkinDB: TDictionary<UInt32, PIffSkin>;
    public
      constructor Create;
      destructor Destroy; override;
      function IsExist(TypeId: UInt32): Boolean;
      function GetItemName(TypeId: UInt32): AnsiString;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeId: UInt32; ADay: UInt32): UInt32;
      function GetSkinFlag(TypeId : UInt32): UInt8;
      function LoadSkin(ID: UInt32; var Skin: PIffSkin): Boolean;
      property FSkin: TDictionary<UInt32, PIffSkin> read FSkinDB;
  end;


implementation

{ TIffSkins }

constructor TIffSkins.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Item : PIffSkin;
begin
  FSkinDB := TDictionary<UInt32, PIffSkin>.Create;;

  if not FileExists('data\Skin.iff') then begin
    WriteConsole(' data\Skin.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\Skin.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 0 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base.Enabled, SizeOf(TIffSkin));
      // Add to skin database
      FSkinDB.Add(Item.Base.TypeID, Item);
    end;

  finally
    Packet.Free;
  end;

end;

destructor TIffSkins.Destroy;
var
  Items : PIffSkin;
begin
  for Items in FSkinDB.Values do
  begin
    Dispose(Items);
  end;
  FSkinDB.Clear;
  FreeAndNil(FSkinDB);
  inherited;
end;

function TIffSkins.GetItemName(TypeId: UInt32): AnsiString;
var
  Items : PIffSkin;
begin
  if not LoadSkin(TypeId, Items) then Exit;

  Exit(Items.Base.Name);
end;

function TIffSkins.GetPrice(TypeId, ADay: UInt32): UInt32;
var
  Items : PIffSkin;
begin
  if not LoadSkin(TypeId, Items) then Exit(0);

  if (Items.Base.Enabled = 1) then
  begin
    case ADay of
      15:
        begin
          Exit(Items.Price15);
        end;
      30:
        begin
          Exit(Items.Price30);
        end;
      365:
        begin
          Exit(Items.Price365);
        end;
    end;
    if (Items.Price15 = 0) and (Items.Price30 = 0) and (Items.Price365 = 0) then
    begin
      Exit(Items.Base.ItemPrice);
    end;
    Exit(0);
  end;
  Exit(0);
end;

function TIffSkins.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Items : PIffSkin;
begin
  if not LoadSkin(TypeId, Items) then Exit(-1);
  if (Items.Base.TypeID = TypeId) and (Items.Base.Enabled = 1) then
  begin
    Exit(Items.Base.PriceType);
  end;
  Exit(-1);
end;

function TIffSkins.GetSkinFlag(TypeId: UInt32): UInt8;
var
  Items: PIffSkin;
begin
  if not LoadSkin(TypeId, Items) then Exit(0);
  if (Items.Base.TypeID = TypeId) and (Items.Base.Enabled = 1) then
  begin
    if (Items.Price15 = 0) and (Items.Price30 = 0) and (Items.Price365 = 0) then
    begin
      Exit(0);
    end
    else
    begin
      Exit($20);
    end;
  end;
  Exit(0);
end;

function TIffSkins.IsBuyable(TypeId: UInt32): Boolean;
var
  Items : PIffSkin;
begin
  if not LoadSkin(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) and (Items.Base.ItemFlag AND 1 <> 0) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffSkins.IsExist(TypeId: UInt32): Boolean;
var
  Items : PIffSkin;
begin
  if not LoadSkin(TypeId, Items) then Exit(False);
  if (Items.Base.Enabled = 1) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffSkins.LoadSkin(ID: UInt32; var Skin: PIffSkin): Boolean;
begin
  if not FSkinDB.TryGetValue(UInt32(ID), Skin) then
  begin
    Exit(False);
  end;
  Exit(True);
end;

end.
