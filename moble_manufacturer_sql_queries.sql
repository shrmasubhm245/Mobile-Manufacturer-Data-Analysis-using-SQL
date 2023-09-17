
--Q1. List all the states in which we have customers who have bought cellphones 
---from 2005 till today.

SELECT DISTINCT [State]
FROM DIM_LOCATION AS D
INNER JOIN FACT_TRANSACTIONS AS F
ON D.IDLocation = F.IDLocation
WHERE DATEPART(YEAR,[Date]) > 2005

--Q1--END

--Q2. . What state in the US is buying the most 'Samsung' cell phones?

WITH MAN_MODEL AS 
(
 SELECT MO.*,Manufacturer_Name
 FROM DIM_MODEL AS MO
 INNER JOIN DIM_MANUFACTURER AS MA
 ON MO.IDManufacturer = MA.IDManufacturer
 WHERE Manufacturer_Name = 'Samsung'
 )
 SELECT [State]
 FROM
 (
				SELECT TOP 1 [State], COUNT(Quantity) AS [Quantity]
				FROM MAN_MODEL AS A
				FULL OUTER JOIN FACT_TRANSACTIONS AS F
				ON A.IDModel = F.IDModel
				FULL OUTER JOIN DIM_LOCATION AS L
				ON L.IDLocation = F.IDLocation
				WHERE Country = 'US' AND Manufacturer_Name <> 'Null'
				GROUP BY [State]
				ORDER BY COUNT(Quantity) DESC
 ) AS X

--Q2--END

--Q3. Show the number of transactions for each model per zip code per state.      
	
 SELECT X.IDModel,Model_Name,ZipCode,[State],[No. of Transactions]
 FROM
 (
    SELECT ZipCode, [State],IDModel, COUNT (IDCustomer) AS [No. of Transactions]
    FROM DIM_LOCATION AS L
    FULL OUTER JOIN FACT_TRANSACTIONS AS T
    ON L.IDLocation = T.IDLocation
    GROUP BY ZipCode,[State],IDModel
) AS X 
LEFT JOIN  DIM_MODEL AS M
ON X.IDModel = M.IDModel

--Q3--END

--Q4 . Show the cheapest cellphone (Output should contain the price)

SELECT TOP 1 Model_Name, TotalPrice, Unit_price
FROM DIM_MODEL AS M
LEFT JOIN FACT_TRANSACTIONS AS F
ON F.IDModel = F.IDModel
ORDER BY TotalPrice ASC, Unit_price ASC

--Q4--END

--Q5. Find out the average price for each model in the top5 manufacturers in 
 ---terms of sales quantity and order by average price.

SELECT Model_Name,AVG(TotalPrice) AS [Average Price]
FROM DIM_MODEL AS D
LEFT JOIN FACT_TRANSACTIONS AS F
ON D.IDModel = F.IDModel
WHERE IDManufacturer IN 
				       (SELECT TOP 5  IDManufacturer
						FROM DIM_MODEL AS D
						LEFT JOIN FACT_TRANSACTIONS AS F
						ON D.IDModel = F.IDModel
						GROUP BY IDManufacturer
						ORDER BY COUNT(Quantity) DESC)
GROUP BY Model_Name
ORDER BY [Average Price] DESC

--Q5--END

--Q6. List the names of the customers and the average amount spent in 2009, 
---where the average is higher than 500

SELECT Customer_Name, AVG ( TotalPrice) AS [ Average Amount]
FROM DIM_CUSTOMER AS C
LEFT JOIN FACT_TRANSACTIONS AS F
ON C.IDCustomer = F.IDCustomer
WHERE  DATEPART(YEAR,[Date]) = 2009
GROUP BY Customer_Name
HAVING AVG ( TotalPrice) > 500

--Q6--END

--Q7. . List if there is any model that was in the top 5 in terms of quantity,
--- simultaneously in 2008, 2009 and 2010

WITH COMMON_MODEL AS 
(
				SELECT TOP 5  Model_Name,COUNT(Quantity) AS [Quantity]
				FROM DIM_MODEL AS D	
				LEFT JOIN FACT_TRANSACTIONS AS F
				ON D.IDModel = F.IDModel
				WHERE  DATEPART(YEAR,[Date]) = 2008
				GROUP BY Model_Name
				ORDER BY Quantity DESC 
				                              INTERSECT
				SELECT TOP 5 Model_Name,COUNT(Quantity) AS [Quantity]
				FROM DIM_MODEL AS D	
				LEFT JOIN FACT_TRANSACTIONS AS F
				ON D.IDModel = F.IDModel
				WHERE  DATEPART(YEAR,[Date]) = 2009
				GROUP BY Model_Name
				ORDER BY Quantity DESC
				                              INTERSECT
				SELECT  TOP 5 Model_Name,COUNT(Quantity) AS [Quantity]
				FROM DIM_MODEL AS D	
				LEFT JOIN FACT_TRANSACTIONS AS F
				ON D.IDModel = F.IDModel
				WHERE  DATEPART(YEAR,[Date]) = 2010
				GROUP BY Model_Name
				ORDER BY Quantity DESC
)
SELECT Model_Name, Quantity
FROM COMMON_MODEL

