DROP TABLE all_sessions;
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

SELECT * FROM all_sessions

COPY all_sessions(
	fullVisitorId,
	channelGrouping,
	time,
	country,
	city,
	totalTransactionRevenue,
	transactions,
	timeOnSite,
	pageviews,
	sessionQualityDim,
	date,
	visitId,
	type,
	productRefundAmount,
	productQuantity,
	productPrice,
	productRevenue,
	productSKU,
	v2ProductName,
	v2ProductCategory,
	currencyCode,
	itemQuantity,
	itemRevenue,
	transactionRevenue,
	transactionID,
	pageTitle,
	searchKeyword,
	pagePathLevel1,
	eCommerceAction_type,
	eCommerceAtion_step,
	eCommerceAtion_option
)
FROM '/home/tylan/Documents/lhl/sql_project/csv_data/all_sessions.csv'
DELIMITER ','
CSV HEADER;

DROP TABLE all_sessions;
	
	
	
	
	
	
