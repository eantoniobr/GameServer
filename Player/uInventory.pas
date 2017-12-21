unit uInventory;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  SysUtils, uCharacter,
  Utils, uItemSlot, uWarehouse, uMascot, uCaddie, uFurniture,
  Tools,
  Transactions, ClientPacket, ItemData, Math, System.SyncObjs, IffMain, Defines, uCard, Enum,
  XSuperObject, System.Generics.Collections;

type

  TPlayerInventory = class
    private
      var fPriority: TCriticalSection;
      var fPlayerUID: UInt32;
      var fItemSlot:  TItemsSlot;   { will soon update to sql }
      var fCharacterIndex: UInt32;  { will soon update to sql }
      var FCaddieIndex: UInt32;     { will soon update to sql }
      var FMascotIndex: UInt32;     { will soon update to sql }
      var FGolfEQP: TGolfData;      { will soon update to sql }
      var FPoster1: UInt32;         { will soon update to sql }
      var FPoster2: UInt32;         { will soon update to sql }

      var FPang: UInt32;
      var FCookie: UInt32;

      { player inventories }
      var FInvItem: TSerialWarehouse;
      var FInvCaddie: TSerialCaddies;
      var FInvChar: TSerialCharacter;
      var FInvMascot: TSerialMascots;
      var FInvCard: TSerialCard;
      var FInvRoom: TSerialFurniture;

      var FTranLists: TTransaction;
      function GetPartGroup(TypeID: UInt32): UInt32;
      function GetToolbarJSON: AnsiString;
    public
      function GetQuantity(TypeID: UInt32): UInt32;
      { club system }
      function SetClubIndex(Index: UInt32): Boolean;
      function GetClubData: AnsiString;
      function SetBallTypeID(TypeID: UInt32): Boolean;
      function SetGolfEQP(BallTypeID, ClubIndex: UInt32): Boolean;
      function GetGolfEQP: AnsiString;
      { character system }
      function GetCharData: AnsiString;
      function GetCharTypeID: UInt32;
      function SetCharIndex( CharacterIndex : UInt32 ): Boolean;
      function GetCharacter(TypeID: UInt32): PCharacter;
      { mascot system }
      function SetMascotIndex( Index : UInt32): Boolean;
      function GetMascotData : AnsiString;
      function GetMascotTypeID: UInt32;
      function SetMascotText(MascotIdx: UInt32; const MascotText: AnsiString): Boolean;
      { caddie system }
      function SetCaddieIndex( Index : UInt32): Boolean;
      function GetCaddieData : AnsiString;
      { save }
      procedure Save;
      { adding items }
      function AddRent(TypeID: UInt32; Quantity: UInt32 = 1; Day: UInt16 = 7): TAddData;
      function AddItem(ItemAddData: TAddItem): TAddData;
      function AddItemToDB(ItemAddData: TAddItem): TAddData;
      { remove items }
      function Remove(ItemIffId : UInt32; Quantity : UInt32; Transaction : Boolean = True): TAddData; overload;
      function Remove(ItemIffId, Index : UInt32; Quantity : UInt32; Transaction : Boolean = True): TAddData; overload;
      { transaction }
      function GetTransaction: AnsiString;
      function TranCount: UInt32;
      { item exists? }
      function IsExist(TypeId : UInt32): Boolean; overload;
      function IsExist(TypeID, Index: UInt32; Quantity: UInt32): Boolean; overload;
      function Available(TypeId,Quantity : UInt32): Boolean;
      { self design system }
      function GetUCC(ItemIdx: UInt32): PItem; overload;
      function GetUCC(TypeId: UInt32; const UCC_UNIQUE: AnsiString): PItem; overload;
      function GetUCC(TypeId: UInt32; const UCC_UNIQUE: AnsiString; Status : Boolean): PItem; overload;
      { poster }
      function SetPoster(const Poster1, Poster2: UInt32): Boolean;

      property ItemSlot : TItemsSlot read fItemSlot write fItemSlot;
      property ItemWarehouse : TSerialWarehouse read FInvItem write FInvItem;
      property ItemCaddie : TSerialCaddies read FInvCaddie write FInvCaddie;
      property ItemCharacter : TSerialCharacter read FInvChar write FInvChar;
      property ItemMascot: TSerialMascots read FInvMascot write FInvMascot;
      property ItemCard: TSerialCard read FInvCard write FInvCard;
      property ItemRoom: TSerialFurniture read FInvRoom write FInvRoom;
      property Transaction: TTransaction read FTranLists;
      property UID : UInt32 read fPlayerUID write fPlayerUID;

      property PlayerCookie: UInt32 read FCookie;
      property PlayerPang: UInt32 read FPang;

      constructor Create;
      destructor Destroy; override;
  end;

implementation

{ TPlayerEquip }

function TPlayerInventory.AddItem(ItemAddData: TAddItem): TAddData;
var
  TPItem: Pointer;
