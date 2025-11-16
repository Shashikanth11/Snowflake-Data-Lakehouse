--------------------------------------------------------------------------------------------------------------------------
-- PART 3: Data Analysis
--------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------
-- 1. Top 3 Videos by Views per Country on a Specific Date (2024-04-01) and category (Gaming)
--    - Selects trending gaming videos on 2024-04-01
--    - Ranks videos by view_count within each country
--    - Returns the top 3 per country
---------------------------------------------------------------
WITH ranked AS (
    SELECT 
        country,
        title,
        channeltitle,
        view_count,
        ROW_NUMBER() OVER ( PARTITION BY country ORDER BY view_count DESC ) AS rk
    FROM table_youtube_final
    WHERE trending_date = '2024-04-01'
      AND LOWER(category_title) = 'gaming'
)
SELECT *
FROM ranked
WHERE rk <= 3
ORDER BY country, rk;

---------------------------------------------------------------
-- 2. BTS Mentioned videos for Country
--    - Counts distinct videos mentioning "BTS" in the title
--    - Groups by country and orders by highest counts
---------------------------------------------------------------
SELECT 
    country,
    COUNT(DISTINCT video_id) AS ct
FROM table_youtube_final
WHERE LOWER(title) LIKE '%bts%'
GROUP BY country
ORDER BY ct DESC;

---------------------------------------------------------------
-- 3. Monthly Most Viewed Video per Country (2024)
--    - Finds the most viewed video per country per month in 2024
--    - Includes title, channel, category, view count
--    - Calculates likes-to-views ratio (%)
---------------------------------------------------------------
SELECT country,
       TO_CHAR(DATE_TRUNC('MONTH', trending_date), 'YYYY-MM-DD') AS year_month,
       title,
       channeltitle,
       category_title,
       view_count,
       TO_CHAR(
           ROUND((CAST(likes AS FLOAT) / NULLIF(view_count,0)) * 100, 2),
           '999.00'
       ) AS likes_ratio
FROM (
    SELECT f.*,
           ROW_NUMBER() OVER (
               PARTITION BY country, DATE_TRUNC('MONTH', trending_date)
               ORDER BY view_count DESC
           ) AS rn
    FROM table_youtube_final f
    WHERE EXTRACT(YEAR FROM trending_date) = 2024
) t
WHERE rn = 1
ORDER BY year_month, country;

---------------------------------------------------------------
-- 4. Most Popular Category per Country (since 2022)
--    - Counts distinct videos by category and country
--    - Calculates percentage share of each category within the country
--    - Identifies top-ranked category per country
---------------------------------------------------------------
WITH country_category_counts AS (
    SELECT 
        country,
        category_title,
        COUNT(DISTINCT video_id) AS category_videos
    FROM table_youtube_final
    WHERE EXTRACT(YEAR FROM trending_date) >= 2022
    GROUP BY country, category_title
),
country_totals AS (
    SELECT 
        country,
        COUNT(DISTINCT video_id) AS total_country_videos
    FROM table_youtube_final
    WHERE EXTRACT(YEAR FROM trending_date) >= 2022
    GROUP BY country
),
ranked_categories AS (
    SELECT 
        ccc.country,
        ccc.category_title,
        ccc.category_videos,
        ct.total_country_videos,
        TO_CHAR(ROUND((ccc.category_videos * 100.0 / ct.total_country_videos), 2), '999.00') AS percentage,
        ROW_NUMBER() OVER (PARTITION BY ccc.country ORDER BY ccc.category_videos DESC) AS rn
    FROM country_category_counts ccc
    JOIN country_totals ct
      ON ccc.country = ct.country
)
SELECT country, category_title, category_videos, total_country_videos, percentage
FROM ranked_categories
WHERE rn = 1
ORDER BY category_title,country;

---------------------------------------------------------------
-- 5. Channel with Most Distinct Videos
--    - Finds the channel with the highest number of unique uploaded videos
--    - Returns channel title and count of distinct video IDs
---------------------------------------------------------------
SELECT 
    channeltitle,
    COUNT(DISTINCT video_id) AS distinct_videos
FROM table_youtube_final
GROUP BY channeltitle
ORDER BY distinct_videos DESC
LIMIT 1;
