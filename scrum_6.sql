-- Retrieve current session context information from SNOWFLAKE_LEARNING_DB
-- This query validates session configuration and environment details

USE DATABASE SNOWFLAKE_LEARNING_DB;

WITH session_context AS (
    SELECT
        CURRENT_DATE()      AS current_date,       -- The current date in the session's timezone
        CURRENT_USER()      AS current_user,        -- The user associated with the active session
        CURRENT_WAREHOUSE() AS current_warehouse,   -- The virtual warehouse currently in use
        CURRENT_ROLE()      AS current_role         -- The primary role active in the current session
)

SELECT
    current_date,
    current_user,
    current_warehouse,
    current_role
FROM session_context;