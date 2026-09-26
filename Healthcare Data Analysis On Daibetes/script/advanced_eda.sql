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
WITH patient_medication_triage AS (
    SELECT 
    encounter_id,
    patient_nbr,
    age_midpoint,
    num_medications,
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

