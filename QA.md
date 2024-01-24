# Risk areas

* Improper data type conversion on import
* Removing information when cleaning data
* Improper matching between tables
* Importing only useful information from analytics and divying it up appropriately.
* Joins having the correct number of entries, particularly where I am only interested in sessions that resulted in transactions)


# Preimport

I ran into an issue where opening the csv files using LibreOffice Calc in order to familiarize myself with the data modified the original values. In particular, some large values were converted to scientific notation. My first instinct was to simply convert the values back to standard form. However, after doing so I downloaded a fresh copy of all_sessions.csv in order to verify that no information was modified in the process.

I simply used:

```
head all_sessions2.csv
head all_sessions.csv
```

In the terminal and checked the first 10 rows in each csv. As it turned out, the values of fullvisitorid were not just converted to scientific notation, the last digit was also rounded. Ultimately I decided that it would be best to simply upload completely untouched copies of the csvs to the database.

# Import

## all_sessions

During import the only modification that I made to all_sessions was defining the data type for each column. I erred on the side of leaving columns in the most general type possible, but I did define some types more specifically. All values were defined as either text or numeric, while date was set as type date. Since a successful import meant that the date values were at least in a valid form for conversion, the only thing I needed to check was that there were no drastic outliers for date.
Using

```SQL
SELECT MAX(date), MIN(date) FROM all_sessions;
```

From all_sessions returned a minimum date of 2016-08-01 and a maximum date of 2017-08-01. Since this range was relatively small for the type of dataset being considered I concluded that there were no egregious outliers.

## analytics

Very similar to all_sessions for QA purposes. The one extra step that I took was checking that values from unit_price did not exceed 1000 after dividing the unit_price column by 1000000 and did not have any values less than 0. I set the cutoff at 1000 arbitrarily based on the products that were already present in products.csv as it did not seem that the dataset included particularly expensive products.

```SQL
SELECT MAX(unit_price) FROM analytics;
```

Returned $936.00. Higher than I expected, but within the range that I was willing to accept.

```SQL
SELECT unit_price FROM analytics WHERE unit_price < 0;
```

Returned no data, as expected.

## products

Since products should be a list of distinct products provided, I checked that all of the sku present were distinct

```SQL
SELECT * FROM products;
SELECT DISTINCT(sku) FROM products;
```
Both returned 1092, so this was confirmed.

I then checked for NULL values in products. Only productcategory was ever NULL. I chose to leave these values as missing rather than populating them using the name of the product since this would be too time-consuming. I also checked that orderedquantity, stocklevel, and restockingleadtime were all greater than 0 in the same way that I checked unit_price in analytics.

# sales_by_sku

After a bit of digging I found that sales_by_sku contained 462 unique values while sales_report contained 454. All 454 unique values in sales_report had a corresponding row in sales_by_sku, and
both tables agreed on the total_ordered.

```SQL
SELECT *
FROM sales_by_sku
LEFT JOIN sales_report USING(productsku, total_ordered)
```

 Since this implies that all information save for 8 rows in sales_by_sku is contained in sales_report I simply created a new table, sales, which contained the combination of the information contained in these two tables. I decided to treate sales_report as a subset of sales_by_sku containing additional information for some sales.
 
```SQL
CREATE TABLE sales AS (
SELECT *
FROM sales_by_sku
LEFT JOIN sales_report USING(productsku, total_ordered)
)
```

## sales_report

See above.

# Normalization and Disambiguation

Ultimately I decided to break up all of the information into 6 different tables: sessions, actions (carried out within sessions), products, sales, transactions, and visitors.

There were various pitfalls when breaking up all_sessions. Firstly, it would often create effectively duplicate information in the tables it was moved into. For example, after attempting to move v2productcategory and v2productname into the products table using

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

