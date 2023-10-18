

/*SQL Server 2022*/
USE [master]
GO
EXEC sp_configure
	@configname = 'polybase enabled',
	@configvalue = 1;
GO
RECONFIGURE;
GO
--To insert data, first we need to make sure that
--PolyBase insertion is turned on.
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE
GO
EXEC sp_configure
	@configname = 'allow polybase export',
	@configvalue = 1;
GO
RECONFIGURE;
GO
-- Now restart the SQL Server database engine service and the two PolyBase services.



USE [master]
GO
IF (DB_ID('Wirtualizacja') IS NULL)
BEGIN
	CREATE DATABASE Wirtualizacja
END
GO
USE Wirtualizacja
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'TdH49Kat!';



USE Wirtualizacja
GO
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'TdH49Kat!';
GO
	SELECT *
	FROM sys.database_scoped_credentials
	WHERE name = N'AzureStorageCredential'
	
	CREATE DATABASE SCOPED CREDENTIAL AzureStorageCredential
	WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
	SECRET = 'sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2023-10-31T09:15:27Z&st=2023-09-20T01:15:27Z&spr=https&sig=PSQG2AFmAymXGGS4Wov6aP7LehlJuPp%2BPVuakoUy5cM%3D';





	SELECT *
	FROM sys.external_data_sources 
	WHERE name = N'sqlday2023blobs'

	CREATE EXTERNAL DATA SOURCE sqlday2023blobs WITH
	(
		LOCATION = 'abs://bronze@sqlday2023blobs.blob.core.windows.net',
		CREDENTIAL = AzureStorageCredential
	);


    SELECT *
    FROM sys.external_file_formats 
    WHERE name = N'CsvFileFormat'

    CREATE EXTERNAL FILE FORMAT CsvFileFormat WITH
    (
        FORMAT_TYPE = DELIMITEDTEXT,
        FORMAT_OPTIONS
        (
            FIELD_TERMINATOR = N',',
            USE_TYPE_DEFAULT = True,
            STRING_DELIMITER = '"',
            ENCODING = 'UTF8'
        )
    );


    SELECT *
    FROM sys.external_file_formats 
    WHERE name = N'CsvFileFormatWithHeader'

    CREATE EXTERNAL FILE FORMAT CsvFileFormatWithHeader WITH
    (
        FORMAT_TYPE = DELIMITEDTEXT,
        FORMAT_OPTIONS
        (
            FIELD_TERMINATOR = N',',
			FIRST_ROW = 2,
            USE_TYPE_DEFAULT = True,
            STRING_DELIMITER = '"',
            ENCODING = 'UTF8'
        )
    );



IF (OBJECT_ID('dbo.NorthCarolinaPopulation') IS NULL)
BEGIN
	CREATE EXTERNAL TABLE dbo.NorthCarolinaPopulation
	(
		SumLev INT NOT NULL,
		County INT NOT NULL,
		Place INT NOT NULL,
		IsPrimaryGeography BIT NOT NULL,
		[Name] VARCHAR(120) NOT NULL,
		PopulationType VARCHAR(20) NOT NULL,
		Year INT NOT NULL,
		Population INT NOT NULL
	)
	WITH
	(
        DATA_SOURCE = sqlday2023blobs,
		LOCATION = N'NorthCarolinaPopulation.csv',
		FILE_FORMAT = CsvFileFormatWithHeader,
		REJECT_TYPE = VALUE,
		REJECT_VALUE = 5
	);
END

--Note 13607 rows returned but CSV has 13611 (including one header)
SELECT
    ncp.SumLev AS SummaryLevel,
    ncp.County,
    ncp.Place,
    ncp.IsPrimaryGeography,
    ncp.Name,
    ncp.PopulationType,
    ncp.Year,
    ncp.Population
FROM dbo.NorthCarolinaPopulation ncp;
GO

--Filters work
SELECT
    ncp.Name,
    ncp.Population
FROM dbo.NorthCarolinaPopulation ncp
WHERE
    ncp.Year = 2017
    AND ncp.PopulationType = 'POPESTIMATE'
    AND ncp.County = 0
    AND ncp.SumLev = 162
ORDER BY
    Population DESC,
    Name ASC;
GO

--Normal table as I wanto to join to a SQL table
IF (OBJECT_ID('dbo.PopulationCenter') IS NULL)
BEGIN
    CREATE TABLE dbo.PopulationCenter
    (
        PopulationCenterName VARCHAR(30) NOT NULL PRIMARY KEY CLUSTERED
    );

    INSERT INTO dbo.PopulationCenter
    (
        PopulationCenterName
    )
    VALUES
        ('A'),
        ('B');
