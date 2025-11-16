# Snowflake-Data-Lakehouse
The digital economy thrives on data-driven insights. Platforms like YouTube generate massive
amounts of content daily, oﬀering opportunities to understand audience preferences and global
trends. This project builds a Data Lakehouse in Snowflake to process, clean, and analyze
YouTube Trending Videos from 2020 to 2024 across ten countries (India, USA, UK, Germany,
Canada, France, Brazil, Mexico, South Korea, and Japan).
The goal was to ingest, transform, and consolidate multi-source data (CSV and JSON files) into a
structured, query-ready dataset, enabling analysis of trending categories, user engagement, and
content strategies. The dataset includes metadata such as views, likes, comments, category
information, and daily trending videos, providing a rich foundation for insights across multiple
regions.

Project Overview:

The project was executed in four main parts:

● Data Ingestion – Load data into Snowflake via Azure Blob Storage and create
consolidated internal tables.

● Data Cleaning – Handle duplicates, missing values, and invalid entries to ensure dataset
integrity.

● Data Analysis – Perform SQL-driven analysis on top videos, trending categories,
engagement, and channel performance.

● Business Question – Recommend a content strategy for a new YouTube channel based
on global and regional trends.
