unit EXPSystem;

interface

uses
  System.Generics.Collections;

var
  EXPList: TDictionary<UInt32, UInt32>;

procedure Initial;

implementation

procedure Initial;
begin

  EXPList.Add(0, 30);
  EXPList.Add(1, 40);
  EXPList.Add(2, 50);
  EXPList.Add(3, 60);
  EXPList.Add(4, 70);
  EXPList.Add(5, 140);

  EXPList.Add(6, 105);
  EXPList.Add(7, 125);
  EXPList.Add(8, 145);
  EXPList.Add(9, 165);
  EXPList.Add(10, 330);

  EXPList.Add(11, 248);
  EXPList.Add(12, 278);
  EXPList.Add(13, 308);
  EXPList.Add(14, 338);
  EXPList.Add(15, 675);

  EXPList.Add(16, 506);
  EXPList.Add(17, 546);
  EXPList.Add(18, 586);
  EXPList.Add(19, 626);
  EXPList.Add(20, 1253);

  EXPList.Add(21, 1002);
  EXPList.Add(22, 1052);
  EXPList.Add(23, 1102);
  EXPList.Add(24, 1152);
  EXPList.Add(25, 2304);

  EXPList.Add(26, 1843);
  EXPList.Add(27, 1903);
  EXPList.Add(28, 1963);
  EXPList.Add(29, 2023);
  EXPList.Add(30, 4046);

  EXPList.Add(31, 3237);
  EXPList.Add(32, 3307);
  EXPList.Add(33, 3377);
  EXPList.Add(34, 3447);
  EXPList.Add(35, 6894);

  EXPList.Add(36, 5515);
  EXPList.Add(37, 5595);
  EXPList.Add(38, 5675);
  EXPList.Add(39, 5755);
  EXPList.Add(40, 11511);

  EXPList.Add(41, 8058);
  EXPList.Add(42, 8148);
  EXPList.Add(43, 8238);
  EXPList.Add(44, 8328);
  EXPList.Add(45, 16655);

  EXPList.Add(46, 8328);
  EXPList.Add(47, 8428);
  EXPList.Add(48, 8528);
  EXPList.Add(49, 8628);
  EXPList.Add(50, 17255);

  EXPList.Add(51, 9490);
  EXPList.Add(52, 9690);
  EXPList.Add(53, 9890);
  EXPList.Add(54, 10090);
  EXPList.Add(55, 20181);

  EXPList.Add(56, 20181);
  EXPList.Add(57, 20481);
  EXPList.Add(58, 20781);
  EXPList.Add(59, 21081);
  EXPList.Add(60, 42161);

  EXPList.Add(61, 37945);
  EXPList.Add(62, 68301);
  EXPList.Add(63, 122942);
  EXPList.Add(64, 221296);
  EXPList.Add(65, 442592);

  EXPList.Add(66, 663887);
  EXPList.Add(67, 995831);
  EXPList.Add(68, 1493747);
  EXPList.Add(69, 2240620);
  EXPList.Add(70, 0);
end;

initialization
  begin
    EXPList := TDictionary<UInt32, UInt32>.Create;
    Initial;
  end;
finalization
  begin
    EXPList.Free;
  end;

end.
