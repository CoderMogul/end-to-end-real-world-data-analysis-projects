<div align="center">
  <h1>
    Hospital Readmission Risk Analysis
  </h1>
</div>

<p align="center">
  <img src="https://img.shields.io/badge/SQL-Advanced%20Analytics-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/Database-SQL%20SERVER-orange?style=flat-square"/>
  <img src="https://img.shields.io/badge/Connection-VSCode-purple?style=flat-square"/>
</p>

---

<p align="center">
  <img src="images/public-domain-vectors-7B3GPv6kgwU-unsplash.jpg" alt="Hospital exterior" width="250"/>
</p>

## 🧠 Business Problem

Readmitting a patient within 30 days of discharge isn't just a clinical setback — 
it's a costly one, triggering financial penalties for hospitals under federal 
quality programs. Drawing on 10 years of encounter records from 130 U.S. hospitals, 
this project investigates which patient profiles, diagnoses, and treatment decisions 
are most predictive of early readmission, with the goal of surfacing actionable 
risk patterns.

---

## 🎯 Objective

This project aims to help care teams proactively identify patients at elevated 
risk of 30-day readmission. Specifically, it sets out to:

- Identify the diagnoses, demographics, and care patterns most strongly 
  associated with readmission risk
- Surface patterns that could help focus follow-up resources on high-risk patients
- Provide a data-driven basis for reducing avoidable readmissions

---

## 📊 Data & Inputs

- **Dataset**: Diabetes 130-US Hospitals for Years 1999–2008 (UCI Machine Learning 
  Repository, CC BY 4.0) — ~100,000 patient encounters across 130 hospitals, 1999–2008
- **Format**: Raw CSV files, including a separate ID mapping file for admission type, 
  admission source, and discharge disposition codes
- **Database**: Microsoft SQL Server
- **Tools**: Python (pandas, pyodbc) for data loading and preprocessing; T-SQL for 
  data cleaning, transformation, and analysis

---

## ⚙️ Technical Approach

- **Cleaning**: Replaced placeholder missing values with NULLs, removed a column 
  (`weight`) with ~97% missing data, deduplicated to one encounter per patient 
  (~100,000 → ~70,000 encounters) to avoid duplicate bias, and excluded patients 
  who were inactive or discharged to hospice
- **Exploratory Analysis**: Established baseline readmission rates by age 
  (`age_midpoint`), admission type, and diagnosis category
- **Advanced Analysis**: Built a reusable high-risk patient segment using a CTE, 
  applied window functions to rank and stratify patients by risk, grouped patients 
  by medication use and number of diagnoses, and identified diagnosis categories 
  with above-average readmission rates
- **Findings**: Summarized results into four key findings that connect back to 
  the core business problem

---

## 🔍 Key Findings

### 1. Injury and Circulatory diagnoses carry the highest readmission risk
Among primary diagnosis categories, **Injury** (10.8%) and **Circulatory** 
(9.7%) conditions showed the highest 30-day readmission rates — both above 
the diabetes-specific readmission rate (9.1%) itself. This suggests care 
teams may benefit from closer discharge planning for patients admitted with 
trauma or cardiovascular conditions, not just those with a primary diabetes 
diagnosis.

### 2. Discharge disposition is the strongest predictor identified
Readmission risk varied dramatically by where a patient was discharged to. 
Patients discharged to another **rehabilitation facility** were readmitted 
at **26.3%** — nearly four times the rate of patients discharged directly 
**home** (6.9%). Transfers to another short-term hospital (13.8%) and 
skilled nursing facilities (13.4%) also showed elevated risk. This points 
to post-acute care transitions as a key area for readmission-reduction efforts.

### 3. A medication change at discharge shows a modest association with readmission
Patients whose diabetes medication was changed during their stay had a 
slightly higher readmission rate (9.4%) than those with no medication 
change (8.6%). The difference is real but modest, suggesting medication 
adjustment alone is not a strong standalone predictor.

### 4. A1C testing status shows a counterintuitive pattern
Patients with **no A1C test recorded** had the highest readmission rate 
(9.1%), while those with results indicating poor glucose control (`>8`) 
had the lowest (8.2%). Rather than suggesting poor glucose control is 
protective, this likely reflects that patients who receive A1C testing 
benefit from more thorough overall clinical engagement — a pattern also 
noted in the original research behind this dataset. This suggests testing 
practices themselves may be a meaningful lever for reducing readmissions, 
independent of the result.

