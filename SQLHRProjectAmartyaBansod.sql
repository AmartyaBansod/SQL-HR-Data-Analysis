-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SQL PROJECT ----

/* Introduction 
Following is Data Analysis project on HR data for a certain company done using SQL. Dataset was recieved as CSV file and then imported to MYSQL workbench.
 
The Problem statements are as follows -
1: "Identify Factors Influencing Employee Attrition"
Objective: Determine the factors that contribute to employee attrition within the company and provide insights to reduce attrition rates.

2. Problem Statement 2: "Optimize Employee Training Programs"
Objective: Analyse the effectiveness of training programs and recommend improvements to enhance employee skills and performance.

Dataset contains employee information, performance metrics, and other HR-related data. Here is an example of the dataset structure:

- Employee_ID: Unique identifier for each employee.
- Employee_Name: Name of the employee.
- Age: Age of the employee.
- Gender: Gender of the employee.
- Department: The department in which the employee works (e.g., Sales, Marketing, IT).
- Position: Employee's job position or title.
- Years_of_Service: The number of years the employee has been with the company.
- Salary: Employee's annual salary.
- Performance_Rating: A rating indicating the employee's performance (e.g., on a scale of 1 to 5).
- Work_Hours: The average number of hours worked per week.
- Attrition: Whether the employee has left the company (Yes/No).
- Promotion: Whether the employee has been promoted (Yes/No).
- Training_Hours: The number of training hours the employee has completed.
- Satisfaction_Score: Employee's satisfaction score (e.g., on a scale of 1 to 5).
- Last_Promotion_Date: Date of the employee's last promotion.
*/ 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- We first start with some EDA and Data Cleaning
USE sqldatatodestiney; 
DESC hr_data2;
SELECT * FROM hr_data2;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Doing EDA, checking if all text fields (Gender, Department, Position, Attrition, Promotion) have consistent data.
---------------------------------------------------------------------------------------------------------------------------------
SELECT Gender, COUNT(*) FROM hr_data2 GROUP BY Gender;
-- It is seen that there are 4 different values (Male, Female, M, F). We can change these to 2 values M and F
---------------------------------------------------------------------------------------------------------------------------------
SELECT Department, COUNT(*) FROM hr_data2 GROUP BY Department;
-- All unique distinct values
---------------------------------------------------------------------------------------------------------------------------------
SELECT Position, COUNT(*) FROM hr_data2 GROUP BY Position;
-- 2 values can be changed (DataScientist and Marketinganalyst)
---------------------------------------------------------------------------------------------------------------------------------
SELECT Attrition, COUNT(*) FROM hr_data2 GROUP BY Attrition;
-- All unique distinct values
---------------------------------------------------------------------------------------------------------------------------------
SELECT Promotion, COUNT(*) FROM hr_data2 GROUP BY Promotion;
-- All unique distinct values
---------------------------------------------------------------------------------------------------------------------------------
-- Checking the fields/columns with Numeric Continuous data types

SELECT MIN(Age), MAX(Age), AVG(Age) FROM hr_data2;
SELECT MIN(YearsOfService), MAX(YearsOfService), AVG(YearsOfService) FROM hr_data2;
SELECT MIN(Salary), MAX(Salary), AVG(Salary) FROM hr_data2;
SELECT MIN(WorkHours), MAX(WorkHours), AVG(WorkHours) FROM hr_data2;
SELECT MIN(TrainingHours), MAX(TrainingHours), AVG(TrainingHours) FROM hr_data2;

---------------------------------------------------------------------------------------------------------------------------------
-- Checking the fields/columns with Numeric Categorical data types

SELECT DISTINCT(PerformanceRating) FROM hr_data2;
SELECT DISTINCT(SatisfactionScore) FROM hr_data2;

-- To make some analysis, we can add buckets to the Salary and Age columns.
-- We can also change the LastPromotionDate from text to Date.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- We implement the above changes and the changes in the text columns in a new table

DROP TABLE IF EXISTS hr_database;

