unit MailCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  ClientPacket, Tools, PangyaClient, System.SysUtils, XSuperObject, ItemData;

procedure PlayerGetMailList(const PL: TClientPlayer; const ClientPacket: TClientPacket; const Header: Ansistring = #$11#$02);
procedure PlayerDeleteMail(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerReadMail(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerReleaseItem(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerShowMailPopUp(const PL: TClientPlayer);

implementation

procedure PlayerGetMailList(const PL: TClientPlayer;const ClientPacket: TClientPacket; const Header: Ansistring = #$11#$02);
var
  Query: TFDQuery;
  Con: TFDConnection;
  PageSelect: UInt32;
  Reply: TClientPacket;
begin
  if not clientPacket.ReadUInt32(PageSelect) then
    Exit;

  CreateQuery(Query, Con, False);
  Reply := TClientPacket.Create;
  try
    Query.Open('EXEC [dbo].[ProcGetMail] @UID = :UID, @PAGE = :PAGE, @TOTAL = 20, @READ = 2', [PL.GetUID, PageSelect]);

    Reply.WriteStr(Header);
    Reply.WriteStr(#$00#$00#$00#$00);
    Reply.WriteUInt32(PageSelect);
    Reply.WriteUInt32(Query.FieldByName('PAGE_TOTAL').AsInteger);

    QueryNextSet(Query);

    Reply.WriteUInt32(Query.RecordCount);

    while not Query.Eof do
    begin
      Reply.WriteUInt32(Query.FieldByName('Mail_Index').AsInteger);
      Reply.WriteStr(Query.FieldByName('Sender').AsAnsiString, 16);
      Reply.WriteStr(#$00, $74);
      Reply.WriteUInt8(Query.FieldByName('IsRead').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('Mail_Item_Count').AsInteger);
      Reply.WriteStr(#$FF#$FF#$FF#$FF);
      Reply.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
      Reply.WriteUInt8(Query.FieldByName('IsTimer').AsInteger); // Time
      Reply.WriteUInt32(Query.FieldByName('QTY').AsInteger);
      Reply.WriteUInt32(Query.FieldByName('DAY').AsInteger); // Day
      Reply.WriteStr(#$00, $10);
      Reply.WriteStr(#$FF#$FF#$FF#$FF);
      Reply.WriteUInt32(0);
      Reply.WriteStr(IsUCCNull(Query.FieldByName('UCC_UNIQUE').AsAnsiString, #$30), 8); // UCC UNIQUE
      Reply.WriteStr(#$00, 6);

      Query.Next;
    end;

    PL.Send(Reply);
  finally
    FreeAndNil(Reply);
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerDeleteMail(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  MailIndex, Count: UInt32;
  I: UInt8;
  Query: TFDQuery;
  Con: TFDConnection;
  RET: UInt8;
  JSON, NestJS: ISuperObject;
begin
  if not ClientPacket.ReadUInt32(Count) then Exit;

  CreateQuery(Query, Con);
  JSON := SO;
  try
    for I := 0 to Count - 1 do
    begin
      if not clientPacket.ReadUInt32(MailIndex) then Exit;

      // ## JSON ADDED ##
      NestJS := SO;
      NestJS.I['MailIndex'] := MailIndex;
      JSON.A['MailDelete'].Add(NestJS);
      // ## END
    end;

    Query.SQL.Text := 'EXEC [dbo].[ProcDelMail] @UID = :UID, @JASONData = :JADATA';
    Query.ParamByName('UID').AsInteger := PL.GetUID;
    Query.ParamByName('JADATA').AsAnsiString := AnsiString(JSON.AsJSON);
    Query.Open;

    RET := Query.FieldByName('RET').AsInteger;

    if (RET = 0) then
    begin
      PL.Send(#$14#$02#$F9#$16#$2D#$00); // cant delete mail
      Exit;
    end;

    PlayerGetMailList(PL, clientPacket, #$15#$02);
    //FPlayer.Send(#$14#$02#$FA#$16#$2D#$00); still have an item in email so cannot be deleted
  finally
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerReadMail(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  MailIndex: UInt32;
  Packet: TClientPacket;
  Con: TFDConnection;
  Query: TFDQuery;
begin
  if not clientPacket.ReadUInt32(MailIndex) then Exit;

  Packet := TClientPacket.Create;
  CreateQuery(Query, Con, False);
  try
    Query.Open('EXEC [dbo].[ProcReadMail] @UID = :UID, @Mail_Index = :MID', [PL.GetUID, MailIndex]);

    Packet.WriteStr(#$12#$02#$00#$00#$00#$00);
    Packet.WriteUInt32(Query.FieldByName('Mail_Index').AsInteger);
    Packet.WritePStr(Query.FieldByName('Sender').AsAnsiString);
    Packet.WritePStr(Query.FieldByName('RegDate').AsAnsiString);
    Packet.WritePStr(Query.FieldByName('Msg').AsAnsiString);
    Packet.WriteStr(#$01);

    Query.NextRecordSet;
    Query.FetchAll;

    Packet.WriteUInt32(Query.RecordCount);

    while not Query.Eof do
    begin
      Packet.WriteStr(#$FF#$FF#$FF#$FF);
      Packet.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
      Packet.WriteUInt8(Query.FieldByName('IsTime').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('QTY').AsInteger);
      Packet.WriteUInt32(Query.FieldByName('DAY').AsInteger);
      Packet.WriteStr(#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
      Packet.WriteStr(#$FF#$FF#$FF#$FF#$00#$00#$00#$00#$30#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
      Query.Next;
    end;

    PL.Send(Packet);

  finally
    FreeQuery(Query, Con);
    FreeAndNil(Packet);
  end;
end;

procedure PlayerReleaseItem(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Con: TFDConnection;
  Query: TFDQuery;
  MailIndex: UInt32;
  FTypeID, FQuantity, ItemMailIndex: UInt32;
  ItemAddedData: TAddData;
  ItemData: TAddItem;
  JSON, NestJS: ISuperObject;
begin
  if not clientPacket.ReadUInt32(MailIndex) then Exit;

  CreateQuery(Query, Con);
  JSON := SO;
  try
    Query.Open('EXEC [dbo].[ProcMailItem] @UID = :UID, @Mail_Index = :MID', [PL.GetUID, MailIndex]);

    if not (Query.RecordCount >= 1) then
    begin
      PL.Send(#$14#$02#$98#$26#$2D#$00);
      Exit;
    end;

    while not Query.Eof do
    begin
      FTypeID := Query.FieldByName('TYPEID').AsInteger;
      FQuantity := Query.FieldByName('QTY').AsInteger;

      { EXP POCKET }
      if FTypeID = 436207965 then
      begin

      end
      { PANG POCKET }
      else if FTypeID = 436207632 then
      begin
        if UInt32(PL.GetPang + FQuantity) > UInt32(High(Int32)) then
        begin
          PL.Send(#$14#$02#$2C#$0F#$2D#$00);
          Exit;
        end;
      end
      { OTHERS ITEM }
      else if not PL.Inventory.Available(FTypeID, FQuantity) then
      begin
        PL.Send(#$14#$02#$2C#$0F#$2D#$00);
        Exit;
      end;

      Query.Next;
    end;

    { FETCH AGAIN }
    Query.First;

    while not Query.Eof do
    begin
      FTypeID := Query.FieldByName('TYPEID').AsInteger;
      FQuantity := Query.FieldByName('QTY').AsInteger;
      ItemMailIndex := Query.FieldByName('Mail_Index').AsInteger;

      { EXP POCKET }
      if FTypeID = 436207965 then
      begin
        PL.AddExp(FQuantity);
        { JSON ADDED }
        NestJS := SO;
        NestJS.I['MailIndex'] := ItemMailIndex;
        NestJS.I['ItemTypeID'] := 436207965;
        NestJS.I['ItemAddedIndex'] := 0;
        JSON.A['MailUpdate'].Add(NestJS);
        { END JSON ADD }
      end
      { PANG POCKET }
      else if FTypeID = 436207632 then
      begin
        PL.AddPang(FQuantity);
        PL.SendPang;
        { JSON ADDED }
        NestJS := SO;
        NestJS.I['MailIndex'] := ItemMailIndex;
        NestJS.I['ItemTypeID'] := 436207632;
        NestJS.I['ItemAddedIndex'] := 0;
        JSON.A['MailUpdate'].Add(NestJS);
        { END JSON ADD }
      end
      else
      { OTHER ITEM }
      begin
        with ItemData do
        begin
          ItemIffId := FTypeID;
          Quantity := FQuantity;
          Transaction := True;
          Day := 0;
        end;
        ItemAddedData := PL.AddItem(ItemData);
        { JSON ADDED }
        NestJS := SO;
        NestJS.I['MailIndex'] := ItemMailIndex;
        NestJS.I['ItemTypeID'] := FTypeID;
        NestJS.I['ItemAddedIndex'] := ItemAddedData.ItemIndex;
        JSON.A['MailUpdate'].Add(NestJS);
        { END JSON ADD }
      end;
      Query.Next;
    end;
    PL.SendTransaction;
    PL.Send(#$14#$02#$00#$00#$00#$00);

    { update mail items }
    Query.SQL.Text := 'EXEC [dbo].[ProcUpdateMail] @UID = :UID, @MailIndex = :MAILID , @JSONData = :JSONSTR';
    Query.ParamByName('UID').AsInteger := PL.GetUID;
    Query.ParamByName('MAILID').AsInteger := MailIndex;
    Query.ParamByName('JSONSTR').AsAnsiString := AnsiString(JSON.AsJSON);
    Query.ExecSQL;
  finally
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerShowMailPopUp(const PL: TClientPlayer);
var
  Query: TFDQuery;
  Con: TFDConnection;
  Reply: TClientPacket;
begin
  Reply := TClientPacket.Create;
  CreateQuery(Query, Con, False);
  try
    Query.Open('EXEC [dbo].[ProcGetMail] @UID = :UID, @PAGE = 1, @TOTAL = 5, @READ = 1', [PL.GetUID]);

    QueryNextSet(Query);

    Reply.WriteStr(#$10#$02#$00#$00#$00#$00);
    Reply.WriteInt32(Query.RecordCount);

    while not Query.Eof do
    begin
      Reply.WriteUInt32(Query.FieldByName('Mail_Index').AsInteger);
      Reply.WriteStr(Query.FieldByName('Sender').AsAnsiString, 10);
      Reply.WriteStr(#$00, $7B);
      Reply.WriteUInt32(Query.FieldByName('Mail_Item_Count').AsInteger); // TOTAL ITEM
      Reply.WriteStr(#$FF#$FF#$FF#$FF);
      Reply.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
      Reply.WriteStr(#$00);
      Reply.WriteUInt32(Query.FieldByName('QTY').AsInteger);
      Reply.WriteStr(#$00, $14);
      Reply.WriteStr(#$FF#$FF#$FF#$FF);
      //#$00#$00#$00#$00#$30#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00);
      Reply.WriteUInt32(0);
      Reply.WriteStr(ISUCCNULL(Query.FieldByName('UCC_UNIQUE').AsAnsiString, #$30), 8); // UCC UNIQUE
      Reply.WriteStr(#$00, 6);

      Query.Next;
    end;

    PL.Send(Reply);

  finally
    FreeQuery(Query, Con);
    FreeAndNil(Reply);
  end;
end;

end.
