unit uWarehouse;

interface

uses
  Tools, Math, MyList, SysUtils, Utils, IffMain, ClientPacket, Enum, XSuperObject, ClubData, Defines, DateUtils;

type
  PItem = ^TPlayerWarehouse;

  TPlayerWarehouse = packed record
    public
      var ItemIndex : UInt32;
      var ItemTypeID : UInt32;
      var ItemC0 : UInt16;
      var ItemC1 : UInt16;
      var ItemC2 : UInt16;
      var ItemC3 : UInt16;
      var ItemC4 : UInt16;
      var ItemUCCUnique : AnsiString;
      var ItemUCCName: AnsiString;
      var ItemUCCStatus : Byte;
      var ItemUCCDrawer: AnsiString;
      var ItemUCCDrawerUID : UInt32;
      var ItemUCCCopyCount: UInt16;
      var ItemClubPoint : UInt32;
      var ItemClubWorkCount : UInt32;
      var ItemClubPointLog: UInt32;
      var ItemClubPangLog: UInt32;
      var ItemC0Slot : UInt16;
      var ItemC1Slot : UInt16;
      var ItemC2Slot : UInt16;
      var ItemC3Slot : UInt16;
      var ItemC4Slot : UInt16;
      var ItemClubSlotCancelledCount : UInt32;
      var ItemGroup : UInt8;
      var ItemIsValid : UInt8;
      var ItemFlag : UInt8;
      var ItemEndDate: TDateTime;
      var ItemNeedUpdate : Boolean;
      function SetItemInformations( Info : TPlayerWarehouse): Boolean;
      function GetItems: AnsiString;
      function AddQuantity(Value: UInt32): Boolean;
      function RemoveQuantity(Value: UInt32): Boolean;
      function GetSQLUpdateString: String;

      function GetClubInfo: AnsiString; overload;
      function GetClubInfo(Option: Byte): AnsiString overload;
      function GetClubSlotStatus: TClubStatus;
      function AddClubSlot(AddType: UInt8; Count: UInt8 = 1): Boolean;
      function RemoveClubSlot(RemoveType: UInt8; Count: UInt8 = 1): Boolean;
      function RemoveClubPoint(Amount: UInt32): Boolean;
      function AddClubPoint(Value: UInt32): Boolean;
      function GetClubPoint: UInt32;
      function ClubSetReset: Boolean;
      function ClubSetCanReset: Boolean;
      function ClubSlotAvailable(Slot: TCLUB_STATUS): TClubUpgradeData;
      function ClubAddStatus(Slot: TCLUB_STATUS): Boolean;
      function ClubRemoveStatus(Slot: TCLUB_STATUS): Boolean;
      procedure Update;
      procedure CreateNewItem;
      procedure DeleteItem;
      procedure Renew;
  end;

  TSerialWarehouse = class(TMyList<PItem>)
  private
    function GetItemGroup(TypeID: UInt32): UInt32;
  public
    constructor Create;
    destructor Destroy; override;
    function GetItems: AnsiString;

    function GetItem(Index: UInt32): PItem; overload;
    function GetItem(TypeID: UInt32; Quantity: UInt32): PItem; overload;
    function GetItem(TypeID, Index, Quantity: UInt32): PItem; overload;

    function Add(const Value: PItem): Integer;

    function IsNormalExist(TypeId: UInt32): Boolean;  overload;
    function IsNormalExist(TypeID, Index, Quantity: UInt32): Boolean; overload;

    function IsPartExist(TypeId: UInt32): Boolean; overload;
    function IsPartExist(TypeID, Index, Quantity: UInt32): Boolean; overload;

    function IsSkinExist(TypeId: UInt32): Boolean;
    function IsClubExist(TypeId: UInt32): Boolean;
    function RemoveItem(TypeId: UInt32; Count: UInt32): Boolean; overload;
    function GetQuantity(TypeId : UInt32): UInt32;
    function GetSQLUpdateString: String;
    function GetSQLUpdateJSON: AnsiString;
    function GetClub(ID: UInt32; GetType: TGET_CLUB): PItem;

    function RemoveItem(Item: PItem): Boolean; overload;
  end;

