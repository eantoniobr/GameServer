unit PapelSystem;

interface

uses
  PangyaClient, ClientPacket, PangyaBuffer, RandomItem, ItemData, Math, Tools, SysUtils,
  System.Threading, System.SyncObjs;

type
  TPapelSystem = class
    private
      var RandomWeight : TItemRandomClass;
      var Locker : TCriticalSection;
    public
    procedure HandlePlayerOpenPapel(const Player: TClientPlayer);
    procedure HandlePlayerPlayNormalPapel(const Player: TClientPlayer);
    procedure HandlePlayerPlayBigPapel(const Player: TClientPlayer);
    constructor Create;
    Destructor Destroy; override;
  end;

  var Papel: TPapelSystem;

implementation

{ TPapelSystem }

constructor TPapelSystem.Create;
begin
  Locker := TCriticalSection.Create;

  RandomWeight := TItemRandomClass.Create;
  // Dual Tranquillizer
  RandomWeight.AddItems(402653195, 1, 1 , 1);

  // Dual Lucky Pangya
  RandomWeight.AddItems(402653194, 1, 1 , 1);
  // Oblivion Flower
  RandomWeight.AddItems(402653198, 1, 1 , 1);
  // Silent Wind
  RandomWeight.AddItems(402653190, 1, 1 , 1);
  // Power Calippers
  RandomWeight.AddItems(402653193, 1, 1 , 1);
  // Timer Booster
  RandomWeight.AddItems(436207633, 1, 1 , 1);
  // Replay Tape
  RandomWeight.AddItems(436207695, 1, 1 , 1);
  // Blue Star Comet
  RandomWeight.AddItems(335544322, 1, 1 , 1);
  // Love Love Comet
  RandomWeight.AddItems(335544323, 1, 1 , 1);
  // Bomber Comet
  RandomWeight.AddItems(335544321, 1, 1 , 1);
  // Water Comet
  RandomWeight.AddItems(335544325, 1, 1 , 1);

  // Tiki Report Paper
  RandomWeight.AddItems(436207681, 2, 0 , 10);
  // Bongdari CP(Event)
  RandomWeight.AddItems(436207656, 2, 0 , 10);
  // Scratch Card Slip
  RandomWeight.AddItems(436207677, 2, 0 , 10);
  // Scratch Card (Event)
  RandomWeight.AddItems(436207667, 1, 0 , 10);

  // Strength Boost
  RandomWeight.AddItems(402653188, 2, 0 , 100);
  // Spin Mastery
  RandomWeight.AddItems(402653184, 2, 0 , 100);
  // Tranquillizer
  RandomWeight.AddItems(402653192, 2, 0 , 100);
  // Lucky Pangya
  RandomWeight.AddItems(402653191, 2, 0 , 100);
  // Miracle Sign
  RandomWeight.AddItems(402653189, 2, 0 , 100);
  // Curve Mastery
  RandomWeight.AddItems(402653185, 2, 0 , 100);

  // Supplies
  RandomWeight.AddSupply(436207656); // Event
  RandomWeight.AddSupply(436207657); // Gift
  RandomWeight.AddSupply(436207658); // GM

  RandomWeight.SetCanDup(False);
end;

destructor TPapelSystem.Destroy;
begin
  FreeAndNil(RandomWeight);
  FreeAndNil(Locker);
  inherited;
end;

