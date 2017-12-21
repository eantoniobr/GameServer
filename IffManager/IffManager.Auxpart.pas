unit IffManager.Auxpart;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, AnsiStrings, Enum;

type

  PIffAux = ^TIffAux;

  TIffAux = packed record
    var Base: TBaseIff;
    var Quantity: UInt32;
    var Un1: UInt32;
    var Un2: UInt16;
    var C0, C1, C2, C3, C4: UInt8;
    var Slot1, Slot2, Slot3, Slot4, Slot5: UInt8;
    var Eff1, Eff2, Eff3, Eff4, Eff5, Eff6: UInt16;
    var AuxPair: UInt32;
  end;

  TIffAuxs = class
    private
      var FAuxDB: TDictionary<UInt32, PIffAux>;
    public
      constructor Create;
      destructor Destroy; override;
      function LoadAux(ID: UInt32; var Aux: PIffAux): Boolean;
      function GetItemName(ID: UInt32): AnsiString;
      function IsExist(ID: UInt32): Boolean;
  end;

implementation

{ TIffAuxs }

constructor TIffAuxs.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count : UInt32;
  Aux : PIffAux;
begin
  FAuxDB := TDictionary<UInt32, PIffAux>.Create;

  if not FileExists('data\AuxPart.iff') then begin
    WriteConsole(' data\AuxPart.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\AuxPart.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 1 to Total do
    begin
      New(Aux);
      Packet.Read(Aux.Base.Enabled, SizeOf(TIffAux));
      // Add item to TDictionary
      FAuxDB.Add(Aux.Base.TypeID, Aux);
      writeln(Aux.Base.Name);
    end;

  finally
    Packet.Free;
  end;
end;

destructor TIffAuxs.Destroy;
var
  Aux : PIffAux;
begin
  for Aux in FAuxDB.Values do
  begin
    Dispose(Aux);
  end;
  FAuxDB.Clear;
  FreeAndNil(FAuxDB);
  inherited;
end;

function TIffAuxs.GetItemName(ID: UInt32): AnsiString;
var
  Aux : PIffAux;
begin
  if not LoadAux(ID, Aux) then Exit();

  Exit(Aux.Base.Name);
end;

function TIffAuxs.IsExist(ID: UInt32): Boolean;
var
  Aux : PIffAux;
begin
  if not LoadAux(ID, Aux) then Exit(False);
  Exit(True);
end;

function TIffAuxs.LoadAux(ID: UInt32; var Aux: PIffAux): Boolean;
begin
  if not FAuxDB.TryGetValue(ID, Aux) then Exit(False);

  Exit(True);
end;

end.
