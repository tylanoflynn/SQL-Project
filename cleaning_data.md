# Data Cleaning #

## Import ##

The first step in cleaning the data was identifying the types of data provided. The prompts I used to set up my tables were:

* all_sessions

``` SQL
CREATE TABLE all_sessions (
	fullVisitorId TEXT,
	channelGrouping TEXT,
	time INT,
	country TEXT,
	city TEXT,
	totalTransactionRevenue NUMERIC,
	transactions INT,
	timeOnSite INT,
	pageviews INT,
	sessionQualityDim INT,
	date DATE,
	visitId NUMERIC,
	type TEXT,
	productRefundAmount NUMERIC,
	productQuantity INT,
	productPrice NUMERIC,
	productRevenue NUMERIC,
	productSKU TEXT,
	v2ProductName TEXT,
	v2ProductCategory TEXT,
	productVariant TEXT,
	currencyCode TEXT,
	itemQuantity TEXT,
	itemRevenue NUMERIC,
	transactionRevenue NUMERIC,
	transactionID TEXT,
	pageTitle TEXT,
	searchKeyword TEXT,
	pagePathLevel1 TEXT,
	eCommerceAction_type TEXT,
	eCommerceAction_step INT,
	eCommerceAction_option TEXT
);
```

* analytics

``` SQL
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
);
```

* products

``` SQL
CREATE TABLE products (
	sku TEXT,
	name TEXT,
	orderedquantity INT,
	stocklevel INT,
	restockingleadtime INT,
	sentimentscore NUMERIC,
	sentimentMagnitude NUMERIC
);
```

* sales\_by\_sku

```SQL
CREATE TABLE sales_by_sku (
	productsku text,
	total_ordered INT
);

```

* sales\_report

```SQL
CREATE TABLE sales_by_sku (
	productsku text,
	total_ordered INT,
	name TEXT,
	stocklevel INT,
	restockingleadtime INT,
	sentimentscore NUMERIC,
	sentimentmagnitude NUMERIC
);

```

## Disambiguation and Normalization ##

I first wanted to match values between the all_sessions and analytics tables, and decided to search for a primary key for all_sessions to help faciliate this.

``` SQL
SELECT 'total rows', COUNT(*) from all_sessions
UNION
SELECT 'fullvisitorid', COUNT(DISTINCT fullvisitorid) FROM all_sessions
UNION
SELECT 'visitid', COUNT(DISTINCT visitid) FROM all_sessions
UNION
SELECT 'combined', COUNT(DISTINCT (visitid, fullvisitorid)) FROM all_sessions
UNION
SELECT 'visitid, productsku', COUNT(DISTINCT (visitid, productsku)) FROM all_sessions
UNION
SELECT '
```

Return:

?column? | count
---------|-------
fullvisitorid | 14223
visitid, fullvisitorid | 14561
visitid, productsku | 15129
visitid, fullvisitorid, productsku | 15129
visitid | 14556
producsku | 536
total rows | 15134

From this table it was apparent that the combination of visitid and productsku is sufficient to disambiguate all but 5 rows of all_sessions, with no improvement when fullvisitorid is used. Looking at the 5 duplicate rows, it appears that they are nearly identical, save for the time of purchase and a few other details. I decided that this could indicate that the same visitor purchased the same product at different times during the same visit, so it should not be treated as duplicate data. Instead, I decided to expand the primary key to include the time data. The final primary key that I settled on was (visitid, productsku, time), and this did in fact provide 15134 distinct rows. If future information was added that contained the same values for all 3 columns, I was comfortable with flagging and removing this information as duplicate.

For the analytics table I did not search for an appropriate primary key as all data that appeared to be serialized had many duplicates in the table. Instead, taking into account that it is named analytics and contains a lot of information that is either copied 1-to-1 from other tables or calculated based on values in other tables, I decided that it would be best to treat it like an out-of-place view. That said, there was a lot of information present in the analytics table that was not present elsewhere. I decided that it would be best to divy the information in analytics out into my other tables once I had better segregated and validated them.

To simplify all_sessions I checked for columns that were mainly NULL values using queries similar to

``` SQL
SELECT itemquantity
FROM all_sessions
WHERE itemquantity IS NOT NULL
```

