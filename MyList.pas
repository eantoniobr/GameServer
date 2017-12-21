unit MyList;

interface

uses
  System.Generics.Collections, System.SyncObjs, System.Types;

type
  TMyList<T> = class(TList<T>)
    private
      FLock: TCriticalSection;
      FDuplicates: TDuplicates;
    public
      constructor Create;
      destructor Destroy; override;
      function Add(const Value: T): Integer;
      function Remove(const Value: T): Integer;
      function Contains(const Value: T): Boolean;
      function Count: Integer;
      property Duplicates: TDuplicates read FDuplicates write FDuplicates;
  end;

implementation

{ TMyList<T> }


function TMyList<T>.Add(const Value: T): Integer;
begin
  FLock.Acquire;
  try
    if (FDuplicates = dupAccept) or (Self.IndexOf(Value) = -1) then
    begin
      Result := inherited Add(Value);
    end
    else if FDuplicates = dupError then
    begin
      Exit;
    end;
  finally
    FLock.Release;
  end;
end;

function TMyList<T>.Remove(const Value: T): Integer;
begin
  FLock.Acquire;
  try
    Result := inherited Remove(Value);
  finally
    FLock.Release;
  end;
end;

function TMyList<T>.Contains(const Value: T): Boolean;
begin
  FLock.Acquire;
  try
    Result := inherited Contains(Value);
  finally
    FLock.Release;
  end;
end;

function TMyList<T>.Count: Integer;
begin
  FLock.Acquire;
  try
    Exit(inherited Count);
  finally
    FLock.Release;
  end;
end;

constructor TMyList<T>.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FDuplicates := dupIgnore;
end;

destructor TMyList<T>.Destroy;
begin
  FLock.Free;
  inherited;
end;

end.
