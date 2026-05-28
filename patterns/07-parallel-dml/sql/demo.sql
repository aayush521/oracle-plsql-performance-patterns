-- Pattern 07 — Parallel DML & query hints: serial vs parallel comparison.
--
-- Requires the demo schema from schema/sql/01-create-schema.sql.
-- Some Oracle editions require Enterprise + the Parallel option for full benefit.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

PROMPT === Reset stage column ===
UPDATE exposures SET stage = 1;
COMMIT;

PROMPT === Serial UPDATE (baseline) ===
DECLARE
    l_t0 TIMESTAMP := SYSTIMESTAMP;
BEGIN
    UPDATE exposures
       SET stage = CASE
                      WHEN days_past_due >= 90 THEN 3
                      WHEN days_past_due >= 30 THEN 2
                      ELSE 1
                   END;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('serial update : ' ||
        EXTRACT(SECOND FROM (SYSTIMESTAMP - l_t0)) || ' s');
END;
/

PROMPT === Reset stage column again ===
UPDATE exposures SET stage = 1;
COMMIT;

PROMPT === Parallel DML ===
ALTER SESSION ENABLE PARALLEL DML;

DECLARE
    l_t0 TIMESTAMP := SYSTIMESTAMP;
BEGIN
    UPDATE /*+ PARALLEL(e, 4) */ exposures e
       SET stage = CASE
                      WHEN days_past_due >= 90 THEN 3
                      WHEN days_past_due >= 30 THEN 2
                      ELSE 1
                   END;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('parallel(4) update : ' ||
        EXTRACT(SECOND FROM (SYSTIMESTAMP - l_t0)) || ' s');
END;
/

ALTER SESSION DISABLE PARALLEL DML;

PROMPT === Parallel SELECT (analytic aggregate) ===
DECLARE
    l_t0 TIMESTAMP := SYSTIMESTAMP;
    l_count NUMBER;
BEGIN
    SELECT /*+ PARALLEL(e, 4) */ COUNT(*)
      INTO l_count
      FROM exposures e
     WHERE outstanding_amount > 50000;
    DBMS_OUTPUT.PUT_LINE('parallel(4) count : ' ||
        EXTRACT(SECOND FROM (SYSTIMESTAMP - l_t0)) || ' s, rows=' || l_count);
END;
/

SET TIMING OFF
