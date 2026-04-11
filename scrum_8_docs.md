# SCRUM-8 — Retrieve top 10 tables in SNOWFLAKE_LEARNING_DB

---

## Overview

This query identifies and ranks the **top 10 base tables** within the `SNOWFLAKE_LEARNING_DB` database. Tables are ranked primarily by **row count** (descending), with **storage size in bytes** used as a tiebreaker. The result set surfaces key metadata for each table, including the schema it belongs to, its storage footprint in both raw bytes and human-readable megabytes, and the timestamp of its last modification.

The query is structured using two Common Table Expressions (CTEs) to separate concerns: raw metric extraction and rank assignment. This layered approach improves readability and makes the ranking logic easy to adjust independently of the data retrieval logic.

---

## JIRA Reference

| Field        | Value                                             |
|--------------|---------------------------------------------------|
| **Ticket**   | SCRUM-8                                           |
| **Summary**  | Retrieve top 10 tables in SNOWFLAKE_LEARNING_DB   |
| **Project**  | SCRUM                                             |

---

## Requirements

The following requirements are addressed by this query:

- **Target Database:** Query must operate against `SNOWFLAKE_LEARNING_DB`.
- **Scope:** Only user-defined **base tables** should be included. Views, transient objects, and system metadata schemas must be excluded.
- **Ranking Metric:** Tables should be ranked by **row count** (descending). Storage size in bytes serves as a secondary sort to break ties deterministically.
- **Output Fields:** Results must include at minimum:
  - Table name
  - Schema name
  - The ranking metric used (row count and storage)
- **Result Limit:** Only the **top 10** tables by rank should be returned.
- **Null Handling:** Empty tables reporting a `NULL` row count should surface as `0` in the final output.

---

## Code Walkthrough

The query is composed of two CTEs followed by a final `SELECT` statement.

---

### CTE 1: `table_storage`

```sql
WITH table_storage AS (
    SELECT
        table_catalog                          AS database_name,
        table_schema                           AS schema_name,
        table_name,
        row_count,
        bytes                                  AS storage_bytes,
        ROUND(bytes / (1024 * 1024), 2)        AS storage_mb,
        last_altered                           AS last_modified_at
    FROM snowflake_learning_db.information_schema.tables
    WHERE table_schema != 'INFORMATION_SCHEMA'
      AND table_type = 'BASE TABLE'
)
```

**Purpose:** Extracts raw storage and row metrics from Snowflake's `INFORMATION_SCHEMA.TABLES` view for the target database.

| Column            | Source Column     | Description                                                                 |
|-------------------|-------------------|-----------------------------------------------------------------------------|
| `database_name`   | `table_catalog`   | The name of the database the table belongs to.                              |
| `schema_name`     | `table_schema`    | The schema in which the table resides.                                      |
| `table_name`      | `table_name`      | The name of the table.                                                      |
| `row_count`       | `row_count`       | The approximate number of rows in the table. May be `NULL` for empty tables.|
| `storage_bytes`   | `bytes`           | Raw storage consumed by the table, expressed in bytes.                      |
| `storage_mb`      | Derived           | Storage in megabytes, rounded to 2 decimal places (`bytes / 1,048,576`).   |
| `last_modified_at`| `last_altered`    | Timestamp of the most recent DDL or DML operation on the table.             |

**Filters applied:**

- `table_schema != 'INFORMATION_SCHEMA'` — Excludes the system metadata schema to ensure only user-managed objects are included.
- `table_type = 'BASE TABLE'` — Restricts results to physical base tables, excluding views, external tables, and transient objects.

---

### CTE 2: `ranked_tables`

```sql
ranked_tables AS (
    SELECT
        database_name,
        schema_name,
        table_name,
        row_count,
        storage_bytes,
        storage_mb,
        last_modified_at,
        ROW_NUMBER() OVER (
            ORDER BY row_count DESC NULLS LAST,
                     storage_bytes DESC NULLS LAST
        ) AS row_rank
    FROM table_storage
)
```

**Purpose:** Assigns a unique sequential rank to every table produced by the `table_storage` CTE using the `ROW_NUMBER()` window function.

**Ranking logic:**

| Priority | Column          | Direction      | Null Handling  | Rationale                                                   |
|----------|-----------------|----------------|----------------|-------------------------------------------------------------|
| Primary  | `row_count`     | `DESC`         | `NULLS LAST`   | Larger tables (by row count) are considered more significant.|
| Secondary| `storage_bytes` | `DESC`         | `NULLS LAST`   | Breaks ties between tables with equal row counts.           |

- `ROW_NUMBER()` guarantees a **unique rank per table**, even when two tables share identical row counts and byte sizes.
- `NULLS LAST` ensures that tables with no row count or byte data are deprioritized rather than incorrectly elevated to the top of the ranking.

---

### Final SELECT Statement

```sql
SELECT
    row_rank                                     AS rank,
    database_name,
    schema_name,
    table_name,
    COALESCE(row_count, 0)                       AS row_count,
    storage_mb,
    storage_bytes,
    last_modified_at
FROM ranked_tables
WHERE row_rank <= 10
ORDER BY row_rank ASC;
```

**Purpose:** Filters the ranked results to the top 10 tables and presents a clean, ordered output.

| Output Column     | Description                                                                          |
|-------------------|--------------------------------------------------------------------------------------|
| `rank`            | The table's position in the ranking (1 = largest by row count).                     |
| `database_name`   | The database containing the table (`SNOWFLAKE_LEARNING_DB`).                        |
| `schema_name`     | The schema containing the table.                                                    |
| `table_name`      | The name of the ranked table.                                                       |
| `row_count`       | Number of rows; `NULL` values are coalesced to `0` for clarity.                    |
| `storage_mb`      | Storage size in megabytes, rounded to 2 decimal places.                             |
| `storage_bytes`   | Raw storage size in bytes.                                                           |
| `last_modified_at`| Timestamp of the last modification to the table's structure or data.                |

- `WHERE row_rank <= 10` — Restricts the final output to the top 10 ranked tables only.
- `ORDER BY row_rank ASC` — Presents results in ascending rank order (rank 1 first).
- `COALESCE(row_count, 0)` — Replaces `NULL` row counts with `0` so consumers of this output do not need to handle nulls downstream.

---

## Usage

### Prerequisites

- The executing role must have `USAGE` privileges on `SNOWFLAKE_LEARNING_DB` and at minimum `SELECT` access on `SNOWFLAKE_LEARNING_DB.INFORMATION_SCHEMA.TABLES`.
- No additional Snowflake `ACCOUNT_USAGE` privileges are required, as this query targets the database-scoped `INFORMATION_SCHEMA`.

### Running the Query

Execute the full SQL block in any Snowflake-compatible SQL interface (Snowflake Web UI, SnowSQL, or a connected BI/ETL tool):

```sql
-- Run as-is; no parameter substitution is required.
-- Ensure your active database context or fully qualified path is correct.
```

### Expected Output

The query returns a maximum of **10 rows**, one per ranked table, ordered from rank 1 (highest row count) to rank 10. Example output structure:

| rank | database_name        | schema_name | table_name      | row_count  | storage_mb | storage_bytes | last_modified_at        |
|------|----------------------|-------------|-----------------|------------|------------|---------------|-------------------------|
|