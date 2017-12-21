unit GameExpTable;

interface

uses
  System.StrUtils, System.SysUtils, System.Types, Enum, Defines, System.Generics.Collections, XSuperObject;

type
  TExpTable = class
    private
      function GetDifficulty(Map: UInt8): UInt8;
    public
      constructor Create;
      destructor Destroy; override;
      function GetEXP(GameType: TGAME_TYPE; Map, Rank: UInt8; SumPlayer, SumHole: UInt8): UInt8;
  end;

var
  GameEXP: TExpTable;

implementation

{ TExpTable }

{ $0 = Blue Lagoon 1 Star }
{ $E = Ice Spa 1 Star }
{ $F = Last Seaway 1 Star}
{ $B = Pink Wind 1 Star}
{ $5 = West Wiz 1 Star}

{ $8 = Ice Cannon 2 Stars}
{ $A = Shining Sand 2 Stars}
{ $10 = Eastern Valley 2 Stars}
{ $13 = Wiz City 2 Stars}
{ $14 = Aboot Mine 2 Stars}

{ $6 = Blue Moon 3 Stars}
{ $1 = Blue Water 3 Stars}
{ $2 = Sepia Wind 3 Stars}
{ $9 = White Wiz 3 Stars}

{ $7 = Silvia Canon 4 Stars}
{ $4 = WizWiz 4 Stars}
{ $12 = Ice Inferno 4 Stars}

{ $D = Deep Inferno 5 Stars}
{ $3 = Wind Hill 6 Stars}

constructor TExpTable.Create;
begin
  inherited;

end;

destructor TExpTable.Destroy;
begin

  inherited;
end;

function TExpTable.GetDifficulty(Map: UInt8): UInt8;
begin
  case Map of
    $0, $E, $F, $B, $5:
      Exit(1);
    $8, $A, $10, $13, $14:
      Exit(2);
    $6, $1, $2, $9:
      Exit(3);
    $7, $4, $12:
      Exit(4);
    $D, $3:
      Exit(5);
  end;
end;

function TExpTable.GetEXP(GameType: TGAME_TYPE; Map, Rank, SumPlayer, SumHole: UInt8): UInt8;
var
  exp_3h: array of UInt8;
  exp_6h: array of UInt8;
  exp_9h: array of UInt8;
  exp_18h: array of UInt8;