I found that the products_temp table had 1303 distinct rows instead of the expected 1092 that products had. Upon closer inspection of the added information I found that there were two issues: firstly, v2productname would often describe the same product slightly differently (i.e. 'Google Men's Pullover Hoodie' vs. 'Google Men's Pullover Hoodie Grey') and that the v2productcategory would often give very similar categories, but with different levels of specificity (i.e. Home/Accessories/Fun vs. Home/Accesories). I ultimately decided to remove v2productname from products as it did not add much more information than the name column, and only include the productcategory with the highest degree of specificity (which I determined using text length, acknowledging that some particularly long lower level categories might cause the most specific category to be misidentified. To check that that wasn't the case I simply joined the the products table with all_sessions using sku and hand-checked all v2productcategory vs productcategory.

```SQL
SELECT v2productcategory, productcategory
FROM all_sessions
JOIN productcategory USING(sku);
```

I found that all of the productcategories were as specific as possible, as I had hoped. Given more time (or on a larger database) I would likely instead count the number of '/' characters in v2productcategory to determine which is the most specific.


In cleaning the transactions table, the most important thing to QA was that the new transactionids that I had assigned to the transactions table matched with the old transactionids in the sessions table. I did this by joining them via visitid and oldtransactionid then replacing the transactionid in sessions with newtransactionid, where transactionid was already present in sessions. Otherwise, I added a transactionid where productrevenue was present in all_sessions (meaning that I identified a transaction as having taken place even though no transactionid was present.

Cleaning the sessions table so that no duplicate sessions were present proved to be difficult. Ultimately, this lead to the creation of the actions table

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


Once these values were removed I checked the number of distinct visitids in sessions and found that there were only 7 visitids that identified more than one row. After inspecting these rows, I found they could be distinguished from their "duplicates" by their fullvisitorid and in one case a transactionid. This implied to me that these were truly distinct values. Ultimately, rather than using visitid as the primary key for sessions I opted to create a new sessionid.

```SQL
SELECT DISTINCT *
FROM sessions
```

Which at least ensured that sessions contained no duplicate values.

The last table that required some QA on creation was visitors. The query

```SQL
SELECT * FROM visitors
WHERE fullvisitorid IN
(SELECT fullvisitorid 
 FROM visitors 
 GROUP BY fullvisitorid 
 HAVING COUNT(fullvisitorid) > 1)
ORDER BY fullvisitorid
```

Revealed that the information for each visitor was mainly in agreement except where pageview differed. There were two main cases where fullvisitorid was duplicated in all_sessions: first, where the visitor had multiple sessions in the table. Second, where the same session was recorded multiple times due to different actions being taken in the same session. Where there were multiple values of pageviews I decided that the best course of action was to set pageviews equal to the duplicated value if the values were equal, and sum them if they were not. This unfortunately did make the pageview data much less reliable as if there were two separate sessions with the same amount of pageviews, one sessions pageviews would not be counted. This biased pageviews to be much smaller than the probable values.

# Adding data from analytics

There were many QA obstacles associated with adding the data from analytics into the established tables.

Firstly, I needed to pare down analytics in a way that made sense. I first noted that visitstarttime was nearly identical to visitid for values that I manually checked. This led to me removing visitstarttime as a column. Next I decided that values in analytics that were not associated with a visitor already present in the visitors table would not be usable for my analysis, since they would not have location or product information.

Those two actions removed the vast majority of rows in analytics, leaving me with only 83210 rows of usable data.

The next obstacle was translating the data present in analytics into the existing tables. The data in analytics was labeled differently than in all_sessions. I used a combination of name similarity and value comparison to determine where the data was most likely to fit.

I also needed to make sure that analytics didn't produce contradictory values where ids obviously matched. This was particularly important for the dates already associated with visitids in the table.

```SQL
SELECT s.date, a.date
FROM sessions s
JOIN analytics a USING(visitid)
WHERE s.date != a.date

SELECT (s.date - a.date)
FROM sessions s
JOIN analytics a USING(visitid)
WHERE s.date != a.date AND s.date - a.date > 1
```

What I found was encouraging. The dates associated with visitids in each table only differed occasionally, and where they did they it was by a maximum of 1 day. Everywhere else the best I could do was look at the MAX and MIN values and see how they corresponded to similar values in the tables. For example,

```SQL
SELECT MAX(unit_price), MIN(unitprice) FROM analytics;
SLEECT MAX(productprice), MIN(productprice) FROM transactions;
```
This combined with the column label led me to interpret unit_price as equivalent to productprice in the transactions table.

Overall, my QA process for adding the analytics.csv data to the rest of the database was lacking and this is something I would like to improve on given more time.