implementation

{ TPlayerWarehouse }

function TPlayerWarehouse.AddClubPoint(Value: UInt32): Boolean;
begin
  if ItemClubPoint > 99999 then Exit(False);
  Inc(ItemClubPoint, Value);
  Update;
  Exit(True);
end;

function TPlayerWarehouse.AddClubSlot(AddType, Count: UInt8): Boolean;
begin
  if not (GetItemGroup(Self.ItemTypeID) = $4) then Exit(False);

  Inc(ItemClubWorkCount);

  case AddType of
    0:
      begin
        Inc(ItemC0Slot, Count);
      end;
    1:
      begin
        Inc(ItemC1Slot, Count);
      end;
    2:
      begin
        Inc(ItemC2Slot, Count);
      end;
    3:
      begin
        Inc(ItemC3Slot, Count);
      end;
    4:
      begin
        Inc(ItemC4Slot, Count);
      end;
  end;

  Update;

  Exit(True);
end;

function TPlayerWarehouse.RemoveClubPoint(Amount: UInt32): Boolean;
begin
  if ItemClubPoint < Amount then Exit(False);
  Dec(ItemClubPoint, Amount);

  Update;

  Exit(True);
end;

function TPlayerWarehouse.RemoveClubSlot(RemoveType, Count: UInt8): Boolean;
begin
  if not (GetItemGroup(Self.ItemTypeID) = $4) then Exit(False);

  Dec(ItemClubWorkCount);

  if (ItemClubSlotCancelledCount >= 5) then
  begin
    Exit(False);
  end;

  Inc(ItemClubSlotCancelledCount);

  case RemoveType of
    0:
      begin
        Dec(ItemC0Slot, Count);
      end;
    1:
      begin
        Dec(ItemC1Slot, Count);
      end;
    2:
      begin
        Dec(ItemC2Slot, Count);
      end;
    3:
      begin
        Dec(ItemC3Slot, Count);
      end;
    4:
      begin
        Dec(ItemC4Slot, Count);
      end;
  end;

  Update;

  Exit(True);
end;

function TPlayerWarehouse.AddQuantity(Value: UInt32): Boolean;
begin
  Inc(ItemC0,Value);

  Update;

  Exit(True);
end;

function TPlayerWarehouse.ClubAddStatus(Slot: TCLUB_STATUS): Boolean;
begin
  Update;

  case Slot of
    csPower:
      begin
        Inc(Self.ItemC0, 1);
      end;
    csControl:
      begin
        Inc(Self.ItemC1, 1);
      end;
    csImpact:
      begin
        Inc(Self.ItemC2, 1);
      end;
    csSpin:
      begin
        Inc(Self.ItemC3, 1);
      end;
    csCurve:
      begin
        Inc(Self.ItemC4, 1);
      end;
  end;
  Exit(True);
end;

function TPlayerWarehouse.ClubRemoveStatus(Slot: TCLUB_STATUS): Boolean;
begin
  Update;

  case Slot of
    csPower:
      begin
        if Self.ItemC0 > 0 then
        begin
          Dec(Self.ItemC0, 1);
          Exit(True);
        end;
        Exit(False);
      end;
    csControl:
      begin
        if Self.ItemC1 > 0 then
        begin
          Dec(Self.ItemC1, 1);
          Exit(True);
        end;
        Exit(False);
      end;
    csImpact:
      begin
        if Self.ItemC2 > 0 then
        begin
          Dec(Self.ItemC2, 1);
          Exit(True);
        end;
        Exit(False);
      end;
    csSpin:
      begin
        if Self.ItemC3 > 0 then
        begin
          Dec(Self.ItemC3, 1);
          Exit(True);
        end;
        Exit(False);
      end;
    csCurve:
      begin
        if Self.ItemC4 > 0 then
        begin
          Dec(Self.ItemC4, 1);
          Exit(True);
        end;
        Exit(False);
      end;
  end;
end;

function TPlayerWarehouse.ClubSetCanReset: Boolean;
begin
  if not (GetItemGroup(Self.ItemTypeID) = $4) then Exit(False);

  Exit(True);
