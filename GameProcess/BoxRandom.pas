unit BoxRandom;

interface

uses
  PangyaClient, ClientPacket, ItemData, IffMain, SysUtils,
  System.SyncObjs, AuthClient, Utils, MyList, AnsiStrings, Tools,
  XSuperObject, PacketCreator, PList, Enum, ErrorCode, ServerStr, MailSystem;

type
  PRewardInfo = ^TRewardInfo;

  TRewardInfo = packed record
    var TypeId: UInt32;
    var Quantity: UInt32;
    var Prob: UInt32;
    var RareType: UInt8;
    var Duplicated: Boolean;
    var Announce: Boolean;
    procedure Sets(FTypeID, FQuantity, Probabilities: UInt32; FRareType: UInt8; IsDuplicated, IsAnnounce: Boolean);
  end;

  PBoxInfo = ^TBoxInfo;

  TBoxInfo = packed record
    var BoxTypeID, BoxQuantity: UInt32;
    var SupplyTypeID, SupplyQuantity: UInt32; // USE IN SPIN CUBE [KEY]
    var RewardList: TMyList<PRewardInfo>;
    var SpecialRewardTypeID, SpecialRewardQuantity: UInt32;
  end;

  TBoxItemList = class(TMyList<PBoxInfo>)
    constructor Create;
    destructor Destroy; override;
    function GetBoxInfo(BoxTypeId: UInt32): PBoxInfo;
    function GetItemBox(BoxTypeId:UInt32): PRewardInfo;
  end;

  TBoxRandomClass = class
    private
      var FLock: TCriticalSection;
      var FBoxItem: TBoxItemList;
    public
      procedure HandlePlayerOpenBox(const clientPacket: TClientPacket; const Player: TClientPlayer);
      constructor Create;
      destructor Destroy; override;
  end;

  var
    BoxRand: TBoxRandomClass;

implementation

{ TBoxItemList }

constructor TBoxItemList.Create;
var
  Box: PBoxInfo;
  Reward: PRewardInfo;

  MainJS: ISuperObject;
  AMember, BMember: IMember;
begin
  inherited;

  MainJS := SO.T.ParseFile('RandomBox/BoxData.txt');

  for AMember in MainJS.A['BoxData'] do
  begin
    New(Box);
    Box.BoxTypeID := AMember.AsObject['BoxTypeID'].AsInteger;
    Box.BoxQuantity := AMember.AsObject['BoxQuantity'].AsInteger;
    Box.SupplyTypeID := AMember.AsObject['SupplyTypeID'].AsInteger;
    Box.SupplyQuantity := AMember.AsObject['SupplyQuantity'].AsInteger;
    Box.SpecialRewardTypeID := AMember.AsObject['SpecialRewardTypeID'].AsInteger;
    Box.SpecialRewardQuantity := AMember.AsObject['SpecialRewardQuantity'].AsInteger;
    // # Create box reward lists
    Box.RewardList := TMyList<PRewardInfo>.Create;
    for BMember in AMember.AsObject['RewardItems'].AsArray do
    begin
      New(Reward);
      Reward.TypeId := BMember.AsObject['TypeID'].AsInteger;
      Reward.Quantity := BMember.AsObject['Quantity'].AsInteger;
      Reward.Prob := BMember.AsObject['Probability'].AsInteger;
      Reward.RareType := BMember.AsObject['RareType'].AsInteger;
      Reward.Duplicated := BMember.AsObject['CanDuplicated'].AsBoolean;
      Reward.Announce := BMember.AsObject['Announce'].AsBoolean;
      Box.RewardList.Add(Reward);
    end;
    Self.Add(Box);
  end;
end;

destructor TBoxItemList.Destroy;
var
  Box: PBoxInfo;
  Reward: PRewardInfo;
begin
  for Box in self do
  begin
    for Reward in Box.RewardList do
    begin
      Dispose(Reward);
    end;

    Box.RewardList.Clear;
    FreeAndNil(Box.RewardList);

    Dispose(Box);
  end;
  Clear;
  inherited;
