

--Create the Date Dimension table
--Drop it if it exists
DROP TABLE IF EXISTS [dbo].[DimDate]
GO

/****** Object:  Table [dbo].[DimDate]    Script Date: 08/07/2018 17:38:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimDate](
	[DateId] [int] NULL,
	[DayofMonth] [tinyint] NULL,
	[DayName] [nvarchar](30) NULL,
	[DayShortName] [nvarchar](3) NULL,
	[Week] [tinyint] NULL,
	[CalenderMonth] [tinyint] NULL,
	[CalendarMonthName] [nvarchar](30) NULL,
	[CalendarMonthShortName] [nvarchar](3) NULL,
	[CalendarQuarter] [int] NULL,
	[CalendarYear] [int] NULL,
	[Weekday] [int] NULL,
	[DayOfYear] [int] NULL,
	[FiscalYear] [varchar](7) NULL,
    [FiscalQuarter] [tinyint] NULL,
    [FiscalQuarterName] nvarchar(2) NULL,
    [FiscalMonth] [tinyint] NULL,
	[IsLastDayOfMonth] [int] NOT NULL,
	[IsWeekday] [int] NOT NULL,
	[UKShortDate] [char](8) NULL,
	[date] [date] NULL
) ON [PRIMARY]
GO

--INSERT the dates
--Change the @dt value to the desired start date
--and the @endDate value to the desired end date of the dimension
DECLARE @dt date, @endDate date

SET @dt = '2000-01-01'
SET @endDate = '2030-12-31'

WHILE @dt <= @endDate

BEGIN
    INSERT INTO dbo.DimDate 

    SELECT 
    YEAR(@dt) * 10000 + MONTH(@dt) * 100 + DAY(@dt) DateId
    ,Day(@dt)                                       DayofMonth
    ,DATENAME(weekday,@dt)                          DayName
    ,LEFT(DATENAME(weekday,@dt),3)                  DayShortName
    ,DATEPART(week,@dt)                             Week
    ,Month(@dt)                                     CalenderMonth
    ,DATENAME(MONTH,@Dt)                            CalendarMonthName
    ,LEFT(DATENAME(MONTH,@dt),3)                    CalendarMonthShortName
    ,DATEPART(Q,@dt)                                CalendarQuarter
    ,Year(@dt)                                      CalendarYear
    ,DATEPART(WEEKDAY,@dt)                          Weekday
    ,DATEPART(DAYOFYEAR,@dt)                        DayOfYear
    ,CASE WHEN MONTH(@dt) > 3 THEN
        CAST(YEAR(@dt) AS CHAR(4))  + '-' + CAST(RIGHT(YEAR(@dt) + 1,2) AS CHAR(2))
     ELSE CAST(YEAR(@dt)-1 AS CHAR(4)) + '-' + CAST(RIGHT(YEAR(@dt),2) AS CHAR(2))
    END AS                                          FiscalYear
    ,IIF(DATEPART(Q,@dt) > 1, DATEPART(Q,@dt) - 1, DATEPART(Q,@dt) + 3)FiscalQuarter
    ,IIF(DATEPART(Q,@dt) > 1, 'Q' + CAST(DATEPART(Q,@dt) - 1 AS CHAR(1)), 'Q' + CAST(DATEPART(Q,@dt) + 3 AS CHAR(1))) FiscalQuarter
    ,IIF(MONTH(@dt) > 3, MONTH(@dt) -3, MONTH(@dt) + 9) FiscalMonth
    ,IIF(@dt = EOMONTH(@dt), 1,0)                   IsLastDayOfMonth
    ,IIF(DATEPART(WEEKDAY,@dt) IN (1,7) , 0,-1)     IsWeekday
    ,CONVERT(char(8),@dt,3)                         UKShortDate
    ,@dt                                            date  --default ISO 8601 date format

     SET @dt = DATEADD(DAY,1,@dt)
END

-- delete dbo.DimDate 