END
GO
IF (OBJECT_ID('dbo.CityPopulationCenter') IS NULL)
BEGIN
    CREATE TABLE dbo.CityPopulationCenter
    (
        CityName VARCHAR(120) NOT NULL,
        PopulationCenterName VARCHAR(30) NOT NULL,
        CONSTRAINT [PK_CityPopulationCenter]
            PRIMARY KEY CLUSTERED(CityName, PopulationCenterName)
    );
    INSERT INTO dbo.CityPopulationCenter
    (
        CityName,
        PopulationCenterName
    )
    VALUES
        ('Burlington city', 'A'),
        ('Greensboro city', 'A'),
        ('High Point city', 'A'),
        ('Winston-Salem city', 'B'),
        ('Apex town', 'B'),
        ('Cary town', 'B'),
        ('Chapel Hill town', 'B'),
        ('Durham city', 'B'),
        ('Raleigh city', 'B');
END
GO

SELECT
    ncp.Name,
    cpc.PopulationCenterName,
    ncp.Population
FROM dbo.NorthCarolinaPopulation ncp
    LEFT OUTER JOIN dbo.CityPopulationCenter cpc
        ON ncp.Name = cpc.CityName
WHERE
    ncp.Year = 2017
    AND ncp.PopulationType = 'POPESTIMATE'
    AND ncp.County = 0
    AND ncp.SumLev = 162
ORDER BY
    Population DESC,
    Name ASC;
GO

--Aggregations and other operations work too.
SELECT
    cpc.PopulationCenterName,
    SUM(ncp.Population) AS TotalPopulation
FROM dbo.NorthCarolinaPopulation ncp
    INNER JOIN dbo.CityPopulationCenter cpc
        ON ncp.Name = cpc.CityName
WHERE
    ncp.Year = 2017
    AND ncp.PopulationType = 'POPESTIMATE'
    AND ncp.County = 0
    AND ncp.SumLev = 162
GROUP BY
    cpc.PopulationCenterName;
GO



---DATALAKE
	SELECT *
	FROM sys.database_scoped_credentials
	WHERE name = N'DataLakeCredential'

	CREATE DATABASE SCOPED CREDENTIAL DataLakeCredential
	WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
	SECRET = 'sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupyx&se=2023-10-31T10:03:05Z&st=2023-09-20T01:03:05Z&spr=https&sig=fsTAB64vNjSf9KEkWhUXuMI5aanvyPY3sUmo6eyRM64%3D';


	SELECT *
	FROM sys.external_data_sources 
	WHERE name = N'SaleSmall'

	CREATE EXTERNAL DATA SOURCE SaleSmall WITH
	(
		LOCATION = 'adls://sqlday2023.dfs.core.windows.net/raw/sale-small',
		CREDENTIAL = DataLakeCredential
	);



    SELECT *
    FROM sys.external_file_formats 
    WHERE name = N'ParquetFileFormat'



    CREATE EXTERNAL FILE FORMAT ParquetFileFormat WITH
    (
        FORMAT_TYPE = PARQUET,
		DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
    );


IF (OBJECT_ID('dbo.SalesSmall') IS NULL)
BEGIN
	CREATE EXTERNAL TABLE dbo.SalesSmall
	(
		TransactionId UNIQUEIDENTIFIER NOT NULL,
		CustomerId INT NOT NULL,
		ProductId INT NOT NULL,
		Quantity INT NOT NULL,
		Price DECIMAL (38,18) NOT NULL,
		TotalAmount DECIMAL (38,18) NOT NULL,
		TransactionDate INT NOT NULL,
		ProfitAmount DECIMAL (38,18) NOT NULL,
		[Hour] int not null,
		[Minute]  int not null,
		StoreId int not null
	)
	WITH
	(
		DATA_SOURCE = SaleSmall,
		LOCATION = N'Year=2019/*/*/*/*.parquet',
		FILE_FORMAT = ParquetFileFormat
	);
END
GO


SELECT COUNT(*) FROM dbo.SalesSmall;
GO
SELECT TOP(10) * from dbo.SalesSmall;
GO
SELECT
	ProductId,
	AVG(Price) AS AvgPrice
FROM dbo.SalesSmall
GROUP BY
	ProductId
ORDER BY
	ProductId;
GO
SELECT
	SUBSTRING(CAST(TransactionId as VARCHAR(50)) ,1,10) AS TranModified,
	AVG(Price) AS AvgPrice
FROM dbo.SalesSmall
GROUP BY
	SUBSTRING(CAST(TransactionId as VARCHAR(50)) ,1,10)
ORDER BY
	TranModified;
GO



--SQL Server
	SELECT *
	FROM sys.database_scoped_credentials 
	WHERE name = N'DesktopCredentials'

	CREATE DATABASE SCOPED CREDENTIAL DesktopCredentials
	WITH IDENTITY = 'pbuser', Secret = 'TdH49Kat';




	SELECT *
	FROM sys.external_data_sources  
	WHERE name = N'Desktop'

	CREATE EXTERNAL DATA SOURCE Desktop WITH
	(
		LOCATION = 'sqlserver://This_is_a_name_fake_name',
		CONNECTION_OPTIONS = 'Server=VMSQL',
		PUSHDOWN = ON,
		CREDENTIAL = DesktopCredentials
	);


/*
Msg 46721, Level 20, State 1, Line 345
Login failed. The login is from an untrusted domain and cannot be used with Integrated authentication.
*/

