--------------------------------------------------------------------------------------------------------------------------
-- PART 4: Business Question
--------------------------------------------------------------------------------------------------------------------------

-- Problem Statement:
-- If you were to launch a new YouTube channel tomorrow, which category (excluding “Music” and “Entertainment”)
-- of video will you be trying to create to have them appear in the top trend of YouTube?
-- Will this strategy work in every country?
--------------------------------------------------------------------------------------------------------------------------

------------------------------------------
-- Step 1: Identify top-performing categories globally (excluding Music & Entertainment).
-- This helps us see which categories attract the highest number of trending videos and average views overall.
------------------------------------------
SELECT 
    category_title,
    COUNT(DISTINCT video_id) AS distinct_videos,  -- How many unique trending videos belong to each category
    ROUND(AVG(view_count), 0) AS avg_views        -- Average views per video in the category
FROM table_youtube_final
WHERE category_title NOT IN ('Music', 'Entertainment')
GROUP BY category_title
ORDER BY distinct_videos DESC, avg_views DESC;

-- Insight: Shows globally popular categories that could be good candidates for a new channel.

-------------------------------------------------
-- Step 2: Find the Top 3 categories for each country (excluding Music & Entertainment).
-- This checks whether the same categories dominate in all countries or vary by region.
-------------------------------------------------
SELECT country,
       category_title,
       distinct_videos
FROM (
    SELECT 
        country,
        category_title,
        COUNT(DISTINCT video_id) AS distinct_videos,  -- Unique trending videos in that category per country
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY COUNT(DISTINCT video_id) DESC) AS rn
    FROM table_youtube_final
    WHERE category_title NOT IN ('Music', 'Entertainment')
    GROUP BY country, category_title
) t
WHERE rn <= 3
ORDER BY country, distinct_videos DESC;

-- Insight: Identifies each country’s top 3 trending categories.
-- Helps answer whether one global strategy will work everywhere, or if categories differ locally.

------------------------------------------------------------------------
-- Step 3: Aggregate the Top 3 results across all countries.
-- This counts how often each category appears in the Top 1, Top 2, or Top 3 spots across different countries.
------------------------------------------------------------------------
WITH top3 AS (
    SELECT 
        country,
        category_title,
        COUNT(DISTINCT video_id) AS distinct_videos,
        ROW_NUMBER() OVER (
            PARTITION BY country 
            ORDER BY COUNT(DISTINCT video_id) DESC
        ) AS rn
    FROM table_youtube_final
    WHERE category_title NOT IN ('Music', 'Entertainment')
    GROUP BY country, category_title
)
SELECT 
    category_title,
    SUM(CASE WHEN rn = 1 THEN 1 ELSE 0 END) AS top1_count,  -- How many countries ranked this category #1
    SUM(CASE WHEN rn = 2 THEN 1 ELSE 0 END) AS top2_count,  -- How many countries ranked this category #2
    SUM(CASE WHEN rn = 3 THEN 1 ELSE 0 END) AS top3_count,  -- How many countries ranked this category #3
    COUNT(DISTINCT country) AS total_countries              -- Total countries where the category appeared in Top 3
FROM top3
WHERE rn <= 3
GROUP BY category_title
ORDER BY top1_count DESC, top2_count DESC, top3_count DESC, category_title;

-- Insight: Shows which categories dominate consistently across many countries.
-- If a category has high top1_count across multiple countries, it is a strong global strategy.
-- If categories vary widely, then localised strategy is needed instead of one-size-fits-all.
--------------------------------------------------------------------------------------