This query in particular returned no values for itemquantity, so I removed it from the all_sessions table. I did the same with productrefundamount, itemrevenue, transactionrevenue (NOTE: not all transactionrevenue values were NULL, but they were duplicates of totaltransactionrevenue), and searchkeyword. Doing this pared all_sessions down to 27 usable columns of values.

Doing a similar check on analytics, I determined that, while some columns are sparsely populated, all contain some values.

It was immediately obvious when importing that there was a  lot of information that was duplicated between the tables. The only non-key values that were present in analytics and not present by name in other tables were ```visitnumber, visitstarttime, userid, socialengagementtype, units_sold, bounces, revenue, and unit_price```. Of these, ```userid``` contained only NULL values, ```units_sold``` is a likely duplicate of ```productquantity``` in the all_sessions table, ```revenue``` is a likely duplicate of ```productrevenue``` in all_sessions, and ```unit_price``` is a likely duplicate of ```productprice```. To test this, I first determined that there are 3896 ```DISTINCT fullvisitorid``` in all_sessions that are also present in analytics using

``` SQL
SELECT COUNT(DISTINCT ase.fullvisitorid) FROM
all_sessions ase
JOIN analytics a
ON ase.fullvisitorid = a.fullvisitorid
```

In a similar way I determined that ```visitid``` had 3630 distinct corresponding values in analytics, and that these were a subset of the ```fullvisitorid``` values by showing that 

```
SELECT COUNT(DISTINCT ase.fullvisitorid) FROM
all_sessions ase
JOIN analytics a
ON ase.fullvisitorid = a.fullvisitorid
WHERE ase.visitid = a.visitid
```

Also returned 3630 values. Further, I checked the dates of the rows in all_sessions that corresponded to rows in analytics with the same ```fullvisitorid``` and ```visitid``` and found that the dates only differed by one day where they differed at all. This could potentially be explained by the date information for these rows being pulled at different times near midnight, though the opacity of the time stamps in both of the tables made it difficult to say.

Based on this information I decided to join the data from analytics to all_sessions using fullvisitorid as the foreign key and check for duplicate columns.

The columns that stuck out to me as potential duplicates of information already contained in all_sessions were visitstarttime, date, channelgrouping, units_sold, pageviews, timeonsite, revenue, and unit_price, so I checked these individually using queries such as

```SQL
SELECT COUNT(DISTINCT (a.fullvisitorid, a.visitid))
FROM all_sessions ase
JOIN analytics a
ON (ase.fullvisitorid, a.visitid) = (a.fullvisitorid, a.visitid)
WHERE ase.time != a.visitstarttime
```

And comparing them to the total count of distinct fullvisitorids that are common between the two tables. By doing this I found that rows that were identified by the same fullvisitorid and visitid ase.time and a.visitstarttime were different values, where ase.date and a.date differed they differed by 1 day as noted above, and channelgrouping was identical across the tables. I suspected that productquantity in all_sessions might have been equal to units_sold in analytics. However, there were only 15 rows in the join where both of these values were not NULL. Though all of these values were equal, the contents of both values were weighted very heavily towards 1-2. As such, I could not say with confidence that the values were the same. I opted to treat them as though they were identical, while recognizing that the information would not be reliable. pageviews differed for only 8 out of 3661 visitorid, visitid combinations, so I opted to treat these as identical as well. I found similar results for timeonsite, with only 9 out of 2634 values differing. There was no way to reconcile a.revenue and ase.totaltransactionrevenue, ase.productrevenue, or any combination of the two, though this only affected 12 rows as revenue is very sparse in both tables. Finally, unit_price was equal to productprice for about half of rows present in both tables, while the other half were different. I didn't really know what to make of this.

Next, I decided that the tables should be split up/combined into various smaller tables so that each better encapsulated information about only one aspect of the business. First, I renamed sales_report to simply sales and made productsku its primary key. After a bit of digging I found that sales_by_sku contained 462 unique values while sales_report contained 454. All 454 unique values in sales_report had a corresponding row in sales_by_sku, and both tables agreed on the total_ordered. Since this implies that all information save for 8 rows in sales_by_sku is contained in sales_report I simply created a new table, sales, which contained the combination of the information contained in these two tables.

```SQL
CREATE TABLE sales AS (
SELECT *
FROM sales_by_sku
LEFT JOIN sales_report USING(productsku, total_ordered)
)
```