end;

function TBoxItemList.GetBoxInfo(BoxTypeId: UInt32): PBoxInfo;
var
  Box: PBoxInfo;
begin
  for Box in Self do
    if Box.BoxTypeID = BoxTypeId then
      Exit(Box);

  Exit(Nil);
end;

function TBoxItemList.GetItemBox(BoxTypeId: UInt32): PRewardInfo;
var
  Box: PBoxInfo;
  Reward: PRewardInfo;
  Count, Rand : SmallInt;
begin
  Count := 0;

  Randomize;

  for Box in self do
  begin
    if Box.BoxTypeID = BoxTypeId then
    begin
      for Reward in  Box.RewardList do
      begin
        Inc(Count, Reward.Prob);
      end;

      Rand := Random(Count) + 1;

      for Reward in  Box.RewardList do
      begin
        Dec(Rand, Reward.Prob);
        if Rand <= 0 then
        begin
          Exit(Reward);
        end;
      end;
    end;
  end;
  Exit(Nil);
end;

{ TRewardInfo }

procedure TRewardInfo.Sets(FTypeID, FQuantity, Probabilities: UInt32; FRareType: UInt8; IsDuplicated, IsAnnounce: Boolean);
begin
  TypeId := FTypeID;
  Quantity := FQuantity;
  Prob := Probabilities;
  RareType := FRareType;
  Duplicated := IsDuplicated;
  Announce := IsAnnounce;
end;

{ TBoxRandomClass }

constructor TBoxRandomClass.Create;
begin
  FBoxItem := TBoxItemList.Create;
  FLock := TCriticalSection.Create;
end;

destructor TBoxRandomClass.Destroy;
begin
  FreeAndNil(FBoxItem);
  FreeAndNil(FLock);
  inherited;
end;

procedure TBoxRandomClass.HandlePlayerOpenBox(const clientPacket: TClientPacket; const Player: TClientPlayer);
var
  BoxIffTypeID: UInt32;
  Reward: PRewardInfo;
  BoxInfo: PBoxInfo;
  RemoveItemData, AddItemData: TAddData;
  Item: TAddItem;
  Param: AnsiString;
  Lists: TPointerList;
  APoint: Pointer;
  MailSender: TMailSender;
