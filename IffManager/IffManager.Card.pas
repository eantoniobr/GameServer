unit IffManager.Card;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket,
  UWriteConsole, AnsiStrings, Defines, RandomItem, Enum;

type

  PCardPack = ^TCardPack;

  TCardPack = packed record
    var CType: TPACKCARD;
    var Quan: UInt8;
  end;

  PIffCard = ^TIffCard;

  TIffCard = packed record
    var Base: TBaseIff;
    var CardType: UInt8;
    var MPet: array[$0..$27] of AnsiChar;
    var Unknown5: UInt8;
    var C0: UInt16;
    var C1: UInt16;
    var C2: UInt16;
    var C3: UInt16;
    var C4: UInt16;
    var Effect: UInt16;
    var EffectQty: UInt16;
    var Texture1: array[$0..$27] of AnsiChar;
    var Texture2: array[$0..$27] of AnsiChar;
    var Texture3: array[$0..$27] of AnsiChar;
    var Time: UInt16;
    var Volumn: UInt16;
    var Position: UInt32;
    var Unknown6: UInt32;
    var Unknown7: UInt32;
  end;

  TIffCards = class
  private
    var AllList: TDictionary<UInt32, PIffCard>;
    var PackData: TDictionary<UInt32, PCardPack>;
    var ListCard: TList<PIffCard>;
    procedure AddPack;
  public
    constructor Create;
    destructor Destroy; override;
    function IsExist(TypeId: UInt32): Boolean;
    function GetItemName(TypeId: UInt32): AnsiString;
    function IsBuyable(TypeId: UInt32): Boolean;
    function GetShopPriceType(TypeId: UInt32): ShortInt;
    function GetPrice(TypeId: UInt32): UInt32;
    function GetCard(PackTypeID: UInt32): TList<TPair<UInt32, UInt8>>;
    function GetCardSPCL(TypeID: UInt32): TPair<Boolean, PIffCard>;
    function GetSPCL(TypeId: UInt32): TPair<UInt32, UInt32>;

    function LoadCard(ID: UInt32; var CARD: PIffCard): Boolean;
  published
    property CARD: TDictionary<UInt32, PIffCard> read AllList;
  end;

implementation

{ TIffCards }

procedure TIffCards.AddPack;
var
  CardPack: PCardPack;
  Card: PIffCard;