begin
  fPriority.Acquire;
  try
    if fPlayerUID = 0 then
    begin
      Exit;
    end;

    Result.Status := False;

    case TITEMGROUP(GetPartGroup(ItemAddData.ItemIffId)) of
      { character }
      ITEM_TYPE_CHARACTER:
        begin
          PCharacter(TPItem) := FInvChar.GetChar(ItemAddData.ItemIffId, bTypeID);
          if (TPItem = nil) then
          begin
            Exit(AddItemToDB(ItemAddData));
          end else if not (TPItem = nil) then
          begin
            with Result do
            begin
              Status := True;
              ItemIndex := PCharacter(TPItem).Index;
              ItemTypeID := PCharacter(TPItem).TypeID;
              ItemOldQty := 1;
              ItemNewQty := 1;
              ItemUCCKey := Nulled;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;

            if ItemAddData.Transaction then
              FTranLists.Add($2, PCharacter(TPItem));

          end;
        end;
      { part }
      ITEM_TYPE_PART:
        begin
          Exit(AddItemToDB(ItemAddData));
        end;
      { club set }
      ITEM_TYPE_CLUB:
        begin
          Exit(AddItemToDB(ItemAddData));
        end;
      { normal items, using items }
      ITEM_TYPE_BALL,
      ITEM_TYPE_USE:
        begin
          PItem(TPItem) := FInvItem.GetItem(ItemAddData.ItemIffId, 1);
          if not (TPItem = nil) then
          begin
            with Result do
            begin
              Status := True;
              ItemIndex := PItem(TPItem).ItemIndex;
              ItemTypeID := PItem(TPItem).ItemTypeID;
              ItemOldQty := PItem(TPItem).ItemC0;
              ItemNewQty := PItem(TPItem).ItemC0 + ItemAddData.Quantity;
              ItemUCCKey := PItem(TPItem).ItemUCCUnique;
              ItemFlag := PItem(TPItem).ItemFlag;
              ItemEndDate := 0;
            end;
            // ## add
            PItem(TPItem).AddQuantity(ItemAddData.Quantity);

            if ItemAddData.Transaction then
              FTranLists.Add($2, PItem(TPItem), ItemAddData.Quantity);
          end else if (TPItem = nil) then begin
            Exit(AddItemToDB(ItemAddData));
          end;
        end;
      { caddies }
      ITEM_TYPE_CADDIE:
        begin
          Exit(AddItemToDB(ItemAddData));
        end;
      { caddies items }
      ITEM_TYPE_CADDIE_ITEM:
        begin
          PCaddie(TPItem) := FInvCaddie.GetCaddieBySkinId(ItemAddData.ItemIffId);
          if not (TPItem = nil) then
          begin
            PCaddie(TPItem).UpdateCaddieSkin(ItemAddData.ItemIffId, ItemAddData.Day);
            with Result do
            begin
              Status := True;
              ItemIndex := PCaddie(TPItem).CaddieIdx;
              ItemTypeID := PCaddie(TPItem).CaddieSkin;
              ItemOldQty := 1;
              ItemNewQty := 1;
              ItemUCCKey := Nulled;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
          end;
        end;
      { skin }
      ITEM_TYPE_SKIN:
        begin
          Exit(AddItemToDB(ItemAddData));
        end;
      { mascot }
      ITEM_TYPE_MASCOT:
        begin
          PMascot(TPItem) := FInvMascot.GetMascotByTypeId(ItemAddData.ItemIffId);
          if not (TPItem = nil) then
          begin
            PMascot(TPItem).AddDay(ItemAddData.Day);
            with Result do
            begin
              Status := True;
              ItemIndex := PMascot(TPItem).MascotIndex;
              ItemTypeID := PMascot(TPItem).MascotTypeID;
              ItemOldQty := 1;
              ItemNewQty := 1;
              ItemUCCKey := '';
              ItemFlag := 0;
              ItemEndDate := PMascot(TPItem).MascotEndDate;
            end;
          end;
        end;
      { card }
      ITEM_TYPE_CARD:
        begin
          PCard(TPItem) := Self.FInvCard.GetCard(ItemAddData.ItemIffId, 1);
          if (TPItem = nil) then
          begin
            Exit(AddItemToDB(ItemAddData));
          end else if not (TPItem = nil) then
          begin
            with Result do
            begin
              Status := True;
              ItemIndex := PCard(TPItem).CardIndex;
              ItemTypeID := PCard(TPItem).CardTypeID;
              ItemOldQty := PCard(TPItem).CardQuantity;
              ItemNewQty := PCard(TPItem).CardQuantity + ItemAddData.Quantity;
              ItemUCCKey := Nulled;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;

            // ## add quantity
            PCard(TPItem).AddQuantity(ItemAddData.Quantity);

            if ItemAddData.Transaction then
              FTranLists.Add($2, PCard(TPItem), ItemAddData.Quantity);
          end;
        end;
    end;
    { exit with result }
    Exit(Result);
  finally
    fPriority.Release;
  end;
end;

function TPlayerInventory.AddRent(TypeID, Quantity: UInt32; Day: UInt16): TAddData;
var
  PRent: Pointer;
  Query: TFDQuery;
  Con: TFDConnection;
