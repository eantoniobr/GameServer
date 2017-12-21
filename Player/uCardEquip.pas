unit uCardEquip;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  MyList, Enum, ClientPacket, System.SysUtils, Tools, System.DateUtils,
  System.Generics.Collections, XSuperObject, IffMain, Defines;

type
  TSerialEquipCard = class
    private
      var CARDEQUIP: TMyList<PCardEquip>;
    public
      constructor Create;
      destructor Destroy; override;
      procedure AddCard(P: PCardEquip);
      function UpdateCard(UID, CID, CHARTYPEID, CARDTYPEID: UInt32; SLOT, FLAG, TIME: Byte): TPair<Boolean, PCardEquip>;
      function MapCard(CID: UInt32): AnsiString;
      function GetCard(CID, SLOT: UInt32): PCardEquip;
      function Save: AnsiString;
      function ShowCard: TClientPacket;
      function GetType(TypeID: UInt32): UInt32;
  end;

implementation

{ TSerialEquipCard }

procedure TSerialEquipCard.AddCard(P: PCardEquip);
begin
  Self.CARDEQUIP.Add(P);
end;

constructor TSerialEquipCard.Create;
begin
  CARDEQUIP := TMyList<PCardEquip>.Create;
end;

destructor TSerialEquipCard.Destroy;
var
  P: PCardEquip;
begin
  for P in CARDEQUIP do
    Dispose(P);

  Self.CARDEQUIP.Clear;

  FreeAndNil(CARDEQUIP);
end;

// CHARACTER CARD
function TSerialEquipCard.GetCard(CID, SLOT: UInt32): PCardEquip;
begin
  for Result in CARDEQUIP do
    if (Result.CID = CID) and (Result.SLOT = SLOT) and (Result.FLAG = 0) and (Result.VALID = 1) then
      Exit;

  Exit(nil);
end;

function TSerialEquipCard.GetType(TypeID: UInt32): UInt32;
begin
  case GetCardType(TypeID) of
    tNormal:
      Exit(0);
    tCaddie:
      Exit(1);
    tNPC:
      Exit(5);
    tSpecial:
      Exit(2);
  else
      Exit(0);
  end;
end;

function TSerialEquipCard.UpdateCard(UID, CID, CHARTYPEID, CARDTYPEID: UInt32; SLOT, FLAG, TIME: Byte): TPair<Boolean, PCardEquip>;
var
  UP, P: PCardEquip;
  Query: TFDQuery;
  Con: TFDConnection;
begin
  UP := nil;
  P := nil;

  for P in CARDEQUIP do
  begin
    case FLAG of
      0:
        begin
          if (P.CID = CID) and (P.CHAR_TYPEID = CHARTYPEID) and (P.SLOT = SLOT)
            and (P.FLAG = 0) and (P.VALID = 1) then
          begin
            UP := P;
            Break;
          end;
        end;
      1:
        begin
          if (P.CID = CID) and (P.CARD_TYPEID = CARDTYPEID) and (P.SLOT = SLOT)
            and (P.FLAG = 1) and (P.ENDDATE > Now()) and (P.VALID = 1) then
          begin
            UP := P;
            Break;
          end;
        end;
    end;
  end;

  P := nil;

  if (UP = nil) then
  begin

    CreateQuery(Query, Con);
    try
      Query.SQL.Add('EXEC [dbo].[USP_ADD_CARD_EQUIP]');
      Query.SQL.Add('@UID         = :UID,');
      Query.SQL.Add('@CID         = :CID,');
      Query.SQL.Add('@CHARTYPEID  = :CHARTYPEID,');
      Query.SQL.Add('@CARDTYPEID  = :CARDTYPEID,');
      Query.SQL.Add('@SLOT        = :SLOT,');
      Query.SQL.Add('@FLAG        = :FLAG,');
      Query.SQL.Add('@TIME        = :TIME');

      Query.ParamByName('UID').AsInteger        := UID;
      Query.ParamByName('CID').AsInteger        := CID;
      Query.ParamByName('CHARTYPEID').AsInteger := CHARTYPEID;
      Query.ParamByName('CARDTYPEID').AsInteger := CARDTYPEID;
      Query.ParamByName('SLOT').AsInteger       := SLOT;
      Query.ParamByName('FLAG').AsInteger       := FLAG;
      Query.ParamByName('TIME').AsInteger       := TIME;

      Query.Open;

      if not (Query.FieldByName('CODE').AsInteger = 0) then
      begin
        Exit( Result.Create(False, nil) );
      end;

      New(P);
      P.ID := Query.FieldByName('OUT_INDEX').AsInteger;
      P.CID := Query.FieldByName('CID').AsInteger;
      P.CHAR_TYPEID := Query.FieldByName('CHARTYPEID').AsInteger;
      P.CARD_TYPEID := Query.FieldByName('CARDTYPEID').AsInteger;
      P.SLOT := Query.FieldByName('SLOT').AsInteger;
      P.REGDATE := Query.FieldByName('REGDATE').AsDateTime;
      P.ENDDATE := Query.FieldByName('ENDDATE').AsDateTime;
      P.FLAG := Query.FieldByName('FLAG').AsInteger;
      P.VALID := 1;
      P.NEEDUPDATE := False;

      Self.AddCard(P);
      Exit(Result.Create(True, P));
    finally
      FreeQuery(Query, Con);
    end;
  end else begin
    UP.CARD_TYPEID := CARDTYPEID;
    UP.NEEDUPDATE := True;

    if FLAG = 1 then
      UP.ENDDATE := IncMinute(UP.ENDDATE, TIME);

    Exit(Result.Create(True, UP));
  end;
