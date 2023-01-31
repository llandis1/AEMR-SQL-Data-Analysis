/*
Energy Stability and Market Outages

1. How many approved outage events occurred per outage reason (i.e. Forced, Consequential, Scheduled, Opportunistic) 
over 2016 and 2017?
*/

SELECT  COUNT(*) AS Total_Number_Outages, 
        Outage_Reason 
FROM AEMR_Outage_Table
WHERE (YEAR=2016 OR Year=2017) 
    AND Status='Approved'
GROUP BY Outage_Reason
ORDER BY Total_Number_Outages DESC;
/* 

2. Were any of the approved outages of each reason (Forced, Consequential, Scheduled, Opportunistic) increasing on a monthly basis?*/

SELECT  Year, 
        Month, 
        COUNT(*) AS Total_Number_Outages, 
        Outage_Reason
FROM AEMR_Outage_Table
WHERE (YEAR=2016 OR Year=2017) 
    AND Status='Approved'
GROUP BY Outage_Reason, 
        Year, 
        Month
ORDER BY Outage_Reason, 
        Year, 
        Month;

/*
3. What was the number of approved outage events and the average duration in days for each participant code and outage reason over 2016 and 2017?*/

SELECT  Participant_Code, 
        Outage_Reason, 
        Year, 
        COUNT(*) AS Total_Number_Outage_Events, 
        ROUND((AVG(ABS(JULIANDAY(End_Time) - JULIANDAY(Start_Time)))),2) AS Average_Outage_Duration_in_Days
FROM AEMR_Outage_Table
WHERE (YEAR=2016 OR Year=2017) 
    AND Status='Approved'
GROUP BY Participant_Code, 
         Outage_Reason, 
         Year
ORDER BY Total_Number_Outage_Events DESC, 
         Outage_Reason, 
         Year;

/*
4. Classifying each participant as "High Risk", "Medium Risk", or "Low Risk" based on their average outage duration time for all approved outages across 2016-2017:
High Risk - On average participant is unavailable for > 24 Hours
Medium Risk - On average the participant is unavailable between 12 and 24 Hours
Low Risk - On average the participant is unavailable for less than 12 Hours
*/

SELECT  Participant_Code,
        Outage_Reason,
        Year,
        Total_Number_Outage_Events,
        Average_Outage_Duration_in_Days,
        CASE WHEN Average_Outage_Duration_in_Days>1 THEN 'High Risk'
             WHEN Average_Outage_Duration_in_Days BETWEEN .5 AND 1 THEN 'Medium Risk'
             WHEN Average_Outage_Duration_in_Days<.5 THEN 'Low Risk'
             END AS Risk_Classification
FROM (
    SELECT  Participant_Code, 
            Outage_Reason, 
            Year, 
            COUNT(*) AS Total_Number_Outage_Events, 
            ROUND((AVG(ABS(JULIANDAY(End_Time) - JULIANDAY(Start_Time)))),2) AS Average_Outage_Duration_in_Days
    FROM AEMR_Outage_Table
    WHERE (YEAR=2016 OR Year=2017) 
        AND Status='Approved'
    GROUP BY Participant_Code, 
             Outage_Reason, 
             Year
    ORDER BY Total_Number_Outage_Events DESC, 
             Outage_Reason, 
             Year
    )
ORDER BY Average_Outage_Duration_in_Days DESC;

/*
5. Classifying risk level of participants with different criteria and only focusing risk category on forced outages:
High Risk - On average, the participant is unavailable for > 24 Hours OR the total number of outage events > 20
Medium Risk - On average, the participant is unavailable between 12 and 24 Hours OR the total number of outage events is Between 10 and 20
Low Risk - On average, the participant is unavailable for less than 12 Hours OR the total number of outage events < 10
If outage type is not forced, then N/A 
*/

SELECT Participant_Code,
        Outage_Reason,
        Year,
        Total_Number_Outage_Events,
        Average_Outage_Duration_in_Days,
        CASE WHEN (Average_Outage_Duration_in_Days>1 OR Total_Number_Outage_Events>20) 
                AND Outage_Reason='Forced' THEN 'High Risk'
            WHEN (Average_Outage_Duration_in_Days BETWEEN .5 AND 1 
                OR Total_Number_Outage_Events BETWEEN 10 AND 20) 
                AND Outage_Reason='Forced' THEN 'Medium Risk'
            WHEN (Average_Outage_Duration_in_Days<.5 
                OR Total_Number_Outage_Events<10) 
                AND Outage_Reason='Forced' THEN 'Low Risk'
            ELSE 'N/A' 
            END AS Risk_Classification
FROM (
    SELECT  Participant_Code, 
            Outage_Reason, 
            Year, 
            COUNT(*) AS Total_Number_Outage_Events, 
            ROUND((AVG(ABS(JULIANDAY(End_Time) - JULIANDAY(Start_Time)))),2) AS Average_Outage_Duration_in_Days
    FROM AEMR_Outage_Table
    WHERE (YEAR=2016 OR Year=2017) 
        AND Status='Approved'
    GROUP BY Participant_Code, 
             Outage_Reason, 
             Year
    ORDER BY Total_Number_Outage_Events DESC, 
             Outage_Reason, 
             Year
    )
ORDER BY Average_Outage_Duration_in_Days DESC;






