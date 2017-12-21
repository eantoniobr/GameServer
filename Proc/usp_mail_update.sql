USE [Pangya]
GO

/****** Object:  StoredProcedure [dbo].[USP_MAIL_UPDATE]    Script Date: 7/8/2560 1:19:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		TOP
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[USP_MAIL_UPDATE] 
	@MID INT,
	@JSONData NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
    insert into [dbo].pangya_string(str) values (@JSONData)

	UPDATE [dbo].Pangya_Mail SET IsReceiveItem = 1, IsRead = 1 WHERE MID = @MID
    
    UPDATE [DBO].Pangya_Mail_Item
    SET	APPLY_ITEM_ID = JSON.ItemAddedIndex,
    	RELEASE_DATE = GETDATE()
    FROM OPENJSON(@JSONData, '$.MailUpdate')
    WITH (
    	MailIndex INT,
        ItemAddedIndex INT
    ) AS JSON
    WHERE IDX = JSON.MailIndex
END
GO

