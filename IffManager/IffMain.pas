unit IffMain;

interface

uses
  IffManager.Item, IffManager.SetItem, IffManager.Part, IffManager.Caddie, IffManager.Skin, IffManager.CaddieItem,
  IffManager.Mascot, IffManager.CutinInfo, IffManager.GrandPrixData, IffManager.Card, Math, Defines, IffManager.Club,
  IffManager.LevelUpPrizeItem, IffManager.Character, IffManager.MemorialShopCoinItem,
  IffManager.GrandPrixSpecialHole, IffManager.GPRankReward, IffManager.MemorialShopRareItem,
  IffManager.Ball, IffManager.CaddieMagic, IffManager.Auxpart;

type
  TIffManager = class
    private
      var Items : TIffItems;
      var SetITem: TIffSetItems;
      var Part: TIffParts;
      var Caddie: TIffCaddies;
      var Skin: TIffSkins;
      var CaddieItem : TIffCaddieItems;
      var Mascot: TIffMascots;
      var CutinInfo: TIffCutinInfos;
      var GrandPrix: TGrandPrixDataClass;
      var Card: TIffCards;
      var Club: TIffClubs;
      var LevelPrize: TIffLevelPrize;
      var Character: TIffCharacters;
      var Ball: TIffBalls;
      var GPSpecial: TIffGPSpecial;
      var GPReward: TGPRewardIff;
      var MemorialCoin: TIffMemorialCoin;
      var MemorialRare: TIffMemorialRare;
      var MgicBox: TIffMagicBoxs;
      var AuxPart: TIffAuxs;
      function GetItemGroup(TypeId: UInt32): UInt32;
    public
      constructor Create;
      destructor Destroy; override;
      function IsExist(TypeId: UInt32): Boolean;
      function GetItemName(TypeID: UInt32): AnsiString;
      function IsSelfDesign(TypeId : UInt32): Boolean;
      function GetSetItemStr(TypeId: UInt32): AnsiString;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeId: UInt32; ADay: UInt32 = 1): UInt32;
      function GetRealQuantity(TypeId: UInt32; Qty: UInt32): UInt32;
      function GetItemTimeFlag(TypeId: UInt32): UInt8;
      function GetRentalPrice(TypeID: UInt32): UInt32;

      property FItems : TIffItems read Items;
      property FSets : TIffSetItems read SetITem;
      property FParts : TIffParts read Part;
      property FCaddies : TIffCaddies read Caddie;
      property FSkins : TIffSkins read Skin;
      property FCaddieItem : TIffCaddieItems read CaddieItem;
      property FMascots : TIffMascots read Mascot;
      property FGrandPrixData: TGrandPrixDataClass read GrandPrix;
      property FCards: TIffCards read Card;
      property FClub: TIffClubs read Club;
      property FCutin: TIffCutinInfos read CutinInfo;
      property FLevelPrize: TIffLevelPrize read LevelPrize;
      property FGPHole: TIffGPSpecial read GPSpecial;
      property FMemorialCoin: TIffMemorialCoin read MemorialCoin;
      property FMemorialRare: TIffMemorialRare read MemorialRare;
      property FMagicBox: TIffMagicBoxs read MgicBox;
  end;

var
  IffEntry : TIffManager;

implementation

{ TIffManager }

constructor TIffManager.Create;
begin
  Items := TIffItems.Create;
  SetITem := TIffSetItems.Create;
  Part := TIffParts.Create;
  Caddie := TIffCaddies.Create;
  Skin := TIffSkins.Create;
  CaddieItem := TIffCaddieItems.Create;
  Mascot := TIffMascots.Create;
  CutinInfo := TIffCutinInfos.Create;
  GrandPrix := TGrandPrixDataClass.Create;
  Card := TIffCards.Create;
  Club := TIffClubs.Create;
  LevelPrize := TIffLevelPrize.Create;
  Character := TIffCharacters.Create;
  Ball := TIffBalls.Create;
  GPSpecial := TIffGPSpecial.Create;
  GPReward := TGPRewardIff.Create;
  MemorialRare := TIffMemorialRare.Create;
  MemorialCoin := TIffMemorialCoin.Create;
  MgicBox := TIffMagicBoxs.Create;
  AuxPart := TIffAuxs.Create;
