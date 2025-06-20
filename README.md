# EquipmentApi

**EquipmentApi** — минимальное API-приложение на .NET 6, работающее как Windows-служба (через NSSM). Принимает JSON через HTTP POST, вызывает хранимую процедуру в SQL Server и «умно» обновляет или добавляет записи с помощью MERGE.

---

## 📂 Структура проекта

- **nuget.config** — источники NuGet-пакетов  
- **EquipmentApi.csproj** — конфигурация .NET 6  
- **Program.cs** — сам API-хостинг и логика обработки запросов  
- **InsertEquipmentFromJson** — хранимая процедура SQL Server с реализацией MERGE  
- **log.txt** — вывод логов (перенаправляется NSSM)

---

## 🔧 Предварительные требования

- [.NET SDK 6.0+](https://dotnet.microsoft.com/download)  
- SQL Server + SSMS  
- [NSSM (Non-Sucking Service Manager)](https://nssm.cc/download)  
- Postman (или аналог) для тестирования

---

## 🏗️ Установка и запуск

### 1. Сборка

```bash
dotnet publish -c Release -o C:\EquipmentApi\publish
```
### 2. Копирование

Скопируйте папку `publish` на сервер, например в `C:\EquipmentApi\publish`.

### 3. Установка службы (NSSM)

```powershell
cd C:\EquipmentApi\nssm\win64
.\nssm.exe install EquipmentApi
```

Path: C:\Program Files\dotnet\dotnet.exe

Arguments: EquipmentApi.dll

Startup directory: C:\EquipmentApi\publish

I/O → stdout/stderr: C:\EquipmentApi\publish\log.txt

Запуск службы:

```powershell
.\nssm.exe start EquipmentApi
```

## 🚀 Использование API

**Endpoint:**  
```http
POST http://<SERVER>:5050/api/equipment
Content-Type: application/json
```
Пример тела запроса:
```json
{
  "d": {
    "results": [
      {
        "EQUNR": "1001",
        "CREW_ID": "BR01",
        "CREW": "Бригада-1",
        "WERKS": "122333",
        "WERKS_NAME": "Объект Б",
        "EQKTX": "Компрессор",
        "EQUART": "CMPR",
        "EARTX": "Смазочный компрессор",
        "TYPBZ": "YY",
        "MAPAR": "M200",
        "HERST": "CompTech Inc.",
        "INVNR": "INV-456",
        "WELL": "Well-9"
      }
    ]
  }
}
```
**Успешный ответ:**
```json
{ "message": "Operation completed successfully" }
```
## 🧠 Хранимая процедура `InsertEquipmentFromJson`

```sql
CREATE PROCEDURE InsertEquipmentFromJson
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @data TABLE (
        EQUNR      NVARCHAR(50) PRIMARY KEY,
        CREW_ID    NVARCHAR(50),
        CREW       NVARCHAR(100),
        WERKS      NVARCHAR(50),
        WERKS_NAME NVARCHAR(100),
        EQKTX      NVARCHAR(100),
        EQUART     NVARCHAR(50),
        EARTX      NVARCHAR(100),
        TYPBZ      NVARCHAR(50),
        MAPAR      NVARCHAR(50),
        HERST      NVARCHAR(100),
        INVNR      NVARCHAR(100),
        WELL       NVARCHAR(100)
    );

    INSERT INTO @data
    SELECT *
    FROM OPENJSON(JSON_QUERY(@json, '$.d.results'))
    WITH (
      EQUNR      NVARCHAR(50)  '$.EQUNR',
      CREW_ID    NVARCHAR(50)  '$.CREW_ID',
      CREW       NVARCHAR(100) '$.CREW',
      WERKS      NVARCHAR(50)  '$.WERKS',
      WERKS_NAME NVARCHAR(100) '$.WERKS_NAME',
      EQKTX      NVARCHAR(100) '$.EQKTX',
      EQUART     NVARCHAR(50)  '$.EQUART',
      EARTX      NVARCHAR(100) '$.EARTX',
      TYPBZ      NVARCHAR(50)  '$.TYPBZ',
      MAPAR      NVARCHAR(50)  '$.MAPAR',
      HERST      NVARCHAR(100) '$.HERST',
      INVNR      NVARCHAR(100) '$.INVNR',
      WELL       NVARCHAR(100) '$.WELL'
    );

    MERGE dbo.Equipment AS target
    USING @data AS source
    ON target.EQUNR = source.EQUNR
    WHEN MATCHED THEN
        UPDATE SET
          CREW_ID    = source.CREW_ID,
          CREW       = source.CREW,
          WERKS      = source.WERKS,
          WERKS_NAME = source.WERKS_NAME,
          EQKTX      = source.EQKTX,
          EQUART     = source.EQUART,
          EARTX      = source.EARTX,
          TYPBZ      = source.TYPBZ,
          MAPAR      = source.MAPAR,
          HERST      = source.HERST,
          INVNR      = source.INVNR,
          WELL       = source.WELL
    WHEN NOT MATCHED THEN
        INSERT (EQUNR, CREW_ID, CREW, WERKS, WERKS_NAME, EQKTX, EQUART, EARTX, TYPBZ, MAPAR, HERST, INVNR, WELL)
        VALUES (source.EQUNR, source.CREW_ID, source.CREW, source.WERKS, source.WERKS_NAME, source.EQKTX, source.EQUART, source.EARTX, source.TYPBZ, source.MAPAR, source.HERST, source.INVNR, source.WELL);
END
```
## ✅ Проверка подключения

- **SSMS**  
  ```sql
  SELECT 1 AS TestConnection;
  ```
  sqlcmd
  ```bash
  sqlcmd -S YOUR_SERVER -d YOUR_DATABASE -U YOUR_USER -P YOUR_PASSWORD -Q "SELECT 1"
