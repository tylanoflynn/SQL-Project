What are your risk areas? Identify and describe them.

- Removing information when cleaning data



QA Process:
Describe your QA process and include the SQL queries used to execute it.

### DATA CLEANING PROCESS

## all_sessions

# Data cleaning

The first step of cleaning the data in all_sessions was reformatting the fullvisitorids to be unique 15 character strings identifying the site visitors. In order to do this I used the CTE clean\_all\_sessions (shortened for brevity):

``` SQL
WITH clean_all_sessions AS
(
	SELECT TRANSLATE(fullvisitorid, '.', '')::VARCHAR(15) fullvisitorid,
		channelgrouping,
		...
		ecommerceaction_step,
		ecommerceaction_option
	FROM all_sessions
)
```

After this I used the query

``` SQL
SELECT COUNT(DISTINCT fullvisitorid) FROM clean_all_sessions
INTERSECT
SELECT COUNT(DISTINCT fullvisitorid) FROM all_sessions
```

to insure that no distinct fullvisitorids were lost in the cleaning process. Further, 
