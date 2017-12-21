unit IffManager.GPRankReward;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings;

type

  PGPRankReward = ^TGPRankReward;

  TGPRankReward = packed record
    var Enabled: UInt32;
    var TypeID: UInt32;
    var Rank: UInt32;
    var RewardTypeID: array[$0..$4] of UInt32;
    var Quantity: array[$0..$4] of UInt32;
    var Unknown: array[$0..$13] of AnsiChar;
    var Trophy: UInt32;
  end;

  TGPRewardIff = class
    private
      var FGPRankReward: TDictionary<UInt32, PGPRankReward>;
    public
      constructor Create;
      destructor Destroy; override;
  end;

implementation

{ TGPRewardIff }

constructor TGPRewardIff.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt16;
  GP : PGPRankReward;
begin
  FGPRankReward := TDictionary<UInt32, PGPRankReward>.Create;

  if not FileExists('data\GrandPrixRankReward.iff') then begin
    WriteConsole(' data\GrandPrixRankReward.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\GrandPrixRankReward.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt16(Total) then Exit;

    Packet.Skip(6);

    for Count := 1 to Total do
    begin
      New(GP);
      Packet.Read(GP.Enabled, SizeOf(TGPRankReward));
      PAcket.Skip(516);
      //FGPRankReward.Add(GP.TypeId, GP);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TGPRewardIff.Destroy;
var
  GP : PGPRankReward;
begin
  for GP in Self.FGPRankReward.Values do
    Dispose(GP);

  FGPRankReward.Clear;
  FreeAndNil(FGPRankReward);
  inherited;
end;

end.
