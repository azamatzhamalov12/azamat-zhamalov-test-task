SELECT *
FROM audience_data;

SELECT COUNT(DISTINCT user_id) AS MAU
FROM audience_data;

SELECT AVG(dau) AS avg_DAU
FROM (
    SELECT COUNT(DISTINCT user_id) AS dau
    FROM audience_data
    GROUP BY DATE(date)
) daily_users;



WITH first_users AS (
    SELECT user_id
    FROM audience_data
    GROUP BY user_id
    HAVING MIN(DATE(date)) = '2023-11-01'
)
SELECT 
    COUNT(DISTINCT a.user_id) * 100.0 /
    (SELECT COUNT(*) FROM first_users) AS retention_d1
FROM audience_data a
JOIN first_users f
    ON a.user_id = f.user_id
WHERE DATE(a.date) = '2023-11-02';


SELECT 
    COUNT(DISTINCT CASE WHEN view_adverts > 0 THEN user_id END) * 100.0
    / COUNT(DISTINCT user_id) AS conversion_percent
FROM audience_data;



SELECT 
    SUM(view_adverts) / COUNT(DISTINCT user_id) AS avg_views_per_user
FROM audience_data;