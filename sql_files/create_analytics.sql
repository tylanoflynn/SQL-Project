DROP TABLE analytics;
CREATE TABLE analytics (
visitnumber INT,
visitid NUMERIC,
visitstarttime NUMERIC,
date DATE,
fullvisitorid TEXT,
userid TEXT,
channelgrouping TEXT,
socialengagementtype TEXT,
units_sold TEXT,
pageviews INT,
timeonsite TEXT,
bounces INT,
revenue TEXT,
unit_price INT
)

SELECT * FROM analytics
WITH cte_analytics_truncid AS
(
	SELECT fullvisitorid::VARCHAR(14) idtrunc, * 
	FROM analytics LIMIT 100
),

cte_allsessions_truncid AS
(
	SELECT TRANSLATE(fullvisitorid, '.', '')::VARCHAR(14) idtrunc, *
	FROM all_sessions LIMIT 100
)

SELECT idtrunc FROM cte_analytics_truncid
INTERSECT
SELECT idtrunc FROM cte_allsessions_truncid

SELECT DISTINCT fullvisitorid FROM analytics WHERE fullvisitorid LIKE '0%'
SELECT DISTINCT fullvisitorid FROM analytics

SELECT fullvisitorid, COUNT(DISTINCT visitid) FROM analytics GROUP BY fullvisitorid