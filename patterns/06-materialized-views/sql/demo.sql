-- Pattern 06 — Materialized view for fast aggregate reads.

PROMPT === Drop the MV if it exists ===
BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_exposure_summary';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

PROMPT === Create the materialized view ===
CREATE MATERIALIZED VIEW mv_exposure_summary
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT  reporting_date,
        product_code,
        stage,
        COUNT(*)                AS exposure_count,
        SUM(outstanding_amount) AS total_outstanding,
        NVL(SUM(ecl_amount), 0) AS total_ecl
FROM    exposures
GROUP BY reporting_date, product_code, stage;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_EXPOSURE_SUMMARY');

SET TIMING ON

PROMPT === Slow path: aggregate the base table ===
SELECT product_code, stage, SUM(outstanding_amount) total_outstanding
FROM   exposures
WHERE  reporting_date >= TRUNC(SYSDATE) - 30
GROUP BY product_code, stage
ORDER BY product_code, stage;

PROMPT === Fast path: read the materialized view ===
SELECT product_code, stage, SUM(total_outstanding) total_outstanding
FROM   mv_exposure_summary
WHERE  reporting_date >= TRUNC(SYSDATE) - 30
GROUP BY product_code, stage
ORDER BY product_code, stage;

SET TIMING OFF

PROMPT === Refreshing the MV (would normally run on a schedule) ===
EXEC DBMS_MVIEW.REFRESH('MV_EXPOSURE_SUMMARY', 'C');
