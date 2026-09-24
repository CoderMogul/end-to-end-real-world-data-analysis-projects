-- =======================================
-- EXPLORATORY DATA ANALYSIS (EDA) SCRIPT
-- =======================================
/*What does the overall readmission data look like? What are the distributions of the various features?
 Are there any patterns or trends that can be observed in the data?
 Readmission have 3 outcomes: 0 (no readmission), 1 (readmission within 30 days), and 2 (readmission after 30 days).

Problem Statement: The goal of this analysis is to understand the factors that contribute to hospital readmissions for diabetic patients. 
What penalizes Hospitals is the readmission of patients within 30 days of discharge. 
Therefore, we will focus on the readmission outcome of 1 (readmission within 30 days) 
and compare it to the other two outcomes (0 and 2) to identify any significant differences in patient characteristics, 
treatment patterns, and other factors that may contribute to readmissions.
*/

SELECT 
    readmitted,
    COUNT(*) AS encounter_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM diabetic_data_dedup), 2) AS pct_encounters
FROM diabetic_data_dedup
GROUP BY readmitted
ORDER BY encounter_count DESC;


-- Find the Readmission rate by the age
SELECT
    age,
    age_midpoint,
    COUNT(*) AS encounter_count,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under_30,
    ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_readmitted_under_30
FROM diabetic_data_dedup
GROUP BY age, age_midpoint
ORDER BY age_midpoint;




SELECT
    'Admission Type' AS category_type,
    t.description AS category_value,
    COUNT(*) AS encounter_count,
    ROUND(SUM(CASE WHEN d.readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_readmitted_under_30
FROM diabetic_data_dedup d
JOIN admission_type AS t
    ON d.admission_type_id = t.admission_type_id
GROUP BY t.description

UNION ALL

SELECT
    'Admission Source' AS category_type,
    s.description AS category_value,
    COUNT(*) AS encounter_count,
    ROUND(SUM(CASE WHEN d.readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_readmitted_under_30
FROM diabetic_data_dedup d
JOIN admission_source AS s
    ON d.admission_source_id = s.admission_source_id
GROUP BY s.description

UNION ALL

SELECT
    'Discharge Disposition' AS category_type,
    dd.description AS category_value,
    COUNT(*) AS encounter_count,
    ROUND(SUM(CASE WHEN d.readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_readmitted_under_30
FROM diabetic_data_dedup d
JOIN discharge_disposition AS dd
    ON d.discharge_disposition_id = dd.discharge_disposition_id
GROUP BY dd.description

ORDER BY category_type, pct_readmitted_under_30 DESC;