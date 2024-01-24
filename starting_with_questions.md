Answer the following questions and provide the SQL queries used to find the answer.

    
**Question 1: Which cities and countries have the highest level of transaction revenues on the site?**


SQL Queries:

```SQL
SELECT v.city
	, SUM(totaltransactionrevenue) totaltransactionrevenue
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.city;

SELECT v.country
	, SUM(totaltransactionrevenue) totaltransactionrevenue
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.country;
```




Answer:

City:

city | totaltransactionrevenue
---------------------|----------------
NULL 1456520.16
"South San Francisco"	207.82
"Austin"	6170.40
"Fremont"	362.00
"Cupertino"	119.00
"Santa Monica"	104.46
"Stockholm"	24.99
"Bangkok"	27.98
"Courbevoie"	3.99
"Zhongli District"	18.99
"Jersey City"	9070.04
"San Jose"	7610.81
"Cambridge"	859.61
"Salem"	2905.64
"Tel Aviv-Yafo"	602.00
"New York"	105457.44
"San Francisco"	6281.82
"Jakarta"	34.99
"London"	256.87
"San Diego"	1.99
"Osaka"	30.98
"Bogota"	167.97
"Palo Alto"	3801.99
"Sydney"	379.98
"Santa Clara"	66.96
"Chicago"	49365.70
"Houston"	38.98
"San Bruno"	247506.35
"Seattle"	1773.65
"Columbus"	21.99
"Helsinki"	74.97
"Hong Kong"	1360.05
"Kitchener"	15.19
"Los Angeles"	6905.28
"Ann Arbor"	1379.87
"Paris"	529.06
"Phoenix"	14.69
"Mountain View"	1145722.53
"Minato"	279.90
"Montevideo"	16.99
"Sunnyvale"	24652.58
"Kirkland"	8957.90
"Irvine"	104.39
"Nashville"	4326.00
"Hamburg"	226.90
"Milpitas"	3097.74
"Munich"	16.99
"Zurich"	215.99
"Denver"	155.92
"Yokohama"	90.74
"Charlotte"	7760.73
"Madrid"	99.99
"Ahmedabad"	3.99
"Toronto"	1987.89
"Atlanta"	1409.90
"Seoul"	16.98

Country:

country|totaltransactionrevenue
-----------|---------------------
"Indonesia"	74.98
"Sweden"	35.98
"Dominican Republic"	33.98
"Singapore"	109.08
"Sri Lanka"	205.96
"Portugal"	4.99
"Finland"	74.97
"Colombia"	169.47
"France"	19.47
"Israel"	602.00
"Hong Kong"	1732.00
"United States"	3093113.74
"Belarus"	55.99
"Netherlands"	16.99
"Australia"	407.96
"Spain"	99.99
"Taiwan"	165.62
"Thailand"	27.98
"Uruguay"	16.99
"United Kingdom"	265.86
"Germany"	395.84
"Canada"	3192.39
"South Korea"	16.98
"Egypt"	4.99
"India"	20.98
"Japan"	536.48
"Switzerland"	215.99
"Russia"	181.98
"Norway"	16.99
"Guatemala"	59.99
"Panama"	199.00
"Mexico"	874.00
"Czechia"	6269.10


**Question 2: What is the average number of products ordered from visitors in each city and country?**


SQL Queries:

For the average ordered when any product was ordered:

