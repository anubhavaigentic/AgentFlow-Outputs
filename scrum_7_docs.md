# SCRUM-7 — Write Snowflake SQL query using current context functions only

---

## Overview

This document describes a Snowflake SQL query that retrieves session-level context information using Snowflake's built-in context functions. The query returns four key pieces of metadata about the current session in a single result set: the current date, the authenticated user, the active virtual warehouse, and the active role. This type of query is commonly used for session auditing, debugging connection configurations, and validating that a session is operating under the expected security and compute context.

---

## JIRA Reference

| Field       | Details                                                              |
|-------------|----------------------------------------------------------------------|
| **Ticket**  | SCRUM-7                                                              |
| **Summary** | Write Snowflake SQL query using current context functions only       |
| **Type**    | Task                                                                 |
| **Scope**   | Single `SELECT` statement using Snowflake built-in context functions |

---

## Requirements

The following requirements were defined for this task:

1. **Context functions only** — The query must rely exclusively on Snowflake built-in context functions. No user-defined functions, subqueries, or external data sources are permitted.
2. **Four required functions** — The query must include all four of the following Snowflake context functions:
   - `CURRENT_DATE()`
   - `CURRENT_USER()`
   - `CURRENT_WAREHOUSE()`
   - `CURRENT_ROLE()`
3. **Single `SELECT` statement** — All four values must be returned in one result set produced by a single `SELECT` statement.
4. **No DDL or DML statements** — Statements such as `USE DATABASE`, `CREATE`, `INSERT`, `UPDATE`, or `DELETE` are explicitly excluded.
5. **No `USE DATABASE` statement** — The query must not reference or switch any database context prior to execution.
6. **Readable column aliases** — Each function result must be aliased with a descriptive, human-readable column name.

---

## Code Walkthrough

```sql
SELECT
    CURRENT_DATE()      AS current_date,       -- returns the current date in the session time zone
    CURRENT_USER()      AS current_user,        -- returns the login name of the authenticated user
    CURRENT_WAREHOUSE() AS current_warehouse,   -- returns the virtual warehouse currently in use for the session
    CURRENT_ROLE()      AS current_role         -- returns the primary role active in the current session
```

### Line-by-Line Explanation

| Line | Expression | Alias | Description |
|------|------------|-------|-------------|
| 1 | `CURRENT_DATE()` | `current_date` | Returns the current date according to the session's configured time zone. The result is of Snowflake data type `DATE` and does not include a time component. |
| 2 | `CURRENT_USER()` | `current_user` | Returns the login name of the user who authenticated and initiated the current Snowflake session. The result is of type `TEXT`. |
| 3 | `CURRENT_WAREHOUSE()` | `current_warehouse` | Returns the name of the virtual warehouse that is currently active and being used to process queries in the session. Returns `NULL` if no warehouse is currently selected. The result is of type `TEXT`. |
| 4 | `CURRENT_ROLE()` | `current_role` | Returns the name of the primary role that is active in the current session. This role governs the privileges available to the session. The result is of type `TEXT`. |

### Key Design Decisions

- **No `FROM` clause** — Snowflake allows `SELECT` statements without a `FROM` clause when selecting constant values or context functions, making an explicit table reference unnecessary here.
- **Column aliasing** — Each column is given a clear alias using the `AS` keyword to improve the readability of the result set and to avoid ambiguity in downstream tools or reports.
- **Inline comments** — Inline SQL comments (`--`) are included directly on each line to document the purpose of each function at the point of use, aiding maintainability.

---

## Usage

### Prerequisites

Before executing this query, ensure the following:

- You have an active, authenticated Snowflake session.
- A virtual warehouse is assigned and running in your session (otherwise `CURRENT_WAREHOUSE()` will return `NULL`).
- A role is assigned to your session (otherwise `CURRENT_ROLE()` will return `NULL`).

### Execution

Copy and paste the query directly into any of the following interfaces and execute it:

- **Snowflake Web UI (Snowsight)** — Paste into a worksheet and click **Run**.
- **SnowSQL CLI** — Execute directly from the command line after connecting to your Snowflake account.
- **Any Snowflake-compatible SQL client** — Such as DBeaver, DataGrip, or Tableau.

### Expected Output

The query returns a single row with four columns. A representative result might look like the following:

| current_date | current_user | current_warehouse | current_role |
|--------------|--------------|-------------------|--------------|
| 2024-06-15   | JOHN.DOE     | COMPUTE_WH        | ANALYST      |

> **Note:** The actual values returned will reflect the live state of your specific Snowflake session at the time of execution.

---

## Notes & Assumptions

- **Session time zone** — `CURRENT_DATE()` is sensitive to the session-level time zone parameter (`TIMEZONE`). If the session time zone differs from UTC, the date returned may differ from the UTC date. Verify the session time zone with `SHOW PARAMETERS LIKE 'TIMEZONE'` if consistency across regions is required.
- **No warehouse selected** — If no virtual warehouse has been set for the session prior to running this query, `CURRENT_WAREHOUSE()` will return `NULL`. This query itself does not require a running warehouse to execute, as it uses context functions only.
- **Role inheritance** — `CURRENT_ROLE()` returns only the **primary** active role for the session. Secondary roles activated via `USE SECONDARY ROLES` are not reflected in the output of this function.
- **Read-only operation** — This query does not modify any data, schema, or session state. It is entirely safe to run in any environment, including production.
- **No database or schema dependency** — Because no `FROM` clause is used and no database objects are referenced, this query does not depend on any particular database, schema, or object being available in the session.
- **Snowflake-specific syntax** — The context functions used (`CURRENT_DATE()`, `CURRENT_USER()`, `CURRENT_WAREHOUSE()`, `CURRENT_ROLE()`) are proprietary to Snowflake. This query is not intended to be portable to other SQL dialects such as PostgreSQL, MySQL, or SQL Server without modification.
- **Auditability** — This query is well-suited for inclusion in session initialization scripts, onboarding checklists, or automated pipeline health checks where verifying the correct session context is important before proceeding with further operations.