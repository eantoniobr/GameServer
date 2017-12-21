unit Enum;

interface

uses
  uAction, Defines, DateUtils, System.Math.Vectors;

type

  TStatusArray = array[$0..$4] of UInt8;
  TClubStatus = packed record
    var Power,Control,Impact,Spin,Curve: UInt16;
    var ClubType: ECLUBTYPE;
    var ClubSPoint: UInt8;
    function GetClubTotal(ClubPlayerData: TClubStatus; IsRankUp: Boolean): Integer;
    function GetClubPlayer(ClubPlayerData: TClubStatus): TClubStatus;
    function GetClubArray: TStatusArray;
    class operator Subtract(X,Y: TClubStatus): TClubStatus;
    class operator Add(X,Y: TClubStatus): TClubStatus;
  end;

  TClubUpgradeData = record
    var Able: Boolean;
    var Pang: UInt32;
  end;

  TClubUpgradeTemporary = packed record
    var PClub: Pointer;
    var UpgradeType: ShortInt;
    var Count: UInt8;
    procedure Clear;
  end;

  TClubUpgradeRank = packed record
    var ClubPoint: UInt32;
    var ClubSPoint: UInt8;
    var ClubCurrentRank: UInt8;
    var ClubSlotLeft: TClubStatus;
  end;

  TBuyItem = packed record
    var Flag: UInt8;
    var DayTotal: UInt16;
    var EndDate: TDateTime;
  end;

  TPlayerGuildData = packed record
    var GuildID: UInt32;
    var GuildName: AnsiString;
    var GuildPosition: UInt8;
    var GuildImage: AnsiString;
  end;

  {PAchievementCounter = ^TAchievementCounter;
  TAchievementCounter = packed record
    var CounterID: UInt32;
    var CounterTypeID: UInt32;
    var CounterOldQty: UInt32;
    var CounterNewQty: UInt32;
    var CounterToAdd: UInt32;
  end;}

  PAchievementTrigger = ^TAchievementTrigger;
  TAchievementTrigger = packed record
    var AchievementTypeID: UInt32;
    var AchievementQuestTypeID: UInt32;
  end;


  TStatistic = packed record
    var Drive: UInt32;
    var Putt: UInt32;
    var PlayTime: UInt32; // Second
    var ShotTime: UInt32;
    var LongestDistance: Single;
    var Pangya: UInt32;
    var TimeOut: UInt32;
    var OB: UInt32;
    var DistanceTotal: UInt32;
    var Hole: UInt32;
    var TeamHole: UInt32;
    var HIO: UInt32;
    var Bunker: UInt16;
    var Fairway: UInt32;
    var Albratoss: UInt32;
    var Holein: UInt32;
    var Puttin: UInt32;
    var LongestPutt: Single;
    var LongestChip: Single;
    var EXP: UInt32;
    var Level: UInt8;
    var Pang: UInt64;
    var TotalScore: UInt32;
    var Score: Array[$0..$4] of Int8;
    var Unknown: UInt8;
    var MaxPang0: UInt64;
    var MaxPang1: UInt64;
    var MaxPang2: UInt64;
    var MaxPang3: UInt64;
    var MaxPang4: UInt64;
    var SumPang: UInt64;
    var GamePlayed: UInt32;
    var Disconnected: UInt32;
    var TeamWin: UInt32;
    var TeamGame: UInt32;
    var LadderPoint: UInt32;
    var LadderWin: UInt32;
    var LadderLose: UInt32;
    var LadderDraw: UInt32;
    var LadderHole: UInt32;
    var ComboCount: UInt32;
    var MaxCombo: UInt32;
    var NoMannerGameCount: UInt32;
    var SkinsPang: UInt64;
    var SkinsWin: UInt32;
    var SkinsLose: UInt32;
    var SkinsRunHole: UInt32;
    var SkinsStrikePoint: UInt32;
    var SKinsAllinCount: UInt32;
    var Unknown1: Array[$0..$5] of AnsiChar;
    var GameCountSeason: UInt32;
    var Unknown2: Array[$0..7] of AnsiChar;
    class operator Add(Left, Right: TStatistic): TStatistic;
  end;

  TMatchData = packed record
    var StartTime: TDateTime;
  end;

  PAchievementData = ^TAchievementData;
  TAchievementData = packed record
    var AchID: UInt32;
    var AchTypeID: UInt32;
  end;

  PAchievementQuestData = ^TAchievementQuestData;
  TAchievementQuestData = packed record
    var AchID: UInt32;
    var AchTypeID: UInt32;
    var AchQuestTypeID: UInt32;
    var CounterTypeID: UInt32;
    var CounterID: UInt32;
    var CounterQty: UInt32;
    var SuccessDate: UInt32;
    var SuccessQty: UInt32;
  end;

  PItemData = ^TItemData;
  TItemData = packed record
    var TypeID: UInt32;
    var ItemIndex: UInt32;
    var ItemQuantity: UInt32;
  end;

  TTransacItem = class
    public
      var Types: UInt8;
      var TypeID: UInt32;
      var Index: UInt32;
      var PreviousQuan: UInt32;
      var NewQuan: UInt32;
      var DayStart: TDateTime; // As Unix Datetime
      var DayEnd: TDateTime; // As Unix Datetime
      var UCC: AnsiString;
      var UCCStatus: UInt8;
      var UCCCopyCount: UInt8;
      var C0_SLOT: UInt16;
      var C1_SLOT: UInt16;
      var C2_SLOT: UInt16;
      var C3_SLOT: UInt16;
      var C4_SLOT: UInt16;
      var ClubPoint: UInt32;
      var WorkshopCount: UInt32;
      var CancelledCount: UInt32;
      var CardTypeID: UInt32;
      var CharSlot: UInt8;
      constructor Create;
      destructor Destroy; override;
  end;

  TGolfData = packed record
    var BallTypeID: UInt32;
    var ClubIndex: UInt32;
  end;

  PScore = ^TScore;
  TScore = packed record
    var Score: Integer;
    var Pang: UInt32;
    var BonusPang: UInt32;
  end;

  // ## this must be a class casuse we need reference
  TVSMatch = class
    var Team: TTEAM_VERSUS;
    var Distance: Single;
    var HolePos3D: TPoint3D;
    var WinCount: UInt16;
    var CountPlayer: UInt8;
    var Pang: UInt32;
    var BonusPang: UInt32;
    procedure Clear;
  end;

  TVSData = packed record
    var HoleComplete: Boolean;
    var HoleCompletedCount: UInt8;
    var PlayingConnectionID: UInt32;
    var PlayerBarMoving: Boolean;
    var GameEnd: Integer;
    var GamePauseTime: Integer;
    var RedTeam: TVSMatch;
    var BlueTeam: TVSMatch;
    procedure Init;
    procedure IncCompleted;
  end;

  TWindInformation = packed record
    var WindPower: UInt16;
    var WindDirection: UInt16;
  end;

  TGameHoleInfo = class
    public
      var Hole: UInt8;
      var Weather: UInt8;
      var WindPower: UInt16;
      var WindDirection: UInt16;
      var Map: UInt8;
      var Pos: UInt8;
      var Wind: TWindInformation; // TODO: Delete Soon
  end;

  TShopItemRequest = packed record
  var
    UN1: UInt32;
    IffTypeId: UInt32;
    IffDay: UInt16;
    UN2: UInt16;
    IffQty: UInt32;
    PangPrice: UInt32;
    CookiePrice: UInt32;
  end;

  TBaseIff = packed record
    var Enabled: UInt32;
    var TypeID: UInt32;
    var Name: array[$0..$27] of AnsiChar;
    var MinLevel: UInt8;
    var Preview: array[$0..$27] of AnsiChar;
    var Un1: array[$0..$2] of AnsiChar;
    var ItemPrice: UInt32;
    var DiscountPrice: UInt32;
    var UsedPrice: UInt32;
    var PriceType: UInt8;
    var ItemFlag: UInt8;
    var TimeFlag: UInt8;
    var Timing: UInt8;
    var TPItem: UInt32;
    var TPCount: UInt32;
    var Mileage: UInt16;
    var BonusProb: UInt16;
    var Mileage2: UInt16;
    var Mileage3: UInt16;
    var TikiPointShop: UInt32;
    var TikiPang: UInt32;
    var ActiveDate: UInt32;
    var DateStart: array[$0..$F] of AnsiChar;
    var DateEnd: array[$0..$F] of AnsiChar;
  end;

  PAchievement = ^TAchievement;
  TAchievement = packed record
    var ID: UInt32;
    var TypeID: UInt32;
    var AchievementType: UInt8;
  end;

  PAchievementCounter = ^TAchievementCounter;
  TAchievementCounter = packed record
    var ID: UInt32;
    var TypeID: UInt32;
    var Quantity: UInt32;
  end;

  PAchievementQuest = ^TAchievementQuest;
  TAchievementQuest = packed record
    var ID: UInt32;
    Var AchievementIndex: UInt32;
    var AchievementTypeID: UInt32;
    var CounterIndex: UInt32;
    var SuccessDate: UInt32; // as timestamp
    var Total: UInt32;
  end;

  TShotData = packed record
    ConnectionId: UInt32;
    Vector: TPoint3D;
    ShotType: TShotType;
    Unknown1: array [0..1] of AnsiChar;
    Pang: UInt32;
    BonusPang: UInt32;
    Unknown2: array [0..3] of AnsiChar;
    MatchData: array [0..5] of AnsiChar;
    Unknown3: array [0..$10] of AnsiChar;
  end;

  PCardEquip = ^TCardEquip;
  TCardEquip = packed record
    var ID: UInt32;
    var CID: UInt32;
    var CHAR_TYPEID: UInt32;
    var CARD_TYPEID: UInt32;
    var SLOT: Byte;
    var FLAG: Byte;
    VAR REGDATE: TDateTime;
    var ENDDATE: TDateTime;
    var VALID: Byte;
    var NEEDUPDATE: Boolean;
  end;

  TGameReward = record
    var BestRecovery: Boolean;
    var BestChipIn: Boolean;
    var BestDrive: Boolean;
    var BestSpeeder: Boolean;
    var BestLongPutt: Boolean;
    var Lucky: Boolean;
    procedure Initial;
  end;

  PGameData = ^TGameData;
  TGameData = record
    var Pang: UInt32;
    var BonusPang: UInt32;
    var Score: ShortInt;
    var ParCount: ShortInt;
    var ShotCount: ShortInt;
    var TotalShot: UInt16;
    var HoleComplete: Boolean;
    var HoleCompletedCount: UInt8;
    var Statistic: TStatistic;
    var Rate: UInt8;
    var EXP: UInt32;
    var Reward: TGameReward;
    var Quited: Boolean;
    procedure Reverse;
    procedure Initial;
  end;

  TVersusData = record
    var LoadHole: Boolean;
    var LoadAnimation: Boolean;
    var ShotSync: Boolean;
    var HoleDistance: Single;
    var Team: TVSMatch;
    var LastHit: UInt32; { as timestamp }
    var LastScore: ShortInt; { shortint because variable need to be negative }
  end;

  PPGameData = ^TPGameData;
  TPGameData = packed record
    var ConnectionID: UInt32;
    var UID: UInt32;
    var GameSlot: UInt8;
    var Role: UInt8;
    var GameReady: Boolean;
    var Versus: TVersusData;
    var GameCompleted: Boolean;
    var HolePos3D: TPoint3D;
    var HolePos: UInt32;
    var Action: TPlayerAction;
    var GameData: TGameData;
    procedure SetDefault;
    procedure AddWalk(const Vector: TPoint3D);
    procedure UpdateScore(Success: Boolean);
  end;

  TGameInfo = packed record
    var Unknown1: UInt8;
    var VSTime: UInt32;
    var GameTime: UInt32;
    var MaxPlayer: UInt8;
    var GameType: TGAME_TYPE;
    var HoleTotal: UInt8;
    var Map: UInt8;
    var Mode: UInt8;
    var GMEvent: Boolean;
    { Hole Repeater }
    var HoleNumber: UInt8;
    var LockHole: UInt32;
    { Natural }
    var NaturalMode: UInt32;
    { Game Data }
    var Name: AnsiString;
    var Password: AnsiString;
    var Artifact: UInt32;
    { Grandprix }
    var GP: Boolean;
    var GPTypeID: UInt32;
    var GPTypeIDA: UInt32;
    var GPTime: UInt32;
    var GPStart: TDateTime;
  end;

  TPCards = packed record
    var Card: array[$1..$A] of UInt32;
    procedure Default;
  end;

