unit IffManager.MemorialShopRareItem;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings,
  MTRand, RandomItem;

type

  PSpecialItem = ^TSpecialItem;
  TSpecialItem = packed record
    var Number: UInt8;
    var TypeID: UInt32;
    var Quantity: UInt32;
  end;

  PMemorialRare = ^TMemorialRare;
  TMemorialRare = packed record
    var Enable: UInt32;
    var GachaNum: UInt32;
    var SumGacha: UInt32;
    var TypeID: UInt32;
    var Probabilities: UInt32;
    var RareType: UInt32;
    var ItemType: UInt32;
    var Sex: UInt32;
    var Value_1: UInt32;
    var Item: UInt32;
    var CharacterType: UInt32;
    var UN: array[0..23] of ansichar;
  end;

  TIffMemorialRare = class
    private
      var RareItem: TList<PMemorialRare>;
      var SPItem: TList<PSpecialItem>;
      procedure AddSPList;
    public
      constructor Create;
      destructor Destroy; override;
      function GetNormalItem(TypeID: UInt32): TList<PSpecialItem>;
      function GetRareItem(CoinTypeID: UInt32; Pooling: UInt8): TItemRandomClass;
  end;

implementation

uses
  iffmain;

{ TIffMemorialCoin }

procedure TIffMemorialRare.AddSPList;
var
  SPT: PSpecialItem;
begin
  // 1. ## Strength Boost x5
  New(SPT);
  SPT.Number := 1;
  SPT.TypeID := 402653188;
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  // 2. ## Miracle Sign x5
  New(SPT);
  SPT.Number := 2;
  SPT.TypeID := 402653189;
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  // 3. ## Spin Mastery x5
  New(SPT);
  SPT.Number := 3;
  SPT.TypeID := 402653184;
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  // 4. ## Curve Mastery x5
  New(SPT);
  SPT.Number := 4;
  SPT.TypeID := 402653185;
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  // 5. ## Generic Lucky Pangya x5
  New(SPT);
  SPT.Number := 5;
  SPT.TypeID := 402653191;
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  // 6. ## Generic Nerve Stabilizer x5
  New(SPT);
  SPT.Number := 6;
  SPT.TypeID := 402653192;
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  // 7. ## Club Modification Kit x1
  New(SPT);
  SPT.Number := 7;
  SPT.TypeID := 436208143;
  SPT.Quantity := 1;
  SPItem.Add(SPT);

  {Premium Coin Set No.1}
  New(SPT);
  SPT.Number := 8;
  SPT.TypeID := 402653190; // ## Silent Wind
  SPT.Quantity := 3;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 8;
  SPT.TypeID := 436208015; // ## Bongdari Clip
  SPT.Quantity := 1;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 8;
  SPT.TypeID := 335544321; // ## Bomber Aztec
  SPT.Quantity := 30;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 8;
  SPT.TypeID := 436207633; // ## Timer Boost
  SPT.Quantity := 30;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 8;
  SPT.TypeID := 436207680; // ## Auto Clipper
  SPT.Quantity := 30;
  SPItem.Add(SPT);
  {End Premium Coin}

  {Premium Coin Set No.2}
  New(SPT);
  SPT.Number := 9;
  SPT.TypeID := 436208145; // ## UCIM CHIP
  SPT.Quantity := 2;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 9;
  SPT.TypeID := 335544342; // ## Watermelon Aztec
  SPT.Quantity := 40;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 9;
  SPT.TypeID := 402653224; // ## Safe Tee
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 9;
  SPT.TypeID := 436207633; // ## Timer Boost
  SPT.Quantity := 100;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 9;
  SPT.TypeID := 436207680; // ## Auto Clipper
  SPT.Quantity := 100;
  SPItem.Add(SPT);
  {End Premium Coin}

  {Premium Coin Set No.3}
  New(SPT);
  SPT.Number := 10;
  SPT.TypeID := 436208144; // ## Abbot Coating
  SPT.Quantity := 3;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 10;
  SPT.TypeID := 335544332; // ## Clover Aztec
  SPT.Quantity := 50;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 10;
  SPT.TypeID := 402653223; // ## Double Strength Boost
  SPT.Quantity := 10;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 10;
  SPT.TypeID := 436207815; // ## Air Note
  SPT.Quantity := 60;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 10;
  SPT.TypeID := 436207633; // ## Timer Boost
  SPT.Quantity := 60;
  SPItem.Add(SPT);
  {End Premium Coin}

  {Premium Coin Set No.4}
  New(SPT);
  SPT.Number := 11;
  SPT.TypeID := 2092957696; // ## Card Pack No. 1
  SPT.Quantity := 1;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 11;
  SPT.TypeID := 335544350; // ## Sakura Aztec
  SPT.Quantity := 50;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 11;
  SPT.TypeID := 402653230; // ## Double P.Strength Boost
  SPT.Quantity := 3;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 11;
  SPT.TypeID := 436207618; // ## Pang Mastery
  SPT.Quantity := 20;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 11;
  SPT.TypeID := 436207633; // ## Timer Boost
  SPT.Quantity := 50;
  SPItem.Add(SPT);
  {End Premium Coin}

  {Premium Coin Set No.5}
  New(SPT);
  SPT.Number := 12;
  SPT.TypeID := 2092957700; // ## Card Pack No.2
  SPT.Quantity := 1;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 12;
  SPT.TypeID := 335544369; // ## Halloween Skull Aztec
  SPT.Quantity := 30;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 12;
  SPT.TypeID := 402653194; // ## Dual Lucky Pangya
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 12;
  SPT.TypeID := 436207618; // ## Pang Mastery
  SPT.Quantity := 30;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 12;
  SPT.TypeID := 436207633; // ## Timer Boost
  SPT.Quantity := 50;
  SPItem.Add(SPT);
  {End Premium Coin}

  {Premium Coin Set No.6}
  New(SPT);
  SPT.Number := 13;
  SPT.TypeID := 2092957701; // ## Card Pack No.3
  SPT.Quantity := 1;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 13;
  SPT.TypeID := 335544352; // ## Rainbow Aztec
  SPT.Quantity := 30;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 13;
  SPT.TypeID := 402653195; // ## Dual Tran
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 13;
  SPT.TypeID := 436207618; // ## Pang Mastery
  SPT.Quantity := 30;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 13;
  SPT.TypeID := 436207680; // ## Auto Clipper
  SPT.Quantity := 40;
  SPItem.Add(SPT);
  {End Premium Coin}

  {Premium Coin Set No.7}
  New(SPT);
  SPT.Number := 14;
  SPT.TypeID := 2092957703; // ## Card Pack No.4
  SPT.Quantity := 1;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 14;
  SPT.TypeID := 335544465; // ## Smiling Goblin Aztec
  SPT.Quantity := 50;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 14;
  SPT.TypeID := 402653223; // ## Double Strength Boost
  SPT.Quantity := 5;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 14;
  SPT.TypeID := 436207633; // ## Timer Boost
  SPT.Quantity := 50;
  SPItem.Add(SPT);

  New(SPT);
  SPT.Number := 14;
  SPT.TypeID := 436207680; // ## Auto Clipper
  SPT.Quantity := 50;
  SPItem.Add(SPT);
  {End Premium Coin}

  {for SPT in SpItem do
    WriteLn(Format('%d %s %d' ,[SPT.Number, IffEntry.GetItemName(SPT.TypeID), SPT.Quantity])); }


