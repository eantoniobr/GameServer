unit ClubData;

interface

uses
  IffMain, Enum, Defines;

function PlayerGetClubSlotLeft(ID:UInt32; ClubPlayerData: TClubStatus; IsRankUp: Boolean = False): TClubStatus;
function PlayerGetSlotUpgrade(TypeID,Quantity: UInt32; ClubPlayerData: TClubStatus): ShortInt;
function PlayerGetClubRankUPData(ID: UInt32; ClubPlayerData: TClubStatus): TClubUpgradeRank;
function GetClubMaxStatus(TypeID: UInt32): TClubStatus;

implementation

function GetClubMaxStatus(TypeID: UInt32): TClubStatus;
begin
  Exit(IffEntry.FClub.GetClubStatus(TypeID));
end;

function PlayerGetClubSlotLeft(ID:UInt32; ClubPlayerData: TClubStatus; IsRankUp: Boolean = False): TClubStatus;
var
  ClubData: TClubStatus;
  ClubMaxSlot: TClubStatus;
begin
  ClubData := IffEntry.FClub.GetClubStatus(ID);

  with ClubMaxSlot do
  begin
    case ClubData.ClubType of
      TYPE_BALANCE:
        begin
          case ClubData.GetClubTotal(ClubPlayerData, IsRankUp) of
            30 .. 34: // Balance E
              begin
                Power := 14;
                Control := 12;
                Impact := 12;
                Spin := 5;
                Curve := 5;
              end;
            35 .. 39: // Balance D
              begin
                Power := 15;
                Control := 12;
                Impact := 13;
                Spin := 6;
                Curve := 6;
              end;
            40 .. 44: // Balance C
              begin
                Power := 16;
                Control := 12;
                Impact := 14;
                Spin := 6;
                Curve := 6;
              end;
            45 .. 49: // Balance B
              begin
                Power := 18;
                Control := 13;
                Impact := 15;
                Spin := 7;
                Curve := 7;
              end;
            50 .. 54: // Balance A
              begin
                Power := 20;
                Control := 13;
                Impact := 16;
                Spin := 8;
                Curve := 8;
              end;
            55 .. 59: // Balance S
              begin
                Power := 20;
                Control := 13;
                Impact := 16;
                Spin := 8;
                Curve := 8;
              end;
          end;
        end;
      TYPE_POWER:
        begin
          case ClubData.GetClubTotal(ClubPlayerData, IsRankUp) of
            30 .. 34: // Power E
              begin
                Power := 0;
                Control := 0;
                Impact := 0;
                Spin := 0;
                Curve := 0;
              end;
            35 .. 39: // Power D
              begin
                Power := 16;
                Control := 12;
                Impact := 13;
                Spin := 6;
                Curve := 6;
              end;
            40 .. 44: // Power C
              begin
                Power := 17;
                Control := 12;
                Impact := 14;
                Spin := 6;
                Curve := 6;
              end;
            45 .. 49: // Power B
              begin
                Power := 19;
                Control := 13;
                Impact := 15;
                Spin := 7;
                Curve := 7;
              end;
            50 .. 54: // Power A
              begin
                Power := 20;
                Control := 13;
                Impact := 16;
                Spin := 8;
                Curve := 8;
              end;
            55 .. 59: // Power S
              begin
                Power := 20;
                Control := 13;
                Impact := 16;
                Spin := 8;
                Curve := 8;
              end;
          end;
        end;
      TYPE_CONTROL:
        begin
          case ClubData.GetClubTotal(ClubPlayerData, IsRankUp) of
            30 .. 34: // Control E
              begin
                Power := 0;
                Control := 0;
                Impact := 0;
                Spin := 0;
                Curve := 0;
              end;
            35 .. 39: // Control D
              begin
                Power := 15;
                Control := 12;
                Impact := 13;
                Spin := 6;
                Curve := 6;
              end;
            40 .. 44: // Control C
              begin
                Power := 16;
                Control := 13;
                Impact := 14;
                Spin := 6;
                Curve := 6;
              end;
            45 .. 49: // Control B
              begin
                Power := 18;
                Control := 13;
                Impact := 15;
                Spin := 7;
                Curve := 7;
              end;
            50 .. 54: // Control A
              begin
                Power := 20;
                Control := 13;
                Impact := 16;
                Spin := 8;
                Curve := 8;
              end;
            55 .. 59: // Control S
              begin
                Power := 20;
                Control := 13;
                Impact := 16;
                Spin := 8;
                Curve := 8;
              end;
          end;
        end;
      TYPE_SPIN:
        begin
          case ClubData.GetClubTotal(ClubPlayerData, IsRankUp) of
            30 .. 34: // Spin E
              begin
                Power := 0;
                Control := 0;
                Impact := 0;
                Spin := 0;
                Curve := 0;
              end;
            35 .. 39: // Spin D
              begin
                Power := 15;
                Control := 12;
                Impact := 13;
                Spin := 7;
                Curve := 6;
              end;
            40 .. 44: // Spin C
              begin
                Power := 16;
                Control := 12;
                Impact := 14;
                Spin := 7;
                Curve := 6;
              end;
            45 .. 49: // Spin B
              begin
                Power := 18;
                Control := 13;
                Impact := 15;
                Spin := 8;
                Curve := 7;
              end;
            50 .. 54: // Spin A
              begin
                Power := 20;
                Control := 13;
                Impact := 16;
                Spin := 8;
                Curve := 8;
              end;
            55 .. 59: // Spin S
              begin
                Power := 20;
                Control := 13;
                Impact := 16;
                Spin := 8;
                Curve := 8;
              end;
          end;
        end;
      TYPE_SPECIAL:
        begin
          case ClubData.GetClubTotal(ClubPlayerData, IsRankUp) of
            30 .. 34: // Special E
              begin
                Power := 0;
                Control := 0;
                Impact := 0;
                Spin := 0;
                Curve := 0;
              end;
            35 .. 39: // Special D
              begin
                Power := 17;
                Control := 13;
                Impact := 14;
                Spin := 6;
                Curve := 6;
              end;
            40 .. 44: // Special C
              begin
                Power := 19;
                Control := 13;
                Impact := 15;
                Spin := 7;
                Curve := 7;
              end;
            45 .. 49: // Special B
              begin
                Power := 21;
                Control := 13;
                Impact := 17;
                Spin := 8;
                Curve := 8;
              end;
            50 .. 54: // Special A
              begin
                Power := 22;
                Control := 14;
                Impact := 18;
                Spin := 9;
                Curve := 9;
              end;
            55 .. 59: // Special S
              begin
                Power := 22;
                Control := 14;
                Impact := 18;
                Spin := 9;
                Curve := 9;
              end;
          end;
        end;
    end;
  end;
  Result := ClubMaxSlot - ClubData.GetClubPlayer(ClubPlayerData);
  Exit(Result);
