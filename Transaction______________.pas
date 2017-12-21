unit Transaction;

interface

uses
  ClientPacket, System.SyncObjs, MyList;

type

  TTransactionData = packed record
    var ItemTypeID: UInt32;
    var ItemIndex: UInt32;
    var ItemOldQty: UInt32;
    var ItemNewQty: UInt32;
    var ItemToAddQty: UInt32;
    var ItemType: UInt8;
    var ItemUCCUnique: AnsiString;
    var ItemData: AnsiString;
  end;

  PTransaction = ^TTransaction;
  TTransaction = packed record
    var ItemTypeID: UInt32;
    var ItemIndex: UInt32;
    var ItemOldQty: UInt32;
    var ItemNewQty: UInt32;
    var ItemToAddQty: UInt32;
    var ItemType: UInt8;
    var ItemTypeCard: UInt32;
    var ItemSlotCardNum: UInt8;
    var ItemUCCUnique: AnsiString;
    var ItemData: AnsiString;
    function GetTransaction: AnsiString;
    procedure SetTransaction(FItemTypeID, FItemIndex, FItemOldQty, FItemNewQty,
      FItemToAddQty: UInt32; FItemType: UInt8; FItemUCCUnique: AnsiString = '';
      FItemTypeCard: UInt32 = 0; FItemSlotCardNum: UInt8 = 0;
      FItemData: AnsiString = '');
  end;

  TSerialTransaction = class(TMyList<PTransaction>)
    private
      var TranLock: TCriticalSection;
    public
      constructor Create;
      destructor Destroy; override;
      function GetTran: AnsiString;
  end;

implementation

{ TTransaction }

procedure TTransaction.SetTransaction(FItemTypeID, FItemIndex, FItemOldQty,
  FItemNewQty, FItemToAddQty: UInt32; FItemType: UInt8;
  FItemUCCUnique: AnsiString = ''; FItemTypeCard: UInt32 = 0;
  FItemSlotCardNum: UInt8 = 0; FItemData: AnsiString = '');
begin
  ItemTypeID    := FItemTypeID;
  ItemIndex     := FItemIndex;
  ItemOldQty    := FItemOldQty;
  ItemNewQty    := FItemNewQty;
  ItemToAddQty  := FItemToAddQty;
  ItemType      := FItemType;
  ItemUCCUnique := FItemUCCUnique;
  ItemTypeCard  := FItemTypeCard;
  ItemData      := FItemData;
  {TO CHECK IF UCC}
  if Length(FItemUCCUnique) > 0 then
  begin
    ItemSlotCardNum := 1;
    ItemData        := #$00#$00#$00#$00#$00#$00#$00#$00; // Fix for now
  end
  else
  begin
    ItemSlotCardNum := 0;
  end;
end;

function TTransaction.getTransaction: AnsiString;
var
  Packet : TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    if ItemNewQty < ItemOldQty then
    begin
      ItemToAddQty := ItemNewQty - ItemOldQty;
    end;

    Packet.WriteUInt8(ItemType);
    Packet.WriteUInt32(ItemTypeID);
    Packet.WriteUInt32(ItemIndex);
    Packet.WriteStr(#$00,4);
    Packet.WriteUInt32(ItemOldQty);
    Packet.WriteUInt32(ItemNewQty);
    Packet.WriteUInt32(ItemToAddQty);
    Packet.WriteStr(#$00, $A);
    Packet.WriteUInt16(Length(ItemUCCUnique));
    Packet.WriteStr(ItemUCCUnique, $8);
    Packet.WriteUInt32(ItemTypeCard);
    Packet.WriteUInt8(ItemSlotCardNum);
    Packet.WriteStr(ItemData);
    Result := Packet.ToStr;
  finally
    Packet.Free;
  end;
end;

{ TPlayerTransaction }

constructor TSerialTransaction.Create;
begin
  inherited;
  TranLock := TCriticalSection.Create;
end;

destructor TSerialTransaction.Destroy;
var
  Tran : PTransaction;
begin
  for Tran in self do
  begin
    Dispose(Tran);
  end;
  Clear;
  TranLock.Free;
  inherited;
end;

function TSerialTransaction.GetTran: AnsiString;
var
  Tran: PTransaction;
  Packet: TClientPacket;
begin
  TranLock.Acquire;
  Packet := TClientPacket.Create;
  try
    Packet.WriteUInt32(Count);
    for Tran in self do
    begin
      Packet.WriteStr(Tran.getTransaction);
      Dispose(Tran);
    end;
    Clear;
    Result := Packet.ToStr;
  finally
    Packet.Free;
    TranLock.Release;
  end;
end;

end.
