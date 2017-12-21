unit IffManager.CaddieMagic;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Defines, Enum;


type
  PIffMagicBox = ^TIffMagicBox;

  TIffMagicBox = packed record
    var MagicID: UInt32;
    var Enabled: UInt32;
    var Sector: UInt32;
    var Character: UInt32;
    var Level: UInt32;
    var Un1: UInt32;
    var TypeID: UInt32;
    var Quatity: UInt32;
    var TradeID: array[$0..$3] of UInt32;
    var TradeQuantity: array[$0..$3] of UInt32;
    var BoxID: UInt32;
    var Name: array[$0..$27] of AnsiChar;
    var DateStart: array[$0..$F] of AnsiChar;
    var DateEnd: array[$0..$F] of AnsiChar;
  end;

  TIffMagicBoxs = class
    private
      FMagicBox: TDictionary<UInt32, PIffMagicBox>;
    public
      constructor Create;
      destructor Destroy; override;
      function GetMagicTrade(MagicID: UInt32): TList<TPair<UInt32, UInt32>>;
      function GetItem(MagicID: UInt32): TPair<UInt32, UInt32>;
  end;

implementation

{ TIffMagicBoxs }

constructor TIffMagicBoxs.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total: UInt16;
  Count : UInt32;
  MGBox : PIffMagicBox;
begin
  FMagicBox := TDictionary<UInt32, PIffMagicBox>.Create;

  if not FileExists('data\CadieMagicBox.iff') then begin
    WriteConsole(' data\CadieMagicBox.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\CadieMagicBox.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt16(Total) then Exit;

    Packet.Skip(6);

    for Count := 1 to Total do
    begin
      New(MGBox);
      Packet.Read(MGBox.MagicID, SizeOf(TIffMagicBox));
      FMagicBox.Add(MGBox.MagicID, MGBox);
    end;
  finally
    Packet.Free;
  end;
end;

destructor TIffMagicBoxs.Destroy;
var
  MGBox : PIffMagicBox;
begin
  for MGBox in Self.FMagicBox.Values do
    Dispose(MgBox);

  Self.FMagicBox.Clear;
  FreeAndNil(FMagicBox);
  inherited;
end;

function TIffMagicBoxs.GetItem(MagicID: UInt32): TPair<UInt32, UInt32>;
var
  MGBox : PIffMagicBox;
begin
  if not Self.FMagicBox.TryGetValue(MagicID, MGBox) then Exit(TPair<UInt32, UInt32>.Create(0, 0));

  Exit(TPair<UInt32, UInt32>.Create(MGBox.TypeID, MGBox.Quatity));
end;

function TIffMagicBoxs.GetMagicTrade(MagicID: UInt32): TList<TPair<UInt32, UInt32>>;
var
  MGBox : PIffMagicBox;
  Count: UInt8;
begin
  Result := TList<TPair<UInt32, UInt32>>.Create;

  if not Self.FMagicBox.TryGetValue(MagicID, MGBox) then Exit;

  for Count := 0 to Length(MGBox.TradeID) - 1 do
    if MGBox.TradeID[Count] > 0 then
      Result.Add(TPair<UInt32, UInt32>.Create(MGBox.TradeID[Count], MGBox.TradeQuantity[Count]));

  Exit(Result);
end;

end.
