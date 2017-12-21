unit Trophies;

interface

function TrophyCalulate(TrophyTypeID: UInt32; TrophyType: UInt8): UInt8;

implementation

function TrophyCalulate(TrophyTypeID: UInt32; TrophyType: UInt8): UInt8;
begin
  case TrophyTypeID of
    $2C000000:
      begin
        case TrophyType of
          1: Exit(1);
          2: Exit(2);
          3: Exit(3);
        end;
      end;
    $2C010000:
      begin
        case TrophyType of
          1: Exit(4);
          2: Exit(5);
          3: Exit(6);
        end;
      end;
    $2C020000:
      begin
        case TrophyType of
          1: Exit(7);
          2: Exit(8);
          3: Exit(9);
        end;
      end;
    $2C030000:
      begin
        case TrophyType of
          1: Exit(10);
          2: Exit(11);
          3: Exit(12);
        end;
      end;
    $2C040000:
      begin
        case TrophyType of
          1: Exit(13);
          2: Exit(14);
          3: Exit(15);
        end;
      end;
    $2C050000:
      begin
        case TrophyType of
          1: Exit(16);
          2: Exit(17);
          3: Exit(18);
        end;
      end;
    $2C060000:
      begin
        case TrophyType of
          1: Exit(19);
          2: Exit(20);
          3: Exit(21);
        end;
      end;
    $2C070000:
      begin
        case TrophyType of
          1: Exit(22);
          2: Exit(23);
          3: Exit(24);
        end;
      end;
    $2C080000:
      begin
        case TrophyType of
          1: Exit(25);
          2: Exit(26);
          3: Exit(27);
        end;
      end;
    $2C090000:
      begin
        case TrophyType of
          1: Exit(28);
          2: Exit(29);
          3: Exit(30);
        end;
      end;
    $2C0A0000:
      begin
        case TrophyType of
          1: Exit(31);
          2: Exit(32);
          3: Exit(33);
        end;
      end;
    $2C0B0000:
      begin
        case TrophyType of
          1: Exit(34);
          2: Exit(35);
          3: Exit(36);
        end;
      end;
    $2C0C0000:
      begin
        case TrophyType of
          1: Exit(37);
          2: Exit(38);
          3: Exit(39);
        end;
      end;
  end;
end;

end.