```SQL
SELECT v.city
	, AVG(t.productquantity)::INT
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.city

SELECT v.country
	, AVG(t.productquantity)::INT
FROM transactions t
JOIN sessions s USING(transactionid)
JOIN visitors v USING(fullvisitorid)
GROUP BY v.country
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
-----|----------
NULL	19
"South San Francisco"	1
"Austin"	4
"Fremont"	1
"Cupertino"	1
"Santa Monica"	1
"Stockholm"	1
"Bangkok"	1
"Courbevoie"	1
"Zhongli District"	1
"Jersey City"	5
"San Jose"	12
"Cambridge"	3
"Salem"	8
"Tel Aviv-Yafo"	
"New York"	10
"San Francisco"	1
"Jakarta"	1
"London"	1
"San Diego"	1
"Osaka"	1
"Bogota"	1
"Palo Alto"	1
"Sydney"	1
"Santa Clara"	1
"Chicago"	5
"Houston"	
"San Bruno"	58
"Seattle"	4
"Columbus"	1
"Helsinki"	1
"Hong Kong"	1
"Kitchener"	1
"Los Angeles"	4
"Ann Arbor"	1
"Paris"	4
"Phoenix"	1
"Mountain View"	24
"Minato"	1
"Montevideo"	1
"Sunnyvale"	6
"Kirkland"	2
"Irvine"	1
"Nashville"	6
"Hamburg"	2
"Milpitas"	2
"Munich"	1
"Zurich"	1
"Denver"	2
"Yokohama"	1
"Charlotte"	5
"Madrid"	1
"Ahmedabad"	1
"Toronto"	2
"Atlanta"	4
"Seoul"	1

Country:

Country | average
--------|----------
"Indonesia"	1
"Sweden"	1
"Dominican Republic"	1
"Singapore"	1
"Sri Lanka"	1
"Portugal"	1
"Finland"	1
"Colombia"	1
"France"	1
"Israel"	
"Hong Kong"	1
"United States"	15
"Belarus"	1
"Netherlands"	1
"Australia"	1
"Spain"	1
"Taiwan"	1
"Thailand"	1
"Uruguay"	1
"United Kingdom"	1
"Germany"	1
"Canada"	2
"South Korea"	1
"Egypt"	1
"India"	1
"Japan"	1
"Switzerland"	1
"Russia"	1
"Norway"	1
"Guatemala"	1
"Panama"	1
"Mexico"	2
"Czechia"	25

NOTE: These tables only contain cities and countries with visitors that made transactions. All other cities and countries in the table would have NULL/0 averages.

For the average ordered including when no products were ordered:

Country:

country | average
--------------|--------
"Czechia"	1.23
"Indonesia"	0.02
"Sweden"	0.03
"Dominican Republic"	0.14
"Singapore"	0.02
"Sri Lanka"	0.18
"Finland"	0.17
"Portugal"	0.04
"Colombia"	0.07
"France"	0.02
"Hong Kong"	0.70
"United States"	2.70
"Belarus"	0.14
"Netherlands"	0.01
"Australia"	0.02
"Spain"	0.01
"Taiwan"	0.05
"Thailand"	0.03
"Uruguay"	0.08
"United Kingdom"	0.01
"Germany"	0.05
"Canada"	0.14
"South Korea"	0.04
"Egypt"	0.08
"Japan"	0.11
"Switzerland"	0.01
"Russia"	0.03
"Norway"	0.03
"Guatemala"	0.10
"Panama"	0.06
"Mexico"	0.04

City:

city | average
-------------|--------
	1.77
"South San Francisco"	0.60
"Austin"	0.94
"Fremont"	0.16
"Cupertino"	0.07
"Santa Monica"	1.00
"Stockholm"	0.05
"Bangkok"	0.05
"Courbevoie"	0.33
"Zhongli District"	0.20
"Jersey City"	3.63
"San Jose"	1.41
"Cambridge"	0.98
"Salem"	2.56
"New York"	1.80
"San Francisco"	0.09
"Jakarta"	0.04
"London"	0.03
"San Diego"	0.04
"Osaka"	0.25
"Bogota"	0.13
"Palo Alto"	0.16
"Sydney"	0.03
"Santa Clara"	0.05
"Chicago"	1.63
"San Bruno"	18.53
"Seattle"	1.01
"Columbus"	0.50
"Helsinki"	0.75
"Hong Kong"	0.79
"Kitchener"	0.13
"Los Angeles"	0.55
"Ann Arbor"	0.51
"Paris"	0.25
"Phoenix"	0.13
"Mountain View"	4.33
"Minato"	0.20
"Montevideo"	0.33
"Sunnyvale"	1.43
"Kirkland"	0.84
"Irvine"	0.20
"Nashville"	3.67
"Hamburg"	0.56
"Milpitas"	1.13
"Munich"	0.07
"Zurich"	0.04
"Denver"	0.67
"Yokohama"	0.46
"Charlotte"	4.18
"Madrid"	0.05
"Ahmedabad"	0.08
"Toronto"	0.26
"Atlanta"	0.51
"Seoul"	0.07

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

For this question, I only considered sessions where transactions occurred (a product was ordered) and a sku existed for the transaction (the product category was defined). I found that there was a potential trend of large cities ordering from 'Nest-USA', but given the tiny number of data points (45) it isn't possible to be confident about any patterns. For countries there were only 3 transactions containing products where the category was labeled outside of the United States, so no trend by country could be identified.


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

For cities I decided to stop at the first query since it was clear that the maximum number of labeled products ordered by each (not NULL) city was 1. When partitioning by country I found that the most popular item for Australia was the "Cam Indoor Security Camera - USA", for Canada was the "Men's Zip Hoodie", for Switzerland was the "Men's 3/4 Sleeve Henley", and for United States was the "Learning Thermostat 3rd Gen-USA - Stainless Steel". There are far too few labeled products sold in the dataset to find any pattern.



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

This was only a slight modification of the first question, where I divided the totaltransactionrevneue from each city/country by the sum of the totaltransactionrevenue in transactions, then modified that proportion to a percentage (revenuepercent). I found that the vast majority of revenue (46.84764%) came from transactions with no city information available. Standout cities (>5% total revenue) were San Bruno (7.96%), and Mountain View with a staggering (36.85%).

For countries I found that 99.487% of revenue came from the United States, while the next largest contributor was Czechia at 0.20%. All other countries countributed less than 0.1% of total revenue.





