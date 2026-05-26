-- =============================================================
-- Load synthetic data into the demo schema.
-- Default volumes are kept modest so the demos run in seconds on
-- a free Oracle XE / 23ai Free instance. Edit the constants below
-- to scale up.
-- =============================================================

PROMPT === Loading sample data ===

-- ~10K customers
INSERT INTO customers (customer_id, customer_name, risk_rating, country_code, onboarded_at)
SELECT  LEVEL,
        'Customer ' || LEVEL,
        CASE MOD(LEVEL, 6)
             WHEN 0 THEN 'AA'
             WHEN 1 THEN 'A'
             WHEN 2 THEN 'BB'
             WHEN 3 THEN 'B'
             WHEN 4 THEN 'CC'
             ELSE        'C'
        END,
        CASE MOD(LEVEL, 4)
             WHEN 0 THEN 'CAN'
             WHEN 1 THEN 'USA'
             WHEN 2 THEN 'GBR'
             ELSE        'IND'
        END,
        SYSDATE - DBMS_RANDOM.VALUE(0, 3650)
FROM    dual
CONNECT BY LEVEL <= 10000;

-- ~500K exposures across the last 36 months of reporting dates
INSERT /*+ APPEND */ INTO exposures (
    exposure_id, customer_id, reporting_date, product_code,
    outstanding_amount, days_past_due, stage)
SELECT  LEVEL                                         AS exposure_id,
        TRUNC(DBMS_RANDOM.VALUE(1, 10001))            AS customer_id,
        TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(0, 1095)) AS reporting_date,
        CASE MOD(LEVEL, 3)
             WHEN 0 THEN 'LOAN'
             WHEN 1 THEN 'CARD'
             ELSE        'MTG'
        END                                           AS product_code,
        ROUND(DBMS_RANDOM.VALUE(500, 250000), 2)      AS outstanding_amount,
        TRUNC(DBMS_RANDOM.VALUE(0, 180))              AS days_past_due,
        CASE
             WHEN DBMS_RANDOM.VALUE < 0.85 THEN 1
             WHEN DBMS_RANDOM.VALUE < 0.97 THEN 2
             ELSE                              3
        END                                           AS stage
FROM    dual
CONNECT BY LEVEL <= 500000;

COMMIT;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'CUSTOMERS');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'EXPOSURES');

PROMPT === Sample data loaded ===