begin
  fPriority.Acquire;
  Query := TFDQuery.Create(nil);
  Con := TFDConnection.Create(nil);
  try
    Result.Status := False;

    if not (GetItemGroup(TypeID) = $2) then
    begin
      Exit(Result);
    end;

    Con.ConnectionDefName := 'MSSQLPool';
    Query.Connection := Con;

    Query.SQL.Add('EXEC [DBO].ProcAddRent');
    Query.SQL.Add('@UID = :UID,');
    Query.SQL.Add('@TYPEID = :TYPEID,');
    Query.SQL.Add('@DAY_IN = :DAYIN');

    Query.ParamByName('UID').AsInteger := Self.UID;
    Query.ParamByName('TYPEID').AsInteger := TypeID;
    Query.ParamByName('DAYIN').AsInteger := 7;
    Query.Open;

    if Query.RecordCount <= 0 then Exit(Result);

    New(PItem(PRent));
    PItem(PRent).ItemIndex := Query.FieldByName('ITEM_INDEX').AsInteger;
    PItem(PRent).ItemTypeID := Query.FieldByName('ITEM_TYPEID').AsInteger;
    PItem(PRent).ItemC0 := 0;
    PItem(PRent).ItemUCCUnique := Nulled;
    PItem(PRent).CreateNewItem;
    PItem(PRent).ItemFlag := Query.FieldByName('ITEM_FLAG').AsInteger;
    PItem(PRent).ItemEndDate := Query.FieldByName('ITEM_DATE_END').AsDateTime;
    FInvItem.Add(PItem(PRent));

    with Result do
    begin
      Status := True;
      ItemIndex := PItem(PRent).ItemIndex;
      ItemTypeID := PItem(PRent).ItemTypeID;
      ItemOldQty := 0;
      ItemNewQty := 1;
      ItemUCCKey := PItem(PRent).ItemUCCUnique;
      ItemFlag := PItem(PRent).ItemFlag;
      ItemEndDate := PItem(PRent).ItemEndDate;
    end;

    Exit(Result);
  finally
    FreeAndNil(Query);
    FreeAndNil(Con);
    fPriority.Release;
  end;
end;

function TPlayerInventory.AddItemToDB(ItemAddData: TAddItem): TAddData;
var
  Query: TFDQuery;
  Con: TFDConnection;
  TPItem: Pointer;
  Tran: TTransacItem;
begin
  Query := TFDQuery.Create(nil);
  Con := TFDConnection.Create(nil);
  try
    with ItemAddData do
    begin
      WriteLn(ItemIffId);
      WriteLn(Quantity);
      WriteLn(Transaction);
      WriteLn(Day);
    end;

    Result.Status := False;

    {********** CON & STORE PROC CREATION ************}
    Con.ConnectionDefName := 'MSSQLPool';
    Query.Connection := Con;
    Query.Open
      ('EXEC [dbo].[ProcAddItem] @UID = :UID, @IFFTYPEID = :TYPEID, @QUANTITY = :QUAN, @ISUCC = :ISUCC, @ITEM_TYPE = :ITYPE, @DAY = :ADAY',
      [fPlayerUID, ItemAddData.ItemIffId, ItemAddData.Quantity,
      TGeneric.Iff<UInt8>(IffEntry.IsSelfDesign(ItemAddData.ItemIffId), 1, 0),
      IffEntry.GetItemTimeFlag(ItemAddData.ItemIffId), ItemAddData.Day]);
    {******************* END *************************}

    if Query.RecordCount > 0 then
    begin
      if ItemAddData.Transaction then
      begin
        // ## add to tran
        Tran := TTransacItem.Create;
        with Tran do
        begin
          Types := $2;
          TypeID := Query.FieldByName('iffTypeId').AsInteger;
          Index := Query.FieldByName('IDX').AsInteger;
          PreviousQuan := 0;
          NewQuan := ItemAddData.Quantity;
          UCC := Query.FieldByName('UCC_KEY').AsAnsiString;
        end;
        FTranLists.Add(Tran);
      end;

      case TITEMGROUP(GetPartGroup(ItemAddData.ItemIffId)) of
        // ## type char
        ITEM_TYPE_CHARACTER:
          begin
            New(PCharacter(TPItem));
            PCharacter(TPItem).Index := Query.FieldByName('IDX').AsInteger;
            PCharacter(TPItem).TypeID := Query.FieldByName('iffTypeId').AsInteger;
            PCharacter(TPItem).HairColour := 0;
            PCharacter(TPItem).GiftFlag := 0;
            FInvChar.Add(PCharacter(TPItem));
            with Result do
            begin
              Status := True;
              ItemIndex := PCharacter(TPItem).Index;
              ItemTypeID := PCharacter(TPItem).TypeID;
              ItemOldQty := 0;
              ItemNewQty := 1;
              ItemUCCKey := Nulled;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
          end;
        // ## type part, ball, using
        ITEM_TYPE_PART,
        ITEM_TYPE_BALL,
        ITEM_TYPE_USE,
        ITEM_TYPE_CLUB:
          begin
            New(PItem(TPItem));
            PItem(TPItem).ItemIndex := Query.FieldByName('IDX').AsInteger;
            PItem(TPItem).ItemTypeID := Query.FieldByName('iffTypeId').AsInteger;
            PItem(TPItem).ItemC0 := ItemAddData.Quantity;
            PItem(TPItem).ItemUCCUnique := Query.FieldByName('UCC_KEY').AsAnsiString;
            PItem(TPItem).CreateNewItem;
            // Add to inventory list
            FInvItem.Add(PItem(TPItem));
            // Set the result data
            with Result do
            begin
              Status := True;
              ItemIndex := PItem(TPItem).ItemIndex;
              ItemTypeID := PItem(TPItem).ItemTypeID;
              ItemOldQty := 0;
              ItemNewQty := ItemAddData.Quantity;
              ItemUCCKey := PItem(TPItem).ItemUCCUnique;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
          end;
        // ## type caddie
        ITEM_TYPE_CADDIE:
          begin
            New(PCaddie(TPItem));
            PCaddie(TPItem).CaddieIdx := Query.FieldByName('IDX').AsInteger;
            PCaddie(TPItem).CaddieTypeId := Query.FieldByName('iffTypeId').AsInteger;
            PCaddie(TPItem).CaddieType := Query.FieldByName('Flag').AsInteger;
            PCaddie(TPItem).CaddieDateEnd := Query.FieldByName('END_DATE').AsDateTime;
            PCaddie(TPItem).CaddieAutoPay := 0;
            // Add caddie to inventory list
            FInvCaddie.Add(PCaddie(TPItem));
            // set the result data
            with Result do
            begin
              Status := True;
              ItemIndex := PCaddie(TPItem).CaddieIdx;
              ItemTypeID := PCaddie(TPItem).CaddieTypeId;
              ItemOldQty := 0;
              ItemNewQty := 1;
              ItemUCCKey := Nulled;
              ItemFlag := PCaddie(TPItem).CaddieType;
              ItemEndDate := PCaddie(TPItem).CaddieDateEnd;
            end;
          end;
        // ## type skin
        ITEM_TYPE_SKIN:
          begin
            New(PItem(TPItem));
            PItem(TPItem).ItemIndex := Query.FieldByName('IDX').AsInteger;
            PItem(TPItem).ItemTypeID := Query.FieldByName('iffTypeId').AsInteger;
            PItem(TPItem).ItemC0 := ItemAddData.Quantity;
            PItem(TPItem).ItemUCCUnique := Query.FieldByName('UCC_KEY').AsAnsiString;
            PItem(TPItem).ItemFlag := Query.FieldByName('Flag').AsInteger;
            PItem(TPItem).ItemEndDate := Query.FieldByName('END_DATE').AsDateTime;
            PItem(TPItem).ItemIsValid := 1;
            // Add to item inventory
            FInvItem.Add(PItem(TPItem));
            // set the result data
            with Result do
            begin
              Status := True;
              ItemIndex := PItem(TPItem).ItemIndex;
              ItemTypeID := PItem(TPItem).ItemTypeID;
              ItemOldQty := 0;
              ItemNewQty := ItemAddData.Quantity;
              ItemUCCKey := PItem(TPItem).ItemUCCUnique;
              ItemFlag := PItem(TPItem).ItemFlag;
              ItemEndDate := PItem(TPItem).ItemEndDate;
            end;
          end;
        // ## type card
        ITEM_TYPE_CARD:
          begin
            New(PCard(TPItem));
            PCard(TPItem).CardIndex := Query.FieldByName('IDX').AsInteger;
            PCard(TPItem).CardTypeID := Query.FieldByName('iffTypeId').AsInteger;
            PCard(TPItem).CardQuantity := ItemAddData.Quantity;
            PCard(TPItem).CardIsValid := 1;
            PCard(TPItem).CardNeedUpdate := False;
            // ## add to card
            Self.FInvCard.Add(PCard(TPItem));
            with Result do
            begin
              Status := True;
              ItemIndex := PCard(TPItem).CardIndex;
              ItemTypeID := PCard(TPItem).CardTypeID;
              ItemOldQty := 0;
              ItemNewQty := PCard(TPItem).CardQuantity;
              ItemUCCKey := Nulled;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
          end;
      end;
      // ## resulted
      Exit(Result);
    end;
  finally
    FreeAndNil(Query);
    FreeAndNil(Con);
  end;
