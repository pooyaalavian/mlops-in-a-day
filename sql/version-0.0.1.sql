
CREATE TABLE [dbo].[prediction]
(
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    event_ts DATETIME,
    event_id NVARCHAR(10),
    inputs NVARCHAR(500),
    prediction DECIMAL(10,4)
)

CREATE TABLE [dbo].[outcome]
(
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    event_ts DATETIME,
    event_id NVARCHAR(10),
    inputs NVARCHAR(500),
    outcome DECIMAL(10,4)
)


