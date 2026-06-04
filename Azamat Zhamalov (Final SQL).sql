CREATE DATABASE Customers_transaction;
UPDATE customers SET Gender = NULL WHERE Gender = '';
UPDATE customers SET Age = NULL WHERE Age = '';
ALTER TABLE customers MODIFY Age INT NULL;
SELECT * FROM customers;

CREATE TABLE transactions
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL(10,2));

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\transactions_final.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

USE customers_transaction; 
#1
# Помесячные транзакции клиентов
SELECT 
    ID_client,
    DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,
    COUNT(ID_check) AS operations_count,
    AVG(Sum_payment) AS avg_check,
    SUM(Sum_payment) AS total_sum
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m')
ORDER BY ID_client, transaction_month;

# Клиенты с полной историей (12 месяцев)
SELECT ID_client
FROM (
    SELECT 
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS transaction_month
    FROM Transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m')
) t
GROUP BY ID_client
HAVING COUNT(DISTINCT transaction_month) = 12;

# Итоговая статистика по таким клиентам
SELECT 
    monthly.ID_client,
    AVG(monthly.avg_check) AS avg_check_over_period,
    SUM(monthly.total_sum) / 12 AS avg_monthly_payment,
    SUM(monthly.operations_count) AS total_operations

FROM
(
    SELECT 
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS transaction_month,
        COUNT(ID_check) AS operations_count,
        AVG(Sum_payment) AS avg_check,
        SUM(Sum_payment) AS total_sum
    FROM Transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m')
) monthly

JOIN
(
    SELECT ID_client
    FROM (
        SELECT 
            ID_client,
            DATE_FORMAT(date_new, '%Y-%m') AS transaction_month
        FROM Transactions
        WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
        GROUP BY ID_client, DATE_FORMAT(date_new, '%Y-%m')
    ) x
    GROUP BY ID_client
    HAVING COUNT(DISTINCT transaction_month) = 12
) full_clients
ON monthly.ID_client = full_clients.ID_client
GROUP BY monthly.ID_client;

#2
# Помесячная статистика
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COUNT(DISTINCT t.ID_client) AS clients_count,
    COUNT(t.Id_check) AS operations_count,
    SUM(t.Sum_payment) AS total_sum,
    AVG(t.Sum_payment) AS avg_check
FROM Transactions t
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
ORDER BY month;

# Общие показатели за год
SELECT 
    COUNT(Id_check) AS total_operations_year,
    SUM(Sum_payment) AS total_sum_year
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01';

# Гендерное распределение
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,

    SUM(CASE WHEN c.Gender = 'M' THEN t.Sum_payment ELSE 0 END) AS male_spent,
    SUM(CASE WHEN c.Gender = 'F' THEN t.Sum_payment ELSE 0 END) AS female_spent,
    SUM(CASE WHEN c.Gender IS NULL THEN t.Sum_payment ELSE 0 END) AS na_spent,

    COUNT(DISTINCT CASE WHEN c.Gender = 'M' THEN t.ID_client END) AS male_count,
    COUNT(DISTINCT CASE WHEN c.Gender = 'F' THEN t.ID_client END) AS female_count,
    COUNT(DISTINCT CASE WHEN c.Gender IS NULL THEN t.ID_client END) AS na_count

FROM Transactions t
JOIN Customers c 
    ON t.ID_client = c.ID_client

WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'

GROUP BY DATE_FORMAT(t.date_new, '%Y-%m')
ORDER BY month;

# Доли операций по месяцам
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(Id_check) AS operations_count,
    
    COUNT(Id_check) /
    (
        SELECT COUNT(Id_check)
        FROM Transactions
        WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    ) AS operation_share

FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'

GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;

# Доля суммы по месяцам
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    SUM(Sum_payment) AS monthly_sum,

    SUM(Sum_payment) /
    (
        SELECT SUM(Sum_payment)
        FROM Transactions
        WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    ) AS sum_share

FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'

GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;

#3

SELECT 
    CASE 
        WHEN c.AGE BETWEEN 0 AND 9 THEN '0-9'
        WHEN c.AGE BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.AGE BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.AGE BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.AGE BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.AGE BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.AGE BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.AGE BETWEEN 70 AND 79 THEN '70-79'
        ELSE 'Unknown'
    END AS age_group,

    COUNT(t.ID_check) AS operations_count,
    SUM(t.Sum_payment) AS total_sum,
    AVG(t.Sum_payment) AS avg_payment_per_quarter,

    (
        COUNT(t.ID_check) * 100.0 /
        (
            SELECT COUNT(ID_check)
            FROM Transactions
            WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
        )
    ) AS percentage

FROM Transactions t

JOIN Customers c
ON t.ID_client = c.ID_client

WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'

GROUP BY age_group
ORDER BY age_group;

