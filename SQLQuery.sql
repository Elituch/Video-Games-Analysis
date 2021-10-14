
/*
1.	Games with multiple consoles:
a)	How many games have been released with 3 or more Platforms? 1283
b)	What is the ratio of games that have exactly 3 Platforms 
*/


SELECT Name, COUNT(Platform) AS 'Number of platforms'
FROM Sales_and_Ratings
GROUP BY name
HAVING COUNT(Platform) >= 3

/* There are 1283 games that have been released with 3 ot more platforms */

DECLARE @3andMore decimal(10,1)

SELECT @3andMore =COUNT(*)
FROM (SELECT name
      FROM Sales_and_Ratings
      GROUP BY name
      HAVING COUNT(Platform) >= 3) AS count3andmore


PRINT @3andMore


SELECT CAST((COUNT(*) / @3andMore) AS decimal(10,1)) AS 'Ratio 3 - 3 and bigger'
FROM (SELECT Name , COUNT(Platform) AS 'Exactly 3'
               FROM Sales_and_Ratings
			   GROUP BY Name
			   HAVING COUNT(Platform) =3
			   ) AS Exactthree

/* The ratio is 0.6 */
/*

3.	Analyze and find which year per Genre was the year in which the most units were sold. 
In what year was the number of Geners at their peak the highest?
*/

SELECT *
FROM (SELECT Genre , Year_of_Release , SUM(NA_Sales +EU_Sales
+JP_Sales +Other_Sales) AS 'Total sales' ,
ROW_NUMBER () OVER (PARTITION BY Genre ORDER BY  SUM(NA_Sales +EU_Sales
+JP_Sales +Other_Sales) DESC) AS 'RANK_of_sales'
FROM Sales_and_Ratings
GROUP BY Genre , Year_of_Release) AS year_most_units 
WHERE RANK_of_sales =1



SELECT Year_of_Release , COUNT(Genre) 'Number of peaks'
FROM (SELECT Genre , Year_of_Release , SUM(NA_Sales +EU_Sales
+JP_Sales +Other_Sales) AS 'Total sales' ,
ROW_NUMBER () OVER (PARTITION BY Genre ORDER BY  SUM(NA_Sales +EU_Sales
+JP_Sales +Other_Sales) DESC) AS 'RANK_of_sales'
FROM Sales_and_Ratings
GROUP BY Genre , Year_of_Release) AS year_most_units 
WHERE RANK_of_sales =1
GROUP BY Year_of_Release
ORDER BY 2 DESC

/* The year with the  the number of Geners at their peak the highest is 2008 there are 3 genres */

/*

3.	Compute per Rating the Weighted Average taking the Critic_count as the weight), the normal Average, and the Mode of critic_score, all rounded to 1 decimal point.
 Which two Ratings have the same value for all three measures? Did you idetnfiy the source for this reason? 
*/





CREATE VIEW VW_AvgForEachRating1
AS
(SELECT Rating ,CAST(AVG(Critic_Score) AS decimal(10,1)) AS 'Regular avg'
 , CAST(SUM(Critic_Count*Critic_Score)/ SUM(Critic_Count) AS decimal(10,1)) AS 'Weighted Average'
FROM Sales_and_Ratings
GROUP BY Rating)


CREATE VIEW VW_ModesOfEachRating1
AS
(SELECT Rating , CAST(AVG(Critic_Score) AS decimal(10,1)) AS 'AVGmode' 
FROM(SELECT Rating , Critic_Score, 
DENSE_RANK() OVER (PARTITION BY Rating ORDER BY RankforMODE DESC) AS 'MODESbeforeAVG'
FROM (SELECT Rating , Critic_Score, 
DENSE_RANK() OVER (PARTITION BY Rating ORDER BY COUNT(Critic_Score)) AS 'RankforMODE'
FROM Sales_and_Ratings
GROUP BY Rating , Critic_Score) AS findModes) AS ModesforRating
WHERE MODESbeforeAVG =1
GROUP BY Rating)


SELECT AVGS.Rating , AVGS.[Regular avg] , AVGS.[Weighted Average] , MODES.AVGmode
FROM VW_AvgForEachRating1 AVGS JOIN 
VW_ModesOfEachRating1 MODES
ON MODES.Rating = AVGS.Rating

/* The ratings that has the same values for all three measures , are AO and KA
The reason is that both ratings have only one row with values that are not NULL */

