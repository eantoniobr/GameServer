unit uItemSlot;

interface

type
  TItemsSlot = packed record
    var Slot1 : UInt32;
    var Slot2 : UInt32;
    var Slot3 : UInt32;
    var Slot4 : UInt32;
    var Slot5 : UInt32;
    var Slot6 : UInt32;
    var Slot7 : UInt32;
    var Slot8 : UInt32;
    var Slot9 : UInt32;
    var Slot10 : UInt32;
    function SetItemSlot(SlotData: TItemsSlot): Boolean;
    function GetItemSlot: AnsiString;
    procedure Clear;
  end;

implementation

{ TItemsUsing }

procedure TItemsSlot.Clear;
begin
  FillChar(Self.Slot1, SizeOf(TItemsSlot), 0);
end;

function TItemsSlot.GetItemSlot: AnsiString;
begin
  SetLength(Result, SizeOf(TItemsSlot));
  Move(Self.Slot1, Result[1], SizeOf(TItemsSlot))
end;

function TItemsSlot.SetItemSlot(SlotData: TItemsSlot): Boolean;
begin
  Self.Slot1 := SlotData.Slot1;
  Self.Slot2 := SlotData.Slot2;
  Self.Slot3 := SlotData.Slot3;
  Self.Slot4 := SlotData.Slot4;
  Self.Slot5 := SlotData.Slot5;
  Self.Slot6 := SlotData.Slot6;
  Self.Slot7 := SlotData.Slot7;
  Self.Slot8 := SlotData.Slot8;
  Self.Slot9 := SlotData.Slot9;
  Self.Slot10 := SlotData.Slot10;

  Exit(True);
end;
end.
