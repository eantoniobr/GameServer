unit RandInteger;

interface

{ * This is unit is use for random integer with no duplicated }

uses
  SysUtils, MyList;

type
  TRandInt = class
    private
      var IntList: TMyList<UInt32>;
    public
      function GetInteger(Remove: Boolean = True): UInt32;
      function GetIntegerAndRemove(IntVar: UInt32): UInt32;
      constructor Create(FIntList: Array of UInt32);
      destructor Destroy; override;
  end;

implementation

{ TRandInt }

constructor TRandInt.Create(FIntList: Array of UInt32);
var
  Index: UInt32;
begin
  IntList := TMyList<UInt32>.Create;

  for Index := 0 to Length(FIntList)-1 do
  begin
    IntList.Add(FIntList[Index]);
  end;

  for Index := 0 to Length(FIntList)-1 do
  begin
    IntList.Exchange(Random(IntList.Count - 1), Random(IntList.Count - 1));
  end;
end;

function TRandInt.GetInteger(Remove: Boolean = True): UInt32;
var
  RInteger: UInt32;
begin
  if not Remove then
  begin
    RInteger := IntList.First;
    IntList.Exchange(0, Random(IntList.Count - 1)); // Swap new position
    Exit(RInteger);
  end
  else
  begin
    if IntList.Count <= 0 then Exit(0);

    RInteger := IntList.First;
    IntList.Remove(RInteger);
    Exit(RInteger);
  end;
end;

function TRandInt.GetIntegerAndRemove(IntVar: UInt32): UInt32;
begin
  IntList.Remove(IntVar);
  Exit(IntVar);
end;

destructor TRandInt.Destroy;
begin
  IntList.Clear;
  IntList.Free;
  inherited;
end;

end.