CREATE TABLE hr_database AS 
SELECT
	EmployeeID,
    Age,
    CASE
		WHEN Age <= 30 THEN '<= 30 years'
        ELSE '> 30 years'
        END AS AgeGroup,
	REPLACE(REPLACE(GENDER, 'Female', 'F'), 'Male', 'M') AS Gender,
    Department,
	REPLACE(REPLACE(Position, 'DataScientist', 'Data Scientist'), 'Marketinganalyst', 'Marketing Analyst') AS Position,
    YearsOfService,
    Salary,
    CASE 
		WHEN Salary >= 90000 THEN '90K - 100K'
		WHEN Salary >= 80000 THEN '80K - 90K'
        WHEN Salary >= 70000 THEN '70K - 80K'
        WHEN Salary >= 60000 THEN '60K - 70K'
        ELSE '50K - 60K'
        END AS SalaryBucket,
        PerformanceRating,
        WorkHours,
        Attrition,
        Promotion,
        TrainingHours,
        SatisfactionScore,
        LastPromotionDate,
        CASE 
			WHEN POSITION('-' IN LastPromotionDate) = 5 THEN STR_TO_DATE(LastPromotionDate, '%Y-%m-%d')	
            WHEN POSITION('-' IN LastPromotionDate) = 3 THEN DATE_FORMAT(STR_TO_DATE(LastPromotionDate, '%d-%m-%Y'),'%Y-%m-%d')
		END AS DateLastPromotion 
FROM hr_data2;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Now Some Analysis of the cleaned data
-- Problem Statement 1: "Identify Factors Influencing Employee Attrition"
-- 1) Stats
SELECT 
    COUNT(*) AS Total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND((SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) / COUNT(*))*100,2) AS Attrition_Count,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS Total_Active_employees,
    ROUND(AVG(Age),0) AS AvgAge,
    ROUND(AVG(YearsOfService),0) AS AvgYearsOfService,
    ROUND(AVG(Salary),0) AS AvgSalary,
    ROUND(AVG(SatisfactionScore),0) AS AvgSatisfactionScore,
    ROUND(AVG(WorkHours),0) AS AvgWorkHours,
    ROUND(AVG(TrainingHours),0) AS AvgTrainingHours
FROM hr_database
WHERE Attrition = 'Yes';

/*
For the complete company, the stats are as follows - 
Attrition rate is 33.75%.
Avg Age is 31 years
Avg Years of Service is 5 years
Avg Salary is ~67K
Avg Satisfaction Score is 4
Avg Work Hours is 41

--Insight
Avg Working Hours for people who left the company was higher than the total average 
as well folks who are still working in the company.

Less training was provided compared to the average that is why they left.
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Let us check how few attributes are related to or contribute to attrition 
---------------------------------------------------------------------------------------------------------------------------------
-- Age and Age Groups 
WITH AgeTab AS (
SELECT AgeGroup, COUNT(*) AS TotalAgeAttri
FROM hr_database
WHERE Attrition = 'Yes'
GROUP BY AgeGroup)

SELECT hr.AgeGroup, att.TotalAgeAttri, COUNT(*) AS TotalEmp, ROUND(att.TotalAgeAttri*100/COUNT(*), 2) AS AgeAttrPercent
FROM hr_database AS hr 
LEFT JOIN AgeTab AS att
ON hr.AgeGroup = att.AgeGroup
GROUP BY AgeGroup ,TotalAgeAttri
ORDER BY AgeAttrPercent;

-- Number of People leaving and having age > 30 have attrition rate greater than that of the company avg.

---------------------------------------------------------------------------------------------------------------------------------
-- Gender distribution
SELECT Gender,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Yes,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS Attrition_No
FROM hr_database
GROUP BY Gender;

-- Based on gender alone, there is no indication that gender and attrition are related.

---------------------------------------------------------------------------------------------------------------------------------
-- DEPARTMENT
WITH DeptTab AS (
SELECT Department, COUNT(*) AS TotalDeptAttri
FROM hr_database
WHERE Attrition = 'Yes'
GROUP BY Department)

SELECT hr.Department, dt.TotalDeptAttri, COUNT(*) AS TotalEmp, ROUND(dt.TotalDeptAttri*100/COUNT(*), 2) AS DeptAttrPercent
FROM hr_database AS hr 
LEFT JOIN DeptTab AS dt
ON hr.Department = dt.Department
GROUP BY Department ,TotalDeptAttri
ORDER BY DeptAttrPercent;
	   
-- It is seen that Finance dept has the max attrition rate and is followed by IT and Marketing depts

---------------------------------------------------------------------------------------------------------------------------------
-- POSTION 
WITH PosTab AS (
SELECT Position, COUNT(*) AS TotalPosAttri
FROM hr_database
WHERE Attrition = 'Yes'
GROUP BY Position)

SELECT hr.Position, pt.TotalPosAttri, COUNT(*) AS TotalEmpPerPos, ROUND(pt.TotalPosAttri*100/COUNT(*), 2) AS PosAttrPercent
FROM hr_database AS hr 
LEFT JOIN PosTab AS pt
ON hr.Position = pt.Position
GROUP BY Position ,TotalPosAttri
ORDER BY PosAttrPercent;

-- It is seen that managerial posts have the highest attrition rate. 85% Financial Managers have left the company, while 55% of marketing managers have left the company.

---------------------------------------------------------------------------------------------------------------------------------
-- Years of Service
WITH YoS AS(SELECT YearsOfService, COUNT(*) AS TotalEmpperYos,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Yes,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS Attrition_No
FROM hr_database
GROUP BY YearsOfService)

SELECT YearsOfService,Attrition_Yes, TotalEmpperYos,ROUND(Attrition_Yes*100/TotalEmpperYos, 2) AS YoSAttrPercent 
FROM YoS
ORDER BY YoSAttrPercent; 

/* 
There is a high attrition rate at 2 years work ex, which comes down in the 3rd and the following years where it remains below average. 
This trend is broken after year 6, after which there is 50% attrition rate for years 7,8,9,10. 
People with 11 or more years or experience are only 2 and have not left the company. 
*/
---------------------------------------------------------------------------------------------------------------------------------
-- Salary and Salary Bucket
WITH SalTab AS (
SELECT SalaryBucket, COUNT(*) AS TotalSalAttri
FROM hr_database
WHERE Attrition = 'Yes'
GROUP BY SalaryBucket)