end;

function TPlayerInventory.GetCharData: AnsiString;
var
  CharInfo : PCharacter;
begin
  Exit(Self.FInvChar.GetCharData(FCharacterIndex));
end;

function TPlayerInventory.GetCharTypeID: UInt32;
var
  CharInfo : PCharacter;
begin
  CharInfo := FInvChar.GetChar(FCharacterIndex, bIndex);
  if not (CharInfo = nil) then
  begin
    Exit(CharInfo.TypeID);
  end;
  Exit(0);
end;

function TPlayerInventory.GetMascotData: AnsiString;
var
  MascotInfo: PMascot;
begin
  MascotInfo := FInvMascot.GetMascotByIndex(FMascotIndex);
  if not (MascotInfo = nil) then
  begin
    Exit(MascotInfo.GetMascotInfo);
  end;
  Exit(GetZero($3E));
end;

function TPlayerInventory.GetMascotTypeID: UInt32;
var
  MascotInfo: PMascot;
begin
  MascotInfo := FInvMascot.GetMascotByIndex(FMascotIndex);
  if not (MascotInfo = nil) then
  begin
    Exit(MascotInfo.MascotTypeID);
  end;
  Exit(0);
end;

function TPlayerInventory.GetUCC(ItemIdx: UInt32): PItem;
var
  ItemUCC: PItem;
begin
  for ItemUCC in FInvItem do
  begin
    if (ItemUCC.ItemIndex = ItemIdx) and (Length(ItemUCC.ItemUCCUnique) >= 8) then
    begin
      Exit(ItemUCC);
    end;
  end;
  Exit(nil);
end;

// THIS IS USE FOR UCC THAT ALREADY PAINTED
function TPlayerInventory.GetUCC(TypeId: UInt32; const UCC_UNIQUE: AnsiString; Status: Boolean): PItem;
var
  ItemUCC: PItem;