IF (OBJECT_ID('dbo.SalesInvoiceLines') IS NULL)
BEGIN
	CREATE EXTERNAL TABLE [dbo].[SalesInvoiceLines]
	(
	[InvoiceLineID] [int] NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[TaxAmount] [decimal](18, 2) NOT NULL,
	[LineProfit] [decimal](18, 2) NOT NULL,
	[ExtendedPrice] [decimal](18, 2) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL
	)
	WITH
	(
		DATA_SOURCE = Desktop,
		LOCATION = 'wideworldimporters.Sales.InvoiceLines'
	);
END
GO


DBCC TRACEON (6408,-1)



SELECT
	*
FROM dbo.SalesInvoiceLines
WHERE InvoiceId = 47
GO




/*Excel*/


    SELECT *
    FROM sys.external_data_sources  
    WHERE name = N'NCExcel'

    CREATE EXTERNAL DATA SOURCE NCExcel WITH
    (
        LOCATION = 'odbc://noplace',
        CONNECTION_OPTIONS = 'Driver={Microsoft Excel Driver (*.xls, *.xlsx, *.xlsm, *.xlsb)}; DBQ=C:\sql_sample_databases\NorthCarolinaPopulation.xlsx'
    );



    SELECT *
    FROM sys.external_tables 
    WHERE name = N'NCTableFromExcel'

    CREATE EXTERNAL TABLE dbo.NCTableFromExcel
    (
        SUMLEV FLOAT(53),
        COUNTY FLOAT(53),
        PLACE FLOAT(53),
        PRIMGEO_FLAG FLOAT(53),
        NAME NVARCHAR(255),
        POPTYPE NVARCHAR(255),
        YEAR FLOAT(53),
        POPULATION FLOAT(53)
    )
    WITH
    (
        DATA_SOURCE = NCExcel,
        LOCATION = 'NorthCarolinaPopulation$'
 

SELECT * FROM dbo.NCTableFromExcel;



/*CosmosDB i CosmosDB*/


    SELECT *
    FROM sys.database_scoped_credentials 
    WHERE name = N'CosmosCredential'

    CREATE DATABASE SCOPED CREDENTIAL CosmosCredential
    WITH IDENTITY = 'damian', Secret = 'pwd';


    SELECT *
    FROM sys.external_data_sources 
    WHERE name = N'CosmosDB'

    CREATE EXTERNAL DATA SOURCE CosmosDB WITH
    (
        LOCATION = 'mongodb://damianpolybasetest.mongo.cosmos.azure.com:10255',
        CONNECTION_OPTIONS = 'ssl=true',
        CREDENTIAL = CosmosCredential,
        PUSHDOWN = ON

	)

    SELECT *
    FROM sys.external_tables  
    WHERE name = N'Volcano'

    CREATE EXTERNAL TABLE dbo.Volcano
    (
        _id NVARCHAR(100) NOT NULL, 
        VolcanoName NVARCHAR(100) NOT NULL, 
        Country NVARCHAR(100) NULL, 
        Region NVARCHAR(100) NULL,
        Location_Type NVARCHAR(100) NULL,
        Elevation INT NULL,
        Type NVARCHAR(100) NULL,
        Status NVARCHAR(200) NULL,
        LastEruption NVARCHAR(300) NULL,
        [Volcano_Coordinates] FLOAT(53)
    )
    WITH
    (
        DATA_SOURCE = CosmosDB,
        LOCATION='PolyBaseTest.Volcano'
    );



SELECT * FROM dbo.Volcano;
GO


SELECT DISTINCT
	v._id,
    v.VolcanoName,
    v.Country,
    v.Region,
    v.Elevation,
    v.Type,
    v.Status,
    v.LastEruption
FROM dbo.Volcano v;
GO


SELECT *
INTO #Volcanoes
FROM dbo.Volcano;

SELECT
	v._id,
    v.VolcanoName,
    v.Country,
    v.Region,
    v.Location_Type AS LocationType,
    STRING_AGG(v.Volcano_Coordinates, ',') AS Coordinates,
    v.Elevation,
    v.Type,
    v.Status,
    v.LastEruption
FROM #Volcanoes v
GROUP BY
	v._id,
    v.VolcanoName,
    v.Country,
    v.Region,
    v.Location_Type,
    v.Elevation,
    v.Type,
    v.Status,
    v.LastEruption
ORDER BY
    v.Elevation ASC;
GO


    SELECT *
    FROM sys.external_tables 
    WHERE name = N'Volcano2'

    CREATE EXTERNAL TABLE dbo.Volcano2
    (
        _id NVARCHAR(100) NOT NULL, 
        VolcanoName NVARCHAR(100) NOT NULL, 
        Country NVARCHAR(100) NULL, 
        Region NVARCHAR(100) NULL,
        Location_Type NVARCHAR(100) NULL,
        Elevation INT NULL,
        Type NVARCHAR(100) NULL,
        Status NVARCHAR(200) NULL,
        LastEruption NVARCHAR(300) NULL
    )
    WITH
    (
        DATA_SOURCE = CosmosDB,
        LOCATION='PolyBaseTest.Volcano'
    );


SELECT * FROM dbo.Volcano2;
GO