SELECT * 
FROM layoffs;

CREATE TABLE working_database
LIKE layoffs;

SELECT * 
FROM working_database;

INSERT working_database
SELECT *
FROM layoffs;

# Checking duplicates
WITH duplicate_cte AS(
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM working_database)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO working_database2
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM working_database;

DELETE 
FROM working_database2
WHERE row_num > 1;

SELECT * 
FROM working_database2
WHERE row_num > 1;

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

ALTER TABLE working_database2
MODIFY COLUMN `date` DATE;

SELECT * 
FROM working_database2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM working_database2
WHERE industry is null
OR industry = '';


SELECT * 
FROM working_database2
where company like 'Airbnb%';

SELECT *
FROM working_database2 tab1
JOIN working_database2 tab2
	ON tab1.company = tab2.company
    AND tab1.location = tab2.location
WHERE (tab1.industry IS NULL OR tab1.industry = '')
AND tab2.industry IS NOT NULL;


SELECT tab1.industry, tab2.industry
FROM working_database2 tab1
JOIN working_database2 tab2
	ON tab1.company = tab2.company
    AND tab1.location = tab2.location
WHERE (tab1.industry IS NULL OR tab1.industry = '')
AND tab2.industry IS NOT NULL;

UPDATE working_database2 
SET industry = NULL
WHERE industry = '';


UPDATE working_database2 tab1
JOIN working_database2 tab2
	ON tab1.company = tab2.company 
SET tab1.industry = tab2.industry
WHERE (tab1.industry IS NULL OR tab1.industry = '')
AND tab2.industry IS NOT NULL;


SELECT * 
FROM working_database2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;


DELETE
FROM working_database2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;


SELECT * 
FROM working_database2;

ALTER TABLE working_database2
DROP COLUMN row_num;



SELECT* 
FROM working_database2;


SELECT company, SUM(total_laid_off) 
FROM working_database2
GROUP BY company
ORDER BY 2 DESC;


SELECT industry, SUM(total_laid_off)
FROM working_database2
GROUP BY industry
ORDER BY 2 DESC;

SELECT country, SUM(total_laid_off)
FROM working_database2
GROUP BY country
ORDER BY 2 DESC;

SELECT `date`, Max(total_laid_off) 
FROM working_database2
GROUP BY `date`
ORDER BY 2 DESC;

SELECT `date`, SUM(total_laid_off) 
FROM working_database2
GROUP BY `date`
ORDER BY 2 DESC;

SELECT YEAR(`date`) AS `YEAR`, SUM(total_laid_off) 
FROM working_database2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;



SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM working_database2
WHERE SUBSTRING(`date`,1,7)  IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ;


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


SELECT * 
FROM working_database2;

SELECT company, YEAR(`date`), SUM(total_laid_off) 
FROM working_database2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;


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