end;

destructor TIffManager.Destroy;
begin
  Items.Free;
  SetITem.Free;
  Part.Free;
  Caddie.Free;
  Skin.Free;
  CaddieItem.Free;
  Mascot.Free;
  CutinInfo.Free;
  GrandPrix.Free;
  Card.Free;
  Club.Free;
  LevelPrize.Free;
  Character.Free;
  Ball.Free;
  GPSpecial.Free;
  GPReward.Free;
  MemorialRare.Free;
  MemorialCoin.Free;
  MgicBox.Free;
  AuxPart.Free;
  inherited;
end;

function TIffManager.GetRealQuantity(TypeId: UInt32; Qty: UInt32): UInt32;
begin
  case TITEMGROUP(GetItemGroup(TypeId)) of
    ITEM_TYPE_USE:
      begin
        Exit(Items.GetRealQuantity(TypeId, Qty));
      end;
    ITEM_TYPE_BALL:
      begin
        Exit(Ball.GetRealQuantity(TypeID, Qty));
      end;
  end;
  Exit(Qty);
end;

function TIffManager.GetRentalPrice(TypeID: UInt32): UInt32;
begin
  if not (GetItemGroup(TypeID) = $2) then
   Exit(0);

  Exit(Part.GetRentalPrice(TypeID));
end;

function TIffManager.GetItemName(TypeID: UInt32): AnsiString;
begin
  case TITEMGROUP(GetItemGroup(TypeId)) of
    ITEM_TYPE_CHARACTER:
      begin
        Exit(Character.GetItemName(TypeId));
      end;
    ITEM_TYPE_PART: // Part
      begin
        Exit(Part.GetItemName(TypeId));
      end;
    ITEM_TYPE_CLUB:
      begin
        Exit(Club.GetItemName(TypeId));
      end;
    ITEM_TYPE_BALL: // Ball
      begin
        Exit(Ball.GetItemName(TypeID));
      end;
    ITEM_TYPE_USE: // Normal Item
      begin
        Exit(Items.GetItemName(TypeId));
      end;
    ITEM_TYPE_CADDIE: // Cadie
      begin
        Exit(Caddie.GetItemName(TypeId));
      end;
    ITEM_TYPE_CADDIE_ITEM:
      begin
        Exit(CaddieItem.GetItemName(TypeId));
      end;
    ITEM_TYPE_SETITEM: // Part
      begin
        Exit(SetITem.GetItemName(TypeId));
      end;
    ITEM_TYPE_SKIN:
      begin
        Exit(Skin.GetItemName(TypeId));
      end;
    ITEM_TYPE_MASCOT:
      begin
        Exit(Mascot.GetItemName(TypeId));
      end;
    ITEM_TYPE_CARD:
      begin
        Exit(Card.GetItemName(TypeId));
      end;
    ITEM_TYPE_AUX:
      begin
        Exit(Auxpart.GetItemName(TypeId))
      end;
  end;
  Exit('(Unknown Item Name)');
end;

function TIffManager.GetItemTimeFlag(TypeId: UInt32): UInt8;
begin
  case TITEMGROUP(GetItemGroup(TypeId)) of
    ITEM_TYPE_CADDIE:
      begin
        if Caddie.GetSalary(TypeId) > 0 then
        begin
          Exit(2);
        end;
        Exit(0);
      end;
    ITEM_TYPE_SKIN: // SKIN FLAG
      begin
        Exit(Skin.GetSkinFlag(TypeId));
      end;
  else
    Exit(0);
  end;
end;

