

/*
Author: Steve Flynn, Data Agile
Creates a date dimension for use in BI projects
Needs start and end dates to be provided, but defaults to 1 Jan 2000 to 31 Dec 2039
Some columns need updating following creation depending on local factors.
These are IsBankHoliday and IsWorkingDay
These will vary depending on location

*/

--Create the Date Dimension table
--Drop it if it exists
DROP TABLE IF EXISTS [dbo].[DimDate] --SQL 2016 and above
--for older versions use 
--IF OBJECT_ID('dbo.DimDate') IS NOT NULL DROP TABLE [dbo].[DimDate]
GO

/****** Object:  Table [dbo].[DimDate]    Script Date: 08/07/2018 17:38:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--------------------------
--Create a function to return the date of Easter
--This is used to calculate the Bank Holidays for Good Friday and Easter Monday
CREATE OR ALTER FUNCTION [dbo].[fn_getEasterDate] (
	@xYear int
)
RETURNS date
AS
BEGIN
	/*Calculate date of easter based on Year passed*/
	/*Based on Anonymous Gregorian Algorithm, also known as the Meeus/Jones/Butcher algorithm*/
	Declare @dGregorianEaster date
	Declare @a int, @b int, @c int, @d int, @e int, @f int, @g int, @h int, @i int, @k int, @L int, @m int, @month int, @day int
	set @a = @xYear % 19
	set @b = floor(@xyear / 100)
	set @c = @xYear % 100
	set @d = floor(@b / 4)
	set @e = @b % 4
	set @f = floor((@b + 8) / 25)
	set @g = floor((@b - @f + 1)/3)
	set @h = (19*@a + @b - @d - @g + 15) % 30
	set @i = floor(@c / 4)
	set @k = @c % 4
	set @L = (32 + 2*@e + 2*@i - @h - @k) % 7
	set @m = floor((@a + 11*@h + 22*@L) / 451)
	set @month = floor((@h + @L - 7*@m + 114) / 31)
	set @day = (@h + @L - 7*@m + 114) % 31 + 1
	set @dGregorianEaster = cast( cast(@xYear as char(4)) + '-' + right('0' + cast(@month as varchar(2)), 2)+ '-' + right('0' + cast(@day as varchar(2)), 2) as date)
	RETURN(@dGregorianEaster)
END
GO

DROP TABLE IF EXISTS dbo.DimDATE

