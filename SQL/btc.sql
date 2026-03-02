-- Raw data overview
-- Selecting all records to verify table structure and data availability

SELECT 
    *
FROM 
    dbo.btc_analysis;

-- Price analysis by sentiment
-- Calculating the average closing price (Close) for each emotional phase

SELECT 
    value_classification, 
    AVG([close]) AS mean_close
FROM 
    dbo.btc_analysis
GROUP BY 
    value_classification
ORDER BY 
    mean_close ASC;

-- Checking the index range

SELECT 
    value_classification, 
    MIN([value]) AS min_value, 
    MAX([value]) AS max_value, 
    COUNT(*)     AS count_days
FROM 
    dbo.btc_analysis
GROUP BY 
    value_classification
ORDER BY 
    min_value;


-- Price extremes by classification
-- Analyzing historical highs and lows of Bitcoin price for each market state

SELECT 
    value_classification, 
    MIN([close]) AS min_price, 
    MAX([close]) AS max_price, 
    COUNT(*)     AS count_days
FROM 
    dbo.btc_analysis
GROUP BY 
    value_classification
ORDER BY 
    max_price DESC;


-- Average, Min, and Max price change range over a 7-day period for each market state

WITH PriceChange7 AS (
    SELECT
        value_classification,
        [close] AS current_price,
        LEAD([close], 7) OVER (ORDER BY [timestamp]) AS price_7d
    FROM 
        dbo.btc_analysis
)
SELECT
    value_classification,
    AVG((price_7d - current_price) / current_price) * 100 AS percent_7d,
    MIN((price_7d - current_price) / current_price) * 100 AS max_loss_percent,
    MAX((price_7d - current_price) / current_price) * 100 AS max_profit_percent
FROM 
    PriceChange7 
GROUP BY 
    value_classification
ORDER BY 
    percent_7d DESC;


-- Comparative analysis of expected returns over 1, 7, and 30-day horizons

WITH PriceChange AS (
    SELECT
        value_classification,
        [close] AS current_price,
        LEAD([close], 1)  OVER (ORDER BY [timestamp]) AS price_1d,
        LEAD([close], 7)  OVER (ORDER BY [timestamp]) AS price_7d,
        LEAD([close], 30) OVER (ORDER BY [timestamp]) AS price_30d
    FROM 
        dbo.btc_analysis
)
SELECT
    value_classification,
    AVG((price_1d - current_price)  / current_price) * 100 AS percent_1d,
    AVG((price_7d - current_price)  / current_price) * 100 AS percent_7d,
    AVG((price_30d - current_price) / current_price) * 100 AS percent_30d,
    COUNT(price_1d)  AS count_1d,
    COUNT(price_7d)  AS count_7d,
    COUNT(price_30d) AS count_30d
FROM 
    PriceChange 
GROUP BY 
    value_classification
ORDER BY 
    percent_30d DESC;


-- Identifying the specific day with the largest price crash of -45% during the 'Fear' state

WITH PriceChange AS (
    SELECT
        [timestamp],
        [value] AS fear_index,
        value_classification,
        [close] AS start_price,
        LEAD([close], 7) OVER (ORDER BY [timestamp]) AS price_7d,
        volume
    FROM 
        dbo.btc_analysis
)
SELECT TOP 10
    [timestamp],
    fear_index,
    value_classification,
    start_price,
    price_7d,
    ((price_7d - start_price) / start_price) * 100 AS weekly_percent,
    volume
FROM 
    PriceChange
WHERE 
    price_7d IS NOT NULL
ORDER BY 
    weekly_percent ASC;


-- Calculating the average 30-day holding period return by year

WITH PriceChange AS (
    SELECT
        YEAR([timestamp]) AS year_time,
        [close]          AS current_price,
        LEAD([close], 30) OVER (ORDER BY [timestamp]) AS price_30d
    FROM 
        dbo.btc_analysis
)
SELECT
    year_time,
    COUNT(*) AS days_count,
    AVG((price_30d - current_price) / current_price) * 100 AS avg_return_30d
FROM 
    PriceChange
WHERE 
    price_30d IS NOT NULL
GROUP BY 
    year_time
ORDER BY 
    year_time;


-- Calculating returns separately for positive and negative price movements (7 and 30-day horizons)

