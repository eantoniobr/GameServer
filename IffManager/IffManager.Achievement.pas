unit IffManager.Achievement;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  System.Generics.Collections, SysUtils, Classes, Tools, PangyaBuffer, ClientPacket, UWriteConsole, Enum, Defines, AnsiStrings;

type
  PIffAchievement = ^TIffAchievement;

  TIffAchievement = packed record
    var Achievement_Enable: UInt32;
    var Achievement_TypeID: UInt32;
    var Achievement_Name: AnsiString;
    var Achievement_QuestTypeID: UInt32;
  end;

  TIffAchievements = class
    private
      var FAchievementDB: TDictionary<UInt32, PIffAchievement>;
    public
      constructor Create;
      destructor Destroy; override;
  end;

  var
    Ach: TIffAchievements;

implementation

{ TIffAchievements }

constructor TIffAchievements.Create;
var
  Buffer : TMemoryStream;
  Data : AnsiString;
  Packet : TClientPacket;
  Total, Count , Index: UInt32;
  Achievement : PIffAchievement;
  FQuestTypeID, FQuestQAty: array[$0..$4] of Int32;
  FName: array[$0..$4] of AnsiString;
  Names: AnsiString;
  Ints, Enable, ACTYPEID: UInt32;

  Con : TFDConnection;
begin
  FAchievementDB := TDictionary<UInt32, PIffAchievement>.Create;

  if not FileExists('data\QuestItem.iff') then begin
    WriteConsole(' data\QuestItem.iff is not loaded');
    Exit;
  end;

  Buffer := TMemoryStream.Create;
  Buffer.LoadFromFile('data\QuestItem.iff');
  Data := MemoryStreamToString(Buffer);
  Buffer.Free;

  Packet := TClientPacket.Create(Data);
  Con := TFDConnection.Create(nil);
  Con.ConnectionDefName := 'MSSQLPool';
  try
    if not Packet.ReadUInt32(Total) then Exit;

    Packet.Skip(4);

    for Count := 1 to Total do
    begin
      //New(ClubInfo);
      Packet.ReadUInt32(Enable);
      Packet.ReadUInt32(ACTYPEID);
      //for Index := 0 to Length(FName)- 1 do
      //begin
        Packet.ReadStr(Names, $40);
        Names := Trim(Names);
        Packet.Skip($6C);
        //FName[Index] := Trim(Names);
        writeLn(names);

        Packet.ReadUInt32(Ints);

      packet.Skip($40);
      Con.ExecSQL('INSERT INTO [DBO].Achievement_QuestItem(TypeID,Name, QuestTypeID) VALUES(:B,:X,:Y)',
          [ACTYPEID, Names,Ints]);

      {Con.ExecSQL('INSERT INTO [DBO].Achievement_Counter_Data(Enable, Name, TypeID) VALUES(:A,:B,:C)',
          [Enable, Names, ACTYPEID] );}

      {for Index := 0 to Length(FQuestTypeID)- 1 do
      begin
        if FQuestTypeID[Index] > 0 then
        begin
          Con.ExecSQL('INSERT INTO [DBO].Achievement_QuestStuffs(Enable,TypeID, Name, CounterTypeID,CounterQuantity) VALUES(:B,:X,:Y,:Z,:G)',
          [Enable, ACTYPEID,Names, FQuestTypeID[Index], FQuestQAty[Index]] );
        end;
      end;}
    end;

  finally
    Packet.Free;
    Con.Free;
  end;
end;

destructor TIffAchievements.Destroy;
var
  Achievement : PIffAchievement;
begin
  for Achievement in FAchievementDB.Values do
  begin
    Dispose(Achievement);
  end;
  FAchievementDB.Clear;
  FAchievementDB.Free;
  inherited;
end;

end.
