unit ItemData;

interface

type
  TAddItem = packed record
    var ItemIffId: UInt32;
    var Transaction: Boolean;
    var Quantity: UInt32;
    var Day: UInt32;
  end;

  TAddData = packed record
    var Status: Boolean;
    var ItemIndex: UInt32;
    var ItemTypeID: UInt32;
    var ItemOldQty: UInt32;
    var ItemNewQty: UInt32;
    var ItemUCCKey: AnsiString;
    var ItemFlag: UInt8;
    var ItemEndDate: TDateTime;
    procedure SetData(FStatus: Boolean; FItemIndex, FItemTypeId, FItemOldQty, FItemNewQty: UInt32; FItemUCCKey: AnsiString; FItemFlag: UInt8; FItemEndDate: TDateTime);
  end;

implementation

{ TAddData }

procedure TAddData.SetData(FStatus: Boolean; FItemIndex, FItemTypeId, FItemOldQty,
  FItemNewQty: UInt32; FItemUCCKey: AnsiString; FItemFlag: UInt8;
  FItemEndDate: TDateTime);
begin
  Self.Status       := FStatus;
  Self.ItemIndex   := FItemIndex;
  Self.ItemTypeID   := FItemTypeId;
  Self.ItemOldQty   := FItemOldQty;
  Self.ItemNewQty   := FItemNewQty;
  Self.ItemUCCKey   := FItemUCCKey;
  Self.ItemFlag     := FItemFlag;
  Self.ItemEndDate  := FItemEndDate;
end;

end.