begin
  for ItemUCC in FInvItem do
  begin
    if (ItemUCC.ItemTypeID = TypeId) and (ItemUCC.ItemUCCUnique = UCC_UNIQUE) and (ItemUCC.ItemUCCStatus = 1) then
    begin
      Exit(ItemUCC);
    end;
  end;
  Exit(nil);
end;

// THIS IS USE FOR UCC THAT ALREADY {NOT} PAINTED
function TPlayerInventory.GetUCC(TypeID: UInt32; const UCC_UNIQUE: AnsiString): PItem;
var
  ItemUCC: PItem;
begin
  for ItemUCC in FInvItem do
  begin
    if (ItemUCC.ItemTypeID = TypeID) and (ItemUCC.ItemUCCUnique = UCC_UNIQUE) and not (ItemUCC.ItemUCCStatus = 1) then
    begin
      Exit(ItemUCC);
    end;
  end;
  Exit(nil);
end;

function TPlayerInventory.GetQuantity(TypeId: UInt32): UInt32;
begin
  fPriority.Acquire;
  try
    case GetPartGroup(TypeId) of
      5, 6: // Ball And Normal
        begin
          Exit(FInvItem.GetQuantity(TypeId));
        end;
    else
      Exit(0);
    end;
  finally
    fPriority.Release;
  end;
end;

function TPlayerInventory.GetCharacter(TypeID: UInt32): PCharacter;
var
  Character: PCharacter;
begin
  Character := FInvChar.GetChar(TypeID, bTypeID);
  if not (Character = nil) then
  begin
    Exit(Character);
  end;
  Exit(nil);
end;

function TPlayerInventory.GetClubData: AnsiString;
var
  ClubInfo: PItem;
begin
  ClubInfo := FInvItem.GetItem(Self.FGolfEQP.ClubIndex);
  if (ClubInfo = nil) then
  begin
    Exit;
  end;
  Exit(ClubInfo.GetClubInfo);
end;

function TPlayerInventory.GetCaddieData: AnsiString;
var
  CaddieInfo : PCaddie;
begin
  CaddieInfo := FInvCaddie.GetCaddieByIndex(FCaddieIndex);
  if not (CaddieInfo = nil) then
  begin
    Exit(CaddieInfo.GetCaddieInfo);
  end;
  Exit(GetZero($19));
end;

function TPlayerInventory.GetToolbarJSON: AnsiString;
var
  JSON: ISuperObject;
begin
  JSON := SO;
  JSON.I['UID'] := fPlayerUID;
  JSON.I['CharIndex'] := FCharacterIndex;
  JSON.I['CaddieIndex'] := FCaddieIndex;
  JSON.I['MascotIndex'] := FMascotIndex;
  JSON.I['BallTypeID'] := Self.FGolfEQP.BallTypeID;
  JSON.I['ClubIndex'] := Self.FGolfEQP.ClubIndex;
  JSON.I['SLOT1'] := fItemSlot.Slot1;
  JSON.I['SLOT2'] := fItemSlot.Slot2;
  JSON.I['SLOT3'] := fItemSlot.Slot3;
  JSON.I['SLOT4'] := fItemSlot.Slot4;
  JSON.I['SLOT5'] := fItemSlot.Slot5;
  JSON.I['SLOT6'] := fItemSlot.Slot6;
  JSON.I['SLOT7'] := fItemSlot.Slot7;
  JSON.I['SLOT8'] := fItemSlot.Slot8;
  JSON.I['SLOT9'] := fItemSlot.Slot9;
  JSON.I['SLOT10'] := fItemSlot.Slot10;
  Exit(JSON.AsJSON());
end;

procedure TPlayerInventory.Save;
var
  Query : TFDQuery;
  Con: TFDConnection;
begin
  if fPlayerUID <= 0 then Exit;

  Query := TFDQuery.Create(nil);
  Con := TFDConnection.Create(nil);
  try
    {********** CON & STORE PROC CREATION ************}
    Con.ConnectionDefName := 'MSSQLPool';
    Query.Connection := Con;

    Query.SQL.Text := 'EXEC [dbo].[ProcSaveToolbar] @UID = :UID, @JSONData = :JDATA';
    Query.ParamByName('UID').AsInteger := Self.fPlayerUID;
    Query.ParamByName('JDATA').AsAnsiString := Self.GetToolbarJSON;
    Query.ExecSQL;
    {******************* END *************************}

    // # PLAYER ITEM UPDATE
    Query.SQL.Text := 'EXEC [dbo].[ProcSaveItem] @UID = :UID, @JSONData = :JSONDATA';
    Query.ParamByName('UID').AsInteger := fPlayerUID;
    Query.ParamByName('JSONDATA').AsAnsiString := FInvItem.GetSQLUpdateJSON;
    Query.ExecSQL;

    // # PLAYER CADDIE
    Query.SQL.Text :=  'EXEC [dbo].[ProcSaveCaddies] @UID = :UID, @JSONData = :JSONDATA';
    Query.ParamByName('UID').AsInteger := fPlayerUID;
    Query.ParamByName('JSONDATA').AsAnsiString := FInvCaddie.GetSQLUpdateJSON;
    Query.ExecSQL;

    // # PLAYER EQUIP UPDATE
    Query.SQL.Text := 'EXEC [dbo].[ProcSaveCharacter] @UID = :UID, @JSONData = :JSONDATA';
    Query.ParamByName('UID').AsInteger := fPlayerUID;
    Query.ParamByName('JSONDATA').AsAnsiString:= FInvChar.GetSQLUpdateJSON;
    Query.ExecSQL;

    // # PLAYER CARD UPDATE
    Query.SQL.Text := 'EXEC [dbo].[ProcSaveCard] @UID = :UID, @JSONData = :JSONDATA';
    Query.ParamByName('UID').AsInteger := fPlayerUID;
    Query.ParamByName('JSONDATA').AsAnsiString:= Self.FInvCard.GetSQLUpdateJSON;
    Query.ExecSQL;

    // # PLAYER CARD EQUIP
    Query.SQL.Text :=  'EXEC [dbo].[ProcSaveCardEquip] @UID = :UID, @JSData = :JSONDATA';
    Query.ParamByName('UID').AsInteger := fPlayerUID;
    Query.ParamByName('JSONDATA').AsAnsiString := Self.FInvChar.sCard.Save;
    Query.ExecSQL;

  finally
    FreeAndNil(Query);
    FreeAndNil(Con);
  end;