end;

function TPlayerWarehouse.ClubSetReset: Boolean;
begin
  if not (GetItemGroup(Self.ItemTypeID) = $4) then Exit(False);

  ItemC0 := 0;
  ItemC1 := 0;
  ItemC2 := 0;
  ItemC3 := 0;
  ItemC4 := 0;

  ItemC0Slot := 0;
  ItemC1Slot := 0;
  ItemC2Slot := 0;
  ItemC3Slot := 0;
  ItemC4Slot := 0;

  ItemClubSlotCancelledCount := 0;

  ItemClubPointLog := 0;
  ItemClubPangLog := 0;

  Update;

  Exit(True);
end;

function TPlayerWarehouse.ClubSlotAvailable(Slot: TCLUB_STATUS): TClubUpgradeData;
const
  Power   = 2100;
  Con     = 1700;
  Impact  = 2400;
  Spin    = 1900;
  Curve   = 1900;
var
  ClubData: TClubStatus;
begin
  ClubData := GetClubMaxStatus(Self.ItemTypeID);

  case Slot of
    csPower:
      begin
        if Self.ItemC0 < (ClubData.Power + Self.ItemC0Slot) then
        begin
          Result.Able := True;
          Result.Pang := (Self.ItemC0 * Power) + Power;
          Exit(Result);
        end;
      end;
    csControl:
      begin
        if Self.ItemC1 < (ClubData.Control + Self.ItemC1) then
        begin
          Result.Able := True;
          Result.Pang := (Self.ItemC1 * Con) + Con;
          Exit(Result);
        end;
      end;
    csImpact:
      begin
        if Self.ItemC2 < (ClubData.Impact + Self.ItemC2) then
        begin
          Result.Able := True;
          Result.Pang := (Self.ItemC2 * Impact) + Impact;
          Exit(Result);
        end;
      end;
    csSpin:
      begin
        if Self.ItemC3 < (ClubData.Spin + Self.ItemC3) then
        begin
          Result.Able := True;
          Result.Pang := (Self.ItemC3 * Spin) + Spin;
          Exit(Result);
        end;
      end;
    csCurve:
      begin
        if Self.ItemC4 < (ClubData.Curve + Self.ItemC4) then
        begin
          Result.Able := True;
          Result.Pang := (Self.ItemC4 * Curve) + Curve;
          Exit(Result);
        end;
      end;
  end;

  with Result do
  begin
    Able := False;
    Pang := 0;
  end;

  Exit(Result);
end;

procedure TPlayerWarehouse.CreateNewItem;
begin
  Self.ItemC1 := 0;
  Self.ItemC2 := 0;
  Self.ItemC3 := 0;
  Self.ItemC4 := 0;
  Self.ItemUCCName := Nulled;
  Self.ItemUCCStatus := 0;
  Self.ItemUCCDrawer := Nulled;
  Self.ItemUCCDrawerUID := 0;
  Self.ItemClubPoint := 0;
  Self.ItemClubWorkCount := 0;
  Self.ItemClubPointLog := 0;
  Self.ItemClubPangLog := 0;
  Self.ItemC0Slot := 0;
  Self.ItemC1Slot := 0;
  Self.ItemC2Slot := 0;
  Self.ItemC3Slot := 0;
  Self.ItemC4Slot := 0;
  Self.ItemClubSlotCancelledCount := 0;
  Self.ItemNeedUpdate := False;
  Self.ItemIsValid := 1;
  Self.ItemNeedUpdate := False;
  Self.ItemFlag := 0;

  { part and clubset }
  case GetItemGroup(Self.ItemTypeID) of
    $4, $2:
      begin
        Self.ItemC0 := 0;
      end;
  end;
end;

procedure TPlayerWarehouse.DeleteItem;
begin
  Self.ItemIsValid := 0;
  Self.ItemNeedUpdate := True;
end;

function TPlayerWarehouse.GetClubInfo: AnsiString;
var
  Packet: TClientPacket;
  ClubData: TClubStatus;
