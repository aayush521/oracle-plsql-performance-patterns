-- Pattern 03 — Indexing: before & after on the same query.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

PROMPT === Drop the composite index if it already exists ===
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX ix_exp_cust_date';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'EXPOSURES');

PROMPT === BEFORE: query without composite index ===
SELECT /*+ NO_INDEX(e) */ COUNT(*)
  FROM exposures e
 WHERE customer_id = 4242
   AND reporting_date >= TRUNC(SYSDATE) - 365;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'BASIC LAST'));

PROMPT === Create composite index ===
CREATE INDEX ix_exp_cust_date ON exposures (customer_id, reporting_date);

EXEC DBMS_STATS.GATHER_INDEX_STATS(USER, 'IX_EXP_CUST_DATE');

PROMPT === AFTER: same query with index in place ===
SELECT COUNT(*)
  FROM exposures
 WHERE customer_id = 4242
   AND reporting_date >= TRUNC(SYSDATE) - 365;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'BASIC LAST'));

SET TIMING OFF
