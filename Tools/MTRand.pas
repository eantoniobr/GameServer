(*
    This file is part of the Delphi MapleStory Server

    	Copyright (C) 2009-2010  Hendi

    The code contains portions of:

	    OdinMS
	    KryptoDEV Source
	    Vana

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation. You may not use, modify
    or distribute this program under any other version of the
    GNU Affero General Public License.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License <http://www.gnu.org/licenses/>
    for more details.
*)

unit MTRand;

(* **************************************************************************** *)
(* *                                                                          * *)
(* *  TMTRand:                                                                * *)
(* *     Generates random numbers using Mersenne Twister                      * *)
(* *                                                                          * *)
(* **************************************************************************** *)

{$R-} { range checking off }
{$Q-} { overflow checking off }

interface

const
  RtsRNGN = 624;

type
  TRNGStateArray = array [0..RtsRNGN - 1] of Cardinal; // the array for the state vector

type
  TMTRand = class
  private
    Mt: TRNGStateArray;
    Mti: Integer;
    // Generates a random number from Low(Integer) to High(Integer)
    function GetFullRangeRandom: Integer;
    // 0 <= Result < Range
    function Random(Range: Integer): Integer; overload;
  public
    constructor Create;
    procedure SetSeed(Seed: Cardinal); overload;
    procedure SetSeed(const SeedArray: TRNGStateArray); overload;
    procedure Randomize;
    // 0 <= Result < 1
    function RandDouble: Double;
    // 0 <= Result <= Max
    function RandInt(Max: Integer): Integer; overload;
    // RFrom <= Result <= RTo
    function RandInt(RFrom, RTo: Integer): Integer; overload;
    // Liefert eine Gauss-Verteilte Zufallszahl zurück:
    function Gauss(Mean, Variance: Extended): Extended;
  end;

var
  Rand: TMTRand;  // singleton

implementation

const
  { Period parameters }
  RtsRNGM = 397;
  RtsRNGMATRIX_A = $9908B0DF;
  RtsRNGUPPER_MASK = $80000000;
  RtsRNGLOWER_MASK = $7FFFFFFF;

  { Tempering parameters }
  TEMPERING_MASK_B = $9D2C5680;
  TEMPERING_MASK_C = $EFC60000;

constructor TMTRand.Create;
begin
  Mti := RtsRNGN + 1;
end;

procedure TMTRand.SetSeed(Seed: Cardinal);
var
  I: Integer;
begin
  for I := 0 to RtsRNGN - 1 do
  begin
    Mt[I] := Seed and $FFFF0000;
    Seed := 69069 * Seed + 1;
    Mt[I] := Mt[I] or ((Seed and $FFFF0000) shr 16);
    Seed := 69069 * Seed + 1;
  end;
  Mti := RtsRNGN;
end;

procedure TMTRand.SetSeed(const SeedArray: TRNGStateArray);
var
  I: Integer;
begin
  for I := 0 to RtsRNGN - 1 do
    Mt[I] := SeedArray[I];
  Mti := RtsRNGN;
end;

function TMTRand.GetFullRangeRandom: Integer;
const
  Mag01: array [0..1] of Cardinal = (0, RtsRNGMATRIX_A);
var
  Y, Kk: Cardinal;
begin
  if Mti >= RtsRNGN then
  begin
    if Mti = (RtsRNGN + 1) then
      SetSeed(4357);
    for Kk := 0 to RtsRNGN - RtsRNGM - 1 do
    begin
      Y := (Mt[Kk] and RtsRNGUPPER_MASK) or (Mt[Kk + 1] and RtsRNGLOWER_MASK);
      Mt[Kk] := Mt[Kk + RtsRNGM] xor (Y shr 1) xor Mag01[Y and $00000001];
    end;
    for Kk := RtsRNGN - RtsRNGM to RtsRNGN - 2 do
    begin
      Y := (Mt[Kk] and RtsRNGUPPER_MASK) or (Mt[Kk + 1] and RtsRNGLOWER_MASK);
      Mt[Kk] := Mt[Int32(Kk) + (RtsRNGM - RtsRNGN)] xor (Y shr 1) xor Mag01[Y and $00000001];
    end;
    Y := (Mt[RtsRNGN - 1] and RtsRNGUPPER_MASK) or (Mt[0] and RtsRNGLOWER_MASK);
    Mt[RtsRNGN - 1] := Mt[RtsRNGM - 1] xor (Y shr 1) xor Mag01[Y and $00000001];
    Mti := 0;
  end;
  Y := Mt[Mti];
  Inc(Mti);
  Y := Y xor (Y shr 11);
  Y := Y xor (Y shl 7) and TEMPERING_MASK_B;
  Y := Y xor (Y shl 15) and TEMPERING_MASK_C;
  Y := Y xor (Y shr 18);
  Result := Y;
end;

procedure TMTRand.Randomize;
var
  Old: Integer;
begin
  Old := System.Randseed;
  System.Randomize;
  SetSeed(System.RandSeed);
  System.RandSeed := Old;
end;

function TMTRand.Random(Range: Integer): Integer;
begin
  // 0 <= Result < Range
  Result := Trunc(Range * RandDouble);
end;

function TMTRand.RandDouble: Double;
begin
  // 0 <= Result < 1
  Result := Abs(GetFullRangeRandom / High(Integer));

  while Result > 0.9999999999 do
    Result := Result - 0.000001
end;

function TMTRand.RandInt(Max: Integer): Integer;
begin
  // 0 <= Result <= Max
  Result := RandInt(0, Max);
end;

function TMTRand.RandInt(RFrom, RTo: Integer): Integer;
begin
  // RFrom <= Result <= RTo
  if RFrom > RTo then
    Result := Random(RFrom - RTo + 1) + RTo
  else
    Result := Random(RTo - RFrom + 1) + RFrom;
end;

function TMTRand.Gauss(Mean, Variance: Extended): Extended;
{ Marsaglia-Bray algorithm }
var
  A, B: Extended;
begin
  repeat
    A := 2 * RandDouble - 1;
    B := Sqr(A) + Sqr(2 * RandDouble - 1);
  until B < 1;
  Result := Sqrt(-2 * Ln(B) / B) * A * Variance + Mean;
end;

initialization
  Rand := TMTRand.Create;

finalization
  Rand.Free;

end.

