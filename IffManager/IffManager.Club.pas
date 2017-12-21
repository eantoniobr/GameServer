unit IffManager.Club;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, Enum, Defines, AnsiStrings;

type
  PIffClub = ^TIffClub;

  TIffClub = packed record
    var Base: TBaseIff;
    var Club1, Club2, Club3, Club4: UInt32;
    var C0: UInt16;
    var C1: UInt16;
    var C2: UInt16;
    var C3: UInt16;
    var C4: UInt16;
    var MaxPow: UInt16;
    var MaxCon: UInt16;
    var MaxImp: UInt16;
    var MaxSpin: UInt16;
    var MaxCurve: UInt16;
    var ClubType: UInt32;
    var ClubSPoint: UInt32;
    var RecoveryLimit: UInt32;
    var RateWorkshop: Single;
    var Unknown6: UInt32;
    var Transafer: UInt16;
    var Flag1: UInt16;
    var Unknown7: UInt32;
    var Unknown8: UInt32;
  end;


  TIffClubs = class
    private
      var FClubDB: TDictionary<UInt32, PIffClub>;
    public
      constructor Create;
      destructor Destroy; override;
      function IsExist(TypeId: UInt32): Boolean;
      function LoadItem(ID: UInt32; var ClubInfo: PIffClub): Boolean;
      function GetItemName(TypeId: UInt32): AnsiString;
      function GetClubStatus(ID: UInt32): TClubStatus;
      function GetPrice(TypeID: UInt32): UInt32;
      function GetShopPriceType(TypeId: UInt32): ShortInt;
      function IsBuyable(TypeId: UInt32): Boolean;
  end;

implementation

{ TIffClubs }

constructor TIffClubs.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  ClubInfo : PIffClub;
begin
  FClubDB := TDictionary<UInt32, PIffClub>.Create;

  if not FileExists('data\ClubSet.iff') then begin
    WriteConsole(' data\ClubSet.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\ClubSet.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 1 to Total do
    begin
      New(ClubInfo);
      Packet.Read(ClubInfo.Base.Enabled, SizeOf(TIffClub));
      // Add item to TDictionary
      FClubDB.Add(ClubInfo.Base.TypeID, ClubInfo);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TIffClubs.Destroy;
var
  ClubInfo: PIffClub;
begin
  for ClubInfo in FClubDB.Values do
  begin
    Dispose(ClubInfo);
  end;
  FClubDB.Clear;
  FClubDB.Free;
  inherited;
end;

function TIffClubs.GetClubStatus(ID: UInt32): TClubStatus;
var
  ClubInfo: PIffClub;
begin
  if not LoadItem(ID, ClubInfo) then Exit;
  with Result do
  begin
    Power := ClubInfo.MaxPow;
    Control := ClubInfo.MaxCon;
    Impact := ClubInfo.MaxImp;
    Spin := ClubInfo.MaxSpin;
    Curve := ClubInfo.MaxCurve;
    ClubType := ECLUBTYPE(ClubInfo.ClubType);
    ClubSPoint := ClubInfo.ClubSPoint;
  end;
  Exit(Result);
end;

function TIffClubs.GetItemName(TypeId: UInt32): AnsiString;
var
  ClubInfo: PIffClub;
begin
  if not LoadItem(TypeId, ClubInfo) then Exit;
  Exit(ClubInfo.Base.Name);
end;

function TIffClubs.GetPrice(TypeID: UInt32): UInt32;
var
  ClubInfo: PIffClub;
begin
  if not LoadItem(TypeID, ClubInfo) then Exit(999999999);
  Exit(ClubInfo.Base.ItemPrice);
end;

function TIffClubs.GetShopPriceType(TypeId: UInt32): ShortInt;
var
  ClubInfo: PIffClub;
begin
  if not LoadItem(TypeID, ClubInfo) then Exit(-1);

  Exit(ClubInfo.Base.PriceType);
end;

function TIffClubs.IsBuyable(TypeId: UInt32): Boolean;
var
  ClubInfo: PIffClub;
begin
  if not LoadItem(TypeID, ClubInfo) then Exit(False);

  if (ClubInfo.Base.TypeID = TypeId) and (ClubInfo.Base.Enabled = 1) and (ClubInfo.Base.ItemFlag AND 1 <> 0) then
    Exit(True);

  Exit(False);
end;

function TIffClubs.IsExist(TypeId: UInt32): Boolean;
var
  ClubInfo: PIffClub;
begin
  if not LoadItem(TypeId, ClubInfo) then Exit(False);

  if (ClubInfo.Base.Enabled = 1) then
  begin
    Exit(True);
  end;
  Exit(False);
end;

function TIffClubs.LoadItem(ID: UInt32; var ClubInfo: PIffClub): Boolean;
begin
  if not FClubDB.TryGetValue(UInt32(ID), ClubInfo) then
  begin
    Exit(False);
  end;
  Exit(True);
end;

end.
