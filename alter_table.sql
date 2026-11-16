-- =====================================================================
-- Add the new columns to public.ai_token_spend
-- =====================================================================

ALTER TABLE public.ai_token_spend
    ADD COLUMN failed_requests    INT,
    ADD COLUMN retry_tokens       BIGINT,
    ADD COLUMN wasted_cost_usd    NUMERIC(12,4),
    ADD COLUMN latency_p50_ms     INT,
    ADD COLUMN latency_p95_ms     INT,
    ADD COLUMN channel            TEXT,
    ADD COLUMN reasoning_tokens   BIGINT,
    ADD COLUMN monthly_budget_usd NUMERIC(12,2),
    ADD COLUMN is_anomaly         TEXT;

-- Table is empty, so just load the new file:
-- \copy public.ai_token_spend FROM 'ai_token_spend_v2.csv' CSV HEADER


-- =====================================================================
-- Checks
-- =====================================================================

-- retry waste
SELECT ROUND(SUM(wasted_cost_usd)) AS wasted,
       ROUND(SUM(wasted_cost_usd) / SUM(cost_usd) * 100, 1) AS pct_of_spend
FROM public.ai_token_spend;

-- budget vs actual by team-month (budget is per team-month, so take MAX not SUM)
SELECT team_name, month_year,
       ROUND(SUM(cost_usd))   AS actual,
       MAX(monthly_budget_usd) AS budget,
       ROUND(SUM(cost_usd) - MAX(monthly_budget_usd)) AS variance
FROM public.ai_token_spend
GROUP BY team_name, month_year
HAVING SUM(cost_usd) > MAX(monthly_budget_usd)
ORDER BY variance DESC;

-- the anomaly days
SELECT usage_date, team_name, ROUND(SUM(cost_usd)) AS cost
FROM public.ai_token_spend
WHERE is_anomaly = 'Yes'
GROUP BY usage_date, team_name
ORDER BY usage_date;
