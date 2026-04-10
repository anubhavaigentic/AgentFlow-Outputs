SELECT
    CURRENT_DATE()      AS current_date,       -- returns the current date in the session time zone
    CURRENT_USER()      AS current_user,        -- returns the login name of the authenticated user
    CURRENT_WAREHOUSE() AS current_warehouse,   -- returns the virtual warehouse currently in use for the session
    CURRENT_ROLE()      AS current_role         -- returns the primary role active in the current session