WITH price_30 AS (
    SELECT
        value_classification,
        [timestamp],
        [close] AS current_price,
        LEAD([close], 30) OVER(ORDER BY [timestamp]) AS price_30d
    FROM 
        dbo.btc_analysis
), 
bool_exp_30 AS (
    SELECT
        value_classification,
        ((price_30d - current_price) / current_price) * 100 AS change_percent,
        CASE
            WHEN price_30d > current_price THEN 1
            ELSE 0
        END AS price_dynamic
    FROM 
        price_30
)
SELECT
    value_classification,
    COUNT(*) AS total_days,
    SUM(price_dynamic) AS positive_dynamic_count,
    ROUND(AVG(CAST(price_dynamic AS FLOAT)) * 100, 2) AS win_percentage,
    ROUND(AVG(CASE WHEN change_percent > 0 THEN change_percent END), 2) AS avg_positive_percent_change,
    ROUND(AVG(CASE WHEN change_percent < 0 THEN change_percent END), 2) AS avg_negative_percent_change
FROM 
    bool_exp_30
GROUP BY 
    value_classification
ORDER BY 
    win_percentage DESC;

--

WITH price_7 AS (
    SELECT
        value_classification,
        [timestamp],
        [close] AS current_price,
        LEAD([close], 7) OVER(ORDER BY [timestamp]) AS price_7d
    FROM 
        dbo.btc_analysis
), 
bool_exp_7 AS (
    SELECT
        value_classification,
        ((price_7d - current_price) / current_price) * 100 AS change_percent,
        CASE
            WHEN price_7d > current_price THEN 1
            ELSE 0
        END AS price_dynamic
    FROM 
        price_7
)
SELECT
    value_classification,
    COUNT(*) AS total_days,
    SUM(price_dynamic) AS positive_dynamic_count,
    ROUND(AVG(CAST(price_dynamic AS FLOAT)) * 100, 2) AS win_percentage,
    ROUND(AVG(CASE WHEN change_percent > 0 THEN change_percent END), 2) AS avg_positive_percent_change,
    ROUND(AVG(CASE WHEN change_percent < 0 THEN change_percent END), 2) AS avg_negative_percent_change
FROM 
    bool_exp_7
GROUP BY 
    value_classification
ORDER BY 
    win_percentage DESC;



-- Creating a view for visualizations

-- Average overall profit margin

CREATE VIEW price_change AS
WITH pricechange AS (
    SELECT
        CAST([timestamp] AS DATE) AS [date],
        value_classification,
        [close] AS current_price,
        LEAD([close], 1)  OVER (ORDER BY [timestamp]) AS price_1d,
        LEAD([close], 7)  OVER (ORDER BY [timestamp]) AS price_7d,
        LEAD([close], 30) OVER (ORDER BY [timestamp]) AS price_30d
    FROM 
        dbo.btc_analysis
)
SELECT
    [date],
    value_classification,
    ((price_1d - current_price)  / current_price) * 100 AS percent_1d,
    ((price_7d - current_price)  / current_price) * 100 AS percent_7d,
    ((price_30d - current_price) / current_price) * 100 AS percent_30d
FROM 
    pricechange;


-- Price fluctuations over time

CREATE VIEW time_change AS
SELECT
    CAST([timestamp] AS DATE) AS [date],
    value_classification,
    [value]                AS fear_greed_index,
    [close]                AS btc_price,
    [volume]               AS volume
FROM 
    dbo.btc_analysis;

-- 7-day and 30-day holding period returns for positive and negative price growth

CREATE VIEW price_move AS
WITH both_prices AS (
    SELECT
        value_classification,
        [timestamp],
        [close] AS current_price,
        LEAD([close], 30) OVER(ORDER BY [timestamp]) AS price_30d,
        LEAD([close], 7)  OVER(ORDER BY [timestamp]) AS price_7d
    FROM 
        dbo.btc_analysis
), 
price_30 AS (
    SELECT
        value_classification,
        30 AS period_d,
        ((price_30d - current_price) / current_price) * 100 AS change_percent,
        CASE
            WHEN price_30d > current_price THEN 1
            ELSE 0
        END AS price_dynamic
    FROM 
        both_prices
), 
price_7 AS (
    SELECT
        value_classification,
        7 AS period_d,
        ((price_7d - current_price) / current_price) * 100 AS change_percent,
        CASE
            WHEN price_7d > current_price THEN 1
            ELSE 0
        END AS price_dynamic
    FROM 
        both_prices
), 
combined AS (
    SELECT * FROM price_30
    UNION ALL
    SELECT * FROM price_7
)
SELECT
    value_classification,
    period_d,
    COUNT(*) AS total_days,
    SUM(price_dynamic) AS positive_dynamic_count,
    ROUND(AVG(CAST(price_dynamic AS FLOAT)) * 100, 2) AS win_percentage,
    ROUND(AVG(CASE WHEN change_percent > 0 THEN change_percent END), 2) AS avg_positive_percent_change,
    ROUND(AVG(CASE WHEN change_percent < 0 THEN change_percent END), 2) AS avg_negative_percent_change
FROM 
    combined
GROUP BY 
    value_classification, 
    period_d;