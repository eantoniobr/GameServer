unit GameShopCore;

interface

uses
  System.SysUtils, System.Generics.Collections,PangyaClient, ClientPacket, IffMain, Enum,
  Defines, System.DateUtils, ErrorCode, Tools, PacketCreator, ItemData;

procedure PlayerEnterGameShop(const PL: TClientPlayer);
procedure PlayerBuyItemGameShop(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure AddShopItem(const PL: TClientPlayer; const ShopItem: TShopItemRequest);
procedure AddShopRentItem(const PL: TClientPlayer; const ShopItem: TShopItemRequest);
function CheckData(AddData: TAddData): TBuyItem;

implementation

procedure PlayerEnterGameShop(const PL: TClientPlayer);
begin
  PL.Send(#$0E#$02#$00#$00#$00#$00#$00#$00#$00#$00);
end;

{
 1 = Buying Failed
 2 = Pang is not enought
 3 = Password is wrong
 4 = You once bought this item
 9 = Please check the time to use this item
 11 = Please check the sell time
 16 = You are using this item
 17 = You are using this item
 18 = You can not buy this item
 19 = You can not buy this item
 21 = You too much bought this item
 23 = Cookie is not enought
 24 = Failed to update cookie
 35 = This item is expire
 36 = This item can not be purchased, Please wait
 37,38,39,40 = You once bought this item
 41 = Send mail box successfully
 44,45 = Your Level is not enought to buy this item
 46 = This channel can not use this system
 53 = Asking or using about cash is not permitted rigt now

}

procedure PlayerBuyItemGameShop(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  BuyType: UInt8;
  BuyTotal: UInt16;
  Count: UInt8;
  ShopItem: TShopItemRequest;
  DeletePang, DeleteCookie: UInt32;
  RentalPice: UInt32;
const
  PacketID: TChar = #$68#$00;
  procedure SendCode(Code: UInt32);
  var
    IPacket: TClientPacket;
  begin
    IPacket := TClientPacket.Create;
    try
      IPacket.WriteStr(PacketID);
      IPacket.WriteUInt32(Code);
      PL.Send(IPacket);
    finally
      FreeAndNil(IPacket);
    end;
  end;
begin
  if not ClientPacket.ReadUInt8(BuyType) then Exit;
  if not ClientPacket.ReadUInt16(BuyTotal) then Exit;

  case BuyType of
    0:
      begin
        for Count := 0 to BuyTotal - 1 do
        begin
          if not ClientPacket.Read(ShopItem.UN1, SizeOf(TShopItemRequest)) then
          begin
            SendCode(1);
            Exit;
          end;

          if not IffEntry.IsExist(ShopItem.IffTypeId) then
          begin
            SendCode(3);
            Exit;
          end;

          if not IffEntry.IsBuyable(ShopItem.IffTypeId) then
          begin
            SendCode($13);
            Exit;
          end;

          if not PL.Inventory.Available(ShopItem.IffTypeId, ShopItem.IffQty) then
          begin
            SendCode(1);
            Exit;
          end;

          if IffEntry.GetPrice(ShopItem.IffTypeId, ShopItem.IffDay) <= 0 then
          begin
            SendCode(1);
            Exit;
          end;

          case IffEntry.GetShopPriceType(ShopItem.IffTypeId) of
            0, 2: // Pang
              begin
                DeletePang := IffEntry.GetPrice(ShopItem.IffTypeId, ShopItem.IffDay) * ShopItem.IffQty;
                if not PL.RemovePang(DeletePang) then
                begin
                  SendCode(2);
                  raise Exception.CreateFmt('HandlePlayerBuyItemGameShop: Cannot delete player''s %d pang(s)',[DeletePang]);
                end;
              end;
            1: // Cookie
              begin
                DeleteCookie := IffEntry.GetPrice(ShopItem.IffTypeId, ShopItem.IffDay);
                if not PL.RemoveCookie(DeleteCookie) then
                begin
                  SendCode($17);
                  raise Exception.CreateFmt('HandlePlayerBuyItemGameShop: Cannot delete player''s %d cookie(s)',[DeleteCookie]);
                end;
              end;
          end;

          AddShopItem(PL, ShopItem);
        end;
      end;
    1: // Rental
      begin
        for Count := 0 to BuyTotal - 1 do
        begin
          if not ClientPacket.Read(ShopItem.UN1, SizeOf(TShopItemRequest)) then
          begin
            SendCode(1);
            Exit;
          end;

          if not (GetItemGroup(ShopItem.IffTypeId) = $2) then
          begin
            SendCode(36);
            Exit;
          end;

          if not IffEntry.IsExist(ShopItem.IffTypeId) then
          begin
            SendCode(3);
            Exit;
          end;

          if not IffEntry.IsBuyable(ShopItem.IffTypeId) then
          begin
            SendCode($13);
            Exit;
          end;

          if PL.Inventory.IsExist(ShopItem.IffTypeId) then
          begin
            SendCode(37);
            Exit;
          end;

          // ## get rent price
          RentalPice := IffEntry.GetRentalPrice(ShopItem.IffTypeId);

          if RentalPice <= 0 then
          begin
            SendCode(36);
            Exit;
          end;

          // ## delete pang
          if not PL.RemovePang(RentalPice) then
          begin
            SendCode(2);
            raise Exception.CreateFmt('HandlePlayerBuyItemGameShop: rental cannot delete player''s %d pang(s)', [DeletePang]);
          end;

          AddShopRentItem(PL, ShopItem);
        end;
      end;
  end;
  PL.Write(ShowBuyItemSucceed(PL.GetPang, PL.GetCookie));
end;

procedure AddShopItem(const PL: TClientPlayer; const ShopItem: TShopItemRequest);
var
  ListSet: TList<TPair<UInt32, UInt32>>;
  Enum: TPair<UInt32, UInt32>;
  ItemAddedData: TAddData;
  ItemAddData: TAddItem;
  DataBuy: TBuyItem;
begin
  if GetItemGroup(ShopItem.IffTypeId) = $9 then
  begin
    ListSet := IffEntry.FSets.SetList(ShopItem.IffTypeId);
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
          Transaction := False;
          Day := 0; // ## set should not be limited time in their set
        end;
        ItemAddedData := PL.AddItem(ItemAddData);
        DataBuy := CheckData(ItemAddedData);
        PL.Write(ShowBuyItem(ItemAddedData, DataBuy, PL.GetPang, PL.GetCookie));
      end;
    finally
      FreeAndNil(ListSet);
    end;
  end else begin
    with ItemAddData do
    begin
      ItemIffId := ShopItem.IffTypeId;
      Quantity := IffEntry.GetRealQuantity(ShopItem.IffTypeId, ShopItem.IffQty);
      Transaction := False;
      Day := ShopItem.IffDay;
    end;
    ItemAddedData := PL.AddItem(ItemAddData);
    DataBuy := CheckData(ItemAddedData);
    PL.Write(ShowBuyItem(ItemAddedData, DataBuy, PL.GetPang, PL.GetCookie));
  end;
end;

procedure AddShopRentItem(const PL: TClientPlayer; const ShopItem: TShopItemRequest);
var
  ItemAddedData: TAddData;
  DataBuy: TBuyItem;
begin

  ItemAddedData := PL.Inventory.AddRent(ShopItem.IffTypeId);

  with DataBuy do
  begin
    Flag := $6;
    DayTotal := $7;
    EndDate := 0;
  end;

  PL.Write(ShowBuyItem(ItemAddedData, DataBuy, PL.GetPang, PL.GetCookie));
end;

function CheckData(AddData: TAddData): TBuyItem;
begin
  case TITEMGROUP(GetItemGroup(AddData.ItemTypeID)) of
    ITEM_TYPE_CADDIE:
      begin
        if AddData.ItemEndDate > Now() then
        begin
          Result.Flag := 1;
          Result.DayTotal := DaysBetween(AddData.ItemEndDate, Now()) + 1;
          Result.EndDate := AddData.ItemEndDate;
        end
        else
        begin
          Result.Flag := 0;
          Result.DayTotal := 0;
          Result.EndDate := 0;
        end;
      end;
    ITEM_TYPE_SKIN:
      begin
        if AddData.ItemEndDate > Now() then
        begin
          Result.Flag := 4;
          Result.DayTotal := DaysBetween(AddData.ItemEndDate, Now()) + 1;
          Result.EndDate := 0;
        end
        else
        begin
          Result.Flag := 0;
          Result.DayTotal := 0;
          Result.EndDate := 0;
        end;
      end;
    ITEM_TYPE_MASCOT:
      begin
        if AddData.ItemEndDate > Now() then
        begin
          Result.Flag := 4;
          Result.DayTotal := DaysBetween(AddData.ItemEndDate, Now()) + 1;
          Result.EndDate := 0;
        end
        else
        begin
          Result.Flag := 0;
          Result.DayTotal := 0;
          Result.EndDate := 0;
        end;
      end;
    else
    begin
      Result.Flag := 0;
      Result.DayTotal := 0;
      Result.EndDate := 0;
    end;
  end;
end;

end.
