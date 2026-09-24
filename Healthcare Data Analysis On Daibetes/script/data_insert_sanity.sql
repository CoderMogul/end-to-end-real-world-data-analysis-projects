SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('diabetic_data_raw', 'admission_type', 'discharge_disposition', 'admission_source')
ORDER BY TABLE_NAME, ORDINAL_POSITION;


SELECT * 
FROM admission_type;

SELECT COUNT(*)
FROM diabetic_data_raw;

SELECT TOP 10 *
FROM diabetic_data_raw;