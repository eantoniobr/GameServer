unit ClubSystemCore;

interface

uses
  System.SysUtils, ClientPacket, PangyaClient, ErrorCode, Enum, uWarehouse,
  ItemData, ClubData, Defines, PacketCreator, Tools, System.Math;

procedure PlayerUpgradeClub(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerUpgradeClubAccept(const PL: TClientPlayer);
procedure PlayerUpgradeClubCancel(const PL: TClientPlayer);
procedure PlayerUpgradeRank(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerUseAbbot(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerUseClubPowder(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerUpgradeClubSlot(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerTransferClubPoint(const PL: TClientPlayer;const ClientPacket: TClientPacket);

implementation

procedure PlayerUpgradeClub(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TClubUpgrade = packed record
    var ItemTypeID: UInt32;
    var ItemQty: UInt16;
    var ClubIndex: UInt32;
  end;
const
  PacketID: TChar = #$3D#$02;
var
  ClubData: TClubUpgrade;
  ClubInfo: TClubStatus;
  Club: PItem;
  RemoveItem: TAddData;
  GetType: ShortInt;
  Packet: TClientPacket;
  function Check: Boolean;
  begin
    Result := ((ClubData.ItemTypeID = $1A00020F) or (ClubData.ItemTypeID = $7C800026)) and (ClubData.ItemQty > 0);
  end;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
begin
  if (not ClientPacket.Read(ClubData, SizeOf(TClubUpgrade))) or (not Check) then begin
    SendCode(READ_PACKET_ERROR);
    Exit;
  end;

  Club := PL.Inventory.ItemWarehouse.GetClub(ClubData.ClubIndex, gcIndex);

  if (Club = nil) then
  begin
    SendCode(CLUBSET_NOT_FOUND_OR_NOT_EXIST);
    Exit;
  end;

  RemoveItem := PL.Inventory.Remove(ClubData.ItemTypeID, ClubData.ItemQty, True);
  if not RemoveItem.Status then
  begin
    SendCode(REMOVE_ITEM_FAIL);
    Exit;
  end;

  ClubInfo := Club^.GetClubSlotStatus;
  ClubInfo := PlayerGetClubSlotLeft(Club^.ItemTypeID ,ClubInfo);

  GetType := PlayerGetSlotUpgrade(ClubData.ItemTypeID, ClubData.ItemQty, ClubInfo);

  if GetType <= -1 then
  begin
    SendCode(CLUBSET_SLOT_FULL);
    Exit;
  end;

  if not Club.AddClubSlot(GetType) then
  begin
    SendCode(CLUBSET_SLOT_FULL);
    Exit;
  end;

  PL.FClubTemporary.PClub := Club;
  PL.FClubTemporary.UpgradeType := GetType;
  PL.FClubTemporary.Count := 1;

  Packet := TClientPacket.Create;;
  try
    Packet.WriteStr(#$3D#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(GetType);
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure PlayerUpgradeClubAccept(const PL: TClientPlayer);
const
  PacketID: TChar = #$3E#$02;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
var
  Packet: TClientPacket;
begin
  if (PL.FClubTemporary.PClub = nil) then
  begin
    SendCode(CLUBSET_NOT_FOUND_OR_NOT_EXIST);
    Exit;
  end;

  // ## add transaction
  PL.Inventory.Transaction.AddClubSystem(PItem(PL.FClubTemporary.PClub));

  PL.SendTransaction;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$3E#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(PL.FClubTemporary.UpgradeType);
    Packet.WriteUInt32(PItem(PL.FClubTemporary.PClub).ItemIndex);
    PL.Send(Packet.ToStr);
  finally
    PL.FClubTemporary.Clear;
    FreeAndNil(Packet);
  end;
end;

procedure PlayerUpgradeClubCancel(const PL: TClientPlayer);
const
  PacketID: TChar = #$3F#$02;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
var
  Packet: TClientPacket;
begin
  if (PL.FClubTemporary.PClub = nil) then
  begin
    SendCode(CLUBSET_NOT_FOUND_OR_NOT_EXIST);
    Exit;
  end;

  if PItem(PL.FClubTemporary.PClub).ItemClubSlotCancelledCount >= 5 then
  begin
    SendCode(CLUBSET_CANNOT_CANCEL);
    Exit;
  end;

  if not ( PItem(PL.FClubTemporary.PClub).RemoveClubSlot(PL.FClubTemporary.UpgradeType) ) then
  begin
    SendCode(CLUBSET_FAIL_CANCEL);
    Exit;
  end;

  // ## add transaction
  PL.Inventory.Transaction.AddClubSystem(PItem(PL.FClubTemporary.PClub));

  PL.SendTransaction;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$3F#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(PItem(PL.FClubTemporary.PClub).ItemIndex);
    PL.Send(Packet.ToStr);
  finally
    PL.FClubTemporary.Clear;
    FreeAndNil(Packet);
  end;
end;

// ## 01 = succeed upgrade
// ## 02 = succeed downgrade
// ## 03 = not enought pang for upgrade
// ## 04 = no more slot for upgrade
// ## 05 = no slot for downgrade
procedure PlayerUpgradeClubSlot(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TActionType = ( atUpgrade = $1, atDowngrade = $3 );
  TRead = packed record
    var Action: TActionType;
    var Level: UInt8;
    var Slot: TCLUB_STATUS;
    var ClubIndex: UInt32;
  end;
var
  ClubData: TRead;
  GetClub: TClubUpgradeData;
  Club: PItem;
begin
  if not ClientPacket.Read(ClubData, SizeOf(TRead)) then Exit;

  Club := PL.Inventory.ItemWarehouse.GetClub(ClubData.ClubIndex, gcIndex);

  if Club = nil then
  begin
    PL.Send(#$A5#$00#$04);
    Exit;
  end;

  case ClubData.Action of
    atUpgrade:
      begin
        GetClub := Club.ClubSlotAvailable(ClubData.Slot);
        if not GetClub.Able then
        begin
          PL.Send(#$A5#$00#$04);
          Exit;
        end;
        if not PL.RemovePang(GetClub.Pang) then
        begin
          PL.Send(#$A5#$00#$03);
          Exit;
        end;
        if Club.ClubAddStatus(ClubData.Slot) then
        begin
          Inc(Club.ItemClubPangLog, GetClub.Pang);
          PL.Write(ShowClubUpgrade(ClubData.Slot, Club.ItemIndex, GetClub.Pang));
          PL.SendPang;
        end;
      end;
    atDowngrade:
      begin
        if Club.ClubRemoveStatus(ClubData.Slot) then
        begin
          PL.Write(ShowClubDowngrade(ClubData.Slot, Club.ItemIndex, 0));
          PL.SendPang;
        end else
        begin
          PL.Send(#$A5#$00#$05);
        end;
      end;
  end;
end;

procedure PlayerUpgradeRank(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TClubUpgrade = packed record
    var ItemTypeID: UInt32;
    var ItemQty: UInt16;
    var ClubIndex: UInt32;
  end;
var
  UpgradeData: TClubUpgrade;
  UpgradeInfo: TClubUpgradeRank;
  Club: PItem;
  GetType: ShortInt;
  Packet: TClientPacket;
  RemoveItem: TAddData;
  function Check: Boolean;
  begin
    Result := (UpgradeData.ItemTypeID = $7C800041){ and (UpgradeData.ItemQty >= 0)};
  end;
const
  PacketID: TChar = #$40#$02;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
begin
  if (not ClientPacket.Read(UpgradeData, SizeOf(TClubUpgrade))) or (not Check) then
  begin
    SendCode(READ_PACKET_ERROR);
    Exit;
  end;

  Club := PL.Inventory.ItemWarehouse.GetItem(UpgradeData.ClubIndex);

  if (Club = nil) or (not (GetItemGroup(Club^.ItemTypeID) = $4)) then
  begin
    SendCode(CLUBSET_NOT_FOUND_OR_NOT_EXIST);
    Exit;
  end;

  UpgradeInfo := PlayerGetCLubRankUPData(Club^.ItemTypeID, Club^.GetClubSlotStatus);

  if UpgradeInfo.ClubPoint <= 0 then
  begin
    SendCode(CLUBSET_NOT_ENOUGHT_POINT_FOR_UPGRADE); // TODO: This must be showned as cannot rank up anymore
    Exit;
  end;

  GetType := PlayerGetSlotUpgrade(UpgradeData.ItemTypeID, UpgradeData.ItemQty, UpgradeInfo.ClubSlotLeft);

  if GetType <= -1 then
  begin
    SendCode(CLUBSET_CANNOT_ADD_SLOT);
    Exit;
  end;

  {/* remove soren card */}
  RemoveItem := PL.Inventory.Remove(UpgradeData.ItemTypeID, UpgradeData.ItemQty, True);
  if not RemoveItem.Status then
  begin
    SendCode(REMOVE_ITEM_FAIL);
    Exit;
  end;

  if not Club^.RemoveClubPoint(UpgradeInfo.ClubPoint) then
  begin
    SendCode(CLUBSET_NOT_ENOUGHT_POINT_FOR_UPGRADE);
    Exit;
  end;

  // Add To Log
  Inc(Club^.ItemClubPointLog, UpgradeInfo.ClubPoint);

  if not Club^.AddClubSlot(GetType) then
  begin
    SendCode(CLUBSET_CANNOT_ADD_SLOT);
    Exit;
  end;

  {* this is used for add club slot when rank is up to Special *}
  if UpgradeInfo.ClubCurrentRank >= 4 then
  begin
    if not Club^.AddClubSlot(UpgradeInfo.ClubSPoint) then
    begin
      SendCode(CLUBSET_CANNOT_ADD_SLOT);
      Exit;
    end;
  end;

  // ## add transaction
  PL.Inventory.Transaction.AddClubSystem(Club);

  PL.SendTransaction;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$40#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(GetType);
    Packet.WriteUInt32(Club^.ItemIndex);
    PL.Send(Packet.ToStr);
  finally
    PL.FClubTemporary.Clear;
    FreeAndNil(Packet);
  end;
end;

procedure PlayerUseAbbot(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TAbbotData = packed record
    var SupplyTypeID: UInt32;
    var ClubIndex: UInt32;
  end;
const
  PacketID: TChar = #$46#$02;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
var
  AbbotData: TAbbotData;
  ClubInfo: PItem;
  RemoveItem: TAddData;
  function Check: Boolean;
  begin
    Result := (AbbotData.SupplyTypeID = $1A000210);
  end;
begin
  if not ClientPacket.Read(AbbotData, SizeOf(TAbbotData)) or (not Check) then
  begin
    SendCode(READ_PACKET_ERROR);
    Exit;
  end;

  ClubInfo := PL.Inventory.ItemWarehouse.GetItem(AbbotData.ClubIndex);

  if (ClubInfo = nil) or (not (GetItemGroup(ClubInfo^.ItemTypeID) = $4)) then
  begin
    SendCode(CLUBSET_NOT_FOUND_OR_NOT_EXIST);
    Exit;
  end;

  if ClubInfo^.ItemClubSlotCancelledCount <= 0 then
  begin
    SendCode(CLUBSET_ABBOT_NOT_READY);
    Exit;
  end;

  RemoveItem := PL.Inventory.Remove(AbbotData.SupplyTypeID, 1, True);
  if not RemoveItem.Status then
  begin
    SendCode(REMOVE_ITEM_FAIL);
    Exit;
  end;

  // ## reset
  ClubInfo^.ItemClubSlotCancelledCount := 0;

  // ## add transaction
  PL.Inventory.Transaction.AddClubSystem(ClubInfo);
  PL.SendTransaction;

  PL.Send(#$46#$02#$00#$00#$00#$00);
end;

procedure PlayerUseClubPowder(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TClubPowerData = packed record
    var SupplyTypeID: UInt32;
    var ClubIndex: UInt32;
  end;
var
  ClubData: TClubPowerData;
  ClubInfo: PItem;
  RemoveItem: TAddData;
  Packet: TClientPacket;
  Tran: TTransacItem;
const
  PacketID: TChar = #$47#$02;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
  function Check: Boolean;
  begin
    Result := (ClubData.SupplyTypeID = $1A00024B) or (ClubData.SupplyTypeId = $1A000247);
  end;
  {
  47 02 00 1A,436208199=Titan Boo Powder L
  4B 02 00 1A,436208203=Titan Boo Powder H
  }
begin
  if not ClientPacket.Read(ClubData, SizeOf(TClubPowerData)) or (not Check) then
  begin
    SendCode(READ_PACKET_ERROR);
    Exit;
  end;

  ClubInfo := PL.Inventory.ItemWarehouse.GetClub(ClubData.ClubIndex, gcIndex);

  if (ClubInfo = nil) then
  begin
    SendCode(CLUBSET_NOT_FOUND_OR_NOT_EXIST);
    Exit;
  end;

  if not ClubInfo^.ClubSetCanReset then
  begin
    SendCode(CLUBSET_CANNOT_CANCEL);
    Exit;
  end;

  RemoveItem := PL.Inventory.Remove(ClubData.SupplyTypeID, 1, True);
  if not RemoveItem.Status then
  begin
    SendCode(REMOVE_ITEM_FAIL);
    Exit;
  end;

  if ClubData.SupplyTypeID = $1A00024B then
  begin
    PL.AddPang( Round(ClubInfo^.ItemClubPangLog/2) );
    PL.SendPang;
    Inc(ClubInfo^.ItemClubPoint, Round(ClubInfo^.ItemClubPointLog/2) );
  end;

  // Reset club point
  ClubInfo^.ClubSetReset;

  // ## add transaction
  PL.Inventory.Transaction.AddClubSystem(ClubInfo);

  Tran := TTransacItem.Create;
  with Tran do
  begin
    Types := $C9;
    TypeID := ClubInfo^.ItemTypeID;
    Index := ClubInfo^.ItemIndex;
    PreviousQuan := 0;
    NewQuan := 0;
    UCC := Nulled;
  end;
  // ## add transaction
  PL.Inventory.Transaction.Add(Tran);
  PL.SendTransaction;

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$47#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(ClubInfo^.ItemTypeID);
    Packet.WriteUInt32(ClubInfo^.ItemIndex);
    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
  end;
end;

procedure PlayerTransferClubPoint(const PL: TClientPlayer;const ClientPacket: TClientPacket);
type
  TClubTrasfer = packed record
    var SupplyTypeID: UInt32;
    var ClubIndex: UInt32;
    var ClubMoveToIndex: UInt32;
    var Quantity: UInt32;
  end;
var
  ClubMoveData: TClubTrasfer;
  ClubToMove, ClubMoveTo: PItem;
  RemoveItem: TAddData;
  TotalPoint: UInt32;
const
  PacketID: TChar = #$45#$02;
  ItemMovePoint: UInt16 = 300;
  procedure SendCode(Code: TChar);
  begin
    PL.Send(PacketID + Code);
  end;
  function Check: Boolean;
  begin
    Result := (ClubMoveData.SupplyTypeID = $1A000211) and (ClubMoveData.Quantity > 0);
  end;
begin
  if (not ClientPacket.Read(ClubMoveData, SizeOf(TClubTrasfer))) or (not Check) then
  begin
    SendCode(READ_PACKET_ERROR);
    Exit;
  end;

  ClubToMove := PL.Inventory.ItemWarehouse.GetClub(ClubMoveData.ClubIndex, gcIndex);
  ClubMoveTo := PL.Inventory.ItemWarehouse.GetClub(ClubMoveData.ClubMoveToIndex, gcIndex);

  if (ClubToMove = nil) or (ClubMoveTo = nil) or
    (not(GetItemGroup(ClubToMove^.ItemTypeID) = $4)) or
    (not(GetItemGroup(ClubMoveTo^.ItemTypeID) = $4)) then
  begin
    SendCode(CLUBSET_NOT_FOUND_OR_NOT_EXIST);
    Exit;
  end;

  TotalPoint := ClubMoveData.Quantity * ItemMovePoint;

  if ClubToMove^.GetClubPoint < TotalPoint then
  begin
    TotalPoint := ClubToMove^.GetClubPoint;
  end;

  if not (Ceil(TotalPoint/ItemMovePoint) = Integer(ClubMoveData.Quantity)) then Exit;

  if (ClubMoveTo^.GetClubPoint + TotalPoint) > 99999 then
  begin
    SendCode(CLUBSET_POINTFULL_OR_NOTENOUGHT);
    Exit;
  end;

  // # REMOVE UCM CHIP #
  RemoveItem := PL.Inventory.Remove(ClubMoveData.SupplyTypeID, ClubMoveData.Quantity, True);
  if not RemoveItem.Status then
  begin
    SendCode(REMOVE_ITEM_FAIL);
    Exit;
  end;

  if ClubToMove.RemoveClubPoint(TotalPoint) then
  begin
    if not ClubMoveTo.AddClubPoint(TotalPoint) then
    begin
      SendCode(CLUBSET_POINTFULL_OR_NOTENOUGHT);
      Exit;
    end;
  end else
  begin
    SendCode(CLUBSET_POINTFULL_OR_NOTENOUGHT);
    Exit;
  end;

  // ## add transaction
  PL.Inventory.Transaction.AddClubSystem(ClubToMove);
  // ## add transaction
  PL.Inventory.Transaction.AddClubSystem(ClubMoveTo);
  PL.SendTransaction;

  PL.Send(#$45#$02#$00#$00#$00#$00);
end;

end.
