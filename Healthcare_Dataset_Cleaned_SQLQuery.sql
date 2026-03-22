SELECT TOP (1000) [Patient_ID]
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
      ,[Invalid_Date_Flag]
      ,[Invalid_Time_Flag]
      ,[Invalid_Wait_Flag]
      ,[DayOfWeek]
      ,[HourOfAdmission]
      ,[Dept_Avg_Wait]
      ,[Dept_Avg_Satisfaction]
      ,[Simulated_Waittime]
  FROM [Healthcare_Ops].[dbo].[healthcare_analytics_dash]

  -- Patient Flow Analysis: Wait Times & Satisfaction
SELECT 
    Department_Referral,
    DayOfWeek,
    HourOfAdmission,
    COUNT(Patient_ID) AS Total_Patients,
    AVG(Patient_Waittime) AS Avg_Waittime,
    AVG(Patient_Satisfaction_Score) AS Avg_Satisfaction,
    SUM(CASE WHEN Patient_Admission_Flag = 'Admission' THEN 1 ELSE 0 END) AS Admissions,
    SUM(CASE WHEN Patient_Admission_Flag = 'Not Admission' THEN 1 ELSE 0 END) AS Non_Admissions
FROM [Healthcare_Ops].[dbo].[healthcare_analytics_dash]
WHERE Invalid_Date_Flag = 0 
  AND Invalid_Time_Flag = 0 
  AND Invalid_Wait_Flag = 0
GROUP BY Department_Referral, DayOfWeek, HourOfAdmission
ORDER BY Department_Referral, DayOfWeek, HourOfAdmission;

-- Bucketed Wait Times for Histogram/Heatmap
SELECT 
    Department_Referral,
    CASE 
        WHEN Patient_Waittime <= 15 THEN '0-15 mins'
        WHEN Patient_Waittime <= 30 THEN '16-30 mins'
        WHEN Patient_Waittime <= 45 THEN '31-45 mins'
        ELSE '46+ mins'
    END AS Wait_Bucket,
    COUNT(Patient_ID) AS Patient_Count
FROM [Healthcare_Ops].[dbo].[healthcare_analytics_dash]
WHERE Invalid_Wait_Flag = 0
GROUP BY Department_Referral,
    CASE 
        WHEN Patient_Waittime <= 15 THEN '0-15 mins'
        WHEN Patient_Waittime <= 30 THEN '16-30 mins'
        WHEN Patient_Waittime <= 45 THEN '31-45 mins'
        ELSE '46+ mins'
    END
ORDER BY Department_Referral, Wait_Bucket;

-------------------------------------------------------
-- Unified Patient Flow Analytics Table
SELECT 
    Patient_ID,
    Patient_Admission_Date,
    Patient_Admission_Time,
    DayOfWeek,
    HourOfAdmission,
    Department_Referral,
    Patient_Gender,
    Patient_Age,
    Patient_Race,
    Patient_Admission_Flag,
    Patient_Waittime,
    Patient_Satisfaction_Score,
    
    -- Aggregates for dashboarding
    COUNT(Patient_ID) OVER (PARTITION BY Department_Referral) AS Dept_Total_Patients,
    AVG(Patient_Waittime) OVER (PARTITION BY Department_Referral) AS Dept_Avg_Waittime,
    AVG(Patient_Satisfaction_Score) OVER (PARTITION BY Department_Referral) AS Dept_Avg_Satisfaction,
    
    COUNT(Patient_ID) OVER (PARTITION BY DayOfWeek, HourOfAdmission) AS Patients_By_Time,
    AVG(Patient_Waittime) OVER (PARTITION BY DayOfWeek, HourOfAdmission) AS Avg_Wait_By_Time,
    AVG(Patient_Satisfaction_Score) OVER (PARTITION BY DayOfWeek, HourOfAdmission) AS Avg_Satisfaction_By_Time,
    
    SUM(CASE WHEN Patient_Admission_Flag = 'Admission' THEN 1 ELSE 0 END) 
        OVER (PARTITION BY Department_Referral) AS Dept_Admissions,
    SUM(CASE WHEN Patient_Admission_Flag = 'Not Admission' THEN 1 ELSE 0 END) 
        OVER (PARTITION BY Department_Referral) AS Dept_Non_Admissions,
    
    -- Wait time buckets for histograms
    CASE 
        WHEN Patient_Waittime <= 15 THEN '0-15 mins'
        WHEN Patient_Waittime <= 30 THEN '16-30 mins'
        WHEN Patient_Waittime <= 45 THEN '31-45 mins'
        ELSE '46+ mins'
    END AS Wait_Bucket,
    
    -- Monthly grouping for trend analysis
    FORMAT(Patient_Admission_Date, 'yyyy-MM') AS Admission_Month
