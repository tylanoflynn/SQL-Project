SELECT * FROM all_sessions LIMIT 10;
SELECT * FROM analytics LIMIT 10;
SELECT * FROM sales_report LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM sales_by_sku LIMIT 10;

WITH clean_all_sessions AS
(
	SELECT TRANSLATE(fullvisitorid, '.', '')::VARCHAR(15) fullvisitorid,
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
)

SELECT DISTINCT fullvisitorid FROM clean_all_sessions
SELECT DISTINCT fullvisitorid FROM analytics

