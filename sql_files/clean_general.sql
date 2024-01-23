SELECT COUNT(*) FROM sales_report
UNION
SELECT COUNT(DISTINCT productsku) FROM sales_report

SELECT COUNT(distinct productsku) from sales_by_sku
UNION
SELECT COUNT(DISTINCT productsku) FROM sales_by_sku

SELECT COUNT(*) FROM sales_by_sku WHERE total_ordered IS NULL

SELECT COUNT(*) FROM sales_report JOIN sales_by_sku USING(productsku)
WHERE sales_by_sku.total_ordered != sales_report.total_ordered

CREATE TABLE sales AS (
SELECT *
FROM sales_by_sku
LEFT JOIN sales_report USING(productsku, total_ordered)
)

SELECT COUNT(DISTINcT sku) FROM products

SELECT * FROM sales WHERE name IS NULL

DROP TABLE sales_by_sku
DROP TABLE sales_report

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

SELECT *
FROM sales s 
JOIN products p
ON s.productsku = p.sku
WHERE s.total_ordered != orderedquantity

SELECT * FROM sales WHERE productsku NOT IN (SELECT sku FROM products)

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

SELECT s.name
	, p.name
	, s.total_ordered
	, p.orderedquantity
	, s.stocklevel
	, p.stocklevel
	, s.restockingleadtime
	, p.restockingleadtime
	, s.sentimentscore
	, p.sentimentscore
	, s.sentimentmagnitude
	, p.sentimentmagnitude
FROM sales s
JOIN products p
ON s.productsku = p.sku

SELECT * FROM products

DROP TABLE analytics

SELECT ase.sku, ase.productquantity, s.total_ordered, p.orderedquantity
FROM all_sessions ase
JOIN sales s USING(sku)
JOIN products p USING(sku)

SELECT COUNT(DISTINCT sku) FROM all_sessions
WHERE sku NOT IN (SELECT sku FROM products)
SELECT COUNT(DISTINCT sku) FROM sales

SELECT COUNT(*) FROM all_sessions
SELECT COUNT(DISTINCT fullvisitorid) FROM all_sessions




SELECT productvariant FROM all_sessions WHERE productvariant IS NOT NULL
AND productvariant != '(not set)'

SELECT transactionid, * FROM all_sessions WHERE transactionid is NOT NULL

SELECT v2productcategory FROM all_sessions WHERE v2productcategory IS NOT NULL ORDER BY v2productcategory

SELECT sku, p.name, ase.v2productname FROM all_sessions ase JOIN products p USING(sku) WHERE v2productname IS NOT NULL AND p.name != ase.v2productname ORDER BY sku


SELECT p.* FROM products p JOIN sales USING(sku)

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

SELECT 'missing names', COUNT(DISTINCT missing_name) FROM missing_products
UNION
SELECT 'name_matches', COUNT(DISTINCT p.sku)
FROM products p
JOIN missing_products mp
ON p.name = mp.missing_name


SELECT DISTINCT(sku)
FROM all_sessions
WHERE sku IN 
(
	SELECT DISTINCT(p.sku)
	FROM products p
	JOIN missing_products mp
	ON p.name = mp.missing_name
)

DROP TABLE products_temp
CREATE TEMPORARY TABLE products_temp AS (
	WITH max_cats_all_sessions AS (
		SELECT DISTINCT sku, v2productcategory
		FROM 
		(
			SELECT DISTINCT sku, v2productcategory, MAX(LENGTH(v2productcategory)) OVER(PARTITION BY sku) lencat
			FROM all_sessions
			GROUP BY sku, v2productcategory
		) AS cwmax
		WHERE LENGTH(v2productcategory) = lencat
		ORDER BY sku
	)
	
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
	LEFT JOIN max_cats_all_sessions ase USING(sku)
	ORDER BY sku
)

SELECT sku FROM products_temp GROUP BY sku HAVING COUNT(sku) > 1 ORDER BY sku

SELECT * FROM products_temp


SELECT sku FROM products_temp GROUP BY sku HAVING COUNT(sku) > 1


SELECT DISTINCT(sku) FROM products

SELECT * FROM products_temp WHERE productcategory IS NOT NULL
	
SELECT * FROM products

SELECT sku, productcategory 
FROM all_sessions ase
WHERE sku IN 


SELECT DISTINCT sku, visitid, v2productcategory
FROM 
(SELECT DISTINCT sku, visitid, v2productcategory, MAX(LENGTH(v2productcategory)) lencat
FROM all_sessions
GROUP BY sku, visitid, v2productcategory) AS cwmax
WHERE LENGTH(v2productcategory) = lencat