I then removed the sales_by_sku and sales_report tables.

The next step in normalizing the tables was combining the potentially duplicate information between sales and products. Upon initial inspection, it appears that the name, stocklevel, restockingleadtime, sentimentscore, sentimentmagnitude, and potentially orderedquantity/total_ordered coumns are duplicated. To compare these two tables I used the following query

``` SQL
SELECT productsku,
	name,
	total_ordered,
	stocklevel,
	restockingleadtime,
	sentimentscore,
	sentimentmagnitude
FROM sales
INTERSECT
SELECT * FROM products
```

Unfortunately, this only returned 83 identical rows, and since 

```SQL
SELECT DISTINCT(sales.productsku)
FROM sales
JOIN products
ON sales.productsku = products.sku
```

Returns 454 rows, this means that some of the seemingly duplicate information is actually contradictory. After looking more closely at the data in both tables, I found that orderedquantity and total_ordered were the source of disagreement, while all other information was duplicate.In order to remove repetition from the dataset, I decided to remove sentimentscore and sentimentmagnitude from products, and name, stocklevel, and restockingleadtime from sales. I renamed 'productsku' in sales to simply 'sku', and made sku the primary key for both the products and sales tables. I also made sku a foreign key for both tables, referencing the other table.

My next step was to break down the monolithic all_sessions table into smaller, single-purpose tables, while appropriately distributing certain columns into the products and sales tables. I settled on splitting all_sessions into two tables, visitors, sessions, and transactions.

The visitors table contained the columns fullvisitorid (PK), country, city, and pageviews.

```SQL
CREATE TABLE visitors AS (
	SELECT fullvisitorid, country, city, pageviews
	FROM all_sessions
)
```

The sessions table contained the columns visitid (PK), fullvisitorid (FK - visitors), channelgrouping, date, time, timeonsite, sessionqualitydim, type, pagetitle, pagepathlevel1,
ecommerceaction_type, ecommerceaction_step, and ecommerceaction_type.

```SQL
CREATE TABLE sessions AS (
	SELECT visitid, fullvisitorid, channelgrouping, date, time, timeonsite,
		sessionqualitydim, type, pagetitle, pagepathlevel1, ecommerceaction_type,
		ecommerceation_step, ecommerceaction_type
	FROM all_sessions
)
```

And the transactions table contained transactionid (PK), visitid (FK - sessions), sku (FK - products, sales), totaltransactionrevenue, currencycode, transactions, productquantity, productrevenue and productprice.

```SQL
CREATE TABLE transactions AS (
	SELECT transactionid, visitid, fullvisitorid, sku, 
	totaltransactionrevenue, transactions, productquantity, 
	productrevenue, productprice
	FROM all_sessions
```

I then moved v2productname and v2productcategory into products.

```SQL
CREATE OR REPLACE table products AS (
	SELECT p.sku, p.name, ase.v2productname, ase.v2productcategory, p.orderedquantity,
		p.stocklevel, p.restockingleadtime
	FROM products p
	LEFT JOIN all_sessions ase USING(sku)
)
```

This moved the information to the products table for products that already existed in the table, but during the process I noticed that there were many products in all_sessions that did not exist in the products table. In particular,

```SQL
SELECT COUNT(DISTINCT sku)
FROM all_sessions
WHERE sku NOT IN (SELECT sku FROM products)
```

Returned 147 distinct products. I wanted to add these products to the products table, but I first needed to check that they weren't already present there under a different sku. Noting that v2productname tended to be identical to product.name save for the manufacturer/retailers prefixed at the start, I decided to check for similar names in products under different sku:

```SQL
WITH missing_products AS (
	SELECT sku
		, productquantity
		, REGEXP_REPLACE(v2productname, '([^\s]+)', '') missing_name 
	FROM all_sessions
	WHERE sku IN 
	(SELECT DISTINCT sku 
	 FROM all_sessions 
	 WHERE sku NOT IN 
		(SELECT sku 
		 FROM products))
)

SELECT 'missing sku count', COUNT(DISTINCT missing_name) FROM missing_products
UNION
SELECT 'name_matches', COUNT(DISTINCT p.sku)
FROM products p
JOIN missing_products mp
ON p.name = mp.missing_name
```

Regex credit: https://stackoverflow.com/questions/1400431/regular-expression-match-any-			word-until-first-space

