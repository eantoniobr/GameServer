unit Transactions;

interface

uses
  MyList, Enum, ClientPacket, Tools, System.DateUtils, System.SysUtils, Defines,
  uCharacter, uWarehouse, Math, ObjectList, uCard;

type
  TTransaction = class
    private
      FTranList: TMyObject;
    public
      constructor Create;
      destructor Destroy; override;
      function GetTran: TClientPacket;
      procedure Add(Tran: TTransacItem); overload;
      procedure Add(ShowType: UInt8; Char: PCharacter); overload;
      //procedure Add(ShowType: UInt8; Counter: PAchievementCounter); overload;
      procedure Add(ShowType: UInt8; Item: PItem; Add: UInt32); overload;
      procedure Add(ShowType: UInt8; Card: PCard; Add: UInt32); overload;
      procedure AddCharStatus(ShowType: UInt8; Char: PCharacter);
      procedure AddClubSystem(Item: PItem);
      property TranList: TMyObject read FTranList;
  end;

implementation

{ TTransaction }

procedure TTransaction.Add(Tran: TTransacItem);
begin
  FTranList.Add(Tran);
end;

procedure TTransaction.Add(ShowType: UInt8; Char: PCharacter);
var
  Tran: TTransacItem;
begin
  if (Char = nil) then Exit;
  Tran := TTransacItem.Create;
  with Tran do
  begin
    Types := ShowType;
    TypeID := Char.TypeID;
    Index := Char.Index;
    PreviousQuan := 0;
    NewQuan := 0;
    UCC := Nulled;
  end;
  Self.Add(Tran);
end;

{procedure TTransaction.Add(ShowType: UInt8; Counter: PAchievementCounter);
var
  Tran: TTransacItem;
begin
  if (Counter = nil) then Exit;
  Tran := TTransacItem.Create;
  with Tran do
  begin
    Types := ShowType;
    TypeID := Counter.CounterTypeID;
    Index := Counter.CounterID;
    PreviousQuan := Counter.CounterOldQty;
    NewQuan := Counter.CounterNewQty;
    UCC := Nulled;
  end;
  Self.Add(Tran);
end;}

procedure TTransaction.Add(ShowType: UInt8; Item: PItem; Add: UInt32);
var
  Tran: TTransacItem;
begin
  if (Item = nil) then Exit;
  Tran := TTransacItem.Create;
  with Tran do
  begin
    Types := ShowType;
    TypeID := Item.ItemTypeID;
    Index := Item.ItemIndex;
    PreviousQuan := Item.ItemC0 - Add;
    NewQuan := Item.ItemC0;
    UCC := Nulled;
  end;
  Self.Add(Tran);
end;

procedure TTransaction.Add(ShowType: UInt8; Card: PCard; Add: UInt32);
var
  Tran: TTransacItem;
begin
  if (Card = nil) then Exit;
  Tran := TTransacItem.Create;
  with Tran do
  begin
    Types := ShowType;
    TypeID := Card.CardTypeID;
    Index := Card.CardIndex;
    PreviousQuan := Card.CardQuantity - Add;
    NewQuan := Card.CardQuantity;
    UCC := Nulled;
  end;
  Self.Add(Tran);
end;

procedure TTransaction.AddCharStatus(ShowType: UInt8; Char: PCharacter);
var
  Tran: TTransacItem;
begin
  if (Char = nil) then Exit;

  Tran := TTransacItem.Create;
  with Tran do
  begin
    Types := ShowType;
    TypeID := Char.TypeID;
    Index := Char.Index;
    PreviousQuan := 0;
    NewQuan := 0;
    UCC := Nulled;
    C0_SLOT := Char.Power;
    C1_SLOT := Char.Control;
    C2_SLOT := Char.Impact;
    C3_SLOT := Char.Spin;
    C4_SLOT := Char.Curve;
  end;
  Self.Add(Tran);
end;

procedure TTransaction.AddClubSystem(Item: PItem);
var
  Tran: TTransacItem;
