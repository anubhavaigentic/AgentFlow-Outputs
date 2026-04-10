# SCRUM-6 — Write Snowflake SQL query to select current session details from SNOWFLAKE_LEARNING_DB

---

## Overview

This document describes a Snowflake SQL query developed to retrieve key session-level context information from the `SNOWFLAKE_LEARNING_DB` database. The query leverages Snowflake's built-in context functions to surface details about the active session, including the current date, user, virtual warehouse, and role. This is particularly useful for validating that a session is correctly configured before executing more complex workloads or troubleshooting environment-related issues.

---

## JIRA Reference

| Field        | Detail                                                                                       |
|--------------|----------------------------------------------------------------------------------------------|
| **Ticket**   | SCRUM-6                                                                                      |
| **Summary**  | Write Snowflake SQL query to select current session details from SNOWFLAKE_LEARNING_DB       |
| **Status**   | Completed                                                                                    |

---

## Requirements

The following requirements were defined for this task:

1. **Target Database** — The query must execute within the context of `SNOWFLAKE_LEARNING_DB`.
2. **Current Date** — Retrieve the current date as recognised by the active session's timezone using Snowflake's built-in function.
3. **Current User** — Retrieve the username associated with the active Snowflake session.
4. **Current Warehouse** — Retrieve the name of the virtual warehouse currently in use by the session.
5. **Current Role** — Retrieve the primary role active in the current session.
6. **Session Validation** — The query output should serve as a quick mechanism for validating session configuration and confirming the correct environment details are in effect.

---

## Code Walkthrough

```sql
-- Retrieve current session context information from SNOWFLAKE_LEARNING_DB
-- This query validates session configuration and environment details

USE DATABASE SNOWFLAKE_LEARNING_DB;
```

> **`USE DATABASE SNOWFLAKE_LEARNING_DB;`**
> Sets the active database context to `SNOWFLAKE_LEARNING_DB`. All subsequent queries in the session will reference this database unless explicitly overridden. This ensures the query runs within the intended environment.

---

```sql
WITH session_context AS (
    SELECT
        CURRENT_DATE()      AS current_date,       -- The current date in the session's timezone
        CURRENT_USER()      AS current_user,        -- The user associated with the active session
        CURRENT_WAREHOUSE() AS current_warehouse,   -- The virtual warehouse currently in use
        CURRENT_ROLE()      AS current_role         -- The primary role active in the current session
)
```

> **Common Table Expression (CTE) — `session_context`**
> A CTE is used here to logically encapsulate the session context data before selecting from it. This improves readability and maintainability. The following Snowflake context functions are called within the CTE:
>
> | Alias               | Function              | Description                                                                 |
> |---------------------|-----------------------|-----------------------------------------------------------------------------|
> | `current_date`      | `CURRENT_DATE()`      | Returns the current date based on the session's configured timezone.        |
> | `current_user`      | `CURRENT_USER()`      | Returns the login name of the user associated with the active session.      |
> | `current_warehouse` | `CURRENT_WAREHOUSE()` | Returns the name of the virtual warehouse currently being used.             |
> | `current_role`      | `CURRENT_ROLE()`      | Returns the name of the primary role active in the current session.         |

---

```sql
SELECT
    current_date,
    current_user,
    current_warehouse,
    current_role
FROM session_context;
```

> **Final `SELECT` Statement**
> Selects and surfaces all four aliased columns from the `session_context` CTE. The result is a single-row output containing the session's contextual metadata at the time of query execution.

---

## Usage

### Prerequisites

- Access to a Snowflake account with sufficient privileges to query context functions.
- The `SNOWFLAKE_LEARNING_DB` database must exist and be accessible to the active user and role.
- A virtual warehouse must be active (i.e., running and assigned to the session) for `CURRENT_WAREHOUSE()` to return a non-null value.

### Running the Query

1. Open your Snowflake interface (Snowsight, SnowSQL CLI, or any compatible SQL client).
2. Copy and paste the full SQL code block into the query editor.
3. Execute the query.

### Expected Output

The query returns a **single row** with the following columns:

| Column              | Example Value       | Description                                      |
|---------------------|---------------------|--------------------------------------------------|
| `current_date`      | `2024-11-15`        | The current date in the session's timezone.      |
| `current_user`      | `JOHN_DOE`          | The Snowflake username of the active session.    |
| `current_warehouse` | `COMPUTE_WH`        | The virtual warehouse currently in use.          |
| `current_role`      | `SYSADMIN`          | The active role associated with the session.     |

> **Note:** Actual values will vary depending on the session's configuration at the time of execution.

---

## Notes & Assumptions

- **Single-row result:** Snowflake's context functions each return a scalar value reflecting the state of the current session. As a result, this query will always produce exactly one row of output.
- **Timezone dependency:** `CURRENT_DATE()` is sensitive to the session-level timezone parameter (`TIMEZONE`). If the session timezone differs from UTC, the returned date may vary accordingly. Verify the timezone setting with `SHOW PARAMETERS LIKE 'TIMEZONE';` if precision is required.
- **Null warehouse value:** If no virtual warehouse is assigned to the session at the time of execution, `CURRENT_WAREHOUSE()` will return `NULL`. Ensure a warehouse is active before running the query to confirm warehouse context.
- **Role context:** `CURRENT_ROLE()` reflects only the **primary** active role. Secondary roles activated via `USE SECONDARY ROLES` are not surfaced by this function.
- **No schema or table dependency:** This query does not read from any user-defined tables or views. It relies entirely on Snowflake system-level context functions, meaning it will execute successfully regardless of the schema structure within `SNOWFLAKE_LEARNING_DB`.
- **Assumption — database exists:** It is assumed that `SNOWFLAKE_LEARNING_DB` has already been created in the target Snowflake account. If it does not exist, the `USE DATABASE` statement will raise an error and the query will not execute.
- **Read-only operation:** This query performs no data manipulation (no `INSERT`, `UPDATE`, or `DELETE`). It is entirely safe to run in any environment, including production, without risk of data modification.