And found that of the 138 sku that are present in all_sessions but missing in products, 59 of them are associated with a product with a near identical name present in products. However, this did not give me sufficient confidence to simply combine the values. In the end, I opted to not add products from all_sessions that were not present in products to products.

To begin adding the other information provided in all_sessions to products I first create a temporary table

``` SQL
CREATE TEMPORARY TABLE products_temp AS (
	SELECT DISTINCT p.sku, p.name, ase.v2productname,
	 ase.v2productcategory,p.orderedquantity
	 p.stocklevel, p.restockingleadtime
	FROM products p
	JOIN all_sessions ase USING(sku)
	ORDER BY p.sku
)
```

That added v2productname and v2productcategory to the already present products. This table ended up with 1303 rows instead of the expected 1092 rows because multiple entries in all_sessions would give slightly different values for v2productname and v2product category. I.e. 'Google Men's Pullover Hoodie' vs. 'Google Men's Pullover Hoodie Grey', 'Home/Accessories/Fun/' vs.  'Home/Accesories/'. For the sake of time I decided to simply remove v2productname as it only added a small amount of information (manufacturer) vs name. But category needed some processing. My initial query for doing so was:

```SQL
CREATE TEMPORARY TABLE products_temp AS (
	SELECT DISTINCT p.sku, 
		p.name,
		CASE
			WHEN ase.v2productcategory = '(not set)' THEN NULL
			WHEN ase.v2productcategory = '${escCatTitle}' THEN NULL
			WHEN ase.v2productcategory NOT LIKE '%/%' THEN ase.v2productcategory
			-- 'Home/Shop by Brand/' doesn't really provide any information
			WHEN ase.v2productcategory = 'Home/Shop by Brand/' THEN NULL
			-- Hardcoded fix for 'bottles/' and 'lifestyle/' not parsing correctly
			WHEN ase.v2productcategory = 'Bottles/' THEN 'Bottles'
			WHEN ase.v2productcategory = 'Lifestyle/' THEN 'Lifestyle'
			-- First, trim trailing '/'. Then find position of first '/' in reversed string (= last '/' in original)
			ELSE TRANSLATE(RIGHT(ase.v2productcategory, POSITION('/' IN REVERSE(RTRIM(ase.v2productcategory, '/')))), '/', '')
		END AS productcategory, 
		p.orderedquantity,
		p.stocklevel,
		p.restockingleadtime
	FROM products p
	LEFT JOIN all_sessions ase USING(sku)
	ORDER BY sku
)
```

However, I found that didn't help to combine rows. I noticed that the categories were for the most part increasing in specificity (corresponding to clicking deeper into links on a website) so I decided to only consider the sku/v2productcategory pairs where v2productcategory was of maximum length.

```SQL
WITH max_cats_all_sessions AS (
		SELECT DISTINCT sku, v2productcategory
		FROM 
		(
		SELECT DISTINCT sku, v2productcategory,
		 MAX(LENGTH(v2productcategory)) OVER(PARTITION BY sku) lencat
		FROM all_sessions
		GROUP BY sku, v2productcategory
		) AS cwmax
		WHERE LENGTH(v2productcategory) = lencat
		ORDER BY sku
	)
```

Using the above CTE in the creation of the table yielded the desired result. Ultimately,
306 out of the 1092 products in the table ended up with categories. The new table did also have 1094 distinct skus instead of the expected 1092. I checked the two duplicates and manually chose the most appropriate category for each. This allowed me to restore sku as the primary key for the table.

Next I sought to clean up the transactions table. As it turned out, transactionid, my desired primary key, was NULL for all but 9 rows of all_sessions. This was fine for most values as it appeared that no transaction had occurred (totaltransactionrevenue, transactions, and product revenue were all NULL). However, I wanted to consider a transaction as having occurred if either totaltransactionrevenue or productrevenue was not NULL. This was true for 81 rows. I also noted that productrevenue was only NOT NULL where totaltransaction revenue was also NOT NULL.

First, I dropped rows of transactions where I considered no transaction to have occurred. Then I altered the transactionid to be a SERIAL PRIMARY KEY. I then recreated the sessions table adding the new trasactionid to the table where relevant.