FROM [Healthcare_Ops].[dbo].[healthcare_analytics_dash]
WHERE Invalid_Date_Flag = 0 
  AND Invalid_Time_Flag = 0 
  AND Invalid_Wait_Flag = 0;
  SUM(CASE WHEN Patient_Admission_Flag = 'Admission' THEN 1 ELSE 0 END) 
        OVER (PARTITION BY Department_Referral) AS Dept_Admissions,
    SUM(CASE WHEN Patient_Admission_Flag = 'Not Admission' THEN 1 ELSE 0 END) 
        OVER (PARTITION BY Department_Referral) AS Dept_Non_Admissions,
    
    -- Wait time buckets for histograms
    CASE 
        WHEN Patient_Waittime <= 15 THEN '0-15 mins'
        WHEN Patient_Waittime <= 30 THEN '16-30 mins'
        WHEN Patient_Waittime <= 45 THEN '31-45 mins'
        ELSE '46+ mins'
    END AS Wait_Bucket,
    
    -- Monthly grouping for trend analysis
    FORMAT(Patient_Admission_Date, 'yyyy-MM') AS Admission_Month
FROM [Healthcare_Ops].[dbo].[healthcare_analytics_dash]
WHERE Invalid_Date_Flag = 0 
  AND Invalid_Time_Flag = 0 
  AND Invalid_Wait_Flag = 0;


  -- Unified Patient Flow Analytics Export
SELECT 
    Department_Referral,
    DayOfWeek,
    HourOfAdmission,
    CONVERT(VARCHAR(7), Patient_Admission_Date, 120) AS Admission_Month,
    
    COUNT(Patient_ID) AS Total_Patients,
    AVG(Patient_Waittime) AS Avg_Waittime,
    AVG(Patient_Satisfaction_Score) AS Avg_Satisfaction,
    
    SUM(CASE WHEN Patient_Admission_Flag = 'Admission' THEN 1 ELSE 0 END) AS Admissions,
    SUM(CASE WHEN Patient_Admission_Flag = 'Not Admission' THEN 1 ELSE 0 END) AS Non_Admissions,
    
    -- Wait time buckets
    SUM(CASE WHEN Patient_Waittime <= 15 THEN 1 ELSE 0 END) AS Wait_0_15,
    SUM(CASE WHEN Patient_Waittime > 15 AND Patient_Waittime <= 30 THEN 1 ELSE 0 END) AS Wait_16_30,
    SUM(CASE WHEN Patient_Waittime > 30 AND Patient_Waittime <= 45 THEN 1 ELSE 0 END) AS Wait_31_45,
    SUM(CASE WHEN Patient_Waittime > 45 THEN 1 ELSE 0 END) AS Wait_46_plus
FROM [Healthcare_Ops].[dbo].[healthcare_analytics_dash]
WHERE Invalid_Date_Flag = 0 
  AND Invalid_Time_Flag = 0 
  AND Invalid_Wait_Flag = 0
GROUP BY Department_Referral, DayOfWeek, HourOfAdmission, CONVERT(VARCHAR(7), Patient_Admission_Date, 120)
ORDER BY Department_Referral, Admission_Month, DayOfWeek, HourOfAdmission;