SELECT hr.SalaryBucket, st.TotalSalAttri, COUNT(*) AS TotalSalEmp, ROUND(st.TotalSalAttri*100/COUNT(*), 2) AS SalAttrPercent
FROM hr_database AS hr 
LEFT JOIN SalTab AS st
ON hr.SalaryBucket = st.SalaryBucket
GROUP BY SalaryBucket ,TotalSalAttri
ORDER BY SalAttrPercent;

-- While most of the salary buckets have attrition rate near to the company avg, the attrition rate of employees with the 90k-100k salary range is 85%.

---------------------------------------------------------------------------------------------------------------------------------
-- Performance Rating 
WITH PerfRate AS(SELECT PerformanceRating, COUNT(*) AS TotalEmpPerPerfRate,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Yes_Perf,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS Attrition_No_Perf
FROM hr_database
GROUP BY PerformanceRating)

SELECT PerformanceRating, Attrition_Yes_Perf, TotalEmpPerPerfRate,ROUND(Attrition_Yes_Perf*100/TotalEmpPerPerfRate, 2) AS PerfAttrPercent 
FROM PerfRate
ORDER BY PerfAttrPercent; 

-- Above avg attrition rate for Performance rating of 4.

---------------------------------------------------------------------------------------------------------------------------------
-- WorkHours
WITH WorkHrs AS(SELECT WorkHours, COUNT(*) AS TotalEmpWorkHrs,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Yes_WrkHrs,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS Attrition_No_WrkHrs
FROM hr_database
GROUP BY WorkHours)

SELECT WorkHours,Attrition_Yes_WrkHrs, TotalEmpWorkHrs,ROUND(Attrition_Yes_WrkHrs*100/TotalEmpWorkHrs, 2) AS WrkHrsAttrPercent 
FROM WorkHrs
ORDER BY WrkHrsAttrPercent; 

/*
Lower Working Hours have lower or nil attrition rate. 
Majority of attrition is contributed from employees who have Work hours more the company average. 
*/
---------------------------------------------------------------------------------------------------------------------------------
-- Promotion
WITH PromTab AS(SELECT Promotion, COUNT(*) AS TotalEmpProm,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Yes_Prom,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS Attrition_No_Prom
FROM hr_database
GROUP BY Promotion)

