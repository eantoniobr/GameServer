unit IffManager.GrandPrixData;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings;

type

  PGrandPrixData = ^TGrandPrixData;

  TGrandPrixData = packed record
    var Enable: UInt32;
    var TypeId: UInt32;
    var TrueTypeId: UInt32;
    var TypeGP: UInt32;
    var TimeHole: UInt16;
    var Name: Array[0..65] of AnsiChar;
    var TicketTypeID: UInt32;
    var Quantity: UInt32;
    var Image: Array[0..39] of AnsiChar;
    var Unknown1: UInt8;
    var Natural: UInt8;
    var ShortGame: UInt8;
    var HoleSize: UInt8;
    var Artifact: UInt32;
    var Map: UInt32;
    var Mode: UInt32;
    var TotalHole: UInt8;
    var MinLevel: UInt8;
    var MaxLevel: UInt8;
    var Unknown2: UInt8;
    var Condition1: UInt32;
    var Condition2: UInt32;
    var ScoreBotMax: Int32;
    var ScoreBotMed: Int32;
    var ScoreBotMin: Int32;
    var Diffucult: UInt32;
    var PangReward: UInt32;
    var RewardTypeID: Array[0..4] of UInt32;
    var RewardQuantity: Array[0..4] of UInt32;
    var Unknown3: Array[0..11] of AnsiChar;

    var DateActive: Array[0..15] of AnsiChar;
    var Hour_Open: UInt16;
    var Min_Open: UInt16;
    var Unknown4: Array[0..11] of AnsiChar;

    var Hour_Start: UInt16;
    var Min_Start: UInt16;
    var Unknown5: Array[0..11] of AnsiChar;

    var Hour_End: UInt16;
    var Min_End: UInt16;
    var Unknown6: Array[0..7] of AnsiChar;
    var TypeIDGPLock: UInt32;
    var Lock: UInt32;
    function GetName: AnsiString;
    function IsNovice: Boolean;
  end;

  TGrandPrixDataClass = class
    private
      var FGPData: TDictionary<UInt32, PGrandPrixData>;
      function LoadGP(ID: UInt32; var GP: PGrandPrixData): Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      function IsGPExist(TypeId: UInt32): Boolean;
      function GetGP(TypeId: UInt32): PGrandPrixData;
      property GP: TDictionary<UInt32, PGrandPrixData> read FGPData;
  end;

implementation

{ TGrandPrixDataClass }

constructor TGrandPrixDataClass.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt16;
  GP : PGrandPrixData;
begin
  FGPData := TDictionary<UInt32, PGrandPrixData>.Create;

  if not FileExists('data\GrandPrixData.iff') then begin
    WriteConsole(' data\GrandPrixData.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\GrandPrixData.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt16(Total) then Exit;

    Packet.Skip(6);

    for Count := 1 to Total do
    begin
      New(GP);
      Packet.Read(GP.Enable, SizeOf(TGrandPrixData));
      PAcket.Skip(516);
      FGPData.Add(GP.TypeId, GP);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TGrandPrixDataClass.Destroy;
var
  GP : PGrandPrixData;
begin
  for GP in FGPData.Values do
  begin
    Dispose(GP);
  end;
  FGPData.Clear;
  FreeAndNil(FGPData);
  inherited;
end;

function TGrandPrixDataClass.GetGP(TypeId: UInt32): PGrandPrixData;
var
  GP : PGrandPrixData;
begin
  if not LoadGP(TypeId, GP) then Exit(nil);

  Exit(GP);
end;

function TGrandPrixDataClass.IsGPExist(TypeId: UInt32): Boolean;
var
  GP : PGrandPrixData;
begin
  if not LoadGP(TypeId, GP) then Exit(False);

  Exit(True);
end;

function TGrandPrixDataClass.LoadGP(ID: UInt32; var GP: PGrandPrixData): Boolean;
begin
  if not FGPData.TryGetValue(ID, GP) then Exit(False);

  Exit(True);
end;

{ TGrandPrixData }

function TGrandPrixData.GetName: AnsiString;
begin
  SetLength(Result, SizeOf(Self.Name));
  Move(Self.Name[0], Result[1], SizeOf(Self.Name));
  Exit(Trim(Result));
end;

function TGrandPrixData.IsNovice: Boolean;
begin
  Result := (Self.Hour_Open = 0) and (Self.Min_Open = 0) and (Self.Hour_End = 0) and (Self.Min_End = 0);
end;

end.
