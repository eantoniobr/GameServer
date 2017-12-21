unit SelfDesignCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  ClientPacket, PangyaClient, uWarehouse, Tools, System.SysUtils;

type
  TSaveUCC = packed record
    var fUID: UInt32;
    var fUCCIndex: UInt32;
    var fUCCName: AnsiString;
    var fUCCStatus: UInt8;
    var fUccDrawerUID: UInt32;
  end;

procedure PlayerRequestUploadKey(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure PlayerAfterUploaded(const PL: TClientPlayer; const ClientPacket: TClientPacket);
procedure SaveUCC(const PL: TClientPlayer; const Data: TSaveUCC);

implementation

procedure PlayerRequestUploadKey(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Option: UInt8;
  ITEMID: UInt32;
  Packet: TClientPacket;
  ItemUCC: PItem;
  Query: TFDQuery;
  Con: TFDConnection;
begin
  if not ClientPacket.ReadUInt8(Option) then Exit;
  case Option of
    0:
      begin
        ClientPacket.Skip(5); // Skip for ununsed data

        if not ClientPacket.ReadUInt32(ITEMID) then Exit;

        ItemUCC := PL.Inventory.GetUCC(ITEMID);

        if (ItemUCC = nil) then Exit;

        CreateQuery(Query, Con);
        Packet := TClientPacket.Create;
        try
          Query.Open('EXEC [dbo].[USP_UCC_REQUEST_UPLOAD] @UID = :UID, @ITEMID = :ITEMID', [PL.GetUID, ITEMID]);

          if not(Query.FieldByName('CODE').AsInteger = 1) then
          begin
            Exit;
          end;

          Packet.WriteStr(#$53#$01);
          Packet.WriteUInt8(Option); // Maybe Option
          Packet.WriteUInt8(1); // Unknown now
          Packet.WriteUInt32(ITEMID);
          Packet.WritePStr(Query.FieldByName('UCCKEY').AsAnsiString);
          Packet.WriteStr(#$01); // Unknown
          PL.Send(Packet);

        finally
          FreeQuery(Query, Con);
          FreeAndNil(Packet);
        end;
      end;
  end;
end;

procedure PlayerAfterUploaded(const PL: TClientPlayer; const ClientPacket: TClientPacket);
var
  Option, Cases: UInt8;
  TypeId, UCC_IDX: UInt32;
  UCC_UNIQUE, UCC_NAME: AnsiString;
  Packet: TClientPacket;
  Item: PItem;
  UCC_SAVE: TSaveUCC;
  Query: TFDQuery;
  Con: TFDConnection;
begin
  Packet := TClientPacket.Create;
  try
    if not ClientPacket.ReadUInt8(Option) then Exit;
    case Option of
      0: // Save Permanently
        begin
          if not ClientPacket.ReadUInt32(TypeId) then Exit;
          if not ClientPacket.ReadPStr(UCC_UNIQUE) then Exit;
          if not ClientPacket.ReadPStr(UCC_NAME) then Exit;

          Item := PL.Inventory.GetUCC(TypeId, UCC_UNIQUE);

          if (Item = nil) then
          begin
            Exit;
          end;

          if not (Item = nil) then
          begin
            Item.ItemUCCStatus := 1;
            Item.ItemUCCName := UCC_NAME;
            Item.ItemUCCDrawerUID := PL.GetUID;
            Item.ItemNeedUpdate := False; // NO NEED TO UPDATE BECAUSE WE UPDATED IT ALREADY BELOW TO GET INFORMATION SOON

            UCC_SAVE.fUID := PL.GetUID;
            UCC_SAVE.fUCCIndex := Item.ItemIndex;
            UCC_SAVE.fUCCName := UCC_NAME;
            UCC_SAVE.fUCCStatus := Item.ItemUCCStatus;
            UCC_SAVE.fUccDrawerUID := PL.GetUID;
            // SAVE TO DATABASE
            SaveUCC(PL, UCC_SAVE);
          end;

          Packet.WriteStr(#$2E#$01#$00#$01);
          Packet.WriteUInt32(Item.ItemIndex);
          Packet.WriteUInt32(Item.ItemTypeID);
          Packet.WritePStr(Item.ItemUCCUnique);
          Packet.WritePStr(UCC_NAME);

          PL.Send(Packet);
        end;
      1: // UCC INFO
        begin
          if not ClientPacket.ReadUInt32(UCC_IDX) then Exit;
          if not ClientPacket.ReadUInt8(Cases) then Exit;

          if (UCC_IDX = 0) then
          begin
            PL.Send(#$2E#$01#$04);
            Exit;
          end;

          CreateQuery(Query, Con);
          try
            Query.Open('EXEC [dbo].[ProcGetUCCData] @UCC_INDEX = :UCCINDEX', [UCC_IDX]);

            if Query.RecordCount <= 0 then
            begin
              Exit;
            end;

            Packet.WriteStr(#$2E#$01#$01);
            Packet.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
            Packet.WritePStr(Query.FieldByName('UCC_UNIQE').AsAnsiString);
            Packet.WriteStr(#$01);
            Packet.WriteUInt32(Query.FieldByName('item_id').AsInteger);
            Packet.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
            Packet.WriteStr(#$00, $F);
            Packet.WriteStr(#$01);
            Packet.WriteStr(#$00, $10);
            Packet.WriteStr(#$02);
            Packet.WriteStr(Query.FieldByName('UCC_NAME').AsAnsiString, $10);
            Packet.WriteStr(#$00, $19);
            Packet.WriteStr(Query.FieldByName('UCC_UNIQE').AsAnsiString, $9);
            Packet.WriteUInt8(Query.FieldByName('UCC_STATUS').AsInteger);
            Packet.WriteUInt16(Query.FieldByName('UCC_COPY_COUNT').AsInteger);
            Packet.WriteStr(Query.FieldByName('Nickname').AsAnsiString, $10);
            Packet.WriteStr(#$00, $56);
            PL.Send(Packet);
          finally
            FreeQuery(Query, Con);
          end;
        end;
      2: // COPY UCC
        begin
          if not ClientPacket.ReadUInt32(TypeId) then Exit;
          if not ClientPacket.ReadPStr(UCC_UNIQUE) then Exit;
          ClientPacket.Skip(2);
          if not ClientPacket.ReadUInt32(UCC_IDX) then Exit; // IDX TO COPY

          Item := PL.Inventory.GetUCC(TypeId, UCC_UNIQUE, True);

          if Item = nil then
          begin
            Exit;
          end;

          CreateQuery(Query, Con);
          try
            Query.Open('EXEC [dbo].[ProcSaveUCCCopy] @UID=:UID,@UCC_UNIQUE=:UCCIDX,@UCC_IDX=:ITEMID', [PL.GetUID, UCC_UNIQUE, UCC_IDX]);

            if Query.FieldByName('Code').AsInteger = 0 then
            begin
              Exit;
            end;

            Packet.WriteStr(#$2E#$01 + #$02);
            Packet.WriteUInt32(TypeId);
            Packet.WritePStr(UCC_UNIQUE);
            Packet.WriteStr(#$01#$00); // UNKNOWN YET
            Packet.WriteUInt32(UCC_IDX);
            Packet.WriteUInt32(Query.FieldByName('ITEM_ID').AsInteger);
            Packet.WriteUInt32(Query.FieldByName('TYPEID').AsInteger);
            Packet.WritePStr(Query.FieldByName('UCC_UNIQE').AsAnsiString);
            Packet.WriteUInt16(Query.FieldByName('UCC_COPY_COUNT').AsInteger);
            Packet.WriteStr(#$01);
            PL.Send(Packet);
          finally
            FreeQuery(Query, Con);
          end;
        end;
      3: // SAVE TEMPARARILY
        begin
          if not ClientPacket.ReadUInt32(TypeId) then Exit;
          if not ClientPacket.ReadPStr(UCC_UNIQUE) then Exit;

          Packet.WriteStr(#$2E#$01);
          Packet.WriteUInt8(Option);
          Packet.WriteUInt32(TypeId);
          Packet.WritePStr(UCC_UNIQUE);

          Item := PL.Inventory.GetUCC(TypeId, UCC_UNIQUE);

          if Item = nil then
          begin
            Packet.WriteStr(#$00);
          end;

          if not (Item = nil) then
          begin
            Item.ItemUCCStatus := 2;
            Item.ItemNeedUpdate := True;
            Packet.WriteStr(#$01);
          end;

          PL.Send(Packet);
        end;
    end;
  finally
    FreeAndNil(Packet);
  end;
end;

procedure SaveUCC(const PL: TClientPlayer; const Data: TSaveUCC);
var
  Query: TFDQuery;
  Con: TFDConnection;
begin
  CreateQuery(Query, Con);
  try
    Query.ExecSQL
      ('EXEC [dbo].[ProcSaveUCC] @UID = :UID, @UCC_ITEMID = :ITEMID, @UCC_NAME = :UCCNAME, @UCC_STATUS = :UST, @UCC_DRAWER_UID = :DRAWUID',
      [Data.fUID, Data.fUCCIndex, Data.fUCCName, Data.fUCCStatus,
      Data.fUccDrawerUID]);
  finally
    FreeQuery(Query, Con);
  end;
end;


end.