SELECT Promotion, Attrition_Yes_Prom, TotalEmpProm, ROUND(Attrition_Yes_Prom*100/TotalEmpProm, 2) AS PromAttrPercent 
FROM PromTab
ORDER BY PromAttrPercent; 

-- More than 80% of people leaving had not received a promotion during their employment. 
-- But, attrition rate for both - employees with promotion and those with no promotion have average of around the company average.  

---------------------------------------------------------------------------------------------------------------------------------
-- Training Hours 
WITH TrainHrs AS(SELECT TrainingHours, COUNT(*) AS TotalEmpTrainHrs,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Yes_TrainHrs,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS Attrition_No_TrainHrs
FROM hr_database
GROUP BY TrainingHours)

SELECT TrainingHours, Attrition_Yes_TrainHrs, TotalEmpTrainHrs, ROUND(Attrition_Yes_TrainHrs*100/TotalEmpTrainHrs, 2) AS TrainHrsAttrPercent 
FROM TrainHrs
ORDER BY TrainHrsAttrPercent;

-- Employees with training time less than 10 hours shows tendency of leaving.

---------------------------------------------------------------------------------------------------------------------------------
-- Satisfaction Score
WITH SatfsScr AS(SELECT SatisfactionScore, COUNT(*) AS TotalEmpSatfsScr,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Yes_SatfsScr,
    SUM(CASE WHEN Attrition = 'No' THEN 1 ELSE 0 END) AS Attrition_No_SatfsScr
FROM hr_database
GROUP BY SatisfactionScore)

SELECT SatisfactionScore, Attrition_Yes_SatfsScr, TotalEmpSatfsScr, ROUND(Attrition_Yes_SatfsScr*100/TotalEmpSatfsScr, 2) AS SatfsScrAttrPercent 
FROM SatfsScr
ORDER BY SatfsScrAttrPercent;
/*
Attrition percent per satisfaction score is around the company average. The score of 4 at satisfaction leads to most attrition, closely followed by score of 3.
Number of employees having a low Satisfaction score have a low Attrition rate. Meaning, they would rather like to improve.
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Given the analysis of features individually, let us look at if some of them are interrelated. 
---------------------------------------------------------------------------------------------------------------------------------
-- Let us check some details of the finance department

SELECT Position, Attrition , COUNT(*)
FROM hr_database
WHERE Department = 'Finance'
GROUP BY Position, Attrition;

-- The finance department has 2 Positions. The financial manager position has a very high attrition rate as compared to the Financial Analyst position.

SELECT AVG(Age), AVG(Salary), AVG(YearsOfService),AVG(PerformanceRating), AVG(WorkHours), AVG(TrainingHours), AVG(SatisfactionScore)  
FROM hr_database
WHERE Position = 'Financial Manager' AND Attrition = 'Yes';

SELECT Promotion, COUNT(*)
FROM hr_database
WHERE Position = 'Financial Manager' AND Attrition = 'Yes'
GROUP BY Promotion;

/*
There are 6 people leaving their job from the position of Financial Manager.
All of them had equal salary, good satisfaction score and performance rating, but their work hours were above average, their work experience was above 6 years on average and 5 of them had not been promoted, which can be a cause for the attrition.
*/
---------------------------------------------------------------------------------------------------------------------------------
-- Majority of Attriton comes from people having satisfaction score of 3 or 4. 

SELECT Position, COUNT(*)
FROM hr_database
WHERE SatisfactionScore IN (3,4) AND Attrition = 'Yes'
GROUP BY Position; 

SELECT AVG(YearsOfService), AVG(Salary)
FROM hr_database
WHERE SatisfactionScore IN (3,4) AND Attrition = 'Yes' AND Promotion = 'No';

/*
41 out of the 115 people having a Satisfaction score of either 3 or 4 have left. 
Financial Analyst, Software Engineer, Data Scientist, Marketing Manager, HR Coordinator constitute of 31 out of the 41
33 out of these 41 have not been promoted, while having an above average salary, and having at average more than 5.7 years of experience.
*/
---------------------------------------------------------------------------------------------------------------------------------
SELECT 
	Department,
    COUNT(*) AS TotalEmp,
    ROUND(AVG(Salary),0) AS AvgSalary,
    ROUND(AVG(SatisfactionScore),0) AS AvgSatisfactionScore,
    ROUND(AVG(WorkHours),0) AS AvgWorkHours,
    ROUND(AVG(TrainingHours),0) AS AvgTrainingHours
