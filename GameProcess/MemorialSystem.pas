unit MemorialSystem;

interface

uses
  ClientPacket, PangyaClient;

type
  TMemorialSystem = class
    private
    public
      procedure HandlePlayerPlayerMemorial(const clientPacket: TClientPacket;
  const Player: TClientPlayer);
  end;

implementation

{ TMemorialSystem }

procedure TMemorialSystem.HandlePlayerPlayerMemorial(
  const clientPacket: TClientPacket; const Player: TClientPlayer);
begin
  Player.Send(#$64#$02#$00#$00#$00#$00#$01#$00#$00#$00#$04#$00#$00#$00#$00#$00#$C0#$7C#$01#$00#$00#$00);
end;

end.
