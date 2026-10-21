USE master;
GO

IF DB_ID(N'MotoFix') IS NOT NULL
BEGIN
    ALTER DATABASE MotoFix SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MotoFix;
END
GO

CREATE DATABASE MotoFix;
GO

SELECT name, compatibility_level, collation_name
FROM sys.databases
WHERE name = N'MotoFix';
GO