CREATE TABLE [dbo].[DimDate](
	[DateId] [int] NOT NULL,
	[DayofMonth] [tinyint] NOT NULL,
	[DayName] [nvarchar](30) NOT NULL,
	[DayShortName] [nvarchar](3) NOT NULL,
	[Week] [tinyint] NOT NULL,
	[CalendarMonth] [tinyint] NOT NULL,
	[CalendarMonthName] [nvarchar](30) NOT NULL,
	[CalendarMonthShortName] [nvarchar](3) NOT NULL,
	[CalendarQuarter] [int] NOT NULL,
	[CalendarYear] [int] NOT NULL,
	[Weekday] [int] NOT NULL,
	[DayOfYear] [int] NOT NULL,
	[FiscalYear] [varchar](7) NOT NULL,
    [FiscalQuarter] [tinyint] NOT NULL,
    [FiscalQuarterName] nvarchar(2) NOT NULL,
    [FiscalMonth] [tinyint] NOT NULL,
	[IsLastDayOfMonth] [bit]  NOT NULL,
	[IsWeekday] [bit]  NOT NULL,
	[IsBankHoliday] [bit] NOT NULL,
	[IsWorkingDay] [bit] NOT NULL,
	[UKShortDate] [char](8) NOT NULL,
	[date] [date] NOT NULL,
    CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED 
(
	[DateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

--INSERT the dates
--Change the @dt value to the desired start date
--and the @endDate value to the desired end date of the dimension
DECLARE @dt date, @endDate date

SET @dt = '2000-01-01'
SET @endDate = '2039-12-31'

WHILE @dt <= @endDate

BEGIN
    INSERT INTO dbo.DimDate 

    SELECT 
    YEAR(@dt) * 10000 + MONTH(@dt) * 100 + DAY(@dt) DateId
    ,Day(@dt)                                       DayofMonth
    ,DATENAME(weekday,@dt)                          DayName
    ,LEFT(DATENAME(weekday,@dt),3)                  DayShortName
    ,DATEPART(week,@dt)                             Week
    ,Month(@dt)                                     CalendarMonth
    ,DATENAME(MONTH,@Dt)                            CalendarMonthName
    ,LEFT(DATENAME(MONTH,@dt),3)                    CalendarMonthShortName
    ,DATEPART(Q,@dt)                                CalendarQuarter
    ,Year(@dt)                                      CalendarYear
    ,DATEPART(WEEKDAY,@dt)                          Weekday
    ,DATEPART(DAYOFYEAR,@dt)                        DayOfYear
    ,IIF (MONTH(@dt) > 3
         ,CAST(YEAR(@dt) AS CHAR(4))  + '-' + CAST(RIGHT(YEAR(@dt) + 1,2) AS CHAR(2))
         ,CAST(YEAR(@dt)-1 AS CHAR(4)) + '-' + CAST(RIGHT(YEAR(@dt),2) AS CHAR(2)))
     FiscalYear
    ,IIF(DATEPART(Q,@dt) > 1, DATEPART(Q,@dt) - 1, DATEPART(Q,@dt) + 3)FiscalQuarter
    ,IIF(DATEPART(Q,@dt) > 1, 'Q' + CAST(DATEPART(Q,@dt) - 1 AS CHAR(1)), 'Q' + CAST(DATEPART(Q,@dt) + 3 AS CHAR(1))) FiscalQuarter
    ,IIF(MONTH(@dt) > 3, MONTH(@dt) -3, MONTH(@dt) + 9) FiscalMonth
    ,IIF(@dt = EOMONTH(@dt), 1,0)                   IsLastDayOfMonth
    ,IIF(DATEPART(WEEKDAY,@dt) IN (1,7) , 0,1)     IsWeekday
	,0												IsBankHoliday --defaults to 0, must be updated after creation
	,IIF(DATEPART(WEEKDAY,@dt) IN (1,7) , 0,1)     IsWorkingDay  --defaults to 1 for weekdays, 0 for weekends.  Must updated to add public holidays after creation
    ,CONVERT(char(8),@dt,3)                         UKShortDate
    ,@dt                                            date  --default ISO 8601 date format

     SET @dt = DATEADD(DAY,1,@dt)
END

GO


-- delete dbo.DimDate 
--Set Christmas day and boxing day
UPDATE dbo.DimDate

SET IsBankHoliday = 
--Bank Holidays in Scotland are different
CASE --New Year's day in England and Wales 
	WHEN CalendarMonth = 1 AND DayofMonth = 1 AND Weekday NOT IN(1,7)
		THEN CONVERT(bit,1)
	WHEN CalendarMonth = 1 AND ((DayOfMonth = 2 AND Weekday = 2) OR (DayOfMonth = 3 AND Weekday = 2))
		THEN CONVERT(bit,1)
	--Christmas and Boxing day
	 WHEN CalendarMonth=12 AND DayofMonth IN (25,26) AND Weekday NOT IN (1,7) 
		THEN CONVERT(bit, 1)
	 WHEN  CalendarMonth=12 AND DayofMonth= 28 AND Weekday IN (2,3) 
		THEN CONVERT(bit, 1)
	 WHEN  CalendarMonth=12 AND DayofMonth= 27 AND Weekday IN (2,3) 
		THEN CONVERT(bit, 1)
	--First May Bank Holiday
	 WHEN CalendarMonth=5 AND DayOfMonth BETWEEN 1 AND 7 AND Weekday = 2
		THEN CONVERT(bit, 1)
	--Second May Bank Holiday
	WHEN CalendarMonth = 5 AND DayOfMonth BETWEEN 24 AND 31 AND Weekday = 2
		THEN CONVERT(bit, 1)
	--August Bank Holiday
	WHEN CalendarMonth = 8 AND DayOfMonth BETWEEN 24 AND 31 AND Weekday = 2
		THEN CONVERT(bit, 1)
	ELSE CONVERT(bit, 0)
END

GO


--Set Easter Dates

DECLARE @y as int
DECLARE @easterday as date
SET @y = 2000
WHILE @y < 2040 BEGIN
	Select @easterday = dbo.fn_getEasterDate(@y)

	UPDATE dbo.DimDate
		Set ISBankHoliday = CONVERT(bit,1) 
	WHERE [date] = DATEADD(d,-2,@easterday) OR date = DATEADD(d,1,@easterday)

SET @y = @y+1
END

Go

UPDATE dbo.DimDate Set IsWorkingDay = 0 WHERE IsBankHoliday = 1

Go