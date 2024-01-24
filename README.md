# Final-Project-Transforming-and-Analyzing-Data-with-SQL

## Project/Goals
The goal of this project was to take a toy dataset with messy values and convert it into a normalized relational database managed using PostgreSQL, then answer questions based on that data.

## Process

* First, I imported the data in the .csvs without modification into a PostgresSQL-managed database.
* Then, I created new tables labeled actions, products, sales, sessions, transactions, and visitors to house the raw data.
* Next, I cleaned the raw data in all .csvs with the exception of analytics.csv, while endeavouring to minimize information loss, creating appropriate relationships between the tables for the purpose of normalizing the database.
* Lastly, I split analytics up between the tables, while taking care not to add unnecessary data that was not sufficiently linked to a visitor/product/location.

## Results

The resulting data allowed me to both ask and answer a series of questions, which can be found in starting_with_questions.md and starting_with_data.md. Some highlights of that analysis:

* A large proportion of all revenue earned $1,145,722.53 (36.851%) came from one city, Mountain View. This was a fairly suspect result given that Mountain View is a relatively small city with a population of 82,376, but could be possible if it is the main area that the ecommerce business actually services, or if very large orders are made from there.
* After the United States which makes up 99.487% of total revenue, the country that provides the most revenue is Czechia.
* Visitors that made purchases had 75% more page views than the average.
* Referrals were 42.5% more likely to be converted into sales than the next most likely channel, which was direct links. (NOTE: this was only calculated based on the information in all_sessions, not analytics).

## Challenges 

* Developing a non-destructive import pipeline: while familiarizing myself with the dataset and importing/distributing data, there were multiple occasions where data was modified or deleted unnecessarily.
* Normalizing the database in a way that made sense and did not lose information.
* Common data betwen all_sessions and analytics was contradictory. Often in a reconcilable way, but that reconciliation came with the risk of potentially mislabelling data.
* Certain data types were difficult/impossible to interpret, particularly time data. 
* Analysis was limited by the lack of time data.


## Future Goals

* Starting with drawing relationships and searching for an appropriate primary key in all of the established tables was a mistake. I would like to start from scratch, combining data in all_sessions and analytics into one large table, then extracting data from that central table to the pre-defined relations. Only then would I define primary/foreign keys on each table.
* Further normalize the database. I left too much product information in the transactions table instead of moving it to the products table. Actions ended up being a table where I moved information that made sessions harder to interpret instead of a table that contained useful, atomic data on its own. A lot of information was still duplicated.
* Add data from the analytics table into the actions table. This would also allow me to remove much of the duplicate data that was added to sessions when I extracted it from analytics.
* Attempt to interpret time/timestamps/time intervals. The way that they were listed in the data was opaque which led to me ignoring them, but time data is very valuable.
* Better QA throughout. particularly for the process of breaking up analytics into the individual tables. Too much information was lost in the process.
* Not remove data in analytics that wasn't associated with a visitor. It might have been possible to link data that did not have a corresponding fullvisitorid in visitors to a product using the unit_price/visitorid, though this would have been messy.
* Use more statistically rigourous methods of determining where data in analytics should be allocated.
* Determine the relationship between totaltransactionrevenue and productrevenue.
