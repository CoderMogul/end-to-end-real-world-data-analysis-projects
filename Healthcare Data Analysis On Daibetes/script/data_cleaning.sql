-- STEP 1 : Check for null values and '?'

    
SELECT race, weight, payer_code, medical_specialty, diag_1, diag_2, diag_3
FROM diabetic_data_raw
WHERE race = '?' OR weight = '?' OR payer_code = '?' 
   OR medical_specialty = '?' OR diag_1 = '?' OR diag_2 = '?' OR diag_3 = '?';

-- Checking columns to see if they are nullable and their data types
SELECT COLUMN_NAME, IS_NULLABLE, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'diabetic_data_raw'
  AND COLUMN_NAME IN ('race', 'weight', 'payer_code', 'medical_specialty', 'diag_1', 'diag_2', 'diag_3');

-- Checking the maximum length of the columns to ensure they can accommodate the data
SELECT COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'diabetic_data_raw'
  AND COLUMN_NAME IN ('race', 'weight', 'payer_code', 'medical_specialty', 'diag_1', 'diag_2', 'diag_3');

-- Ensuring that the columns can accommodate the data and null values by altering their data types if necessary
ALTER TABLE diabetic_data_raw ALTER COLUMN race NVARCHAR(50) NULL;
ALTER TABLE diabetic_data_raw ALTER COLUMN weight NVARCHAR(50) NULL;
ALTER TABLE diabetic_data_raw ALTER COLUMN payer_code NVARCHAR(50) NULL;
ALTER TABLE diabetic_data_raw ALTER COLUMN medical_specialty NVARCHAR(50) NULL;
ALTER TABLE diabetic_data_raw ALTER COLUMN diag_1 NVARCHAR(50) NULL;
ALTER TABLE diabetic_data_raw ALTER COLUMN diag_2 NVARCHAR(50) NULL;
ALTER TABLE diabetic_data_raw ALTER COLUMN diag_3 NVARCHAR(50) NULL;


-- STEP 2 : Replace '?' with NULL in the specified columns  
UPDATE diabetic_data_raw
SET race = NULLIF(race, '?'),
    weight = NULLIF(weight, '?'),
    payer_code = NULLIF(payer_code, '?'),
    medical_specialty = NULLIF(medical_specialty, '?'),
    diag_1 = NULLIF(diag_1, '?'),
    diag_2 = NULLIF(diag_2, '?'),
    diag_3 = NULLIF(diag_3, '?');



  
UPDATE diabetic_data_raw
SET race = NULLIF(race, '?'),
    weight = NULLIF(weight, '?'),
    payer_code = NULLIF(payer_code, '?'),
    medical_specialty = NULLIF(medical_specialty, '?'),
    diag_1 = NULLIF(diag_1, '?'),
    diag_2 = NULLIF(diag_2, '?'),
    diag_3 = NULLIF(diag_3, '?');

-- ==================================
-- DATA CLEANING AND SANITY CHECKS
-- =================================


-- STEP 1: Calculaate the percentage of null values in the specified columns
SELECT
    ROUND(SUM(CASE WHEN weight IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_weight,
    ROUND(SUM(CASE WHEN race IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_race,
    ROUND(SUM(CASE WHEN payer_code IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_payer_code,
    ROUND(SUM(CASE WHEN medical_specialty IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_medical_specialty,
    ROUND(SUM(CASE WHEN diag_1 IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_diag_1,
    ROUND(SUM(CASE WHEN diag_2 IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_diag_2,
    ROUND(SUM(CASE WHEN diag_3 IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_diag_3
FROM diabetic_data_raw;

-- ======================================================================================================================================
-- STEP 2: Tracking any duplicate patient encounter IDs in the dataset
SELECT TOP 10 
  patient_nbr,
    COUNT(*) AS encounter_count
FROM diabetic_data_raw
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY encounter_count DESC;

-- Find the first encounter of each patient and create a new table with only the first encounters
SELECT t.*
INTO diabetic_data_dedup
FROM diabetic_data_raw t
INNER JOIN (
    SELECT 
        patient_nbr,
        MIN(encounter_id) AS first_encounter
    FROM diabetic_data_raw
    GROUP BY patient_nbr) AS first_encounters 
ON t.patient_nbr = first_encounters.patient_nbr 
AND t.encounter_id = first_encounters.first_encounter 

-- Show the count of the diabetic_data_dedup table to ensure that the duplicates have been removed
SELECT COUNT(*) AS dedup_count
FROM diabetic_data_dedup;

-- ======================================================================================================================================
-- STEP 3: Remove encounters that can not be readmitted (i.e. those with discharge_disposition_id = 11, 13, 14, 19, 20, 21)

--view the discharge_disposition_id values and their counts to understand the distribution of discharge dispositions in the dataset
SELECT 
   discharge_disposition_id,
   COUNT(*) AS encounter_count
FROM diabetic_data_raw
GROUP BY discharge_disposition_id
ORDER BY encounter_count DESC;

-- Check for the ids that can not be readmitted (i.e. those with discharge_disposition_id = 11, 13, 14, 19, 20, 21)
SELECT *
FROM discharge_disposition
WHERE description LIKE '%hospice%'
   OR description LIKE '%expired%'
   OR description LIKE '%deceased%';

-- DELETE the encounters that can not be readmitted diabetic_data_dedup table 
DELETE FROM diabetic_data_dedup
WHERE discharge_disposition_id IN (11, 13, 14, 19, 20, 21);

-- ======================================================================================================================================
-- STEP 5: Change the age bracket to the midpoint of the age range for better analysis

SELECT TOP 50 *
FROM diabetic_data_dedup;

-- Alter the table to include a new column for the age midpoint
ALTER TABLE diabetic_data_dedup
ADD age_midpoint INT;

-- update the age midpoint column with the midpoint of the age range
UPDATE diabetic_data_dedup
SET age_midpoint = CASE 
    WHEN age = '[0-10)' THEN 5
    WHEN age = '[10-20)' THEN 15
    WHEN age = '[20-30)' THEN 25
    WHEN age = '[30-40)' THEN 35
    WHEN age = '[40-50)' THEN 45
    WHEN age = '[50-60)' THEN 55
    WHEN age = '[60-70)' THEN 65
    WHEN age = '[70-80)' THEN 75
    WHEN age = '[80-90)' THEN 85
    WHEN age = '[90-100)' THEN 95
    ELSE NULL
END;
