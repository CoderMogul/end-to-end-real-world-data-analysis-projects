/*
====================================================
Create the mapping tables for the ids in the dataset
====================================================
*/  

IF OBJECT_ID('dbo.admission_type', 'U') IS NOT NULL
    DROP TABLE dbo.admission_type;
GO

CREATE TABLE dbo.admission_type (
    admission_type_id INT PRIMARY KEY,
    description VARCHAR(255) NOT NULL
);

IF OBJECT_ID('dbo.discharge_disposition', 'U') IS NOT NULL
    DROP TABLE dbo.discharge_disposition;
GO

CREATE TABLE dbo.discharge_disposition (
    discharge_disposition_id INT PRIMARY KEY,
    description VARCHAR(255) NOT NULL
);

IF OBJECT_ID('dbo.admission_source', 'U') IS NOT NULL
    DROP TABLE dbo.admission_source;   
GO

CREATE TABLE dbo.admission_source (
    admission_source_id INT PRIMARY KEY,
    description VARCHAR(255) NOT NULL
);
