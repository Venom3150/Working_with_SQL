# Working_with_SQL
## Overview
The primary objective of this project is to clean, standardize, and analyze a dataset of global layoffs to extract meaningful insights about patterns in layoffs across industries, countries, and companies over time.

## Dataset Used
- Name: `layoffs.csv`
- Description: The dataset contains records of employee layoffs across various companies, industries, countries, and timeframes, with features such as `company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, and `funds_raised_millions`.
- [Dataset](https://github.com/Venom3150/Working_with_SQL/blob/main/layoffs.csv)

## Part 1: Data Cleaning 
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

3. Standardizing Text Fields
- Removed extra spaces in company, industry, and country.
- Standardized entries like Crypto... to just Crypto.
- Removed trailing dots in country names.
- Converted the date field from text format to MySQL DATE type using STR_TO_DATE.
- Identified and deleted rows where both total_laid_off and percentage_laid_off were missing.

```sql
# STANDARDIZE THE DATABASE 
SELECT*
FROM working_database2;

SELECT DISTINCT(company) 
FROM working_database2;

UPDATE working_database2
SET company = TRIM(company);

SELECT DISTINCT(industry)
FROM working_database2
ORDER BY 1;


UPDATE working_database2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT(country)
FROM working_database2
ORDER BY 1;

SELECT country, TRIM(trailing '.' FROM country)
FROM working_database2;

UPDATE working_database2
SET country = TRIM(trailing '.' FROM  country);

# date formatting 
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM working_database2;


UPDATE working_database2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Changing the datatype of some column
ALTER TABLE working_database2
MODIFY COLUMN `date` DATE;

-- Standardize blank industry fields by converting them to NULL
UPDATE working_database2 
SET industry = NULL
WHERE industry = '';
```
Find rows with no data for both `total_laid_off` and `percentage_laid_off`
``` sql
SELECT * 
FROM working_database2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
```

Identify rows where industry is either NULL or blank
```sql
SELECT *
FROM working_database2
WHERE industry IS NULL
   OR industry = '';
```

Inspect all entries for companies that start with 'Airbnb'
```sql
SELECT * 
FROM working_database2
WHERE company LIKE 'Airbnb%';
```

Find rows where industry is missing but can be inferred from other entries with the same company and location
```sql
SELECT *
FROM working_database2 tab1
JOIN working_database2 tab2
  ON tab1.company = tab2.company
 AND tab1.location = tab2.location
WHERE (tab1.industry IS NULL OR tab1.industry = '')
  AND tab2.industry IS NOT NULL;
```

Preview mismatched industry values: NULL vs actual values (for review before updating)
```sql
SELECT tab1.industry, tab2.industry
FROM working_database2 tab1
JOIN working_database2 tab2
  ON tab1.company = tab2.company
 AND tab1.location = tab2.location
WHERE (tab1.industry IS NULL OR tab1.industry = '')
  AND tab2.industry IS NOT NULL;
```

Impute missing industry data from matching company (and optionally location) entries
```sql
UPDATE working_database2 tab1
JOIN working_database2 tab2
  ON tab1.company = tab2.company 
SET tab1.industry = tab2.industry
WHERE (tab1.industry IS NULL OR tab1.industry = '')
  AND tab2.industry IS NOT NULL;
```

Re-check rows that still lack layoff data after previous fixes
``` sql
SELECT * 
FROM working_database2
WHERE total_laid_off IS NULL 
  AND percentage_laid_off IS NULL;
```

Delete rows that have no layoff data (completely non-informative)
``` sql
DELETE
FROM working_database2
WHERE total_laid_off IS NULL 
  AND percentage_laid_off IS NULL;
Top companies with the highest layoffs:
```sql
SELECT company, SUM(total_laid_off) 
FROM working_database2
GROUP BY company
ORDER BY 2 DESC;
```

## Removed helper column `row_num`.
Ensured a clean dataset is ready for analysis.
```sql
ALTER TABLE working_database2
DROP COLUMN row_num;
```


## Part 2: Exploratory Data Analysis

Industries most affected by layoffs:
```sql
SELECT industry, SUM(total_laid_off)
FROM working_database2
GROUP BY industry
ORDER BY 2 DESC;
```

Countries with the most layoffs:
```sql
SELECT country, SUM(total_laid_off)
FROM working_database2
GROUP BY country
ORDER BY 2 DESC;
```

Layoffs with time:
```sql
-- BY YEAR
SELECT YEAR(`date`) AS `YEAR`, SUM(total_laid_off) 
FROM working_database2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

-- BY MONTH
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM working_database2
WHERE SUBSTRING(`date`,1,7)  IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ;
```

With rolling monthly total using window function
```sql
WITH rolling_total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) as laid_off
FROM working_database2
WHERE SUBSTRING(`date`,1,7)  IS NOT NULL
GROUP BY `MONTH`
)

SELECT * , 
SUM(laid_off) OVER(ORDER BY `MONTH`) AS roll_total
FROM rolling_total;

```

Used `DENSE_RANK()` to find top 5 companies by layoffs each year:
```sql
WITH company_rank AS(
SELECT company, YEAR(`date`) AS years, SUM(total_laid_off) as total_laid_off
FROM working_database2
GROUP BY company, YEAR(`date`)
), ranking AS(
SELECT *,
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) as ranking
FROM company_rank
WHERE years IS NOT NULL)

SELECT* 
FROM ranking
WHERE ranking <= 5;
```

## Conclusion
This project demonstrates the end-to-end process of transforming raw and messy data into a structured and insightful format. From identifying duplicates and cleaning inconsistent text fields to formatting dates and analyzing global layoff trends, this SQL-based project provides a strong foundation for further visualization or predictive modeling.