begin
  ClubData := GetClubMaxStatus(Self.ItemTypeID);

  Packet := TClientPacket.Create;
  try
    Packet.WriteUInt32(Self.ItemIndex);
    Packet.WriteUInt32(Self.ItemTypeID);
    Packet.WriteUInt16(Self.ItemC0);
    Packet.WriteUInt16(Self.ItemC1);
    Packet.WriteUInt16(Self.ItemC2);
    Packet.WriteUInt16(Self.ItemC3);
    Packet.WriteUInt16(Self.ItemC4);
    Packet.WriteUInt16(ClubData.Power + Self.ItemC0Slot);
    Packet.WriteUInt16(ClubData.Control + Self.ItemC1Slot);
    Packet.WriteUInt16(ClubData.Impact + Self.ItemC2Slot);
    Packet.WriteUInt16(ClubData.Spin + Self.ItemC3Slot);
    Packet.WriteUInt16(ClubData.Curve + Self.ItemC4Slot);
    Exit(Packet.ToStr);
  finally
    FreeAndNil(Packet);
  end;
end;

function TPlayerWarehouse.GetClubInfo(Option: Byte): AnsiString;
begin

end;

function TPlayerWarehouse.GetClubPoint: UInt32;
begin
  Exit(ItemClubPoint);
end;

function TPlayerWarehouse.GetClubSlotStatus: TClubStatus;
begin
  Result.Power := Self.ItemC0Slot;
  Result.Control := Self.ItemC1Slot;
  Result.Impact := Self.ItemC2Slot;
  Result.Spin := Self.ItemC3Slot;
  Result.Curve := Self.ItemC4Slot;
end;

function TPlayerWarehouse.GetItems: AnsiString;
begin
  SetLength(Result , SizeOf(TPlayerWarehouse));
  move(Self.ItemIndex , Result[1], SizeOf(TPlayerWarehouse));
end;

function TPlayerWarehouse.GetSQLUpdateString: String;
var
  SQLString: TStringBuilder;
begin
  SQLString := TStringBuilder.Create;
  try
    SQLString.Append('^');
    SQLString.Append(ItemIndex);
    SQLString.Append('^');
    SQLString.Append(ItemC0);
    SQLString.Append('^');
    SQLString.Append(ItemIsValid);
    SQLString.Append('^');
    SQLString.Append(TGeneric.Iff<UInt8>(IffEntry.IsSelfDesign(ItemTypeID), 1, 0));
    SQLString.Append('^');
    SQLString.Append(ItemUCCStatus);
    SQLString.Append('^');
    SQLString.Append(ItemUCCUnique);
    SQLString.Append(','); // close for next player
    Exit(SQLString.ToString);
  finally
    FreeAndNil(SQLString);
  end;
end;

function TPlayerWarehouse.RemoveQuantity(Value: UInt32): Boolean;
begin
  Dec(ItemC0, Value);
  if ItemC0 <= 0 then
  begin
    ItemIsValid := 0;
  end;
  Update;
  Exit(True);
end;

procedure TPlayerWarehouse.Renew;
begin
  Self.ItemEndDate := IncDay(Now, 7);
  Self.ItemFlag := $60;
  Self.ItemNeedUpdate := True;
end;

function TPlayerWarehouse.SetItemInformations(Info: TPlayerWarehouse): Boolean;
begin
  Self := Info;
  Exit(True);
end;

procedure TPlayerWarehouse.Update;
begin
  if not Self.ItemNeedUpdate then
    Self.ItemNeedUpdate := True;
end;

{ TSerialWarehouse }

function TSerialWarehouse.Add(const Value: PItem): Integer;
begin
  Value.ItemNeedUpdate := False;
  Result := Inherited;
end;

constructor TSerialWarehouse.Create;
begin
  inherited;
end;

destructor TSerialWarehouse.Destroy;
var
  ItemInfo : PItem;
begin
  for ItemInfo in self do
  begin
    Dispose(ItemInfo);
  end;
  Clear;
  inherited;
end;

function TSerialWarehouse.GetClub(ID: UInt32; GetType: TGET_CLUB): PItem;
var
  Items : PItem;
