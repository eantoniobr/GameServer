unit Form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.StdCtrls, Vcl.ComCtrls,
  System.Generics.Collections, PangyaClient, {GameServer,} Crypts, Utils, PangyaBuffer, Tools, ClientPacket,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  IffManager.Item, IffMain, IffManager.SetItem, IffManager.Caddie,
  IffManager.CaddieItem, IffManager.Skin, IffManager.Mascot,
  IffManager.GrandPrixData,
  IffManager.Part, IffManager.Card, Vcl.Grids, FireDAC.Phys.MSSQLDef,
  FireDAC.Phys.ODBCBase, FireDAC.Phys.MSSQL, System.Threading, Math,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer, IdContext, MainServer,
  IdCoder, IdCoder3to4, IdCoderMIME, IdScheduler, IdSchedulerOfThread,
  IdSchedulerOfThreadPool, Vcl.ExtCtrls, DateUtils, RandInteger, Enum, ClubData, IffManager.Achievement,
  XSuperObject, MailSystem, ServerStr, Transactions, generics.defaults,
  IffManager.MemorialShopCoinItem, IffManager.MemorialShopRareItem, UWriteConsole, MTRand, RandomItem,
  System.TypInfo, Defines, GameExpTable;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    btn1: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    ServerLog: TRichEdit;
    TabSheet3: TTabSheet;
    Edit1: TEdit;
    lbl1: TLabel;
    btn2: TButton;
    Button1: TButton;
    Edit2: TEdit;
    Button2: TButton;
    Button3: TButton;
    Data: TTabSheet;
    Items: TPageControl;
    TabSheet4: TTabSheet;
    StringGrid1: TStringGrid;
    FDPhysMSSQLDriverLink1: TFDPhysMSSQLDriverLink;
    TabSheet5: TTabSheet;
    StringGrid2: TStringGrid;
    TabSheet6: TTabSheet;
    StringGrid3: TStringGrid;
    TabSheet7: TTabSheet;
    StringGrid4: TStringGrid;
    TabSheet2: TTabSheet;
    StringGrid5: TStringGrid;
    TabSheet8: TTabSheet;
    StringGrid6: TStringGrid;
    TabSheet9: TTabSheet;
    StringGrid7: TStringGrid;
    TabSheet10: TTabSheet;
    StringGrid8: TStringGrid;
    IdTCPServer1: TIdTCPServer;
    TabSheet11: TTabSheet;
    StringGrid9: TStringGrid;
    FDQuery1: TFDQuery;

    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure LoadData;
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure Button3Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    procedure AutoSizeCol(Grid: TStringGrid; Column: integer);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  GameServerHandle: TGameServer;
  testing : TIffItems;
  IntTest: TRandInt;

implementation

{$R *.dfm}

procedure TForm1.AutoSizeCol(Grid: TStringGrid; Column: integer);
var
  i, W, WMax: integer;
begin
  WMax := 0;
  for i := 0 to (Grid.RowCount - 1) do begin
    W := Grid.Canvas.TextWidth(Grid.Cells[Column, i]);
    if W > WMax then
      WMax := W;
  end;
  Grid.ColWidths[Column] := WMax + 5;
end;

procedure TForm1.btn1Click(Sender: TObject);
begin
  //GameServerHandle.KickAll;
end;

procedure TForm1.btn2Click(Sender: TObject);
begin
  GameServerHandle.HandleNotice(AnsiString(Edit1.Text));
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ServerLog.Clear;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  ShowMessage(IntToStr(GetItemGroup(StrToInt(Edit2.Text))));
end;

type
  ttestx = class
  public
  var
    x: uint32;
  end;


procedure TForm1.Button3Click(Sender: TObject);
var
  x: TList<integer>;
  b: ^tstatistic;
  c: tclientpacket;
begin
  //Writeln(GameEXP.GetEXP(VERSUS_STROKE, $D, 1, 3, 18));
  c := tclientpacket.Create;
  try
    new(b);
    c.Write(b.Drive, sizeof(tstatistic));
    writeln(showhex(c.ToStr));
  finally

  end;
  writeln(getmap);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  GameServerHandle.Destroy;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  GameServerHandle := TGameServer.Create;
  GameServerHandle.Run;
  LoadData;
  SetConsoleOutputCP(CP_UTF8);
end;

