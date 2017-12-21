USE [Pangya]
GO

/****** Object:  Table [dbo].[Pangya_Mail_SetItem]    Script Date: 6/8/2560 21:56:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Pangya_Mail_SetItem](
	[MAIL_IDX] [int] NOT NULL,
	[TYPE_ID] [int] NULL,
	[QTY] [int] NULL,
	[DAY] [smallint] NULL,
	[IN_DATE] [datetime] NULL,
 CONSTRAINT [PK_Pangya_Mail_SetItem] PRIMARY KEY CLUSTERED 
(
	[MAIL_IDX] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Pangya_Mail_SetItem] ADD  CONSTRAINT [DF_Pangya_Mail_SetItem_DAY]  DEFAULT ((0)) FOR [DAY]
GO

ALTER TABLE [dbo].[Pangya_Mail_SetItem] ADD  CONSTRAINT [DF_Pangya_Mail_SetItem_IN_DATE]  DEFAULT (getdate()) FOR [IN_DATE]
GO

