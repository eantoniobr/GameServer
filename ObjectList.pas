unit ObjectList;

interface

uses
  MyList, System.SysUtils;

type
  TMyObject = class(TMyList<TObject>)
    public
      procedure ClearObj;
      constructor Create;
      destructor Destroy; override;
  end;

implementation

{ TPointerList }

procedure TMyObject.ClearObj;
var
  AObj: TObject;
begin
  for AObj in Self do
  begin
    if Assigned(AObj) then
    begin
      AObj.Free;
    end;
  end;
  Clear;
end;

constructor TMyObject.Create;
begin
  inherited Create;
end;

destructor TMyObject.Destroy;
begin
  ClearObj;
  inherited;
end;

end.
