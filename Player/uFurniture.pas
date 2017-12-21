unit uFurniture;

interface

uses
  ClientPacket, MyList, XSuperObject;

type

  PFurniture = ^TPlayerFurniture;

  TPlayerFurniture = packed record
    var Index: UInt32;
    var TypeID: UInt32;
    var PosX: Single;
    var PosY: Single;
    var PosZ: Single;
    var PosR: Single;
    var Valid: UInt8;
    var Update: Boolean;
  end;

  TSerialFurniture = class(TMyList<PFurniture>)
    public
      function Add(Const Value: PFurniture): Integer;
      constructor Create;
      destructor Destroy; override;
  end;

implementation

{ TSerialFurniture }

function TSerialFurniture.Add(const Value: PFurniture): Integer;
begin
  Value.Update := False;
  Exit(inherited Add(Value));
end;

constructor TSerialFurniture.Create;
begin
  inherited;
end;

destructor TSerialFurniture.Destroy;
var
  Furniture: PFurniture;
begin

  for Furniture in Self do
    Dispose(Furniture);

  Self.Clear;

  inherited;
end;

end.