end;

function PlayerGetSlotUpgrade(TypeID,Quantity: UInt32; ClubPlayerData: TClubStatus): ShortInt;
  function Check: Boolean;
  begin
    with ClubPlayerData do
    begin
      Result := (Power > 0) or (Control > 0) or (Impact > 0) or (Spin > 0) or (Curve > 0);
    end;
  end;
const
  RandTo: UInt8 = 30;
var
  RandInt: UInt8;
  Index: UInt8;
begin
  if not Check then Exit(-1);

  Randomize;
  RandInt := Random($64) + 1;

  case TypeID of
    $7C800026: // Orihakon
      begin
        case Quantity of
          1:
            begin
              if (RandInt < RandTo) and (ClubPlayerData.Impact > 0) then
              begin
                Exit(2);
              end;
            end;
          2:
            begin
              if (RandInt < RandTo) and (ClubPlayerData.Curve > 0) then
              begin
                Exit(4);
              end;
            end;
          3:
            begin
              if (RandInt < RandTo) and (ClubPlayerData.Power > 0) then
              begin
                Exit(0);
              end;
            end;
          4:
            begin
              if (RandInt < RandTo) and (ClubPlayerData.Spin > 0) then
              begin
                Exit(3);
              end;
            end;
          5:
            begin
              if (RandInt < RandTo) and (ClubPlayerData.Control > 0) then
              begin
                Exit(1);
              end;
            end;
        end;
      end;
    $7C800041: // Soren
      begin
        case Quantity of
          0:
            begin
              if ClubPlayerData.Impact > 0 then
              begin
                Exit(2);
              end;
            end;
          1:
            begin
              if ClubPlayerData.Curve > 0 then
              begin
                Exit(4);
              end;
            end;
          2:
            begin
              if ClubPlayerData.Power > 0 then
              begin
                Exit(0);
              end;
            end;
          3:
            begin
               if ClubPlayerData.Spin > 0 then
              begin
                Exit(3);
              end;
            end;
          4:
            begin
               if ClubPlayerData.Control > 0 then
              begin
                Exit(1);
              end;
            end;
        end;
      end;
  end;

  while true do
  begin
    Randomize;
    for Index := 0 to 4 do
    begin
      RandInt := Random($64) + 1;
      if (ClubPlayerData.GetClubArray[Index] > 0) and (RandInt <= 20) then
      begin
        Exit(Index);
      end;
    end;
  end;

  Exit(-1);
