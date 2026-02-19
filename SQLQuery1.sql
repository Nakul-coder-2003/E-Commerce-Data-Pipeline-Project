select TOP 5 * from Dim_Customer
select count(*) from Dim_Location
select count(*) from Dim_Product
select count(*) from Dim_Region
select count(*) from Fact_Sales


-- 1. Primary Keys Set
ALTER TABLE dbo.Dim_Customer ADD CONSTRAINT PK_Cust PRIMARY KEY (Customer_Id);
ALTER TABLE dbo.Dim_Location ADD CONSTRAINT PK_Loc PRIMARY KEY (Location_ID);
ALTER TABLE dbo.Dim_Product ADD CONSTRAINT PK_Prod PRIMARY KEY (Product_Id);
ALTER TABLE dbo.Dim_Region ADD CONSTRAINT PK_Reg PRIMARY KEY (Region_Id);
ALTER TABLE dbo.Fact_Sales ADD CONSTRAINT PK_Sales PRIMARY KEY (Order_Id);

-- 2. Foreign Keys Set
ALTER TABLE Fact_Sales ADD CONSTRAINT FK_Cust FOREIGN KEY (Customer_Id) REFERENCES Dim_Customer(Customer_Id);
ALTER TABLE Fact_Sales ADD CONSTRAINT FK_Prod FOREIGN KEY (Product_Id) REFERENCES Dim_Product(Product_Id);
ALTER TABLE Fact_Sales ADD CONSTRAINT FK_Loc FOREIGN KEY (Location_ID) REFERENCES Dim_Location(Location_ID);
ALTER TABLE Fact_Sales ADD CONSTRAINT FK_Reg FOREIGN KEY (Region_ID) REFERENCES Dim_Region(Region_ID);

-- create view 1
CREATE VIEW vw_Master_Sales AS
SELECT 
    f.Order_Date,
    f.Ship_Date,
    f.Sales,
    f.Quantity,
    f.Profit,
    f.Discount,
    p.Product_Name,
    p.Category,
    p.Sub_Category,
    c.Customer_Name,
    c.Segment,
    l.City,
    l.State,
    l.Country,
    r.Region
FROM Fact_Sales f
JOIN Dim_Product p ON f.Product_Id = p.Product_Id
JOIN Dim_Customer c ON f.Customer_Id = c.Customer_Id
JOIN Dim_Location l ON f.Location_ID = l.Location_ID
JOIN Dim_Region r ON f.Region_ID = r.Region_ID;

SELECT Top 10 * FROM vw_Master_Sales

-- create view 2 (YoY Growth Analysis)
CREATE VIEW vw_YoY_Growth AS
WITH YearlySales AS (
    SELECT 
        YEAR(Order_Date) as Order_Year,
        SUM(Sales) as Total_Sales,
        SUM(Profit) as Total_Profit
    FROM Fact_Sales
    GROUP BY YEAR(Order_Date)
)
SELECT 
    Order_Year,
    Total_Sales,
    -- LAG function pichle saal ki sales uthayega
    round(LAG(Total_Sales) OVER (ORDER BY Order_Year),2) as Previous_Year_Sales,
    
    -- Growth Calculation: (This Year - Last Year) / Last Year
    round((Total_Sales - LAG(Total_Sales) OVER (ORDER BY Order_Year)) / 
      LAG(Total_Sales) OVER (ORDER BY Order_Year),2) * 100 as YoY_Growth_Percent
FROM YearlySales;

SELECT * FROM vw_YoY_Growth

-- creat view 3 RFM Analysis View (Customer Segmentation)
CREATE VIEW vw_RFM_Analysis AS
SELECT 
    c.Customer_Name,
    MAX(f.Order_Date) as Last_Order_Date,
    
    -- Recency: Aaj se kitne din pehle order kiya
    DATEDIFF(day, MAX(f.Order_Date), (SELECT MAX(Order_Date) FROM Fact_Sales)) as Recency_Days,
    
    -- Frequency: Total kitne orders kiye
    COUNT(DISTINCT f.Order_Id) as Frequency,
    
    -- Monetary: Total kitna kharch kiya
    SUM(f.Sales) as Monetary_Value
FROM Fact_Sales f
JOIN Dim_Customer c ON f.Customer_Id = c.Customer_Id
GROUP BY c.Customer_Name;

SELECT * FROM vw_RFM_Analysis

-- create view 4 (Shipping_Performance)
CREATE VIEW vw_Shipping_Performance AS
SELECT 
    f.Ship_Mode,
    r.Region,
    -- Average days taken to ship
    AVG(DATEDIFF(day, f.Order_Date, f.Ship_Date)) as Avg_Shipping_Days,
    -- Count of orders that took more than 5 days (Late Shipping)
    SUM(CASE WHEN DATEDIFF(day, f.Order_Date, f.Ship_Date) > 5 THEN 1 ELSE 0 END) as Late_Orders_Count,
    COUNT(f.Order_Id) as Total_Orders
FROM Fact_Sales f
JOIN Dim_Region r ON f.Region_ID = r.Region_ID
GROUP BY f.Ship_Mode, r.Region;

