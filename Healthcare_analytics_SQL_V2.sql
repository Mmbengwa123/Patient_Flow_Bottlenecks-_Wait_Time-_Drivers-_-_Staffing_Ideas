SELECT TOP (1000) [Patient_Id]
      ,[Patient_Admission_Date]
      ,[Patient_Admission_Time]
      ,[Merged]
      ,[Patient_Gender]
      ,[Patient_Age]
      ,[Patient_Race]
      ,[Department_Referral]
      ,[Patient_Admission_Flag]
      ,[Patient_Satisfaction_Score]
      ,[Patient_Waittime]
  FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
SELECT * FROM [Healthcare_Ops].[dbo].[healthcare_analytics]


--Section 1: Data Quality & Integrity
--Goal: Ensure the dataset is clean and usable before analysis.

--Questions

--•	Which columns have inconsistent formats (e.g., dates in dd/mm/yyyy vs mm/dd/yyyy, times with am/pm)?

SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'healthcare_analytics';

--•	Are there missing or null values in critical fields like Admission_Date, Admission_Time, or Wait_Time?
SELECT 
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN Patient_Admission_Date IS NULL THEN 1 ELSE 0 END) AS MissingAdmissionDate,
    SUM(CASE WHEN Patient_Admission_Time IS NULL THEN 1 ELSE 0 END) AS MissingAdmissionTime,
    SUM(CASE WHEN Patient_Waittime IS NULL THEN 1 ELSE 0 END) AS MissingWaitTime
FROM [Healthcare_Ops].[dbo].[healthcare_analytics];

--•	Do duplicate patient IDs or admission records exist?

SELECT 
    Patient_Id,
    COUNT(*) AS RecordCount
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
GROUP BY Patient_Id
HAVING COUNT(*) > 1;

--•identify invalid entries (e.g., negative wait times, impossible discharge dates)?
SELECT *
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
WHERE TRY_CONVERT(DATE, Patient_Admission_Date, 103) > GETDATE()
   OR Patient_Waittime < 0;

--   Section 2: Descriptive Analytics

--Goal: Summarize patient flow metrics to spot patterns.

--Questions:

--•	What is the average wait time per department, per day of week, and per hour of admission?

SELECT  
    Department_Referral,
    DATENAME(WEEKDAY, TRY_CONVERT(DATE, Patient_Admission_Date, 103)) AS DayOfWeek,
    DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) AS HourOfAdmission,
    AVG(Patient_Waittime) AS AverageWaitTime
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
WHERE TRY_CONVERT(DATE, Patient_Admission_Date, 103) IS NOT NULL
  AND TRY_CONVERT(TIME, Patient_Admission_Time, 109) IS NOT NULL
GROUP BY Department_Referral,
         DATENAME(WEEKDAY, TRY_CONVERT(DATE, Patient_Admission_Date, 103)),
         DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109))
         ORDER BY Department_Referral, DayOfWeek, HourOfAdmission desc;

--•	How do patient satisfaction scores correlate with wait times?
SELECT 
    Patient_Satisfaction_Score,
    AVG(Patient_Waittime) AS AverageWaitTime
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
WHERE Patient_Satisfaction_Score IS NOT NULL
GROUP BY Patient_Satisfaction_Score
ORDER BY Patient_Satisfaction_Score;

--•	Which admission times (morning vs evening) show the highest bottlenecks?

SELECT 
    CASE 
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Night'
    END AS AdmissionPeriod,
    AVG(Patient_Waittime) AS AverageWaitTime
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
WHERE TRY_CONVERT(TIME, Patient_Admission_Time, 109) IS NOT NULL
GROUP BY CASE 
            WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 18 AND 23 THEN 'Evening'
            ELSE 'Night'
         END
ORDER BY AdmissionPeriod;

--•	Are certain departments consistently above the average wait time?

SELECT 
    Department_Referral,
    AVG(Patient_Waittime) AS AverageWaitTime
    FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
    GROUP BY Department_Referral
    HAVING AVG(Patient_Waittime) > (SELECT AVG(Patient_Waittime) FROM [Healthcare_Ops].[dbo].[healthcare_analytics])
    ORDER BY AverageWaitTime DESC;

--    Section 3: Diagnostic Analytics

--Goal: Pinpoint root causes of bottlenecks.

--Questions:

--•	Which staffing levels (nurses/doctors per shift) correlate most strongly with reduced wait times?

SELECT 
    Department_Referral,
    COUNT(DISTINCT Patient_Id) AS TotalPatients,
    AVG(Patient_Waittime) AS AverageWaitTime
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
GROUP BY Department_Referral;

--•	Do longer wait times occur more often during peak admission hours?

SELECT 
    CASE 
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Night'
    END AS AdmissionPeriod,
    AVG(Patient_Waittime) AS AverageWaitTime
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
WHERE TRY_CONVERT(TIME, Patient_Admission_Time, 109) IS NOT NULL
GROUP BY CASE 
            WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 18 AND 23 THEN 'Evening'
            ELSE 'Night'
         END
ORDER BY AdmissionPeriod;

--•	Which patient categories (emergency vs scheduled) drive the longest delays?

SELECT 
    Patient_Admission_Flag,
    AVG(Patient_Waittime) AS AverageWaitTime
    FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
    GROUP BY Patient_Admission_Flag
    ORDER BY AverageWaitTime DESC;

--•	Can correlation analysis (SQL + export to Python/Power BI) highlight high impact drivers?