end;

function PlayerGetClubRankUPData(ID: UInt32; ClubPlayerData: TClubStatus): TClubUpgradeRank;
var
  ClubData: TClubStatus;
begin
  ClubData := IffEntry.FClub.GetClubStatus(ID);

  Result.ClubPoint := 0;
  Result.ClubCurrentRank := 0;
  Result.ClubSPoint := ClubData.ClubSPoint;
  Result.ClubSlotLeft := PlayerGetClubSlotLeft(ID, ClubPlayerData, True);

  with Result do
  begin
    case ClubData.ClubType of
      TYPE_BALANCE, TYPE_POWER, TYPE_SPIN:
        begin
          case ClubData.GetClubTotal(ClubPlayerData, False) of
            59:
              begin
                ClubPoint := 0;
                ClubCurrentRank := 5;
              end;
            54:
              begin
                ClubPoint := 68000;
                ClubCurrentRank := 4;
              end;
            49:
              begin
                ClubPoint := 20200;
                ClubCurrentRank := 3;
              end;
            44:
              begin
                ClubPoint := 11000;
                ClubCurrentRank := 2;
              end;
            39:
              begin
                ClubPoint := 2500;
                ClubCurrentRank := 1;
              end;
            34:
              begin
                ClubPoint := 900;
                ClubCurrentRank := 0;
              end;
          end;
        end;
      TYPE_CONTROL:
        begin
          case ClubData.GetClubTotal(ClubPlayerData, False) of
            59:
              begin
                ClubPoint := 0;
                ClubCurrentRank := 5;
              end;
            54:
              begin
                ClubPoint := 75000;
                ClubCurrentRank := 4;
              end;
            49:
              begin
                ClubPoint := 32500;
                ClubCurrentRank := 3;
              end;
            44:
              begin
                ClubPoint := 15000;
                ClubCurrentRank := 2;
              end;
            39:
              begin
                ClubPoint := 4800;
                ClubCurrentRank := 1;
              end;
            34:
              begin
                ClubPoint := 0;
                ClubCurrentRank := 0;
              end;
          end;
        end;
      TYPE_SPECIAL:
        begin
          case ClubData.GetClubTotal(ClubPlayerData, False) of
            59:
              begin
                ClubPoint := 0;
                ClubCurrentRank := 5;
              end;
            54:
              begin
                ClubPoint := 90000;
                ClubCurrentRank := 4;
              end;
            49:
              begin
                ClubPoint := 35000;
                ClubCurrentRank := 3;
              end;
            44:
              begin
                ClubPoint := 17600;
                ClubCurrentRank := 2;
              end;
            39:
              begin
                ClubPoint := 5300;
                ClubCurrentRank := 1;
              end;
            34:
              begin
                ClubPoint := 0;
                ClubCurrentRank := 0;
              end;
          end;
        end;
    end;
  end;
  Exit(Result);
end;

end.
