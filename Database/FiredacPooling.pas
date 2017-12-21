unit FiredacPooling;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Classes;

type
  TFireDacPooling = class
    private
      FManager : TFDManager;
    public
      constructor Create;
      destructor Destroy; override;
  end;

var
  DBPool : TFireDacPooling;

implementation

{ TFireDacPooling }

constructor TFireDacPooling.Create;
var
  Params: TStringList;
begin
  Params := TStringList.Create;
  try
    // oParams.Add('Server=DESKTOP-3RKGJ2M');
    //Params.Add('User_Name=sa');
    //Params.Add('Password=1');
    //Params.Add('Server=127.0.0.
    Params.Add('Server=DESKTOP-3RKGJ2M');
    Params.Add('OSAuthent=Yes');
    Params.Add('Database=Pangya');
    Params.Add('Pooled=True');
    Params.Add('POOL_MaximumItems=1000');

    FManager := TFDManager.Create(nil);
    FManager.AddConnectionDef('MSSQLPool', 'MSSQL', Params);

  finally
    Params.Free;
  end;
end;

destructor TFireDacPooling.Destroy;
begin
  FManager.Free;
  inherited;
end;

initialization
  DBPool := TFireDacPooling.Create;
finalization
  DBPool.Free;

end.