end;

function TPlayerInventory.GetTransaction: AnsiString;
var
  Transac: TClientPacket;
begin
  fPriority.Acquire;
  try
    Transac := FTranLists.GetTran;
    try
      Exit(Transac.ToStr);
    finally
      FreeAndNil(Transac);
    end;
  finally
    fPriority.Release;
  end;
end;

function TPlayerInventory.GetPartGroup(TypeID: UInt32): UInt32;
begin
  Result := Round( (TypeID AND 4227858432) / Power(2,26) );
end;

function TPlayerInventory.IsExist(TypeID, Index, Quantity: UInt32): Boolean;
begin
  case GetPartGroup(TypeId) of
    5, 6: // ## normal and ball
      begin
        Exit(Self.FInvItem.IsNormalExist(TypeID, Index, Quantity));
      end;
    2: // ## part
      begin
        Exit(Self.FInvItem.IsPartExist(TypeID, Index, Quantity));
      end;
    $1F: // ## card
      begin
        Exit(Self.FInvCard.IsExist(TypeID, Index, Quantity));
      end;
  end;
  Exit(False);
end;

function TPlayerInventory.IsExist(TypeId: UInt32): Boolean;
var
  ListSet: TList<TPair<UInt32, UInt32>>;
  Enum: TPair<UInt32, UInt32>;
begin
  case GetPartGroup(TypeId) of
    2:
      begin
        Exit(FInvItem.IsPartExist(TypeID));
      end;
    5, 6:
      begin
        Exit(FInvItem.IsNormalExist(TypeId));
      end;
    9:
      begin
        ListSet := IffEntry.FSets.SetList(TypeID);
        try
          if ListSet.Count <= 0 then
            Exit(False);
          for Enum in ListSet do
            if Self.IsExist(Enum.Key) then
              Exit(True);
          Exit(False);
        finally
          FreeAndNil(ListSet);
        end;
      end;
    14:
      begin
        Exit(FInvItem.IsSkinExist(TypeId));
      end;
  end;
  Exit(False);
end;

function TPlayerInventory.Available(TypeId,Quantity: UInt32): Boolean;
var
  ListSet: TList<TPair<UInt32, UInt32>>;
  Enum: TPair<UInt32, UInt32>;
begin
  case TITEMGROUP(GetPartGroup(TypeId)) of
    ITEM_TYPE_SETITEM:
      begin
        ListSet := IffEntry.FSets.SetList(TypeID);
        try
          if ListSet.Count <= 0 then
            Exit(False);
          for Enum in ListSet do
            if Self.Available(Enum.Key {TypeID}, Enum.Value {Qunaity}) then
              Exit(True);
          Exit(False);
        finally
          FreeAndNil(ListSet);
        end;
      end;
    ITEM_TYPE_CHARACTER:
      begin
        Exit(True);
      end;
    ITEM_TYPE_PART: // Part Item
      begin
        Exit(True);
      end;
    ITEM_TYPE_CLUB:
      begin
        if Self.FInvItem.IsClubExist(TypeId) then
          Exit(False)
        else
          Exit(True);
      end;
    ITEM_TYPE_BALL,
    ITEM_TYPE_USE: // Normal Item
      begin
        if GetQuantity(TypeId) + Quantity > 32767 then
        begin
          Exit(False);
        end;
        Exit(True);
      end;
    ITEM_TYPE_CADDIE: // Cadie
      begin
        if FInvCaddie.IsExist(TypeId) then
        begin
          Exit(False);
        end;
        Exit(True);
      end;
    ITEM_TYPE_CADDIE_ITEM: // Cadie item
      begin
        if FInvCaddie.CanHaveSkin(TypeId) then
        begin
          Exit(True);
        end;
        Exit(False);
      end;
    ITEM_TYPE_SKIN: // skin
      begin
        if FInvItem.IsSkinExist(TypeId) then
        begin
          Exit(False);
        end;
        Exit(True);
      end;
    ITEM_TYPE_MASCOT:
      begin
        Exit(True);
      end;
    ITEM_TYPE_CARD:
      begin
        Exit(True);
      end
  else
    Exit(False);
  end;
end;

function TPlayerInventory.SetMascotText(MascotIdx: UInt32;
  const MascotText: AnsiString): Boolean;
var
  Mascot: PMascot;