DROP TABLE products

CREATE TABLE products AS (
	SELECT * FROM products_temp
)
SELECT * FROM products WHERE sku IN (SELECT sku FROM products GROUP BY sku HAVING COUNT(sku) > 1)


DELETE FROM products
WHERE sku = 'GGOEGFKQ020799' AND productcategory = 'Google'

DROP TABLE products_old

SELECT COUNT(*) FROM all_sessions WHERE fullvisitorid IS NULL

CREATE TABLE visitors AS (
	SELECT fullvisitorid, country, city, pageviews
	FROM all_sessions
)

DROP TABLE sessions;

CREATE TABLE sessions AS (
	SELECT visitid, fullvisitorid, transactionid, channelgrouping, date, time, timeonsite,
		sessionqualitydim, type, pagetitle, pagepathlevel1, ecommerceaction_type,
		ecommerceaction_step, ecommerceaction_option
	FROM all_sessions
)

DROP TABLE transactions
CREATE TABLE transactions AS (
	SELECT transactionid, visitid, fullvisitorid, sku, 
	totaltransactionrevenue, currencycode, transactions, productquantity, 
	productrevenue, productprice
	FROM all_sessions
	WHERE totaltransactionrevenue IS NOT NULL
)



ALTER TABLE transactions ADD COLUMN transactionid SERIAL PRIMARY KEY

SELECT * FROM transactions

SELECT * FROM transactions WHERE totaltransactionrevenue IS NOT NULL OR productrevenue IS NOT NULL

DROP TABLE sessions;
CREATE TABLE sessions AS (
	SELECT a.visitid, a.fullvisitorid, t.transactionid, channelgrouping, date, time, timeonsite,
		sessionqualitydim, type, pagetitle, pagepathlevel1, ecommerceaction_type,
		ecommerceaction_step, ecommerceaction_option
	FROM all_sessions a
	LEFT JOIN transactions t
	ON (t.visitid, t.sku) = (a.visitid, a.sku)
		
)

SELECT *
FROM all_sessions a
LEFT JOIN transactions t
ON (t.visitid, t.sku) = (a.visitid, a.sku)

SELECT * FROM sessions where transactionid IS NOT NULL

SELECT * FROM sessions

SELECT DISTINCT (visitid, fullvisitorid) FROM sessions
SELECT * FROM sessions

SELECT * from visitors
SELECT DISTINCT(fullvisitorid) FROM visitors


SELECT *
FROM sessions
WHERE visitid IN
(
	SELECT visitid
	FROM sessions
	GROUP BY visitid
	HAVING COUNT(visitid) > 1
)
ORDER BY visitid

DROP TABLE actions
CREATE TABLE actions AS
(
	SELECT visitid, time, channelgrouping, type, pagetitle,
		ecommerceaction_type,
		ecommerceaction_step,
		ecommerceaction_option
	FROM sessions
)

ALTER TABLE actions ADD COLUMN actionid SERIAL PRIMARY 

SELECT * FROM actions


DROP TABLE sessions_temp
CREATE TEMPORARY TABLE sessions_temp AS (
SELECT DISTINCT * FROM sessions
)

SELECT * FROM sessions_temp

SELECT *
FROM sessions_temp
WHERE visitid IN
(
	SELECT visitid
	FROM sessions_temp
	GROUP BY visitid
	HAVING COUNT(visitid) > 1
)
ORDER BY visitid

CREATE TEMPORARY TABLE actions_temp AS (
	SELECT a.actionid,
		a.visitid,
		a.time,
		a.channelgrouping,
		a.type,
		a.pagetitle,
		s.pagepathlevel1,
		a.ecommerceaction_type,
		a.ecommerceaction_step,
		a.ecommerceaction_option
	FROM actions a
	JOIN sessions s USING(visitid)
)

SELECT * FROM actions_temp WHERE pagepathlevel1 IS NULL

DROP TABLE actions;
CREATE TABLE actions AS
(
	SELECT * FROM actions_temp
)

SELECT * FROM actions WHERE actionid IS NULL

SELECT * FROM 

ALTER TABLE sessions_temp ADD COLUMN sessionid SERIAL

DROP TABLE sessions;
CREATE TABLE sessions AS (
	SELECT * FROM sessions_temp
);

SELECT * FROM visitors
WHERE fullvisitorid IN
(SELECT fullvisitorid 
 FROM visitors 
 GROUP BY fullvisitorid 
 HAVING COUNT(fullvisitorid) > 1)
ORDER BY fullvisitorid

CREATE TEMPORARY TABLE condense_equal_visitors AS
(
	SELECT DISTINCT * FROM visitors
);

