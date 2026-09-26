-- =================
-- ADVANCED EDA
-- =================

-- Create base CTE for patient risk factors
WITH patient_risk_base AS (
    SELECT
        encounter_id,
        patient_nbr,
        age_midpoint,
        time_in_hospital,
        num_medications,
        num_lab_procedures,
        number_diagnoses,
        number_inpatient,
        number_emergency,
        number_outpatient,
        diag_1,
        readmitted,
        CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END AS readmitted_flag      
    FROM diabetic_data_dedup
)

SELECT TOP 20 * FROM patient_risk_base


-- =================================================================================================================
-- Create a triage sort for the health team to prioritize age bracket of patients with the highest medication count
-- =================================================================================================================
/* A 30 year old on 8 medication don't post the same risk as an 80 year old on 8 medication.*/


WITH patient_medication_triage AS (
    SELECT 
    encounter_id,
    patient_nbr,
    age_midpoint,
    num_medications,
    readmitted,
    CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END AS readmitted_flag      
    FROM diabetic_data_dedup
)
SELECT TOP 200
    encounter_id,
    age_midpoint,
    num_medications,
    RANK() OVER (PARTITION BY age_midpoint ORDER BY num_medications DESC) AS med_rank_by_age_group
FROM patient_medication_triage
ORDER BY  age_midpoint, med_rank_by_age_group;

-- ========================================================================================================================================
-- Population Level Segmentation. Senior Care Management want a small group of the population they can act on and not the total population.
-- ========================================================================================================================================

-- Using Ntile to split the total population into a specified group number where the first is the most at risk - hospital risk stratification.
/*Fist quartile is the group a care team will prioritize follow up for outreach 
since prior impatient visit is a one of the strongest predictors for future readmission
*/


WITH patient_risk_base AS(
    SELECT
        encounter_id, number_inpatient, readmitted,
        CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END AS readmitted_flag      
    FROM diabetic_data_dedup
)
SELECT 
    encounter_id,
    number_inpatient,
    readmitted,
    NTILE(4) OVER (ORDER BY number_inpatient DESC) AS risk_quartile
FROM patient_risk_base

-- =========================================================================================================================================
-- Risk tiering for non technical stake holders to understand the differenct risk (Turninig continuous number to business readable category)
-- =========================================================================================================================================

SELECT 
    encounter_id,
    num_medications,
    CASE 
        WHEN num_medications <= 10 THEN 'Low'
        WHEN num_medications BETWEEN 11 AND 20 THEN 'Medium'
        ELSE 'High'
    END AS medication_burden_tier,
    CASE 
        WHEN number_diagnoses <= 5 THEN 'Low Complexity'
        WHEN number_diagnoses BETWEEN 6 AND 8 THEN 'Moderate Complexity'  
        ELSE 'High Complexity'
    END AS diagnosis_complexity_tier
FROM diabetic_data_dedup;


-- ==================================================================
-- Business question 1: Top diagnosis categories driving readmission
-- ==================================================================

/* ICD-9 International Classification of Disease, 9th Revision Code Ranges
-- diag_1 notes
-- 390 - 459: Diseasses of the circulatory system
-- 460 - 519: Disesases of the respiratory system
-- 520 - 579: Diseases of the digestive system
-- 580 - 629: Diseases of the genitourinary system
-- 800 - 999: Injury and poisoning.
*/


WITH diag_categorized AS (
    SELECT
        encounter_id,
        readmitted,
        CASE 
            WHEN diag_1 LIKE '250%' THEN 'Diabetes'
            WHEN LEFT(diag_1,3) NOT LIKE '%[^0-9]%' AND CAST(LEFT(diag_1,3) AS INT) BETWEEN 390 AND 459 THEN 'Circulatory'
            WHEN LEFT(diag_1,3) NOT LIKE '%[^0-9]%' AND CAST(LEFT(diag_1,3) AS INT) BETWEEN 460 AND 519 THEN 'Respiratory'
            WHEN LEFT(diag_1,3) NOT LIKE '%[^0-9]%' AND CAST(LEFT(diag_1,3) AS INT) BETWEEN 520 AND 579 THEN 'Digestive'
            WHEN LEFT(diag_1,3) NOT LIKE '%[^0-9]%' AND CAST(LEFT(diag_1,3) AS INT) BETWEEN 580 AND 629 THEN 'Genitourinary'
            WHEN LEFT(diag_1,3) NOT LIKE '%[^0-9]%' AND CAST(LEFT(diag_1,3) AS INT) BETWEEN 800 AND 999 THEN 'Injury'
            ELSE 'Other'
        END AS diagnosis_category,
        CASE
            WHEN readmitted = '<30' THEN 1
            ELSE 0
        END AS readmitted_flag    
    FROM diabetic_data_dedup
    WHERE diag_1 IS NOT NULL   
)
SELECT  
    diagnosis_category,
    COUNT(*) AS total_encounters,
    CAST(ROUND(AVG(readmitted_flag * 1.0) * 100, 1) AS DECIMAL(5,1)) AS pct_readmission_rate
FROM diag_categorized
GROUP BY diagnosis_category
HAVING AVG(readmitted_flag * 1.0) > (SELECT AVG(readmitted_flag * 1.0) FROM diag_categorized)
ORDER BY pct_readmission_rate DESC;



-- ===============================================================================
-- Business question 2: Does a medication change at discharge affect readmission?
-- ===============================================================================

SELECT 
    [change],
    COUNT(*) AS total_encounters,
    CAST(ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) *1.0 / COUNT(*) *100, 1) AS DECIMAL(5,1)) AS pct_readmission_rate
FROM diabetic_data_dedup
GROUP BY [change];


-- ===============================================================================
-- Business question 3: Does Discharge disposition impact readmission
-- ===============================================================================

SELECT TOP 10
    m.description AS discharge_dispostion,
    COUNT(*) AS total_encounters,
    CAST(ROUND(SUM(CASE WHEN d.readmitted = '<30' THEN 1 ELSE 0 END) *1.0 / COUNT(*) * 100, 1) AS DECIMAL(5,1)) AS pct_readmission_rate
FROM diabetic_data_dedup AS d
JOIN discharge_disposition AS m
ON d.discharge_disposition_id = m.discharge_disposition_id
GROUP BY m.description
HAVING COUNT(*) > 100
ORDER BY pct_readmission_rate DESC;

-- =========================================================================================
-- Business question 4 : Does A1C testing of the hospital lead to readmission outcome
-- =========================================================================================

SELECT 
    A1Cresult,
    COUNT(*) AS total_encounters,
    CAST(ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) *1.0 / COUNT(*) * 100, 1) AS DECIMAL(5,1)) AS pct_readmission_rate
FROM diabetic_data_dedup
GROUP BY A1Cresult

-- (Strong line for the portfolio project)
-- Our finding challenges or lines up with the original research.
