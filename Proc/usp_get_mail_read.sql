USE [Pangya]
GO

/****** Object:  StoredProcedure [dbo].[USP_GET_MAIL_READ]    Script Date: 7/8/2560 0:46:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[USP_GET_MAIL_READ] @UID INT
	,@MAIL_IDX INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT Main.*
		,B.TYPEID
		,B.QTY
		,CASE 
			WHEN B.DAY > 0
				THEN 1
			ELSE 0
			END AS IsTime
		,B.Day
	FROM (
		SELECT MID
			,Sender
			,RegDate
			,Msg
			,IsRead
		FROM [dbo].Pangya_Mail
		WHERE UID = @UID
			AND MID = @MAIL_IDX
			AND IsDeleted = 0
		) Main
	LEFT JOIN [dbo].Pangya_Mail_Item B ON B.MAIL_IDX = Main.MID
		AND B.RELEASE_DATE IS NULL

	UPDATE [dbo].Pangya_Mail
	SET IsRead = 1
	WHERE MID = @MAIL_IDX
		AND IsRead = 0
END
GO