WITH visitors_multiple_pv AS
(
SELECT fullvisitorid FROM condense_equal_visitors
WHERE fullvisitorid IN
(SELECT fullvisitorid 
 FROM condense_equal_visitors
 GROUP BY fullvisitorid 
 HAVING COUNT(fullvisitorid) > 1)
ORDER BY fullvisitorid
)

DROP TABLE condense_equal_visitors_step2;
CREATE TEMPORARY TABLE condense_equal_visitors_step2 AS
(
SELECT fullvisitorid, country, city,
	SUM(sum) OVER (PARTITION BY (fullvisitorid, country, city)) totalviews
FROM condense_equal_visitors
ORDER BY fullvisitorid
)

CREATE TEMPORARY TABLE condense_equal_visitors_step3 AS
(
	SELECT DISTINCT * FROM condense_equal_visitors_step2
)

DROP TABLE condense_equal_visitors;

CREATE TEMPORARY TABLE condense_equal_visitors AS
(
	SELECT DISTINCT * FROM condense_equal_visitors_step2
);

SELECT * FROM condense_equal_visitors;

SELECT * FROM condense_equal_visitors
WHERE fullvisitorid IN
(SELECT fullvisitorid 
 FROM condense_equal_visitors
 GROUP BY fullvisitorid 
 HAVING COUNT(fullvisitorid) > 1)
ORDER BY fullvisitorid

	
WITH null_citynotset_visitors AS (
	SELECT fullvisitorid,
		CASE
			WHEN city = 'not available in demo dataset' THEN NULL
			WHEN city = '(not set)' THEN NULL
			ELSE city
		END AS city,
		country,
		sum
	FROM condense_equal_visitors
)

SELECT *
FROM null_citynotset_visitors n1
JOIN null_citynotset_visitors n2
ON n1.city

SELECT * FROM condense_equal_visitors_step3
WHERE fullvisitorid IN
(SELECT fullvisitorid 
 FROM condense_equal_visitors_step3
 GROUP BY fullvisitorid 
 HAVING COUNT(fullvisitorid) > 1)
ORDER BY fullvisitorid


UPDATE condense_equal_visitors
SET (country, city) = (NULL, NULL)
WHERE fullvisitorid = '7830248036973856928'

UPDATE condense_equal_visitors
SET country = 
WHERE fullvisitorid = '312563032232212298'

UPDATE condense_equal_visitors
SET city = 'Salem'
WHERE fullvisitorid = '9801276214964695322'

SELECT * FROM condense_equal_visitors_step3

DROP TABLE visitors;
CREATE TABLE visitors AS (
	SELECT * FROM condense_equal_visitors_step3
)

SELECT * FROM visitors

SELECT * FROM sessions
WHERE sessionid IN
(
SELECT sessionid
FROM sessions
GROUP BY sessionid
HAVING COUNT(sessionid) > 1
)
ORDER BY sessionid

DROP TABLE actions_temp
CREATE TEMPORARY TABLE actions_temp AS (
	SELECT DISTINCT * FROM actions
)

DROP TABLE actions_temp;

CREATE TEMPORARY TABLE actions_temp AS
(
	SELECT a.actionid,
		a.visitid,
		s.sessionid,
		a.time,
		a.channelgrouping,
		a.type,
		a.pagetitle,
		a.ecommerceaction_type,
		a.ecommerceaction_step,
		a.ecommerceaction_option
	FROM actions a
	JOIN sessions s USING(visitid)
)

SELECT * FROM actions

UPDATE actions_temp WHERE
SELECT * FROM actions_temp WHERE actionid IN
(
	SELECT actionid
	FROM actions_temp
	GROUP BY actionid
	HAVING COUNT(actionid) > 1
)

DROP TABLE actions
CREATE TABLE actions AS (
	SELECT * FROM actions_temp
)

ALTER TABLE actions ADD COLUMN actionid SERIAL PRIMARY KEY

DELETE FROM actions WHERE 

SELECT * FROM sessions WHERE sessionid = 11245 OR sessionid = 4121

DROP TABLE all_session

CREATE TEMPORARY TABLE transaction_temp AS
(
	SELECT * FROM transactions
)

UPDATE transactions 
SET productprice = productprice / 1000000


SELECT * FROM transaction_temp

ALTER TABLE transactions ALTER COLUMN 

SELECT * FROM products WHERE sku = 'GGOENEBQ078999'

SELECT * FROM transactions

ALTER TABLE transactions
ALTER COLUMN productprice TYPE NUMERIC(10,2)

SELECT * FROM transactions