function TIffManager.GetPrice(TypeId: UInt32; ADay: UInt32 = 1): UInt32;
begin
  case TITEMGROUP(GetItemGroup(TypeId)) of
    ITEM_TYPE_BALL:
      begin
        Exit(Self.Ball.GetPrice(TypeID));
      end;
    ITEM_TYPE_CLUB:
      begin
        Exit(Self.Club.GetPrice(TypeID));
      end;
    ITEM_TYPE_CHARACTER:
      begin
        Exit(Character.GetPrice(TypeId));
      end;
    ITEM_TYPE_PART:
      begin
        Exit(Part.GetPrice(TypeId));
      end;
    ITEM_TYPE_USE:
      begin
        Exit(Items.GetPrice(TypeId));
      end;
    ITEM_TYPE_CADDIE:
      begin
        Exit(Caddie.GetPrice(TypeId));
      end;
    ITEM_TYPE_CADDIE_ITEM:
      begin
        Exit(CaddieItem.GetPrice(TypeId, ADay));
      end;
    ITEM_TYPE_SETITEM:
      begin
        Exit(SetITem.GetPrice(TypeId));
      end;
    ITEM_TYPE_SKIN:
      begin
        Exit(Skin.GetPrice(TypeId, ADay));
      end;
    ITEM_TYPE_MASCOT:
      begin
        Exit(Mascot.GetPrice(TypeId, ADay));
      end;
    ITEM_TYPE_CARD:
      begin
        Exit(Card.GetPrice(TypeId));
      end;
  end;
  Exit(0);
end;

function TIffManager.GetSetItemStr(TypeId: UInt32): AnsiString;
begin
  if not (TITEMGROUP(GetItemGroup(TypeId)) = ITEM_TYPE_SETITEM) then Exit;

  Exit(SetITem.GetSetItemStr(TypeId));
end;

function TIffManager.GetShopPriceType(TypeId: UInt32): ShortInt;
begin
  case TITEMGROUP(GetItemGroup(TypeId)) of
    ITEM_TYPE_BALL:
      begin
        Exit(Self.Ball.GetShopPriceType(TypeID));
      end;
    ITEM_TYPE_CLUB:
      begin
        Exit(Self.Club.GetShopPriceType(TypeID));
      end;
    ITEM_TYPE_CHARACTER:
      begin
        Exit(Character.GetShopPriceType(TypeId));
      end;
    ITEM_TYPE_PART:
      begin
        Exit(Part.GetShopPriceType(TypeId));
      end;
    ITEM_TYPE_USE:
      begin
        Exit(Items.GetShopPriceType(TypeId));
      end;
    ITEM_TYPE_CADDIE:
      begin
        Exit(Caddie.GetShopPriceType(TypeId));
      end;
    ITEM_TYPE_CADDIE_ITEM:
      begin
        Exit(CaddieItem.GetShopPriceType(TypeId));
      end;
    ITEM_TYPE_SETITEM:
      begin
        Exit(SetITem.GetShopPriceType(TypeId));
      end;
    ITEM_TYPE_SKIN:
      begin
        Exit(Skin.GetShopPriceType(TypeId));
      end;
    ITEM_TYPE_MASCOT:
      begin
        Exit(Mascot.GetShopPriceType(TypeId));
      end;
    ITEM_TYPE_CARD:
      begin
        Exit(Card.GetShopPriceType(TypeId));
      end;
  end;
  Exit(-1);
end;

function TIffManager.GetItemGroup(TypeId: UInt32): UInt32;
begin
  Result := Round( (TypeID AND $FC000000) / Power(2,26) );
end;

