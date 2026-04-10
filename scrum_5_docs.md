# SCRUM-5 — SQL query to retrieve users who signed up in the last 30 days

## Overview

This query retrieves all user records from the `users` table whose registration date falls within the last 30 days relative to the current date. Results are returned in reverse chronological order so that the most recently registered users appear first. The query is structured using Common Table Expressions (CTEs) for clarity, maintainability, and production-grade performance.

---

## JIRA Reference

| Field        | Value                                                                 |
|--------------|-----------------------------------------------------------------------|
| **Ticket**   | SCRUM-5                                                               |
| **Summary**  | SQL query to retrieve users who signed up in the last 30 days         |
| **Status**   | In Progress                                                           |

---

## Requirements

- Retrieve all user records from the database where the signup or registration date falls within the **last 30 days** from the current date.
- The query must return **relevant user information**, including but not limited to: user ID, username, email address, full name, signup date, and account status.
- The query must be **efficient for production use**, avoiding patterns such as correlated subqueries or repeated evaluation of date functions.
- The **current day must be included** in the 30-day window (i.e., the upper bound of the date range is inclusive).
- Results must be **ordered by signup date descending**, so the most recently registered users appear at the top.

---

## Code Walkthrough

The query is composed of two CTEs and a final `SELECT` statement. Each section is described in detail below.

### CTE 1 — `date_range`

```sql
WITH date_range AS (
    SELECT
        CURRENT_DATE - INTERVAL '30 days' AS start_date,
        CURRENT_DATE AS end_date
),
```

**Purpose:**
Calculates the start and end boundaries of the 30-day window a single time and makes them available as named columns for subsequent CTEs.

**Key Details:**
- `CURRENT_DATE - INTERVAL '30 days'` — Computes the start of the window, which is exactly 30 calendar days before today.
- `CURRENT_DATE` — Captures today's date as the end boundary.
- Computing these values once in a dedicated CTE avoids repeated calls to `CURRENT_DATE` throughout the query, which is both cleaner and more performant at scale.

---

### CTE 2 — `recent_users`

```sql
recent_users AS (
    SELECT
        u.id                  AS user_id,
        u.username,
        u.email,
        u.first_name,
        u.last_name,
        u.created_at          AS signup_date,
        u.status              AS account_status
    FROM users u
    JOIN date_range dr
        ON u.created_at >= dr.start_date
        AND u.created_at < dr.end_date + INTERVAL '1 day'
)
```

**Purpose:**
Filters the `users` table to only those records whose `created_at` timestamp falls within the computed 30-day window, and selects the relevant columns.

**Columns Returned:**

| Alias            | Source Column   | Description                              |
|------------------|-----------------|------------------------------------------|
| `user_id`        | `u.id`          | Unique identifier for the user           |
| `username`       | `u.username`    | The user's chosen username               |
| `email`          | `u.email`       | The user's email address                 |
| `first_name`     | `u.first_name`  | The user's first name                    |
| `last_name`      | `u.last_name`   | The user's last name                     |
| `signup_date`    | `u.created_at`  | Timestamp when the user registered       |
| `account_status` | `u.status`      | Current status of the account            |

**Key Details:**
- A `JOIN` against `date_range` is used rather than a correlated subquery or a `WHERE` clause with inline function calls. This gives the query planner a better opportunity to optimize execution.
- The lower bound `u.created_at >= dr.start_date` is **inclusive**, capturing records from the start of the 30th day prior.
- The upper bound `u.created_at < dr.end_date + INTERVAL '1 day'` is deliberately set to **the start of tomorrow**. Because `created_at` is a timestamp (with a time component), using a strict less-than (`<`) against midnight of the next day ensures that all records from today — regardless of the time of day — are included without truncating or casting the timestamp.

---

### Final `SELECT`

```sql
SELECT
    user_id,
    username,
    email,
    first_name,
    last_name,
    signup_date,
    account_status
FROM recent_users
ORDER BY signup_date DESC;
```

**Purpose:**
Projects the final result set from the `recent_users` CTE and applies the sort order.

**Key Details:**
- All columns are passed through from `recent_users` without further transformation.
- `ORDER BY signup_date DESC` ensures that the newest registrations appear at the top of the result set, which is the most useful ordering for typical reporting and monitoring use cases.

---

## Usage

### Prerequisites

- The target database must contain a `users` table with at minimum the following columns: `id`, `username`, `email`, `first_name`, `last_name`, `created_at`, and `status`.
- The `created_at` column must be of a date or timestamp data type for the interval arithmetic to function correctly.
- This query is written for **PostgreSQL**. Minor adjustments may be required for other database engines (see [Notes & Assumptions](#notes--assumptions)).

### Running the Query

Execute the query directly against the target database:

```sql
WITH date_range AS (
    SELECT
        CURRENT_DATE - INTERVAL '30 days' AS start_date,
        CURRENT_DATE AS end_date
),

recent_users AS (
    SELECT
        u.id                  AS user_id,
        u.username,
        u.email,
        u.first_name,
        u.last_name,
        u.created_at          AS signup_date,
        u.status              AS account_status
    FROM users u
    JOIN date_range dr
        ON u.created_at >= dr.start_date
        AND u.created_at < dr.end_date + INTERVAL '1 day'
)

SELECT
    user_id,
    username,
    email,
    first_name,
    last_name,
    signup_date,
    account_status
FROM recent_users
ORDER BY signup_date DESC;
```

### Example Output

| user_id | username    | email                  | first_name | last_name | signup_date              | account_status |
|---------|-------------|------------------------|------------|-----------|--------------------------|----------------|
| 1042    | jsmith      | jsmith@example.com     | John       | Smith     | 2024-11-14 09:23:11+00   | active         |
| 1039    | adavis      | adavis@example.com     | Alice      | Davis     | 2024-11-10 14:05:44+00   | active         |
| 1031    | bwilson     | bwilson@example.com    | Bob        | Wilson    | 2024-11-01 08:47:30+00   | pending        |

### Recommended Index

To ensure optimal performance in production, verify that an index exists on the `created_at` column of the `users` table:

```sql
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at);
```

This allows the database engine to perform an efficient index range scan rather than a full table scan when filtering by the date window.

---

## Notes & Assumptions

- **Database Compatibility:** This query is written for **PostgreSQL** and relies on PostgreSQL-specific syntax, including `CURRENT_DATE`, `INTERVAL '30 days'`, and `INTERVAL '1 day'`. For other database engines, the following adjustments may be needed:
  - **MySQL / MariaDB:** Replace `CURRENT_DATE - INTERVAL '30 days'` with `DATE_SUB(CURDATE(), INTERVAL 30 DAY)`.
  - **SQL Server (T-SQL):** Replace with `DATEADD(DAY, -30, CAST(GETDATE() AS DATE))