type
  THole18 = array [0 .. 17] of Integer;
  TMap19 = array [0 .. 18] of Integer;

const
  _THole18: THole18 = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18);
  _TMap19: TMap19 = ($14, $12, $13, $10, $0F, $0E, $0D, $0B, $08, $0A, $00, $01, $02, $03, $04, $05, $06, $07, $09);


implementation

uses
  uWarehouse;

{ TClubStatus }

function TClubStatus.GetClubArray: TStatusArray;
begin
  Result[0] := Power;
  Result[1] := Control;
  Result[2] := Impact;
  Result[3] := Spin;
  Result[4] := Curve;
end;

function TClubStatus.GetClubPlayer(ClubPlayerData: TClubStatus): TClubStatus;
begin
  Result := Self + ClubPlayerData;
end;

function TClubStatus.GetClubTotal(ClubPlayerData: TClubStatus; IsRankUp: Boolean): Integer;
begin
  Result := (
    Power +
    Control +
    Impact +
    Spin +
    Curve +
    ClubPlayerData.Power +
    ClubPlayerData.Control +
    ClubPlayerData.Impact +
    ClubPlayerData.Spin +
    ClubPlayerData.Curve
  );
  if IsRankUp then
  begin
    Inc(Result, 1);
  end;
  Exit(Result);
