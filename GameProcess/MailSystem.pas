unit MailSystem;

interface

uses
  // ## FOR SQL
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  // ## END SQL
  FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  System.SysUtils ,System.Generics.Collections, PList, XSuperObject, IffMain, IffManager.SetItem, 
  IffManager.LevelUpPrizeItem, Tools, ServerStr, Math;

type
  PMailItem = ^TMailItem;

  TMailItem = packed record
    var TypeID: UInt32;
    var SetID: UInt32;
    var Quantity: UInt32;
    var Day: UInt16;
  end;

  TMailSender = class
    private
      var FMailItemLists: TPointerList;
      var FSender: String;
      var FMessage: TStringBuilder;
      procedure AddMessage(const Text: AnsiString);
    public
      constructor Create;
      destructor Destroy; override;
      function GetJSONString: AnsiString;
      procedure AddItem(ItemData: TMailItem; WithName: Boolean = False); overload;
      procedure AddItem(rTypeID, rQuantity: UInt32; WithName: Boolean = False); overload;
      procedure AddSetItem(SetTypeID: UInt32; WithName: Boolean = False);
      procedure AddText(const Text: AnsiString);
      procedure AddItemLevel(Level: UInt8);
      procedure Send(UID: UInt32);
      property Sender: String read FSender write FSender;
  end;

implementation

{ TMailSender }

procedure TMailSender.AddItem(ItemData: TMailItem; WithName: Boolean = False);
var
  PItemData: PMailItem;
begin
  New(PItemData);
  PItemData.TypeID := ItemData.TypeID;
  PItemData.SetID := ItemData.SetID;
  PItemData.Quantity := ItemData.Quantity;
  PItemData.Day := ItemData.Day;

  FMailItemLists.Add(PItemData);

  if WithName then
  begin
    FMessage.Append(AnsiFormat(ReadString.GetText('MailSendItem'),[IffEntry.GetItemName(ItemData.TypeID), ItemData.Quantity]) );
  end;
end;

procedure TMailSender.AddItem(rTypeID, rQuantity: UInt32; WithName: Boolean = False);
var
  MailItem: TMailItem;
begin
  if GetItemGroup(rTypeID) = 9 then
  begin
    Self.AddSetItem(rTypeID, WithName);
    Exit;
  end;
  with MailItem do
  begin
    TypeID := rTypeID;
    SetID := 0;
    Quantity := rQuantity;
    Day := 0;
  end;
  Self.AddItem(MailItem, WithName);
end;

procedure TMailSender.AddItemLevel(Level: UInt8);
var
  Item: PIffPrize;
begin
  for Item in IffEntry.FLevelPrize.ReadLevelPrize do
  begin
    if Item.Level = Level then
    begin
      Self.AddItem(Item.TypeID, Item.Quantity);
    end;
  end;
end;

procedure TMailSender.AddMessage(const Text: AnsiString);
begin
  FMessage.Append(Text);
end;

procedure TMailSender.AddSetItem(SetTypeID: UInt32; WithName: Boolean = False);
var
  SetITem: PIffSetItem;
  Index: UInt32;
  MailItem: TMailItem;
begin
  if not (GetItemGroup(SetTypeID) = 9) then Exit;
  
  if not IffEntry.FSets.FItemSet.TryGetValue(SetTypeID, SetITem) then Exit;

  if (SetITem.Base.Enabled = 1) then
  begin
    for Index := 0 to 9 do
    begin
      if not(SetITem.TypeIff[Index] > 0) then
      begin
        Break;
      end;
      with MailItem do
      begin
        TypeID := SetITem.TypeIff[Index];
        SetID := SetTypeID;
        Quantity := SetITem.QtyIff[Index];
        Day := 0;
      end;
      AddItem(MailItem);
      if WithName then
      begin
        Self.AddMessage(AnsiFormat(ReadString.GetText('MailSendItem'), [IffEntry.GetItemName(SetITem.TypeIff[Index]), SetITem.QtyIff[Index]]) );
      end;
    end;
  end;
end;

procedure TMailSender.AddText(const Text: AnsiString);
begin
  Self.FMessage.Append(Text);
end;

constructor TMailSender.Create;
begin
  FMailItemLists := TPointerList.Create;
  FMessage := TStringBuilder.Create;
end;

destructor TMailSender.Destroy;
begin
  FreeAndNil(FMailItemLists);
  FreeAndNil(FMessage);
  inherited;
end;

function TMailSender.GetJSONString: AnsiString;
var
  FJSON, Nested: ISuperObject;
  MailItem: Pointer;
begin
  FJSON := SO;
  FJSON.S['Sender']   := Self.FSender;
  FJSON.S['Messages'] := Self.FMessage.ToString;
  for MailItem in FMailItemLists do
  begin
    Nested := SO;
    Nested.I['TypeID']    := PMailItem(MailItem).TypeID;
    Nested.I['SetTypeID'] := PMailItem(MailItem).SetID;
    Nested.I['Quantity']  := PMailItem(MailItem).Quantity;
    Nested.I['Day']       := PMailItem(MailItem).Day;
    Nested.I['ItemGroup'] := GetItemGroup(PMailItem(MailItem).TypeID);
    FJSON.A['Items'].Add(Nested);
  end;
  Exit(AnsiString(FJSON.AsJSON()));
end;

procedure TMailSender.Send(UID: UInt32);
var
  FJSON, Nested: ISuperObject;
  MailItem: Pointer;
  Con: TFDConnection;
  Query: TFDQuery;
begin
  FJSON := SO;
  FJSON.S['Sender']   := Self.FSender;
  FJSON.S['Messages'] := Self.FMessage.ToString;
  for MailItem in FMailItemLists do
  begin
    Nested := SO;
    Nested.I['TypeID']    := PMailItem(MailItem).TypeID;
    Nested.I['SetTypeID'] := PMailItem(MailItem).SetID;
    Nested.I['Quantity']  := PMailItem(MailItem).Quantity;
    Nested.I['Day']       := PMailItem(MailItem).Day;
    Nested.I['ItemGroup'] := GetItemGroup(PMailItem(MailItem).TypeID);
    FJSON.A['Items'].Add(Nested);
  end;

  Query := TFDQuery.Create(nil);
  Con := TFDConnection.Create(nil);
  try
    {********** CON & STORE PROC CREATION ************}
    Con.ConnectionDefName := 'MSSQLPool';
    Query.Connection := Con;
    {******************* END *************************}

    Query.SQL.Text := 'EXEC [dbo].[ProcMailInsert] @UID = :UID, @JSONData = :JDATA';
    Query.ParamByName('UID').AsInteger := UID;
    Query.ParamByName('JDATA').AsAnsiString := AnsiString(FJSON.AsJSON());
    Query.ExecSQL;
  finally
    FreeAndNil(Query);
    FreeAndNil(Con);
  end;

end;

end.
