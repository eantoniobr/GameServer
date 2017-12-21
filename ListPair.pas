unit ListPair;

interface

uses
  System.Generics.Collections, System.Generics.Defaults;

type
  TPairs<TKey, TValue> = class(TList < TPair < TKey, TValue >> )
  protected
    fKeyComparer: IComparer<TKey>;
    fValueComparer: IComparer<TValue>;
    function GetValue(Key: TKey): TValue;
    procedure SetValue(Key: TKey; const Value: TValue);
    function ComparePair(const Left, Right: TPair<TKey, TValue>): Integer;
  public
    constructor Create; overload;
    procedure Add(const aKey: TKey; const aValue: TValue); overload;
    function IndexOfKey(const aKey: TKey): Integer;
    function ContainsKey(const aKey: TKey): Boolean; inline;
    property Values[Key: TKey]: TValue read GetValue write SetValue;
  end;

implementation

constructor TPairs<TKey, TValue>.Create;
begin
  if fKeyComparer = nil then fKeyComparer := TComparer<TKey>.Default;
  if fValueComparer = nil then fValueComparer := TComparer<TValue>.Default;
  inherited Create(TDelegatedComparer <TPair<TKey, TValue>>.Create(ComparePair));
end;

function TPairs<TKey, TValue>.ComparePair(const Left, Right: TPair<TKey, TValue>): Integer;
begin
  Result := fKeyComparer.Compare(Left.Key, Right.Key);
  if Result = 0 then Result := fValueComparer.Compare(Left.Value, Right.Value);
end;

function TPairs<TKey, TValue>.IndexOfKey(const aKey: TKey): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to Count - 1 do
    if fKeyComparer.Compare(Items[i].Key, aKey) = 0 then
      begin
        Result := i;
        break;
      end;
end;

function TPairs<TKey, TValue>.ContainsKey(const aKey: TKey): Boolean;
begin
  Result := IndexOfKey(aKey) >= 0;
end;

function TPairs<TKey, TValue>.GetValue(Key: TKey): TValue;
var
  i: Integer;
begin
  i := IndexOfKey(Key);
  if i >= 0 then Result := Items[i].Value
  else Result := default (TValue);
end;

procedure TPairs<TKey, TValue>.SetValue(Key: TKey; const Value: TValue);
var
  i: Integer;
  Pair: TPair<TKey, TValue>;
begin
  i := IndexOfKey(Key);
  if i >= 0 then
    begin
      Pair := Items[i];
      Pair.Value := Value;
      Items[i] := Pair;
    end
  else
    begin
      Pair.Create(Key, Value);
      inherited Add(Pair);
    end;
end;

procedure TPairs<TKey, TValue>.Add(const aKey: TKey; const aValue: TValue);
begin
  SetValue(aKey, aValue);
end;

end.