end;

constructor TIffMemorialRare.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt16;
  Item : PMemorialRare;
begin

  SPItem := TList<PSpecialItem>.Create;
  RareItem := TList<PMemorialRare>.Create;

  AddSPList;

  if not FileExists('data\MemorialShopRareItem.iff') then begin
    WriteConsole(' data\MemorialShopRareItem.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\MemorialShopRareItem.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt16(Total) then Exit;

    Packet.Skip(6);

    for Count := 1 to Total do
    begin
      New(Item);
      Packet.Read(Item.Enable, SizeOf(TMemorialRare));

      //WriteLn(IffEntry.GetItemName(Item.TypeID), Item.Probabilities);
      // ## add to list
      RareItem.Add(Item);
      //FItemDB.Add(Item.TypeId, Item);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TIffMemorialRare.Destroy;
var
  SPEach: PSpecialItem;
  RareEach: PMemorialRare;
begin
  for SPEach in SPItem do
    Dispose(SPEach);

  for RareEach in RareItem do
    Dispose(RareEach);

  SPItem.Clear;
  RareItem.Clear;

  SPItem.Free;
  RareItem.Free;
  inherited;
end;

function TIffMemorialRare.GetNormalItem(TypeID: UInt32): TList<PSpecialItem>;
var
  PairNum: UInt8;
  SpecialItem: PSpecialItem;
begin
  Result := TList<PSpecialItem>.Create;
  case TypeID of
    436208242:
      begin
        PairNum := Rand.RandInt(8, 14);
      end;
    else
      begin
        PairNum := Rand.RandInt(1, 7);
      end;
  end;

  for SpecialItem in SPItem do
  begin
    if SpecialItem.Number = Pairnum then
      Result.Add(SpecialItem);
  end;

  Exit(Result);
end;

function TIffMemorialRare.GetRareItem(CoinTypeID: UInt32; Pooling: UInt8): TItemRandomClass;
var
  Item: PMemorialRare;
begin
  Result := TItemRandomClass.Create;
  case Pooling of
    0:
      begin
        for Item in Self.RareItem do
          Result.AddItems(Item.TypeID, 1, Item.RareType, Item.Probabilities);
      end;
    else
      begin
        for Item in Self.RareItem do
          if Item.CharacterType = Pooling then
            Result.AddItems(Item.TypeID, 1, Item.RareType, Item.Probabilities);
      end;
  end;

  Result.SetCanDup(False);
  Result.Arrange;
  Exit(Result);
end;

end.

