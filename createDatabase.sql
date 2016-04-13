create database DBManagement;
go

use DBManagement
go

CREATE TABLE [dbo].[dbs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[database_name] [varchar](50) NULL,
	[owner] [varchar](50) NULL,
	[created] [datetime] NULL,
	[purpose] [varchar](100) NULL,
	[database_server] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[dbs] ADD  DEFAULT (NULL) FOR [created]
GO

CREATE TABLE [dbo].[DBFifoQueue](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Operation] [varchar](10) NULL,
	[DatabaseName] [varchar](10) NULL,
	[InsertDate] [datetime] NULL,
	[Username] [varchar](50) NULL,
 CONSTRAINT [PK__FifoQueue] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[usage](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[database_name] [varchar](50) NULL,
	[operation] [varchar](10) NULL,
	[username] [varchar](50) NULL,
	[actionDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  StoredProcedure [dbo].[dequeueFifo]    Script Date: 4/12/2016 3:12:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[dequeueFifo] (@operation varchar(10) OUTPUT, @databasename varchar(10) OUTPUT, @username varchar(50) OUTPUT)
as
  set nocount on;
  DECLARE @payloadTable table (operation varchar(10), databasename varchar(10), username varchar(50));

  with cte as (
    select top(1) Operation, DatabaseName, Username
      from dbo.DBFifoQueue with (rowlock, readpast)
    order by Id)
  delete from cte
    output deleted.operation, deleted.DatabaseName, deleted.Username INTO @payloadTable;
  select @operation = Operation, @databasename = DatabaseName, @username = Username from @payloadTable;
GO

