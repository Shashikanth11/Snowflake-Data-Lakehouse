--------------------------------------------------------------------------------------------------------------------------
-- PART-1: Data Loading and Preparation
--------------------------------------------------------------------------------------------------------------------------

------------------------------------------
-- 3(a) Create a new database for the assignment
------------------------------------------
CREATE DATABASE IF NOT EXISTS assignment_1;

-- Switch to the new database
USE DATABASE assignment_1;

------------------------------------------
-- 3(b) Create a Stage to connect to Azure Blob Storage
------------------------------------------
CREATE OR REPLACE STAGE stage_assignment
  URL = 'azure://bigdataeng.blob.core.windows.net/assignment-1'
  CREDENTIALS = (
    AZURE_SAS_TOKEN = 'sp=racwdli&st=2025-08-17T01:11:18Z&se=2026-08-17T09:26:18Z&spr=https&sv=2024-11-04&sr=c&sig=mN9dCjPWR2vl0OVsYhc7vP358T4EjDmGK4tGEbYlYXc%3D'
  );

-- Verify available files in the stage
LIST @stage_assignment;

------------------------------------------
-- 4 Create File Formats for CSV and JSON
------------------------------------------
-- Define CSV file format (for YouTube trending data)
CREATE OR REPLACE FILE FORMAT file_format_csv
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
NULL_IF = ('\\N', 'NULL', 'NUL', '')
FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- Define JSON file format (for YouTube category data)
CREATE OR REPLACE FILE FORMAT file_format_json
TYPE = 'JSON';

------------------------------------------
-- 4(a) Create External Table for YouTube Trending (CSV)
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_trending
WITH LOCATION = @stage_assignment/youtube_trending/
FILE_FORMAT = file_format_csv
PATTERN = '.*[.]csv';

-- Preview raw data
SELECT * FROM ex_table_youtube_trending LIMIT 5;

------------------------------------------
-- 4(a) Recreate the Trending External Table with Proper datatypes
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_trending (
    video_id STRING AS (VALUE:c1::STRING),
    title STRING AS (VALUE:c2::STRING),
    publishedAt DATE AS (VALUE:c3::DATE),
    channelId STRING AS (VALUE:c4::STRING),
    channelTitle STRING AS (VALUE:c5::STRING),
    categoryId INT AS (VALUE:c6::INT),
    trending_date DATE AS (VALUE:c7::DATE),
    view_count INT AS (VALUE:c8::INT),
    likes INT AS (VALUE:c9::INT),
    dislikes INT AS (VALUE:c10::INT),
    comment_count INT AS (VALUE:c11::INT)
)
WITH LOCATION = @stage_assignment/youtube_trending/
FILE_FORMAT = file_format_csv
PATTERN = '.*[.]csv';

-- Preview structured trending data
SELECT * FROM ex_table_youtube_trending LIMIT 5;

------------------------------------------
-- 4(b) Create External Table for YouTube Category (JSON)
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_category
WITH LOCATION = @stage_assignment/youtube-category/
FILE_FORMAT = file_format_json
PATTERN = '.*[.]json'
AUTO_REFRESH = TRUE;

-- Preview raw category data
SELECT * FROM ex_table_youtube_category;

------------------------------------------
-- 4(b) Flatten the YouTube Category JSON to Extract Fields with correct datatypes
------------------------------------------
SELECT
    l.value:id::STRING                  AS categoryId,
    l.value:etag::STRING                AS etag,
    l.value:kind::STRING                AS kind,
    l.value:snippet.assignable::BOOLEAN AS assignable,
    l.value:snippet.channelId::STRING   AS channel_id,
    l.value:snippet.title::STRING       AS category_title
FROM ex_table_youtube_category,
     LATERAL FLATTEN(input => $1:items) l
LIMIT 10;

------------------------------------------
-- 5(a) Create a Table for Trending Data 
------------------------------------------
CREATE OR REPLACE TABLE table_youtube_trending AS
SELECT
    video_id,
    title,
    publishedAt,
    channelId,
    channelTitle,
    categoryId,
    trending_date,
    view_count,
    likes,
    dislikes,
    comment_count,
    -- Extract country code from file name (e.g., US, IN, CA)
    SPLIT_PART(SPLIT_PART(METADATA$FILENAME, '/', -1), '_', 1) AS country 
FROM ex_table_youtube_trending;

-- Preview trending table
SELECT * FROM table_youtube_trending LIMIT 10;

------------------------------------------
-- 5(b) Create a Table for YouTube Categories with Country from Metadata
------------------------------------------
CREATE OR REPLACE TABLE table_youtube_category AS
SELECT
    SPLIT_PART(SPLIT_PART(METADATA$FILENAME, '/', -1), '_', 1) AS country,
    l.value:id::STRING AS categoryId,
    l.value:snippet.title::STRING AS category_title
FROM ex_table_youtube_category,
     LATERAL FLATTEN(input => VALUE:items) l;

-- Preview category table
SELECT * FROM table_youtube_category LIMIT 5;

------------------------------------------
-- 6. Create Final Consolidated YouTube Table
------------------------------------------
CREATE OR REPLACE TABLE table_youtube_final AS
SELECT
    UUID_STRING() AS id,                -- Unique identifier for each row
    t.video_id,
    t.title,
    t.publishedAt,
    t.channelId,
    t.channelTitle,
    t.categoryId,
    c.category_title,
    t.trending_date,
    t.view_count,
    t.likes,
    t.dislikes,
    t.comment_count,
    t.country
FROM table_youtube_trending t
LEFT JOIN table_youtube_category c
       ON t.categoryId = c.categoryId
      AND t.country = c.country;

-- Preview final table
SELECT * FROM table_youtube_final;
