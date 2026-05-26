-- Pattern 02 — Partitioning: build a partitioned twin of EXPOSURES.

PROMPT === Building partitioned and non-partitioned tables ===

BEGIN
    FOR rec IN (SELECT table_name FROM user_tables
                 WHERE table_name IN ('EXPOSURES_PARTITIONED','EXPOSURES_NOPART')) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' PURGE';
    END LOOP;
END;
/

CREATE TABLE exposures_partitioned (
    exposure_id        NUMBER          NOT NULL,
    customer_id        NUMBER          NOT NULL,
    reporting_date     DATE            NOT NULL,
    product_code       VARCHAR2(10)    NOT NULL,
    outstanding_amount NUMBER(18,2)    NOT NULL,
    days_past_due      NUMBER(5)       NOT NULL,
    stage              NUMBER(1)       NOT NULL
)
PARTITION BY RANGE (reporting_date) INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
    PARTITION p_initial VALUES LESS THAN (DATE '2023-01-01')
);

CREATE TABLE exposures_nopart AS SELECT * FROM exposures WHERE 1 = 0;

INSERT /*+ APPEND */ INTO exposures_partitioned SELECT * FROM exposures;
INSERT /*+ APPEND */ INTO exposures_nopart      SELECT * FROM exposures;
COMMIT;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'EXPOSURES_PARTITIONED');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'EXPOSURES_NOPART');

PROMPT === Inspect the plan: partition pruning ===
EXPLAIN PLAN FOR
    SELECT SUM(outstanding_amount)
    FROM   exposures_partitioned
    WHERE  reporting_date BETWEEN TRUNC(SYSDATE) - 90 AND TRUNC(SYSDATE);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());
