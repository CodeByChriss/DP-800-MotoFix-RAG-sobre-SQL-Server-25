USE master;
GO

EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

EXECUTE sp_configure 'external rest endpoint enabled';
GO