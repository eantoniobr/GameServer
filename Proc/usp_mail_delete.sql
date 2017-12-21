USE [Pangya]
GO

/****** Object:  StoredProcedure [dbo].[USP_MAIL_DELETE]    Script Date: 7/8/2560 0:46:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		TOP
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[USP_MAIL_DELETE] 
	@UID INT,
	@MAIL_ID INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Code TINYINT = 0

	IF EXISTS (SELECT 1 FROM [dbo].Pangya_Mail WHERE UID = @UID AND MID = @MAIL_ID AND IsDeleted = 0) BEGIN
		IF EXISTS (SELECT 1 FROM [dbo].Pangya_Mail_Item WHERE MAIL_IDX = @MAIL_ID AND RELEASE_DATE IS NULL) BEGIN
			SET @Code = 9 -- THERE ARE AN ITEM IN MAIL
		END ELSE BEGIN
			UPDATE [dbo].Pangya_Mail SET IsDeleted = 1 WHERE UID = @UID AND MID = @MAIL_ID
			SET @Code = 1
		END
	END ELSE BEGIN
		SET @Code = 10 -- MAIL NOT FOUND
	END

	SELECT @Code AS RET

END
GO