begin
  Mascot := FInvMascot.GetMascotByIndex(MascotIdx);
  if not (Mascot = nil) then
  begin
    Mascot.SetText(MascotText);
    Exit(True);
  end;
  Exit(False);
end;

function TPlayerInventory.Remove(ItemIffId, Quantity: UInt32; Transaction: Boolean): TAddData;
var
  ItemDeletedData : TAddData;
  Items : PItem;
  Cards: PCard;
  Tran: TTransacItem;
begin
  fPriority.Acquire;
  try
    if fPlayerUID = 0 then
    begin
      Exit;
    end;

    if (ItemIffId <= 0) or (Quantity <= 0) then
    begin
      Exit;
    end;

    ItemDeletedData.Status := False;

    case TITEMGROUP(GetPartGroup(ItemIffId)) of
      ITEM_TYPE_BALL,
      ITEM_TYPE_USE:
        begin
          Items := FInvItem.GetItem(ItemIffId, Quantity);
          if not (Items = nil) then
          begin
            // Result Of Delete
            with ItemDeletedData do
            begin
              Status := True;
              ItemIndex := Items.ItemIndex;
              ItemTypeID := Items.ItemTypeID;
              ItemOldQty := Items.ItemC0;
              ItemNewQty := Items.ItemC0 - Quantity;
              ItemUCCKey := Items.ItemUCCUnique;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
            if Transaction then
            begin
              // add to transaction
              Tran := TTransacItem.Create;
              with Tran do
              begin
                Types := $2;
                TypeID := Items.ItemTypeID;
                Index := Items.ItemIndex;
                PreviousQuan := Items.ItemC0;
                NewQuan := Items.ItemC0 - Quantity;
              end;
              FTranLists.Add(Tran);
            end;
            // update item info
            Items.RemoveQuantity(Quantity);
            Exit(ItemDeletedData);
          end;
        end;
      ITEM_TYPE_CARD:
        begin
          Cards := Self.FInvCard.GetCard(ItemIffId, Quantity);
          if not (Cards = nil) then
          begin
            // Result Of Delete
            with ItemDeletedData do
            begin
              Status := True;
              ItemIndex := Cards.CardIndex;
              ItemTypeID := Cards.CardTypeID;
              ItemOldQty := Cards.CardQuantity;
              ItemNewQty := Cards.CardQuantity - Quantity;
              ItemUCCKey := Nulled;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
            if Transaction then
            begin
              Tran := TTransacItem.Create;
              with Tran do
              begin
                Types := $2;
                TypeID :=  Cards.CardTypeID;
                Index := Cards.CardIndex;
                PreviousQuan := Cards.CardQuantity;
                NewQuan := Cards.CardQuantity - Quantity;
              end;
              FTranLists.Add(Tran);
            end;
            Cards.RemoveQuantity(Quantity);
            Exit(ItemDeletedData);
          end;
        end;
    end;
    ItemDeletedData.SetData(False, 0, 0, 0, 0, Nulled, 0 ,0);
    Exit(ItemDeletedData);
  finally
    fPriority.Release;
  end;
end;

function TPlayerInventory.Remove(ItemIffId, Index, Quantity: UInt32; Transaction: Boolean): TAddData;
var
  ItemDeletedData : TAddData;
  Items : PItem;
  Cards: PCard;
  Tran: TTransacItem;
begin
  fPriority.Acquire;
  try
    if fPlayerUID = 0 then
    begin
      Exit;
    end;

    if (ItemIffId <= 0) or (Quantity <= 0) then
    begin
      Exit;
    end;

    ItemDeletedData.Status := False;

    case TITEMGROUP(GetPartGroup(ItemIffId)) of
      ITEM_TYPE_BALL,
      ITEM_TYPE_USE:
        begin
          Items := FInvItem.GetItem(ItemIffId, Index, Quantity);
          if not (Items = nil) then
          begin
            // Result Of Delete
            with ItemDeletedData do
            begin
              Status := True;
              ItemIndex := Items.ItemIndex;
              ItemTypeID := Items.ItemTypeID;
              ItemOldQty := Items.ItemC0;
              ItemNewQty := Items.ItemC0 - Quantity;
              ItemUCCKey := Items.ItemUCCUnique;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
            if Transaction then
            begin
              // add to transaction
              Tran := TTransacItem.Create;
              with Tran do
              begin
                Types := $2;
                TypeID := Items.ItemTypeID;
                Index := Items.ItemIndex;
                PreviousQuan := Items.ItemC0;
                NewQuan := Items.ItemC0 - Quantity;
              end;
              FTranLists.Add(Tran);
            end;
            // update item info
            Items.RemoveQuantity(Quantity);
            Exit(ItemDeletedData);
          end;
        end;
      ITEM_TYPE_CARD:
        begin
          Cards := Self.FInvCard.GetCard(ItemIffId, Index, Quantity);
          if not (Cards = nil) then
          begin
            // Result Of Delete
            with ItemDeletedData do
            begin
              Status := True;
              ItemIndex := Cards.CardIndex;
              ItemTypeID := Cards.CardTypeID;
              ItemOldQty := Cards.CardQuantity;
              ItemNewQty := Cards.CardQuantity - Quantity;
              ItemUCCKey := Nulled;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
            if Transaction then
            begin
              Tran := TTransacItem.Create;
              with Tran do
              begin
                Types := $2;
                TypeID :=  Cards.CardTypeID;
                Index := Cards.CardIndex;
                PreviousQuan := Cards.CardQuantity;
                NewQuan := Cards.CardQuantity - Quantity;
              end;
              FTranLists.Add(Tran);
            end;
            Cards.RemoveQuantity(Quantity);
            Exit(ItemDeletedData);
          end;
        end;
      ITEM_TYPE_PART:
        begin
          Items := FInvItem.GetItem(ItemIffId, Index, 0); // ## part should be zero
          if not (Items = nil) then
          begin
            // Result Of Delete
            with ItemDeletedData do
            begin
              Status := True;
              ItemIndex := Items.ItemIndex;
              ItemTypeID := Items.ItemTypeID;
              ItemOldQty := 1;
              ItemNewQty := 0;
              ItemUCCKey := Nulled;
              ItemFlag := 0;
              ItemEndDate := 0;
            end;
            if Transaction then
            begin
              // add to transaction
              Tran := TTransacItem.Create;
              with Tran do
              begin
                Types := $2;
                TypeID := Items.ItemTypeID;
                Index := Items.ItemIndex;
                PreviousQuan := 1;
                NewQuan := 0;
              end;
              FTranLists.Add(Tran);
            end;
            // ## delete part item
            Items.DeleteItem;
            Exit(ItemDeletedData);
          end;
        end;
    end;
    ItemDeletedData.SetData(False, 0, 0, 0, 0, Nulled, 0 ,0);
    Exit(ItemDeletedData);
  finally
    fPriority.Release;
  end;
