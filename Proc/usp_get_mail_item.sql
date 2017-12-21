USE [Pangya]
GO

/****** Object:  StoredProcedure [dbo].[USP_GET_MAIL_ITEM]    Script Date: 7/8/2560 1:19:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		TOP
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[USP_GET_MAIL_ITEM] @UID INT
	,@MAIL_ID INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT B.TYPEID
		,B.QTY
		,B.IDX
		,CASE 
			WHEN B.DAY > 0
				THEN 1
			ELSE 0
			END AS IsTime
		,B.DAY
	FROM (
		SELECT MID
		FROM [dbo].Pangya_Mail
		WHERE UID = @UID
			AND MID = @MAIL_ID
			AND IsReceiveItem = 0
		) A
	INNER JOIN [dbo].Pangya_Mail_Item B ON B.MAIL_IDX = A.MID
END
GO