Next I needed to clean up sessions the sessions table. Ideally, would be able to distinguish between sessions. However, there were over 100 duplicate visitids in the table. This was likely due to multiple entries being made in all_sessions when more than one ecommerceaction/transaction was performed. The other concern was visitids having contradictory fullvisitorids, which should not be possible based on my interpretation of the data. First I checked the values where this was the case

```SQL
SELECT *
FROM sessions
WHERE visitid IN
(
	SELECT visitid
	FROM sessions
	GROUP BY visitid
	HAVING COUNT(DISTINCT(visitid, fullvisitorid)) > 1
)
ORDER BY visitid
```

Only a handful of values had this issue. That said, the rows were very unique with the only commonality for most being the date of the visit. I decided that it would not be appropriate to combine these rows as this would remove information from the table. Overall, it appeared that everywhere visitid was duplicated the rows were distinct enough to not be considered duplicate data. The main columns where they differed were time, channelgrouping, type, and pagetitle, and pagepathlevel1. I decided to create a new table called actions that would link via the visitid to sessions and house all of this data, as well the ecommerceaction data as it seemed like a more appropriate place for it. I also added a new column actionid to act as the primary key for actions.

```SQL
CREATE TABLE actions AS
(
	SELECT visitid, time, channelgrouping, type, pagetitle,
		ecommerceaction_type,
		ecommerceaction_step,
		ecommerceaction_option
	FROM sessions
)

ALTER TABLE actions ADD COLUMN actionid SERIAL PRIMARY KEY
```

With these values removed all duplicate rows in the sessions table were duplicate information, so I simply removed them by creating a temporary table containing only distinct values in sessions, then replacing sessions with it.

```SQL
CREATE TEMPORARY TABLE sessions_temp AS (
	SELECT DISTINCT * FROM sessions
);
```

After doing this, sessions contained only 7 values where visitid was duplicated. These unfortunately were not duplicate rows, and could be distinguished by the fullvisitorid and in one case a transactionid. I did not think I could condense any of these rows so I decided to simply replace visitid with a new serial primary key, sessionid. 

```SQL
ALTER TABLE sessions_temp ADD COLUMN sessionid SERIAL;
DROP TABLE sessions;
CREATE TABLE sessions AS (
	SELECT * FROM sessions_temp
);
```

The last table that needed cleaning up before I started modifying individual data was visitors. The query

```SQL
SELECT * FROM visitors
WHERE fullvisitorid IN
(SELECT fullvisitorid 
 FROM visitors 
 GROUP BY fullvisitorid 
 HAVING COUNT(fullvisitorid) > 1)
ORDER BY fullvisitorid
```

Revealed that the information for each visitor was mainly in agreement except where pageview differed. There were two main cases where fullvisitorid was duplicated in all_sessions: first, where the visitor had multiple sessions in the table. Second, where the same session was recorded multiple times due to different actions being taken in the same session. Where there were multiple values of pageiews I decided that the best course of action was to set pageviews equal to the duplicated value if the values were equal, and sum them if they were not. This unfortunately did make the pageview data much less reliable as if there were two separate sessions with the same amount of pageviews, both sessions one sessions pageviews would not be counted. This will bias pageviews to be much smaller than the probable values.


```SQL
CREATE TEMPORARY TABLE condense_equal_visitors AS
(
	SELECT DISTINCT * FROM visitors
);

CREATE TEMPORARY TABLE condense_equal_visitors_step2 AS
(
SELECT fullvisitorid, country, city,
	SUM(pageviews) OVER (PARTITION BY (fullvisitorid, country, city))
FROM condense_equal_visitors
ORDER BY fullvisitorid
);

DROP TABLE condense_equal_visitors;

CREATE TEMPORARY TABLE condense_equal_visitors AS
(
	SELECT DISTINCT * FROM condense_equal_visitors_step2
);

```

Doing this revealed that there were some visitors which had city identified in one row, while being labeled as "not available in demo dataset" in a different row. Alternatively, there were some values where the same fullvisitorid had contradictory values for country or city. Before repeating the process above, and recondensing the pageviews, I needed to rectify these errors.
As there were only 64 rows returned by the query

```SQL
SELECT * FROM condense_equal_visitors
WHERE fullvisitorid IN
(SELECT fullvisitorid 
 FROM condense_equal_visitors
 GROUP BY fullvisitorid 
 HAVING COUNT(fullvisitorid) > 1)
ORDER BY fullvisitorid;
```

