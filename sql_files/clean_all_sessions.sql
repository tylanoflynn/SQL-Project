SELECT * FROM all_sessions LIMIT 10;
SELECT * FROM analytics LIMIT 10;
SELECT * FROM sales_report LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM sales_by_sku LIMIT 10;

WITH clean_all_sessions AS
(
	SELECT TRANSLATE(fullvisitorid, '.', '')::VARCHAR(20) fullvisitorid,
		channelgrouping,
		time,
		country,
		city,
		totaltransactionrevenue,
		transactions,
		timeonsite,
		pageviews,
		sessionqualitydim,
		date,
		visitid,
		type,
		productrefundamount,
		productquantity,
		productprice,
		productrevenue,
		productsku,
		v2productname,
		v2productcategory,
		productvariant,
		currencyCode,
		itemquantity,
		itemrevenue,
		transactionrevenue,
		transactionid,
		pagetitle,
		searchkeyword,
		pagepathlevel1,
		ecommerceaction_type,
		ecommerceaction_step,
		ecommerceaction_option
	FROM all_sessions
),

clean_analytics AS
(
	SELECT visitnumber,
		visitid,
		visitstarttime,
		date,
		fullvisitorid::NUMERIC::TEXT
	FROM analytics
)

SELECT COUNT(DISTINCT visitid) FROM all_sessions
UNION
SELECT COUNT(DISTINCT fullvisitorid) FROM all_sessions
UNION
SELECT COUNT(DISTINCT visitid) FROM analytics
UNION
SELECT COUNT(DISTINCT fullvisitorid) FROM all_sessions

SELECT acs.fullvisitorid, a.fullvisitorid
FROM all_sessions acs
JOIN analytics a
ON acs.visitid = a.visitid
WHERE acs.fullvisitorid != a.fullvisitorid