begin
  for Items in Self do
  begin
    case GetType of
      gcTypeID:
        begin
          if (Items.ItemTypeID = ID) and (Items.ItemIsValid = 1) and (GetItemGroup(Items.ItemTypeID) = $4) then
          begin
            Exit(Items)
          end;
        end;
      gcIndex:
        begin
          if (Items.ItemIndex = ID) and (Items.ItemIsValid = 1) and (GetItemGroup(Items.ItemTypeID) = $4) then
          begin
            Exit(Items)
          end;
        end;
    end;
  end;
  Exit(nil);
end;

function TSerialWarehouse.GetItem(Index: UInt32): PItem;
var
  Items : PItem;
begin
  for Items in Self do
  begin
    if (Items.ItemIndex = Index) and (Items.ItemIsValid = 1) then
    begin
      Exit(Items)
    end;
  end;
  Exit(nil);
end;

function TSerialWarehouse.GetItem(TypeID: UInt32; Quantity : UInt32): PItem;
var
  Items : PItem;
begin
  for Items in self do
  begin
    if (Items.ItemTypeID = TypeID) and (Items.ItemC0 >= Quantity) and (Items.ItemIsValid = 1) then
    begin
      Exit(Items);
    end;
  end;
  Exit(nil);
end;

function TSerialWarehouse.GetItem(TypeID, Index, Quantity: UInt32): PItem;
var
  Items : PItem;
begin
  for Items in Self do
    if (Items.ItemTypeID = TypeID) and (Items.ItemIndex = Index) and (Items.ItemC0 >= Quantity) and (Items.ItemIsValid = 1) then
      Exit(Items);

  Exit(nil);
end;

function TSerialWarehouse.GetItems: AnsiString;
var
  Items : PItem;
begin
  for Items in self do begin
    Result := Result + Items.GetItems;
  end;
end;

function TSerialWarehouse.GetQuantity(TypeId: UInt32): UInt32;
var
  Items : PItem;
begin
  for Items in Self do
  begin
    if Items.ItemTypeID = TypeId then
    begin
      Exit(Items.ItemC0);
    end;
  end;
  Exit(0);
end;

function TSerialWarehouse.GetSQLUpdateJSON: AnsiString;
var
  JSON, NestJS: ISuperObject;
  Items : PItem;
begin
  JSON := SO;
  for Items in Self do
  begin
    if Items.ItemNeedUpdate then
    begin
      Items.ItemNeedUpdate := False;
      NestJS := SO;
      NestJS.I['ItemIndex'] := Items.ItemIndex;
      NestJS.I['ItemC0'] := Items.ItemC0;
      NestJS.I['ItemC1'] := Items.ItemC1;
      NestJS.I['ItemC2'] := Items.ItemC2;
      NestJS.I['ItemC3'] := Items.ItemC3;
      NestJS.I['ItemC4'] := Items.ItemC4;
      NestJS.I['ItemValid'] := Items.ItemIsValid;
      NestJS.I['IsSelfDesign'] := TGeneric.Iff<UInt8>(IffEntry.IsSelfDesign(Items.ItemTypeID), 1, 0);
      NestJS.I['ItemUCCStatus'] := Items.ItemUCCStatus;
      NestJS.S['ItemUCCUnique'] := String(Items.ItemUCCUnique);
      NestJS.D['ItemEndDate'] := Items.ItemEndDate;
      NestJS.I['ItemFlag'] := Items.ItemFlag;
      { CLUB SET DATA }
      NestJS.I['ClubPoint'] := Items.ItemClubPoint;
      NestJS.I['WorkCount'] := Items.ItemClubWorkCount;
      NestJS.I['PointLog'] := Items.ItemClubPointLog;
      NestJS.I['PangLog'] := Items.ItemClubPangLog;
      NestJS.I['C0Slot'] := Items.ItemC0Slot;
      NestJS.I['C1Slot'] := Items.ItemC1Slot;
      NestJS.I['C2Slot'] := Items.ItemC2Slot;
      NestJS.I['C3Slot'] := Items.ItemC3Slot;
      NestJS.I['C4Slot'] := Items.ItemC4Slot;
      NestJS.I['CancelCount'] := Items.ItemClubSlotCancelledCount;
      NestJS.I['IsClubset'] := TGeneric.Iff<UInt8>( GetItemGroup(Items.ItemTypeID) = $4, 1, 0);

      JSON.A['Items'].Add(NestJS);
    end;
  end;
  Exit(AnsiString(JSON.AsJSON()));