end;

class operator TClubStatus.Subtract(X, Y: TClubStatus): TClubStatus;
begin
  Result.Power := X.Power - Y.Power;
  Result.Control := X.Control - Y.Control;
  Result.Impact := X.Impact - Y.Impact;
  Result.Spin := X.Spin - Y.Spin;
  Result.Curve := X.Curve - Y.Curve;
end;

class operator TClubStatus.Add(X, Y: TClubStatus): TClubStatus;
begin
  Result.Power := X.Power + Y.Power;
  Result.Control := X.Control + Y.Control;
  Result.Impact := X.Impact + Y.Impact;
  Result.Spin := X.Spin + Y.Spin;
  Result.Curve := X.Curve + Y.Curve;
end;

{ TClubUpgradeTemporary }

procedure TClubUpgradeTemporary.Clear;
begin
  PClub := nil;
  UpgradeType := -1;
end;

{ TUserStatistic }

class operator TStatistic.Add(Left, Right: TStatistic): TStatistic;
begin
  { Drive }
  Result.Drive := Left.Drive + Right.Drive;
  { Putt}
  Result.Putt := Left.Putt + Right.Putt;
  { Player Time Do Nothing }
  Result.PlayTime := Left.PlayTime;
  { Shot Time }
  Result.ShotTime := Left.ShotTime + Right.ShotTime;
  { Longest }
  if Right.LongestDistance > Left.LongestDistance then
    Result.LongestDistance := Right.LongestDistance
  else
    Result.LongestDistance := Left.LongestDistance;
  { Hit Pangya }
  Result.Pangya := Left.Pangya + Right.Pangya;
  { Timeout }
  Result.TimeOut := Left.TimeOut;
  { OB }
  Result.OB := Left.OB + Right.OB;
  { Total Distance }
  Result.DistanceTotal := Left.DistanceTotal + Right.DistanceTotal;
  { Hole Total }
  Result.Hole := Left.Hole + Right.Hole;
  { Team Hole }
  Result.TeamHole := Left.TeamHole;
  { Hole In One }
  Result.HIO := Left.HIO;
  { Bunker }
  Result.Bunker := Left.Bunker + Right.Bunker;
  { Fairway }
  Result.Fairway := Left.Fairway + Right.Fairway;
  { Albratoss }
  Result.Albratoss := Left.Albratoss + Right.Albratoss;
  { Holein ? }
  Result.Holein := Left.Holein + (Result.Hole - Right.Holein);
  { Puttin }
  Result.Puttin := Left.Puttin + Right.Puttin;
  { Longest Putt }
  if Right.LongestPutt > Left.LongestPutt then
    Result.LongestPutt := Right.LongestPutt
  else
    Result.LongestPutt := Left.LongestPutt;
  { Longest Chip }
  if Right.LongestChip > Left.LongestChip then
    Result.LongestChip := Right.LongestChip
  else
    Result.LongestChip := Left.LongestChip;
