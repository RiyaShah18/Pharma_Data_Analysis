-- Removing rows with negative sales amount
DELETE FROM pharmasales
WHERE sales<0;


--1) Year-over-year growth in sales 
WITH SalesByYear AS(
     SELECT Year, ROUND(SUM(sales),0) AS TotalSales
	 FROM PharmaSales
	 GROUP BY year 
),
SalesGrowth AS(
	 SELECT Year, TotalSales, LAG(TotalSales)OVER(ORDER BY Year) AS PreviousYearSales
	 FROM SalesByYear
)
SELECT Year, TotalSales, PreviousYearSales, 
       CASE 
	       WHEN PreviousYearSales IS NULL THEN NULL
		   ELSE (TotalSales - PreviousYearSales)*100/(PreviousYearSales)
	   END AS YearOverYearGrowth
FROM SalesGrowth;


--2) Top 5 cities with the highest sales
SELECT TOP 5 city, SUM(sales) AS total_sales
FROM pharmasales
GROUP BY city
ORDER BY SUM(sales) DESC;


--3) Top 10 products by sales revenue 
SELECT TOP 10 [Product Name] AS product, ROUND(SUM(sales),0) AS total_sales
FROM pharmasales
GROUP BY [Product Name]
ORDER BY total_sales DESC


--4) Product classes in order of their total sales
SELECT [product class], ROUND(SUM(sales),0) as total_revenue 
FROM PharmaSales
GROUP BY [Product Class]
ORDER BY total_revenue DESC;


--5) Percentage sales distribution across different channels (Hospital vs. Pharmacy) 
WITH percentsales AS (
    SELECT Channel, sales, ROUND(SUM(sales) OVER (), 0) AS total_sales 
    FROM pharmasales
)
SELECT Channel, ROUND((ROUND(SUM(sales), 0) * 100 / MAX(total_sales)),2) AS percent_channel_sales
FROM percentsales
GROUP BY Channel
ORDER BY percent_channel_sales DESC;


--6) Distribution of sales across different sub-channels for each channel
WITH channelsales AS (
    SELECT Channel, [sub-channel], sales, ROUND(SUM(sales) OVER (PARTITION BY channel), 0) AS channel_sales 
    FROM pharmasales
)
SELECT Channel, [sub-channel], ROUND((ROUND(SUM(sales), 0) * 100 / MAX(channel_sales)),2) AS subchannel_percent
FROM channelsales
GROUP BY Channel, [sub-channel]
ORDER BY Channel, subchannel_percent DESC;



--7) Product class which is most commonly purchased by a specific channel
WITH mostcommon AS(
	 SELECT Channel, [product class], COUNT(Quantity) AS count
	 FROM pharmasales
	 GROUP BY Channel, [product class]
)
SELECT Channel, [product class]
FROM mostcommon
WHERE count IN (SELECT MAX(count)
			   FROM mostcommon
			   GROUP BY Channel)


--8) Average order size (quantity) for different customer groups
SELECT Channel, [Sub-Channel], ROUND(AVG(Quantity),0) AS avg_quantity
FROM pharmasales
GROUP BY Channel, [Sub-channel]
ORDER BY Channel, avg_quantity DESC,



--9) Total revenue generated by each sales team over the 4 years
SELECT [sales team], ROUND(SUM(sales),0) as total_revenue
FROM PharmaSales
GROUP BY [sales team]
ORDER BY total_revenue DESC;



--10) Growth in Manager's performance year-over-year
WITH SalesByYear AS(
     SELECT Manager, Year, ROUND(SUM(sales),0) AS TotalSales
	 FROM PharmaSales
	 GROUP BY Manager, year
),
SalesGrowth AS(
	 SELECT Manager, Year, TotalSales, LAG(TotalSales)OVER(PARTITION BY Manager ORDER BY Year) AS PreviousYearSales
	 FROM SalesByYear
)
SELECT Manager, Year, TotalSales, PreviousYearSales, 
       CASE 
	       WHEN PreviousYearSales IS NULL THEN NULL
		   ELSE (TotalSales - PreviousYearSales)*100/(PreviousYearSales)
	   END AS ManagerGrowth
FROM SalesGrowth
ORDER BY Manager, year;


--11) Top 5-performing sales reps
SELECT TOP 5[Name of Sales Rep], ROUND(SUM(sales),0) AS total_sales
FROM pharmasales
GROUP BY [Name of Sales Rep]
ORDER BY total_sales DESC ;


--12) Find the top 5 customers contributing the most to sales for each year
WITH Rankedsales AS(
     SELECT [Customer name], Year, ROUND(SUM(sales),0) AS total_sales, RANK()OVER(PARTITION BY Year ORDER BY ROUND(SUM(sales),0) DESC) AS Rank
     FROM pharmasales
     GROUP BY [Customer name], Year
)
SELECT * 
FROM Rankedsales
WHERE Rank<=5;


--13) Distributors with the highest sales contribution for each year and their contribution percentage
WITH annualsales AS(
     SELECT year, ROUND(SUM(sales),0) as annual_sale
     FROM pharmasales
     GROUP BY year
),
distributorsales AS(
     SELECT distributor, year, ROUND(SUM(sales),0) AS d_annual_sale
     FROM pharmasales 
     GROUP BY distributor, year
)
SELECT a.year, b.distributor, (d_annual_sale*100/annual_sale) AS percent_contri
FROM annualsales a JOIN distributorsales b
ON a.year = b.year
WHERE (d_annual_sale*100/annual_sale) In (SELECT MAX(d_annual_sale*100/annual_sale) 
	                                      FROM annualsales a JOIN distributorsales b
	                                      ON a.year = b.year
										  GROUP BY a.year)
ORDER BY a.year


--14) The month with the lowest sales in each year
WITH MonthlySales AS(
     SELECT Year, Month, SUM(sales) AS totalsales
     FROM PharmaSales
     GROUP BY Year, Month
),
LowestSales AS (
     SELECT Year, MIN(totalsales) AS LowestMonthlySale
	 FROM MonthlySales
	 GROUP BY year
)
SELECT a.Year, Month AS LowestSaleMonth , totalsales AS SalesAmount
FROM MonthlySales a JOIN LowestSales b
ON a.Year = b.year
WHERE a.totalsales=b.LowestMonthlySale
ORDER BY a.year