select TOP 5 * from Dim_Customer
select TOP 5 * from Dim_Location
select TOP 5 * from Dim_Product
select TOP 5 * from Dim_Region
select TOP 5 * from Fact_Sales

---Phase 1: Aggregations & Data Filtering
---1 Category Performance: Write a query to find the total sales amount and total quantity
---sold for each product category.
SELECT 
  p.Category,
  sum(Sales) as Total_Sales,
  count(Quantity) as Total_Quantity_Sold
FROM Dim_Product p 
JOIN Fact_Sales s ON p.Product_Id = s.Product_Id
GROUP BY p.Category

---2. Top Locations: Identify the top 5 cities that generated the highest total revenue.
select 
  TOP 5
  l.City,
  sum(Sales) as Toatal_Revenue
from Fact_Sales s
join Dim_Location l on s.Location_ID = l.Location_ID
group by l.City
order by Toatal_Revenue desc


---3. High-Value Months: Find the specific months and years where the total monthly sales exceeded a specific target 


---4. Customer AOV: Calculate the Average Order Value (AOV) for each customer. 
----Only include customers who have placed more than 3 orders.
select 
  c.Customer_Id,
  round(avg(s.Sales * 1.0),2) as average_order_value
from Fact_Sales s
join Dim_Customer c on s.Customer_Id = c.Customer_Id
group by c.Customer_Id
having count(s.Order_Id) > 3

---Phase 2
---5. Price Categorization: Use a CASE statement to group products into 'High Value' (Price > 100), 'Medium' (50 to 100), and 'Low' (< 50). 
---Count how many products fall into each bucket.
with bucket_cate as (
select 
  case 
    when s.Sales > 100 then 'High' 
    when s.Sales between 50 and 100 then 'Medium'
    when s.Sales < 50 then 'low'
    end as bucket
from Fact_Sales s
join Dim_Product p on s.Product_Id = p.Product_Id
)
select 
  bucket,
  count(*) as total_product
from bucket_cate
group by bucket 

--second approach
WITH Bucket_Cate AS (
    SELECT 
        Product_Id,
        CASE 
            -- Price nikalne ke liye Sales ko Quantity se divide kiya
            WHEN (Sales / NULLIF(Quantity, 0)) > 100 THEN 'High Value' 
            WHEN (Sales / NULLIF(Quantity, 0)) BETWEEN 50 AND 100 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS Price_Bucket
    FROM Fact_Sales
)
SELECT 
    Price_Bucket,
    COUNT(DISTINCT Product_Id) AS Total_Products
FROM Bucket_Cate
GROUP BY Price_Bucket;


---6. Discount Flags
with Discount_Flags as (
select
  Sales,
  case 
    when Discount > 0.2 then 'High Discount'
    else 'low discount' end as Discount_Flag
from Fact_Sales 
)
select 
  Discount_Flag,
  round(sum(Sales)*1.0,2) as total_revenue
from Discount_Flags
group by Discount_Flag

---7. Weekend vs. Weekday Sales
with day_types as (
select 
  Sales,
  case 
    when DATENAME(WEEKDAY,Order_Date) IN ('Saturday','Sunday') then 'weekend'
    else 'weekday' end as day_type
from Fact_Sales
)
select 
 day_type,
 round(sum(Sales)*1.0,2) as total_revenue
from day_types
group by day_type


---Phase 3
-- 8. Second Highest Product: Find the 2nd highest-selling product in every single category.
WITH ProductSales AS (
    -- Step 1: Har product ki total sales nikalna
    SELECT 
        p.Category, 
        p.Product_Name, 
        SUM(s.Sales) AS Total_Sales
    FROM Fact_Sales s
    JOIN Dim_Product p ON s.Product_Id = p.Product_Id
    GROUP BY p.Category, p.Product_Name
),
RankedProducts AS (
    -- Step 2: Har category ke andar Sales ke hisaab se rank dena
    SELECT 
        Category, 
        Product_Name, 
        Total_Sales,
        DENSE_RANK() OVER (PARTITION BY Category ORDER BY Total_Sales DESC) AS Rnk
    FROM ProductSales
)
-- Step 3: Sirf Rank 2 wale products ko filter karna
SELECT Category, Product_Name, Total_Sales
FROM RankedProducts
WHERE Rnk = 2;


---9. Running Totals (Cumulative Sum) for 2016
with daily as (
select 
  CAST(Order_Date as date) as daily_order,
  sum(Sales) as daily_sales
from Fact_Sales
where YEAR(Order_Date) = 2016
group by CAST(Order_Date as date)
)
select
  daily_order,
  daily_sales,
  sum(daily_sales) over(order by daily_order) as running_total
from daily

---10. Month-over-Month (MoM): Find the difference in total revenue between the current month and the previous month.
with monthly_data as (
select 
  MONTH(Order_Date) as month_num,
  DATENAME(month,Order_Date) as month_name,
  sum(Sales) as total_revenue
from Fact_Sales
group by MONTH(Order_Date),DATENAME(month,Order_Date)
),
lag_data as (
select 
 month_num,
 month_name,
 total_revenue as current_revenue,
 isnull(lag(total_revenue) over(order by month_num),0) as prev_revenue
from monthly_data
)
select 
 month_num,
 month_name,
 current_revenue,
 prev_revenue,
 (current_revenue - ISNULL(prev_revenue,0)) as differ
from lag_data
order by month_num

---11 First Purchase: Assign a row number to every order a customer has placed, ordered by date. 
---Filter the query to show only the very first purchase made by each customer.
select TOP 5 * from Fact_Sales