/*
4.	Data Scaffolding – Provide a query that details at Genere, Platform, and Year_of_Release the global units sold.
 The catch – Some of the combinations in between does not exist (such as for Platform '2600' for Action Genere, 
 the years 1984-1986 lack in the data – use the query below to validate that).
 Your task is to display the measure for all possible combinations that can be between the fields 
 (excluding NULLs) and bestowing zero when it's NULL for the measure.
 */

 WITH cteGenre
AS (SELECT DISTINCT  Genre
    FROM Sales_and_Ratings
	WHERE Genre IS NOT NULL),

ctePlatform 
AS (SELECT DISTINCT Platform
    FROM Sales_and_Ratings
	WHERE Platform IS NOT NULL),

cteYear 
AS (SELECT DISTINCT Year_of_Release
    FROM Sales_and_Ratings
	WHERE Year_of_Release IS NOT NULL),

cteGlobal_sales
AS (SELECT Genre , Platform , Year_of_Release, SUM(Global_Sales) AS 'sum of sales'
    FROM Sales_and_Ratings
	GROUP BY Genre , Platform , Year_of_Release)

SELECT AllPossibleCombi.Genre, AllPossibleCombi.Platform , AllPossibleCombi.Year_of_Release ,
ISNULL(GlSa.[sum of sales] , 0) AS 'Global unit sales'
FROM(SELECT G.Genre , P.Platform , Y.Year_of_Release 
FROM cteGenre G
     CROSS JOIN ctePlatform  P
	 CROSS JOIN cteYear Y
	 GROUP BY G.Genre , P.Platform , Y.Year_of_Release) AS AllPossibleCombi
	 LEFT JOIN cteGlobal_sales GlSa
	 ON AllPossibleCombi.Genre = GlSa.Genre AND AllPossibleCombi.Platform = GlSa.Platform
	 AND AllPossibleCombi.Year_of_Release = GlSa.Year_of_Release

/*

5.	Analyze per Platform the year with the greatest YoY % (Year of Year relative growth equation > (a – b) / b), in terms of Global_Sales. 
Which of the following had recorded the most siginifiacnt growth rate within the dataset, and on which year? Circle the answer and write the year next to the icon.
*/


/* When yoy is '0' means the data about the salses of the previous year in that
record, is missing */ 

SELECT Platform , Year_of_Release , ISNULL(Yoy , 0) AS Yoy
FROM(SELECT * ,
ROW_NUMBER () OVER ( PARTITION BY Platform ORDER BY Yoy DESC) AS 'Rank_Of_Yoys'
FROM (SELECT * , CAST(((Current_year_sales -  Last_year_sales) /  Last_year_sales) AS decimal (6,2)) AS Yoy
FROM (SELECT SA1.Platformtemp AS Platform , SA1.Year_of_Release_temp AS Year_of_Release , SA1.Global_Sales_temp AS Current_year_sales,
SA2.Global_Sales_temp  AS Last_year_sales
FROM ##tempfor6 SA1
LEFT JOIN ##tempfor7 SA2
ON SA1.Platformtemp = SA2.Platformtemp AND SA2.Year_of_Release_temp = SA1.Year_of_Release_temp-1)
AS  exclude_nulls) AS allyoys) AS best_yoys
WHERE Rank_Of_Yoys = 1
ORDER BY 1


SELECT Platform , Year_of_Release , ISNULL(Yoy , 0) AS Yoy
FROM(SELECT * ,
ROW_NUMBER () OVER ( PARTITION BY Platform ORDER BY Yoy DESC) AS 'Rank_Of_Yoys'
FROM (SELECT * , CAST(((Current_year_sales -  Last_year_sales) /  Last_year_sales) AS decimal (6,2)) AS Yoy
FROM (SELECT SA1.Platformtemp AS Platform , SA1.Year_of_Release_temp AS Year_of_Release , SA1.Global_Sales_temp AS Current_year_sales,
SA2.Global_Sales_temp  AS Last_year_sales
FROM ##tempfor6 SA1
LEFT JOIN ##tempfor7 SA2
ON SA1.Platformtemp = SA2.Platformtemp AND SA2.Year_of_Release_temp = SA1.Year_of_Release_temp-1)
AS  exclude_nulls) AS allyoys) AS best_yoys
WHERE Rank_Of_Yoys = 1 AND (Platform LIKE 'X360' OR  Platform LIKE 'GBA' OR  Platform LIKE 'PS4')
ORDER BY 1

/* GBA , 2001 , 1026 */

