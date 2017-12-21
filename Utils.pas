{*******************************************************}
{                                                       }
{       Pangya Server                                   }
{                                                       }
{       Copyright (C) 2015 Shad'o Soft tm               }
{                                                       }
{*******************************************************}

unit utils;

interface

uses
  Windows, SysUtils;

type
  TGeneric = class
    class function Iff<T>(const expression: Boolean; trueValue: T; falseValue: T): T; inline;
  end;

function GetDataFromfile(const filePath: string): AnsiString; overload;
function GetDataFromfile(const filePath: string; offset: UInt32): AnsiString; overload;
procedure WriteDataToFile(const filePath: string; const data: AnsiString);

implementation

function GetDataFromfile(const filePath: string): AnsiString;
var
  x: THandle;
  size: Integer;
  data: AnsiString;
begin
  x := fileopen(filepath, $40);
  size := fileseek(x, 0, 2);
  fileseek(x, 0, 0);
  setlength(data, size);
  fileread(x, data[1], size);
  fileclose(x);
  Exit(data);
end;

function GetDataFromfile(const filePath: string; offset: UInt32): AnsiString;
var
  x: THandle;
  size: Integer;
  data: AnsiString;
begin
  x := fileopen(filepath, $40);
  size := fileseek(x, 0, 2);
  fileseek(x, 0, 0);
  setlength(data, size);
  fileread(x, data[1], size);
  fileclose(x);
  delete(data, 1, offset);
  Exit(data);
end;

procedure WriteDataToFile(const filePath: string; const data: AnsiString);
var
  x: THandle;
  size: Integer;
begin
  x := FileCreate(filepath);
  size := Length(data);
  FileWrite(x, data[1], size);
  fileclose(x);
end;

class function TGeneric.Iff<T>(const expression: Boolean; trueValue: T; falseValue: T): T;
begin
  if (expression) then
  begin
    Exit(trueValue);
  end else
  begin
    Exit(falseValue);
  end;
end;

end.