procedure TForm1.IdTCPServer1Connect(AContext: TIdContext);
begin
 //
end;

procedure TForm1.LoadData;
var
  Items : PIffItem;
  Sets : PIffSetItem;
  Count : UInt32;
  Parts: PIffPart;
  Caddies: PIffCaddie;
  Skins: PIffSkin;
  CaddieItems: PIffCaddieItem;
  Mascots: PIffMascot;
  GrandPrix: PGrandPrixData;
  Card: PIffCard;
begin

  // NORMAL ITEM

  Count := 0;

  StringGrid1.Cells[0,0]:='TypeID';
  StringGrid1.Cells[1,0]:='Name';
  StringGrid1.Cells[2,0]:='ShopPrice';
  StringGrid1.Cells[3,0]:='ShopPriceType';
  StringGrid1.Cells[4,0]:='ShopFlag';
  StringGrid1.Cells[5,0]:='Total';

  StringGrid1.RowCount := IffEntry.FItems.FItem.Count;

  for Items in IffEntry.FItems.FItem.Values do
  begin
    StringGrid1.Cells[0,Count+1]:= Items.Base.TypeID.ToString;
    StringGrid1.Cells[1,Count+1]:= Trim(String(Items.Base.Name));
    StringGrid1.Cells[2,Count+1]:= Items.Base.ItemPrice.ToString;
    StringGrid1.Cells[3,Count+1]:= Items.Base.PriceType.ToString;
    StringGrid1.Cells[4,Count+1]:= Items.Base.ItemFlag.ToString;
    StringGrid1.Cells[5,Count+1]:= Items.C0.ToString;
    Inc(Count);
  end;


  // SET ITEM

  Count := 0;

  StringGrid2.Cells[0,0]:='TypeID';
  StringGrid2.Cells[1,0]:='Name';
  StringGrid2.Cells[2,0]:='ShopPrice';
  StringGrid2.Cells[3,0]:='ShopPriceType';
  StringGrid2.Cells[4,0]:='ShopFlag';
  StringGrid2.Cells[5,0]:='Total';

  StringGrid2.RowCount := IffEntry.FSets.FItemSet.Count;

  for Sets in IffEntry.FSets.FItemSet.Values do
  begin
    StringGrid2.Cells[0,Count+1]:= Sets.Base.Enabled.ToString;
    StringGrid2.Cells[1,Count+1]:= Trim(String(Sets.Base.Name));
    StringGrid2.Cells[2,Count+1]:= Sets.Base.ItemPrice.ToString;
    StringGrid2.Cells[3,Count+1]:= Sets.Base.PriceType.ToString;
    StringGrid2.Cells[4,Count+1]:= Sets.Base.ItemFlag.ToString;
    StringGrid2.Cells[5,Count+1]:= Sets.Total.ToString;
    Inc(Count);
  end;

  // PART ITEM

  Count := 0;

  StringGrid3.Cells[0,0]:='TypeID';
  StringGrid3.Cells[1,0]:='Name';
  StringGrid3.Cells[2,0]:='ShopPrice';
  StringGrid3.Cells[3,0]:='ShopPriceType';
  StringGrid3.Cells[4,0]:='ShopFlag';
  StringGrid3.Cells[5,0]:='Rent Pang';

  StringGrid3.RowCount := IffEntry.FParts.PartData.Count;

  for Parts in IffEntry.FParts.PartData.Values do
  begin
    StringGrid3.Cells[0,Count+1]:= Parts.Base.TypeId.ToString;
    StringGrid3.Cells[1,Count+1]:= Trim(String(Parts.Base.Name));
    StringGrid3.Cells[2,Count+1]:= Parts.Base.ItemPrice.ToString;
    StringGrid3.Cells[3,Count+1]:= Parts.Base.PriceType.ToString;
    StringGrid3.Cells[4,Count+1]:= Parts.Base.ItemFlag.ToString;
    StringGrid3.Cells[5,Count+1]:= Parts.RentPang.ToString;
    Inc(Count);
  end;

  // CADDIE ITEM

  Count := 0;

  StringGrid4.Cells[0,0]:='TypeID';
  StringGrid4.Cells[1,0]:='Name';
  StringGrid4.Cells[2,0]:='ShopPrice';
  StringGrid4.Cells[3,0]:='ShopPriceType';
  StringGrid4.Cells[4,0]:='ShopFlag';
  StringGrid4.Cells[5,0]:='Salary';

  StringGrid4.RowCount := IffEntry.FCaddies.Count;

  for Caddies in IffEntry.FCaddies do
  begin
    StringGrid4.Cells[0,Count+1]:= Caddies.Base.TypeId.ToString;
    StringGrid4.Cells[1,Count+1]:= Trim(String(Caddies.Base.Name));
    StringGrid4.Cells[2,Count+1]:= Caddies.Base.ItemPrice.ToString;
    StringGrid4.Cells[3,Count+1]:= Caddies.Base.PriceType.ToString;
    StringGrid4.Cells[4,Count+1]:= Caddies.Base.ItemFlag.ToString;
    StringGrid4.Cells[5,Count+1]:= Caddies.Salary.ToString;
    Inc(Count);
  end;

  // SKIN ITEM

  Count := 0;

  StringGrid5.Cells[0,0]:='TypeID';
  StringGrid5.Cells[1,0]:='Name';
  StringGrid5.Cells[2,0]:='ShopPrice';
  StringGrid5.Cells[3,0]:='ShopPriceType';
  StringGrid5.Cells[4,0]:='ShopFlag';
  StringGrid5.Cells[5,0]:='Price 15';
  StringGrid5.Cells[6,0]:='Price 30';
  StringGrid5.Cells[7,0]:='Price 365';

  StringGrid5.RowCount := IffEntry.FSkins.FSkin.Count;

  for Skins in IffEntry.FSkins.FSkin.Values do
  begin
    StringGrid5.Cells[0,Count+1]:= Skins.Base.TypeId.ToString;
    StringGrid5.Cells[1,Count+1]:= Trim(String(Skins.Base.Name));
    StringGrid5.Cells[2,Count+1]:= Skins.Base.ItemPrice.ToString;
    StringGrid5.Cells[3,Count+1]:= Skins.Base.PriceType.ToString;
    StringGrid5.Cells[4,Count+1]:= Skins.Base.ItemFlag.ToString;
    StringGrid5.Cells[5,Count+1]:= Skins.Price15.ToString;
    StringGrid5.Cells[6,Count+1]:= Skins.Price30.ToString;
    StringGrid5.Cells[7,Count+1]:= Skins.Price365.ToString;
    Inc(Count);
  end;

  // CADDIE ITEMs

  Count := 0;

  StringGrid6.Cells[0,0]:='TypeID';
  StringGrid6.Cells[1,0]:='Name';
  StringGrid6.Cells[2,0]:='ShopPrice';
  StringGrid6.Cells[3,0]:='ShopPriceType';
  StringGrid6.Cells[4,0]:='ShopFlag';
  StringGrid6.Cells[5,0]:='Price 1';
  StringGrid6.Cells[6,0]:='Price 15';
  StringGrid6.Cells[7,0]:='Price 30';

  StringGrid6.RowCount := IffEntry.FCaddieItem.Count;

  for CaddieItems in IffEntry.FCaddieItem do
  begin
    StringGrid6.Cells[0,Count+1]:= CaddieItems.Base.TypeId.ToString;
    StringGrid6.Cells[1,Count+1]:= Trim(String(CaddieItems.Base.Name));
    StringGrid6.Cells[2,Count+1]:= CaddieItems.Base.ItemPrice.ToString;
    StringGrid6.Cells[3,Count+1]:= CaddieItems.Base.PriceType.ToString;
    StringGrid6.Cells[4,Count+1]:= CaddieItems.Base.ItemFlag.ToString;
    StringGrid6.Cells[5,Count+1]:= CaddieItems.Price1.ToString;
    StringGrid6.Cells[6,Count+1]:= CaddieItems.Price15.ToString;
    StringGrid6.Cells[7,Count+1]:= CaddieItems.Price30.ToString;
    Inc(Count);
  end;

  // Mascot ITEMs

  Count := 0;

  StringGrid7.Cells[0, 0] := 'TypeID';
  StringGrid7.Cells[1, 0] := 'Name';
  StringGrid7.Cells[2, 0] := 'ShopPrice';
  StringGrid7.Cells[3, 0] := 'ShopPriceType';
  StringGrid7.Cells[4, 0] := 'ShopFlag';
  StringGrid7.Cells[5, 0] := 'Price 1';
  StringGrid7.Cells[6, 0] := 'Price 15';
  StringGrid7.Cells[7, 0] := 'Price 30';

  StringGrid7.RowCount := IffEntry.FMascots.MascotData.Count;

  for Mascots in IffEntry.FMascots.MascotData.Values do
  begin
    StringGrid7.Cells[0,Count+1]:= Mascots.Base.TypeID.ToString;
    StringGrid7.Cells[1,Count+1]:= Trim(String(Mascots.Base.Name));
    StringGrid7.Cells[2,Count+1]:= Mascots.Base.ItemPrice.ToString;
    StringGrid7.Cells[3,Count+1]:= Mascots.Base.PriceType.ToString;
    StringGrid7.Cells[4,Count+1]:= Mascots.Base.ItemFlag.ToString;
    StringGrid7.Cells[5,Count+1]:= Mascots.Price1.ToString;
    StringGrid7.Cells[6,Count+1]:= Mascots.Price7.ToString;
    StringGrid7.Cells[7,Count+1]:= Mascots.Price30.ToString;
    Inc(Count);
  end;

  // Grand Prix Data

  Count := 0;

  StringGrid8.Cells[0,0]:='TypeID';
  StringGrid8.Cells[1,0]:='TrueTypeId';
  StringGrid8.Cells[2,0]:='Type';
  StringGrid8.Cells[3,0]:='TimePerHole';
  StringGrid8.Cells[4,0]:='Name';
  StringGrid8.Cells[5,0]:='Ticket';
  StringGrid8.Cells[6,0]:='Quan';
  StringGrid8.Cells[7,0]:='Natural';
  StringGrid8.Cells[8,0]:='ShortGame';
  StringGrid8.Cells[9,0]:='BigHole';
  StringGrid8.Cells[10,0]:='Artifact';
  StringGrid8.Cells[11,0]:='Map';
  StringGrid8.Cells[12,0]:='Mode';
  StringGrid8.Cells[13,0]:='TotalHole';
  StringGrid8.Cells[14,0]:='MinLevel';
  StringGrid8.Cells[15,0]:='MaxLevel';
  StringGrid8.Cells[16,0]:='ScoreBotMax';
  StringGrid8.Cells[17,0]:='ScoreBotMed';
  StringGrid8.Cells[18,0]:='ScoreBotMin';
  StringGrid8.Cells[19,0]:='Diffucult';
  StringGrid8.Cells[20,0]:='PangReward';
  StringGrid8.Cells[21,0]:='Hour_Open';
  StringGrid8.Cells[22,0]:='Min_Open';
  StringGrid8.Cells[23,0]:='Hour_Start';
  StringGrid8.Cells[24,0]:='Min_Start';
  StringGrid8.Cells[25,0]:='Hour_End';
  StringGrid8.Cells[26,0]:='Min_End';

  StringGrid8.RowCount := IffEntry.FGrandPrixData.GP.Count;

  for GrandPrix in IffEntry.FGrandPrixData.GP.Values do
  begin
    StringGrid8.Cells[0,Count+1]:= GrandPrix.TypeId.ToString;
    StringGrid8.Cells[1,Count+1]:= GrandPrix.TrueTypeId.ToString;
    StringGrid8.Cells[2,Count+1]:= GrandPrix.TypeGP.ToString;
    StringGrid8.Cells[3,Count+1]:= GrandPrix.TimeHole.ToString;
    StringGrid8.Cells[4,Count+1]:= String(GrandPrix.GetName);
    StringGrid8.Cells[5,Count+1]:= GrandPrix.TicketTypeID.ToString();
    StringGrid8.Cells[6,Count+1]:= GrandPrix.Quantity.ToString();
    StringGrid8.Cells[7,Count+1]:= GrandPrix.Natural.ToString();
    StringGrid8.Cells[8,Count+1]:= GrandPrix.ShortGame.ToString();
    StringGrid8.Cells[9,Count+1]:= GrandPrix.HoleSize.ToString();
    StringGrid8.Cells[10,Count+1]:= GrandPrix.Artifact.ToString();
    StringGrid8.Cells[11,Count+1]:= GrandPrix.Map.ToString();
    StringGrid8.Cells[12,Count+1]:= GrandPrix.Mode.ToString();
    StringGrid8.Cells[13,Count+1]:= GrandPrix.TotalHole.ToString();
    StringGrid8.Cells[14,Count+1]:= GrandPrix.MinLevel.ToString();
    StringGrid8.Cells[15,Count+1]:= GrandPrix.MaxLevel.ToString();
    StringGrid8.Cells[16,Count+1]:= GrandPrix.ScoreBotMax.ToString();
    StringGrid8.Cells[17,Count+1]:= GrandPrix.ScoreBotMed.ToString();
    StringGrid8.Cells[18,Count+1]:= GrandPrix.ScoreBotMin.ToString();
    StringGrid8.Cells[19,Count+1]:= GrandPrix.Diffucult.ToString;
    StringGrid8.Cells[20,Count+1]:= GrandPrix.PangReward.ToString;
    StringGrid8.Cells[21,Count+1]:= GrandPrix.Hour_Open.ToString();
    StringGrid8.Cells[22,Count+1]:= GrandPrix.Min_Open.ToString();
    StringGrid8.Cells[23,Count+1]:= GrandPrix.Hour_Start.ToString();
    StringGrid8.Cells[24,Count+1]:= GrandPrix.Min_Start.ToString();
    StringGrid8.Cells[25,Count+1]:= GrandPrix.Hour_End.ToString();
    StringGrid8.Cells[26,Count+1]:= GrandPrix.Min_End.ToString();
    Inc(Count);
  end;

  // card ITEMs

  Count := 0;

  StringGrid9.Cells[0, 0] := 'TypeID';
  StringGrid9.Cells[1, 0] := 'Name';
  StringGrid9.Cells[2, 0] := 'ShopPrice';
  StringGrid9.Cells[3, 0] := 'ShopPriceType';
  StringGrid9.Cells[4, 0] := 'ShopFlag';
  StringGrid9.Cells[5, 0] := 'PackNumber';
  StringGrid9.Cells[6, 0] := 'SPCL1';
  StringGrid9.Cells[7, 0] := 'SPCL2';
  StringGrid9.Cells[8, 0] := 'Time';
  StringGrid9.Cells[9, 0] := 'CardType';

  StringGrid9.RowCount := IffEntry.FCards.CARD.Count;

  for Card in IffEntry.FCards.CARD.Values do
  begin
    StringGrid9.Cells[0,Count+1]:= Card.Base.TypeId.ToString;
    StringGrid9.Cells[1,Count+1]:= Trim(String(Card.Base.Name));
    StringGrid9.Cells[2,Count+1]:= Card.Base.ItemPrice.ToString;
    StringGrid9.Cells[3,Count+1]:= Card.Base.PriceType.ToString;
    StringGrid9.Cells[4,Count+1]:= Card.Base.ItemFlag.ToString;
    StringGrid9.Cells[5,Count+1]:= Card.Volumn.ToString;
    StringGrid9.Cells[6,Count+1]:= Card.Effect.ToString;
    StringGrid9.Cells[7,Count+1]:= Card.EffectQty.ToString;
    StringGrid9.Cells[8,Count+1]:= Card.Time.ToString;
    StringGrid9.Cells[9,Count+1]:= Card.CardType.ToString;
    Inc(Count);
  end;

  for Count := 0 to StringGrid1.ColCount - 1 do
    AutoSizeCol(StringGrid1, Count);

  for Count := 0 to StringGrid2.ColCount - 1 do
    AutoSizeCol(StringGrid2, Count);

  for Count := 0 to StringGrid3.ColCount - 1 do
    AutoSizeCol(StringGrid3, Count);

  for Count := 0 to StringGrid4.ColCount - 1 do
    AutoSizeCol(StringGrid4, Count);

  for Count := 0 to StringGrid5.ColCount - 1 do
    AutoSizeCol(StringGrid5, Count);

  for Count := 0 to StringGrid6.ColCount - 1 do
    AutoSizeCol(StringGrid6, Count);

   for Count := 0 to StringGrid7.ColCount - 1 do
    AutoSizeCol(StringGrid7, Count);

   for Count := 0 to StringGrid8.ColCount - 1 do
    AutoSizeCol(StringGrid8, Count);

   for Count := 0 to StringGrid9.ColCount - 1 do
    AutoSizeCol(StringGrid9, Count);


end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  writeln('test');
end;

end.
