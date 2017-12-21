unit Tools;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Messages, SysUtils, DateUtils, Math , Classes, Graphics, System.Threading, PangyaBuffer,
  ClientPacket, Console, AnsiStrings, ListPair, Enum, PList, System.Generics.Collections,
  Windows, Defines;

Type
  TArray = Array of Integer;

  TServerTime = packed record
    var Year,Month,DayOfWeek,Day,Hour,Min,Sec,MilliSec: UInt16;
  end;

  TCompare = class
    class function IfCompare<T>(const Expression: Boolean; IfTrue, IfFalse: T): T; inline;
  end;

  procedure NullString(var StringVariable: AnsiString); inline;
  function GameTime: AnsiString; overload; inline;
  function GetFixTime(FixDateTime: TDateTime): AnsiString; inline;
  function GetSQLTime(DateTime: TDateTime): string; inline;
  function GetCaddieTypeIDBySkinID(SkinTypeID: UInt32): UInt32; inline;
  function GetItemGroup(TypeID: UInt32): UInt32; inline;
  function GetCardType(TypeID: UInt32): tCARDTYPE; inline;
  function GetAuxType(ID: UInt32): UInt8; inline;
  function GetZero(CharCount: UInt32): AnsiString; inline;
  function MemoryStreamToString(Data: TMemoryStream): AnsiString;
  function ShowHex(const txt : AnsiString) : AnsiString; inline;
  function Space(const txt: AnsiString): AnsiString; inline;
  function RandomChar(Count : Word; UpperInclude : Boolean = False): AnsiString; inline;
  function RandomAuth(Count : Word): AnsiString; inline;
  function AnsiFormat(const Format: AnsiString; const Args: array of const): AnsiString;
  function UnixTimeConvert(Val: TDateTime): UInt32;
  function IsTimeNull(Val: TDateTime): TDateTime;
  procedure PairClear(var Pair: TPairs<PAchievementData, TPointerList>);
  procedure PairFree(var Pair: TPairs<PAchievementData, TPointerList>);
  function CreateGPDateTime(Hour, Min: Word): TDateTime;
  function GenerateArray(Min, Max: Integer; ArraySize: Integer): TArray;
  function GenerateIntArray(Max: UInt32; ArraySize: Integer): TArray;
  function GetTick: UInt32;
  procedure CreateQuery(var Query: TFDQuery; var Connection: TFDConnection; AutoClose: Boolean = True);
  procedure FreeQuery(const Query: TFDQuery; const Connection: TFDConnection);
  procedure QueryNextSet(const Query: TFDQuery);
  function IsUCCNull(const UNIQUE, IfNull: AnsiString): AnsiString;
  procedure SwapX(var lhs, rhs: Integer);
  function RandomHole: THole18;
  function RandomMap: TMap19;
  function GetMap: UInt16;

implementation

{ TTool }

function GameTime: AnsiString;
var
  CurrentDate : TDateTime;
  ServerTime: TServerTime;
begin
  CurrentDate := Now;

  with ServerTime do
  begin
    Year        := StrToInt(ForMatDateTime('yyyy',CurrentDate));
    Month       := StrToInt(ForMatDateTime('m',CurrentDate));
    DayOfWeek   := DayOfTheWeek(CurrentDate);
    Day         := StrToInt(ForMatDateTime('d',CurrentDate));
    Hour        := StrToInt(ForMatDateTime('h',CurrentDate));
    Min         := StrToInt(ForMatDateTime('n',CurrentDate));
    Sec         := StrToInt(ForMatDateTime('s',CurrentDate));
    MilliSec    := StrToInt(ForMatDateTime('z',CurrentDate));
  end;

  SetLength(Result , SizeOf(TServerTime));
  Move(ServerTime.Year, Result[1], SizeOf(TServerTime));
  Exit(Result);
end;

function GetSQLTime(DateTime: TDateTime): string;
var
  Date,Time: string;
  StringBuilder: TStringBuilder;
begin
  DateTimeToString(Date, 'yyyy-mm-dd', DateTime);
  DateTimeToString(Time, 'hh:nn:ss', DateTime);

  StringBuilder := TStringBuilder.Create;
  try
    StringBuilder.Append(Date);
    StringBuilder.Append('T');
    StringBuilder.Append(Time);
    Exit(StringBuilder.ToString);
  finally
    StringBuilder.Free;
  end;
end;

function MemoryStreamToString(Data: TMemoryStream): AnsiString;
begin
  SetString(Result, PAnsiChar(Data.Memory), Data.Size);
end;

procedure NullString(var StringVariable: AnsiString);
begin
  StringVariable := '';
end;

function Space(const txt: AnsiString): AnsiString;
var
  i: Integer;
begin
  i := 3;
  Result := Copy(txt, 0, 2);
  while i <= Length(txt) do
  begin
    Result := result + ' ' + Copy(txt, i, 2);
    i := i + 2;
  end;
