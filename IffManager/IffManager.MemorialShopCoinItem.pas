unit IffManager.MemorialShopCoinItem;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings;

type

  PMemorialCoin = ^TMemorialCoin;
  
  TMemorialCoin = packed record
    var Enable: UInt32;
    var TypeID: UInt32;
    var CoinType: UInt32;
    var Value_1: UInt32;
    var Value_2: UInt32;
    var GachaNum: UInt32;
    var Pool: UInt32;
    var ItemType: UInt32;
    var Value_3: UInt32;
    var Value_4: UInt32;
    var UN: array[0..23] of ansichar;
  end;

  TIffMemorialCoin = class
    private
      var CoinDB: TDictionary<UInt32, PMemorialCoin>;
    public
      constructor Create;
      destructor Destroy; override;
      function LoadCoin(TypeID: UInt32; var PCoin : PMemorialCoin): Boolean;
      function IsExist(TypeID: UInt32): Boolean;
      function GetPool(TypeID: UInt32): UInt8;
  end;

implementation

uses
  iffmain;

{ TIffMemorialCoin }

constructor TIffMemorialCoin.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt16;
  Item : PMemorialCoin;
begin
  CoinDB := TDictionary<UInt32, PMemorialCoin>.Create;

  if not FileExists('data\MemorialShopCoinItem.sff') then begin
    WriteConsole(' data\MemorialShopCoinItem.sff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\MemorialShopCoinItem.sff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt16(Total) then Exit;
    
    Packet.Skip(6);

    for Count := 1 to Total do
    begin
      New(Item);
      Packet.Read(Item.Enable, SizeOf(TMemorialCoin));
      {WriteLn(Format('%d  :%d  :%d  :%d   :%d  :%d   :%d  :%d  :%d :%d :%s' ,
      [Item.Enable,
      item.TypeID,
      Item.CoinType,
      Item.Value_1,
      Item.Value_2,
      Item.GachaNum,
      Item.Pool,
      Item.ItemType,
      Item.Value_3,
      Item.Value_4,
      iffentry.GetItemName(item.TypeID)
      ]
      ));}
      // Add item to TDictionary
      CoinDB.Add(Item.TypeId, Item);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TIffMemorialCoin.Destroy;
var
  Enum: TPair<UInt32, PMemorialCoin>;
begin
  for Enum in CoinDB do
    Dispose(Enum.Value);

  CoinDB.Clear;

  FreeAndNil(CoinDB);
  inherited;
end;

function TIffMemorialCoin.GetPool(TypeID: UInt32): UInt8;
var
  Coin: PMemorialCoin;
begin
  if not LoadCoin(TypeID, Coin) then Exit(0);

  Exit(Coin.Pool);
end;

function TIffMemorialCoin.IsExist(TypeID: UInt32): Boolean;
var
  Coin: PMemorialCoin;
begin
  if not LoadCoin(TypeID, Coin) then Exit(False);
  Exit(True);
end;

function TIffMemorialCoin.LoadCoin(TypeID: UInt32; var PCoin : PMemorialCoin): Boolean;
begin
  if not CoinDB.TryGetValue(TypeID, PCoin) then Exit(False);
  Exit(True);
end;

end.
