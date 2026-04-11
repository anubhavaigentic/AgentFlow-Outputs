WITH table_storage AS (
    -- Pull storage and row metrics from Snowflake's account usage layer
    SELECT
        table_catalog                          AS database_name,
        table_schema                           AS schema_name,
        table_name,
        row_count,
        bytes                                  AS storage_bytes,
        -- Convert raw bytes to a human-readable MB figure
        ROUND(bytes / (1024 * 1024), 2)        AS storage_mb,
        last_altered                           AS last_modified_at
    FROM snowflake_learning_db.information_schema.tables
    WHERE table_schema != 'INFORMATION_SCHEMA'  -- exclude system metadata schema
      AND table_type = 'BASE TABLE'             -- exclude views and transient objects
),

ranked_tables AS (
    -- Rank tables by row count descending as the primary relevance metric
    SELECT
        database_name,
        schema_name,
        table_name,
        row_count,
        storage_bytes,
        storage_mb,
        last_modified_at,
        ROW_NUMBER() OVER (
            ORDER BY row_count DESC NULLS LAST,  -- break ties by storage size
                     storage_bytes DESC NULLS LAST
        )                                        AS row_rank
    FROM table_storage
)

SELECT
    row_rank                                     AS rank,
    database_name,
    schema_name,
    table_name,
    COALESCE(row_count, 0)                       AS row_count,       -- surface 0 instead of NULL for empty tables
    storage_mb,
    storage_bytes,
    last_modified_at
FROM ranked_tables
WHERE row_rank <= 10
ORDER BY row_rank ASC;