/* There was not a single cellphone model which was in TOP 5 in terms of quantity sold,
   simuntaneously in the year 2008,2009,2010.*/

--Q7--END

--Q8. . Show the manufacturer with the 2nd top sales in the year of 2009 and the
---manufacturer with the 2nd top sales in the year of 2010.

WITH MANU_MODEL AS
(
		SELECT MO.*,Manufacturer_Name
		FROM DIM_MANUFACTURER AS MA
		LEFT JOIN DIM_MODEL AS MO
		ON MA.IDManufacturer = MO.IDManufacturer
)
SELECT [Year], Manufacturer_Name
FROM 
(
		SELECT Manufacturer_Name,SUM(TotalPrice) AS Sales, DATEPART(YEAR,[Date]) AS [Year],
		RANK () OVER (ORDER BY SUM(TotalPrice) DESC) AS RANKS
		FROM MANU_MODEL AS X
		LEFT JOIN FACT_TRANSACTIONS AS F
		ON F.IDModel = X.IDModel
		WHERE  DATEPART(YEAR,[Date]) = 2009 
		GROUP BY Manufacturer_Name,DATEPART(YEAR,[Date])
) AS Y
WHERE RANKS = 2 
                                          UNION 
SELECT [Year], Manufacturer_Name
FROM 
(
		SELECT Manufacturer_Name,SUM(TotalPrice) AS Sales, DATEPART(YEAR,[Date]) AS [Year],
		RANK () OVER (ORDER BY SUM(TotalPrice) DESC) AS RANKS
		FROM MANU_MODEL AS X
		LEFT JOIN FACT_TRANSACTIONS AS F
		ON F.IDModel = X.IDModel
		WHERE  DATEPART(YEAR,[Date]) = 2010
		GROUP BY Manufacturer_Name,DATEPART(YEAR,[Date])
) AS Y
WHERE RANKS = 2

--Q8--END

--Q9. Show the manufacturers that sold cellphones in 2010 but did not in 2009.
	
WITH MANU_MODEL AS
(
		SELECT MO.*,Manufacturer_Name
		FROM DIM_MANUFACTURER AS MA
		LEFT JOIN DIM_MODEL AS MO
		ON MA.IDManufacturer = MO.IDManufacturer
)
SELECT DISTINCT Manufacturer_Name
FROM MANU_MODEL AS X
LEFT JOIN FACT_TRANSACTIONS AS F
ON X.IDModel = F.IDModel
WHERE DATEPART(YEAR,[Date]) = 2010
                                    EXCEPT
SELECT DISTINCT Manufacturer_Name
FROM MANU_MODEL AS X
LEFT JOIN FACT_TRANSACTIONS AS F
ON X.IDModel = F.IDModel
WHERE DATEPART(YEAR,[Date]) = 2009

--Q9--END

--Q10. Find top 100 customers and their average spend, average quantity by each
--- year. Also find the percentage of change in their spend.

SELECT IDCustomer,Customer_Name,YEARS,Average_Quantity,Average_Spend,
LAG(Average_Spend ,1,NULL) OVER ( PARTITION BY Customer_Name
			ORDER BY YEARS)  AS PREV_SPEND,
(((LAG(Average_Spend ,1,NULL) OVER ( PARTITION BY Customer_Name
			ORDER BY YEARS))-Average_Spend) / Average_Spend) * 100 AS Percentage_Change
FROM
(
			SELECT C.IDCustomer, Customer_Name,DATEPART(YEAR,[Date]) AS YEARS,
			AVG(TotalPrice) AS Average_Spend, AVG(Quantity) AS Average_Quantity,
			RANK () OVER (PARTITION BY DATEPART(YEAR,[Date]) ORDER BY AVG(TotalPrice) DESC,
			AVG(Quantity) DESC) AS RANKS
			FROM DIM_CUSTOMER AS C
			LEFT JOIN FACT_TRANSACTIONS AS F
			ON C.IDCustomer = F.IDCustomer
			GROUP BY C.IDCustomer, Customer_Name,DATEPART(YEAR,[Date])
		
) AS X 
WHERE RANKS  BETWEEN 1 AND 10
ORDER BY  Customer_Name ASC

--Q10--END
	