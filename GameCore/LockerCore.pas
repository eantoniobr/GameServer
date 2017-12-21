unit LockerCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  ClientPacket, PangyaClient, Tools, SysUtils, uWarehouse, IffMain;

procedure PlayerSetLocker(const PL: TClientPlayer; const clientPacket: TClientPacket);
procedure HandleEnterRoom(const PL: TClientPlayer);
procedure PlayerOpenLocker(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerChangeLockerPwd(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGetPangLocker(const PL: TClientPlayer);
procedure PlayerLockerProcessPang(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerPutItemLocker(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerGetLockerItem(const PL: TCLientPlayer; const ClientPacket: TClientPacket);
procedure PlayerTakeItemLocker(const PL: TClientPlayer; const ClientPacket: TClientPacket);

implementation

procedure PlayerSetLocker(const PL: TClientPlayer; const clientPacket: TClientPacket);
var
  PwdInput: AnsiString;
  Query: TFDQuery;
  Con: TFDConnection;
  DD: Double;
begin
  if not (PL.LockerPwd = '0') then
  begin
    Exit;
  end;

  if not ClientPacket.ReadPStr(PwdInput) then Exit;

  if (Length(PwdInput) >= 4) and TryStrToFloat(PwdInput, DD) then
  begin
    CreateQuery(Query, Con);
    try
      Query.Open('EXEC [DBO].ProcSetLockerPwd @UID = :UID, @PWD = :PWD', [PL.GetUID, PwdInput]);

      if not (Query.FieldByName('Code').AsInteger = 1) then Exit;

      PL.LockerPwd := PwdInput;
      PL.Send(#$76#$01#$00#$00#$00#$00);
    finally
      FreeQuery(Query, Con);
    end;
  end;
end;

procedure PlayerChangeLockerPwd(const PL:TClientPlayer; const ClientPacket: TClientPacket);
var
  OLDPWD, NEWPWD: AnsiString;
  Query: TFDQuery;
  Con: TFDConnection;
  DD: Double;
begin
  if not ClientPacket.ReadPStr(OLDPWD) then Exit;
  if not ClientPacket.ReadPStr(NEWPWD) then Exit;

  if not (PL.LockerPWD = OLDPWD) then
  begin
    PL.Send(#$74#$01#$75#$00#$00#$00);
    Exit;
  end;

  if (Length(NEWPWD) >= 4) and TryStrToFloat(NEWPWD, DD) then
  begin
    CreateQuery(Query, Con);
    try
      Query.Open('EXEC [DBO].ProcSetLockerPwd @UID = :UID, @PWD = :PWD', [PL.GetUID, NEWPWD]);

      if not (Query.FieldByName('Code').AsInteger = 1) then Exit;

      PL.LockerPwd := NEWPWD;
      PL.Send(#$74#$01#$00#$00#$00#$00);
    finally
      FreeQuery(Query, Con);
    end;
  end;
end;

procedure PlayerGetPangLocker(const PL: TClientPlayer);
begin
  PL.SendLockerPang;
  PL.Send(#$6D#$01#$01#$00#$01#$00);
end;

procedure PlayerOpenLocker(const PL: TClientPlayer; const CLientPacket: TClientPacket);
var
  PwdInput: AnsiString;
begin
  if not ClientPacket.ReadPStr(PwdInput) then Exit;

  if not (PL.LockerPWD = PwdInput) then
  begin
    PL.Send(#$6C#$01#$75#$00#$00#$00);
    Exit;
  end;

  PL.Send(#$6C#$01#$00#$00#$00#$00);

end;

procedure HandleEnterRoom(const PL: TClientPlayer);
begin
  if PL.LockerPwd = '0' then
  begin
    PL.Send(#$70#$01#$00#$00#$00#$00#$02#$00#$00#$00);
    Exit;
  end;

  PL.Send(#$70#$01#$00#$00#$00#$00#$4C#$00#$00#$00);
end;

procedure PlayerLockerProcessPang(const PL: TClientPlayer; const ClientPacket: TClientPacket);
type
  TLockerData = packed record
    var Process: UInt8;
    var Pang: UInt64;
  end;
var
  Data: TLockerData;
begin
  if not ClientPacket.Read(Data, SizeOf(TLockerData)) then Exit;

  if (Data.Pang <= 0) then Exit;

  PL.Send(#$71#$01#$00#$00#$00#$00);

  case Data.Process of
    0: // WITHDRAW
      begin
        if PL.RemoveLockerPang(Data.Pang) then
        begin
          PL.AddPang(Data.Pang);
        end;
      end;
    1: // DEPOSIT
      begin
        if PL.RemovePang(Data.Pang) then
        begin
          PL.AddLockerPang(Data.Pang);
        end;
      end;
  end;

  PL.SendPang;
  PL.SendLockerPang;
end;

// 6B = The process is not yet finished
// 6C = You have too many items, cannot be put more
// 6D = This item can not be put in locker
// 6E = This item can be expired, cannot be put it locker
// 6F = Cannot be put the amount of item more than you have
// 70 = The process is finished // automatically close the locker
procedure PlayerPutItemLocker(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Index: UInt32;
  ItemP: PItem;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
begin
  // Skip for unused data
  ClientPacket.Skip(13);
  if not ClientPacket.ReadUInt32(Index) then Exit;

  ItemP := PL.Inventory.ItemWarehouse.GetItem(Index);

  if (nil = ItemP) then
  begin
    PL.Send(#$6E#$01#$6B#$00#$00#$00);
    Exit;
  end;

  if not (GetItemGroup(ItemP.ItemTypeID) = $2) then
  begin
    PL.Send(#$6E#$01#$6D#$00#$00#$00);
    Exit;
  end;

  CreateQuery(Query, Con);
  Packet := TClientPacket.Create;
  try
    Query.SQL.Add('EXEC [dbo].[USP_INVEN_PUSH]');
    Query.SQL.Add('@UID     = :UID,');
    Query.SQL.Add('@TYPEID  = :TYPEID,');
    Query.SQL.Add('@NAME    = :NAME,');
    Query.SQL.Add('@FROM_ID = :FROMID');

    Query.ParamByName('UID').AsInteger       := PL.GetUID;
    Query.ParamByName('TYPEID').AsInteger    := ItemP.ItemTypeID;
    Query.ParamByName('NAME').AsAnsiString   := IffEntry.GetItemName(ItemP.ItemTypeID);
    Query.ParamByName('FROMID').AsInteger    := ItemP.ItemIndex;

    Query.Open;

    if not (Query.FieldByName('CODE').AsInteger = 0) then
    begin
      PL.Send(#$6E#$01#$6B#$00#$00#$00);
      Exit;
    end;

    if PL.Inventory.ItemWarehouse.RemoveItem(ItemP) then
    begin
      PL.Send(#$39#$01#$00#$00);

      // EC
      with Packet do
      begin
        WriteStr(#$EC#$00);
        WriteUInt32(1);
        WriteUInt32(1);
        WriteStr(#$00, $9);
        WriteUInt32(ItemP.ItemTypeID);
        WriteUInt32(ItemP.ItemIndex);
        WriteUInt32(1); // Quantity
        WriteStr(#$00, $1B);
        WriteStr(ItemP.ItemUCCUnique, $9);
        WriteUInt16(ItemP.ItemUCCCopyCount);
        WriteUInt8(ItemP.ItemUCCStatus);
        WriteStr(#$00, $36);
        WriteStr(ItemP.ItemUCCName, $10);
        WriteStr(#$00, $19);
        WriteStr(ItemP.ItemUCCDrawer ,$16);
      end;

      PL.Send(Packet);

      // 6E 01
      with Packet do
      begin
        Clear;
        WriteStr(#$6E#$01);
        WriteStr(#$00, $C);
        WriteUInt32(ItemP.ItemTypeID);
        WriteUInt32(ItemP.ItemIndex);
        WriteUInt32(1); // Quantity
        WriteStr(#$00, $1B);
        WriteStr(ItemP.ItemUCCUnique, $9);
        WriteUInt16(ItemP.ItemUCCCopyCount);
        WriteUInt8(ItemP.ItemUCCStatus);
        WriteStr(#$00, $36);
        WriteStr(ItemP.ItemUCCName, $10);
        WriteStr(#$00, $19);
        WriteStr(ItemP.ItemUCCDrawer ,$16);
      end;

      PL.Send(Packet);

      // Dispose Item
      Dispose(ItemP);
    end;
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerGetLockerItem(const PL: TCLientPlayer; const ClientPacket: TClientPacket);
var
  Page: UInt16;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
begin
  ClientPacket.Skip(4);
  if not ClientPacket.ReadUInt16(Page) then Exit;

  CreateQuery(Query, Con, False);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [DBO].ProcGetLockerItem @UID = :UID, @PAGE = :PAGE' ,[PL.GetUID, Page]);

    with Packet do
    begin
      WriteStr(#$6D#$01);
      WriteUInt16(Query.FieldByName('TOTAL_PAGE').AsInteger);
      WriteUInt16(Page);

      QueryNextSet(Query);

      WriteUInt8(Query.RecordCount);

      while not Query.Eof do
      begin
        WriteUInt32(Query.FieldByName('INVEN_ID').AsInteger);
        WriteUInt32(0);
        WriteUInt32(Query.FieldByName('TypeID').AsInteger);
        WriteUInt32(0);
        WriteUInt32(1);
        WriteStr(#$00, $1B);
        WriteStr(Query.FieldByName('UCC_UNIQE').AsAnsiString, $9);
        WriteUInt16(Query.FieldByName('UCC_COPY_COUNT').AsInteger);
        WriteUInt8(Query.FieldByName('UCC_STATUS').AsInteger);
        WriteStr(#$00, $36);
        WriteStr(Query.FieldByName('UCC_NAME').AsAnsiString ,$10);
        WriteStr(#$00, $19);
        WriteStr(Query.FieldByName('NICKNAME').AsAnsiString ,$16);
        Query.Next;
      end;

      PL.Send(Packet);
    end;

  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;

end;

procedure PlayerTakeItemLocker(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  InvenID: UInt32;
  Query: TFDQuery;
  Con: TFDConnection;
  Packet: TClientPacket;
  Item: PItem;
begin
  ClientPacket.Skip(1);
  if not ClientPacket.ReadUInt32(InvenID) then Exit;

  CreateQuery(Query, Con, False);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [DBO].USP_INVEN_POP @UID = :UID, @INV_ID = :INVID' ,[PL.GetUID, InvenID]);

    if not (Query.FieldByName('ERROR').AsInteger = 0) then
    begin
      PL.Send(#$6F#$01#$6B#$00#$00#$00);
      Exit;
    end;

    QueryNextSet(Query);

    New(Item);
    Item.CreateNewItem;
    Item.ItemIndex := Query.FieldByName('ITEM_ID').AsInteger;
    Item.ItemTypeID := Query.FieldByName('TYPEID').AsInteger;
    Item.ItemC0 := Query.FieldByName('C0').AsInteger;
    Item.ItemC1 := Query.FieldByName('C1').AsInteger;
    Item.ItemC2 := Query.FieldByName('C2').AsInteger;
    Item.ItemC3 := Query.FieldByName('C3').AsInteger;
    Item.ItemC4 := Query.FieldByName('C4').AsInteger;
    Item.ItemEndDate := Query.FieldByName('DateEnd').AsDateTime;
    Item.ItemFlag := Query.FieldByName('FLAG').AsInteger;
    Item.ItemUCCUnique := Query.FieldByName('UCC_UNIQE').AsAnsiString;
    Item.ItemUCCStatus := Query.FieldByName('UCC_STATUS').AsInteger;
    Item.ItemUCCName := Query.FieldByName('UCC_NAME').AsAnsiString;
    Item.ItemUCCDrawerUID := Query.FieldByName('UCC_DRAWER_UID').AsInteger;
    Item.ItemUCCDrawer := Query.FieldByName('UCC_DRAWER_NICKNAME').AsAnsiString;
    Item.ItemUCCCopyCount := Query.FieldByName('UCC_COPY_COUNT').AsInteger;
    // Add to inventory
    PL.Inventory.ItemWarehouse.Add(Item);

    Packet.WriteStr(#$EC#$00);
    Packet.WriteUInt8(1);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(PL.GetPang);
    Packet.WriteStr(#$00, $8);
    Packet.WriteUInt32(Item.ItemTypeID);
    Packet.WriteUInt32(Item.ItemIndex);
    Packet.WriteUInt32(1);
    Packet.WriteStr(#$00, $1B);
    Packet.WriteStr(Item.ItemUCCUnique, $9);
    Packet.WriteUInt16(Item.ItemUCCCopyCount);
    Packet.WriteUInt8(Item.ItemUCCStatus);
    Packet.WriteStr(#$00, $36);
    Packet.WriteStr(Item.ItemUCCName, $10);
    Packet.WriteStr(#$00, $19);
    Packet.WriteStr(Item.ItemUCCDrawer, $10);
    Packet.WriteStr(#$00, $6);
    Packet.WriteUInt8(3);
    Packet.WriteUInt32(Item.ItemIndex);
    Packet.WriteUInt32(Item.ItemTypeID);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(1);
    Packet.WriteStr(#$00, $6);
    Packet.WriteUInt32(1);
    Packet.WriteStr(#$00, $E);
    Packet.WriteUInt8(2);
    Packet.WriteStr(Item.ItemUCCName, $10);
    Packet.WriteStr(#$00, $19);
    Packet.WriteStr(Item.ItemUCCUnique, $9);
    Packet.WriteUInt8(Item.ItemUCCStatus);
    Packet.WriteUInt16(Item.ItemUCCCopyCount);
    Packet.WriteStr(Item.ItemUCCDrawer, $10);
    Packet.WriteStr(#$00, $4E);
    Packet.WriteStr(#$FF#$FF#$FF#$FF);
    Packet.WriteUInt32(0);
    PL.Send(Packet);

    Packet.Clear;
    Packet.WriteStr(#$6F#$01);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(InvenID);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(Item.ItemTypeID);
    Packet.WriteUInt32(Item.ItemIndex);
    Packet.WriteUInt32(1);
    Packet.WriteStr(#$00, $1B);
    Packet.WriteStr(Item.ItemUCCUnique, $9);
    Packet.WriteUInt16(Item.ItemUCCCopyCount);
    Packet.WriteUInt8(Item.ItemUCCStatus);
    Packet.WriteStr(#$00, $36);
    Packet.WriteStr(Item.ItemUCCName, $10);
    Packet.WriteStr(#$00, $19);
    Packet.WriteStr(Item.ItemUCCDrawer, $10);
    Packet.WriteStr(#$00, $6);
    PL.Send(Packet);
  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

end.
