# sqlscripts
Some useful scripts that I use in BI projects

## Date Dimension
CreateDateDimension.sql creates and populates a basic data dimension for SQL datawarehousing projects. Defaults to a date range of 2000-01-01 to 2030-12-31 but easily configurable with two parameters.

Includes a function to calculate the date of Easter based on the Gregorian calendar, which can be used to flag Good Friday, and Easter Monday as non-working/bank holidays.