end;

function ShowHex(const txt: AnsiString): AnsiString;
var
  a : integer ;
  st : TStringStream;
  buf : array [0..1] of AnsiChar;
  tmp : ShortString;
begin
  st := TStringStream.Create;
  st.Size := Length(txt)*2;
  st.Position := 0;
  for a:=1 to Length(txt) do
  begin
    tmp := ShortString(IntToHex(Ord(txt[a]),2));
    buf[0] := tmp[1];
    buf[1] := tmp[2];
    st.Write(buf,2);
  end;
  st.Position := 0;
  Result := Space(AnsiString(st.DataString));
  st.Free;
end;

function GetCardType(TypeID: UInt32): tCARDTYPE; inline;
begin
  if Round((TypeID and $FF000000) / Power(2,24)) = $7C then
    Exit( tCardType(Round((TypeID and $00FF0000) / Power(2,16))) );

  if Round((TypeID and $FF000000) / Power(2,24)) = $7D then
    if Round((TypeID and $00FF0000) / Power(2,16)) = $40 then
      Exit(tCardType(tNPC));
end;

function GetItemGroup(TypeID : UInt32): UInt32;
begin
  Exit(Round((TypeID and 4227858432) / Power(2,26)));
end;

function GetAuxType(ID: UInt32): UInt8; inline;
begin
  Exit(Round((ID and $001f0000) / Power(2, 16)));
end;

function GetCaddieTypeIDBySkinID(SkinTypeID: UInt32): UInt32;
var
  CaddieTypeID: UInt32;
begin
  CaddieTypeID := Round( ( (SkinTypeId AND $0FFF0000) SHR 16 ) / 32 );
  Result := (CaddieTypeID + $1C000000) + ((SkinTypeID AND $000F0000) SHR 16);
end;

function RandomAuth(Count: Word): AnsiString;
var
  Str: AnsiString;
begin
  Randomize;
  Str    := 'abcdefg1234567890';
  Result := '';
  repeat
    Result := Result + Str[Random(Length(Str)) + 1];
  until (Length(Result) = Count)

end;

function RandomChar(Count: Word; UpperInclude : Boolean = False): AnsiString;
var
  Str: AnsiString;
begin
  Randomize;
  Str    := 'abcdefghijklmnopqrstuvwxyz0123456789';
  if UpperInclude then
    Str := Str + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  Result := '';
  repeat
    Result := Result + Str[Random(Length(Str)) + 1];
  until (Length(Result) = Count)
end;

function GetZero(CharCount: UInt32): AnsiString;
var
  Index: UInt32;
  StringBuilder: TStringBuilder;
