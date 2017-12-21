unit RandomItem;

interface

uses
  Math, MyList, System.Generics.Defaults, MTRand;

type
  PItemRandom = ^TItemRandom;

  TItemRandom = packed record
    var TypeId : UInt32;
    var MaxQuantity : UInt32;
    var Probs : UInt16;
    var RareType : UInt32;
  end;

  PSupplies = ^TSupplies;

  TSupplies = packed record
    var TypeId : UInt32;
    var DelQuantity : Word;
  end;

  TItemRandomClass = class(TMyList<PItemRandom>)
    private
      var FSupplies : TMyList<PSupplies>;
      var FTItem : TMyList<PItemRandom>;
      var FDuplicated : Boolean;
    public
      procedure AddItems(TypeID, MaxQuan, RareType: UInt32; Probabilities : UInt16);
      procedure AddSupply(TypeID: UInt32; Quantity: UInt32 = 1);
      procedure SetCanDup(Val : Boolean);
      function GetItems: PItemRandom;
      procedure Restore;
      procedure Arrange;
      function GetLeft: UInt32;

      property Supply : TMyList<PSupplies> read FSupplies;
      constructor Create;
      destructor Destroy; override;
  end;

implementation

{ TScratchLists }

procedure TItemRandomClass.AddItems(TypeID, MaxQuan, RareType: UInt32; Probabilities : UInt16);
var
  Items : PItemRandom;
begin
  New(Items);
  Items.TypeId := TypeID;
  Items.MaxQuantity := MaxQuan;
  Items.Probs := Probabilities;
  Items.RareType := RareType;
  Add(Items);
end;

procedure TItemRandomClass.AddSupply(TypeID: UInt32; Quantity: UInt32 = 1);
var
  FSupply : PSupplies;
begin
  New(FSupply);
  FSupply.TypeId := TypeID;
  FSupply.DelQuantity := Quantity;
  FSupplies.Add(FSupply);
end;

procedure TItemRandomClass.Arrange;
begin
  FTItem.Sort(TComparer<PItemRandom>.Construct(
    function(const Item1, Item2: PItemRandom): Integer
    begin
      if Item1.RareType > Item2.RareType then
        Result := -1
      else if Item1.RareType < Item2.RareType then
        Result := 1
      else
        Result := 0;
    end));
end;

procedure TItemRandomClass.Restore;
var
  Items : PItemRandom;
begin
  FTItem.Clear;

  for Items in self do
  begin
    FTItem.Add(Items);
  end;
end;

procedure TItemRandomClass.SetCanDup(Val: Boolean);
begin
  FDuplicated := Val;
  Restore;
end;

constructor TItemRandomClass.Create;
begin
  FSupplies := TMyList<PSupplies>.Create;
  FTItem := TMyList<PItemRandom>.Create;
  FDuplicated := True;
  inherited;
end;

destructor TItemRandomClass.Destroy;
var
  Items : PItemRandom;
  Supples : PSupplies;
begin
  // ## temp random
  FTItem.Clear;
  FTItem.Free;

  // ## Clear Supply
  for Supples in FSupplies do
  begin
    Dispose(Supples);
  end;
  FSupplies.Free;

  for Items in self do
  begin
    Dispose(Items);
  end;
  Clear;
  inherited;
end;

function TItemRandomClass.GetItems: PItemRandom;
var
  Items : PItemRandom;
  Count, RInt : Int32;
begin
  Count := 0;

  if not FDuplicated then
  begin
    for Items in FTItem do
    begin
      Inc(Count, Items.Probs);
    end;
    RInt := Rand.RandInt(Count);
    for Items in FTItem do
    begin
      Dec(RInt, Items.Probs);
      if RInt <= 0 then
      begin
        FTItem.Remove(Items);
        Exit(Items);
      end;
    end;
  end
  else if FDuplicated then
  begin
    for Items in Self do
    begin
      Inc(Count, Items.Probs);
    end;
    RInt := Rand.RandInt(Count);
    for Items in self do
    begin
      Dec(RInt, Items.Probs);
      if RInt <= 0 then
      begin
        Exit(Items);
      end;
    end;
  end;
  Exit(nil);
end;

function TItemRandomClass.GetLeft: UInt32;
begin
  if Self.FDuplicated then
    Exit(Self.Count)
  else
    Exit(Self.FTItem.Count);
end;

end.