end;

function TSerialEquipCard.MapCard(CID: UInt32): AnsiString;
var
  PC: PCardEquip;
  TC: TPCards;
  Packet: TClientPacket;
begin
  TC.Default;

  for PC in CARDEQUIP do
    if PC.CID = CID then
      TC.Card[PC.SLOT] := PC.CARD_TYPEID;

  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteUInt32(TC.Card[1]);
      WriteUInt32(TC.Card[2]);
      WriteUInt32(TC.Card[3]);
      WriteUInt32(TC.Card[4]);
      WriteUInt32(TC.Card[5]);
      WriteUInt32(TC.Card[6]);
      WriteUInt32(TC.Card[7]);
      WriteUInt32(TC.Card[8]);
      WriteUInt32(TC.Card[9]);
      WriteUInt32(TC.Card[10]);
      Exit(ToStr);
    end;
  finally
    Packet.Free;
  end;
end;

function TSerialEquipCard.Save: AnsiString;
var
  JSON, NestJSON: ISuperObject;
  P: PCardEquip;
begin
  JSON := SO;

  for P in CARDEQUIP do
  begin
    if P.NEEDUPDATE then
    begin
      NestJSON := SO;
      NestJSON.I['UNID'] := P.ID;
      NestJSON.I['CARDTYPEID'] := P.CARD_TYPEID;
      NestJSON.D['ENDDATE'] := P.ENDDATE;
      NestJSON.I['VALID'] := P.VALID;
      P.NEEDUPDATE := False;
      JSON.A['CARDEQUIP'].Add(NestJSON);
    end;
  end;

  Exit(AnsiString(JSON.AsJSON()));
end;

function TSerialEquipCard.ShowCard: TClientPacket;
var
  C: PCardEquip;
  P: TPair<UInt32, UInt32>;
begin
  Result := TClientPacket.Create;
  with Result do
  begin
    WriteStr(#$37#$01);
    WriteUInt16(CARDEQUIP.Count);

    for C in CARDEQUIP do
    begin
      P := IffEntry.FCards.GetSPCL(C.CARD_TYPEID);

      WriteUInt32(0);
      WriteUInt32(C.CARD_TYPEID);
      WriteUInt32(C.CHAR_TYPEID);
      WriteUInt32(C.CID);
      WriteUInt32(P.Key);
      WriteUInt32(P.Value);
      WriteUInt32(C.SLOT);
      if not (C.CID = 0) then
      begin
        WriteStr(#$00, $10);
        WriteStr(#$00, $10);
      end else begin
        WriteStr(GetFixTime(C.REGDATE), $10);
        WriteStr(GetFixTime(C.ENDDATE), $10);
      end;
      WriteUInt32(Self.GetType(C.CARD_TYPEID));
      WriteUInt8(1);
    end;
  end;
end;

end.
