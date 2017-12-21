unit Counter;

interface

uses
  SysUtils, Windows, UWriteConsole, Tools;

type
  TCounter = class
    private
      var StartTime : Double;
    public
      procedure Start;
      function GetTime: Double;
      constructor Create;
      destructor Destroy; override;
  end;

var
  M_Counter : TCounter;

implementation

{ TCounter }

constructor TCounter.Create;
begin

end;

destructor TCounter.Destroy;
begin
  inherited;
end;

function TCounter.GetTime: Double;
begin
  Result := GetTickCount - StartTime;
  WriteConsole( AnsiFormat('%f', [Result]) );
end;

procedure TCounter.Start;
begin
  StartTime := GetTickCount;
end;

initialization
  M_Counter := TCounter.Create;

Finalization
  M_Counter.Free;

end.
