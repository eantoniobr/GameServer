unit IffManager.CutinInfo;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole;

type
  PIffCutinInfo = ^TIffCutinInfo;

  TIffCutinInfo = packed record
    var Enable : UInt32;
    var TypeId : UInt32;
    var Num1: UInt32;
    var Num2: UInt32;
    var NumImg1: UInt32;
    var IMG1: AnsiString;
    var NumImg2: UInt32;
    var IMG2: AnsiString;
    var NumImg3: UInt32;
    var IMG3: AnsiString;
    var Num3: UInt32;
    var Num4: UInt32;
  end;

  TIffCutinInfos = class
    private
      var FCutin: TDictionary<UInt32, PIffCutinInfo>;
      function LoadCutin(ID: UInt32; var Cutin: PIffCutinInfo): Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      function GetCutinString(TypeID: UInt32): AnsiString;
  end;

implementation

{ TIffCutinInfos }

constructor TIffCutinInfos.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total: UInt16;
  Count : UInt32;
  Item : PIffCutinInfo;
begin
  FCutin := TDictionary<UInt32, PIffCutinInfo>.Create;

  if not FileExists('data\CutinInfomation.iff') then begin
    WriteConsole(' data\CutinInfomation.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\CutinInfomation.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt16(Total) then Exit;
    Packet.Skip(2);

    Packet.Skip(4);

    for Count := 1 to Total do
    begin
      New(Item);
      Packet.ReadUInt32(Item.Enable);
      Packet.ReadUInt32(Item.TypeId);
      Packet.Skip(8);
      Packet.ReadUInt32(Item.Num1);
      Packet.ReadUInt32(Item.Num2);
      Packet.ReadUInt32(Item.NumImg1);
      Packet.ReadStr(Item.IMG1, 40);

      Item.IMG1 := Trim(Item.IMG1);

      Packet.ReadUInt32(Item.NumImg2);
      Packet.ReadStr(Item.IMG2, 40);

      Item.IMG2 := Trim(Item.IMG2);

      Packet.ReadUInt32(Item.NumImg3);
      Packet.ReadStr(Item.IMG3, 40);

      Item.IMG3 := Trim(Item.IMG3);

      Packet.ReadUInt32(Item.Num3);
      Packet.Skip(44);
      Packet.ReadUInt32(Item.Num4);
      FCutin.Add(Item.TypeId ,Item);
    end;
  finally
    Packet.Free;
  end;
end;

destructor TIffCutinInfos.Destroy;
var
  Items : PIffCutinInfo;
begin
  for Items in FCutin.Values do
  begin
    Dispose(Items);
  end;
  FCutin.Clear;
  FreeAndNil(FCutin);
  inherited;
end;

function TIffCutinInfos.GetCutinString(TypeID: UInt32): AnsiString;
var
  Cutin: PIffCutinInfo;
  Packet: TClientPacket;
begin
  if not LoadCutin(TypeID, Cutin) then Exit(#$8D#$01#$00);

  Packet := TClientPacket.Create;
  try
    Packet.WriteStr(#$8D#$01);
    Packet.WriteUInt8(1);
    Packet.WriteUInt32(Cutin.TypeId);
    Packet.WriteUInt32(Cutin.Num1);
    Packet.WriteUInt32(Cutin.Num2);
    Packet.WriteUInt32(Cutin.NumImg2);
    Packet.WriteUInt32(Cutin.NumImg3);
    Packet.WriteUInt32(Cutin.Num3);
    Packet.WriteUInt32(0);
    Packet.WriteUInt32(Cutin.Num4);
    Packet.WriteStr(Cutin.IMG1, 40);
    Packet.WriteStr(Cutin.IMG2, 40);
    Packet.WriteStr(Cutin.IMG3, 40);
    Packet.WriteStr(#$00, 40);
    Exit(Packet.ToStr);
  finally
    Packet.Free;
  end;
end;

function TIffCutinInfos.LoadCutin(ID: UInt32; var Cutin: PIffCutinInfo): Boolean;
begin
  if not FCutin.TryGetValue(UInt32(ID), Cutin) then
  begin
    Exit(False);
  end;
  Exit(True);
end;

end.
