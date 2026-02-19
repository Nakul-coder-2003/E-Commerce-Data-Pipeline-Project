# 🛒 End-to-End E-Commerce Analytics & ETL Pipeline

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=power-bi&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)

## 📌 Project Overview
This project is a complete end-to-end Data Analytics solution designed to analyze e-commerce sales data. The goal of this project is to build a robust data pipeline that extracts raw data, transforms it into a structured database, and visualizes key business metrics to help stakeholders make data-driven decisions.
> **⚠️ Dataset Note:** Due to GitHub's file size limits, only a sample dataset of 100 rows is uploaded in this repository to demonstrate the data structure and ETL pipeline functionality. The complete dataset was sourced from Kaggle and processed locally.

## 🏗️ Data Architecture & Workflow
The project follows a standard Data Engineering & Analytics pipeline:
1. **Extract & Transform (Python):** Raw CSV data is ingested and cleaned using the `pandas` library. The flat file is normalized into a Star Schema.
2. **Load (SQL Server):** The normalized dataframes are loaded into MS SQL Server using `SQLAlchemy`.
3. **Data Modeling (SQL):** Primary and Foreign Key constraints are applied to create a robust relational model (1 Fact Table, 4 Dimension Tables).
4. **Business Logic (SQL):** SQL `VIEWS` and `STORED PROCEDURES` are created to handle heavy calculations like Year-over-Year (YoY) growth, Profit Margins, and Exception Reporting.
5. **Visualization (Power BI):** The SQL database is connected to Power BI via Import Mode. DAX measures are utilized for Time-Intelligence and dynamic RFM (Recency, Frequency, Monetary) Customer Segmentation.

## 🗄️ Database Schema (Star Schema)
The database is normalized into the following tables:
* **Fact Table:** `Fact_Sales` (Transactional data)
* **Dimension Tables:** `Dim_Customer`, `Dim_Product`, `Dim_Location`, `Dim_Region`

## 📊 Key Business Insights & Dashboards
The Power BI report is divided into three actionable pages:
1. **Executive Summary:** High-level KPIs (Total Sales, Profit Margin, YoY Growth) and geographical performance.
2. **Detailed Product Analysis:** Identification of Top 10 revenue-generating products and loss-making categories using conditional formatting.
3. **Customer Segmentation (RFM Analysis):** Categorized customers into **VIP**, **Loyal**, **At-Risk**, and **Lost** segments using DAX `SWITCH` logic to drive targeted marketing strategies.

---

### 📷 Dashboard Screenshots
*(Add your dashboard screenshots here by dragging and dropping the images into the GitHub editor)*

![Dashboard Page 1 - Executive Summary]
<img width="917" height="494" alt="page1" src="https://github.com/user-attachments/assets/da22fdec-86c4-4667-8d88-3221c36d5704" />

![Dashboard Page 2 - Details_Analysis]
<img width="926" height="493" alt="page2" src="https://github.com/user-attachments/assets/e58d8d44-0c78-45c7-a773-71859aab59e4" />

![Dashboard Page 3 - RFM Analysis]
<img width="934" height="518" alt="page4" src="https://github.com/user-attachments/assets/7d047509-00b2-40f6-b50d-9303d54caa7d" />

---

## 💻 Technical Implementation (Step-by-Step)

### Step 1: Python ETL Pipeline
* **Script:** `etl_pipeline.py`
* Handles missing values, date formatting, and data normalization.
* Automatically establishes an ODBC connection to SQL Server to push structured tables.

### Step 2: SQL Server Backend
* **Script:** `SQL_Queries_and_Views.sql`
* Applies PK/FK constraints.
* Creates Views: `vw_Master_Sales`, `vw_YoY_Growth`, `vw_RFM_Analysis`.
* Creates Stored Procedures for ad-hoc analysis (e.g., `sp_GetLossMakingProducts`).

### Step 3: Power BI Data Model
* Connects to SQL Server Views to ensure optimal dashboard performance.
* **Key DAX Formulas Used:** `CALCULATE`, `SAMEPERIODLASTYEAR`, `SWITCH`, `DIVIDE`, `ISBLANK`.

## 🚀 How to Run This Project
1. Clone this repository to your local machine.
2. Run the `etl_pipeline.py` script after updating your SQL Server credentials.
3. Open MS SQL Server Management Studio (SSMS) and execute the queries in `SQL_Queries_and_Views.sql`.
4. Open the `Ecommerce_Dashboard.pbix` file in Power BI Desktop and refresh the dataset.

## 👨‍💻 About Me
I am a Data Enthusiast with a strong foundation in Computer Applications, passionate about turning raw data into meaningful business stories using Python, SQL, and Power BI.
