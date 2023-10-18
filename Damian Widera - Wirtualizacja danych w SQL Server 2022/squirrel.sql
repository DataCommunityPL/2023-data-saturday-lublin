/*squirrels*/
	SELECT *
	FROM sys.database_scoped_credentials
	WHERE name = N'DataLakeCredential'

	CREATE DATABASE SCOPED CREDENTIAL DataLakeCredential
	WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
	SECRET = 'sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupyx&se=2023-10-31T10:03:05Z&st=2023-09-20T01:03:05Z&spr=https&sig=fsTAB64vNjSf9KEkWhUXuMI5aanvyPY3sUmo6eyRM64%3D';


	SELECT *
	FROM sys.external_data_sources 
	WHERE name = N'SquirrelDataSource'

	CREATE EXTERNAL DATA SOURCE SquirrelDataSource WITH
	(
		LOCATION = 'adls://sqlday2023.dfs.core.windows.net/bronze/us_public_adata',
		CREDENTIAL = DataLakeCredential
	);

	drop external file format CsvFileFormatWithHeader
	SELECT *
    FROM sys.external_file_formats 
    WHERE name = N'CsvFileFormatWithHeader'

    CREATE EXTERNAL FILE FORMAT CsvFileFormatWithHeader WITH
    (
        FORMAT_TYPE = DELIMITEDTEXT,
        FORMAT_OPTIONS
        (
            FIELD_TERMINATOR = N';',
			FIRST_ROW = 2,
            USE_TYPE_DEFAULT = True,
            STRING_DELIMITER = '"',
            ENCODING = 'UTF16'
        )
    );


drop external table dbo.squirrel
IF (OBJECT_ID('dbo.Squirrel') IS NULL)
BEGIN
	CREATE EXTERNAL TABLE dbo.Squirrel
	(
		X VARCHAR(50) NOT NULL,
		Y VARCHAR(50) NOT NULL ,
		[Unique Squirrel ID] VARCHAR(50) NOT NULL,
		[Hectare Squirrel Number] VARCHAR(50)  NOT NULL,
		Age VARCHAR(50) ,
		[Primary Fur Color] VARCHAR(50) ,
		[Highlight Fur Color] VARCHAR(50)
	)
	WITH
	(
		DATA_SOURCE = SquirrelDataSource,
		LOCATION = N'2018_Central_Park_Squirrel_Census_-_Squirrel_Data Small.csv',
		FILE_FORMAT = CsvFileFormatWithHeader
	);
END
GO


select * from dbo.Squirrel