procedure TPapelSystem.HandlePlayerOpenPapel(const Player: TClientPlayer);
begin
  Player.Send(#$0B#$01#$FF#$FF#$FF#$FF#$FF#$FF#$FF#$FF#$00#$00#$00#$00);
end;

procedure TPapelSystem.HandlePlayerPlayBigPapel(const Player: TClientPlayer);
var
  Packet: TClientPacket;
  Count, IQuantity, I: UInt8;
  Reward: PItemRandom;
  ItemData: TAddData;
  Item: TAddItem;
begin
  Locker.Acquire;
  try
    if not Player.RemovePang(10000) then
    begin
      Player.Send(#$6C#$02#$7A#$73#$28#$00);
      Exit;
    end;

    Player.SendPang;

    Player.Send(#$FB#$00#$FF#$FF#$FF#$FF#$FD#$FF#$FF#$FF);

    Packet := TClientPacket.Create;

    try
      Randomize;
      Count := RandomRange(4, 10); {2,3,4,5}

      Packet.WriteUInt32(Count);

      for I := 1 to Count do
      begin
        Reward := RandomWeight.GetItems;

        if Random($64) <= 20 then
          IQuantity := RandomRange(3, 6) {3 4 5}
        else
          IQuantity := RandomRange(5, 10); {5 6 7 8 9}

        if (Reward.RareType = 1) or (Reward.RareType = 2) then
        begin
          IQuantity := 1;
        end;

        with Item do
        begin
          ItemIffId := Reward.TypeId;
          Quantity := IQuantity;
          Transaction := True;
          Day := 0;
        end;

        ItemData := Player.AddItem(Item);

        Packet.WriteUInt32(Random(3));
        Packet.WriteUInt32(ItemData.ItemTypeID);
        Packet.WriteUInt32(ItemData.ItemIndex);
        Packet.WriteUInt32(IQuantity);
        Packet.WriteUInt32(Reward.RareType);
      end;
      Packet.WriteUInt32(Player.GetPang);
      Packet.WriteUInt32(0);
      Packet.WriteUInt32(Player.GetCookie);
      Packet.WriteUInt32(0);

      Player.SendTransaction;
      Player.Send(#$6C#$02#$00#$00#$00#$00#$00#$00#$00#$00 + Packet.ToStr);

      { ** Achievement ** }
      { ** Add Papel Counter ** }
      //Player.AddAchivementQuest(1816133706, 10);
      //Player.SendAchievement;

      RandomWeight.Restore;
    finally
      FreeAndNil(Packet);
    end;
  finally
    Locker.Release;
  end;

end;

procedure TPapelSystem.HandlePlayerPlayNormalPapel(const Player: TClientPlayer);
var
  Packet: TClientPacket;
  Supply: PSupplies;
  ItemData: TAddData;
  Stuff: UInt32;
  Count, Quantity, I: UInt8;
  Reward: PItemRandom;
  Item: TAddItem;
begin
  Locker.Acquire;
  try
    Stuff := 0;

    for Supply in RandomWeight.Supply do
    begin
      ItemData := Player.Inventory.Remove(Supply.TypeId, Supply.DelQuantity);
      if ItemData.Status then
      begin
        Stuff := ItemData.ItemIndex;
        Break;
      end;
    end;

    if not ItemData.Status then // ## If Item can't be Deleted
    begin
      if not Player.RemovePang(900) then
      begin
        Player.Send(#$1B#$02#$7A#$73#$28#$00);
        Exit;
      end;
      Stuff := 0;
    end;

    Player.Send(#$FB#$00#$FF#$FF#$FF#$FF#$FD#$FF#$FF#$FF);

    Packet := TClientPacket.Create;
    try
      Randomize;

      if Random($64) + 1 < 20 then
        Count := RandomRange(3, 6) {3 4 5}
      else
        Count := RandomRange(2, 4); {2 3 }

      Packet.WriteUInt32(Stuff);
      Packet.WriteUInt32(Count);

      for I := 1 to Count do
      begin
        Reward := RandomWeight.GetItems;

        if Random($64) <= 20 then
          Quantity := Random(Reward.MaxQuantity) + 1
        else
          Quantity := 1;

        Item.ItemIffId := Reward.TypeId;
        Item.Quantity := Quantity;
        Item.Transaction := True;
        Item.Day := 0;

        ItemData := Player.AddItem(Item);

        Packet.WriteUInt32(Random(3));
        Packet.WriteUInt32(ItemData.ItemTypeID);
        Packet.WriteUInt32(ItemData.ItemIndex);
        Packet.WriteUInt32(Quantity);
        Packet.WriteUInt32(Reward.RareType);
      end;
      Packet.WriteUInt32(Player.GetPang);
      Packet.WriteUInt32(0);
      Packet.WriteUInt32(Player.GetCookie);
      Packet.WriteUInt32(0);

      Player.SendTransaction;
      Player.Send(#$1B#$02#$00#$00#$00#$00 + Packet.ToStr);

      { ** Achievement ** }
      { ** Add Papel Counter ** }
      //Player.AddAchivementQuest(1816133706, 1);
      //Player.SendAchievement;

      RandomWeight.Restore;
    finally
      FreeAndNil(Packet);
    end;
  finally
    Locker.Release;
  end;
end;

initialization
  begin
    Papel := TPapelSystem.Create;
  end;

finalization
  begin
    FreeAndNil(Papel);
  end;

end.
