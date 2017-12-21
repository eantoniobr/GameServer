unit UserMatchHistory;

interface

type
  TMatchHistory = record
    var
      UID1, UID2, UID3, UID4, UID5: UInt32;
    procedure Add(UID: UInt32);
  end;

implementation

{ TMatchHistory }

procedure TMatchHistory.Add(UID: UInt32);
var
  tUID1, tUID2, tUID3, tUID4, tUID5: UInt32;
begin
  tUID1 := UID1;
  tUID2 := UID2;
  tUID3 := UID3;
  tUID4 := UID4;
  tUID5 := UID5;

  UID1 := UID;
  UID2 := tUID1;
  UID3 := tUID2;
  UID4 := tUID3;
  UID5 := tUID4;
end;

end.
