unit IffManager.Ball;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type

  PIffBall = ^TIffBall;

  TIffBall = packed record
    var Base: TBaseIff;
    var Un1: UInt32;
    var MPet: array[$0..$27] of AnsiChar;
    var Un2, Un3: UInt32;
    var Un4: array[$0..$22F] of AnsiChar;
    var C0, C1, C2, C3, C4: UInt16;
    var Un5: UInt16;
  end;

  TIffBalls = class
    private
      var FBall: TDictionary<UInt32, PIFfBall>;
    public
      constructor Create;
      destructor Destroy; override;
      function IsExist(TypeId: UInt32): Boolean;
      function IsBuyable(TypeId: UInt32): Boolean;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function GetPrice(TypeID: UInt32): UInt32;
      function GetItemName(TypeID: UInt32): AnsiString;
      function GetRealQuantity(TypeId, Qty: UInt32): UInt32;
      function LoadBall(ID: UInt32; var Ball: PIffBall): Boolean;
  end;

implementation

{ TIffBalls }

constructor TIffBalls.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Ball : PIffBall;
begin
  FBall := TDictionary<UInt32, PIFfBall>.Create;;

  if not FileExists('data\Ball.iff') then begin
    WriteConsole(' data\Ball.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\Ball.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 1 to Total do
    begin
      New(Ball);
      Packet.Read(Ball.Base.Enabled, SizeOf(TIffBall));
      // Add to ball database
      FBall.Add(Ball.Base.TypeID, Ball);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TIffBalls.Destroy;
var
  Ball : PIffBall;
begin
  for Ball in FBall.Values do
    Dispose(Ball);

  FBall.Clear;
  FreeAndNil(FBall);
  inherited;
end;

function TIffBalls.GetItemName(TypeID: UInt32): AnsiString;
var
  Ball : PIffBall;
begin
  if not LoadBall(TypeID, Ball) then Exit;

  Exit(Ball.Base.Name);
end;

function TIffBalls.GetPrice(TypeID: UInt32): UInt32;
var
  Ball : PIffBall;
begin
  if not LoadBall(TypeID, Ball) then Exit(99999999);
  Exit(Ball.Base.ItemPrice);
end;

function TIffBalls.GetRealQuantity(TypeId, Qty: UInt32): UInt32;
var
  Ball : PIffBall;
begin
  if not LoadBall(TypeID, Ball) then Exit(0);

  if (Ball.Base.Enabled = 1) and (Ball.C0 > 0) then
    Exit(Ball.C0);

  Exit(Qty);
end;

function TIffBalls.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  Ball : PIffBall;
begin
  if not LoadBall(TypeID, Ball) then Exit(-1);

  Exit(Ball.Base.PriceType);
end;

function TIffBalls.IsBuyable(TypeId: UInt32): Boolean;
var
  Ball : PIffBall;
begin
  if not LoadBall(TypeID, Ball) then Exit(False);
  Exit( (Ball.Base.Enabled = 1) and (Ball.Base.ItemFlag and 1 <> 0) );
end;

function TIffBalls.IsExist(TypeId: UInt32): Boolean;
var
  Ball : PIffBall;
begin
  if not LoadBall(TypeID, Ball) then Exit(False);
  Exit(Ball.Base.Enabled = 1);
end;

function TIffBalls.LoadBall(ID: UInt32; var Ball: PIffBall): Boolean;
begin
  if not FBall.TryGetValue(ID, Ball) then Exit(False);
  Exit(True);
end;

end.
