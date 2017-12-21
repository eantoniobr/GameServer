unit IffManager.LevelUpPrizeItem;

interface

uses
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, Enum, Defines;

type

  PIffPrize = ^TIffPrize;

  TIffPrize = packed record
    var Level,TypeID, Quantity: UInt32;
  end;

  TIffLevelPrize = class
    private
      var FLevelPrize : TList<PIffPrize>;
    public
      constructor Create;
      destructor Destroy; override;
      property ReadLevelPrize: TList<PIffPrize> read FLevelPrize;
  end;

implementation

{ TIffLevelPrize }
{ This unit must use TList because of its algorithm }

constructor TIffLevelPrize.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Count : UInt32;
  Total: UInt16;
  Level, Index: UInt16;
  TypeID, Quantity: Array[$0..$1] Of UInt32;
  Item: PIffPrize;
begin
  FLevelPrize := TList<PIffPrize>.Create;

  if not FileExists('data\LevelUpPrizeItem.iff') then begin
    WriteConsole(' data\LevelUpPrizeItem.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\LevelUpPrizeItem.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  try
    if not Packet.ReadUInt16(Total) then Exit;

    Packet.Skip(6);

    for Count := 1 to Total do
    begin

      Packet.Skip($22);
      Packet.ReadUInt16(Level);
      Packet.Read(TypeId, SizeOf(TypeID));
      Packet.Read(Quantity, SizeOf(Quantity));
      Packet.Skip($8C);

      for Index := 0 to Length(TypeID) - 1 do
      begin
        if (TypeId[Index] > 0) and (Quantity[Index] > 0) then
        begin
          New(Item);
          Item.Level := Level;
          Item.TypeID := TypeId[Index];
          Item.Quantity := Quantity[Index];
          FLevelPrize.Add(Item);
        end;
      end;
    end;
  finally
    Packet.Free;
  end;

end;

destructor TIffLevelPrize.Destroy;
var
  Item: PIffPrize;
begin
  for Item in FLevelPrize do
  begin
    Dispose(Item);
  end;
  FLevelPrize.Clear;
  FLevelPrize.Free;
  inherited;
end;

end.
