/*
Energy Losses and Market Reliability

1. What percent of the approved outages in 2016 and 2017 were forced outages?
*/

SELECT
    Total_Number_Outage_Events,
    Total_Number_Forced_Outage_Events,
    ROUND(((Total_Number_Forced_Outage_Events/Total_Number_Outage_Events)),2)*100 AS Forced_Outage_Percentage,
    Year
FROM (
    SELECT
    COUNT(*) AS Total_Number_Outage_Events,
    Year,
    SUM(CASE WHEN Outage_Reason='Forced' THEN 1 ELSE 0 END) AS Total_Number_Forced_Outage_Events
    FROM AEMR_Outage_Table
    WHERE Status='Approved'
    GROUP BY Year
    )
GROUP BY Year
;

/*
2. What was the average duration in days and average energy lost of all approved forced outages for each participant code and facility code,
sorted by average energy lost in descending order?
*/

SELECT 
    ROUND((AVG(ABS(JULIANDAY(End_Time) - JULIANDAY(Start_Time)))),2) AS Avg_Duration_in_Days,
    ROUND((AVG(Energy_Lost_MW)),2) AS Avg_Energy_Lost,
    Outage_Reason,
    Participant_Code,
    Facility_Code,               
    Year  
    FROM AEMR_Outage_Table
    WHERE (YEAR=2016 OR Year=2017) 
        AND Status='Approved' 
        AND Outage_Reason='Forced'
    GROUP BY Participant_Code, 
             Outage_Reason, 
             Year
    ORDER BY Avg_Energy_Lost DESC, 
             Year;

/*
3. What was the percentage of energy lost due to forced outages for each facility code out of the total energy lost due to forced outages? 
AND
What were the top 3 participants by total energy loss due to forced outages?
*/

WITH facility_energy_lost AS
    (
    SELECT ROUND((AVG(Energy_Lost_MW)),2) AS Avg_Forced_Energy_Lost,
            ROUND((SUM(Energy_Lost_MW)),2) AS Total_Forced_Energy_Lost_by_Facility,
            Outage_Reason,
            Participant_Code,
            Facility_Code,
            EventID
    FROM AEMR_Outage_Table
    WHERE (YEAR=2016 OR Year=2017) 
        AND Status='Approved' 
        AND Outage_Reason='Forced'
    GROUP BY Facility_Code
    ),

    total_energy_lost AS 
    (
    SELECT
        SUM(Energy_Lost_MW) OVER() AS Total_Forced_Energy_Lost,
        EventID, 
        Participant_Code, 
        Facility_Code
    FROM AEMR_Outage_Table
    WHERE (YEAR=2016 OR Year=2017) 
        AND Status='Approved' 
        AND Outage_Reason='Forced')

SELECT 
    fel.Avg_Forced_Energy_Lost, 
    fel.Total_Forced_Energy_Lost_by_Facility, 
    ROUND((tel.Total_Forced_Energy_Lost),2) AS Total_Forced_Energy_Lost, 
    ROUND(((fel.Total_Forced_Energy_Lost_by_Facility/tel.Total_Forced_Energy_Lost)*100),2) AS Perc_Forced_Energy_Lost,
    fel.Participant_Code, 
    fel.Facility_Code
FROM facility_energy_lost AS fel
JOIN total_energy_lost AS tel
    ON fel.Facility_Code=tel.Facility_Code
GROUP BY fel.Facility_Code, 
         fel.Participant_Code
ORDER BY fel.Total_Forced_Energy_Lost_by_Facility DESC
LIMIT 3;

/*
4. For the 3 partipants with the highest total energy losses due to forced outages, what Description_Of_Outage had the highest total energy loss for each facility code?
Also, what percentage of energy was lost out of the total due to forced outages for these Description_Of_Outages?*/

SELECT *
FROM (SELECT  Participant_Code,
        Facility_Code,
        Description_Of_Outage,
        ROUND(SUM(Energy_Lost_MW),2) as Total_Energy_Lost,
        (SELECT ROUND((SUM(Energy_Lost_MW)),2) 
               FROM AEMR_Outage_Table 
               WHERE Status = 'Approved' 
                   AND Outage_Reason = 'Forced') AS Overall_Energy_Loss,
        ROUND(SUM(Energy_Lost_MW) / 
              (SELECT SUM(Energy_Lost_MW) 
               FROM AEMR_Outage_Table 
               WHERE Status = 'Approved' 
                   AND Outage_Reason = 'Forced')*100,2) AS Pct_Energy_Loss,
        RANK() OVER (PARTITION BY Participant_Code, Facility_Code ORDER BY SUM(Energy_Lost_MW) DESC) AS rank 
FROM AEMR_Outage_Table
WHERE Participant_Code IN ('GW','MELK','AURICON') 
    AND Status = 'Approved' 
    AND Outage_Reason = 'Forced'
GROUP BY Participant_Code, 
         Facility_Code, 
         Description_Of_Outage
ORDER BY Participant_Code, 
         Total_Energy_Lost DESC)
WHERE rank=1;
  