begin
  StringBuilder := TStringBuilder.Create;
  try
    Index := 1;
    repeat
      StringBuilder.Append(#$00);
      Inc(Index);
    until Index > UInt32(CharCount);
    Exit(AnsiString(StringBuilder.ToString));
  finally
    StringBuilder.Free;
  end;
end;

function GetFixTime(FixDateTime: TDateTime): AnsiString;
var
  ServerTime: TServerTime;
begin
  if FixDateTime = 0 then
  begin
    Exit(GetZero($10));
  end;

  if IsZero(Date) then
  begin
    Exit(GetZero($10));
  end;

  with ServerTime do
  begin
    Year      := StrToInt(ForMatDateTime('yyyy', FixDateTime));
    Month     := StrToInt(ForMatDateTime('m', FixDateTime));
    DayOfWeek := DayOfTheWeek(FixDateTime);
    Day       := StrToInt(ForMatDateTime('d', FixDateTime));
    Hour      := StrToInt(ForMatDateTime('h', FixDateTime));
    Min       := StrToInt(ForMatDateTime('n', FixDateTime));
    Sec       := StrToInt(ForMatDateTime('s', FixDateTime));
    MilliSec  := StrToInt(ForMatDateTime('z', FixDateTime));
  end;

  SetLength(Result , SizeOf(TServerTime));
  Move(ServerTime.Year, Result[1], SizeOf(TServerTime));
  Exit(Result);
end;

function AnsiFormat(const Format: AnsiString; const Args: array of const): AnsiString;
begin
  Exit(AnsiStrings.Format(Format, Args));
end;

function UnixTimeConvert(Val: TDateTime): UInt32;
begin
  if IsZero(Val) then
  begin
    Exit(0);
  end;
  Exit(DateTimeToUnix(Val, False));
end;

function IsTimeNull(Val: TDateTime): TDateTime;
begin
  if IsZero(Val) then
  begin
    Exit(0);
  end;
  Exit(Val);
end;

procedure PairClear(var Pair: TPairs<PAchievementData, TPointerList>);
var
  Item: TPair<PAchievementData, TPointerList>;
begin
  for Item in Pair do
  begin
    Dispose(Item.Key);
    Item.Value.Free;
  end;
  Pair.Clear;
end;

procedure PairFree(var Pair: TPairs<PAchievementData, TPointerList>);
var
  Item: TPair<PAchievementData, TPointerList>;
begin
  for Item in Pair do
  begin
    Dispose(Item.Key);
    Item.Value.Free;
  end;
  Pair.Clear;
  FreeAndNil(Pair);
end;

function CreateGPDateTime(Hour, Min: Word): TDateTime;
var
  FYear, FMonth, FDay, FHour, FMin, FSec, FMSec: Word;
begin
  DecodeDateTime(Now, FYear, FMonth, FDay, FHour, FMin, FSec, FMSec);

  Result := EncodeDateTime(FYear, FMonth, FDay, Hour, Min, 0, 0);

  Exit(Result);
end;

function GenerateArray(Min, Max: Integer; ArraySize: Integer): TArray;
var
  I, FMax: Integer;
begin
  Randomize;
  // ## first set the length of result
  SetLength(Result, ArraySize);
  // ## get the random to all arrays
  for I := 0 to Length(Result) - 1 do
    Result[I] := RandomRange(-2, (5+1));

  FMax := RandomRange(Min, (Max+1));

  // ## check the sum, should not more than Max
  while True do
  begin
    if (SumInt(Result) > FMax) then
    begin
      I := RandomRange(0, Length(Result));

      if (Result[I] >= -1) and (Result[I] <= 5) then
        Dec(Result[I]);
    end else if (SumInt(Result) < Min) then begin
      I := RandomRange(0, Length(Result));

      if (Result[I] >= -2) and (Result[I] <= 4) then
        Inc(Result[I]);
    end else begin
      Break;
    end;
  end;

  // ## exit the result
  Exit(Result);
end;

function GenerateIntArray(Max: UInt32; ArraySize: Integer): TArray;
var
  I: Integer;
begin
  Randomize;
  // ## first set the length of result
  SetLength(Result, ArraySize);
  // ## get the random to all arrays
  for I := 0 to Length(Result) - 1 do
    Result[I] := RandomRange(1, (Max));

  while True do
  begin
    if (SumInt(Result) > Max ) then
    begin
      I := RandomRange(0, Length(Result));

      if Result[I] > 0 then
        Dec(Result[I]);
    end else begin
      Break;
    end;
  end;
  Exit(Result);
end;

procedure SwapX(var lhs, rhs: Integer);
var
  tmp: Integer;
begin
  tmp := lhs;
  lhs := rhs;
  rhs := tmp;
end;

function RandomHole: THole18;
var
  I: Integer;
  Values: THole18;
begin
  Values := _THole18;
  for I := 0 to High(Result) do
    SwapX(Values[I], Values[I + Random(Length(Values)-I)]);

  Exit(Values);
end;

function RandomMap: TMap19;
var
  I: Integer;
  Values: TMap19;
begin
  Values := _TMap19;
  for I := 0 to High(Result) do
    SwapX(Values[I], Values[I + Random(Length(Values)-I)]);

  Exit(Values);
end;

procedure CreateQuery(var Query: TFDQuery; var Connection: TFDConnection; AutoClose: Boolean = True);
begin
  Query := TFDQuery.Create(nil);
  Connection := TFDConnection.Create(nil);
  Connection.ConnectionDefName := 'MSSQLPool';
  Query.Connection := Connection;
  Query.FetchOptions.AutoClose := AutoClose;
end;

procedure FreeQuery(const Query: TFDQuery; const Connection: TFDConnection);
begin
  Query.Free;
  Connection.Free;
end;

procedure QueryNextSet(const Query: TFDQuery);
begin
  Query.NextRecordSet;
  Query.FetchAll;
end;

function GetTick: UInt32;
begin
  Exit(Gettickcount());
end;

function IsUCCNull(const UNIQUE, IfNull: AnsiString): AnsiString;
begin
  if Length(UNIQUE) <= 0 then
  begin
    Exit(IfNull);
  end;
  Exit(UNIQUE);
end;

function GetMap: UInt16;
var
  Map: TMap19;
  I, S: UInt8;
  A, B: UInt8;
begin
  Randomize;

  Map := _TMap19;

  for I := 0 to Length(_TMap19)-1 do
  begin
    S := Random(Length(_TMap19));
    A := Map[S]; { position to switch }
    B := Map[I]; { position switch to }

    Map[I] := A;
    Map[S] := B;
  end;
  Exit(Map[Random(Length(Map))]);
end;

{ TCompare }

class function TCompare.IfCompare<T>(const Expression: Boolean; IfTrue, IfFalse: T): T;
begin
  if (Expression) then
  begin
    Exit(IfTrue);
  end;
  Exit(IfFalse);
end;

end.
