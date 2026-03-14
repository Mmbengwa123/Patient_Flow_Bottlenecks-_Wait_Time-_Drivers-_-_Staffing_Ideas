CREATE DATABASE Healthcare_Ops;

GO

CREATE TABLE Patient_App_Scheduling_Dataset
(
	patient_id INT PRIMARY KEY,
	Patient_Admission_Date DATE,
	Patient_Admission_Time TIME,
	Merged varchar(200),
	Patient_Gender VARCHAR(20),
	Patient_age INT,
	Patient_Race VARCHAR(50),
	Department_Referral VARCHAR(100),
	Patient_Admission_Flag varchar(100),
	Patient_Satisfaction_Score INT,
	Patient_Wait_time INT
	);

