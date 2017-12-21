unit PlayersList;

interface

uses
  PangyaClient, SysUtils, MyList;

type
  TPlayersList = class (TMyList<TClientPlayer>)
    public
      constructor Create;
      destructor Destroy; override;
      function GetByConnectionId(connectionId: UInt32): TClientPlayer;
      function GetById(Id: UInt32): TClientPlayer;
  end;

implementation


constructor TPlayersList.Create;
begin
  inherited;
end;

destructor TPlayersList.Destroy;
begin
  inherited;
end;

function TPlayersList.GetByConnectionId(connectionId: UInt32): TClientPlayer;
var
  gameClient: TClientPlayer;
begin
  for gameClient in self do
  begin
    if gameClient.connectionId = connectionId then
    begin
      Exit(gameClient);
    end;
  end;
  Exit(nil);
end;

function TPlayersList.GetById(Id: UInt32): TClientPlayer;
var
  gameClient: TClientPlayer;
begin
  for gameClient in self do
  begin
    if gameClient.GetUID = id then
    begin
      Exit(gameClient);
    end;
  end;
  Exit(nil);
end;

end.

