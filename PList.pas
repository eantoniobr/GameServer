unit PList;

interface

uses
  MyList;

type
  TPointerList = class(TMyList<Pointer>)
    public
      procedure ClearPointer;
      constructor Create;
      destructor Destroy; override;
  end;

implementation

{ TPointerList }

procedure TPointerList.ClearPointer;
var
  PPointer: Pointer;
begin
  for PPointer in Self do
  begin
    Dispose(PPointer);
  end;
  Clear;
end;

constructor TPointerList.Create;
begin
  inherited Create;
end;

destructor TPointerList.Destroy;
begin
  ClearPointer;
  inherited;
end;

end.