I decided to manually fix the missing values and contradictions.

This was a mistake.

Note: Where contradictions existed in the country and city information was unavailable, I updated the country to NULL.

After some work, this led to a table where fullvisitorid was uniquely tied to a country/city/totalviews combination. I then set fullvisitorid as the primary key of visitors.

The last step in the normalization process was to establish foreign keys between tables. I used the following setup to link the tables together:

actions: actionid (PK), sessionid (FK, sessions)
products: sku (PK)
sales: sku (PK), sku (FK, products)
sessions: sessionid (PK), transactionid (FK, transactions), fullvisitorid (FK, visitors)
transactions: transactionid (PK), sku (FK, products, sales)
visitors: fullvisitorid (PK)

## Altering Improperly Formatted Values ##

### actions ###

The only value that wasn't quite "atomic" in actions was the pagetitle. I opted to leave this as is.

### products ###

There were two distinct types of sku present in the dataset. One was numeric and the other was alphanumeric. This did not create issues for my analysis.

### sales ###

Similar problems with sku in products.

### sessions ###

Timeonsite was not possible for me to convert to an interval without more information but I chose to leave it in as it still has value in comparing one session length to another.

### transactions ###

Transactions contained all of the monetary information. It was clear from the data given (t-shirts don't cost millions of USD) that all data related to currency had been multiplied by 1000000 in the dataset. I simply altered totaltransactionrevenue, productrevenue, and productprice by dividing them by 1000000. I also changed their type to be a numeric value with 2 significant digits.

### visitors ###

For the visitors table the only necessary modification was setting city = NULL wherever the value was "not available in demo dataset" or "(not set)"

## Using the analytics table ##

Before extracting the information contained in analytics and divying it up between the existent tables, I needed to clean up its values as well. Firstly, I removed visitstarttime as a column as it was equal to (or very close to) visitid for all values in the table. Since any value of fullvisitorid contained in analytics that did not match a value in visitors would not contain any location information, I decided to remove these values from the table.

```SQL
CREATE TEMPORARY TABLE analytics_temp AS (
	SELECT *
	FROM analytics
	WHERE fullvisitorid IN
	(SELECT DISTINCT fullvisitorid
	FROM analytics
	JOIN visitors USING(fullvisitorid))
);

DROP table analytics;

CREATE TABLE analytics AS (
	SELECT DISTINCT * FROM analytics_temp
);
```


This pared the analytics table down from ~4000000 rows to 83210 rows, while guaranteeing that all rows of analytics are distinct and that we would have country and city information for all rows.

I also needed to modify currency values in analytics by dividing them by 1000000, as I did with the other tables.

From here it seemed appropriate to alter the existing tables and add in the information contained in analytics. First, I deleted socialengagementtype, userid, visitnumber, and bounces from analytics as they don't have corresponding values in other tables or are not interesting useful for my analysis. First, where visitid and fullvisitorid matched

Next, I needed to figure out which values in other tables the values in analytics corresponded to. 
visitid, date, fullvisitorid, channelgrouping, timeonsite, and pageviews matched by name to their corresponding values in sessions/actions/visitors. I translated units_sold to productquantity, revenue to totaltransactionrevenue, and unit_price to productprice in the transactions table.

To start, I wanted to add sessions to the sessions table where they did not already exist, and merge values where they did. I identified sessions that did not already exist in the table using

``` SQL
SELECT *
FROM analytics a
LEFT JOIN sessions s USING(visitid, fullvisitorid)
WHERE (s.visitid, s.fullvisitorid) IS NULL
```

And found that there were 36962 such values. To add them to the sessions table I first created a temporary table 'sessions_added' to keep track of the new values added to sessions and added that to the end of sessions.

``` SQL
CREATE TEMPORARY TABLE sessions_added AS
(
SELECT a.visitid,
	a.fullvisitorid,
	a.date,
	a.timeonsite
FROM analytics a
WHERE (a.visitid, a.fullvisitorid) IN
(SELECT a.visitid, a.fullvisitorid
FROM analytics a
LEFT JOIN sessions s USING(visitid, fullvisitorid)
WHERE (s.visitid, s.fullvisitorid) IS NULL)
);

INSERT INTO sessions (visitid, fullvisitorid, date, timeonsite)
SELECT * FROM sessions_added
RETURNING *;
```

This didn't work because the sessionid was null on the inserted rows. I decided to manually add new sessionids

```SQL
ALTER TABLE sessions_added ADD COLUMN sessionid SERIAL;

UPDATE sessions_added SET sessionid = sessionid + (SELECT MAX(sessionid) FROM sessions)
```

and try the above again, inserting the new sessionids as well. This query was successful, with the added sessions starting at sessionid 14564.

Before moving on to adding the corresponding values from these new sessions into the other tables,
I needed to check for contradictory values as well.

``` SQL
SELECT s.timeonsite, a.timeonsite
FROM analytics a
JOIN sessions s USING(visitid, fullvisitorid)
WHERE s.timeonsite != a.timeonsite
```

I found 987 contradictions between the timeonsite given in sessions and the timeonsite given in analytics. I did not know where these contradictions arose from so I decided to not use timeonesite in my analysis.

There were no other values on which the two tables might contradict.

Next I needed to add any transactions corresponding to the added sessions to the transactions table, and match their transactionid in the sessions table. To do so I used:

```SQL
CREATE TEMPORARY TABLE transactions_added AS (
SELECT DISTINCT a.visitid
	, a.fullvisitorid
	, a.revenue totaltransactionrevenue
	, a.units_sold productquantity
	, a.unit_price productprice
FROM analytics a
JOIN sessions_added s USING(visitid, fullvisitorid)
WHERE a.revenue IS NOT NULL OR a.units_sold IS NOT NULL
);

SELECT * FROM transactions_added;
```

From this I noticed that some visitid/fullvisitorid combinations had multiple transactions, and 
there was often a productquantity and productprice while revenue was listed as null. It was clear from the rows that containe productquantity, productprice, and revenue that the revenue column was simply productquantity * productprice * (1 + unknown tax value). I decided to extrapolate the null values of totaltransactionrevenue from this, ignoring tax.

```SQL
UPDATE transactions_added
SET totaltransactionrevenue = productquantity * productprice
WHERE totaltransactionrevenue IS NULL;
```

And add a transactionid column to the table in the same way that I did with the sessions_added table.

```SQL
ALTER TABLE transactions_added ADD COLUMN transactionid SERIAL;
UPDATE transactions_added SET transactionid = transactionid + (SELECT MAX(transactionid) FROM transactions);
```

I then tacked transactions_added on to the end of the transactions table and linked the new transactions to the new sessions using the transactionid.

```SQL
INSERT INTO transactions (totaltransactionrevenue, productquantity, productprice, transactionid)
SELECT totaltransactionrevenue, productquantity, productprice, transactionid FROM transactions_added
RETURNING *;

CREATE TEMPORARY TABLE sessions_temp AS
(
	SELECT visitid, fullvisitorid, t.transactionid, date,
		timeonsite, sessionqualitydim, sessionid
	FROM sessions
	JOIN transactions_added t USING(visitid, fullvisitorid)
)

```
This created a new problem. Multiple transactions per unique session meant that duplicate sessions were to be added to the sessions table. Given more time, I wanted to link transactions to individual actions instead of sessions, but a fix that allowed me to still do some basic analysis was dropping the sessions_added from earlier and affixing a new sessions_added based on transactions_ad, with a new sessionid generated.

```
DELETE FROM sessions WHERE sessionid >= 14564;

DROP TABLE sessions_temp;
CREATE TEMPORARY TABLE sessions_temp AS
(
	SELECT DISTINCT visitid, fullvisitorid, t.transactionid, date,
		timeonsite
	FROM sessions_added
	JOIN transactions_added t USING(visitid, fullvisitorid)
)

ALTER TABLE sessions_temp ADD COLUMN sessionid SERIAL;
UPDATE sessions_temp SET sessionid = sessionid + (SELECT MAX(sessionid) FROM sessions);

INSERT INTO sessions (visitid, fullvisitorid, transactionid, date, timeonsite, sessionid)
SELECT * FROM sessions_temp
RETURNING *;
```

This was the end of my data extraction from analytics. In the future, I would like to consider extracting more data and linking it to the actions table.

For now, the last SQL query I executed was:

```SQL
DROP TABLE analytics;
```





 



















 

