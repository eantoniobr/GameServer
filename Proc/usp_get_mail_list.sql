USE [Pangya]
GO

/****** Object:  StoredProcedure [dbo].[USP_GET_MAIL_LIST]    Script Date: 7/8/2560 0:46:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		TOP
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[USP_GET_MAIL_LIST] @UID INT
	,@PAGE INT
	,@TOTAL INT
	,@READ TINYINT -- 1 ONLY NOT READ , 2 ALL
AS
BEGIN
	SET NOCOUNT ON;

	SELECT CEILING(Q.QTY * 1.0 / @TOTAL) AS MAIL_TOTAL
	FROM (
		SELECT QTY = COUNT(1)
		FROM [dbo].Pangya_Mail
		WHERE UID = @UID
			AND IsDeleted = 0
		) Q

	SELECT MailMain.MID
		,MailMain.Sender
		,MailMain.IsReceiveItem
		,MailMain.IsRead
		,CASE 
			WHEN MailMain.IsReceiveItem = 1
				OR A.TYPE_ID IS NULL
				THEN 0
			ELSE A.TYPE_ID
			END AS TYPE_ID
		,CASE 
			WHEN MailMain.IsReceiveItem = 1
				OR A.QTY IS NULL
				THEN 0
			ELSE A.QTY
			END AS QTY
		,CASE 
			WHEN [dbo].UDF_PARTS_GROUP(A.TYPE_ID) = 9
				THEN (
						CASE 
							WHEN D.M_COUNT > 0
								THEN 1
							ELSE D.M_COUNT
							END
						)
			ELSE (D.M_COUNT)
			END AS TOTAL_ITEM
		,CASE 
			WHEN A.DAY > 0
				THEN 1
			ELSE 0
			END AS IsTime
		,A.DAY
		,B.UCC_UNIQUE
	FROM (
		SELECT MID
			,Sender
			,IsReceiveItem
			,IsRead
		FROM [dbo].Pangya_Mail
		WHERE UID = @UID
			AND IsDeleted = 0
			AND IsRead BETWEEN 0
				AND CASE 
						WHEN @READ = 1
							THEN 0
						ELSE 1
						END
		ORDER BY MID DESC OFFSET (@PAGE - 1) * @TOTAL ROWS FETCH NEXT @TOTAL ROWS ONLY
		) MailMain
	LEFT JOIN [dbo].Pangya_Mail_SetItem A ON A.MAIL_IDX = MailMain.MID
	OUTER APPLY (
		SELECT COUNT(1) AS M_COUNT
		FROM [dbo].Pangya_Mail_Item D
		WHERE D.MAIL_IDX = MailMain.MID
			AND RELEASE_DATE IS NULL
		) D
	OUTER APPLY (
		SELECT TOP 1 *
		FROM [dbo].Pangya_Mail_Item B
		WHERE B.MAIL_IDX = A.MAIL_IDX
		) B
	ORDER BY MailMain.MID DESC --FOR JSON AUTO
END
GO

