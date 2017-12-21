unit GameList;

interface

uses
  MyList, System.SysUtils, SerialID, GameBase, PangyaClient;

type
  TGameList = class
    private
      fGameList: TMyList<TGameBase>;
      fSerialID: TSerialID;
      procedure DestroyGame;
      function GetGame(GameID: UInt16): TGameBase; overload;
      function GetGame(Player: TClientPlayer): TGameBase; overload;
    public
      constructor Create;
      destructor Destroy; override;
      property GameHandle[GameID: UInt16]: TGameBase read GetGame; default;
      property GameHandle[Player: TClientPlayer]: TGameBase read GetGame; default;
      function GetGPID(ID: UInt32): TGameBase;
      function GetID: UInt32;
      procedure RemoveID(ID: UInt32);

      property Games: TMyList<TGameBase> read fGameList;
  end;


implementation

{ TGameList }

constructor TGameList.Create;
begin
  fGameList := TMyList<TGameBase>.Create;
  fSerialID := TSerialID.Create;
end;

destructor TGameList.Destroy;
begin
  Self.DestroyGame;
  FreeAndNil(fGameList);
  FreeAndNil(fSerialID);
  inherited;
end;

procedure TGameList.DestroyGame;
var
  G: TGameBase;
begin
  for G in fGameList do
    G.Free;
end;

function TGameList.GetGame(GameID: UInt16): TGameBase;
begin
  for Result in fGameList do
    if Result.ID = GameID then
      Exit;

  Exit(nil);
end;

function TGameList.GetGame(Player: TClientPlayer): TGameBase;
begin
  Exit(GetGame(Player.GameID));
end;

function TGameList.GetGPID(ID: UInt32): TGameBase;
begin
  for Result in Self.fGameList do
    if Result.GameData.GPTypeID = ID then
      Exit;

  Exit(nil);
end;

function TGameList.GetID: UInt32;
begin
  Exit(Self.fSerialID.GetId);
end;

procedure TGameList.RemoveID(ID: UInt32);
begin
  Self.fSerialID.RemoveId(ID);
end;

end.
