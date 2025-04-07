CREATE SCHEMA Netflix

CREATE DATABASE Netflix

USE Netflix

SELECT * FROM Netflix.Netflix_data;


Select Count(*) as TotalRecords From Netflix.Netflix_data;

SELECT * INTO Netflix.netflix_data_copy
FROM Netflix.netflix_data;

SELECT 
    SUM(CASE WHEN director IS NULL THEN 1 ELSE 0 END) AS MissingDirectors,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS MissingCountries,
    SUM(CASE WHEN date_added IS NULL THEN 1 ELSE 0 END) AS MissingDates,
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS MissingRatings
FROM Netflix.Netflix_data;

ALTER TABLE Netflix.netflix_data
ALTER COLUMN date_added DATE;


SELECT title, release_year, COUNT(*) AS dup_count
FROM Netflix.Netflix_data
GROUP BY title, release_year
HAVING COUNT(*) > 1;

WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY title, director, release_year ORDER BY show_id) AS rn
    FROM Netflix.netflix_data
)
DELETE FROM CTE WHERE rn > 1;

SELECT type, COUNT(*) AS count, 
      TRY_CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Netflix.netflix_data_copy) AS DECIMAL(5,2)) AS percentage
FROM Netflix.netflix_data
GROUP BY type;

Select release_year, COUNT(*) as Content_count
FROM Netflix.netflix_data
GROUP BY release_year
ORDER BY release_year DESC;

SELECT YEAR(date_added) AS year_added, COUNT(*) AS count
FROM Netflix.netflix_data 
GROUP BY YEAR(date_added)
ORDER BY year_added;

SELECT 
    YEAR(date_added) AS year,
    MONTH(date_added) AS month,
    COUNT(*) AS count
FROM Netflix.netflix_data
GROUP BY YEAR(date_added), MONTH(date_added)
ORDER BY year, month;

SELECT top 10 country, count(*) as content_count
FROM Netflix.netflix_data
GROUP BY country 
ORDER BY content_count DESC;

SELECT country, type, COUNT(*) AS count
FROM Netflix.netflix_data 
GROUP BY country, type
ORDER BY country, count DESC;

SELECT 
    TRIM(value) AS genre,
    COUNT(*) AS count
FROM Netflix.netflix_data
CROSS APPLY STRING_SPLIT(listed_in, ',')
GROUP BY TRIM(value)
ORDER BY count DESC;

SELECT TOP 10 director, COUNT(*) AS content_count
FROM Netflix.netflix_data
WHERE director <> 'Not Given'
GROUP BY director
ORDER BY content_count DESC;

WITH GenreDirectors AS (
    SELECT 
        TRIM(value) AS genre,
        director,
        COUNT(*) AS content_count
    FROM Netflix.netflix_data
    CROSS APPLY STRING_SPLIT(listed_in, ',')
    WHERE director <> 'Not Given'
    GROUP BY TRIM(value), director
)
SELECT 
    genre,
    director,
    content_count
FROM (
    SELECT 
        genre,
        director,
        content_count,
        ROW_NUMBER() OVER (PARTITION BY genre ORDER BY content_count DESC) AS rank
    FROM GenreDirectors
) AS ranked
WHERE rank = 1
ORDER BY content_count DESC;

SELECT 
    AVG(TRY_CAST(REPLACE(duration, ' min', '') AS INT)) AS avg_minutes,
    MIN(TRY_CAST(REPLACE(duration, ' min', '') AS INT)) AS min_minutes,
    MAX(TRY_CAST(REPLACE(duration, ' min', '') AS INT)) AS max_minutes
FROM Netflix.netflix_data
WHERE type = 'Movie' AND duration LIKE '%min%';

SELECT 
    AVG(TRY_CAST(REPLACE(REPLACE(duration, ' Seasons', ''), ' Season', '') AS INT)) AS avg_seasons,
	MIN(TRY_CAST(REPLACE(REPLACE(duration, ' Seasons', ''), ' Season', '') AS INT)) AS min_seasons,
    MAX(TRY_CAST(REPLACE(REPLACE(duration, ' Seasons', ''), ' Season', '') AS INT)) AS max_seasons
FROM Netflix.netflix_data
WHERE type = 'TV Show' AND duration LIKE '%Season%';

SELECT type, rating, COUNT(*) AS count
FROM Netflix.netflix_data
GROUP BY type, rating
ORDER BY type, count DESC;

SELECT 
    YEAR(date_added) AS year,
    rating,
    COUNT(*) AS count
FROM Netflix.netflix_data
WHERE date_added IS NOT NULL
GROUP BY YEAR(date_added), rating
ORDER BY year, count DESC;

SELECT 
    country,
    SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS tv_shows,
    SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) AS movies,
    CAST(SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS tv_to_movie_ratio
FROM Netflix.netflix_data
GROUP BY country
HAVING COUNT(*) > 50
ORDER BY tv_to_movie_ratio DESC;
