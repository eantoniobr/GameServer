unit QuestCore;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  ClientPacket, PangyaClient, System.Generics.Collections,
  Enum, Tools, Defines, System.SysUtils, XSuperObject;

procedure PlayerLoadQuest(const PL: TClienTPlayer);
procedure PlayerAcceptQuest(const PL: TClienTPlayer; const ClientPacket: TClientPacket);
procedure SendQuestAccept(const PL: TClienTPlayer; const QuestUpdate: TList<UInt32>);

implementation

procedure PlayerLoadQuest(const PL: TClienTPlayer);
var
  Packet: TClientPacket;
  Query: TFDQuery;
  Con: TFDConnection;
  Tran: TTransacItem;
begin
  CreateQuery(Query, Con, False);
  Packet := TClientPacket.Create;
  try
    Query.Open('EXEC [DBO].USP_DAILYQUEST_LOAD @UID = :UID', [PL.GetUID]);

    while not Query.Eof do
    begin
      Tran := TTransacItem.Create;
      with Tran do
      begin
        Types := $02;
        TypeID := Query.FieldByName('TypeID').AsInteger;
        Index := Query.FieldByName('QuestIndex').AsInteger;
        PreviousQuan := 0;
        NewQuan := Query.FieldByName('Quantity').AsInteger;
        UCC := Nulled;
      end;
      PL.Inventory.Transaction.Add(Tran);

      Query.Next;
    end;

    PL.SendTransaction;

    QueryNextSet(Query);

    Packet.WriteStr(#$25#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(Query.FieldByName('QuestRegDate').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('ActivityDate').AsInteger);
    Packet.WriteUInt32(3);
    Packet.WriteUInt32(Query.FieldByName('Quest1').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('Quest2').AsInteger);
    Packet.WriteUInt32(Query.FieldByName('Quest3').AsInteger);

    QueryNextSet(Query);
    Packet.WriteUInt32(Query.RecordCount);

    while not Query.Eof do
    begin
      Packet.WriteUInt32(Query.FieldByName('QuestIndex').AsInteger);
    end;

    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
    FreeQuery(Query, Con);
  end;
end;

procedure PlayerAcceptQuest(const PL: TClienTPlayer; const ClientPacket: TClientPacket);
var
  Count, QuestTotal: UInt32;
  QuestIndex: UInt32;
  JSON, NestJS: ISuperObject;
  Query: TFDQuery;
  Con: TFDConnection;
  Tran: TTransacItem;
  QuestUpdate: TList<UInt32>;
begin
  if not ClientPacket.ReadUInt32(QuestTotal) then Exit;

  {INITIALIZATION JSON}
  JSON := SO;

  for Count := 1 to QuestTotal do
  begin
    if not ClientPacket.ReadUInt32(QuestIndex) then Exit;
    NestJS := SO;
    NestJS.I['QuestID'] := QuestIndex;
    JSON.A['QuestIDs'].Add(NestJS);
  end;

  CreateQuery(Query, Con, False);
  QuestUpdate := TList<UInt32>.Create;
  try
    Query.Open('EXEC [DBO].USP_DAILYQUEST_ACCEPT @UID = :UID, @QUESTSTR = :STR', [PL.GetUID, JSON.AsJSON()]);

    while not Query.Eof do
    begin
      Tran := TTransacItem.Create;
      with Tran do
      begin
        Types := $02;
        TypeID := Query.FieldByName('TypeID').AsInteger;
        Index := Query.FieldByName('ID').AsInteger;
        PreviousQuan := 0;
        NewQuan := 0;
        UCC := Nulled;
      end;
      PL.Inventory.Transaction.Add(Tran);

      Query.Next;
    end;
    PL.SendTransaction;

    { RELOAD QUEST }
    PL.ReloadAchievement;

    QueryNextSet(Query);

    while not Query.Eof do
    begin
      QuestUpdate.Add(Query.FieldByName('QuestID').AsInteger);
      Query.Next;
    end;

    SendQuestAccept(PL, QuestUpdate);
  finally
    FreeQuery(Query, Con);
    QuestUpdate.Clear;
    FreeAndNil(QuestUpdate);
  end;
end;

procedure SendQuestAccept(const PL: TClienTPlayer; const QuestUpdate: TList<UInt32>);
var
  Packet, Packet2: TClientPacket;
  Achievement: PAchievement;
  Quest: PAchievementQuest;
  Counter: PAchievementCounter;
  QuestID: UInt32;
  Count: UInt32;
begin
  Packet := TClientPacket.Create;
  Packet2 := TClientPacket.Create;
  try
    Packet.WriteStr(#$26#$02);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(QuestUpdate.Count);

    for QuestID in QuestUpdate do
    begin
      for Achievement in PL.Achievements do
      begin
        if Achievement.ID = QuestID then
        begin
          Packet.WriteUInt8(1);
          Packet.WriteUInt32(Achievement.TypeID);
          Packet.WriteUInt32(Achievement.ID);
          Packet.WriteUInt32(Achievement.AchievementType);

          Count := 0;
          Packet2.Clear;
          for Quest in PL.AchievementQuests do
          begin
            if Quest.AchievementIndex = Achievement.ID then
            begin
              Inc(Count, 1);

              PL.AchievemetCounters.TryGetValue(Quest.CounterIndex, Counter);

              Packet2.WriteUInt32(Quest.AchievementTypeID);
              Packet2.WriteUInt32(Counter.TypeID);
              Packet2.WriteUInt32(Counter.ID);
              Packet2.WriteUInt32(Counter.Quantity);
            end;
          end;
          Packet.WriteUInt32(Count);
          Packet.WriteStr(Packet2.ToStr);
        end;
      end;
    end;

    PL.Send(Packet);
  finally
    FreeAndNil(Packet);
    FreeAndNil(Packet2);
  end;
end;

end.
