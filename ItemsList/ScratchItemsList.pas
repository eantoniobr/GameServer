unit ScratchItemsList;

interface

uses
  Math, Tools, SysUtils, MyList;

type
  PItemRandom = ^TItemRandom;

  TItemRandom = packed record
    var TypeId : UInt32;
    var MaxQuantity : UInt32;
    var Probs : UInt16;
    var RareType : UInt32;
  end;

  TItemRandomClass = class(TMyList<PItemRandom>)
    private
      var FSupplies : Array[0..2] of UInt32;
    public
      procedure AddItems(TTypeId, TMaxQuan, TRaretype: UInt32; TProbs : UInt16);
      function GetIndex(Index : Byte): UInt32;
      function GetItems: PItemRandom;
      function GetSupplyLength: Byte;
      property Supply[Index : Byte]: UInt32 read GetIndex;

      constructor Create;
      destructor Destroy; override;

  end;

implementation

{ TScratchLists }

procedure TItemRandomClass.AddItems(TTypeId, TMaxQuan, TRaretype: UInt32; TProbs : UInt16);
var
  Items : PItemRandom;
begin
  New(Items);
  Items.TypeId := TTypeId;
  Items.MaxQuantity := TMaxQuan;
  Items.Probs := TProbs;
  Items.RareType := TRareType;
  Add(Items);
end;

constructor TItemRandomClass.Create;
begin
  inherited;
  // Card Remover
  AddItems(436207810, 1, 0 ,10);
  // Replay Tape
  AddItems(436207695, 2, 0 ,50);
  // Dual Lucky Pangya
  AddItems(402653194, 2, 0 ,50);
  // Oblivion Flower
  AddItems(402653198, 2, 0 ,50);
  // Dual Tran
  AddItems(402653195, 2, 0 ,50);
  // Power Calippers
  AddItems(402653193, 2, 0 ,50);
  // Silent Wind
  AddItems(402653190, 2, 0 ,50);

  // Supplies
  FSupplies[0] := 436207664; // Gift
  FSupplies[1] := 436207667; // Event
  FSupplies[2] := 436207668; // GM

end;

destructor TItemRandomClass.Destroy;
var
  Items : PItemRandom;
begin
  for Items in self do
  begin
    Dispose(Items);
  end;
  Clear;
  inherited;
end;

function TItemRandomClass.GetIndex(Index: Byte): UInt32;
begin
  Result := FSupplies[Index];
end;

function TItemRandomClass.GetItems: PItemRandom;
var
  Items : PItemRandom;
  Count, Rand : SmallInt;
begin
  Count := 0;
  Rand := 0;

  for Items in Self do
  begin
    Inc(Count, Items.Probs);
  end;

  Randomize;
  Rand := Random(Count) + 1;

  for Items in self do
  begin
    Dec(Rand, Items.Probs);
    if Rand <= 0 then
    begin
      Exit(Items);
    end;
  end;
end;

function TItemRandomClass.GetSupplyLength: Byte;
begin
  Exit(Length(FSupplies));
end;

end.