end;

function TPlayerInventory.SetCaddieIndex(Index: UInt32): Boolean;
var
  Caddie : PCaddie;
begin
  if Index = 0 then
  begin
    FCaddieIndex := 0;
    Exit(True);
  end;
  Caddie := FInvCaddie.GetCaddieByIndex(Index);
  if Caddie = nil then
  begin
    Exit(False);
  end;
  FCaddieIndex := Caddie.CaddieIdx;
  Exit(True);
end;

function TPlayerInventory.SetMascotIndex(Index: UInt32): Boolean;
var
  Mascot: PMascot;
begin
  if Index = 0 then
  begin
    FMascotIndex := 0;
    Exit(True);
  end;
  Mascot := FInvMascot.GetMascotByIndex(Index);
  if Mascot = nil then
  begin
    Exit(False);
  end;
  FMascotIndex := Mascot.MascotIndex;
  Exit(True);
end;

function TPlayerInventory.SetCharIndex(CharacterIndex: UInt32): Boolean;
var
  Char : PCharacter;
begin
  Char := FInvChar.GetChar(CharacterIndex, bIndex);
  if (Char = nil) then
  begin
    Exit(False);
  end;
  FCharacterIndex := Char.Index;
  Exit(True);
end;

function TPlayerInventory.SetClubIndex(Index: UInt32): Boolean;
var
  Club: PItem;
begin
  Club := FInvItem.GetItem(Index);
  if (Club = nil) or (not (GetItemGroup(Club.ItemTypeID) = $4)) then
  begin
    Exit(False);
  end;
  Self.FGolfEQP.ClubIndex := Index;
  Exit(True);
end;

function TPlayerInventory.SetGolfEQP(BallTypeID, ClubIndex: UInt32): Boolean;
begin
  Exit( Self.SetBallTypeID(BallTypeID) and Self.SetClubIndex(ClubIndex) );
end;

function TPlayerInventory.SetBallTypeID(TypeID: UInt32): Boolean;
var
  Ball: PItem;
begin
  Ball := FInvItem.GetItem(TypeID, 1);
  if (Ball = nil) or (not (GetItemGroup(Ball.ItemTypeID) = $5)) then
  begin
    Exit(False);
  end;
  Self.FGolfEQP.BallTypeID := TypeID;
  Exit(True);
end;

function TPlayerInventory.GetGolfEQP: AnsiString;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    Packet.WriteUInt32(Self.FGolfEQP.BallTypeID);
    Packet.WriteUInt32(Self.FGolfEQP.ClubIndex);
    Exit(Packet.ToStr);
  finally
    FreeAndNil(Packet);
  end;
end;

function TPlayerInventory.SetPoster(const Poster1, Poster2: UInt32): Boolean;
begin
  Self.FPoster1 := Poster1;
  Self.FPoster2 := Poster2;
end;

function TPlayerInventory.TranCount: UInt32;
begin
  Exit(Self.FTranLists.TranList.Count);
end;

constructor TPlayerInventory.Create;
begin
  fPriority := TCriticalSection.Create;
  FInvChar := TSerialCharacter.Create;
  FInvMascot := TSerialMascots.Create;
  FInvItem := TSerialWarehouse.Create;
  FInvCaddie := TSerialCaddies.Create;
  FInvCard := TSerialCard.Create;
  FTranLists := TTransaction.Create;
  FInvRoom := TSerialFurniture.Create;
end;

destructor TPlayerInventory.Destroy;
begin
  fPlayerUID := 0;
  fItemSlot.Clear;
  FreeAndNil(fPriority);
  FreeAndNil(FInvChar);
  FreeAndNil(FInvMascot);
  FreeAndNil(FInvItem);
  FreeAndNil(FInvCaddie);
  FreeAndNil(FInvCard);
  FreeAndNil(FTranLists);
  FreeAndNil(FInvRoom);
  inherited;
end;

end.