FROM hr_database
WHERE Attrition = 'Yes'
GROUP BY Department;
/*
On an absolute scale, the number of employees leaving from IT department is the maximum. 
As seen in a previous analysis, there was a high rate of attrition from Finance, Marketing, and IT department. In case for the IT and Finance departments, they have below average salary and above average work hours. 
*/
---------------------------------------------------------------------------------------------------------------------------------
-- POSITION
SELECT
	Position,
    COUNT(*) AS TotalEmp,
    ROUND(AVG(Salary),0) AS AvgSalary,
    MIN(Salary) as MinSal,
    MAX(Salary) as MaxSal,
    ROUND(AVG(SatisfactionScore),0) AS AvgSatisfactionScore,
    ROUND(AVG(WorkHours),0) AS AvgWorkHours,
    ROUND(AVG(TrainingHours),0) AS AvgTrainingHours,
    ROUND(AVG(YearsOfService),0) AS AvgYearsOfService,
	SUM(CASE WHEN Promotion = 'Yes' THEN 1 ELSE 0 END) AS Promotion_Yes,
    ROUND(AVG(PerformanceRating),0) AS AvgPerformanceRating
FROM hr_database
WHERE Attrition = 'Yes'
GROUP BY Position;
/*
On an Absolute scale, Financial Analysts and Data Scientists have the maximum attrition rate. 
Leaving Data Scientists, Marketing Analyst and HR coordinators have below average salary, Above avg work hours and less experience. 
*/
---------------------------------------------------------------------------------------------------------------------------------
SELECT 
	YearsOfService, Attrition,
    SUM(CASE WHEN Promotion = 'Yes' THEN 1 ELSE 0 END) AS Promoted,
    SUM(CASE WHEN Promotion = 'No' THEN 1 ELSE 0 END) AS NotPromoted
FROM hr_database
GROUP BY YearsOfService, Attrition
ORDER BY YearsOfService, Attrition;

-- Attrition doesn't show a correlation with Promotion when looked with respect to Years Of Service. The amount of people leaving is less as compared to people staying while not having a promotion. 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Problem Statement 2: "Optimize Employee Training Programs"
-- Objective: Analyse the effectiveness of training programs and recommend improvements to enhance employee skills and performance.

-- One way to check for how training is affecting employees is to check their salaries

SELECT TrainingHours, ROUND(AVG(Salary),2) AS AvgSalPerTrainHrs
FROM hr_database
GROUP BY TrainingHours;

-- Based on the above Stat alone, it can be said that the employees must have training hours between 20-25 hours to have the max salary. 

---------------------------------------------------------------------------------------------------------------------------------
-- Let us look at if there is any disparity between training hours and gender

SELECT TrainingHours,
    SUM(CASE WHEN Gender = 'M' THEN 1 ELSE 0 END) AS Male,
    SUM(CASE WHEN Gender = 'F' THEN 1 ELSE 0 END) AS Female
FROM hr_database
GROUP BY TrainingHours
ORDER BY TrainingHours;

SELECT Gender, AVG(TrainingHours)
FROM hr_database
GROUP BY Gender;

-- On Average, Female Employees have higher training hours.
---------------------------------------------------------------------------------------------------------------------------------
SELECT TrainingHours,
    SUM(CASE WHEN AgeGroup = '> 30 years' THEN 1 ELSE 0 END) AS '30+',
    SUM(CASE WHEN AgeGroup = '<= 30 years' THEN 1 ELSE 0 END) AS '<=30'
FROM hr_database
GROUP BY TrainingHours
ORDER BY TrainingHours;

SELECT AgeGroup, AVG(TrainingHours)
FROM hr_database
GROUP BY AgeGroup;

-- Average training hours for employees of age <30 or >= 30 are similar. 
---------------------------------------------------------------------------------------------------------------------------------
-- We can also check for relationships between Training Hours and Satisfaction score

SELECT TrainingHours, ROUND(AVG(SatisfactionScore),2) AS AvgSatScr
FROM hr_database
GROUP BY TrainingHours;

-- Training Hours and Satisfaction Score seem to be inversely related. Employees with lower Training Hours show higher Satisfaction. 