begin
  if (Item = nil) then Exit;
  Tran := TTransacItem.Create;
  with Tran do
  begin
    Types := $CC;
    TypeID := Item.ItemTypeID;
    Index := Item.ItemIndex;
    PreviousQuan := 0;
    NewQuan := 0;
    UCC := Nulled;
    C0_SLOT := Item.ItemC0Slot;
    C1_SLOT := Item.ItemC1Slot;
    C2_SLOT := Item.ItemC2Slot;
    C3_SLOT := Item.ItemC3Slot;
    C4_SLOT := Item.ItemC4Slot;
    ClubPoint := Item.ItemClubPoint;
    WorkshopCount := Item.ItemClubWorkCount;
    CancelledCount := Item.ItemClubSlotCancelledCount;
  end;
  Self.Add(Tran);
end;

constructor TTransaction.Create;
begin
  FTranList := TMyObject.Create;
end;

destructor TTransaction.Destroy;
begin
  FreeAndNil(FTranList);
  inherited;
end;

function TTransaction.GetTran: TClientPacket;
var
  TranObj: TObject;
  Tran: TTransacItem;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$16#$02);
    WriteUInt32(Random($FFFFFFFF));
    WriteUInt32(FTranList.Count);
    for TranObj in FTranList do
    begin
      if not (TranObj is TTransacItem) then Continue;
      Tran := TranObj as TTransacItem;

      WriteUInt8(TCompare.IfCompare<UInt8>( Tran.Types <= 0, $2, Tran.Types));
      WriteUInt32(Tran.TypeID);
      WriteUInt32(Tran.Index);
      WriteUInt32(TCompare.IfCompare<UInt32>( Tran.DayEnd > Now, 1, 0));

      // ## if the item has a period time
      if (Tran.DayEnd > Now()) then
      begin
        WriteUInt32(DateTimeToUnix(Tran.DayStart, False));
        WriteUInt32(DateTimeToUnix(Tran.DayEnd, False));
        WriteUInt32(DaysBetween(Tran.DayEnd, Tran.DayStart));
      end else
      begin
        WriteUInt32(Tran.PreviousQuan);
        WriteUInt32(Tran.NewQuan);
        WriteUInt32(Tran.NewQuan - Tran.PreviousQuan);
      end;

      if (Tran.Types = $C9) then
      begin
        WriteUInt16(Tran.C0_SLOT);
        WriteUInt16(Tran.C1_SLOT);
        WriteUInt16(Tran.C2_SLOT);
        WriteUInt16(Tran.C3_SLOT);
        WriteUInt16(Tran.C4_SLOT);
      end else if (Tran.DayEnd > Tran.DayStart) then
      begin
        WriteStr(#$00, $8);
        WriteUInt16(DaysBetween(Tran.DayEnd, Tran.DayStart));
      end else begin
        WriteStr(#$00, $A);
      end;

      WriteUInt16(Length(Tran.UCC));
      WriteStr(Tran.UCC, $8);
      if Length(Tran.UCC) >= 8 then
      begin
        WriteUInt32(Tran.UCCStatus);
        WriteUInt16(Tran.UCCCopyCount);
        WriteStr(#$00, $7);
      end else if (Tran.Types = $CB) then
      begin
        WriteUInt32(Tran.CardTypeID);
        WriteUInt8(Tran.CharSlot);
      end else if (Tran.Types = $CC) then
      begin
        WriteUInt32(0);
        WriteUInt8(0);
        WriteUInt16(Tran.C0_SLOT);
        WriteUInt16(Tran.C1_SLOT);
        WriteUInt16(Tran.C2_SLOT);
        WriteUInt16(Tran.C3_SLOT);
        WriteUInt16(Tran.C4_SLOT);
        WriteUInt32(Tran.ClubPoint);
        WriteUInt8(TCompare.IfCompare<UInt8>( Tran.WorkshopCount > 0, 0, $FF));
        WriteUInt32(Tran.WorkshopCount);
        WriteUInt32(Tran.CanCelledCount);
      end else begin
        WriteUInt32(0);
        WriteUInt8(0);
      end;
    end;
  end;
  FTranList.ClearObj;
end;

end.
