unit IffManager.GrandPrixSpecialHole;

interface

uses
  MyList, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings;

type

  PGPSpecial = ^TGPSpecial;

  TGPSpecial = packed record
    var Enable: UInt32;
    var TypeID: UInt32;
    var HolePOS: UInt32;
    var Map: UInt32;
    var Hole: UInt32;
  end;

  TIffGPSpecial = class
    private
      FGPSpecial: TMyList<PGPSpecial>;
    public
      constructor Create;
      destructor Destroy; override;

      property GPHSpecial: TMyList<PGPSpecial> read FGPSpecial;
  end;

implementation

{ TIffGPSpecial }

constructor TIffGPSpecial.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt16;
  GP : PGPSpecial;
begin
  FGPSpecial := TMyList<PGPSpecial>.Create;

  if not FileExists('data\GrandPrixSpecialHole.iff') then begin
    WriteConsole(' data\GrandPrixSpecialHole.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\GrandPrixSpecialHole.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt16(Total) then Exit;

    Packet.Skip(6);

    for Count := 1 to Total do
    begin
      New(GP);
      Packet.Read(GP.Enable, SizeOf(TGPSpecial));
      FGPSpecial.Add(GP);
    end;

  finally
    Packet.Free;
  end;

end;

destructor TIffGPSpecial.Destroy;
var
  P: PGPSpecial;
begin
  for P in FGPSpecial do
    Dispose(P);

  FGPSpecial.Clear;
  FreeAndNil(FGPSpecial);
  inherited;
end;

end.
