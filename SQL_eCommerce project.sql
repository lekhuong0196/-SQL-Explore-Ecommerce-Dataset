-- Query 01: calculate total visit, pageview, transaction and revenue for Jan, Feb and March 2017 order by month

   SELECT 
    FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) month_extract
    ,SUM(totals.visits) visits
    ,SUM(totals.pageviews) pageviews
    ,SUM(totals.transactions) transactions
    ,ROUND(SUM(totals.totalTransactionRevenue)/POW(10,6),2) revenue
   FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
   WHERE _table_suffix BETWEEN '0101' AND '0331'
   GROUP BY month_extract


-- Query 02: Bounce rate per traffic source in July 2017

SELECT
    trafficSource.source as source,
    sum(totals.visits) as total_visits,
    sum(totals.Bounces) as total_no_of_bounces,
    (sum(totals.Bounces)/sum(totals.visits))* 100 as bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;

-- Query 3: Revenue by traffic source by week, by month in June 2017
WITH GET_RE_MONTH AS 
(
    SELECT DISTINCT
        CASE WHEN 1=1 THEN "Month" END time_type,
        FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS time ,
        trafficSource.source AS source,
        ROUND(SUM(totals.totalTransactionRevenue/1000000) OVER(PARTITION BY trafficSource.source),2) revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
),

GET_RE_WEEK AS 
(
    SELECT
        CASE WHEN 1=1 THEN "WEEK" END time_type,
        FORMAT_DATE("%Y%W", PARSE_DATE("%Y%m%d", date)) AS time,
        trafficSource.source AS source,
        SUM(totals.totalTransactionRevenue)/1000000 revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    WHERE _table_suffix BETWEEN '0601' AND '0630'
    GROUP BY 1,2,3
)

SELECT * FROM GET_RE_MONTH
UNION ALL 
SELECT * FROM GET_RE_WEEK
ORDER BY revenue DESC;



--Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017. 

WITH GET_6_MONTH AS (
  SELECT  
CASE WHEN 1= 1 THEN "201706" END AS MONTH,
SUM(CASE WHEN totals.transactions >=1 THEN totals.pageviews END) AS TOTAL_PUR_PAGEVIEWS,
SUM(CASE WHEN totals.transactions IS NULL THEN totals.pageviews END) AS TOTAL_NON_PUR_PAGEVIEWS,
COUNT(DISTINCT(CASE WHEN totals.transactions >=1 THEN fullVisitorId END)) AS NUM_PUR,
COUNT(DISTINCT(CASE WHEN totals.transactions IS NULL THEN fullVisitorId END)) AS NUM_NON_PUR
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`),

GET_7_MONTH AS (SELECT  
CASE WHEN 1= 1 THEN "201707" END AS MONTH,
SUM(CASE WHEN totals.transactions >=1 THEN totals.pageviews END) AS TOTAL_PUR_PAGEVIEWS,
SUM(CASE WHEN totals.transactions IS NULL THEN totals.pageviews END) AS TOTAL_NON_PUR_PAGEVIEWS,
COUNT(DISTINCT(CASE WHEN totals.transactions >=1 THEN fullVisitorId END)) AS NUM_PUR,
COUNT(DISTINCT(CASE WHEN totals.transactions IS NULL THEN fullVisitorId END)) AS NUM_NON_PUR
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`)

SELECT MONTH as month ,
TOTAL_PUR_PAGEVIEWS/NUM_PUR as avg_pageviews_purchase,
TOTAL_NON_PUR_PAGEVIEWS/NUM_NON_PUR as avg_pageviews_non_purchase
FROM GET_6_MONTH

UNION ALL

SELECT MONTH as month ,
TOTAL_PUR_PAGEVIEWS/NUM_PUR as avg_pageviews_purchase,
TOTAL_NON_PUR_PAGEVIEWS/NUM_NON_PUR as avg_pageviews_non_purchase
FROM GET_7_MONTH
ORDER BY MONTH;
--câu 4 này lưu ý là mình nên dùng full join, bởi vì trong câu này, phạm vi chỉ từ tháng 6-7, nên chắc chắc sẽ có pur và nonpur của cả 2 tháng
--mình inner join thì vô tình nó sẽ ra đúng. nhưng nếu đề bài là 1 khoảng thời gian dài hơn, 2-3 năm chẳng hạn, nó cũng tháng chỉ có nonpur mà k có pur
--thì khi đó inner join nó sẽ làm mình bị mất data, thay vì hiện số của nonpur và pur thì nó để trống