begin
  FLock.Acquire;
  Lists := TPointerList.Create;
  try
    if not ClientPacket.ReadUInt32(BoxIffTypeID) then
    begin
      Exit;
    end;

    BoxInfo := FBoxItem.GetBoxInfo(BoxIffTypeID);
    // # Box doens't exist
    if (BoxInfo = nil) then
    begin
      Player.Write(ShowOpenBoxFail);
      raise Exception.CreateFmt('HandlePlayerOpenBox: Cannot find system''s box to open %d', [BoxIffTypeID]);
    end;

    // # Player does not have this box
    if not Player.Inventory.IsExist(BoxInfo.BoxTypeID) then
    begin
      raise Exception.CreateFmt('HandlePlayerOpenBox: Player hasn''t had this box %d', [BoxIffTypeID]);
    end;

    // # Special item to delete # use for openned cube
    if (BoxInfo.SupplyTypeID > 0) then
    begin
      if not Player.Inventory.IsExist(BoxInfo.SupplyTypeID) then
      begin
        raise Exception.CreateFmt('HandlePlayerOpenBox: Can''t find player''s supply %d', [BoxInfo.SupplyTypeID]);
      end;
    end;

    // # delete box
    RemoveItemData := Player.Inventory.Remove(BoxInfo.BoxTypeID,BoxInfo.BoxQuantity, False);
    // # add to list
    New(PItemData(APoint));
    PItemData(APoint).TypeId        := RemoveItemData.ItemTypeID;
    PItemData(APoint).ItemIndex     := RemoveItemData.ItemIndex;
    PItemData(APoint).ItemQuantity  := RemoveItemData.ItemNewQty;
    Lists.Add(APoint);
    // # end

    // # if supply typeid is specified
    if (BoxInfo.SupplyTypeID > 0) then
    begin
      // # delete supplyment # use for key's spin cube
      RemoveItemData := Player.Inventory.Remove(BoxInfo.SupplyTypeID,BoxInfo.SupplyQuantity, False);
      // # add to list
      New(PItemData(APoint));
      PItemData(APoint).TypeId        := RemoveItemData.ItemTypeID;
      PItemData(APoint).ItemIndex     := RemoveItemData.ItemIndex;
      PItemData(APoint).ItemQuantity  := RemoveItemData.ItemNewQty;
      Lists.Add(APoint);
      // # end
    end;

    // # if special reward is specified
    if (BoxInfo.SpecialRewardTypeID > 0) then
    begin
      Item.ItemIffId    := BoxInfo.SpecialRewardTypeID;
      Item.Quantity     := BoxInfo.SpecialRewardQuantity;
      Item.Transaction  := False;
      Item.Day := 0;

      AddItemData := Player.AddItem(Item);

      if (AddItemData.ItemNewQty > 1) then
      begin
        // # add to list
        New(PItemData(APoint));
        PItemData(APoint).TypeId        := AddItemData.ItemTypeID;
        PItemData(APoint).ItemIndex     := AddItemData.ItemIndex;
        PItemData(APoint).ItemQuantity  := AddItemData.ItemNewQty;
        Lists.Add(APoint);
        // # end
      end;
    end;

    // # send data to player
    Player.Write(ShowBoxItem(Lists));

    // # clear
    Lists.ClearPointer;

    // # send #$AA
    if (AddItemData.ItemNewQty = 1) then
    begin
      New(PItemData(APoint));
      PItemData(APoint).TypeId        := AddItemData.ItemTypeID;
      PItemData(APoint).ItemIndex     := AddItemData.ItemIndex;
      PItemData(APoint).ItemQuantity  := AddItemData.ItemNewQty;
      Lists.Add(APoint);
    end;
    { send result }
    Player.Write(ShowBoxNewItem(Lists, Player.GetPang, Player.GetCookie));

    while True do
    begin
      Reward := FBoxItem.GetItemBox(BoxIffTypeID);
      if not Reward.Duplicated then { if this item can have only one ea }
      begin
        if not Player.Inventory.IsExist(Reward.TypeId) then
        begin
          Break;
        end;
      end
      else if Reward.Duplicated then
      begin
        Break;
      end;
    end;

    if (Reward = nil) then
    begin
      Player.Send(BOX_REWARD_NIL);
      raise Exception.CreateFmt('HandlePlayerOpenBox: Reward is nil with box typeid: %d', [BoxIffTypeID]);
    end;

    if Reward.Announce then
    begin
      { generate param }
      Param := AnsiFormat(ReadString.GetText('BoxAnnounce'),[BoxIffTypeID, Player.GetNickname, Reward.TypeId,Reward.Quantity]);
      { send to auth system }
      AuthController.Write(ShowBoxAnnounce(Param));
    end;

    MailSender := TMailSender.Create;
    try
      MailSender.Sender := 'System';
      MailSender.AddText(AnsiFormat(ReadString.GetText('SpinCubeIem'), [IffEntry.GetItemName(BoxIffTypeID)]));
      MailSender.AddItem(Reward.TypeId, Reward.Quantity);
      MailSender.Send(Player.GetUID);
    finally
      FreeAndNil(MailSender);
    end;

    Player.Write(ShowBoxItem(BoxIffTypeID, Reward.TypeId, Reward.Quantity));
  finally
    FreeAndNil(Lists);
    FLock.Release;
  end;
end;

initialization
  begin
    BoxRand := TBoxRandomClass.Create;
  end;

finalization
  begin
    FreeAndNil(BoxRand);
  end;

end.