SELECT 
    Department_Referral,
    Patient_Admission_Flag,
    AVG(Patient_Waittime) AS Average_Wait_Time
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
GROUP BY Department_Referral, Patient_Admission_Flag
ORDER BY Average_Wait_Time DESC;

--Section 4: Prescriptive Insights & Solutions

--Goal: Translate findings into actionable recommendations.
--Questions:

--•	If staffing is increased during peak hours, how much could average wait time decrease?

SELECT 
    Department_Referral,
    CASE 
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Night'
    END AS AdmissionPeriod,
    AVG(Patient_Waittime) AS Average_Wait_Time
    FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
    GROUP BY Department_Referral, 
             CASE 
                WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 6 AND 11 THEN 'Morning'
                WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 12 AND 17 THEN 'Afternoon'
                WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 18 AND 23 THEN 'Evening'
                ELSE 'Night'
             END
             ORDER BY Average_Wait_Time DESC;

--•	Which departments would benefit most from reallocation of staff?

SELECT 
    Department_Referral,
    AVG(Patient_Waittime) AS Average_Wait_Time
    FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
    GROUP BY Department_Referral
    ORDER BY Average_Wait_Time DESC;

--•	What “what if” scenarios (e.g., +1 nurse per shift) show the biggest improvement in KPIs?

SELECT 
    Department_Referral,
    AVG(Patient_Waittime) AS Average_Wait_Time
    FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
    GROUP BY Department_Referral
    ORDER BY Average_Wait_Time DESC;

--•	How can dashboards visualize staffing vs wait time to support decision making?
SELECT 
    Department_Referral,
    CASE 
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Night'
    END AS AdmissionPeriod,
    AVG(Patient_Waittime) AS Average_Wait_Time
    FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
    GROUP BY Department_Referral, 
             CASE 
                WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 6 AND 11 THEN 'Morning'
                WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 12 AND 17 THEN 'Afternoon'
                WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 18 AND 23 THEN 'Evening'
                ELSE 'Night'
             END
             ORDER BY Average_Wait_Time DESC;

-----------------------------------------------------------------------------------------------------------------------


  ---CLEAN TABLE--


 SELECT
    Patient_ID,
    TRY_CONVERT(DATE, Patient_Admission_Date, 103) AS Patient_Admission_Date,   -- dd/mm/yyyy
    TRY_CONVERT(TIME, Patient_Admission_Time, 109) AS Patient_Admission_Time,   -- hh:mm:ss am/pm
    Merged,
    Patient_Gender,
    Patient_Age,
    Patient_Race,
    Department_Referral,
    Patient_Admission_Flag,
    Patient_Satisfaction_Score,
    CASE 
        WHEN Patient_Waittime < 0 THEN NULL 
        ELSE Patient_Waittime 
    END AS Patient_Waittime
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
WHERE TRY_CONVERT(DATE, Patient_Admission_Date, 103) IS NOT NULL
  AND TRY_CONVERT(TIME, Patient_Admission_Time, 109) IS NOT NULL;
  ------------------------------------------------------------------------


  SELECT
    Patient_ID,
    TRY_CONVERT(DATE, Patient_Admission_Date, 103) AS Patient_Admission_Date,
    TRY_CONVERT(TIME, Patient_Admission_Time, 109) AS Patient_Admission_Time,
    Merged,
    Patient_Gender,
    Patient_Age,
    Patient_Race,
    Department_Referral,
    Patient_Admission_Flag,
    Patient_Satisfaction_Score,
    CASE 
        WHEN Patient_Waittime < 0 THEN NULL 
        ELSE Patient_Waittime 
    END AS Patient_Waittime,

    -- Section 1: Data Quality Flags
    CASE WHEN TRY_CONVERT(DATE, Patient_Admission_Date, 103) IS NULL THEN 1 ELSE 0 END AS Invalid_Date_Flag,
    CASE WHEN TRY_CONVERT(TIME, Patient_Admission_Time, 109) IS NULL THEN 1 ELSE 0 END AS Invalid_Time_Flag,
    CASE WHEN Patient_Waittime < 0 THEN 1 ELSE 0 END AS Invalid_Wait_Flag,

    -- Section 2: Descriptive Metrics
    DATENAME(WEEKDAY, TRY_CONVERT(DATE, Patient_Admission_Date, 103)) AS DayOfWeek,
    DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) AS HourOfAdmission,

    -- Section 3: Diagnostic Metrics
    AVG(Patient_Waittime) OVER (PARTITION BY Department_Referral) AS Dept_Avg_Wait,
    AVG(Patient_Satisfaction_Score) OVER (PARTITION BY Department_Referral) AS Dept_Avg_Satisfaction,

    -- Section 4: Prescriptive Scenario (simulate 10% reduction in wait times during peak hours)
    CASE 
        WHEN DATEPART(HOUR, TRY_CONVERT(TIME, Patient_Admission_Time, 109)) BETWEEN 9 AND 12
        THEN Patient_Waittime * 0.9
        ELSE Patient_Waittime
    END AS Simulated_Waittime

INTO [Healthcare_Ops].[dbo].[healthcare_analytics_dash]
FROM [Healthcare_Ops].[dbo].[healthcare_analytics]
WHERE TRY_CONVERT(DATE, Patient_Admission_Date, 103) IS NOT NULL
  AND TRY_CONVERT(TIME, Patient_Admission_Time, 109) IS NOT NULL;
