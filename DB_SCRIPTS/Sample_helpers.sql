USE [GHT_sample_helper]
GO
/****** Object:  Table [dbo].[t_job_parameter]    Script Date: 26/08/2018 16:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_job_parameter](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[param_name] [varchar](100) NOT NULL,
	[param_value] [varchar](100) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[t_project]    Script Date: 26/08/2018 16:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_project](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[project_id] [int] NULL,
	[sample] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[t_user]    Script Date: 26/08/2018 16:31:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_user](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_login] [nvarchar](100) NULL,
	[sample] [int] NULL
) ON [PRIMARY]
GO
