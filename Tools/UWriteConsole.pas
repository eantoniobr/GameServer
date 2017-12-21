unit UWriteConsole;

interface

uses
  Console, SysUtils;

Const
  LogColor: Integer = 8;

procedure WriteConsole(Const Text: AnsiString; Color: Byte = 15); overload;
procedure WriteConsole(Number: UInt32; Color: Byte = 15); overload;

implementation

procedure WriteConsole(Const Text: AnsiString; Color: Byte = 15);
begin
  TextColor(LogColor);
  Write(Format( '[%s]' , [FormatDateTime ('c:zzz', Now)]));
  TextColor(Color);
  WriteLn(Format( ' %s' , [Text]));
end;

procedure WriteConsole(Number: UInt32; Color: Byte = 15); overload;
begin
  TextColor(LogColor);
  Write(Format( '[%s]' , [FormatDateTime ('c:z', Now)]));
  TextColor(Color);
  WriteLn(Format( ' %d' , [Number]));
end;

end.
