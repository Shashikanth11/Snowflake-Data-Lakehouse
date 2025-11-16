--------------------------------------------------------------------------------------------------------------------------
-- PART 2: Data Cleaning
--------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------
-- Q1. In “table_youtube_category” which category_title has duplicates 
-- if we don’t take into account the categoryId 
-- return only a single row
-------------------------------------------------
SELECT category_title
FROM table_youtube_category
GROUP BY category_title
HAVING COUNT(DISTINCT categoryId) > 1
LIMIT 1;

-------------------------------------------------
-- Q2. In “table_youtube_category” which category_title 
-- only appears in one country? (added categoryId for future reference)
-------------------------------------------------
SELECT category_title
FROM table_youtube_category
GROUP BY category_title
HAVING COUNT(DISTINCT country) = 1;

-------------------------------------------------
-- Q3. In “table_youtube_final”, what is the categoryId 
-- of the missing category_titles?
-------------------------------------------------
SELECT DISTINCT categoryId
FROM table_youtube_final
WHERE category_title IS NULL;

-------------------------------------------------
-- Q4. Update the table_youtube_final to replace the NULL values 
-- in category_title with the answer from the previous question.
-------------------------------------------------

-- Check sample rows with categoryId=29 that have missing titles
select * from table_youtube_final where categoryId=29;

-- Cross-reference with table_youtube_category for categoryId=29
select * from table_youtube_category where categoryId=29;

-- Update NULL category_title values in table_youtube_final by looking up the corresponding title from table_youtube_category
UPDATE table_youtube_final f
SET category_title = (
    SELECT MAX(c.category_title)  -- used MAX to avoid errors if multiple matches
    FROM table_youtube_category c
    WHERE c.categoryId = f.categoryId
)
WHERE f.category_title IS NULL;

-- Verify that rows with categoryId=29 now have category_title populated
select * from table_youtube_final where categoryId=29;

-------------------------------------------------
-- Q5. In “table_youtube_final”, which video doesn’t have 
-- a channeltitle (return only the title)?
-------------------------------------------------
SELECT DISTINCT title
FROM table_youtube_final
WHERE channelTitle IS NULL;

-------------------------------------------------
-- Q6. Delete from “table_youtube_final“ 
-- any record with video_id = “#NAME?”
-------------------------------------------------
DELETE FROM table_youtube_final
WHERE video_id = '#NAME?';

-------------------------------------------------
-- Q7. Create a new table called “table_youtube_duplicates” 
-- containing only the “bad” duplicates by using the row_number() function.
-------------------------------------------------
CREATE OR REPLACE TABLE table_youtube_duplicates AS
SELECT *
FROM (
    SELECT f.*,
           ROW_NUMBER() OVER (
               PARTITION BY video_id, country, trending_date  -- detect duplicates
               ORDER BY view_count DESC                       -- keep highest view_count
           ) AS rn
    FROM table_youtube_final f
) t
WHERE rn > 1; -- only keep rows that are considered duplicates

-- Check the duplicate rows stored in table_youtube_duplicates
select * from table_youtube_duplicates;
-------------------------------------------------
-- Q8. Delete the duplicates in “table_youtube_final“ 
-- by using “table_youtube_duplicates”.
-------------------------------------------------
DELETE FROM table_youtube_final f
USING table_youtube_duplicates d
WHERE f.id = d.id;

-------------------------------------------------
-- Q9. Count the number of rows in “table_youtube_final“ 
-- and check that it is equal to 2,597,494 rows.
-------------------------------------------------
SELECT COUNT(*) AS final_row_count
FROM table_youtube_final; -- remove duplicates based on their unique id
