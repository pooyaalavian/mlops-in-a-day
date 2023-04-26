
CREATE VIEW [dbo].[vMatched]
AS
    SELECT
        P.event_id, P.event_ts,
        P.prediction, Q.outcome,
        [error] = P.prediction - Q.outcome
    FROM [dbo].[prediction] P
        JOIN [dbo].[outcome] Q
        ON P.event_id = Q.event_id

