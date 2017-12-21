unit SerialID;

interface

uses
  System.SysUtils;

type
  TSerialId = class
  private
    var
      FUniqueID: array[0..2999] of ShortInt;
  public
    constructor Create;
    destructor Destroy; override;
    function GetId: Word;
    function RemoveId(Index: Word): Boolean;
  end;

implementation

{ TUniqueId }

constructor TSerialId.Create;
var
  Index: Word;
begin
  for Index := 0 to Length(FUniqueID) - 1 do
  begin
    FUniqueID[Index] := -1;
  end;
end;

destructor TSerialId.Destroy;
begin
  inherited;
end;

function TSerialId.GetId: Word;
var
  Index: Word;
begin
  for Index := 0 to Length(FUniqueID) - 1 do
  begin
    if FUniqueID[Index] = -1 then
    begin
      FUniqueID[Index] := 1;
      Exit(Index)
    end;
  end;
  Exit(0);
end;

function TSerialId.RemoveId(Index: Word): Boolean;
begin
  if FUniqueID[Index] = 1 then
  begin
    FUniqueID[Index] := -1;
    Exit(True);
  end;
  Exit(False);
end;

end.
