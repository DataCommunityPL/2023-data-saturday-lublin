
/*

https://cloud.nordlocker.com/share/receiver/locker/unlock/5c1b3fba345dfe30cb4d507a3558137655aff84c7992dd48519c9085773a6deb#D5QV9D5kiAPm1acTlHgNsg
XEqnNu


.\minio.exe server c:\minio --console-address ":9001"
minioadmin
*/



EXEC sp_configure 'polybase enabled', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'allow polybase export', 1;
GO
RECONFIGURE;
GO

USE [WideWorldImporters]
GO
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'TdH49Kat!';
GO







USE [WideWorldImporters];
GO
IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 's3_wwi')
	DROP EXTERNAL DATA SOURCE s3_wwi;
IF EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE name = 's3://10.0.0.4:9000')
    DROP DATABASE SCOPED CREDENTIAL [s3://10.0.0.4:9000];
GO
CREATE DATABASE SCOPED CREDENTIAL [s3://10.0.0.4:9000]
WITH IDENTITY = 'S3 Access Key',
SECRET = 'damian:TdH49Kat';
GO




USE [WideWorldImporters];
GO
IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 's3_wwi')
	DROP EXTERNAL DATA SOURCE s3_wwi;
GO
CREATE EXTERNAL DATA SOURCE s3_wwi
WITH
(
 LOCATION = 's3://10.0.0.4:9000'
,CREDENTIAL =  [s3://10.0.0.4:9000]
);
GO





USE [WideWorldImporters];
GO
IF EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'ParquetFileFormat')
	DROP EXTERNAL FILE FORMAT ParquetFileFormat;
CREATE EXTERNAL FILE FORMAT ParquetFileFormat WITH (FORMAT_TYPE = PARQUET);
GO





USE [WideWorldImporters];
GO
IF OBJECT_ID('wwi_customer_transactions', 'U') IS NOT NULL
	DROP EXTERNAL TABLE wwi_customer_transactions;
GO
CREATE EXTERNAL TABLE wwi_customer_transactions
WITH (
    LOCATION = '/wwi/',
    DATA_SOURCE = s3_wwi,  
    FILE_FORMAT = ParquetFileFormat
) 
AS
SELECT * FROM Sales.CustomerTransactions;
GO





SELECT c.CustomerName, SUM(wct.OutstandingBalance) as total_balance
FROM wwi_customer_transactions wct
JOIN Sales.Customers c
ON wct.CustomerID = c.CustomerID
GROUP BY c.CustomerName
ORDER BY total_balance DESC;
GO


SELECT *
FROM OPENROWSET
	(BULK '/wwi/'
	, FORMAT = 'PARQUET'
	, DATA_SOURCE = 's3_wwi')
as [wwi_customer_transactions_file];
GO



USE [WideWorldImporters];
GO
CREATE STATISTICS wwi_ctb_stats ON wwi_customer_transactions (CustomerID) WITH FULLSCAN;
GO



SELECT * FROM sys.external_data_sources;
GO
SELECT * FROM sys.external_file_formats;
GO
SELECT * FROM sys.external_tables;
GO



USE [WideWorldImporters];
GO
EXEC sp_describe_first_result_set N'
SELECT *
FROM OPENROWSET
	(BULK ''/wwi/''
	, FORMAT = ''PARQUET''
	, DATA_SOURCE = ''s3_wwi'')
as [wwi_customer_transactions_file];';
GO


SELECT TOP 1 wwi_customer_transactions_file.filepath(), 
wwi_customer_transactions_file.filename()
FROM OPENROWSET
	(BULK '/wwi/'
	, FORMAT = 'PARQUET'
	, DATA_SOURCE = 's3_wwi')
as [wwi_customer_transactions_file];
GO



/*
backups
*/

IF EXISTS (SELECT * FROM sys.credentials WHERE name = 's3://10.0.0.4:9000/backups')
	DROP CREDENTIAL [s3://10.0.0.4:9000/backups];
GO
CREATE CREDENTIAL [s3://10.0.0.4:9000/backups]
WITH IDENTITY = 'S3 Access Key',
SECRET = 'minioadmin:minioadmin';
GO

USE MASTER;
GO
ALTER DATABASE WideWorldImporters SET RECOVERY FULL;
GO
BACKUP DATABASE WideWorldImporters
TO URL = 's3://10.0.0.4:9000/backups/wwi.bak'
WITH CHECKSUM, INIT, FORMAT;
GO
BACKUP DATABASE WideWorldImporters
TO URL = 's3://10.0.0.4:9000/backups/wwidiff.bak'
WITH CHECKSUM, INIT, FORMAT, DIFFERENTIAL
GO
BACKUP LOG WideWorldImporters
TO URL = 's3://10.0.0.4:9000/backups/wwilog.bak'
WITH CHECKSUM, INIT, FORMAT
GO
BACKUP DATABASE WideWorldImporters
FILE = 'WWI_UserData'
TO URL = 's3://10.0.0.4:9000/backups/wwiuserdatafile.bak'
WITH CHECKSUM, INIT, FORMAT;
GO



/*restore*/

GO
RESTORE VERIFYONLY FROM URL = 's3://10.0.0.4:9000/backups/wwi.bak';
GO
RESTORE HEADERONLY FROM URL = 's3://10.0.0.4:9000/backups/wwi.bak';
GO
RESTORE FILELISTONLY FROM URL = 's3://10.0.0.4:9000/backups/wwi.bak';
GO
DROP DATABASE IF EXISTS WideWorldImporters2;
GO
RESTORE DATABASE WideWorldImporters2 
FROM URL = 's3://10.0.0.4:9000/backups/wwi.bak'
WITH MOVE 'WWI_Primary' TO 'c:\sql_sample_databases\WideWorldImporters2.mdf',
MOVE 'WWI_UserData' TO 'c:\sql_sample_databases\WideWorldImporters2_UserData.ndf',
MOVE 'WWI_Log' TO 'c:\sql_sample_databases\WideWorldImporters2.ldf',
MOVE 'WWI_InMemory_Data_1' TO 'c:\sql_sample_databases\WideWorldImporters2_InMemory_Data_1';
GO