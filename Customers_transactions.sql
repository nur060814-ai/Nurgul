SELECT * FROM CUSTOMERS;
SELECT * FROM transactions;

-- 1. Клиенты с непрерывной историей за год
WITH client_stats AS (
    SELECT 
        ID_client,
        COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS months_active,
        SUM(Sum_payment) AS total_sum,
        COUNT(Id_check) AS total_ops
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client
)
SELECT 
    ID_client,
    total_sum / total_ops AS avg_check_year,
    total_sum / 12 AS avg_monthly_spend,
    total_ops AS operations_count
FROM client_stats
WHERE months_active = 12;

-- 2. Аналитика по месяцам
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    AVG(Sum_payment) AS avg_check_month,
    COUNT(Id_check) / COUNT(DISTINCT ID_client) AS avg_ops_per_client,
    COUNT(DISTINCT ID_client) AS active_clients_count,
    -- Доли от годовых показателей
    COUNT(Id_check) / SUM(COUNT(Id_check)) OVER() AS ops_share_of_year,
    SUM(Sum_payment) / SUM(SUM(Sum_payment)) OVER() AS sum_share_of_year
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month;

-- Пол (M/F/NA) и траты по месяцам
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COALESCE(c.Gender, 'NA') AS Gender,
    COUNT(t.ID_client) / SUM(COUNT(t.ID_client)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100 AS gender_ratio_pct,
    SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100 AS spend_share_pct
FROM transactions t
LEFT JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month, Gender;

-- 3. Возрастные группы (шаг 10 лет)
SELECT 
    CASE 
        WHEN Age IS NULL THEN 'No Info'
        ELSE CONCAT(FLOOR(Age / 10) * 10, '-', FLOOR(Age / 10) * 10 + 9)
    END AS age_group,
    SUM(Sum_payment) AS total_sum,
    COUNT(Id_check) AS total_ops,
    -- Квартальные показатели (пример для Q1)
    AVG(CASE WHEN QUARTER(date_new) = 1 THEN Sum_payment END) AS Q1_avg_sum,
    COUNT(Id_check) / SUM(COUNT(Id_check)) OVER() * 100 AS total_ops_share_pct
FROM transactions t
LEFT JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group;

