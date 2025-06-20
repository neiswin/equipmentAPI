DROP PROCEDURE IF EXISTS InsertEquipmentFromJson;
GO

CREATE PROCEDURE InsertEquipmentFromJson
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Извлекаем массив объектов из вложенного JSON "d.results"
    DECLARE @parsed NVARCHAR(MAX);
    SELECT @parsed = JSON_QUERY(@json, '$.d.results');

    DECLARE @data TABLE (
        EQUNR NVARCHAR(50) PRIMARY KEY,
        CREW_ID NVARCHAR(50),
        CREW NVARCHAR(100),
        WERKS NVARCHAR(50),
        WERKS_NAME NVARCHAR(100),
        EQKTX NVARCHAR(100),
        EQUART NVARCHAR(50),
        EARTX NVARCHAR(100),
        TYPBZ NVARCHAR(50),
        MAPAR NVARCHAR(50),
        HERST NVARCHAR(100),
        INVNR NVARCHAR(100),
        WELL NVARCHAR(100)
    );

    INSERT INTO @data (EQUNR, CREW_ID, CREW, WERKS, WERKS_NAME, EQKTX, EQUART, EARTX, TYPBZ, MAPAR, HERST, INVNR, WELL)
    SELECT 
        EQUNR, CREW_ID, CREW, WERKS, WERKS_NAME, EQKTX, EQUART, EARTX, TYPBZ, MAPAR, HERST, INVNR, WELL
    FROM OPENJSON(@parsed)
    WITH (
        EQUNR NVARCHAR(50),
        CREW_ID NVARCHAR(50),
        CREW NVARCHAR(100),
        WERKS NVARCHAR(50),
        WERKS_NAME NVARCHAR(100),
        EQKTX NVARCHAR(100),
        EQUART NVARCHAR(50),
        EARTX NVARCHAR(100),
        TYPBZ NVARCHAR(50),
        MAPAR NVARCHAR(50),
        HERST NVARCHAR(100),
        INVNR NVARCHAR(100),
        WELL NVARCHAR(100)
    );

    MERGE INTO dbo.Equipment AS target
    USING @data AS source
    ON target.EQUNR = source.EQUNR
    WHEN MATCHED AND (
        ISNULL(target.CREW_ID, '') <> ISNULL(source.CREW_ID, '')
        OR ISNULL(target.CREW, '') <> ISNULL(source.CREW, '')
        OR ISNULL(target.WERKS, '') <> ISNULL(source.WERKS, '')
        OR ISNULL(target.WERKS_NAME, '') <> ISNULL(source.WERKS_NAME, '')
        OR ISNULL(target.EQKTX, '') <> ISNULL(source.EQKTX, '')
        OR ISNULL(target.EQUART, '') <> ISNULL(source.EQUART, '')
        OR ISNULL(target.EARTX, '') <> ISNULL(source.EARTX, '')
        OR ISNULL(target.TYPBZ, '') <> ISNULL(source.TYPBZ, '')
        OR ISNULL(target.MAPAR, '') <> ISNULL(source.MAPAR, '')
        OR ISNULL(target.HERST, '') <> ISNULL(source.HERST, '')
        OR ISNULL(target.INVNR, '') <> ISNULL(source.INVNR, '')
        OR ISNULL(target.WELL, '') <> ISNULL(source.WELL, '')
    )
    THEN UPDATE SET
        CREW_ID = source.CREW_ID,
        CREW = source.CREW,
        WERKS = source.WERKS,
        WERKS_NAME = source.WERKS_NAME,
        EQKTX = source.EQKTX,
        EQUART = source.EQUART,
        EARTX = source.EARTX,
        TYPBZ = source.TYPBZ,
        MAPAR = source.MAPAR,
        HERST = source.HERST,
        INVNR = source.INVNR,
        WELL = source.WELL
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (EQUNR, CREW_ID, CREW, WERKS, WERKS_NAME, EQKTX, EQUART, EARTX, TYPBZ, MAPAR, HERST, INVNR, WELL)
         VALUES (EQUNR, CREW_ID, CREW, WERKS, WERKS_NAME, EQKTX, EQUART, EARTX, TYPBZ, MAPAR, HERST, INVNR, WELL);
END
GO