end;

function TSerialWarehouse.GetSQLUpdateString: String;
var
  Items : PItem;
  StringBuilder: TStringBuilder;
begin
  StringBuilder := TStringBuilder.Create;
  try
    for Items in Self do
    begin
      if Items.ItemNeedUpdate then
      begin
        StringBuilder.Append(Items.GetSQLUpdateString);
        // ## set update to false when request string
        Items.ItemNeedUpdate := False;
      end;
    end;
    Exit(StringBuilder.ToString);
  finally
    FreeAndNil(StringBuilder);
  end;
end;

function TSerialWarehouse.GetItemGroup(TypeID: UInt32): UInt32;
begin
  Result := Round( (TypeID AND 4227858432) / Power(2,26) );
end;

function TSerialWarehouse.IsClubExist(TypeId: UInt32): Boolean;
var
  Items : PItem;
begin
  for Items in self do
  begin
    if (GetItemGroup(Items.ItemTypeID) = $4) and (Items.ItemTypeID = TypeId) and (Items.ItemIsValid = 1) then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

function TSerialWarehouse.IsNormalExist(TypeID, Index, Quantity: UInt32): Boolean;
var
  Items : PItem;
begin
  for Items in self do
    if (Items.ItemTypeID = TypeID) and (Items.ItemIndex = Index) and (Items.ItemC0 >= Quantity) and (Items.ItemIsValid = 1) then
      Exit(True);

  Exit(False);
end;

function TSerialWarehouse.IsNormalExist(TypeId: UInt32): Boolean;
var
  Items : PItem;
begin
  for Items in self do
  begin
    if (Items.ItemTypeID = TypeId) and (Items.ItemC0 > 0) and (Items.ItemIsValid = 1) then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

function TSerialWarehouse.IsPartExist(TypeID, Index, Quantity: UInt32): Boolean;
var
  Items : PItem;
begin
  for Items in self do
  begin
    if (Items.ItemTypeID = TypeID) and (Items.ItemIndex = Index) and (Items.ItemIsValid = 1) then
    begin
      Exit(True);
    end;
  end;

  Exit(False);
end;

function TSerialWarehouse.IsPartExist(TypeId: UInt32): Boolean;
var
  Items : PItem;
begin
  for Items in self do
  begin
    if (Items.ItemTypeID = TypeId) and (Items.ItemIsValid = 1) then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

function TSerialWarehouse.IsSkinExist(TypeId: UInt32): Boolean;
var
  Items: PItem;
begin
  for Items in self do
  begin
    if (Items.ItemTypeID = TypeId) and (Items.ItemIsValid = 1) and (GetItemGroup(Items.ItemTypeID) = 14) then
    begin
      Exit(True);
    end;
  end;
  Exit(False);
end;

function TSerialWarehouse.RemoveItem(Item: PItem): Boolean;
begin
  if Self.Remove(Item) = -1 then
    Exit(False);

  Exit(True);
end;

function TSerialWarehouse.RemoveItem(TypeId : UInt32; Count : UInt32): Boolean;
var
  Items : PItem;
begin
  case GetItemGroup(TypeId) of
    5, 6: // ## Normal Item And Ball
      begin
        for Items in Self do
        begin
          if (Items^.ItemTypeID = TypeId) and (Items^.ItemC0 >= Count) and (Items^.ItemIsValid = 1) then
          begin
            Dec(Items^.ItemC0, Count);
            if Items^.ItemC0 = 0 then
            begin
              Items^.ItemIsValid := 0;
            end;
            Exit(True);
          end;
        end;
      end;
  end;
  Exit(False);
end;

end.
