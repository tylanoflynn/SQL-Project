Question 1: Are there any products where the ordered quantity is greater than the stock level? If so, how does their restocking lead time compare to the average restocking lead time of products?

SQL Queries:

```SQL
SELECT sku, name, (((restockingleadtime / 
	(SELECT AVG(restockingleadtime) FROM products) - 1) * 100))::NUMERIC(10,2) compare
FROM products
WHERE orderedquantity > stocklevel
```

Answer: 

"sku"|"name"|"compare"
----------------|---------------------------------------------|--
"GGOEGAWQ062948"|" Baby Essentials Set"|-15.6
"GGOEGBJC019999"|"Collapsible Shopping Bag"|-7.16
"GGOEGDHC015299"|"23 oz Wide Mouth Sport Bottle"|1.28
"GGOEGDHQ015399"|"26 oz Double Wall Insulated Bottle"|-24.04
"GGOEGETR014599"|" Tube Power Bank"|-32.48
"GGOEGFKA022299"|"Keyboard DOT Sticker"|-24.04
"GGOEGFSR022099"|" Kick Ball"|-32.48
"GGOEGGOA017399"""Maze Pen"|-24.04
"GGOEGHGT019599"|" Sunglasses"|-32.48
"GGOEGHPB003410"|" Snapback Hat Black"|-74.68
"GGOEGKAA019299"|"Switch Tone Color Crayon Pen"|1.28
"GGOEGOCT019199"|"Red Spiral  Notebook"|-32.48
"GGOEGOLC014299"|" Metallic Notebook Set"|-57.80
"GGOENEBQ079099"|" Protect Smoke + CO White Battery Alarm-USA"|-7.16
"GGOEYOCR077399"|" RFID Journal"|-74.68

For all products that have more orderedquantity than stocklevel, the restockingleadtime is approximately at or below the average restockingleadtime for all products. This likely means that the products are on backorder due their popularity and not due to inefficient supply lines for these particular products.

Question 2: What is the average number of totalviews for visitors that made transactions? How does this compare to the overall average of total views?

SQL Queries: 

```SQL
SELECT AVG(totalviews) aveviewsconversion
	, ( (AVG(totalviews) / (SELECT AVG(totalviews) FROM visitors)) - 1) * 100 compare_to_overall
FROM visitors
JOIN sessions USING(fullvisitorid)
JOIN transactions USING(transactionid)
```

Answer:

"aveviewsconversion"|"compare_to_overall"
--------------------|--------------------
8.04|75

The average number of views for visitors that made transactions was about 8.04, which is ~75% higher than the average number of views for all visitors.

Question 3:  What proportion of each channel grouping resulted in a transaction?

NOTE: I calculated these proportions before adding the extra information from analytics. Since only 81 transactions existed before adding the analytics transactions, these proportions are not reliable. However, I did not have time to add the analytics information to the actions table.

SQL Queries:

```SQL
WITH cte_channelgroupactioncount AS
(
	SELECT a.channelgrouping, COUNT(*) 
	FROM actions a 
	JOIN sessions s USING(sessionid)
	GROUP BY a.channelgrouping
),

cte_grouping_conversioncount_numberactions AS
(
SELECT a.channelgrouping
	, COUNT(t.transactionid)::NUMERIC(10, 5) conversioncount
	, (SELECT count
		FROM cte_channelgroupactioncount
	   WHERE channelgrouping = a.channelgrouping
	   )::NUMERIC(10, 5) numberactions
FROM actions a
JOIN sessions s USING(sessionid)
JOIN transactions t USING(transactionid)
GROUP BY a.channelgrouping, numberactions
)

SELECT channelgrouping
	, ((conversioncount / numberactions)*100)::NUMERIC(10, 2) percentconverted
FROM cte_grouping_conversioncount_numberactions
```

Answer:

"channelgrouping"|"percentconverted"
-----------------|-------------------
"Direct"|0.87
"Organic Search"|0.25
"Paid Search"|0.59
"Referral"|1.24