begin
  for Card in AllList.Values do
  begin
    case Card.Base.TypeID of
      2092957696, { Pangya Card Pack No.1 }
      2092957697, { Golden Card Ticket }
      2092957698, { Silver Card Ticket }
      2092957699, { Bronze card ticket }
      2092957700, { Pangya Card Pack No.2 }
      2092957701, { Card Pack No.3 }
      2092957702, { Platinum Ticket }
      2092957703, { Card Pack No.4 }
      2092957704, { Grand Prix Card Pack }
      2092957706, { Fresh Up! Card Pack }
      2097152001, { Pangya Card Box No.2 }
      2097152002, { Card Box No.3 }
      2097152003, { Pangya Card Box #4 }
      2084569125, { Unknown Name }
      2084569128: { Unknown Name }
        begin
          Continue;
        end;
      end;
    ListCard.Add(Card);
  end;

  // ## pack 1
  New(CardPack);
  CardPack.CType := Pack1;
  CardPack.Quan := 3;
  PackData.Add(2092957696, CardPack);
  // ## pack 2
  New(CardPack);
  CardPack.CType := Pack2;
  CardPack.Quan := 3;
  PackData.Add(2092957700, CardPack);
  // ## pack 3
  New(CardPack);
  CardPack.CType := Pack3;
  CardPack.Quan := 3;
  PackData.Add(2092957701, CardPack);
  // ## pack 4
  New(CardPack);
  CardPack.CType := Pack4;
  CardPack.Quan := 3;
  PackData.Add(2092957703, CardPack);
  // ## FRESH UP!
  New(CardPack);
  CardPack.CType := Rare;
  CardPack.Quan := 3;
  PackData.Add($7CC0000A, CardPack);

end;

function TIffCards.GetCard(PackTypeID: UInt32): TList<TPair<UInt32, UInt8>>;
  function GetProb(RareType: UInt8): UInt32;
  begin
    case RareType of
      0:
        Exit(100);
      1:
        Exit(6);
      2:
        Exit(5);
      3:
        Exit(1);
    end;
  end;
  function GetFreshUPProb(RareType: UInt8): UInt32;
  begin
    case RareType of
      1:
        Exit(100);
      2:
        Exit(10);
      3:
        Exit(4);
    end;
  end;
var
  CPack: PCardPack;
  CRandom: TItemRandomClass;
  PZCard: PIffCard;
  CQty: UInt8;
  CItem: PItemRandom;
begin
  Result := TList<TPair<UInt32, UInt8>>.Create;
  CRandom := TItemRandomClass.Create;
  try
    PackData.TryGetValue(PackTypeID, CPack);

    if CPack = nil then
      Exit(Result);

    case CPack.CType of
      Pack1:
        begin
          for PZCard in ListCard do
           if PZCard.Volumn = 1 then
            CRandom.AddItems(PZCard.Base.TypeID, 1, PZCard.CardType, GetProb(PZCard.CardType));
        end;
      Pack2:
        begin
          for PZCard in ListCard do
           if PZCard.Volumn = 2 then
            CRandom.AddItems(PZCard.Base.TypeID, 1, PZCard.CardType, GetProb(PZCard.CardType));
        end;
      Pack3:
        begin
          for PZCard in ListCard do
           if PZCard.Volumn = 3 then
            CRandom.AddItems(PZCard.Base.TypeID, 1, PZCard.CardType, GetProb(PZCard.CardType));
        end;
      Pack4:
        begin
          for PZCard in ListCard do
           if PZCard.Volumn = 4 then
            CRandom.AddItems(PZCard.Base.TypeID, 1, PZCard.CardType, GetProb(PZCard.CardType));
        end;
      Rare:
        begin
          for PZCard in ListCard do
           if PZCard.CardType >= 1 then
            CRandom.AddItems(PZCard.Base.TypeID, 1, PZCard.CardType, GetFreshUPProb(PZCard.CardType));
        end;
      All:
        begin
          for PZCard in ListCard do
            CRandom.AddItems(PZCard.Base.TypeID, 1, PZCard.CardType, GetProb(PZCard.CardType));
        end;
    end;

    // ## set random class
    CRandom.SetCanDup(False);

    CRandom.Arrange;

    for CQty := 1 to CPack.Quan do
    begin
      CItem := CRandom.GetItems;
      Result.Add(TPair<UInt32, UInt8>.Create(CItem.TypeId, CItem.RareType));
    end;

    Exit(Result);
  finally
    FreeAndNil(CRandom);
  end;
end;

function TIffCards.GetCardSPCL(TypeID: UInt32): TPair<Boolean, PIffCard>;
var
  C: PIffCard;
begin
  if not LoadCard(TypeID, C) then Exit( TPair<Boolean, PIffCard>.Create(False, nil) );
  Exit( TPair<Boolean, PIffCard>.Create(True, C) );
end;

constructor TIffCards.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Item : PIffCard;
begin
  AllList := TDictionary<UInt32, PIffCard>.Create;
  PackData := TDictionary<UInt32, PCardPack>.Create;
  ListCard := TList<PIffCard>.Create;

  if not FileExists('data\Card.iff') then begin
    WriteConsole(' data\Card.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\Card.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 1 to Total do
    begin
      New(Item);
      Packet.Read(Item.Base.Enabled, SizeOf(TIffCard));
      //WriteLn(Item.Position);

      WriteLn(Format('%s S1 %d S2 %d' ,[Item.Base.Name, Item.Effect, Item.EffectQty]));

      AllList.Add(Item.Base.TypeID, Item);
    end;

    // ## add pack
    Self.AddPack;
  finally
    Packet.Free;
  end;
end;

destructor TIffCards.Destroy;
var
  Items : PIffCard;
  Packs: TPair<UInt32, PCardPack>;
begin
  ListCard.Clear;

  for Packs in PackData do
    Dispose(Packs.Value);

  for Items in AllList.Values do
    Dispose(Items);

  AllList.Clear;
  PackData.Clear;
  PackData.Free;
  ListCard.Free;
  AllList.Free;
end;

function TIffCards.GetItemName(TypeId: UInt32): AnsiString;
var
  Items : PIffCard;
begin
  if not LoadCard(TypeID, Items) then Exit('Unknown Item Name');
  Exit(Items.Base.Name);
end;

function TIffCards.GetPrice(TypeId: UInt32): UInt32;
var
  Items : PIffCard;
begin
  if not LoadCard(TypeId, Items) then Exit(0);
  Exit(Items.Base.ItemPrice);
end;

function TIffCards.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Items : PIffCard;
begin
  if not LoadCard(TypeId, Items) then Exit(-1);
  Exit(Items.Base.ItemPrice);
end;

function TIffCards.GetSPCL(TypeId: UInt32): TPair<UInt32, UInt32>;
var
  C: PIffCard;
begin
  if not LoadCard(TypeID, C) then Exit( TPair<UInt32, UInt32>.Create(0, 0));
  Exit(TPair<UInt32, UInt32>.Create(C.Effect, C.EffectQty));
end;

function TIffCards.IsBuyable(TypeId: UInt32): Boolean;
var
  Items : PIffCard;
begin
  if not LoadCard(TypeID, Items) then Exit(False);

  if (Items.Base.TypeID = TypeId) and (Items.Base.Enabled = 1) and (Items.Base.ItemFlag AND 1 <> 0) then
  begin
    Exit(True);
  end;

  Exit(False);
end;

function TIffCards.IsExist(TypeId: UInt32): Boolean;
var
  Items : PIffCard;
begin
  if not LoadCard(TypeID, Items) then Exit(False);

  if (Items.Base.TypeID = TypeId) AND (Items.Base.Enabled = 1) then
  begin
    Exit(True);
  end;

  Exit(False);
end;

function TIffCards.LoadCard(ID: UInt32; var CARD: PIffCard): Boolean;
begin
  if not AllList.TryGetValue(ID, CARD) then Exit(False);
  Exit(True);
end;

end.
