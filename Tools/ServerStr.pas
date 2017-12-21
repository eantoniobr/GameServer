unit ServerStr;

interface

uses
  System.Classes;

type
  TServerString = class
    private
      var ListStr: TStringList;
    public
      function GetText(SectionName: String): AnsiString;
      constructor Create;
      destructor Destroy; override;
  end;

var
  ReadString: TServerString;

implementation

{ TServerString }

constructor TServerString.Create;
begin
  ListStr := TStringList.Create;
  with ListStr do
  begin
    LoadFromFile('string.txt');
  end;
end;

destructor TServerString.Destroy;
begin
  ListStr.Free;
  inherited;
end;

function TServerString.GetText(SectionName: String): AnsiString;
begin
  Exit(AnsiString(ListStr.Values[SectionName]));
end;

initialization
  begin
    ReadString := TServerString.Create;
  end;

finalization
  begin
    ReadString.Free;
  end;

end.
