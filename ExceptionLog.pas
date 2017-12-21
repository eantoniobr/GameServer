unit ExceptionLog;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  System.SyncObjs;

type
  TExceptionLog = class
    private
      var FLock: TCriticalSection;
    public
      constructor Create;
      destructor Destroy; override;
      procedure SaveLog(UID: UInt32; Const Username, ExceptionMessage: AnsiString);
  end;

  var
    FException: TExceptionLog;

implementation

{ TExceptionLog }

constructor TExceptionLog.Create;
begin
  FLock := TCriticalSection.Create;
end;

destructor TExceptionLog.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TExceptionLog.SaveLog(UID: UInt32; const Username, ExceptionMessage: AnsiString);
var
  Query: TFDQuery;
  Con: TFDConnection;
begin
  FLock.Acquire;
  try
    Query := TFDQuery.Create(nil);
    Con := TFDConnection.Create(nil);
    try
      { ********** CON & STORE PROC CREATION ************ }
      Con.ConnectionDefName := 'MSSQLPool';
      Query.Connection := Con;
      Query.ExecSQL('EXEC [dbo].[ProcSaveExceptionLog] @UID = :UID, @USER = :USER, @EXCEPTIONMESSAGE = :EXPMSG, @SERVER = :ServerType',
        [UID, Username, ExceptionMessage, 'GameServer']);
      { ******************* END ************************* }
    finally
      Query.Free;
      Con.Free;
    end;
  finally
    FLock.Release;
  end;
end;

initialization
  begin
    FException := TExceptionLog.Create;
  end;

finalization
  begin
    FException.Free;
  end;

end.
