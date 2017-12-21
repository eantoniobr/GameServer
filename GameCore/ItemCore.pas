unit ItemCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  ClientPacket, PangyaClient, ItemData, System.SysUtils, System.Math,
  uWarehouse, IffMain, Tools, System.Generics.Collections, Defines,
  uCard, RandomItem, MTRand,
  IffManager.MemorialShopRareItem,
  uCharacter, Enum, IffManager.Card;

procedure PlayerOpenAztecBox(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerRenewRent(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerDeleteRent(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerMagicBox(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerRemoveItem(const PL: TClientPlayer; const ClientPacket: TClientPacket);

procedure PlayerPutCard(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerPutBonusCard(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerCardRemove(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerCardSpecial(const PL: TClientPlayer; const ClientPacket: TClientPacket);

procedure PlayerOpenCardpack(const PL: TClientPlayer; const ClientPacket: TClientPacket);

procedure PlayerMemorialGacha(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure LogMemorial(const PL: TClientPlayer; const ItemName: AnsiString; Quantity: UInt32);

function AddItem(const PL: TClientPlayer; const ItemData: TAddItem): TAddData;

implementation

procedure PlayerOpenAztecBox(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  BoxTypeID, BallTypeID: UInt32;
  Packet: TClientPacket;
  ItemAddedData: TAddData;
  ItemAddData: TAddItem;
begin
  if not ClientPacket.ReadUInt32(BoxTypeID) then Exit;
  if not ClientPacket.ReadUInt32(BallTypeID) then Exit;

  if not (BoxTypeID = 436207877) then Exit;

  // CHECK IF USE HAVE ITEM
  if PL.Inventory.IsExist(BoxTypeID) and PL.Inventory.IsExist(BallTypeID) then
  begin
    PL.Inventory.Remove(BoxTypeID, 1, False);

    Randomize;

    with ItemAddData do
    begin
      ItemIffId := BallTypeID;
      Quantity := RandomRange(15, 25);
      Transaction := False;
      Day := 0;
    end;

    ItemAddedData := PL.AddItem(ItemAddData);

    Packet := TClientPacket.Create;
    try
      Packet.WriteStr(#$97#$01#$01);
      Packet.WriteUInt32(BoxTypeID);
      Packet.WriteUInt32(BallTypeID);
      Packet.WriteUInt32(ItemAddedData.ItemNewQty);
      PL.Send(Packet);
    finally
      FreeAndNil(Packet);
    end;
  end
  else
  begin
    PL.Send(#$97#$01);
  end;
end;

// 03 = only extend the expiring part
// 04 = fail to progress (04)
// 05 = the need of extend is refused
// 06 = fail to progress (06)
procedure PlayerRenewRent(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  PPart: PItem;
  PartIndex: UInt32;
  PartCharge: UInt32;
  Packet: TClientPacket;
begin
  if not ClientPacket.ReadUInt32(PartIndex) then Exit;

  PPart := PL.Inventory.ItemWarehouse.GetItem(PartIndex);

  if PPart = nil then
  begin
    PL.Send(#$8F#$01#$05);
    raise Exception.Create('HandlePlayerRenewRent: variable ppart is nill');
  end;

  if (not (GetItemGroup(PPart.ItemTypeID) = $2) ) or (not (PPart.ItemFlag = $62)) then
  begin
    PL.Send(#$8F#$01#$03);
    Exit;
  end;

  PartCharge := IffEntry.GetRentalPrice(PPart.ItemTypeID);

  if PartCharge <= 0 then
  begin
    PL.Send(#$8F#$01#$05);
    Exit;
  end;

  if not PL.RemovePang(PartCharge) then
  begin
    PL.Send(#$8F#$01#$04);
    Exit;
  end;

  PL.SendPang;

  PPart.Renew;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$8F#$01);
    Packet.WriteUInt8(0);
    Packet.WriteUInt32(PPart.ItemTypeID);
    Packet.WriteUInt32(PPart.ItemIndex);
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

// 01 = it's not the same item (wired message)
// 02 = mix with duplicated item try again (wired message)
// 03 = failed to progress(3)
// 04 = Item that contains card cannot be deleted
// 05 = ?? ????? ????????
// 06 = failed to progress(6)
// 07 = failed to progress(7)
procedure PlayerDeleteRent(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  RentIndex: UInt32;
  PPart: PItem;
  Packet: TClientPacket;
begin
  if not ClientPacket.ReadUInt32(RentIndex) then Exit;

  PPart := PL.Inventory.ItemWarehouse.GetItem(RentIndex);

  if PPart = nil then
  begin
    PL.Send(#$90#$01#$03);
    raise Exception.Create('HandlePlayerDeleteRent: variable ppart is nill');
  end;

  if (not (GetItemGroup(PPart.ItemTypeID) = $2) ) or (not (PPart.ItemFlag = $62)) then
  begin
    PL.Send(#$90#$01#$03);
    Exit;
  end;

  PPart.DeleteItem;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$90#$01);
    Packet.WriteUInt8(0); // success return
    Packet.WriteUInt32(PPart.ItemTypeID);
    Packet.WriteUInt32(PPart.ItemIndex);
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;

end;

procedure PlayerMagicBox(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TMagicList = packed record
    var TypeID: UInt32;
    var Index: UInt32;
    var Quantity: UInt32;
  end;
var
  MagicID: UInt16;
  MagicSum: UInt32;
  SumItem: UInt8;
  MagicList: TList<TPair<UInt32, UInt32>>;
  MGPair: TPair<UInt32, UInt32>;

  MGCList: TList<TMagicList>;
  MGItem: TMagicList;

  AddItemData: TAddItem;
  GetItem: TPair<UInt32, UInt32>;
  Packet: TClientPacket;
  ItemData : TAddData;
begin
  if not ClientPacket.ReadUInt16(MagicID) then Exit;
  if not ClientPacket.ReadUInt32(MagicSum) then Exit;
  if not ClientPacket.ReadUInt8(SumItem) then Exit;

  MagicList := IffEntry.FMagicBox.GetMagicTrade(MagicID + 1);
  MGCList := TList<TMagicList>.Create;
  Packet := TClientPacket.Create;
  try
    for MGPair in MagicList do
    begin
      MGItem.TypeID := MGPair.Key;
      MGItem.Quantity := MGPair.Value * MagicSum; // ## should sum with total
      // ## skip for ununsed typeid
      ClientPacket.Skip(4);
      if not ClientPacket.ReadUInt32(MGItem.Index) then Exit;
      // ## if item didn't exist
      if not PL.Inventory.IsExist(MGItem.TypeID, MGItem.Index, MGItem.Quantity) then
      begin
        PL.Send(#$2F#$02#$B3#$F9#$56#$00); // ## delete item fail or item didn't exist
        Exit;
      end;
      // ## add to list
      MGCList.Add(MGItem);
    end;

    for MGItem in MGCList do
    begin
      if not PL.Inventory.Remove(MGItem.TypeID, MGItem.Index, MGItem.Quantity, True).Status then
      begin
        PL.Send(#$2F#$02#$01#$00#$00#$00);
        raise Exception.Create('HandlePlayerMagicBox: fail to delete player''s item while check true');
      end;
    end;

    GetItem := IffEntry.FMagicBox.GetItem(MagicID + 1);

    with AddItemData do
    begin
      ItemIffId := GetItem.Key;
      Quantity := GetItem.Value * MagicSum;
      Transaction := True;
      Day := 0;
    end;

    ItemData := AddItem(PL, AddItemData);

    // ## send tran
    PL.SendTransaction;

    Packet.WriteStr(#$2F#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(MagicID);
    Packet.WriteUInt32(1);
    Packet.WriteUInt32(ItemData.ItemTypeID);
    Packet.WriteUInt32(ItemData.ItemIndex);
    Packet.WriteUInt32(GetItem.Value * MagicSum);
    Packet.WriteUInt32(ItemData.ItemNewQty);
    Packet.WriteUInt32(0);
    PL.Send(Packet);
  finally
    MagicList.Clear;
    FreeAndNil(MagicList);
    MGCList.Clear;
    FreeAndNil(MGCList);
    FreeAndNil(Packet);
  end;
end;

function AddItem(const PL: TClientPlayer; const ItemData: TAddItem): TAddData;
var
  ListSet: TList<TPair<UInt32, UInt32>>;
  Enum: TPair<UInt32, UInt32>;
  ItemAddData: TAddItem;
begin
  if GetItemGroup(ItemData.ItemIffId) = $9 then
  begin
    ListSet := IffEntry.FSets.SetList(ItemData.ItemIffId);
    try
      if ListSet.Count <= 0 then
      begin
        // ## should not be happened
        Exit;
      end;
      for Enum in ListSet do
      begin
        with ItemAddData do
        begin
          ItemIffId := Enum.Key;
          Quantity := Enum.Value;
          Transaction := True;
          Day := 0; // ## set should not be limited time in their set
        end;
        PL.AddItem(ItemAddData);
      end;
      Result.Status := True;
      Result.ItemIndex := $FFFFFFFF;
      Result.ItemTypeID := ItemData.ItemIffId;
      Result.ItemOldQty := 0;
      Result.ItemNewQty := 1;
      Result.ItemUCCKey := Nulled;
      Result.ItemFlag := 0;
      Result.ItemEndDate := 0;
      Exit(Result);
    finally
      FreeAndNil(ListSet);
    end;
  end else
  begin
    Exit(PL.AddItem(ItemData));
  end;
end;

procedure PlayerRemoveItem(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  TypeId, Quantity: UInt32;
  ItemAddedData: TAddData;
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    if not ClientPacket.ReadUInt32(TypeId) then Exit;
    if not ClientPacket.ReadUInt32(Quantity) then Exit;

    if not (GetItemGroup(TypeId) = 6) then
    begin
      Exit;
    end;

    ItemAddedData := PL.Inventory.Remove(TypeId, Quantity, False);

    if not ItemAddedData.Status then
    begin
      Exit;
    end;

    Packet.WriteStr(#$C5#$00#$01);
    Packet.WriteUInt32(ItemAddedData.ItemTypeID);
    Packet.WriteUInt32(Quantity);
    Packet.WriteUInt32(ItemAddedData.ItemIndex);
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure PlayerOpenCardpack(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TCardData = packed record
    var TypeID: UInt32;
    var CardIndex: UInt32;
  end;

  function Check(TypeID: UInt32): Boolean;
  begin
    case TypeID of
      { Pack No.1 } $7CC00000,
      { Pack No.2 } $7CC00004,
      { Pack No.3 } $7CC00005,
      { Pack No.4 } $7CC00007,
      { GrandPrix } $7CC00008,
      { FreshUP!! } $7CC0000A:
        begin
          Exit(True);
        end;
    end;
    Exit(False);
  end;
var
  CardData: TCardData;
  PlayerCard: PCard;
  CardList: TList<TPair<UInt32, UInt8>>;
  Enum: TPair<UInt32, UInt8>;
  Packet: TClientPacket;
  ResultAdd: TAddData;
  AddData: TAddItem;
begin
  if not ClientPacket.Read(CardData, SizeOf(TCardData)) then Exit;
  // ## get card
  PlayerCard := PL.Inventory.ItemCard.GetCard(CardData.CardIndex);
  // ## if card can't be open
  if not Check(PlayerCard.CardTypeID) then
  begin
    PL.Send(#$54#$01#$01#$00#$00#$00);
    raise Exception.Create('HandlePlayerOpenCardPack: card can''t be open');
  end;

  // ## delete player card
  if not PL.Inventory.Remove(CardData.TypeID, 1, False).Status then
  begin
    PL.Send(#$54#$01#$01#$00#$00#$00);
    raise Exception.Create('HandlePlayerOpenCardPack: Card Not Found');
  end;

  // ## get random card
  CardList := IffEntry.FCards.GetCard(PlayerCard.CardTypeID);
  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$54#$01);
    Packet.WriteUInt32(0); // ## 0 = success
    Packet.WriteUInt32(PlayerCard.CardIndex);
    Packet.WriteUInt32(PlayerCard.CardTypeID);
    Packet.WriteStr(#$00, $C);
    Packet.WriteUInt32(1);
    Packet.WriteStr(#$00, $20);
    Packet.WriteStr(#$01#$00);
    Packet.WriteUInt8(CardList.Count);
    for Enum in  CardList do
    begin
      AddData.ItemIffId := Enum.Key;
      AddData.Transaction := False;
      AddData.Quantity := 1;
      AddData.Day := 0;
      // ## add item
      ResultAdd := PL.AddItem(AddData);

      Packet.WriteUInt32(ResultAdd.ItemIndex);
      Packet.WriteUInt32(ResultAdd.ItemTypeID);
      Packet.WriteStr(#$00, $C);
      Packet.WriteUInt32(ResultAdd.ItemNewQty);
      Packet.WriteStr(#$00, $20);
      Packet.WriteStr(#$01#$00);
      Packet.WriteUInt32(1);
    end;
    PL.Send(Packet);
  finally
    Packet.Free;
    CardList.Clear;
    FreeAndNil(CardList);
  end;
end;

{
1 = 1 CHAR
2 = 2 CHAR
3 = 3 CHAR

5 = 1 CADDIE
6 = 2 CADDIE
7 = 3 CADDIE

9 = 1 NPC
10 = 2 NPC

4 = 1 BONUS CHAR
8 = 2 BONUS CADDIE
}

function CardCheckPosition(TypeID: UInt32; Slot: Byte): Boolean;
begin
  case Slot of
    1,2,3,4:
      begin
        if not (GetCardType(TypeID) = tNormal) then Exit(False);
        Exit(True);
      end;
    5,6,7,8:
      begin
        if not (GetCardType(TypeID) = tCaddie) then Exit(False);
        Exit(True);
      end;
    9,10:
      begin
        if not (GetCardType(TypeID) = tNPC) then Exit(False);
        Exit(True);
      end;
  end;
end;

procedure PlayerPutBonusCard(const PL: TClientPlayer; const ClientPacket: TClientPacket);
const
  BongdariClip: UInt32 = $1A00018F;
type
  TCardData = record
    var CharTypeID: UInt32;
    var CharIndex: UInt32;
    var CardTypeID: UInt32;
    var CardIndex: UInt32;
    var Position: UInt32;
  end;
var
  Data: TCardData;
  PLCard: PCard;
  PLCharacter: PCharacter;
  ItemData: TAddData;
  Transac: TTransacItem;
  Packet: TClientPacket;
begin
  if not ClientPacket.Read(Data, SizeOf(TCardData)) then Exit;

  if not PL.Inventory.IsExist(BongdariClip) then
  begin
    PL.Send(#$72#$02#$B3#$F9#$56#$00);
    Exit;
  end;

  PLCard := PL.Inventory.ItemCard.GetCard(Data.CardIndex);
  PLCharacter := PL.Inventory.ItemCharacter.GetChar(Data.CharIndex, bIndex);

  if (PLCard = nil) or (PLCharacter = nil) then Exit;
  if (not (PLCard.CardTypeID = Data.CardTypeID)) or (not (PLCharacter.TypeID = Data.CharTypeID)) then Exit;
  if not CardCheckPosition(Data.CardTypeID, Data.Position) then Exit;

  (* DELETE BONGDARI CLIP *)
  ItemData := PL.Inventory.Remove(BongdariClip, 1, True);

  if not ItemData.Status then
  begin
    PL.Send(#$72#$02#$B3#$F9#$56#$00);
    Exit;
  end;

  (* DELETE CARD *)
  ItemData := PL.Inventory.Remove(Data.CardTypeID, 1, True);

  if not ItemData.Status then
  begin
    PL.Send(#$72#$02#$B3#$F9#$56#$00);
    Exit;
  end;

  (* UPDATE PLAYER *)

  if PL.Inventory.ItemCharacter.sCard.UpdateCard(PL.GetUID, PLCharacter.Index, PLCharacter.TypeID, ItemData.ItemTypeID, Data.Position, 0, 0).Key then
  begin
    Transac := TTransacItem.Create;
    with Transac do
    begin
      Types := $CB;
      TypeID := PLCharacter.TypeID;
      Index := PLCharacter.Index;
      PreviousQuan := 0;
      NewQuan := 0;
      UCC := Nulled;
      CardTypeID := Data.CardTypeID;
      CharSlot := Data.Position;
    end;

    PL.Inventory.Transaction.Add(Transac);

    PL.SendTransaction;

    Packet := TClientPacket.Create;
    try
      Packet.WriteStr(#$72#$02);
      Packet.WriteUInt32(0);
      Packet.WriteUInt32(Data.CardTypeID);

      PL.Send(Packet);
    finally
      Packet.Free;
    end;
  end;
end;

procedure PlayerPutCard(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TCardData = record
    var CharTypeID: UInt32;
    var CharIndex: UInt32;
    var CardTypeID: UInt32;
    var CardIndex: UInt32;
    var Position: UInt32;
  end;
var
  Data: TCardData;
  PLCard: PCard;
  PLCharacter: PCharacter;
  ItemData: TAddData;
  Transac: TTransacItem;
  Packet: TClientPacket;
begin
  if not ClientPacket.Read(Data, SizeOf(TCardData)) then Exit;

  PLCard := PL.Inventory.ItemCard.GetCard(Data.CardIndex);
  PLCharacter := PL.Inventory.ItemCharacter.GetChar(Data.CharIndex, bIndex);

  if (PLCard = nil) or (PLCharacter = nil) then Exit;
  if (not (PLCard.CardTypeID = Data.CardTypeID)) or (not (PLCharacter.TypeID = Data.CharTypeID)) then Exit;
  if not CardCheckPosition(Data.CardTypeID, Data.Position) then Exit;

  ItemData := PL.Inventory.Remove(Data.CardTypeID, 1, True);

  if not ItemData.Status then
  begin
    PL.Send(#$71#$02#$B3#$F9#$56#$00);
    Exit;
  end;

  if PL.Inventory.ItemCharacter.sCard.UpdateCard(PL.GetUID, PLCharacter.Index, PLCharacter.TypeID, ItemData.ItemTypeID, Data.Position, 0, 0).Key then
  begin
    Transac := TTransacItem.Create;
    with Transac do
    begin
      Types := $CB;
      TypeID := PLCharacter.TypeID;
      Index := PLCharacter.Index;
      PreviousQuan := 0;
      NewQuan := 0;
      UCC := Nulled;
      CardTypeID := Data.CardTypeID;
      CharSlot := Data.Position;
    end;

    PL.Inventory.Transaction.Add(Transac);

    PL.SendTransaction;

    Packet := TClientPacket.Create;
    try
      Packet.WriteStr(#$71#$02);
      Packet.WriteUInt32(0);
      Packet.WriteUInt32(Data.CardTypeID);

      PL.Send(Packet);
    finally
      Packet.Free;
    end;
  end;
end;

procedure PlayerCardRemove(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TCardRemove = packed record
    var CharTypeID: UInt32;
    var CharIndex: UInt32;
    var RemoverTypeID: UInt32;
    var RemoverIndex: UInt32;
    var Slot: UInt32;
  end;
var
  Data: TCardRemove;
  PLCharacter: PCharacter;
  CARDDATA: PCardEquip;
  ItemData: TAddData;
  Transac: TTransacItem;
  Packet: TClientPacket;
  ItemAdd: TAddItem;
begin
  if not ClientPacket.Read(Data, SizeOf(TCardRemove)) then Exit;

  if not (Data.RemoverTypeID = $1A0000C2) then
  begin
    PL.Send(#$73#$02#$62#$73#$55#$00);
    Exit;
  end;

  PLCharacter := PL.Inventory.ItemCharacter.GetChar(Data.CharIndex, bIndex);

  //CardTypeID := PLCharacter.GetCardPos(Data.Slot);
  CARDDATA := PL.Inventory.ItemCharacter.sCard.GetCard(PLCharacter.Index, Data.Slot);

  if (nil = CARDDATA) or (CARDDATA.CARD_TYPEID = 0) or ( not (GetItemGroup(CARDDATA.CARD_TYPEID) = $1F)) then
  begin
    PL.Send(#$73#$02#$63#$73#$55#$00);
    Exit;
  end;

  ItemData := PL.Inventory.Remove(Data.RemoverTypeID, 1, True);

  if not ItemData.Status then
  begin
    PL.Send(#$73#$02#$B3#$F9#$56#$00);
    Exit;
  end;

  ItemAdd.ItemIffId := CARDDATA.CHAR_TYPEID;
  ItemAdd.Transaction := True;
  ItemAdd.Quantity := 1;
  ItemAdd.Day := 0;

  PL.Inventory.AddItem(ItemAdd);

  if PL.Inventory.ItemCharacter.sCard.UpdateCard(PL.GetUID, PLCharacter.Index, PLCharacter.TypeID, 0, Data.Slot, 0, 0).Key then
  begin
    Transac := TTransacItem.Create;
    with Transac do
    begin
      Types := $CB;
      TypeID := PLCharacter.TypeID;
      Index := PLCharacter.Index;
      PreviousQuan := 0;
      NewQuan := 0;
      UCC := Nulled;
      CardTypeID := 0;
      CharSlot := Data.Slot;
    end;

    PL.Inventory.Transaction.Add(Transac);

    PL.SendTransaction;

    Packet := TClientPacket.Create;
    try
      Packet.WriteStr(#$73#$02);
      Packet.WriteUInt32(0);
      Packet.WriteUInt32(CARDDATA.CARD_TYPEID);

      PL.Send(Packet);
    finally
      Packet.Free;
    end;
  end;
end;

procedure PlayerMemorialGacha(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  TypeID: UInt32;
  RemoveData: TAddData;
  AddItem: TAddItem;
  Packet: TClientPacket;
  // ## for normal item
  NormalItem: TList<PSpecialItem>;
  PNormal: PSpecialItem;
  // ## for rare item
  RareItem: TItemRandomClass;
  PRare: PItemRandom;
  // ## rand
  RandInt: UInt32;
  ListSet: TList<TPair<UInt32, UInt32>>;
  Enum: TPair<UInt32, UInt32>;
begin
  if not ClientPacket.ReadUInt32(TypeID) then Exit;

  if not IffEntry.FMemorialCoin.IsExist(TypeID) then
  begin
    PL.Send(#$64#$02#$85#$73#$55#$00);
    raise Exception.Create('HandlePlayerMemorialGacha: coin was not found');
  end;

  RemoveData := PL.Inventory.Remove(TypeId, 1);

  if not RemoveData.Status then
  begin
    PL.Send(#$64#$02#$85#$73#$55#$00);
    raise Exception.Create('HandlePlayerMemorialGacha: Player don''t have that coin TypeID');
  end;

  RandInt := Rand.RandInt(1, 150);

  if RandInt <= 7 then
  begin
    Packet := TClientPacket.Create;
    RareItem := IffEntry.FMemorialRare.GetRareItem(TypeId, IffEntry.FMemorialCoin.GetPool(TypeID));
    try
      while True do
      begin
        PRare := nil;
        if RareItem.GetLeft <= 0 then
          Break;
        PRare := RareItem.GetItems;
        if not PL.Inventory.IsExist(PRare.TypeId) then
          Break;
      end;

      if PRare = nil then
      begin
        PL.Send(#$64#$02#$AD#$F9#$56#$00);
        raise Exception.Create('HandlePlayerMemorialGacha: Player is owned everything in memorial gacha');
      end;

      if GetItemGroup(PRare.TypeId) = $9  then
      begin
        ListSet := IffEntry.FSets.SetList(PRare.TypeId);
        try
          if ListSet.Count <= 0 then
            Exit; // ## should not be happened

          for Enum in ListSet do
          begin
            with AddItem do
            begin
              ItemIffId := Enum.Key;
              Quantity := Enum.Value;
              Transaction := True;
              Day := 0; // ## set should not be limited time in their set
            end;
            PL.AddItem(AddItem);
          end;
        finally
          FreeAndNil(ListSet);
        end;
      end else begin
        AddItem.ItemIffId := PRare.TypeId;
        AddItem.Quantity := PRare.MaxQuantity;
        AddItem.Transaction := True;
        AddItem.Day := 0;

        PL.AddItem(AddItem);
      end;

      PL.SendTransaction;

      Packet.WriteStr(#$64#$02);
      Packet.WriteUInt32(0);
      Packet.WriteUInt32(1);
      Packet.WriteUInt32(PRare.RareType);
      Packet.WriteUInt32(PRare.TypeId);
      Packet.WriteUInt32(Prare.MaxQuantity);

      PL.Send(Packet);

      // ## log
      LogMemorial(PL, IffEntry.GetItemName(PRare.TypeId), PRare.MaxQuantity);
    finally
      FreeAndNil(RareItem);
      FreeAndNil(Packet);
    end;
  end
  else
  begin
    Packet := TClientPacket.Create;
    NormalItem := IffEntry.FMemorialRare.GetNormalItem(TypeID);
    try
      // ## add to item list
      for PNormal in NormalItem do
      begin
        AddItem.ItemIffId := PNormal.TypeID;
        AddItem.Quantity := PNormal.Quantity;
        AddItem.Transaction := True;
        AddItem.Day := 0;
        // ## add to warehouse
        PL.AddItem(AddItem);
      end;
      // ## send transaction
      PL.SendTransaction;
      // ## end
      Packet.WriteStr(#$64#$02);
      Packet.WriteUInt32(0);
      Packet.WriteUInt32(NormalItem.Count);
      for PNormal in NormalItem do
      begin
        Packet.WriteStr(#$FF#$FF#$FF#$FF);
        Packet.WriteUInt32(PNormal.TypeID);
        Packet.WriteUInt32(PNormal.Quantity);
      end;
      PL.Send(Packet);
    finally
      NormalItem.Clear;
      FreeAndNil(NormalItem);
      FreeAndNil(Packet);
    end;
  end;
end;

procedure PlayerCardSpecial(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  TypeID: UInt32;
  C: TPair<Boolean, PIffCard>;
  CP: TPair<Boolean, PCardEquip>;
  Packet: TClientPacket;
  Remove: TAddData;
  GetDate: TDateTime;
begin
  GetDate := Now();

  if not ClientPacket.ReadUInt32(TypeID) then Exit;

  C := IffEntry.FCards.GetCardSPCL(TypeID);
  if (False = C.Key) or (not (GetCardType(TypeID) = tSpecial)) then Exit;

  Remove := PL.Inventory.Remove(TypeID, 1, False);
  if not Remove.Status then Exit;

  case C.Value.Base.TypeID of
    $7C800000, $7C800022, $7C800034:
      begin
        PL.AddExp(C.Value.EffectQty);
      end;
    $7C80001F:
      begin
        PL.AddPang(C.Value.EffectQty);
      end
  else
    begin
      CP := PL.Inventory.ItemCharacter.sCard.UpdateCard(PL.GetUID, 0, 0, TypeID, 0, 1, C.Value.Time);
      if not CP.Key then
        Exit;
      GetDate := CP.Value.ENDDATE;
    end;
  end;

  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteStr(#$60#$01);
      WriteUInt32(0);
      WriteUInt32(Remove.ItemIndex);
      WriteUInt32(Remove.ItemTypeID);
      WriteStr(#$00, $C);
      WriteUInt32(1);
      WriteStr(GetFixTime(Now()));
      WriteStr(GetFixTime(GetDate));
      WriteStr(#$00#$00);
      PL.Send(Packet);
    end;

    case C.Value.Base.TypeID of
      $7C800000, $7C800022, $7C800034:
        begin
          PL.SendExp;
        end;
      $7C80001F:
        begin
          PL.SendPang;
        end;
    end;

  finally
    Packet.Free;
  end;
end;

procedure LogMemorial(const PL: TClientPlayer; const ItemName: AnsiString; Quantity: UInt32);
var
  Con: TFDConnection;
  Query: TFDQuery;
begin
  CreateQuery(Query, Con);
  try
    Query.ExecSQL('EXEC [dbo].[ProcLogMemorial] @UID = :UID, @ItemName = :NAME, @Quantity = :QUAN', [PL.GetUID, ItemName, Quantity]);
  finally
    FreeQuery(Query, Con);
  end;
end;


end.
