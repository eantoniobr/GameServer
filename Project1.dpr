program Project1;

{$APPTYPE CONSOLE}

{$IFDEF DEBUG}
  {$DEFINE ENABLEFORM}
{$ENDIF}

uses
  {$IFDEF DEBUG}
  FastMM4 in 'Tools\FastMM\FastMM4.pas',
  FastMM4Messages in 'Tools\FastMM\FastMM4Messages.pas',
  {$ENDIF }
  Windows,
  SysUtils,
  {$IFDEF ENABLEFORM}
  Vcl.Forms,
  {$ENDIF }
  TimerQueue in 'Tools\TimerQueue.pas',
  AuthClient in 'Auth\AuthClient.pas',
  CryptLib in 'Crypts\CryptLib.pas',
  Crypts in 'Crypts\Crypts.pas',
  PangyaClient in 'PangyaClient.pas',
  Buffer in 'Packets\Buffer.pas',
  ClientPacket in 'Packets\ClientPacket.pas',
  PangyaBuffer in 'Packets\PangyaBuffer.pas',
  Tools in 'Tools\Tools.pas',
  Utils in 'Utils.pas',
  LobbyList in 'Lobby\LobbyList.pas',
  Lobby in 'Lobby\Lobby.pas',
  PacketData in 'Packets\PacketData.pas',
  ScratchCard in 'GameProcess\ScratchCard.pas',
  PlayersList in 'PlayersList.pas',
  uCharacter in 'Player\uCharacter.pas',
  uInventory in 'Player\uInventory.pas',
  uAction in 'Player\uAction.pas',
  uWarehouse in 'Player\uWarehouse.pas',
  Defines in 'Defines.pas',
  Ticker in 'GameProcess\Ticker.pas',
  SerialID in 'SerialID.pas',
  PapelSystem in 'GameProcess\PapelSystem.pas',
  ItemData in 'Player\ItemData.pas',
  RandomItem in 'ItemsList\RandomItem.pas',
  FiredacPooling in 'Database\FiredacPooling.pas',
  IffManager.Item in 'IffManager\IffManager.Item.pas',
  IffMain in 'IffManager\IffMain.pas',
  Counter in 'Counter.pas',
  MemorialSystem in 'GameProcess\MemorialSystem.pas',
  IffManager.SetItem in 'IffManager\IffManager.SetItem.pas',
  IffManager.Part in 'IffManager\IffManager.Part.pas',
  IffManager.Caddie in 'IffManager\IffManager.Caddie.pas',
  IffManager.Skin in 'IffManager\IffManager.Skin.pas',
  IffManager.CaddieItem in 'IffManager\IffManager.CaddieItem.pas',
  uMascot in 'Player\uMascot.pas',
  IffManager.Mascot in 'IffManager\IffManager.Mascot.pas',
  IffManager.Character in 'IffManager\IffManager.Character.pas',
  IffManager.CutinInfo in 'IffManager\IffManager.CutinInfo.pas',
  BoxRandom in 'GameProcess\BoxRandom.pas',
  FJSON in 'Tools\FJSON.pas',
  uCard in 'Player\uCard.pas',
  IffManager.GrandPrixData in 'IffManager\IffManager.GrandPrixData.pas',
  MainServer in 'MainServer.pas',
  JunkPacket in 'Tools\JunkPacket.pas',
  IffManager.Card in 'IffManager\IffManager.Card.pas',
  UWriteConsole in 'Tools\UWriteConsole.pas',
  Form in 'Form.pas' {Form1},
  uItemSlot in 'Player\uItemSlot.pas',
  RandInteger in 'RandInteger.pas',
  MyList in 'MyList.pas',
  IffManager.Club in 'IffManager\IffManager.Club.pas',
  ClubData in 'ClubData.pas',
  Enum in 'Enum.pas',
  ErrorCode in 'ErrorCode.pas',
  EXPSystem in 'EXPSystem.pas',
  IffManager.LevelUpPrizeItem in 'IffManager\IffManager.LevelUpPrizeItem.pas',
  IffManager.Achievement in 'IffManager\IffManager.Achievement.pas',
  PList in 'PList.pas',
  ExceptionLog in 'ExceptionLog.pas',
  XSuperJSON in 'Tools\JSON\XSuperJSON.pas',
  XSuperObject in 'Tools\JSON\XSuperObject.pas',
  ListPair in 'ListPair.pas',
  PacketCreator in 'PacketCreator.pas',
  MailSystem in 'GameProcess\MailSystem.pas',
  ServerStr in 'Tools\ServerStr.pas',
  Transactions in 'Transactions.pas',
  ObjectList in 'ObjectList.pas',
  ClientHelper in 'ClientHelper.pas',
  Trophies in 'Trophies.pas',
  IffManager.MemorialShopCoinItem in 'IffManager\IffManager.MemorialShopCoinItem.pas',
  IffManager.MemorialShopRareItem in 'IffManager\IffManager.MemorialShopRareItem.pas',
  IffManager.GrandPrixSpecialHole in 'IffManager\IffManager.GrandPrixSpecialHole.pas',
  IffManager.GPRankReward in 'IffManager\IffManager.GPRankReward.pas',
  MTRand in 'Tools\MTRand.pas',
  IffManager.Ball in 'IffManager\IffManager.Ball.pas',
  IffManager.CaddieMagic in 'IffManager\IffManager.CaddieMagic.pas',
  IffManager.Auxpart in 'IffManager\IffManager.Auxpart.pas',
  uFurniture in 'Player\uFurniture.pas',
  MailCore in 'GameCore\MailCore.pas',
  PlayerDataCore in 'GameCore\PlayerDataCore.pas',
  GameShopCore in 'GameCore\GameShopCore.pas',
  LobbyCore in 'GameCore\LobbyCore.pas',
  GuildCore in 'GameCore\GuildCore.pas',
  GameCore in 'GameCore\GameCore.pas',
  ClubSystemCore in 'GameCore\ClubSystemCore.pas',
  ItemCore in 'GameCore\ItemCore.pas',
  SelfDesignCore in 'GameCore\SelfDesignCore.pas',
  QuestCore in 'GameCore\QuestCore.pas',
  UserMatchHistory in 'UserMatchHistory.pas',
  LockerCore in 'GameCore\LockerCore.pas',
  GamePlayCore in 'GameCore\GamePlayCore.pas',
  uCardEquip in 'Player\uCardEquip.pas',
  uCaddie in 'Player\uCaddie.pas',
  Console in 'Tools\Console.pas',
  GameBase in 'GameBase\GameBase.pas',
  GameList in 'GameBase\GameList.pas',
  Vcl.Themes,
  Vcl.Styles,
  GameModeChat in 'GameBase\GameModeChat.pas',
  GameModeStroke in 'GameBase\GameModeStroke.pas',
  GameModeMatch in 'GameBase\GameModeMatch.pas',
  GameModePractice in 'GameBase\GameModePractice.pas',
  GameExpTable in 'GameBase\GameExpTable.pas';

{$R *.res}

{$Hints Off}

var
  Msg: TMsg;
  bRet: LongBool;
  GameServerHandle: TGameServer;
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
{$IFDEF ENABLEFORM}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Sky');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
{$ELSE}
  try
    SetConsoleTitle('Pangya Fresh UP! Game Server');
    GameServerHandle := TGameServer.Create;
    GameServerHandle.Run;
    repeat
      bRet := GetMessage(Msg, 0, 0, 0);
      if Integer(bRet) = -1 then
      begin
        Break;
      end
      else
      begin
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
    until not bRet;
  except
    on E: Exception do
    begin
      Writeln(E.Classname + ': ' + E.Message);
    end;
  end;
{$ENDIF}
end.