with customer_detail as (
select 
  Customer_Id,
  Order_Date,
  ROW_NUMBER() over(partition by Customer_Id order by Order_Date) as row_num
from Fact_Sales 
)
select
  Customer_Id,
  Order_Date
from customer_detail
where row_num = 1

---12. Moving Average: Calculate a 7-day moving average of sales to smooth out the daily revenue trend.
with daily_sales as (
select 
 CAST(Order_Date as date) as order_day,
 sum(Sales) as total_sales
from Fact_Sales 
group by CAST(Order_Date as date)
)
select 
  order_day,
  total_sales,
  round(AVG(total_sales) over(order by order_day rows between 6 preceding and current row),2) as moving_avg
from daily_sales

---Phase 4: Views, CTEs & Stored Procedures
---13. Question: Create a View named vw_VIPCustomers that displays all details of customers 
-----whose lifetime spending is in the top 10%.
create or alter view vw_VIPCustomers as 
select 
  top 10 percent
  c.Customer_Id,
  c.Customer_Name,
  sum(s.Sales) as lifetime_spending
from Dim_Customer c
join Fact_Sales s
on c.Customer_Id = s.Customer_Id
group by c.Customer_Id,c.Customer_Name
order by lifetime_spending desc

select * from vw_VIPCustomers

---14. Question: Write a Stored Procedure named sp_GetCategorySales that takes two input parameters 
---(@Year and @CategoryName) and returns the sales details for that specific input.
create or alter Procedure sp_GetCategorySales (
 @Year INT,
 @CategoryName varchar(100)
 )
 AS
 BEGIN 
   SET NOCOUNT ON 
   select 
     p.Product_Name,
     sum(f.Sales) as total_sales,
     sum(f.Quantity) as total_quantity
   from Fact_Sales f
   join Dim_Product p
   on f.Product_Id = p.Product_Id
   where YEAR(f.Order_Date) = @Year
   AND p.Category = @CategoryName
   group by p.Product_Name
   order by total_sales desc
 END

 EXEC sp_GetCategorySales @Year = 2016, @CategoryName = 'Furniture'

 --- store procedure -- total sales by sub category
select 
  p.Sub_Category,
  round(sum(s.Sales),2) as total_sales
from Dim_Product p
join Fact_Sales s on p.Product_Id = s.Product_Id
group by p.Sub_Category
order by total_sales desc

create or alter Procedure sp_getsubCategory_sale (
 @subCategory varchar(100)
)
as 
begin
  select 
  p.Sub_Category,
  round(sum(s.Sales),2) as total_sales
from Dim_Product p
join Fact_Sales s on p.Product_Id = s.Product_Id
where p.Sub_Category = @subCategory
group by p.Sub_Category
order by total_sales desc
end

EXEC sp_getsubCategory_sale @subCategory = 'Phones'

create or alter Procedure sp_getsubCategory_sale2 (
 @subCategory varchar(max)
)
as 
begin
  select 
  p.Sub_Category,
  round(sum(s.Sales),2) as total_sales
from Dim_Product p
join Fact_Sales s on p.Product_Id = s.Product_Id
where p.Sub_Category in (
  select trim(value) from string_split(@subCategory,',')
)
group by p.Sub_Category
order by total_sales desc
end

EXEC sp_getsubCategory_sale2 @subCategory = 'Phones,Chairs,Tables'

---16. YoY Growth Procedure
---Question: Write a Stored Procedure that
---calculates the Year-over-Year (YoY) growth percentage for the entire business, returning the results in a clean table.

create view yoy_growth as 
with yearlySales as ( 
select 
  year(Order_Date) as year_name,
  round(sum(Sales),2) as curr_sales
from Fact_Sales
group by year(Order_Date)
),
prev_data as (
select 
 year_name,
 curr_sales,
 (lag(curr_sales) over(order by year_name)) as prev_sales
from yearlySales
),
growth_calculation as (
select 
  year_name,curr_sales,prev_sales,
  round((curr_sales - prev_sales) * 100.0 / prev_sales,0) as yoy_growth
from prev_data
)
select 
  year_name,curr_sales,prev_sales,
  case 
   when yoy_growth is not null then CAST(yoy_growth as varchar) + '%'
   else 'N/A'
   end as YOY_GROWTH_PER
from growth_calculation

select * from yoy_growth

---RFM analysis view 
create view RFM_ANALYSIS as 
select 
 Customer_Id,
 DATEDIFF(DAY,max(Order_Date), (select max(Order_Date) from Fact_Sales)) as recency_days,
 count(distinct Order_Id) as frequency,
 sum(Sales) as montary_value
from Fact_Sales
group by Customer_Id

select * from RFM_ANALYSIS
order by recency_days , frequency desc, montary_value desc

---store procedure -- customer details
create or alter Procedure customer_details(
 @Customer_Id varchar(100)
)
AS
BEGIN
WITH customers_sales AS (
    SELECT 
        Customer_Id,
        SUM(Sales) AS total_sales,
        COUNT(DISTINCT Order_Id) AS total_orders,
        -- MAX() lagane se ek customer ki sirf 1 Location_ID select hogi, duplicate nahi banega
        MAX(Location_ID) AS single_location_id 
    FROM Fact_Sales
    GROUP BY Customer_Id
)
SELECT 
    s.Customer_Id,
    c.Customer_Name,
    c.Segment,
    l.Country, 
    l.State, 
    l.City,
    s.total_orders,
    s.total_sales
FROM customers_sales s
JOIN Dim_Customer c ON s.Customer_Id = c.Customer_Id
JOIN Dim_Location l ON s.single_location_id = l.Location_ID
where s.Customer_Id = @Customer_Id
END

EXEC customer_details @Customer_Id = 'CG-12520'