SELECT TrainingHours, Department, ROUND(AVG(SatisfactionScore),2) AS AvgSatScr
FROM hr_database
GROUP BY TrainingHours, Department
ORDER BY Department, TrainingHours;

/*
Checking per department, the finance department need to have training for 15 hours, as this results in the best satisfaction score
HR department has the maximum Satisfaction score at 30 hours
IT, Sales, and Marketing department is fine with less training, having the max Satisfaction score at 10 hours
*/
---------------------------------------------------------------------------------------------------------------------------------
-- Let us check how are training hours and promotion related
SELECT TrainingHours,
    SUM(CASE WHEN Promotion = 'Yes' THEN 1 ELSE 0 END) AS Promoted,
    SUM(CASE WHEN Promotion = 'No' THEN 1 ELSE 0 END) AS NotPromoted
FROM hr_database
GROUP BY TrainingHours
ORDER BY TrainingHours;

/*
Employees with 25 hours of training have been promoted the most
Employees with 15 or less than 15 hours of training barely get promoted.
*/
SELECT TrainingHours, Position,
    SUM(CASE WHEN Promotion = 'Yes' THEN 1 ELSE 0 END) AS Promoted,
    SUM(CASE WHEN Promotion = 'No' THEN 1 ELSE 0 END) AS NotPromoted
FROM hr_database
GROUP BY TrainingHours, Position
ORDER BY Position, TrainingHours;

/*
Marketing Analyst, HR Coordinators and Data Scientists with 20-25 hours of Training have a better chance of getting promoted.
Sales Managers, Sales Associate and Marketing Analyst with 25-30 hours of Training have a better chance of getting promoted.
Majority of Financial Analysts with 30 hours of training have been promoted.
Promotions for the position of 
Managerial Positions show promotion at 15 hours of training time. 
Software Engineers have been promoted at similar rates for all Training Hours
*/
---------------------------------------------------------------------------------------------------------------------------------
-- Doing similar analysis for Performance rating
SELECT TrainingHours, ROUND(AVG(PerformanceRating),2) AS AvgPerfScr
FROM hr_database
GROUP BY TrainingHours;

/*
Performance score does not seem to vary much with training hours. 
The Max Average Performance score is achieved at 10 hours.
The Min Average Performance score is achieved at 25 hours.
*/ 

SELECT TrainingHours, COUNT(*) AS emps
FROM hr_database
WHERE PerformanceRating IN (5)
GROUP BY TrainingHours;

-- Employees getting a 5 on Performance rating majorly have TrainingHours between 15-20 Hours. 
SELECT TrainingHours, COUNT(*) AS emps 
FROM hr_database
WHERE PerformanceRating IN (4,5) 
GROUP BY TrainingHours;

/*
A more even distribution of training hours is seen for Performance Rating of 4 and 5, with max being at 15 hours.  
It can clearly be seen that min 15 hours of training has helped employees get a Performance ranking of 4 or 5.
*/

SELECT TrainingHours, Department,  ROUND(AVG(PerformanceRating),2) AS AvgPerfScr
FROM hr_database
GROUP BY TrainingHours, Department
ORDER BY Department, TrainingHours;

/*
For the finance department, the average satisfaction rating is above 4, with max at 20 hours.
The HR department has a lowest rating at 25 hours, but the max rating at 30 hours.  
The IT department has min satisfaction rating of 4.17 at 30 hours and max score of 4.63 at 20 hours.
Marketing Department in General has a low Performance rating, with the max performance rating of 3.40
Sales has a uniform average performance rating of 4 for all training hours. 
*/

SELECT TrainingHours, Position,  ROUND(AVG(PerformanceRating),2) AS AvgPerfScr
FROM hr_database
GROUP BY TrainingHours, Position
ORDER BY Position, TrainingHours;

/*
Data Scientists have min rating of 4.33 at 25 hours, and max at 20 hours. 
Financial Managers with 15+ hours of training have average rating above 4.75
Marketing Analysts and HR coordinators have average rating of near 3 for all training hours
HR mangers somehow do not do well with training time of 20 and 25 hours
Financial Analysts, Marketing Manager, Sales Associate, Sales Manager, Software Engineer have average rating around 4 for all the training hours.
*/