end;


{ TTransacItem }

constructor TTransacItem.Create;
var
  DefaultDate: TDateTime;
begin
  DefaultDate := EncodeDateTime(1899, 12, 30, 0, 0, 0, 0);
  Self.DayStart := DefaultDate;
  Self.DayEnd := DefaultDate;
end;

destructor TTransacItem.Destroy;
begin

  inherited;
end;

{ TVersusData }

procedure TVSData.IncCompleted;
begin
  Inc(HoleCompletedCount, 1);
end;

procedure TVSData.Init;
begin
  Self.HoleComplete := False;
  Self.HoleCompletedCount := 0;
  Self.PlayingConnectionID := 0;
  Self.PlayerBarMoving := False;
  Self.GameEnd := 0;
  Self.GamePauseTime := 0;
  Self.RedTeam.Clear;
  Self.BlueTeam.Clear;
end;

{ TVSMatch }

procedure TVSMatch.Clear;
begin
  Self.Distance := 99999999;
  with Self.HolePos3D do
  begin
    X := 0;
    Y := 0;
    Z := 0;
  end;
  Self.WinCount := 0;
  CountPlayer := 0;
  Pang := 0;
  BonusPang := 0;
end;

{ TPCards }

procedure TPCards.Default;
var
  C: UInt32;