begin
  case GameType of
    VERSUS_STROKE:
      begin
        { Default }
        exp_3h  := [0, 0, 0, 0];
        exp_6h  := [0, 0, 0, 0];
        exp_9h  := [0, 0, 0, 0];
        exp_18h := [0, 0, 0, 0];
        { Declare Versus Mode Exp Table }
        case Self.GetDifficulty(Map) of
          1:
            begin
              case SumPlayer of
                2:
                  begin
                    exp_3h  := [7, 6, 0, 0];
                    exp_6h  := [14, 10, 0, 0];
                    exp_9h  := [20, 15, 0, 0];
                    exp_18h := [40, 29, 0, 0];
                  end;
                3:
                  begin
                    exp_3h  := [9, 8, 7, 0];
                    exp_6h  := [17, 15, 13, 0];
                    exp_9h  := [25, 22, 18, 0];
                    exp_18h := [50, 43, 36, 0];
                  end;
                4:
                  begin
                    exp_3h  := [11, 10, 9, 8];
                    exp_6h  := [21, 19, 17, 15];
                    exp_9h  := [31, 29, 25, 22];
                    exp_18h := [62, 56, 49, 42];
                  end;
              end;
            end;
          2:
            begin
              case SumPlayer of
                2:
                  begin
                    exp_3h  := [8, 6, 0, 0];
                    exp_6h  := [14, 11, 0, 0];
                    exp_9h  := [21, 16, 0, 0];
                    exp_18h := [41, 30, 0, 0];
                  end;
                3:
                  begin
                    exp_3h  := [9, 8, 7, 0];
                    exp_6h  := [18, 16, 13, 0];
                    exp_9h  := [26, 23, 19, 0];
                    exp_18h := [52, 45, 38, 0];
                  end;
                4:
                  begin
                    exp_3h  := [12, 11, 9, 8];
                    exp_6h  := [22, 20, 18, 16];
                    exp_9h  := [33, 30, 26, 23];
                    exp_18h := [65, 59, 52, 45];
                  end;
              end;
            end;
          3:
            begin
              case SumPlayer of
                2:
                  begin
                    exp_3h  := [8, 6, 0, 0];
                    exp_6h  := [15, 11, 0, 0];
                    exp_9h  := [22, 16, 0, 0];
                    exp_18h := [43, 32, 0, 0];
                  end;
                3:
                  begin
                    exp_3h  := [10, 9, 7, 0];
                    exp_6h  := [19, 16, 14, 0];
                    exp_9h  := [27, 24, 20, 0];
                    exp_18h := [54, 47, 40, 0];
                  end;
                4:
                  begin
                    exp_3h  := [12, 11, 10, 9];
                    exp_6h  := [23, 21, 19, 16];
                    exp_9h  := [34, 31, 28, 24];
                    exp_18h := [67, 62, 55, 47];
                  end;
              end;
            end;
          4:
            begin
              case SumPlayer of
                2:
                  begin
                    exp_3h  := [8, 7, 0, 0];
                    exp_6h  := [16, 12, 0, 0];
                    exp_9h  := [23, 18, 0, 0];
                    exp_18h := [45, 35, 0, 0];
                  end;
                3:
                  begin
                    exp_3h  := [11, 9, 8, 0];
                    exp_6h  := [20, 18, 15, 0];
                    exp_9h  := [30, 26, 22, 0];
                    exp_18h := [58, 51, 44, 0];
                  end;
                4:
                  begin
                    exp_3h  := [13, 12, 11, 10];
                    exp_6h  := [25, 23, 21, 18];
                    exp_9h  := [37, 34, 30, 27];
                    exp_18h := [72, 67, 60, 53];
                  end;
              end;
            end;
          5:
            begin
              case SumPlayer of
                2:
                  begin
                    exp_3h  := [9, 7, 0, 0];
                    exp_6h  := [17, 14, 0, 0];
                    exp_9h  := [25, 20, 0, 0];
                    exp_18h := [49, 39, 0, 0];
                  end;
                3:
                  begin
                    exp_3h  := [12, 10, 9, 0];
                    exp_6h  := [22, 20, 17, 0];
                    exp_9h  := [33, 29, 25, 0];
                    exp_18h := [64, 57, 50, 0];
                  end;
                4:
                  begin
                    exp_3h  := [14, 13, 12, 11];
                    exp_6h  := [27, 26, 23, 21];
                    exp_9h  := [41, 38, 34, 31];
                    exp_18h := [80, 75, 68, 61];
                  end;
              end;
            end;
        end;
        { Return Exp Point }
        case SumHole of
          3:
            Exit(exp_3h[Rank - 1]);
          6:
            Exit(exp_6h[Rank - 1]);
          9:
            Exit(exp_9h[Rank - 1]);
          18:
            Exit(exp_18h[Rank - 1]);
        else
          Exit(0);
        end;
      end;
    VERSUS_MATCH: ;
    CHAT_ROOM: ;
    TOURNEY: ;
    TOURNEY_TEAM: ;
    TOURNEY_GUILD: ;
    PANG_BATTLE: ;
    CHIP_IN_PRACTICE: ;
    SSC: ;
    HOLE_REPEAT:
      begin
        if (SumHole > 18) then
          Exit(0);
        Exit(SumHole);
      end;
    GRANDPRIX: ;
  end;
end;

initialization
  GameEXP := TExpTable.Create;

finalization
  GameEXP.Free;

end.