---create view 5 (Product_Profitability)
CREATE VIEW vw_Product_Profitability AS
SELECT 
    p.Product_Name,
    p.Category,
    SUM(f.Sales) as Total_Sales,
    SUM(f.Profit) as Total_Profit,
    -- Business Logic in SQL
    CASE 
        WHEN SUM(f.Profit) < 0 THEN 'Loss Maker'
        WHEN SUM(f.Profit) > 0 AND (SUM(f.Profit)/SUM(f.Sales)) > 0.2 THEN 'High Margin'
        ELSE 'Average Margin'
    END as Profit_Status
FROM Fact_Sales f
JOIN Dim_Product p ON f.Product_Id = p.Product_Id
GROUP BY p.Product_Name, p.Category;

SELECT * FROM vw_Product_Profitability

--create stored procedure to get sales by date range
CREATE PROCEDURE sp_GetSalesByDateRange
    @StartDate DATE,
    @EndDate DATE
    AS
    BEGIN
    SELECT 
        p.Category,
        SUM(f.Sales) as Total_Sales,
        SUM(f.Profit) as Total_Profit
    FROM Fact_Sales f
    JOIN Dim_Product p ON f.Product_Id = p.Product_Id
    WHERE f.Order_Date BETWEEN @StartDate AND @EndDate
    GROUP BY p.Category
    ORDER BY Total_Sales DESC;
    END;
-- Execute the stored procedure for a specific date range
EXEC sp_GetSalesByDateRange '2014-01-01', '2014-12-31';

--create another store procedure to get top N products by sales
CREATE PROCEDURE sp_GetTopNProductsBySales
    @TopN INT
    as
    BEGIN
    SELECT TOP(@TopN) 
            p.Product_Name,
            SUM(f.Sales) as Total_Sales
        FROM Fact_Sales f
        JOIN Dim_Product p ON f.Product_Id = p.Product_Id
        GROUP BY p.Product_Name
        ORDER BY Total_Sales DESC;
    END;
    EXEC sp_GetTopNProductsBySales 2;

    -- create stored procedure to get sales and profit by customer segment
   CREATE PROCEDURE SP_GetCustomerSegmentSales
    @Segment VARCHAR(50)
    AS
    BEGIN
    SELECT 
        c.Segment,
        SUM(f.Sales) as Total_Sales,
        SUM(f.Profit) as Total_Profit
    FROM Fact_Sales f
    JOIN Dim_Customer c ON f.Customer_Id = c.Customer_Id
    WHERE c.Segment = @Segment
    GROUP BY c.Segment;
    END;
    EXEC SP_GetCustomerSegmentSales 'Consumer';
    
    -- create stored procedure to get customer purchase history
    Create PROCEDURE SP_GetCustomerHistory
     @CustomerID VARCHAR(100)
     AS 
     BEGIN 
       SELECT
        C.Customer_Name,
        P.Product_Name,
        F.Order_Date,
        F.Sales,
        F.Profit
       FROM Fact_Sales F
       JOIN Dim_Customer C ON F.Customer_Id = C.Customer_Id
       JOIN Dim_Product P ON F.Product_Id = P.Product_Id
       WHERE C.Customer_Id = @CustomerID
       ORDER BY F.Order_Date DESC;
     END ;
     EXEC SP_GetCustomerHistory 'DV-13045';
   
   --create stored procedure to get loss making products based on a loss threshold
   CREATE PROCEDURE SP_GetLossMakingProducts
     @LossThreshold DECIMAL(10,2)
     AS
     BEGIN
        SELECT
          P.Product_Name,
          P.Category,
          SUM(F.Sales) AS Total_Sales,
          sum(F.Profit) AS Total_Loss,
          Count(F.Order_Id) as Total_Orders
        FROM Fact_Sales F
        JOIN Dim_Product P ON F.Product_Id = P.Product_Id
        Group by P.Product_Name,P.Category
        Having SUM(F.Profit) < @LossThreshold
        order by Total_Loss ASC;
     END;
     EXEC SP_GetLossMakingProducts -5000;

     --create stored procedure to analyze category performance for a given year and region
     Create Procedure Sp_GetCategoryPerformace
      @Year INT,
      @Region_Name VARCHAR(50)
      AS
      BEGIN
        SELECT 
          p.Category,
          p.Sub_Category,
          SUM(f.Sales) as Total_Revenue,
          SUM(f.Quantity) as Total_Units_Sold,
          CAST((SUM(f.Profit) / SUM(f.Sales)) * 100 AS DECIMAL(10,2)) as Profit_Margin_Percent
        From Fact_Sales f
        join Dim_Product p on f.Product_Id = p.Product_Id
        join Dim_Region r on  f.Region_Id = r.Region_Id
        WHERE YEAR(f.Order_Date) = @Year AND r.Region = @Region_Name
        Group by p.Category,p.Sub_Category
        Order by Total_Revenue DESC
      END;
      EXEC Sp_GetCategoryPerformace 2016, 'West';