-- Query 05: Average number of transactions per user that made a purchase in July 2017

WITH GET_AVG_7_MONTH AS (SELECT
CASE WHEN 1 = 1 THEN "201707" END AS Month,
SUM(CASE WHEN totals.transactions >=1 THEN totals.transactions END ) AS total_transactions,
COUNT(DISTINCT(CASE WHEN totals.transactions >=1 THEN fullVisitorId END )) AS NUM_USER
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`)

SELECT 
Month,
ROUND(total_transactions/NUM_USER,2) as Avg_total_transactions_per_user
FROM GET_AVG_7_MONTH;



-- Query 06: Average amount of money spent per session

SELECT 
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  ROUND((SUM(product.productRevenue) / SUM(totals.visits))/1000000,2) AS Avg_revenue_by_user_per_visit
FROM 
  `bigquery-public-data.google_analytics_sample.ga_sessions_*`, 
  UNNEST(hits) AS hits, 
  UNNEST(hits.product) AS product
WHERE 
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
  AND product.productRevenue IS NOT NULL
  AND totals.transactions IS NOT NULL
GROUP BY month;



-- Query 07: Products purchased by customers who purchased product A (Classic Ecommerce
#standardSQL

WITH GET_CUS_ID AS (SELECT DISTINCT fullVisitorId as Henley_CUSTOMER_ID
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST(hits) AS hits,
UNNEST(hits.product) as product
WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
AND product.productRevenue IS NOT NULL)

SELECT product.v2ProductName AS other_purchased_products,
       SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` TAB_A 
RIGHT JOIN GET_CUS_ID
ON GET_CUS_ID.Henley_CUSTOMER_ID=TAB_A.fullVisitorId,
UNNEST(hits) AS hits,
UNNEST(hits.product) as product
WHERE TAB_A.fullVisitorId IN (SELECT * FROM GET_CUS_ID)
    AND product.v2ProductName <> "YouTube Men's Vintage Henley"
    AND product.productRevenue IS NOT NULL
GROUP BY product.v2ProductName
ORDER BY QUANTITY DESC;


--Query 08: Calculate cohort map from pageview to addtocart to purchase in last 3 month. For example, 100% pageview then 40% add_to_cart and 10% purchase.

WITH addtocart AS
(
       SELECT
       FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS month
       ,COUNT(eCommerceAction.action_type) AS num_addtocart
       FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`   
               ,UNNEST (hits) AS hits
       WHERE _table_suffix BETWEEN '0101' AND '0331'
               AND eCommerceAction.action_type = '3'
       GROUP BY month 
)
   , productview AS
(
       SELECT
       FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS month
       ,COUNT(eCommerceAction.action_type) AS num_product_view
       FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`   
               ,UNNEST (hits) AS hits
       WHERE _table_suffix BETWEEN '0101' AND '0331'
               AND eCommerceAction.action_type = '2'
       GROUP BY month 
)
   , id_purchase_revenue AS -- this is the first step to inspect the purchase step
(
               SELECT
       FORMAT_DATE("%Y%m",PARSE_DATE("%Y%m%d",date)) AS month
       ,fullVisitorId
       ,eCommerceAction.action_type
       ,product.productRevenue -- notice that not every purchase step that an ID made that the revenue was recorded (maybe refund?).
       FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`   
               ,UNNEST (hits) AS hits
               ,UNNEST (hits.product) AS product -- productrevenue 
       WHERE _table_suffix BETWEEN '0101' AND '0331'
               AND eCommerceAction.action_type = '6'
)
   , purchase AS
(
       SELECT 
           month
           ,COUNT(action_type) AS num_purchase
       FROM id_purchase_revenue 
       WHERE productRevenue IS NOT NULL
       GROUP BY month
)
SELECT 
       month
       ,num_product_view
       ,num_addtocart
       ,num_purchase
       ,ROUND(num_addtocart / num_product_view * 100.0, 2) AS add_to_cart_rate
       ,ROUND(num_purchase / num_product_view * 100.0, 2) AS purchase_rate
FROM productview
JOIN addtocart
USING (month)
JOIN purchase
USING (month)
ORDER BY month;

