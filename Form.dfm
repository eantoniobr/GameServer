object Form1: TForm1
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Game Server'
  ClientHeight = 402
  ClientWidth = 684
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar1: TStatusBar
    Left = 0
    Top = 383
    Width = 684
    Height = 19
    Panels = <>
  end
  object btn1: TButton
    Left = 487
    Top = 291
    Width = 141
    Height = 25
    Caption = 'Being Close'
    TabOrder = 1
    OnClick = btn1Click
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 4
    Width = 681
    Height = 373
    ActivePage = Data
    TabOrder = 2
    object TabSheet1: TTabSheet
      Caption = 'Logs'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object ServerLog: TRichEdit
        Left = 3
        Top = 3
        Width = 621
        Height = 247
        Font.Charset = THAI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        Lines.Strings = (
          'ServerLog')
        ParentFont = False
        TabOrder = 0
        Zoom = 100
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Notice'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object lbl1: TLabel
        Left = 4
        Top = 5
        Width = 269
        Height = 24
        Caption = 'Notice to the top of the player'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -20
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Edit1: TEdit
        Left = 4
        Top = 35
        Width = 620
        Height = 27
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
      object btn2: TButton
        Left = 3
        Top = 68
        Width = 86
        Height = 37
        Caption = 'Send'
        TabOrder = 1
        OnClick = btn2Click
      end
    end
    object Data: TTabSheet
      Caption = 'Data'
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Items: TPageControl
        Left = 3
        Top = 0
        Width = 646
        Height = 321
        ActivePage = TabSheet11
        TabOrder = 0
        object TabSheet4: TTabSheet
          Caption = 'Item'
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid1: TStringGrid
            Left = 0
            Top = 0
            Width = 609
            Height = 219
            ColCount = 6
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
        object TabSheet5: TTabSheet
          Caption = 'SetItem'
          ImageIndex = 1
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid2: TStringGrid
            Left = 0
            Top = 0
            Width = 617
            Height = 219
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
        object TabSheet6: TTabSheet
          Caption = 'Part'
          ImageIndex = 2
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid3: TStringGrid
            Left = 0
            Top = 0
            Width = 617
            Height = 219
            ColCount = 6
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
        object TabSheet7: TTabSheet
          Caption = 'Caddie'
          ImageIndex = 3
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid4: TStringGrid
            Left = 0
            Top = 0
            Width = 609
            Height = 219
            ColCount = 6
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
        object TabSheet2: TTabSheet
          Caption = 'Skin'
          ImageIndex = 4
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid5: TStringGrid
            Left = 3
            Top = 3
            Width = 607
            Height = 216
            ColCount = 10
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
        object TabSheet8: TTabSheet
          Caption = 'Caddie Item'
          ImageIndex = 5
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid6: TStringGrid
            Left = 3
            Top = 3
            Width = 606
            Height = 214
            ColCount = 10
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
        object TabSheet9: TTabSheet
          Caption = 'Mascot'
          ImageIndex = 6
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid7: TStringGrid
            Left = 0
            Top = 0
            Width = 610
            Height = 219
            ColCount = 10
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
        object TabSheet10: TTabSheet
          Caption = 'GrandPrixData'
          ImageIndex = 7
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid8: TStringGrid
            Left = 3
            Top = 3
            Width = 632
            Height = 222
            ColCount = 30
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
        object TabSheet11: TTabSheet
          Caption = 'Card'
          ImageIndex = 8
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object StringGrid9: TStringGrid
            Left = 3
            Top = 0
            Width = 632
            Height = 262
            ColCount = 10
            TabOrder = 0
            ColWidths = (
              64
              64
              64
              64
              64
              64
              64
              64
              64
              64)
            RowHeights = (
              24
              24
              24
              24
              24)
          end
        end
      end
    end
  end
  object Button1: TButton
    Left = 8
    Top = 291
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 3
    OnClick = Button1Click
  end
  object Edit2: TEdit
    Left = 288
    Top = 291
    Width = 105
    Height = 24
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object Button2: TButton
    Left = 399
    Top = 291
    Width = 82
    Height = 25
    Caption = 'Get Item Type'
    TabOrder = 5
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 89
    Top = 291
    Width = 75
    Height = 25
    Caption = 'Button3'
    TabOrder = 6
    OnClick = Button3Click
  end
  object FDPhysMSSQLDriverLink1: TFDPhysMSSQLDriverLink
    Left = 384
    Top = 184
  end
  object IdTCPServer1: TIdTCPServer
    Bindings = <>
    DefaultPort = 0
    OnConnect = IdTCPServer1Connect
    Left = 523
    Top = 236
  end
  object FDQuery1: TFDQuery
    Left = 232
    Top = 176
  end
end
