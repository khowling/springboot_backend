:setvar SQLCMDLOGINTIMEOUT 60


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

:Connect  $(SQLCMDSERVER) -U $(user) -P $(passwd)

USE $(dbname);
go
CREATE TABLE profile (id INT NOT NULL IDENTITY(1,1) PRIMARY KEY, first_name nvarchar(100),  last_name nvarchar(100));
go
