unit DatabasePooling;

interface

uses
  Data.DB, DBAccess, Uni, MySQLUniProvider;

type
  TDatabasePooling = class
    private
      var FConnection : TUniConnection;
    public
      constructor Create;
      destructor Destroy; override;
      property Connection : TUniConnection read FConnection write FConnection;
  end;

var
  DBPooling : TDatabasePooling;

implementation

{ TDatabasePooling }

constructor TDatabasePooling.Create;
begin
  FConnection := TUniConnection.Create(nil);
  FConnection.ProviderName := 'MySQL';
  FConnection.Server := 'localhost';
  FConnection.Username := 'pangya';
  FConnection.Password := '1';
  FConnection.Port := 3306;
  FConnection.Database := 'py_new';
  FConnection.LoginPrompt := False;
  FConnection.AutoCommit := True;
  FConnection.Pooling := True;
  FConnection.PoolingOptions.MinPoolSize := 10;
  FConnection.PoolingOptions.MaxPoolSize := 20;
  FConnection.SpecificOptions.Values['UseUnicode'] := 'True';
  FConnection.SpecificOptions.Values['Charset'] := 'UTF8';
  FConnection.Connect;
end;

destructor TDatabasePooling.Destroy;
begin
  FConnection.Free;
  inherited;
end;

end.
