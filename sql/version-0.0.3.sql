
CREATE PROCEDURE sp_calculate_mse
    @start_ts DATETIME,
    @end_ts DATETIME
AS
BEGIN
    DECLARE @sq_error FLOAT
    DECLARE @n FLOAT
    SET NOCOUNT ON

    SELECT @sq_error = SUM(POWER([error], 2)), @n=COUNT(*)
    FROM [dbo].[vMatched]
    WHERE event_ts BETWEEN @start_ts AND @end_ts

    SELECT @sq_error / @n AS mse
END

