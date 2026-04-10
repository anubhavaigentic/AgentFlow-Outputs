WITH date_range AS (
    -- Calculate the 30-day window once to avoid repeated function calls
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
    -- Join instead of correlated subquery for better performance
    JOIN date_range dr
        ON u.created_at >= dr.start_date
        AND u.created_at < dr.end_date + INTERVAL '1 day' -- inclusive upper bound for the current day
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
-- Most recently signed-up users appear first
ORDER BY signup_date DESC;