function TIffManager.IsBuyable(TypeId: UInt32): Boolean;
begin
  case TITEMGROUP(GetItemGroup(TypeId)) of
    ITEM_TYPE_BALL:
      begin
        Exit(Self.Ball.IsBuyable(TypeID));
      end;
    ITEM_TYPE_CLUB:
      begin
        Exit(Self.Club.IsBuyable(TypeID));
      end;
    ITEM_TYPE_CHARACTER:
      begin
        Exit(Character.IsBuyable(TypeId));
      end;
    ITEM_TYPE_PART:
      begin
        Exit(Part.IsBuyable(TypeId));
      end;
    ITEM_TYPE_USE:
      begin
        Exit(Items.IsBuyable(TypeId));
      end;
    ITEM_TYPE_CADDIE:
      begin
        Exit(Caddie.IsBuyable(TypeId));
      end;
    ITEM_TYPE_CADDIE_ITEM:
      begin
        Exit(CaddieItem.IsBuyable(TypeId));
      end;
    ITEM_TYPE_SETITEM:
      begin
        Exit(SetITem.IsBuyable(TypeId));
      end;
    ITEM_TYPE_SKIN:
      begin
        Exit(Skin.IsBuyable(TypeId));
      end;
    ITEM_TYPE_MASCOT:
      begin
        Exit(Mascot.IsBuyable(TypeId));
      end;
    ITEM_TYPE_CARD:
      begin
        Exit(Card.IsBuyable(TypeId));
      end;
  end;
  Exit(False);
end;

function TIffManager.IsExist(TypeId: UInt32): Boolean;
begin
  case TITEMGROUP(GetItemGroup(TypeId)) of
    ITEM_TYPE_CLUB:
      begin
        Exit(Self.Club.IsExist(TypeID));
      end;
    ITEM_TYPE_CHARACTER:
      begin
        Exit(Character.IsExist(TypeId));
      end;
    ITEM_TYPE_PART: // Part
      begin
        Exit(Part.IsExist(TypeId));
      end;
    ITEM_TYPE_BALL: // Ball
      begin
        Exit(Ball.IsExist(TypeID));
      end;
    ITEM_TYPE_USE: // Normal Item
      begin
        Exit(Items.IsExist(TypeId));
      end;
    ITEM_TYPE_CADDIE:
      begin
        Exit(Caddie.IsExist(TypeId));
      end;
    ITEM_TYPE_CADDIE_ITEM:
      begin
        Exit(CaddieItem.IsExist(TypeId));
      end;
    ITEM_TYPE_SETITEM: // SetItem
      begin
        Exit(SetITem.IsExist(TypeId));
      end;
    ITEM_TYPE_SKIN:
      begin
        Exit(Skin.IsExist(TypeId));
      end;
    ITEM_TYPE_MASCOT:
      begin
        Exit(Mascot.IsExist(TypeId));
      end;
    ITEM_TYPE_CARD:
      begin
        Exit(Card.IsExist(TypeId));
      end;
    ITEM_TYPE_AUX:
      begin
        Exit(Auxpart.IsExist(TypeId))
      end;
  end;
  Exit(False);
end;

function TIffManager.IsSelfDesign(TypeId: UInt32): Boolean;
begin
  case TypeId of
    134258720, 134242351, 134258721, 134242355, 134496433, 134496434, 134512665,
      134496344, 134512666, 134496345, 134783001, 134758439, 134783002,
      134758443, 135020720, 135020721, 135045144, 135020604, 135045145,
      135020607, 135299109, 135282744, 135299110, 135282745, 135545021,
      135545022, 135569438, 135544912, 135569439, 135544915, 135807173,
      135807174, 135823379, 135807066, 135823380, 135807067, 136093719,
      136069163, 136093720, 136069166, 136331407, 136331408, 136355843,
      136331271, 136355844, 136331272, 136593549, 136593550, 136617986,
      136593410, 136617987, 136593411, 136880144, 136855586, 136880145,
      136855587, 136855588, 136855589, 137379868, 137379869, 137404426,
      137379865, 137404427, 137379866, 137904143, 137904144, 137928708,
      137904140, 137928709, 137904141:
      begin
        Exit(True);
      end;
  else
    Exit(False);
  end;
  Exit(False);
end;

end.
