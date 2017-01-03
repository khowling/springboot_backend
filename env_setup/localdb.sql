sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'user instance timeout', 300;
RECONFIGURE;
GO
DROP DATABASE IF EXISTS $(dbname);
go
DROP LOGIN $(user)
go
CREATE LOGIN $(user) WITH PASSWORD = '$(passwd)';
go
CREATE DATABASE $(dbname);
go
USE $(dbname);
go
CREATE USER $(user) FOR LOGIN $(user);
go
ALTER ROLE db_owner ADD MEMBER $(user);
go
:Connect  $(SQLCMDSERVER) -l $(SQLCMDLOGINTIMEOUT) -U $(user) -P $(passwd)

USE $(dbname);
go

:r src\main\resources\import.sql