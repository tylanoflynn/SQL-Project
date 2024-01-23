Answer the following questions and provide the SQL queries used to find the answer.

    
**Question 1: Which cities and countries have the highest level of transaction revenues on the site?**


SQL Queries:

```SQL
SELECT v.city
	, SUM(totaltransactionrevenue) totaltransactionrevenue
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.city

SELECT v.country
	, SUM(totaltransactionrevenue) totaltransactionrevenue
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.country
```




Answer:

City:

city|totaltransactionrevenue
-----------|---------------------
NULL|6092.56
"Austin"|157.78
"San Jose"|262.38
"Tel Aviv-Yafo"|602.00
"New York"|598.35
"San Francisco"|1564.32
"Palo Alto"|608.00
"Sydney"|358.00
"Chicago"|449.52
"Houston"|38.98
"San Bruno"|103.77
"Seattle"|358.00
"Columbus"|21.99
"Los Angeles"|479.48
"Mountain View"|483.36
"Sunnyvale"|992.23
"Nashville"|157.00
"Zurich"|16.99
"Toronto"|82.16
"Atlanta"|854.44

Country:

country|totaltransactionrevenue
-----------|---------------------
Israel|602.00
United States|13154.17
Australia|358.00
Canada|150.15
Switzerland|16.99


**Question 2: What is the average number of products ordered from visitors in each city and country?**


SQL Queries:

For the average ordered when any product was ordered:

```SQL
SELECT v.city
	, AVG(t.productquantity)
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.city

SELECT v.country
	, AVG(t.productquantity)
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.city
```

For the average ordered including sessions where no products were ordered:

```SQL
SELECT v.city
	, AVG(CASE
		  WHEN productquantity is NULL THEN 0
		  ELSE productquantity
		  END)::NUMERIC(10, 2) average
FROM transactions t
RIGHT JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.city

SELECT v.country
	, AVG(CASE
		  WHEN productquantity is NULL THEN 0
		  ELSE productquantity
		  END)::NUMERIC(10, 2) average
FROM transactions t
RIGHT JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.country
```


Answer:

For the average ordered when any product was ordered:

City:

city | average
-----------|----------
NULL | 19.83
"Austin" | NULL	
"San Jose" | NULL	
"Tel Aviv-Yafo" | NULL
"New York" | 1.00
"San Francisco" | 1.00
"Palo Alto" | 1.00
"Sydney" | NULL
"Chicago" | 1.00
"Houston" | NULL
"San Bruno" | NULL
"Seattle" | 1.00
"Columbus" | 1.00
"Los Angeles" | NULL
"Mountain View" | 1.00
"Sunnyvale" | 1.00
"Nashville" | NULL
"Zurich" | NULL
"Toronto" | NULL
"Atlanta" | 4.00

Country:

country | average
-----------|----------
Israel | NULL 
United States | 7.44
Australia | NULL	
Canada | NULL
Switzerland | NULL

NOTE: These tables only contain cities and countries with visitors that made transactions. All other cities and countries in the table would have NULL/0 averages.

For the average ordered including when no products were ordered:

Country:

country | average
--------------|--------
United States | 0.01601

City:

city | average
-------------|--------
Mountain View|0.01434
New York|0.00323
San Francisco|0.00449
Palo Alto|0.01031
Chicago|0.00524
Seattle|0.00847
Columbus|0.50000
Sunnyvale|0.00284
Atlanta|0.06250

NOTE: For brevity I have excluded locations where the average is 0 from the tables.

Averages including visitors that do not make purchases provide insight into the proportion of visitors from each region that are likely to make purchases.


**Question 3: Is there any pattern in the types (product categories) of products ordered from visitors in each city and country?**


SQL Queries:

```SQL
SELECT v.city,
	p.productcategory
FROM transactions t
JOIN products p USING(sku)
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
WHERE v.city IS NOT NULL AND p.productcategory IS NOT NULL
ORDER BY v.city, p.productcategory

SELECT v.country,
	p.productcategory
FROM transactions t
JOIN products p USING(sku)
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
WHERE v.country IS NOT NULL AND p.productcategory IS NOT NULL
ORDER BY v.country, p.productcategory
```

Answer:

For this question, I only considered sessions where transactions occurred (a product was ordered). I found that there was a potential trend of large cities ordering from 'Nest-USA', but given the tiny number of data points (45) it isn't possible to be confident about any patterns. For countries there were only 4 transactions containing products where the category was labeled outside of the United States.


**Question 4: What is the top-selling product from each city/country? Can we find any pattern worthy of noting in the products sold?**


SQL Queries:

```SQL
SELECT v.city, p.name
	, COUNT(p.name)
FROM transactions t
JOIN products p USING(sku)
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
WHERE v.city IS NOT NULL
GROUP BY v.city, p.name
HAVING COUNT(p.name) > 0

with cte_sold_by_country AS
(
	SELECT v.country, p.name
		, COUNT(p.name) totalsold
	FROM transactions t
	JOIN products p USING(sku)
	JOIN sessions s USING(transactionid)
	JOIN visitors v USING(fullvisitorid)
	WHERE v.country IS NOT NULL
	GROUP BY v.country, p.name
	HAVING COUNT(p.name) > 0
),

cte_sold_by_country_ranked AS (
	SELECT country, name, totalsold,
		DENSE_RANK() OVER (PARTITION BY country ORDER BY totalsold DESC) rank
	FROM cte_sold_by_country
)

SELECT * FROM cte_sold_by_country_ranked WHERE rank = 1;
```


Answer:

For cities I decided to stop at the first query since it was clear that the maximum number of products ordered by each (not NULL) city was 1. When partitioning by country I found that the most popular item for Australia was the "Cam Indoor Security Camera - USA", for Canada was the "Men's Zip Hoodie", for Switzerland was the "Men's 3/4 Sleeve Henley", and for United States was the "Learning Thermostat 3rd Gen-USA - Stainless Steel". There are far too few products sold in the dataset to find any pattern.



**Question 5: Can we summarize the impact of revenue generated from each city/country?**

SQL Queries:

```SQL
SELECT v.city
	, (SUM(totaltransactionrevenue)/(SELECT SUM(totaltransactionrevenue) 
	  FROM transactions) * 100)::NUMERIC(10, 3) revenuepercent
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.city

SELECT v.country
	, (SUM(totaltransactionrevenue)/(SELECT SUM(totaltransactionrevenue) 
	  FROM transactions) * 100)::NUMERIC(10, 3) revenuepercent
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.country
```


Answer:

This was only a slight modification of the first question, where I divided the totaltransactionrevneue from each city/country by the sum of the totaltransactionrevenue in transactions, then modified that proportion to a percentage (revenuepercent). I found that the vast majority of revenue (42.661%) came from transactions with no city information available. Standout cities (>5% total revenue) were San Francisco (10.954%), Sunnyvale (6.948%), and Atlanta (5.983%).

For countries I found that 92.108% of revenue came from the United States, 4.215% from Israel, 2.507% from Australia, 1.051% from Canada, and 0.119% from Switzerland.





