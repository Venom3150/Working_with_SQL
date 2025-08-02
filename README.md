# Working_with_SQL
## Overview
The primary objective of this project is to clean, standardize, and analyze a dataset of global layoffs to extract meaningful insights about patterns in layoffs across industries, countries, and companies over time.

## Dataset Used
Name: `layoffs.csv`
Description: The dataset contains records of employee layoffs across various companies, industries, countries, and timeframes, with features such as `company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, and `funds_raised_millions`.

## 1. Copying Original Table
Created a working copy of the dataset to preserve the raw data using:
```sql
CREATE TABLE working_database
LIKE layoffs;
---
INSERT working_database
SELECT *
FROM layoffs;
```

## 2.Handling Duplicates
- Identified duplicates using `ROW_NUMBER()` window function.
```sql
-- Checking duplicates
WITH duplicate_cte AS(
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM working_database)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
```
Removed duplicates by creating the copy of working database as  `working_database2` and deleting where `row_num` > 1.
```sql
CREATE TABLE `working_database2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` INT
) 
INSERT INTO working_database2
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM working_database;


-- Removing the duplicate rows
DELETE 
FROM working_database2
WHERE row_num > 1;

```








