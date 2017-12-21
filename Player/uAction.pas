unit uAction;

interface

uses
  System.Math.Vectors, ClientPacket;

type
  PPlayerAction = ^TPlayerAction;
  TPlayerAction = packed record
    var Animate : UInt32;
    var Unknown1 : UInt16;
    var Posture: UInt32;
    var Vector: TPoint3D;
    procedure Clear;
    function ToStr: AnsiString;
  end;

implementation

procedure TPlayerAction.Clear;
begin
  FillChar(Self.Animate, SizeOf(TPlayerAction), 0);
end;

function TPlayerAction.ToStr: AnsiString;
var
  Packet: TClientPacket;
begin
  Packet := TClientPacket.Create;
  try
    with Packet do
    begin
      WriteUInt32(Animate);
      WriteStr(#$0D#$A2);
      WriteUInt32(Posture);
      Write(Vector.X, SizeOf(TPoint3D));
      Exit(ToStr);
    end;
  finally
    Packet.Free;
  end;
end;

end.
