unit ScratchCard;

interface

uses
  Math, Tools, SysUtils, PangyaClient, ClientPacket, PangyaBuffer, ItemData, RandomItem, SyncObjs;

type
  TScratchCard = class
    private
      var FRandomWeight : TItemRandomClass;
      var Lock: TCriticalSection;
    public
      procedure HandlePlayerOpenScratchCard(Const Player : TClientPlayer);
      procedure HandlePlayerScratchCard(Const Player : TClientPlayer);
      constructor Create;
      Destructor Destroy; override;
  end;

  var
    Scratch: TScratchCard;

implementation

{ TScratchCard }

procedure TScratchCard.HandlePlayerScratchCard(const Player: TClientPlayer);
var
  Packet : TClientPacket;
  ItemData : TAddData;
  Count, I, IQuantity : Byte;
  Reward : PItemRandom;
  Supply : PSupplies;
  AddItemData: TAddItem;
begin
  Lock.Acquire;
  try
    for Supply in FRandomWeight.Supply do
    begin
      ItemData := Player.Inventory.Remove(Supply.TypeId, Supply.DelQuantity);
      if ItemData.Status then
      begin
        Break;
      end;
    end;

    if not ItemData.Status then // ## item can't be deleted
    begin
      Player.Send(#$DD#$00#$E4#$C6#$2D#$00);
      Exit;
    end;

    Packet := TClientPacket.Create;
    try
      Randomize;
      if Random($64) < 10 then
        Count := 2
      else
        Count := 1;

      Packet.WriteUInt32(Count);

      for I := 1 to Count do
      begin
        Reward := FRandomWeight.GetItems;

        Randomize;
        if Random($64) < 10 then
          IQuantity := Reward.MaxQuantity
        else
          IQuantity := 1;

        with AddItemData do
        begin
          ItemIffId := Reward.TypeId;
          Quantity := IQuantity;
          Transaction := True;
          Day := 0;
        end;

        ItemData := Player.AddItem(AddItemData);

        Packet.WriteStr(#$00, 4);
        Packet.WriteUInt32(ItemData.ItemTypeID);
        Packet.WriteUInt32(ItemData.ItemIndex);
        Packet.WriteUInt32(IQuantity);
        Packet.WriteStr(#$00, 4);
      end;

      Player.SendTransaction;
      Player.Send(#$DD#$00#$00#$00#$00#$00 + Packet.ToStr);
      FRandomWeight.Restore;
    finally
      FreeAndNil(Packet);
    end;
  finally
    Lock.Release;
  end;
end;

constructor TScratchCard.Create;
begin
  FRandomWeight := TItemRandomClass.Create;
  Lock := TCriticalSection.Create;

  // Card Remover
  FRandomWeight.AddItems(436207810, 1, 0 ,10);
  // Replay Tape
  FRandomWeight.AddItems(436207695, 2, 0 ,100);
  // Dual Lucky Pangya
  FRandomWeight.AddItems(402653194, 2, 0 ,100);
  // Oblivion Flower
  FRandomWeight.AddItems(402653198, 2, 0 ,100);
  // Dual Tran
  FRandomWeight.AddItems(402653195, 2, 0 ,100);
  // Power Calippers
  FRandomWeight.AddItems(402653193, 2, 0 ,100);
  // Silent Wind
  FRandomWeight.AddItems(402653190, 2, 0 ,100);

  // Supplies
  FRandomWeight.AddSupply(436207664); // Gift
  FRandomWeight.AddSupply(436207667); // Event
  FRandomWeight.AddSupply(436207668); // GM

  FRandomWeight.SetCanDup(False);
end;

destructor TScratchCard.Destroy;
begin
  FreeAndNil(FRandomWeight);
  FreeAndNil(Lock);
  inherited;
end;

procedure TScratchCard.HandlePlayerOpenScratchCard(Const Player: TClientPlayer);
begin
  Player.Send(#$EB#$01#$00#$00#$00#$00#$00);
end;

initialization
  begin
    Scratch := TScratchCard.Create;
  end;

finalization
  begin
    FreeAndNil(Scratch);
  end;

end.
