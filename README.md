# -SQL-Explore-Ecommerce-Dataset
# 1.	Introduction
This project analyzes website activity data from 2017 stored in a public eCommerce dataset on Google BigQuery. The data originates from Google Analytics user sessions.

Through SQL queries on BigQuery, we will explore various aspects of the website in 2017. This includes calculating bounce rates, identifying peak revenue days, analyzing user behavior on specific pages, and performing other analyses to gain insights into the business health, marketing effectiveness, and product performance.
## 2.	Requirements

•	Google Cloud Platform account

•	Project on Google Cloud Platform

•	Google BigQuery API enabled

•	SQL query editor or IDE
## 3.	 The goal of creating this project

•	Overview of website activity

•	Bounce rate analysis

•	Revenue analysis

•	Transactions analysis

•	Products analysis
## 4. Import raw data

The eCommerce dataset is stored in a public Google BigQuery dataset. To access the dataset, follow these steps:

•	Log in to your Google Cloud Platform account and create a new project.

•	Navigate to the BigQuery console and select your newly created project.

•	Select "Add Data" in the navigation panel and then "Search a project".

•	Enter the project ID "bigquery-public-data.google_analytics_sample.ga_sessions" and click "Enter".

•	Click on the "ga_sessions_" table to open it.
## 5.	 Exploring the Dataset

In this project, I will write 08 query in Bigquery base on Google Analytics dataset

**Query 01: Calculate total visit, pageview, transaction and revenue for January, February and March 2017 order by month**

 ![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/ea9ff773-a8dc-4286-a039-050f469832c3)
 
**•	Query results**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/0636c431-4e50-4346-a177-2daacb2715ed)

**Query 02: Bounce rate per traffic source in July 2017**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/1aa309bd-aaa6-4179-b5a3-13e0f270b61d)

**•	Query results**

 ![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/afab8476-ddac-4c48-a13b-bbef75685b62)
 
**Query 3: Revenue by traffic source by week, by month in June 2017**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/e9c5b80f-78c8-4175-a3a9-aac6f7c09c13)

**•	Query results**

 ![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/aa0b7078-a3a8-4267-b7a8-0d943b6ba6ef)
 
**Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/bc2cf150-bad9-42e8-8029-627d1b94f79a)

**•	Query results**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/964fb121-e3d7-4998-8418-b70067e144d6)

Query 05: Average number of transactions per user that made a purchase in July 2017

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/bf5b4641-0b00-4d2b-a1de-0fc58bb4c7dc)

**•	Query results**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/0a3bd74e-d3ec-4b12-854d-a8941666c6a9)
 
**Query 06: Average amount of money spent per session**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/ff349089-6dae-4ebf-a2c8-f00d84038edf)

**•	Query results**

 ![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/b061702f-3549-4a7a-8617-8b4c64cebac9)

**Query 07: Other products purchased by customers who purchased product” Youtube Men’s Vintage Henley” in July 2017**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/93ac2b9f-bb69-45cb-8794-fc3879f7ee97)

**• Query results**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/faa5ad3d-e552-4a20-8ec1-5b40d82cb60b)
 
**Query 08: Calculate cohort map from pageview to addtocart to purchase in last 3 month. For example, 100% pageview then 40% add_to_cart and 10% purchase.**
```WITH addtocart AS
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
ORDER BY month;```

**• Query results**

![image](https://github.com/lekhuong0196/-SQL-Explore-Ecommerce-Dataset/assets/138196501/a55c1d3e-3f51-433f-a14e-53498aa31662)

## **5.	Conclusion**
   
This e-commerce dataset analysis on BigQuery served as a valuable learning experience about the marketing landscape and customer journeys. By analyzing metrics like bounce rate, transactions, revenue, visits, and purchases, we gained a deeper understanding of customer behavior.

Furthermore, examining referral sources revealed which marketing channels are most successful in driving traffic and sales. This knowledge allows for strategic resource allocation, prioritizing effective channels and optimizing less performing ones to maximize marketing return on investment (ROI).

In conclusion, exploring the data within BigQuery yielded a treasure trove of insights crucial for strategic decision-making. These insights can be leveraged to optimize business operations, enhance customer experiences, and ultimately drive revenue growth.

Overall, this project has demonstrated the power of SQL and big data tools like Google BigQuery to gain insights from large datasets.