begin
  for C := 1 to 10 do
    Self.Card[C] := 0;
end;

{ TPGameData }

procedure TPGameData.AddWalk(const Vector: TPoint3D);
begin
  Self.Action.Vector.X := Self.Action.Vector.X + Vector.X;
  Self.Action.Vector.Y := Self.Action.Vector.Y + Vector.Y;
  Self.Action.Vector.Z := Vector.Z;
end;

procedure TPGameData.SetDefault;
begin
  Self.GameSlot := 0;
  Self.Role := 0;
  Self.GameReady := False;
  Self.HolePos := 0;
  Self.Versus.LoadHole := False;
  Self.Versus.LoadAnimation := False;
  Self.Versus.ShotSync := False;
  Self.Versus.HoleDistance := 0;
  Self.Versus.LastHit := 0;
  Self.Versus.LastScore := 0;
  Self.GameCompleted := False;
  Self.ConnectionID := 0;
  Self.UID := 0;

  Self.GameData.Initial;
  Self.Action.Clear;
end;

procedure TPGameData.UpdateScore(Success: Boolean);
var
  S: ShortInt;
begin
  if not Success then
    S := 5
  else
    S := Self.GameData.ShotCount - Self.GameData.ParCount;

  Self.Versus.LastScore := S;
  Self.GameData.Score := Self.GameData.Score + S;
end;

{ TGameData }

procedure TGameData.Initial;
begin
  Self.Pang := 0;
  Self.BonusPang := 0;
  Self.Score := 0;
  Self.ParCount := 0;
  Self.ShotCount := 0;
  Self.TotalShot := 0; { Total shot default is 1 }
  Self.EXP := 0;
  Self.HoleComplete := False;
  Self.HoleCompletedCount := 0;
  Self.Reward.Initial;
  Self.Quited := False;
  Self.Rate := 0;
end;

procedure TGameData.Reverse;
begin
  Self.Initial;
end;

{ TGameReward }

procedure TGameReward.Initial;
begin
  Self.BestRecovery := False;
  Self.BestChipIn := False;
  Self.BestDrive := False;
  Self.BestSpeeder := False;
  Self.BestLongPutt := False;
  Self.Lucky := False;
end;

end.
