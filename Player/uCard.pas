unit uCard;

interface

uses
  ClientPacket, MyList, XSuperObject;

type
  PCard = ^TPlayerCard;

  TPlayerCard = packed record
    var CardIndex: UInt32;
    var CardTypeID: UInt32;
    var CardQuantity: UInt32;
    var CardIsValid: UInt8;
    var CardNeedUpdate: Boolean;
    procedure AddQuantity(Qty: UInt32);
    function RemoveQuantity(Count: UInt32): Boolean;
  end;

  TSerialCard = class(TMyList<PCard>)
    public
      constructor Create;
      destructor Destroy; override;
      function Add(Const Value : PCard): Integer;
      function GetCard(ID: UInt32; Quantity: UInt32): PCard; overload;
      function GetCard(ID: UInt32): PCard; overload;
      function GetCard(TypeID, Index, Quantity: UInt32): PCard; overload;
      function GetSQLUpdateJSON: AnsiString;
      function IsExist(TypeID, Index, Quantity: UInt32): Boolean;
  end;

implementation

{ TSerialCard }

function TSerialCard.Add(const Value: PCard): Integer;
begin
  Value.CardNeedUpdate := False;
  Exit(inherited Add(Value));
end;

constructor TSerialCard.Create;
begin
  inherited;
end;

destructor TSerialCard.Destroy;
var
  Card: PCard;
begin
  for Card in Self do
    Dispose(Card);

  Self.Clear;

  inherited;
end;

function TSerialCard.GetCard(ID: UInt32): PCard;
var
  Card: PCard;
begin
  for Card in Self do
  begin
    if (Card^.CardIndex = ID) and (Card^.CardQuantity >= 1) and (Card^.CardIsValid = 1) then
    begin
      Exit(Card);
    end;
  end;
  Exit(nil);
end;

function TSerialCard.GetCard(ID: UInt32; Quantity: UInt32): PCard;
var
  Card: PCard;
begin
  for Card in Self do
  begin
    if (Card^.CardTypeID = ID) and (Card^.CardQuantity >= Quantity) and (Card^.CardIsValid = 1) then
    begin
      Exit(Card);
    end;
  end;
  Exit(nil);
end;

function TSerialCard.GetCard(TypeID, Index, Quantity: UInt32): PCard;
var
  Card: PCard;
begin
  for Card in Self do
  begin
    if (Card^.CardTypeID = TypeID) and (Card^.CardIndex = Index) and (Card^.CardQuantity >= Quantity) and (Card^.CardIsValid = 1) then
    begin
      Exit(Card);
    end;
  end;
  Exit(nil);
end;

function TSerialCard.GetSQLUpdateJSON: AnsiString;
var
  JSON, NestJS: ISuperObject;
  Cards: PCard;
begin
  JSON := SO;
  for Cards in Self do
  begin
    if Cards.CardNeedUpdate then
    begin
      Cards.CardNeedUpdate := False;
      NestJS := SO;
      NestJS.I['CardIndex'] := Cards.CardIndex;
      NestJS.I['CardQty'] := Cards.CardQuantity;
      NestJS.I['CardValid'] := Cards.CardIsValid;
      JSON.A['Cards'].Add(NestJS);
    end;
  end;
  Exit(AnsiString(JSON.AsJSON()));
end;

function TSerialCard.IsExist(TypeID, Index, Quantity: UInt32): Boolean;
var
  Card: PCard;
begin
  for Card in Self do
    if (Card^.CardTypeID = TypeID) and (Card^.CardIndex = Index) and (Card^.CardQuantity >= Quantity) and (Card^.CardIsValid = 1) then
      Exit(True);

  Exit(False);
end;

{ TPlayerCard }

procedure TPlayerCard.AddQuantity(Qty: UInt32);
begin
  Inc(Self.CardQuantity, Qty);
  Self.CardNeedUpdate := True;
end;

function TPlayerCard.RemoveQuantity(Count: UInt32): Boolean;
begin
  Dec(Self.CardQuantity, Count);
  if Self.CardQuantity <= 0 then
  begin
    Self.CardIsValid := 0;
  end;
  Self.CardNeedUpdate := True;
  Exit(True);
end;

end.