### Summary
These findings suggest that discharge planning — particularly for patients 
transferred to rehab or skilled nursing facilities — may offer the highest 
leverage for reducing avoidable 30-day readmissions, alongside closer 
monitoring for Injury and Circulatory diagnoses.

---

## 🛠 Key Skills Demonstrated

- Python to parse and load the ID-mapping reference data into separate SQL Server 
  tables, including database connectivity via `pyodbc`
- CTEs to stage a clean, reusable risk cohort across multiple queries
- Window functions: `RANK() OVER (PARTITION BY ...)` to rank medication burden 
  within age groups, and `NTILE(4)` to stratify patients into risk quartiles by 
  prior inpatient visit history
- CASE-based tiering to convert continuous variables (medication count, diagnosis 
  count) into business-readable risk categories
- Correlated subqueries with `HAVING` to isolate diagnosis categories performing 
  above the population-wide average
- Multi-table joins against ID-mapping reference tables to convert numeric codes 
  into readable labels
- Applied three complementary risk-segmentation approaches — ranked triage, 
  quartile stratification, and tiered categorization — suited to different 
  stakeholder needs (clinical prioritization vs. population-level targeting 
  vs. non-technical reporting)
- Cross-dialect SQL fluency — translated queries between MySQL and T-SQL syntax, 
  including identifier quoting, boolean aggregation, and data type differences

---

## 🧩 Challenges & Key Learnings

### 1. Integer Division Silently Truncating Aggregate Results
Calculating readmission percentages with `AVG()` on an integer 0/1 flag column 
returned `0` for every group, despite the underlying data clearly containing 
readmitted cases.

**Fix**: Forced decimal arithmetic by multiplying the flag column by `1.0` 
before aggregating (`AVG(readmitted_flag * 1.0)`).

**Takeaway**: Integer division is a common, silent source of wrong results in 
SQL — any division or averaging involving whole-number columns should be 
treated as a risk area by default.

---

### 2. Safely Casting Mixed Alphanumeric Diagnosis Codes
ICD-9 diagnosis codes aren't purely numeric — V-codes (`V45`) and E-codes 
(`E849`) exist alongside standard numeric codes. Casting these directly to 
`INT` for range-based categorization would throw a runtime error and halt 
the query.

**Fix**: Added a pattern-matching guard (`LEFT(diag_1,3) NOT LIKE '%[^0-9]%'`) 
to confirm a value was purely numeric before attempting the cast, letting 
non-numeric codes fall through safely to an "Other" category.

**Takeaway**: When casting real-world codes to a numeric type, validate the 
format first — don't assume every value will conform.

---

### 3. NULL Handling Across the Python–SQL Boundary
Converting placeholder text (`"NULL"`) to a true missing value in pandas 
produced `NaN` — a float — rather than Python's `None`. SQL Server rejected 
this with a data type error on insert, since it was receiving a float, not 
a null string.

**Fix**: Explicitly checked for `NaN` with `pd.isna()` and converted it to 
`None` immediately before insertion, so `pyodbc` correctly passed a true SQL 
`NULL`.

**Takeaway**: A missing value isn't represented the same way across tools — 
`NaN`, `None`, and SQL `NULL` are related but distinct, and crossing between 
pandas and a database requires explicit handling.

---

### 4. NOT NULL Constraints Blocking Legitimate Data Cleaning
Several source columns (`weight`, `race`, `payer_code`, lookup table 
descriptions) were auto-created as `NOT NULL` during import, which blocked 
converting placeholder values (`'?'`, `'NULL'`) into true SQL `NULL`.

**Fix**: Used `ALTER TABLE ... ALTER COLUMN ... NULL` to relax the constraint 
before running the corresponding `UPDATE` statement.

**Takeaway**: Structural rules (table schema) and data values are two separate 
layers — cleaning data sometimes requires changing the rules first, not just 
the values.

---

### 5. Multi-Section CSV Parsing
The ID-mapping reference file (admission type, admission source, discharge 
disposition) contained three separate lookup tables stacked in a single CSV, 
each with its own header row. A standard import treated later headers as data 
rows, causing type-conversion errors.

**Fix**: Parsed the file line-by-line in Python, detecting section boundaries 
by matching known header names, and routed each block into its own DataFrame 
and target table.

**Takeaway**: Don't assume one file equals one table — inspect raw file 
structure before trusting an automated import tool.